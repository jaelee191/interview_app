class Admin::CoverLettersController < Admin::BaseController
  def index
    @cover_letters = CoverLetter.includes(:user).order(created_at: :desc).limit(100)
  end

  def show
    @cover_letter = CoverLetter.find(params[:id])
  end

  def destroy
    @cover_letter = CoverLetter.find(params[:id])
    @cover_letter.destroy
    redirect_to admin_cover_letters_path, notice: "자소서가 삭제되었습니다."
  end
end
