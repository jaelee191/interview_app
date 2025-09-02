class AddRawPdfTextToCoverLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :cover_letters, :raw_pdf_text, :text
  end
end
