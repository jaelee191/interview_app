#!/usr/bin/env ruby
require_relative 'config/environment'

cover_letter_id = ARGV[0]

if cover_letter_id.nil?
  puts "사용법: ruby clear_analysis_data.rb [cover_letter_id]"
  puts "예시: ruby clear_analysis_data.rb 61"
  puts "\n또는 모든 분석 데이터 삭제:"
  puts "ruby clear_analysis_data.rb all"
  exit
end

if cover_letter_id == "all"
  print "정말로 모든 Cover Letter의 분석 데이터를 삭제하시겠습니까? (yes/no): "
  confirmation = gets.chomp
  
  if confirmation.downcase == "yes"
    CoverLetter.update_all(
      analysis_result: nil,
      advanced_analysis_json: nil,
      analysis_status: nil,
      analysis_completed_at: nil
    )
    
    # deep_analysis_data에서 analysis 관련 키만 제거
    CoverLetter.find_each do |cl|
      if cl.deep_analysis_data
        cl.deep_analysis_data.delete('analysis_result')
        cl.deep_analysis_data.delete('analysis_sections')
        cl.deep_analysis_data.delete('analyzed_at')
        cl.save
      end
    end
    
    puts "✅ 모든 Cover Letter의 분석 데이터가 삭제되었습니다."
  else
    puts "취소되었습니다."
  end
else
  cl = CoverLetter.find_by(id: cover_letter_id)
  
  if cl
    puts "=" * 60
    puts "Cover Letter #{cl.id} 분석 데이터 삭제"
    puts "=" * 60
    puts "제목: #{cl.title}"
    puts "현재 상태:"
    puts "  - analysis_result: #{cl.analysis_result.present? ? '있음' : '없음'}"
    puts "  - advanced_analysis_json: #{cl.advanced_analysis_json.present? ? '있음' : '없음'}"
    puts "  - analysis_status: #{cl.analysis_status}"
    
    print "\n정말로 삭제하시겠습니까? (yes/no): "
    confirmation = gets.chomp
    
    if confirmation.downcase == "yes"
      # 분석 관련 필드 초기화
      cl.update!(
        analysis_result: nil,
        advanced_analysis_json: nil,
        analysis_status: nil,
        analysis_completed_at: nil,
        analysis_error: nil
      )
      
      # deep_analysis_data에서 분석 관련 키만 제거 (PDF 데이터는 유지)
      if cl.deep_analysis_data
        cl.deep_analysis_data.delete('analysis_result')
        cl.deep_analysis_data.delete('analysis_sections')
        cl.deep_analysis_data.delete('analyzed_at')
        cl.save
      end
      
      puts "\n✅ Cover Letter #{cl.id}의 분석 데이터가 삭제되었습니다."
      puts "\n삭제 후 상태:"
      puts "  - analysis_result: #{cl.analysis_result.present? ? '있음' : '없음'}"
      puts "  - advanced_analysis_json: #{cl.advanced_analysis_json.present? ? '있음' : '없음'}"
      puts "  - PDF 데이터: #{cl.deep_analysis_data && cl.deep_analysis_data['pdf_analysis'] ? '유지됨' : '없음'}"
    else
      puts "취소되었습니다."
    end
  else
    puts "❌ Cover Letter #{cover_letter_id}를 찾을 수 없습니다."
  end
end