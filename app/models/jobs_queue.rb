class JobsQueue < ActiveRecord::Base
  belongs_to :aws_key
  has_many :processing_nodes
  has_many :jobs, :order => :submitted_at
  has_many :accesses, :as => :accessable

  acts_as_tsearch :fields => ['name']

  validates_presence_of :name, :min_processing_nodes, :max_processing_nodes, :max_idle_time, :nr_jobs
  validates_uniqueness_of :name, :case_sensitive => false 
  validates_numericality_of :min_processing_nodes, :max_idle_time, :max_waiting_time, :nr_jobs, :only_integer => true
  validates_numericality_of :max_processing_nodes, :greather_than => :min_processing_nodes, :only_integer => true

  named_scope :autoscalable, :conditions => 'is_autoscalable IS TRUE' 
  
  def self.get_jobs_queues(user, criteria)
    if !criteria[:search].blank?
      records = find_match_by_tsearch(criteria[:search],
        {:select => 'DISTINCT(jobs_queues.*)',
        :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['(jobs_queues.is_public IS TRUE OR (accesses.accessable_type = \'JobsQueue\' AND group_users.user_id = ?))', user], 
        :order => get_sort_criteria(criteria[:sort])}, {})
      records = records.paginate(:page => criteria[:page], :per_page => ITEMS_PER_PAGE) unless criteria[:show] 
    else
      if criteria[:show]
        records = all(:select => 'DISTINCT(jobs_queues.*)', 
          :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['(jobs_queues.is_public IS TRUE OR (accesses.accessable_type = \'JobsQueue\' AND group_users.user_id = ?))', user], 
          :order => get_sort_criteria(criteria[:sort]))
      else
        records = paginate(:select => 'DISTINCT(jobs_queues.*)', 
          :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['(jobs_queues.is_public IS TRUE OR (accesses.accessable_type = \'JobsQueue\' AND group_users.user_id = ?))', user], 
          :order => get_sort_criteria(criteria[:sort]), 
          :page => criteria[:page], 
          :per_page => ITEMS_PER_PAGE)  
      end
    end
    records
  end
 
  def self.public_jobs_queues
    all(:conditions => 'is_public IS TRUE')
  end

  # The default queue to use (usually the public one)
  # In the initial phase it's the only one we have - or the first one
  def self.default_queue
    self.first :order => :id
  end

  def self.get_user_jobs_queues(user, criteria, is_super_admin = false)
    if !criteria[:search].blank?
     records = find_by_tsearch(criteria[:search],
        {:select => 'DISTINCT(jobs_queues.*)',
        :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id',
        :conditions => ["#{is_super_admin ? nil : 'is_public = true AND' } (accesses.accessable_type = 'JobsQueue' AND accesses.group_id = ?)", user.groups.default.first.id],
        :order => get_sort_criteria(criteria[:sort])}, {})

    else
      records = all(:select => 'DISTINCT(jobs_queues.*)',
          :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id',
          :conditions => ["#{is_super_admin ? nil : 'is_public = true AND ' } (accesses.accessable_type = 'JobsQueue' AND accesses.group_id = ?)", user.groups.default.first.id],
          :order => get_sort_criteria(criteria[:sort]))
    end
    records = records.uniq
    records = records.paginate(:page => (criteria[:page] || 1),  :per_page => ITEMS_PER_PAGE) unless criteria[:show]

    return records
  end

  # Return the job position in the queue 0 based
  # return nil if the job isn't in the queue
  def job_position(job)
    jobs.index(job)
  end

  # Get the next scheduled job and return it. nil if none available or error
  def run_next_job(proc_node)
    job = nil
    get_next_job = true
    self.transaction do
      while get_next_job
        begin
          job = jobs.first
          job.run(proc_node) if job
          get_next_job = false
        rescue => ex
          # Just name sure we go on
          logger.info "Exception getting next job from queue: #{ex}"
          get_next_job = false
          reload
        end
      end
    end
    job
  end

  def set_visibility(user, parameters)
    self.accesses.each{|access| access.destroy}
    if parameters[:visibility] == 'public'
      self.is_public = true
    else
      self.is_public = false
      parameters[:groups].each do |group_id|
        self.accesses << Access.new(:group_id => group_id)
      end unless parameters[:groups].blank?
    end
    self.accesses << Access.new(:group_id => user.groups.default.first.id)
    self.save
  end

  def owner
    User.first(:select => 'DISTINCT(users.*)', 
      :joins => 'LEFT JOIN group_users ON users.id = group_users.user_id LEFT JOIN accesses ON accesses.group_id = group_users.group_id', 
      :conditions => ['accesses.accessable_type = \'JobsQueue\' AND group_users.role_id = ? AND accesses.accessable_id = ?', Role.find_by_name('Owner').id, self.id])
  end

  def save_aws_key(user, aws_credentials)
    self.aws_key = AwsKey.create(:name => 'Automatically saved key', :access_key_id => aws_credentials[:access_key_id], :secret_access_key => aws_credentials[:secret_access_key], :user_id => user.id)
    self.save! 
  end

  def start_processing_nodes(user)
    1.upto(min_processing_nodes) do
      processing_node = processing_nodes.build(:aws_key_id => aws_key_id) 
      processing_node.save_node(user, {:node_type => 'automatic', :ec2_instance_ami => WORKER_IMG, :ec2_instance_type => 'm1.small', :processing_node => {:aws_key_id => aws_key_id}})
    end
  end

  def update_processing_nodes(user, old_min_processing_nodes)
    if old_min_processing_nodes < min_processing_nodes
      1.upto(min_processing_nodes - old_min_processing_nodes) do
        processing_node = processing_nodes.build(:aws_key_id => aws_key_id) 
        processing_node.save_node(user, {:node_type => 'automatic', :ec2_instance_ami => WORKER_IMG, :ec2_instance_type => 'm1.small', :processing_node => {:aws_key_id => aws_key_id}})
      end
    elsif processing_nodes.size > max_processing_nodes
      nr_of_processing_nodes_to_kill = processing_nodes.size - max_processing_nodes
      processing_nodes.each do |processing_node|
        if (nr_of_processing_nodes_to_kill > 0) and processing_node.jobs.running.size.zero? 
          processing_node.destroy_node
          nr_of_processing_nodes_to_kill -= 1
        end
      end
    end
  end

  def self.kill_idle_processing_nodes
    autoscalable.each do |jobs_queue|
      if jobs_queue.jobs.size.zero? and (jobs_queue.processing_nodes.size > jobs_queue.min_processing_nodes) and !jobs_queue.processing_nodes.idle.size.zero?
        nr_of_processing_nodes_to_kill = jobs_queue.processing_nodes.size - jobs_queue.min_processing_nodes
        jobs_queue.processing_nodes.idle.each do |processing_node|
          if (nr_of_processing_nodes_to_kill > 0) and processing_node.jobs.running.size.zero? 
            processing_node.destroy_node
            nr_of_processing_nodes_to_kill -= 1
          end
        end
      end
    end unless autoscalable.size.zero?
  end

  def self.scale_processing_nodes
    autoscalable.each do |jobs_queue|
      if (jobs_queue.jobs.size > jobs_queue.nr_jobs) and (jobs_queue.processing_nodes.size < jobs_queue.max_processing_nodes) and (Time.now - jobs_queue.jobs.minimum('submitted_at') > jobs_queue.max_waiting_time*60)
        nr_new_processing_nodes = (jobs_queue.processing_nodes.size < jobs_queue.min_processing_nodes) ? jobs_queue.min_processing_nodes - jobs_queue.processing_nodes.size : 1
        nr_new_processing_nodes.times do
        processing_node = jobs_queue.processing_nodes.build(:aws_key_id => jobs_queue.aws_key_id)
        processing_node.save_node(jobs_queue.owner, {:node_type => 'automatic', :ec2_instance_ami => WORKER_IMG, :ec2_instance_type => 'm1.small', :processing_node => {:aws_key_id => jobs_queue.aws_key_id}})
      end
    end
  end
  end
 
  private

  # Get the sort criteria for jobs queues
  def self.get_sort_criteria(sort)
    case sort
    when 'id'                   then 'id'
    when 'name'                 then 'name'
    when 'id_reverse'           then 'id DESC'
    when 'name_reverse'         then 'name DESC'
    else 'name'
    end
  end

end
