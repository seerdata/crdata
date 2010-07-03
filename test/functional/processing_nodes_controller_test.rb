require 'test_helper'

class ProcessingNodesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:processing_nodes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create processing_node" do
    assert_difference('ProcessingNode.count') do
      post :create, :processing_node => { :ip_address => 'Address Test 1', :node_identifier => 'Node ID Test 1', :active => true }
    end

    assert_redirected_to processing_node_path(assigns(:processing_node))
  end

  test "should show processing_node" do
    get :show, :id => processing_nodes(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => processing_nodes(:one).to_param
    assert_response :success
  end

  test "should update processing_node" do
    put :update, :id => processing_nodes(:one).to_param, :processing_node => { }
    assert_redirected_to processing_node_path(assigns(:processing_node))
  end

  test "should destroy processing_node" do
    assert_difference('ProcessingNode.count', -1) do
      delete :destroy, :id => processing_nodes(:one).to_param
    end

    assert_redirected_to processing_nodes_path
  end
end
