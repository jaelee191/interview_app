#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'base64'

# PDF 파일 읽기 및 Base64 인코딩
pdf_content = File.read('test_resume.pdf', mode: 'rb')
pdf_base64 = Base64.strict_encode64(pdf_content)
pdf_data_uri = "data:application/pdf;base64,#{pdf_base64}"

# POST 데이터 준비
params = {
  'cover_letter' => {
    'user_name' => '홍길동',
    'company_name' => '삼성전자',
    'position' => '소프트웨어 개발',
    'title' => 'PDF 업로드 테스트',
    'content' => '안녕하세요. 저는 컴퓨터공학을 전공한 신입 개발자입니다. 
    
    대학에서 다양한 프로젝트를 수행하며 실무 경험을 쌓았습니다.
    특히 Spring Boot를 활용한 백엔드 개발과 React를 이용한 프론트엔드 개발에 관심이 많습니다.
    
    귀사의 소프트웨어 개발 직무에 지원하게 되어 영광입니다.',
    'pdf_content' => pdf_data_uri
  }
}

# HTTP 요청 설정
uri = URI('http://localhost:3004/cover_letters/analyze_advanced')
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/x-www-form-urlencoded'

# 파라미터를 URL 인코딩
form_data = URI.encode_www_form(
  'cover_letter[user_name]' => params['cover_letter']['user_name'],
  'cover_letter[company_name]' => params['cover_letter']['company_name'],
  'cover_letter[position]' => params['cover_letter']['position'],
  'cover_letter[title]' => params['cover_letter']['title'],
  'cover_letter[content]' => params['cover_letter']['content'],
  'cover_letter[pdf_content]' => pdf_data_uri
)
request.body = form_data

# 요청 전송
puts "Sending request to analyze_advanced with PDF..."
puts "PDF file size: #{pdf_content.bytesize} bytes"
puts "Base64 size: #{pdf_base64.bytesize} bytes"

begin
  response = http.request(request)
  
  puts "\nResponse Code: #{response.code}"
  puts "Response Message: #{response.message}"
  
  if response.code == '302' || response.code == '303'
    puts "Redirect to: #{response['Location']}"
    puts "✅ PDF 업로드 및 분석 요청 성공!"
  else
    puts "Response Body (first 500 chars):"
    puts response.body[0..500] if response.body
  end
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(5)
end