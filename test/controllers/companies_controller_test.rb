require "test_helper"

class CompaniesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get companies_index_url
    assert_response :success
  end

  test "should get search" do
    get companies_search_url
    assert_response :success
  end

  test "should get show" do
    get companies_show_url
    assert_response :success
  end

  test "should get crawl" do
    get companies_crawl_url
    assert_response :success
  end
end
