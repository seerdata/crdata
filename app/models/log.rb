class Log < ActiveRecord::Base
  belongs_to :user
  belongs_to :job
  belongs_to :action
  belongs_to :logable, :polymorphic => true
end
