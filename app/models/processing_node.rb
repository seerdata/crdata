class ProcessingNode < ActiveRecord::Base
  include AASM

  belongs_to :jobs_queue
  belongs_to :user
  belongs_to :aws_key
  has_many :jobs
  has_many :running_jobs, :class_name => 'Job', :conditions => "status = 'running'", :order => :started_at

  acts_as_tsearch :fields => ['ip_address', 'node_identifier']
  
  validates_presence_of  :ip_address, :if => Proc.new{|pn| pn.node_identifier.blank? }
  validates_presence_of  :jobs_queue

  named_scope :active, :conditions => { :active => true } 
  named_scope :idle, :joins => 'LEFT JOIN jobs_queues on processing_nodes.jobs_queue_id = jobs_queues.id', 
  :conditions => "NOW() - jobs_queues.max_idle_time * INTERVAL '1 minute' > processing_nodes.updated_at"


  aasm_column :status
  aasm_initial_state :created
  aasm_state :created
  aasm_state :waiting_approval, :enter => Proc.new {|processing_node| Notifier.deliver_notify_jobs_queue_owner_of_processing_node_donation(processing_node); Notifier.deliver_thanks_for_processing_node_donation(processing_node)}
  aasm_state :activated_and_waiting_approval
  aasm_state :approved,         :enter => Proc.new {|processing_node| Notifier.deliver_notify_processing_node_donor_of_approval(processing_node)}
  aasm_state :disapproved,      :enter => Proc.new {|processing_node| Notifier.deliver_notify_processing_node_donor_of_rejection(processing_node)}                      
  aasm_state :activated,        :enter => Proc.new {|processing_node| Notifier.deliver_notify_processing_node_donor_of_approval(processing_node) if processing_node.status == 'activated_and_waiting_approval'}
  
  aasm_event :donate do
    transitions :to => :waiting_approval, :from => [:created]
  end
  
  aasm_event :approve do
    transitions :to => :approved, :from => [:waiting_approval]
  end
    
  aasm_event :disapprove do
    transitions :to => :disapproved, :from => [:waiting_approval, :activated_and_waiting_approval]
  end
   
  aasm_event :activate_waiting_approval do
    transitions :to => :activated_and_waiting_approval, :from => [:waiting_approval]
  end

  aasm_event :activate do
    transitions :to => :activated, :from => [:created, :approved, :activated_and_waiting_approval]
  end
  
  def save_node(user, parameters)
    begin
      if parameters[:node_type] == 'automatic'
        aws_credentials = get_aws_credentials(user, parameters) 
        ec2 = RightAws::Ec2.new(aws_credentials[:access_key_id], aws_credentials[:secret_access_key])
        key = 'crdata_key'
        new_key = ec2.create_key_pair(key) unless ec2.describe_key_pairs().collect{|key_pair| key_pair[:aws_key_name]}.include?('crdata_key')
        self.uuid = UUID.generate
        security_group = AwsKey.is_crdata_key?(aws_credentials[:access_key_id]) ? EC2_SECURITY_GROUP : 'default'
        ec2_instances = ec2.run_instances(parameters[:ec2_instance_ami], 1, 1, [security_group], key, "url='" + CRDATA_HOST + "', uid='" + self.uuid + "'", nil, nil, nil, nil, user.availability_zone_preference)
        self.node_identifier = ec2_instances[0][:aws_instance_id]
      else
        self.aws_key_id = 0
      end
    rescue Exception => e
      self.errors.add('node_type', e.message)
      return false
    else
      self.user = user
      self.save
    end
  end
  
  def save_aws_key(user, aws_credentials)
    self.aws_key = AwsKey.create(:name => 'Automatically saved key', :access_key_id => aws_credentials[:access_key_id], :secret_access_key => aws_credentials[:secret_access_key], :user_id => user.id)
    self.save! 
  end
  
  def self.get_processing_nodes(user, criteria)
    if !criteria[:search].blank?
      records = find_by_tsearch(criteria[:search], 
        :select => 'DISTINCT(processing_nodes.*), jobs_queues.name', 
        :joins => 'LEFT JOIN jobs_queues ON processing_nodes.jobs_queue_id = jobs_queues.id LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['(jobs_queues.is_public IS TRUE OR (accesses.accessable_type = \'JobsQueue\' AND group_users.user_id = ?))', user], 
        :order => get_sort_criteria(criteria[:sort]))
      records = records.paginate(:page => criteria[:page], :per_page => ITEMS_PER_PAGE) unless criteria[:show] 
    else
      if criteria[:show]
        records = all(:select => 'DISTINCT(processing_nodes.*), jobs_queues.name', 
          :joins => 'LEFT JOIN jobs_queues ON processing_nodes.jobs_queue_id = jobs_queues.id LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['(jobs_queues.is_public IS TRUE OR (accesses.accessable_type = \'JobsQueue\' AND group_users.user_id = ?))', user], 
          :order => get_sort_criteria(criteria[:sort]))
      else
        records = paginate(:select => 'DISTINCT(processing_nodes.*), jobs_queues.name', 
          :joins => 'LEFT JOIN jobs_queues ON processing_nodes.jobs_queue_id = jobs_queues.id LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['(jobs_queues.is_public IS TRUE OR (accesses.accessable_type = \'JobsQueue\' AND group_users.user_id = ?))', user], 
          :order => get_sort_criteria(criteria[:sort]), 
          :page => criteria[:page], 
          :per_page => ITEMS_PER_PAGE)  
      end
    end
    records
  end

  def self.get_user_processing_nodes(user,criteria, is_super_admin = false)
    if !criteria[:search].blank?
      records = find_by_tsearch(criteria[:search],
        :select => 'DISTINCT(processing_nodes.*), jobs_queues.name',
        :joins => 'LEFT JOIN jobs_queues ON processing_nodes.jobs_queue_id = jobs_queues.id LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id',
        :conditions => ["#{is_super_admin ? nil : 'is_public = true AND' } (accesses.accessable_type = 'JobsQueue' AND accesses.group_id = ?)", user.groups.default.first.id],
        :order => get_sort_criteria(criteria[:sort]))
      
    else
      records = all(:select => 'DISTINCT(processing_nodes.*), jobs_queues.name',
          :joins => 'LEFT JOIN jobs_queues ON processing_nodes.jobs_queue_id = jobs_queues.id LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id',
          :conditions => ["#{is_super_admin ? nil : 'is_public = true AND' } (accesses.accessable_type = 'JobsQueue' AND accesses.group_id = ?)", user.groups.default.first.id],
          :order => get_sort_criteria(criteria[:sort]))
    end
    records = records.uniq
    records = records.paginate(:page => (criteria[:page] || 1),  :per_page => ITEMS_PER_PAGE) unless criteria[:show]

    return records
  end
  
  def destroy_node
    begin
      if aws_key
        key = aws_key.aws_decrypt
        ec2 = RightAws::Ec2.new(key[0], key[1])
        ec2.terminate_instances(node_identifier)
      end
    rescue Exception => e
      return e.message
    else
      self.destroy
      return true
    end
  end
 
  private

  # Get the sort criteria for processing nodes
  def self.get_sort_criteria(sort)
    case sort
    when 'id'                      then 'id'
    when 'node_identifier'         then 'node_identifier'
    when 'ip_address'              then 'ip_address'
    when 'status'                  then 'active'
    when 'queue'                   then 'jobs_queues.name'
    when 'id_reverse'              then 'id DESC'
    when 'node_identifier_reverse' then 'node_identifier DESC'
    when 'ip_address_reverse'      then 'ip_address DESC'
    when 'status_reverse'          then 'active DESC'
    when 'queue_reverse'           then 'jobs_queues.name DESC'
    else 'id'
    end
  end

  def get_aws_credentials(user, parameters) 
    if aws_key = user.aws_keys.find_by_id(parameters[:processing_node][:aws_key_id])
      decrypted_aws_key = aws_key.decrypt
      {:access_key_id => decrypted_aws_key.access_key_id, :secret_access_key => decrypted_aws_key.secret_access_key} 
    else
      parameters[:aws_credentials]
    end
  end


end
