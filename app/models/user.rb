class User < ActiveRecord::Base
  ajaxful_rater
  acts_as_authentic do |u|
    u.login_field = :email
    u.validate_login_field = false 
  end

  has_many :group_users#, :dependent => :destroy
  has_many :groups, :through => :group_users, :order => 'groups.updated_at DESC'
  has_many :jobs, :dependent => :destroy
  has_many :processing_nodes, :dependent => :destroy
  has_many :aws_keys, :dependent => :destroy
  has_many :logs, :dependent => :destroy, :order => 'created_at DESC'
  has_many :preferences, :dependent => :destroy

  before_create :downcase_email
  before_destroy :destroy_related_records

  validates_presence_of :first_name, :last_name
  
  named_scope :approved,  :conditions => "status = 'approved'"
  named_scope :rejected,  :conditions => "status = 'rejected'"
  named_scope :requested, :conditions => "status = 'requested'"
  named_scope :invited,   :conditions => "status = 'invited'"
  named_scope :cancelled, :conditions => "status = 'cancelled'"
  named_scope :owners,    :conditions => ['group_users.role_id = ?', Role.find_by_name('Owner').id]
  named_scope :admins,    :conditions => ['group_users.role_id IN (?, ?)', Role.find_by_name('Owner').id, Role.find_by_name('Admin').id]

  def self.site_admins_emails
    find_all_by_is_admin(1).collect{|user| user.email}.join(', ')
  end

  def name
    "#{first_name} #{last_name}"
  end
  
  def active?
    is_active
  end

  def activate!
    self.is_active = true
    save
  end

  def is_site_admin?
    is_admin >= 1
  end

  def is_super_admin?
    is_admin == 2
  end

  def deliver_activation_instructions!
    reset_perishable_token!
    Notifier.deliver_activation_instructions(self)
  end

  def deliver_activation_confirmation!
    reset_perishable_token!
    Notifier.deliver_activation_confirmation(self)
  end

  def deliver_password_reset_instructions!  
    reset_perishable_token!  
    Notifier.deliver_password_reset_instructions(self)  
  end

  def r_scripts
    RScript.all(:select => 'DISTINCT(r_scripts.*)', 
      :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['(r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?))', self.id],
      :order => 'r_scripts.updated_at DESC')
  end

  def data_sets
    DataSet.all(:select => 'DISTINCT(data_sets.*)', 
      :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['(data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?))', self.id])
  end

  def jobs_queues
    JobsQueue.all(:select => 'DISTINCT(jobs_queues.*)', 
      :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['(jobs_queues.is_public IS TRUE OR (accesses.accessable_type = \'JobsQueue\' AND group_users.user_id = ?))', self.id])
  end

  def jobs_queues_admin
    jobs_queues = JobsQueue.all(:select => 'DISTINCT(jobs_queues.*)', 
      :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['accesses.accessable_type = \'JobsQueue\' AND group_users.role_id IN (?, ?) AND group_users.user_id = ?', Role.find_by_name('Owner').id, Role.find_by_name('Admin').id, self.id])
    
    jobs_queues |= JobsQueue.public_jobs_queues if is_site_admin?
    jobs_queues
  end

  def jobs_queue_groups_admin(jobs_queue)
    Group.all(:select => 'DISTINCT(groups.*)', 
      :joins => 'LEFT JOIN accesses ON groups.id = accesses.group_id LEFT JOIN jobs_queues ON accesses.accessable_id = jobs_queues.id LEFT JOIN group_users ON groups.id = group_users.group_id', 
      :conditions => ['accesses.accessable_type = \'JobsQueue\' AND accessable_id = ? AND group_users.role_id IN (?, ?) AND group_users.user_id = ?', jobs_queue.id, Role.find_by_name('Owner').id, Role.find_by_name('Admin').id, self.id],
      :order => 'groups.updated_at DESC')
  end

 def is_group_owner?(group)
    !GroupUser.all(:conditions => ['user_id = ? AND group_id = ? AND role_id = ?', self.id, group.id, Role.find_by_name('Owner').id]).blank?
  end
  
  def is_group_admin?(group)
    !GroupUser.all(:conditions => ['user_id = ? AND group_id = ? AND role_id IN (?, ?)', self.id, group.id, Role.find_by_name('Owner').id, Role.find_by_name('Admin').id]).blank?
  end

  def is_group_member?(group)
    !GroupUser.all(:conditions => ['user_id = ? AND group_id = ? AND role_id = ?', self.id, group.id, Role.find_by_name('User').id]).blank?
  end

  def queue_notification_preference
    preferences.find_by_kind('queue')
  end

  def time_notification_preference
    preferences.find_by_kind('time')
  end
  
  def availability_zone_preference
    (preference = preferences.find_by_kind('availability_zone')) ? preference.value : nil
  end

  def save_preferences(parameters)
    if parameters[:private] and parameters[:public]
      queue = 'all'
    elsif parameters[:private]
      queue = 'private'
    elsif parameters[:public]
      queue = 'public'
    else
      queue = nil
    end

    if queue
      if preference = queue_notification_preference
        preference.value = queue
        preference.save
      else
        self.preferences.create(:kind => 'queue', :value => queue)
      end
    elsif preference = queue_notification_preference
      preference.destroy
    end

    if parameters[:time] and !parameters[:value].blank?
      if preference = time_notification_preference
        preference.value = parameters[:value]
        preference.save
      else
        self.preferences.create(:kind => 'time', :value => parameters[:value])
      end
    elsif preference = time_notification_preference
      preference.destroy
    end
  end

  def destroy_related_records
    data_sets = DataSet.find(:all, :joins => "JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id",
      :conditions => ["accesses.accessable_type = 'DataSet' AND accesses.group_id = ?", self.groups.default.first.id])
    data_sets.each {|ds| ds.destroy}
    r_scripts = RScript.find(:all, :joins => "JOIN accesses ON r_scripts.id = accesses.accessable_id",
      :conditions => ["accesses.accessable_type = 'RScript' AND accesses.group_id = ?",self.groups.default.first.id])
    r_scripts.each {|rs| rs.destroy}
    groups = Group.find(:all, :joins => "JOIN group_users ON groups.id = group_users.group_id",
      :conditions => ["group_users.user_id = ? AND group_users.role_id = ?", self.id, Role.find(:first, :conditions => "name = 'Owner'")])
    groups.each {|gs| gs.destroy if gs.group_users.size <= 1}
  end

  def current_notification
    pref = Announcement.find(:first, :order => "created_at DESC")
    return (pref.blank? || Preference.exists?(["kind = ? and user_id = ? and value = ? ","notification_acknowledge",self.id,pref.id.to_s]) ? nil : pref )
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
