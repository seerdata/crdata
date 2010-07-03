class Parameter < ActiveRecord::Base
  belongs_to :r_script
  has_many   :job_parameters, :dependent => :destroy
  has_many   :jobs, :through => :job_parameters

  validates_presence_of :name, :title, :type
  validates_presence_of :min_value, :max_value, :increment_value, :if => Proc.new{|p| p.kind == 'Enumeration'}
  validates_presence_of :default_value, :if => Proc.new{|p| p.kind == 'List'}
  validates_uniqueness_of :name, :title, :scope => :r_script_id, :if => Proc.new{|p| !p.r_script_id.blank?}
  validates_numericality_of :min_value, :max_value, :increment_value, :only_integer => true, :allow_nil => true
  validates_numericality_of :default_value, :only_integer => true, :if => Proc.new{|p| p.kind == 'Integer'}
  validates_numericality_of :default_value, :if => Proc.new{|p| p.kind == 'Float'}
  validate :min_greater_than_max, :if => Proc.new{|p| p.kind == 'Enumeration'}
  
  def check_uniqueness(parameters)
    if !parameters.blank? and Parameter.first(:conditions => ["name = ? AND id IN (#{parameters.join(', ')})", self.name]) 
      errors.add(:name, 'has already been taken')
      return false 
    else
      return true
    end
  end

  private

  def min_greater_than_max
    errors.add(:min_value, 'can\'t be greater than max') if min_value.to_i > max_value.to_i
  end 
end
