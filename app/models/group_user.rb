class GroupUser < ActiveRecord::Base
  include AASM

  belongs_to :user
  belongs_to :group
  belongs_to :role

  aasm_column :status
  aasm_initial_state :created
  aasm_state :created
  aasm_state :requested,        :enter => Proc.new {|group_user| Notifier.deliver_notify_owner_of_user_request(group_user)}
  aasm_state :invited,          :enter => Proc.new {|group_user| Notifier.deliver_notify_user_of_invite(group_user)}
  aasm_state :approved,         :enter => :approve
  aasm_state :rejected,         :enter => Proc.new {|group_user| Notifier.deliver_notify_user_of_reject(group_user)}
  aasm_state :cancelled,        :enter => Proc.new {|group_user| Notifier.deliver_notify_owner_of_user_cancel(group_user)}
  aasm_state :removed,          :enter => Proc.new {|group_user| Notifier.deliver_notify_user_of_removal(group_user)}
  aasm_state :invite_cancelled, :enter => Proc.new {|group_user| Notifier.deliver_notify_user_of_cancel_invite(group_user)}
  aasm_state :invite_declined,  :enter => Proc.new {|group_user| Notifier.deliver_notify_owner_of_user_invitation_decline(group_user)}
  
  aasm_event :approve do
    transitions :to => :approved, :from => [:created, :invited, :requested]
  end
 
  aasm_event :reject do
    transitions :to => :rejected, :from => [:requested]
  end

  aasm_event :invite do
    transitions :to => :invited, :from => [:created, :removed, :invite_cancelled]
  end
 
  aasm_event :request do
    transitions :to => :requested, :from => [:created, :cancelled, :invite_declined]
  end
 
  aasm_event :cancel_invite do
    transitions :to => :invite_cancelled, :from => [:invited]
  end
  
  aasm_event :decline do
    transitions :to => :invite_declined, :from => [:invited]
  end
 
  aasm_event :leave do
    transitions :to => :cancelled, :from => [:approved]
  end
  
  aasm_event :remove do
    transitions :to => :removed, :from => [:approved]
  end

  def self.invite_user(parameters)
   if user = User.find_by_email(parameters[:email].downcase)
     if group_user = GroupUser.first(:conditions => ['group_id = ?  AND user_id = ?', parameters[:group_user][:group_id], user.id])
        if ['removed', 'invite_cancelled'].include?(group_user.status)
          group_user.invite!
          return group_user
        elsif group_user.status == 'approved'
          raise 'This user is already a member'
        else
          raise 'You cannot invite this user'
        end
      else
        group_user = GroupUser.new(parameters[:group_user])
        group_user.user = user
        group_user.role = Role.find_by_name('User')
        group_user.save!
        group_user.invite!
        return group_user 
      end
    else
      raise 'There are no users with this email address. Please try again.'
    end
  end

  private

  def approve
    if status == 'requested'
      Notifier.deliver_notify_user_of_approval(self)
    elsif status == 'invited'
      Notifier.deliver_notify_owner_of_user_invitation_accept(self)
    end
  end
end
