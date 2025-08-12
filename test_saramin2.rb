require 'net/http'
require 'uri'

url = "https://www.saramin.co.kr/zf_user/jobs/relay/view?rec_idx=51523786&view_type=etc"
uri = URI.parse(url)

# 리다이렉트 따라가기
5.times do
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  
  request = Net::HTTP::Get.new(uri)
  request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
  request['Cookie'] = 'RSRVID=web12|aJn7U|aJn7U'
  
  response = http.request(request)
  
  puts "URL: #{uri}"
  puts "Status: #{response.code}"
  puts "Location: #{response['Location']}"
  
  if response.code == '302' || response.code == '301'
    if response['Location']
      new_uri = URI.parse(response['Location'])
      if new_uri.host
        uri = new_uri
      else
        uri = URI.parse("https://#{uri.host}#{response['Location']}")
      end
    else
      break
    end
  else
    puts "Final URL: #{uri}"
    puts "Body size: #{response.body.length}"
    puts "Body preview: #{response.body[0..200]}"
    break
  end
end