require 'net/http'
require 'uri'
require 'nokogiri'

url = "https://www.saramin.co.kr/zf_user/jobs/relay/view?rec_idx=51523786&view_type=etc"
uri = URI.parse(url)

# HTTP 요청 설정
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Get.new(uri)
request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
request['Accept-Language'] = 'ko-KR,ko;q=0.9,en;q=0.8'

response = http.request(request)

puts "Status Code: #{response.code}"
puts "Content Type: #{response['Content-Type']}"
puts "Body Length: #{response.body.length}"

# HTML 파싱
doc = Nokogiri::HTML(response.body)

# 타이틀 확인
title = doc.at('title')&.text
puts "Title: #{title}"

# meta 태그 확인
meta_desc = doc.at('meta[name="description"]')&.attr('content')
puts "Meta Description: #{meta_desc}"

# JavaScript 렌더링 필요 여부 확인
if response.body.include?('window.__PRELOADED_STATE__') || response.body.include?('React') || response.body.include?('Vue')
  puts "\n⚠️  JavaScript 렌더링이 필요한 페이지입니다!"
end

# 실제 콘텐츠 확인
if response.body.include?('로그인') || response.body.include?('login')
  puts "\n⚠️  로그인이 필요할 수 있습니다!"
end

# 주요 선택자 테스트
selectors = ['.company_name', '.job_tit', '.recruitment_info', '#content', '.wrap_jview']
selectors.each do |selector|
  element = doc.at(selector)
  if element
    puts "Found #{selector}: #{element.text[0..50]}"
  end
end

# Body의 첫 500자 출력
puts "\nFirst 500 chars of body text:"
body_text = doc.at('body')&.text&.gsub(/\s+/, ' ')&.strip
puts body_text[0..500] if body_text