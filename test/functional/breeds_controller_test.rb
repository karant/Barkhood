require 'test_helper'

class BreedsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:breeds)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create breed" do
    assert_difference('Breed.count') do
      post :create, :breed => { }
    end

    assert_redirected_to breed_path(assigns(:breed))
  end

  test "should show breed" do
    get :show, :id => breeds(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => breeds(:one).to_param
    assert_response :success
  end

  test "should update breed" do
    put :update, :id => breeds(:one).to_param, :breed => { }
    assert_redirected_to breed_path(assigns(:breed))
  end

  test "should destroy breed" do
    assert_difference('Breed.count', -1) do
      delete :destroy, :id => breeds(:one).to_param
    end

    assert_redirected_to breeds_path
  end
end
