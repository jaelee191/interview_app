require "test_helper"

class CoverLettersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get cover_letters_index_url
    assert_response :success
  end

  test "should get new" do
    get cover_letters_new_url
    assert_response :success
  end

  test "should get create" do
    get cover_letters_create_url
    assert_response :success
  end

  test "should get show" do
    get cover_letters_show_url
    assert_response :success
  end
end
