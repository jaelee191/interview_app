class Admin::UsersController < Admin::BaseController
  def index
    @users = User.order(created_at: :desc).limit(100)
  end

  def show
    @user = User.find(params[:id])
    @cover_letters = @user.cover_letters.order(created_at: :desc)
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "사용자 정보가 업데이트되었습니다."
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :admin)
  end
end