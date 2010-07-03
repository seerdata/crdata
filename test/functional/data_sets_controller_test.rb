require 'test_helper'

class DataSetsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_sets)
  end

  test "should get new" do
    #get :new
    #assert_response :success
  end

  test "should create data_set" do
    assert_difference('DataSet.count') do
      post :create, :data_set => { :name => 'Test Set 1'}, 'Filedata' =>  fixture_file_upload('files/dataset.txt','text/plain') 
    end

    assert_response :success
  end

  test "should show data_set" do
    get :show, :id => data_sets(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => data_sets(:one).to_param
    assert_response :success
  end

  test "should update data_set" do
    put :update, :id => data_sets(:one).to_param, :data_set => { :name => 'Updated Name' }
    assert_redirected_to data_set_path(assigns(:data_set))
  end

  test "should destroy data_set" do
    assert_difference('DataSet.count', -1) do
      delete :destroy, :id => data_sets(:one).to_param
    end

    assert_redirected_to data_sets_path
  end
end
