class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def naver
    @user = User.from_omniauth(request.env["omniauth.auth"])
    
    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "네이버") if is_navigational_format?
    else
      session["devise.naver_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url
    end
  end
  
  def failure
    redirect_to root_path, alert: "로그인에 실패했습니다."
  end
end