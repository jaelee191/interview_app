namespace :pdf do
  desc "Verify PDF parsing for cover letter extraction"
  task verify_parsing: :environment do
    pdf_path = ENV['PDF_PATH'] || '/Users/macmac/Downloads/김지애_이력서 2025.pdf'
    
    unless File.exist?(pdf_path)
      puts "❌ PDF 파일을 찾을 수 없습니다: #{pdf_path}"
      puts "사용법: rails pdf:verify_parsing PDF_PATH=/path/to/pdf"
      exit 1
    end
    
    puts "📄 PDF 분석 시작: #{File.basename(pdf_path)}"
    puts "=" * 60
    
    service = PdfAnalyzerService.new(pdf_path)
    result = service.analyze_resume
    
    if result[:error]
      puts "❌ 오류 발생: #{result[:error]}"
      exit 1
    end
    
    # 메타데이터 출력
    puts "\n📊 PDF 메타데이터"
    puts "-" * 40
    puts "전체 페이지 수: #{result[:metadata][:page_count]}"
    puts "이력서 페이지: #{result[:metadata][:resume_pages].inspect}"
    puts "자소서 페이지: #{result[:metadata][:cover_letter_pages].inspect}"
    puts "자소서 포함: #{result[:metadata][:has_cover_letter] ? '✅ 있음' : '❌ 없음'}"
    puts "전체 단어 수: #{result[:metadata][:word_count]}"
    
    # 이력서 부분
    puts "\n📝 이력서 내용"
    puts "-" * 40
    if result[:structured_content][:resume][:text].present?
      resume_text = result[:structured_content][:resume][:text]
      puts "길이: #{resume_text.length}자"
      puts "첫 200자:"
      puts resume_text.first(200)
      puts "..."
    else
      puts "❌ 이력서를 찾을 수 없습니다"
    end
    
    # 자소서 부분
    puts "\n✍️  자기소개서 내용"
    puts "-" * 40
    if result[:original_cover_letter].present?
      cover_letter_text = result[:original_cover_letter]
      puts "길이: #{cover_letter_text.length}자"
      puts "첫 300자:"
      puts cover_letter_text.first(300)
      puts "..."
      
      # 자소서 패턴 검증
      puts "\n🔍 자소서 패턴 검증:"
      patterns = {
        "지원동기" => /지원\s*동기/i,
        "성장과정" => /성장\s*과정/i,
        "협업경험" => /협업\s*경험/i,
        "자기소개서" => /자기소개서/i
      }
      
      patterns.each do |name, pattern|
        if cover_letter_text =~ pattern
          puts "  ✅ #{name} 발견"
        else
          puts "  ⚠️  #{name} 미발견"
        end
      end
    else
      puts "❌ 자기소개서를 찾을 수 없습니다"
    end
    
    # 성공 여부 판단
    puts "\n" + "=" * 60
    if result[:metadata][:has_cover_letter] && result[:original_cover_letter].present?
      puts "✅ PDF 파싱 성공: 이력서와 자소서가 모두 정상적으로 추출되었습니다."
    elsif !result[:metadata][:has_cover_letter]
      puts "⚠️  자소서가 포함되지 않은 PDF입니다."
    else
      puts "❌ PDF 파싱 실패: 자소서 추출에 문제가 있습니다."
    end
  end
  
  desc "Test PDF parsing and save to cover letter"
  task test_save: :environment do
    pdf_path = ENV['PDF_PATH'] || '/Users/macmac/Downloads/김지애_이력서 2025.pdf'
    cover_letter_id = ENV['LETTER_ID'] || 30
    
    unless File.exist?(pdf_path)
      puts "❌ PDF 파일을 찾을 수 없습니다: #{pdf_path}"
      exit 1
    end
    
    letter = CoverLetter.find_by(id: cover_letter_id)
    unless letter
      puts "❌ Cover Letter ID #{cover_letter_id}를 찾을 수 없습니다"
      exit 1
    end
    
    puts "📄 PDF 분석 및 저장 테스트"
    puts "=" * 60
    
    service = PdfAnalyzerService.new(pdf_path)
    result = service.analyze_resume
    
    if result[:metadata][:has_cover_letter] && result[:original_cover_letter].present?
      old_content = letter.content
      letter.content = result[:original_cover_letter]
      letter.save!
      
      puts "✅ 자소서 저장 완료!"
      puts "이전 길이: #{old_content&.length || 0}자"
      puts "새 길이: #{letter.content.length}자"
      puts "\n저장된 내용 (첫 300자):"
      puts letter.content.first(300)
    else
      puts "❌ PDF에서 자소서를 찾을 수 없습니다"
    end
  end
end