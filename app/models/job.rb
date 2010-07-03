class Job < ActiveRecord::Base

  belongs_to :r_script
  belongs_to :jobs_queue
  belongs_to :processing_node
  belongs_to :user
  has_many   :job_parameters, :dependent => :destroy
  has_many   :parameters, :through => :job_parameters
  has_many   :data_sets,  :through => :job_parameters
  has_many   :logs, :dependent => :destroy

  #accepts_nested_attributes_for :job_data_sets
  accepts_nested_attributes_for :job_parameters

  validates_presence_of  :processing_node, :started_at, :if => Proc.new{|job| job.status == 'running' }
  validates_presence_of  :completed_at, :if => Proc.new{|job| job.status == 'done' }
  validates_presence_of  :r_script
  validates_presence_of  :description
  validates_inclusion_of :status, :in => %w( new submitted running done cancelled pending), :message => 'Valid values are: new, submitted, running, cancelled and done'
  validate :check_state_transition

  before_validation_on_create :set_to_new
  after_create :set_uuid
  before_destroy :check_status
  
  named_scope :running, :conditions => "status = 'running'"

  def self.get_jobs(user, criteria)
    (criteria[:show]) ? Job.all(:conditions => get_conditions(user, criteria[:statuses]), :order => get_sort_criteria(criteria[:sort])) : Job.paginate(:conditions => get_conditions(user, criteria[:statuses]), :order => get_sort_criteria(criteria[:sort]), :page => criteria[:page], :per_page => ITEMS_PER_PAGE)
  end

  # Start running - unqueue and execute
  def run(proc_node)
    self.transaction do
      self.lock!
      self.jobs_queue.update_attributes(:updated_at => Time.now)
      unqueue('running')
      self.processing_node = proc_node
      self.started_at = Time.now
      save! # this is one instance we really want an exception
    end
  end


  # Finish run
  def done(success)
    self.transaction do
      self.lock!
      self.status = 'done'
      self.successful = success
      self.completed_at = Time.now
      self.processing_node.updated_at = Time.now
      self.processing_node.save
      save
    end
  end


  # Clone the job (without saving it) 
  def cloned_job
    self.transaction do
      j = Job.new( :description =>  self.description, :status => 'new', :r_script => self.r_script)
      j.parameters << self.parameters
      j.job_parameters << self.job_parameters

      j
    end
  end

  # Cancel run 
  def cancel
    self.transaction do
      self.lock!
      if jobs_queue
        unqueue('cancelled')
      else
        self.status = 'cancelled'
      end

      #self.successful = false
      self.completed_at = Time.now
      save
    end
  end

  # Queue it
  def submit(queue = nil) 
    self.transaction do
      self.lock!
      # We default to the default queue!!!
      self.jobs_queue = queue || JobsQueue.default_queue
      self.status = 'submitted'
      self.submitted_at = Time.now
      save
    end
  end

  # Set as pending 
  def pending 
    self.transaction do
      self.lock!
      self.status = 'pending'
      save
      Notifier.deliver_notify_admins_of_job_that_needs_user_defined_r_packages(self)
      Notifier.deliver_notify_user_that_job_needs_admin_approval(self) if self.user
    end
  end

  # Approve it 
  def approve 
    self.transaction do
      self.lock!
      self.status = 'done'
      self.successful = true
      self.started_at = self.completed_at = Time.now    
      save
      Notifier.deliver_notify_user_of_job_approval(self) if self.user
    end
  end

  # Return a URL used to upload to S3 (or any other service)
  # We have two different sets - one for results and one for logs
  # upload_type controls the returned URL it can be :logs or :results
  # files is one or more file names and can include a path as well
  def uploadurls(upload_type, files)
    files = { files => files } unless (Hash === files) || files.blank? # We need a hash here...
    raise 'Invalid upload type' if !upload_type || ![:data, :logs, :results].include?(upload_type.to_sym)
    raise 'Invalid files list ' if files.blank?

    # Collect it all in a hash
    host = "#{MAIN_BUCKET}.s3.amazonaws.com"
    files.inject({}) do |res_hash, f|
      path = "/#{upload_type}/#{self.uuid}/#{f[1]}" 
      res_hash[f[1]] = {:header => generate_s3_upload_header(host, path), :host => host, :port => '443', :path => path, :ssl => true} 
      res_hash
    end
  end

  def destroy_job
    begin
      if status == 'done' 
        s3.delete_folder(MAIN_BUCKET, "results/#{uuid}") if successful == true
        s3.delete_folder(MAIN_BUCKET, "logs/#{uuid}") 
      end
    rescue Exception => e
      return e.message
    else
      self.destroy
      return true
    end
  end

  # Helper to return a text formatted job ID
  def formatted_id
    sprintf("job_%010d", id)
  end

  def is_notifiable?
    (qp = user.queue_notification_preference and (qp.value =='all' or (qp.value == 'private' and !jobs_queue.is_public) or (qp.value == 'public' and jobs_queue.is_public))) or (tp = user.time_notification_preference and ((completed_at - started_at) > (tp.value.to_i * 60)))
  end

  private

  # Helper to return an interface to S3
  def s3
    $S3 ||= RightAws::S3Interface.new(AWS_ACCESS_KEY, AWS_SECRET_KEY)
    $S3
  end
 
  def generate_s3_upload_header(host, path)
    date = Time.now.httpdate
    { 'Host' => host, 'AWS-Version' => '2007-05-01', 'x-amz-date' => date, 'x-amz-acl' => 'public-read',
      'Content-type' => "", 'Content-length' => "0",
      'Authorization' => "AWS #{AWS_ACCESS_KEY}:#{generate_signature('PUT', path, date)}" }
  end

  def generate_signature(action, path, date)
    to_sign = <<EOS
