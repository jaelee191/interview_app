class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!
  layout 'admin'

  private

  def authenticate_admin!
    redirect_to root_path, alert: "권한이 없습니다." unless current_user&.admin?
  end
end