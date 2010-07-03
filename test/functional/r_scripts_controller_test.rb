require 'test_helper'

class RScriptsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:r_scripts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create r_script" do
    assert_difference('RScript.count') do
      post :create, :r_script => { :name => 'Script Test 1', :source_code => 'Source Test 1' }
    end

    assert_redirected_to r_script_path(assigns(:r_script))
  end

  test "should show r_script" do
    get :show, :id => r_scripts(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => r_scripts(:one).to_param
    assert_response :success
  end

  test "should update r_script" do
    put :update, :id => r_scripts(:one).to_param, :r_script => { }
    assert_redirected_to r_script_path(assigns(:r_script))
  end

  test "should destroy r_script" do
    assert_difference('RScript.count', -1) do
      delete :destroy, :id => r_scripts(:one).to_param
    end

    assert_redirected_to r_scripts_path
  end
end
