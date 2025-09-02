class CoverLetter < ApplicationRecord
  belongs_to :user, optional: true

  # PDF 파일 내용을 임시로 저장할 가상 속성
  attr_accessor :pdf_content

  # Validations - PDF 업로드 시에는 content 없이도 저장 가능
  validates :content, presence: true, unless: :has_pdf_content?

  private

  def has_pdf_content?
    # PDF 관련 필드가 있으면 content 없어도 됨
    pdf_content.present? || resume_content.present? || resume_json.present?
  end
end
