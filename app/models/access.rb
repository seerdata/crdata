class Access < ActiveRecord::Base
  belongs_to :group
  belongs_to :accessable, :polymorphic => true
end
