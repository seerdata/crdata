class Notifier < ActionMailer::Base

  def feedback_notification(job, user, message)
    subject       "#{job.description} feedback from #{user.name}"
    from          'CRData <no-replay@crdata.org>'
    recipients    job.r_script.owner.email
    sent_on       Time.now
    body          :job => job, :user => user, :message => message
  end
  
  def activation_instructions(user)
    subject       'CRData Account Activation Instructions'
    from          'CRData <noreply@crdata.org>'
    recipients    user.email
    sent_on       Time.now
    body          :account_activation_url => register_url(user.perishable_token)
  end

  def activation_confirmation(user)
    subject       'CRData Account Activation Complete'
    from          'CRData <noreply@crdata.org>'
    recipients    user.email
    sent_on       Time.now
    body          :root_url => root_url
  end

  def password_reset_instructions(user)  
    subject       'Password Reset Instructions'  
    from          'CRData <noreply@crdata.org>'
    recipients    user.email  
    sent_on       Time.now  
    body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token)  
  end 
 
  def notify_user_of_invite(group_user)  
    subject       "You have been invited to join #{group_user.group.name}"  
    from          'CRData <noreply@crdata.org>'
    recipients    group_user.user.email  
    sent_on       Time.now  
    body          :group_user => group_user  
  end 

  def notify_user_of_approval(group_user)  
    subject       "Your request to join #{group_user.group.name} was approved"  
    from          'CRData <noreply@crdata.org>'
    recipients    group_user.user.email  
    sent_on       Time.now  
    body          :group_user => group_user  
  end 

  def notify_user_of_reject(group_user)  
    subject       "Your request to join #{group_user.group.name} was rejected"  
    from          'CRData <noreply@crdata.org>'
    recipients    group_user.user.email  
    sent_on       Time.now  
    body          :group_user => group_user  
  end 
 
  def notify_user_of_removal(group_user)  
    subject       "Your membership of #{group_user.group.name} was cancelled"  
    from          'CRData <noreply@crdata.org>'
    recipients    group_user.user.email  
    sent_on       Time.now  
    body          :group_user => group_user  
  end 
  
  def notify_user_of_cancel_invite(group_user)  
    subject       "Your invitation to join #{group_user.group.name} was cancelled"  
    from          'CRData <noreply@crdata.org>'
    recipients    group_user.user.email  
    sent_on       Time.now  
    body          :group_user => group_user  
  end 
 
  def notify_user_of_role_change(group_user)  
    subject       "Your role in #{group_user.group.name} was changed to #{group_user.role.name}"  
    from          'CRData <noreply@crdata.org>'
    recipients    group_user.user.email  
    sent_on       Time.now  
    body          :group_user => group_user  
  end 

  def notify_owner_of_user_invitation_accept(group_user)  
    subject       "Your invitation to join #{group_user.group.name} was accepted by #{group_user.user.name}"  
    from          'CRData <noreply@crdata.org>'
    recipients    group_user.group.users.owners.first.email  
    sent_on       Time.now  
    body          :group_user => group_user  
  end 

  def notify_owner_of_user_invitation_decline(group_user)  
    subject       "Your invitation to join #{group_user.group.name} was declined by #{group_user.user.name}"  
    from          'CRData <noreply@crdata.org>'
    recipients    group_user.group.users.owners.first.email  
    sent_on       Time.now  
    body          :group_user => group_user  
  end 
  
  def notify_owner_of_user_request(group_user)  
    subject       "#{group_user.user.name} has requested to join #{group_user.group.name}"  
    from          'CRData <noreply@crdata.org>'
    recipients    group_user.group.users.owners.first.email  
    sent_on       Time.now  
    body          :group_user => group_user  
  end 
 
  def notify_owner_of_user_cancel(group_user)  
    subject       "#{group_user.user.name} has canceled membership of #{group_user.group.name}"  
    from          'CRData <noreply@crdata.org>'
    recipients    group_user.group.users.owners.first.email  
    sent_on       Time.now  
    body          :group_user => group_user  
  end
   
  def notify_jobs_queue_owner_of_processing_node_donation(processing_node)
    subject       "A processing node was donated by #{processing_node.user.name} for #{processing_node.jobs_queue.name}"  
    from          'CRData <noreply@crdata.org>'
    recipients    processing_node.jobs_queue.owner.email  
    sent_on       Time.now  
    body          :processing_node => processing_node  
  end
 
  def notify_processing_node_donor_of_approval(processing_node)
    subject       "The processing node donated by you for #{processing_node.jobs_queue.name} was activated"  
    from          'CRData <noreply@crdata.org>'
    recipients    processing_node.user.email  
    sent_on       Time.now  
    body          :processing_node => processing_node  
  end
 
  def notify_processing_node_donor_of_rejection(processing_node)
    subject       "The processing node donated by you for #{processing_node.jobs_queue.name} can't be activated"  
    from          'CRData <noreply@crdata.org>'
    recipients    processing_node.user.email  
    sent_on       Time.now  
    body          :processing_node => processing_node  
  end

  def thanks_for_processing_node_donation(processing_node)
    subject       'Thank you for your donation'  
    from          'CRData <noreply@crdata.org>'
    recipients    processing_node.user.email  
    sent_on       Time.now  
    body          :processing_node => processing_node  
  end

  def notify_user_of_job_completion(job)
    subject       job.successful ? 'Job was successfully finished.' : 'Job was finished with errors.'  
    from          'CRData <noreply@crdata.org>'
    recipients    job.user.email  
    sent_on       Time.now  
    body          :job => job  
  end
  
  def notify_admins_of_job_that_needs_user_defined_r_packages(job)
    subject       'A job that needs user defined R packages was created'  
    from          'CRData <noreply@crdata.org>'
    recipients    User.site_admins_emails 
    sent_on       Time.now  
    body          :job => job  
  end
  
  def notify_user_that_job_needs_admin_approval(job)
    subject       'You created a job that needs user defined R packages to be installed'  
    from          'CRData <noreply@crdata.org>'
    recipients    job.user
    sent_on       Time.now  
    body          :job => job  
  end
 
  def notify_user_of_job_approval(job)
    subject       "The job #{job.description} was approved"  
    from          'CRData <noreply@crdata.org>'
    recipients    job.user
    sent_on       Time.now  
    body          :job => job  
  end
end
