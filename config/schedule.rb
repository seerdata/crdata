every 5.minutes do
  runner "JobsQueue.kill_idle_processing_nodes"
end

every 5.minutes do
  runner "JobsQueue.scale_processing_nodes"
end