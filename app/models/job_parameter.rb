class JobParameter < ActiveRecord::Base
  belongs_to :job
  belongs_to :parameter
  belongs_to :data_set

  before_save  {|record| record.value.strip! if record.parameter && %w(Integer Float Enumeration Boolean List).include?(record.parameter.kind)}
  after_create {|record| record.data_set.logs << Log.new(:user_id => record.job.user_id, :job_id => record.job_id, :action_id => Action.find_by_name('use').id) if record.parameter.kind == 'Dataset'}

  def self.save_job_data_set_parameters(user, job_id, r_script_id, data_set_parameters)
    data_set_parameters.each_pair do |parameter_id, data_set_id|
      JobParameter.create(:job_id => job_id, :parameter_id => parameter_id, :data_set_id => data_set_id) if parameter = Parameter.find_by_id(parameter_id) and RScript.find(r_script_id).parameters.include?(parameter) and data_set = DataSet.find_by_id(data_set_id) and (DataSet.public_data_sets.include?(data_set) or user.data_sets.include?(data_set))
    end
  end

  def data_set_url
    if data_set
      if data_set.is_public
        "http://#{data_set.bucket}.s3.amazonaws.com/#{data_set.file_name}"
      elsif data_set.bucket == MAIN_BUCKET 
      s3 = RightAws::S3Interface.new(AWS_ACCESS_KEY, AWS_SECRET_KEY)
      s3.get_link(data_set.bucket, data_set.file_name, 60*60*24)
      elsif data_set.aws_key
        decrypted_aws_key = data_set.aws_key.decrypt
        s3 = RightAws::S3Interface.new(decrypted_aws_key.access_key_id, decrypted_aws_key.secret_access_key)
        s3.get_link(data_set.bucket, data_set.file_name, 60*60*24)
      end    
    else
       nil
    end
  end

  def to_xml(*args)
    super do |xml|
      xml.data_set_url data_set_url
      xml.name parameter.name
      xml.kind parameter.kind
    end
  end

end