#{action.to_s.upcase}



x-amz-acl:public-read
x-amz-date:#{date}
/#{MAIN_BUCKET}#{path}
EOS
    digest = OpenSSL::Digest::Digest.new 'sha1'
    sig = OpenSSL::HMAC.digest(digest, AWS_SECRET_KEY, to_sign.chomp)
    sig = Base64.encode64(sig).strip
  end
 
  # Remove from the queue
  def unqueue(new_status)
    self.jobs_queue = nil
    self.status = new_status 
  end

  # Set it to new state if not given already
  def set_to_new
    self.status ||= 'new'
  end

  # Set the job unique identifier
  def set_uuid
    self.uuid = "#{id}-#{Digest::SHA1.hexdigest(UUID.generate + Time.now.to_s)}"
    self.save
  end

  # Make sure the state we are transitioing to is valid!
  def check_state_transition    
    # List of statuses we are allowed to set. Anything else is an error
    $ALLOWED_STATUSES ||= { nil => ['new'], 'new' => ['submitted', 'cancelled', 'pending'], 'submitted' => ['running', 'cancelled', 'new'], 
                            'running' => ['done', 'cancelled', 'new'], 'done' => ['new'], 'cancelled' => ['new'], 'pending' => ['done', 'cancelled'] }
    errors.add(:status, 'Invalid status transition!') if status_changed? && !$ALLOWED_STATUSES[status_change[0]].include?(status_change[1])
    # We cannot change the submitted_at if it's already set
    errors.add(:submitted_at, 'Cannot resubmit the same job') if submitted_at_changed? && !submitted_at_change[0].nil?

    # We cannot change the completed_at if it's already set
    errors.add(:completed_at, 'Cannot complete the same job') if completed_at_changed? && !completed_at_change[0].nil?
  end

  # Make sure that only finished or cancelled jobs can be deleted 
  def check_status
    errors.add_to_base 'Cannot delete job' and return false unless %w(new done cancelled).include?(self.status)
  end

  # Get the sort criteria for jobs
  def self.get_sort_criteria(sort)
    case sort
    when 'id'                   then 'id'
    when 'description'          then 'description'
    when 'created_at'           then 'created_at'
    when 'status'               then 'replace(status,\'done\',\' \')'
    when 'running_time'         then 'id' 
    when 'id_reverse'           then 'id DESC'
    when 'description_reverse'  then 'description DESC'
    when 'created_at_reverse'   then 'created_at DESC'
    when 'status_reverse'       then 'replace(status,\'done\',\' \') DESC'
    when 'running_time_reverse' then 'id DESC' 
    else 'updated_at DESC'
    end
  end

  # Get search conditions for jobs
  def self.get_conditions(user, statuses)
    conditions = "user_id #{(user) ? ' = ' + user.id.to_s : ' IS NULL'}"
    conditions += " OR status = 'pending'" if user and user.is_site_admin?
    #conditions = "(#{conditions} OR user_id IS NULL)" if user and user.is_site_admin?
    if statuses
      selected_statuses = statuses.keys & JOB_STATUSES
      selected_states = []
      selected_states << true if selected_statuses.include?('done')
      if selected_statuses.include?('failed')
        selected_statuses -= ['failed']
        selected_statuses |= ['done']
        selected_states << false
      end   
    end
    conditions = "(#{conditions}) AND status IN ('#{selected_statuses.join("', '")}')" if !selected_statuses.blank?
    conditions += " AND (successful IN ('#{selected_states.join("', '")}') #{((selected_statuses - ['done']).size > 0) ? 'OR successful IS NULL' : '' })" if !selected_states.blank?
    conditions
  end

end
