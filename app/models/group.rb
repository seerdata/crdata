class Group < ActiveRecord::Base
  acts_as_tsearch :fields => ['name']

  has_many :group_users, :dependent => :destroy
  has_many :users, :through => :group_users
  has_many :accesses, :dependent => :destroy

  validates_presence_of   :name
  validates_uniqueness_of :name

  named_scope :invited,  :conditions => "status = 'invited'"
  named_scope :approved, :conditions => "status = 'approved'"
  named_scope :default,  :conditions => "is_default IS TRUE"
  named_scope :not_default, :conditions => "is_default IS NOT TRUE"

  def self.get_groups(user, criteria)
    if !criteria[:search].blank?
      records = find_by_tsearch(criteria[:search], :conditions => 'is_default IS FALSE', :order => get_sort_criteria(criteria[:sort]))
      records = records.paginate(:page => criteria[:page], :per_page => ITEMS_PER_PAGE) unless criteria[:show] 
    elsif criteria[:my_groups]
      records = (criteria[:show]) ? user.groups(:conditions => 'is_default IS FALSE', :order => get_sort_criteria(criteria[:sort])) : user.groups.paginate(:conditions => 'is_default IS FALSE', :order => get_sort_criteria(criteria[:sort]), :page => criteria[:page], :per_page => ITEMS_PER_PAGE)  
    else
      records = (criteria[:show]) ? all(:conditions => 'is_default IS FALSE', :order => get_sort_criteria(criteria[:sort])) : paginate(:conditions => 'is_default IS FALSE', :order => get_sort_criteria(criteria[:sort]), :page => criteria[:page], :per_page => ITEMS_PER_PAGE)  
    end
    records
  end


  def self.get_user_groups(user, criteria)
    if !criteria[:search].blank?
      records = find_by_tsearch(criteria[:search], :order => get_sort_criteria(criteria[:sort], :conditions => "is_default = false"))
    else
      records = find(:all, :joins => "JOIN group_users on group_users.group_id = groups.id",
        :conditions => ["groups.is_default = false AND group_users.user_id = ? AND group_users.role_id = ?",user.id, Role.find_by_name('Owner')], :order => get_sort_criteria(criteria[:sort]))
#        user.groups.find(:all, :order => get_sort_criteria(criteria[:sort]))
    end
    records = records.uniq
    records = records.paginate(:page => criteria[:page], :per_page => ITEMS_PER_PAGE, :order => get_sort_criteria(criteria[:sort]))
    return records
  end

  def r_scripts
    RScript.all(:select => 'DISTINCT(r_scripts.*)', 
      :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id',
      :conditions => ['accesses.accessable_type = \'RScript\' AND accesses.group_id = ?', self.id],
      :order => 'r_scripts.updated_at DESC')
  end

  def count_r_scripts
    RScript.count(:select => 'DISTINCT(r_scripts.id)', 
      :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id',
      :conditions => ['accesses.accessable_type = \'RScript\' AND accesses.group_id = ?', self.id])
  end

  def data_sets
    DataSet.all(:select => 'DISTINCT(data_sets.*)', 
      :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id',
      :conditions => ['accesses.accessable_type = \'DataSet\' AND accesses.group_id = ?', self.id],
      :order => 'data_sets.updated_at DESC')
  end

  def count_data_sets
    DataSet.count(:select => 'DISTINCT(data_sets.id)', 
      :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id',
      :conditions => ['accesses.accessable_type = \'DataSet\' AND accesses.group_id = ?', self.id])
  end

  def jobs_queues
    JobsQueue.all(:select => 'DISTINCT(jobs_queues.*)', 
      :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id',
      :conditions => ['accesses.accessable_type = \'JobsQueue\' AND accesses.group_id = ?', self.id])
  end

 private

  # Get the sort criteria for groups
  def self.get_sort_criteria(sort)
    case sort
    when 'id'                   then 'id'
    when 'name'                 then 'name'
    when 'description'          then 'description'
    when 'id_reverse'           then 'id DESC'
    when 'name_reverse'         then 'name DESC'
    when 'description_reverse'  then 'description DESC'
    else 'updated_at DESC'
    end
  end
 
end
