require 'playwright'

url = "https://www.saramin.co.kr/zf_user/jobs/relay/view?rec_idx=51523786&view_type=etc"

begin
  puts "Playwright 테스트 시작..."
  
  Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
    playwright.chromium.launch(headless: true) do |browser|
      puts "브라우저 시작됨"
      
      page = browser.new_page
      puts "페이지 생성됨"
      
      page.goto(url, waitUntil: 'networkidle')
      puts "페이지 로드됨: #{page.url}"
      
      # 대기
      sleep(2)
      
      # 제목 확인
      title = page.title
      puts "페이지 제목: #{title}"
      
      # HTML 가져오기
      html = page.content
      require 'nokogiri'
      doc = Nokogiri::HTML(html)
      
      # 회사명 찾기
      company = doc.at('.company_name a, .co_name a, [class*="company"]')&.text&.strip
      puts "회사명: #{company}"
      
      # 직무명 찾기  
      position = doc.at('.job_tit .tit, h1.tit_job, [class*="job_tit"]')&.text&.strip
      puts "직무명: #{position}"
      
      # 페이지 텍스트 일부
      body_text = doc.text[0..500]
      puts "페이지 내용 (500자): #{body_text}"
    end
  end
  
  puts "테스트 완료!"
rescue => e
  puts "에러 발생: #{e.message}"
  puts e.backtrace.first(5)
end