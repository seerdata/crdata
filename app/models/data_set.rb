class DataSet < ActiveRecord::Base
  acts_as_taggable
  acts_as_commentable
  acts_as_tsearch :fields => ['name', 'description']
  ajaxful_rateable :dimensions => DATASET_DIMENSIONS.keys, :stars => RATING_STARS
  
  belongs_to :aws_key
  has_many :job_parameters, :dependent => :destroy
  has_many :jobs, :through => :job_parameters
  has_many :accesses, :as => :accessable, :dependent => :destroy
  has_many :logs, :as => :logable, :dependent => :destroy, :order => 'created_at DESC'

  validates_uniqueness_of :name, :case_sensitive => false
  validates_presence_of   :name 

  before_save 'self.tag_list.collect!{|tag| tag.downcase}' 

  def self.get_data_sets(user, criteria)
    if !criteria[:search].blank?
      records = find_match_by_tsearch(criteria[:search],
        {:select => 'DISTINCT(data_sets.*)',
        :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['(data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?))', user], 
        :order => get_sort_criteria(criteria[:sort])}, {})
      records = records.paginate(:page => criteria[:page], :per_page => ITEMS_PER_PAGE) unless criteria[:show] 
    elsif criteria[:tag]
      records = find_tagged_with(criteria[:tag], 
        :select => 'DISTINCT(data_sets.*)', 
        :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?)', user], 
        :order => get_sort_criteria(criteria[:sort]))
      records = paginate_tagged_with(criteria[:tag], 
        :select => 'DISTINCT(data_sets.*)', 
        :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?)', user], 
        :order => get_sort_criteria(criteria[:sort]), 
        :page => criteria[:page], 
        :per_page => ITEMS_PER_PAGE, 
        :total_entries => records.size
      ) unless criteria[:show]
    else
      if criteria[:show]
        records = all(:select => 'DISTINCT(data_sets.*)', 
          :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['(data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?))', user], 
          :order => get_sort_criteria(criteria[:sort]))
      else
        records = paginate(:select => 'DISTINCT(data_sets.*)', 
          :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?)', user], 
          :order => get_sort_criteria(criteria[:sort]), 
          :page => criteria[:page], 
          :per_page => ITEMS_PER_PAGE)  
      end
    end
    records
  end
 
  def self.public_data_sets
    all(:conditions => 'is_public IS TRUE', :order => 'updated_at DESC')
  end

  def self.count_public
    count(:conditions => 'is_public IS TRUE')
  end

  def self.get_data_sets_for_select(user)
    data_sets = nil
    selected = false
    if !count_public.zero?
      data_sets = public_data_sets.paginate(:page => 1, :per_page => SELECT_ITEMS_PER_PAGE)
      selected = 'public'
    elsif user and !user.groups.default.first.count_data_sets.zero?
      data_sets = user.groups.default.first.data_sets.paginate(:page => 1, :per_page => SELECT_ITEMS_PER_PAGE)
      selected = 'private'
    elsif user and !user.groups.not_default.blank?
      user.groups.each do |group|
        if !group.count_data_sets.zero?
          data_sets = group.data_sets.paginate(:page => 1, :per_page => SELECT_ITEMS_PER_PAGE)
          selected = group_id
          break
        end
      end
    end
    [data_sets, selected]
  end
   
  def self.get_selected_data_sets(user, type, id, view, page)
    data_sets = nil
    if type == 'public'
      data_sets = public_data_sets
      data_sets = data_sets.paginate(:page => page,  :per_page => SELECT_ITEMS_PER_PAGE) unless view
      tags = DataSet.tag_counts(:conditions => 'is_public IS TRUE', :limit => TAG_CLOUD_SIZE) 
    elsif type == 'private' and user 
      data_sets = user.groups.default.first.data_sets
      data_sets = data_sets.paginate(:page => page,  :per_page => SELECT_ITEMS_PER_PAGE) unless view
      tags = DataSet.tag_counts(:joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id', 
        :conditions => ['accesses.accessable_type = \'DataSet\' AND accesses.group_id = ?', user.groups.default.first.id],
        :limit => TAG_CLOUD_SIZE) 
    elsif type == 'group' and user and group = Group.find_by_id(id)
      data_sets = group.data_sets
      data_sets = data_sets.paginate(:page => page,  :per_page => SELECT_ITEMS_PER_PAGE) unless view
      tags = DataSet.tag_counts(:joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id', 
        :conditions => ['accesses.accessable_type = \'DataSet\' AND accesses.group_id = ?', group.id],
        :limit => TAG_CLOUD_SIZE) 
    elsif type == 'tag'
      data_sets = find_tagged_with(id, 
        :select => 'DISTINCT(data_sets.*)', 
        :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['accesses.accessable_type = \'DataSet\' AND (data_sets.is_public IS TRUE OR group_users.user_id = ?)', user],
        :order => 'data_sets.updated_at DESC'
      )
      data_sets = data_sets.paginate(:page => page,  :per_page => SELECT_ITEMS_PER_PAGE) unless view
      tags = nil
    elsif type == 'search' and !id.blank?
      data_sets = find_by_tsearch(id, 
        :select => 'DISTINCT(data_sets.*)', 
        :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['(data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?))', user],
        :order => 'data_sets.updated_at DESC' 
      )
      data_sets.concat(self.find(:all, :select => 'DISTINCT(data_sets.*)',
          :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id LEFT JOIN taggings on taggings.taggable_id = data_sets.id LEFT join tags on tags.id = taggings.tag_id',
          :conditions => ["(data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = E'%s')) AND (data_sets.name ILIKE '%%%s%%' OR (tags.name ILIKE '%%%s%%' AND taggings.taggable_type = 'DataSet'))", (user.id rescue 0), id, id],
        :order => 'data_sets.updated_at DESC'
        ))
      data_sets = data_sets.uniq.paginate(:page => page,  :per_page => SELECT_ITEMS_PER_PAGE) unless view
      tags = nil
    elsif type == 'all'
      data_sets = all(:select => 'DISTINCT(data_sets.*)', 
        :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?)', user],
        :order => 'data_sets.updated_at DESC'
      )  
      data_sets = data_sets.paginate(:page => page,  :per_page => SELECT_ITEMS_PER_PAGE) unless view
      tags = DataSet.tag_counts(:joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
       :conditions => ['(data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?))', user],
       :limit => TAG_CLOUD_SIZE)
    end
    [data_sets, tags] 
  end
 
  def self.get_user_data_sets(user, criteria, is_super_admin=false)
    if !criteria[:search].blank?
      records = find_by_tsearch(criteria[:search],
        :select => 'DISTINCT(data_sets.*)',
        :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id',
        :conditions => ["(#{is_super_admin ? nil : 'is_public = true AND ' }accesses.accessable_type = 'DataSet' AND accesses.group_id = ?)", user.groups.default.first.id],
        :order => get_sort_criteria(criteria[:sort])
      )

      records.concat(self.find(:all, :select => 'DISTINCT(data_sets.*)',
          :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id LEFT JOIN taggings on taggings.taggable_id = data_sets.id LEFT join tags on tags.id = taggings.tag_id',
          :conditions => ["#{is_super_admin ? nil : 'is_public = true AND' } ((accesses.accessable_type = 'DataSet' AND accesses.group_id = E'%s')) AND (data_sets.name ILIKE '%%%s%%' OR (tags.name ILIKE '%%%s%%' AND taggings.taggable_type = 'DataSet'))", (user.groups.default.first.id), criteria[:search], criteria[:search]],
        :order => get_sort_criteria(criteria[:sort])
        ))

    else
      records = all(:select => 'DISTINCT(data_sets.*)',
        :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id',
        :conditions => ["#{is_super_admin ? nil : 'is_public = true AND ' }accesses.accessable_type = \'DataSet\' AND accesses.group_id = ?", user.groups.default.first.id],
        :order => get_sort_criteria(criteria[:sort])
      )  
    end
    records = records.uniq
    records = records.paginate(:page => (criteria[:page] || 1),  :per_page => SELECT_ITEMS_PER_PAGE) unless criteria[:show]
    
    return records
  end
 
  def save_and_upload_file(user, parameters)
    s3_credentials = self.get_s3_credentials(user, parameters) 

    begin 
      AWS::S3::Base.establish_connection!(:access_key_id => s3_credentials['access_key_id'], :secret_access_key => s3_credentials['secret_access_key'])
      raise 'File could not be stored. Please try again' unless AWS::S3::S3Object.store("data/#{uuid = UUID.generate}/#{parameters['Filename']}", parameters['Filedata'], s3_credentials['bucket'], :access => (parameters['visibility'] == 'public') ? 'public_read' : 'private')
      self.file_name = "data/#{uuid}/#{parameters['Filename']}"
      self.bucket = s3_credentials['bucket']
      s3_object = AWS::S3::S3Object.find(file_name, bucket)
      policy = s3_object.acl
      grant = AWS::S3::ACL::Grant.new
      grantee = AWS::S3::ACL::Grantee.new
      grant.grantee = grantee
      grant.permission = 'READ'
      policy.grants << grant
      grantee.type = 'CanonicalUser'
      grantee.id = S3_OWNER_ID
      grantee.display_name = S3_OWNER_DISPLAY_NAME
      s3_object.acl(policy)
      self.aws_key = AwsKey.create(:name => 'Automatically saved key', :user_id => user.id, :access_key_id => s3_credentials['access_key_id'], :secret_access_key => s3_credentials['secret_access_key']) if parameters[:save_aws_keys] and (parameters[:save_aws_keys] == '1') and user and parameters['aws_key'] and (parameters[:aws_key] == 'new_key')
    rescue  Exception => e
      self.errors.add('bucket', e.message)
      return false
    else
      result = self.save
      s3_object.delete unless errors.empty?
    end
    result
    #true
  end

  def save_from_path(parameters)
    raise 'Invalid path' if parameters[:path].blank?
    if parameters[:job_id] and job = Job.find_by_id(parameters[:job_id])
      self.set_visibility(job.user, {:visibility => 'private'})
      self.name = parameters[:name] ? parameters[:name] : "#{job.description} result dataset"
    else
      self.is_public = true
      self.name = parameters[:name] ? parameters[:name] : UUID.generate
    end
    self.bucket = MAIN_BUCKET
    self.file_name = parameters[:path].starts_with?('/') ? parameters[:path].from(1) : parameters[:path]
    self.save
  end
 
  def set_visibility(user, parameters)
    self.accesses.each{|access| access.destroy}
    if parameters['visibility'] == 'public'
      self.is_public = true
    else
      self.is_public = false
      parameters['groups'].delete("") if parameters['groups']
      parameters['groups'].each do |group_id|
        self.accesses << Access.new(:group_id => group_id)
      end unless parameters['groups'].blank?
    end
    self.accesses << Access.new(:group_id => user.groups.default.first.id) if user
    self.save
  end

  def url(parameters = nil)
    if is_public
    "http://#{bucket}.s3.amazonaws.com/#{file_name}"
    elsif bucket == MAIN_BUCKET 
      s3 = RightAws::S3Interface.new(AWS_ACCESS_KEY, AWS_SECRET_KEY)
      s3.get_link(bucket, file_name)
    elsif parameters and parameters[:access_key_id] and parameters[:secret_access_key] 
      s3 = RightAws::S3Interface.new(parameters[:access_key_id], parameters[:secret_access_key])
      s3.get_link(bucket, file_name)
    end    
  end

  def get_s3_credentials(user, parameters) 
    if (parameters[:visibility] == 'public') or (parameters[:storage] == 'temporary') 
      {'access_key_id' => AWS_ACCESS_KEY, 'secret_access_key' => AWS_SECRET_KEY, 'bucket' => MAIN_BUCKET} 
    elsif parameters[:aws_key] and (parameters[:aws_key] != 'new_key') and aws_key = user.aws_keys.find_by_id(parameters[:aws_key].to_i)
      self.aws_key = aws_key
      decrypted_aws_key = aws_key.decrypt
      {'access_key_id' => decrypted_aws_key.access_key_id, 'secret_access_key' => decrypted_aws_key.secret_access_key, 'bucket' => parameters['s3_credentials']['bucket']} 
    else
      parameters['s3_credentials']
    end
  end

  def owner
    User.first(:joins => 'LEFT JOIN group_users ON users.id = group_users.user_id LEFT JOIN groups ON group_users.group_id = groups.id LEFT JOIN accesses ON groups.id = accesses.group_id', 
      :conditions => ['groups.is_default IS TRUE AND accesses.accessable_id = ? AND accesses.accessable_type = \'DataSet\'', id]
    )
  end

  private

  # Get the sort criteria for datasets
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
