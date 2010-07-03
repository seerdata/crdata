require 'test_helper'

class JobsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:jobs)
  end

  test "should get new" do
    #get :new
    #assert_response :success
  end

  test "should create job" do
    assert_difference('Job.count') do
      post :create, :job => { :r_script => RScript.first, :description => 'description' }
    end

    assert_redirected_to job_path(assigns(:job))
  end

  test "should show job" do
    get :show, :id => jobs(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => jobs(:one).to_param
    assert_response :success
  end

  test "should update job" do
    put :update, :id => jobs(:one).to_param, :job => { :r_script => RScript.first }
    assert_redirected_to job_path(assigns(:job))
  end

  test "should not destroy job" do
    assert_difference('Job.count', 0) do
      delete :destroy, :id => jobs(:one).to_param
    end

    assert_redirected_to jobs_path
  end

  test "should destroy job" do
    assert_difference('Job.count', -1) do
      delete :destroy, :id => jobs(:three).to_param
    end

    assert_redirected_to jobs_path
  end

  test "should submit job" do
    put :submit, :id => jobs(:new).to_param, :queue => JobsQueue.first.id
    assert_redirected_to job_path(assigns(:job))
  end

  test "should submit job to default queue" do
    put :submit, :id => jobs(:new).to_param
    assert_redirected_to job_path(assigns(:job))
  end

  test "should run job" do
    # First we need to submit the job...
    put :submit, :id => jobs(:new).to_param, :queue => JobsQueue.first.id
    assert_redirected_to job_path(assigns(:job))

    # Now we can run it
    put :run, :id => jobs(:new).to_param, :node => ProcessingNode.first.id
    assert_redirected_to r_script_path(assigns(:job).r_script)
  end

  test "should finish job successfully" do
    # First we need to submit the job...
    put :submit, :id => jobs(:new).to_param, :queue => JobsQueue.first.id
    assert_redirected_to job_path(assigns(:job))

    # Now we can run it
    put :run, :id => jobs(:new).to_param, :node => ProcessingNode.first.id
    assert_redirected_to r_script_path(assigns(:job).r_script)

    # Now we can have it finished!
    put :done, :id => jobs(:new).to_param, :success => true
    assert_redirected_to job_path(assigns(:job))
  end

  test "should finish job unsuccessfully" do
    put :done, :id => jobs(:running).to_param, :success => false
    assert_redirected_to job_path(assigns(:job))
  end

  test "should cancel job" do
    put :cancel, :id => jobs(:one).to_param
    assert_redirected_to job_path(assigns(:job))
  end

  test "should get uploadurls" do
    get :uploadurls, :id => jobs(:one).to_param, :upload_type => 'logs', :files => 'script.log'
    assert_response :success
    assert_not_nil assigns(:job)
    assert_not_nil assigns(:url_list)
    get :uploadurls, :id => jobs(:one).to_param, :upload_type => 'results', :files => ['result.html', 'result.png', 'result.css']
    assert_response :success
    assert_not_nil assigns(:job)
    assert_not_nil assigns(:url_list)
    assert_raise RuntimeError do
      get :uploadurls, :id => jobs(:one).to_param, :upload_type => 'results'
    end
    assert_raise RuntimeError do
      get :uploadurls, :id => jobs(:one).to_param
    end
  end

end

