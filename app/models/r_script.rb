class RScript < ActiveRecord::Base
  acts_as_taggable
  acts_as_commentable
  acts_as_tsearch :fields => ['name', 'description']
  ajaxful_rateable :dimensions => R_SCRIPT_DIMENSIONS.keys, :stars => RATING_STARS 
  attr_accessor :file

  has_many :jobs
  has_many :parameters, :dependent => :destroy
  has_many :accesses, :as => :accessable, :dependent => :destroy
  has_many :logs, :as => :logable, :dependent => :destroy, :order => 'created_at DESC'

  validates_uniqueness_of :name, :case_sensitive => false
  validates_presence_of   :name, :source_code

  before_save 'self.tag_list.collect!{|tag| tag.downcase}' 

  def self.get_r_scripts(user, criteria)
    if !criteria[:search].blank?
      records = find_by_tsearch(criteria[:search], 
        :select => 'DISTINCT(r_scripts.*)', 
        :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['(r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?))', user], 
        :order => get_sort_criteria(criteria[:sort]))
      records = records.paginate(:page => criteria[:page], :per_page => ITEMS_PER_PAGE) unless criteria[:show] 
    elsif criteria[:tag]
      records = find_tagged_with(criteria[:tag], 
        :select => 'DISTINCT(r_scripts.*)', 
        :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?)', user], 
        :order => get_sort_criteria(criteria[:sort]))
      records = paginate_tagged_with(criteria[:tag], 
        :select => 'DISTINCT(r_scripts.*)', 
        :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?)', user], 
        :order => get_sort_criteria(criteria[:sort]), 
        :page => criteria[:page], 
        :per_page => ITEMS_PER_PAGE, 
        :total_entries => records.size
      ) unless criteria[:show]
    else
      if criteria[:show]
        records = all(:select => 'DISTINCT(r_scripts.*)', 
          :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['(r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?))', user], 
          :order => get_sort_criteria(criteria[:sort]))
      else
        records = paginate(:select => 'DISTINCT(r_scripts.*)', 
          :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?)', user], 
          :order => get_sort_criteria(criteria[:sort]), 
          :page => criteria[:page], 
          :per_page => ITEMS_PER_PAGE)  
      end
    end
    records
  end
 
  def self.get_r_scripts_for_select(user)
    r_scripts = nil
    selected = false
    if !count_public.zero?
      r_scripts = public_r_scripts.paginate(:page => 1, :per_page => SELECT_ITEMS_PER_PAGE)
      selected = 'public'
    elsif user and !user.groups.default.first.count_r_scripts.zero?
      r_scripts = user.groups.default.first.r_scripts.paginate(:page => 1, :per_page => SELECT_ITEMS_PER_PAGE)
      selected = 'private'
    elsif user and !user.groups.not_default.blank?
      user.groups.each do |group|
        if !group.count_r_scripts.zero?
          r_scripts = group.r_scripts.paginate(:page => 1, :per_page => SELECT_ITEMS_PER_PAGE)
          selected = group_id
          break
        end
      end
    end
    [r_scripts, selected]
  end
  
  def self.get_selected_r_scripts(user, type, id, view, page)
    r_scripts = nil
    if type == 'public'
      r_scripts = public_r_scripts
      r_scripts = r_scripts.paginate(:page => page,  :per_page => SELECT_ITEMS_PER_PAGE) unless view
      tags = RScript.tag_counts(:conditions => 'is_public IS TRUE', :limit => TAG_CLOUD_SIZE) 
    elsif type == 'private' and user 
      r_scripts = user.groups.default.first.r_scripts
      r_scripts = r_scripts.paginate(:page => page,  :per_page => SELECT_ITEMS_PER_PAGE) unless view
      tags = RScript.tag_counts(:joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id', 
        :conditions => ['accesses.accessable_type = \'RScript\' AND accesses.group_id = ?', user.groups.default.first.id],
        :limit => TAG_CLOUD_SIZE) 
    elsif type == 'group' and user and group = Group.find_by_id(id)
      r_scripts = group.r_scripts
      r_scripts = r_scripts.paginate(:page => page,  :per_page => SELECT_ITEMS_PER_PAGE) unless view
      tags = RScript.tag_counts(:joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id', 
        :conditions => ['accesses.accessable_type = \'RScript\' AND accesses.group_id = ?', group.id],
        :limit => TAG_CLOUD_SIZE) 
    elsif type == 'tag'
      r_scripts = find_tagged_with(id, 
        :select => 'DISTINCT(r_scripts.*)', 
        :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['accesses.accessable_type = \'RScript\' AND (r_scripts.is_public IS TRUE OR group_users.user_id = ?)', user],
        :order => 'r_scripts.updated_at DESC'
      )
      r_scripts = r_scripts.paginate(:page => page,  :per_page => SELECT_ITEMS_PER_PAGE) unless view
      tags = nil
    elsif type == 'search' and !id.blank?
      r_scripts = find_by_tsearch(id, 
        :select => 'DISTINCT(r_scripts.*)', 
        :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['(r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?))', user],
        :order => 'r_scripts.updated_at DESC'
      )
      r_scripts.concat(self.find(:all, :select => "DISTINCT(r_scripts.*)",
          :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id LEFT JOIN taggings on taggings.taggable_id = r_scripts.id LEFT join tags on tags.id = taggings.tag_id',
          :conditions => ["(r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = E'%s')) AND (r_scripts.name ILIKE '%%%s%%' OR (tags.name ILIKE '%%%s%%' AND taggings.taggable_type = 'RScript'))", (user.id rescue 0), id, id],
          :order => 'r_scripts.updated_at DESC'
        ))
      r_scripts = r_scripts.uniq.paginate(:page => page,  :per_page => SELECT_ITEMS_PER_PAGE) unless view
      tags = nil
    elsif type == 'all'
      r_scripts = all(:select => 'DISTINCT(r_scripts.*)', 
        :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?)', user],
        :order => 'r_scripts.updated_at DESC'
      )  
      r_scripts = r_scripts.paginate(:page => page,  :per_page => SELECT_ITEMS_PER_PAGE) unless view
      tags = RScript.tag_counts(:joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['(r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?))', user],
        :limit => TAG_CLOUD_SIZE) 
    end
    [r_scripts, tags]
  end
 
  def self.public_r_scripts
    all(:conditions => 'is_public IS TRUE', :order => 'r_scripts.updated_at DESC')
  end

  def self.count_public
    count(:conditions => 'is_public IS TRUE')
  end

  def self.get_user_rscripts(user,arguments, is_super_admin=false)
    if !arguments[:search].blank?
      records = find_by_tsearch(arguments[:search],
        :select => 'DISTINCT(r_scripts.*)',
        :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id',
        :conditions => ["(#{is_super_admin ? nil : 'is_public = true AND ' }accesses.accessable_type = 'RScript' AND accesses.group_id = ?)", user.groups.default.first.id],
        :order => get_sort_criteria(arguments[:sort]))
    
      records.concat(self.find(:all, :select => "DISTINCT(r_scripts.*)",
          :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id LEFT JOIN taggings on taggings.taggable_id = r_scripts.id LEFT join tags on tags.id = taggings.tag_id',
          :conditions => ["(#{is_super_admin ? nil : 'is_public = true AND' } accesses.accessable_type = 'RScript' AND accesses.group_id = ?) AND (r_scripts.name ILIKE '%%%s%%' OR (tags.name ILIKE '%%%s%%' AND taggings.taggable_type = 'RScript'))", (user.groups.default.first.id), arguments[:search], arguments[:search]],
          :order => get_sort_criteria(arguments[:sort])))
       
    else
      records = find(:all, :select => "DISTINCT(r_scripts.*)", :joins => "LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id",
        :conditions => ["#{is_super_admin ? nil : 'is_public = true AND' } accesses.accessable_type = 'RScript' AND accesses.group_id = ?",user.groups.default.first.id],
        :order => get_sort_criteria(arguments[:sort]))
    end
    records = records.uniq
    records = records.paginate(:page => (arguments[:page] || 1),  :per_page => SELECT_ITEMS_PER_PAGE) unless arguments[:show]
    
    return records

  end

  def link_parameters(parameters)
    parameters.each do |parameter_id|
      parameter = Parameter.find_by_id(parameter_id)
      self.parameters << parameter if parameter
    end
    self.save
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
    User.first(:joins => 'LEFT JOIN group_users ON users.id = group_users.user_id LEFT JOIN groups ON group_users.group_id = groups.id LEFT JOIN accesses ON groups.id = accesses.group_id', 
               :conditions => ['groups.is_default IS TRUE AND accesses.accessable_id = ? AND accesses.accessable_type = \'RScript\'', id]
    )
  end

  def has_data_set_parameters?
    parameters.first(:conditions => "kind = 'Dataset'")
  end

  def self.count_remaining_data_set_parameters(r_script_id, data_set_parameters)
    find(r_script_id).parameters.count(:conditions => "kind = 'Dataset'" + (data_set_parameters.blank? ? "" : "AND id NOT IN (#{data_set_parameters.keys.join(',')})"))
  end
  
  def self.get_next_data_set_parameter(r_script_id, data_set_parameters)
    find(r_script_id).parameters.first(:conditions => "kind = 'Dataset'" + (data_set_parameters.blank? ? "" : "AND id NOT IN (#{data_set_parameters.keys.join(',')})"))
  end

  def count_steps
    parameters.count(:conditions => "kind = 'Dataset'") + 2 
  end

  private

  # Get the sort criteria for r_scripts
  def self.get_sort_criteria(sort)
    case sort
    when 'id'                   then 'id'
    when 'name'                 then 'name'
    when 'effort_level'         then 'effort_level'
    when 'id_reverse'           then 'id DESC'
    when 'name_reverse'         then 'name DESC'
    when 'effort_level_reverse' then 'effort_level DESC'
    else 'updated_at DESC'
    end
  end
end
