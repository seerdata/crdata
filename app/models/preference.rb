class Preference < ActiveRecord::Base
  belongs_to :user
  after_save :delete_notification_acknowledgements
  
  validates_presence_of :kind, :value
  validates_numericality_of :value, :only_integer => true, :if => Proc.new{|p| p.kind == 'time'}

  def delete_notification_acknowledgements
    Preference.destroy_all({:kind => "notification_acknowledge"}) if self.kind == "homepage_notification"
  end
end
