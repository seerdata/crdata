require 'test_helper'

class JobsQueuesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:jobs_queues)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create jobs_queue" do
    assert_difference('JobsQueue.count') do
      post :create, :jobs_queue => { :name => 'Test Q1' }
    end

    assert_redirected_to jobs_queue_path(assigns(:jobs_queue))
  end

  test "should show jobs_queue" do
    get :show, :id => jobs_queues(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => jobs_queues(:one).to_param
    assert_response :success
  end

  test "should update jobs_queue" do
    put :update, :id => jobs_queues(:one).to_param, :jobs_queue => { :name => 'Test Q2' }
    assert_redirected_to jobs_queue_path(assigns(:jobs_queue))
  end

  test "should destroy jobs_queue" do
    assert_difference('JobsQueue.count', -1) do
      delete :destroy, :id => jobs_queues(:one).to_param
    end

    assert_redirected_to jobs_queues_path
  end

  test "should run job" do
    # First we should fail as there is no job in queue
    put :run_next_job, :id => jobs_queues(:one).to_param, :node => ProcessingNode.first.id
    assert_nil assigns(:job)
    assert_response 404

    # Now we put two jobs in the queue
    q1 = jobs_queues(:one)
    j1 = Job.find 3
    j1.submit(q1)
    j2 = Job.find 8
    j2.submit(q1)

    # Run the firt one - make sure we got the correct one
    put :run_next_job, :id => jobs_queues(:one).to_param, :node => ProcessingNode.first.id
    assert assigns(:job)
    assert assigns(:job) == j1
    assert_redirected_to job_path(j1)

    # Run the firt one - make sure we got the correct one
    put :run_next_job, :id => jobs_queues(:one).to_param, :node => ProcessingNode.first.id
    assert assigns(:job)
    assert assigns(:job) == j2
    assert_redirected_to job_path(j2)

    # Finally, the queue should be empty now
    put :run_next_job, :id => jobs_queues(:one).to_param, :node => ProcessingNode.first.id
    assert_nil assigns(:job)
    assert_response 404

  end

  test "should run job on default queue" do
    # First we should fail as there is no job in queue
    put :run_next_job, :id => JobsQueue.default_queue.to_param, :node => ProcessingNode.first.id
    assert_nil assigns(:job)
    assert_response 404

    # Now we put two jobs in the default queue
    j1 = Job.find 8
    j1.submit
    j2 = Job.find 3
    j2.submit

    # Run the firt one - make sure we got the correct one
    put :run_next_job, :node => ProcessingNode.first.id
    assert assigns(:job)
    assert assigns(:job) == j1
    assert_redirected_to job_path(j1)

    # Run the firt one - make sure we got the correct one
    put :run_next_job, :node => ProcessingNode.first.id
    assert assigns(:job)
    assert assigns(:job) == j2
    assert_redirected_to job_path(j2)

    # Finally, the queue should be empty now
    put :run_next_job, :node => ProcessingNode.first.id
    assert_nil assigns(:job)
    assert_response 404

  end

end
