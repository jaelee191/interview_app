require './config/environment'

url = "https://www.saramin.co.kr/zf_user/jobs/relay/view?rec_idx=51523786&view_type=etc"

puts "Testing JobPostingCache..."
begin
  # 캐시 테스트
  result = JobPostingCache.fetch(url)
  puts "Fetch result: #{result.inspect}"
  
  # Store 테스트
  JobPostingCache.store(url, "test content")
  puts "Store succeeded"
rescue => e
  puts "Cache error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

puts "\nTesting JobPostingAnalyzerService..."
begin
  service = JobPostingAnalyzerService.new
  puts "Service created"
  
  # fetch_job_posting_content 테스트
  content = service.send(:fetch_job_posting_content, url)
  puts "Content fetched: #{content ? content.length : 'nil'} chars"
rescue => e
  puts "Service error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end