class Comment < ActiveRecord::Base
  include ActsAsCommentable::Comment

  belongs_to :user
  belongs_to :commentable, :polymorphic => true

  validates_presence_of   :title, :comment
  validates_uniqueness_of :user_id, :scope => [:commentable_type, :commentable_id]

  default_scope :order => 'created_at ASC'

end
