module PreferencesHelper
  def formatted_queues(queues)
    formatted_queues = {}
    mark_paused_jobs_queues(queues).collect{|job_queue| formatted_queues.merge!({job_queue.name => job_queue.id.to_s})}
    formatted_queues
  end
end
