#!/usr/bin/env ruby
require 'playwright'

puts "Testing Playwright setup..."

begin
  Playwright.create(playwright_cli_executable_path: './node_modules/.bin/playwright') do |playwright|
    puts "✅ Playwright initialized"
    
    chromium = playwright.chromium
    puts "✅ Chromium driver loaded"
    
    browser = chromium.launch(headless: true)
    puts "✅ Browser launched"
    
    page = browser.new_page
    puts "✅ New page created"
    
    page.goto("https://www.google.com")
    puts "✅ Navigated to Google"
    
    title = page.title
    puts "✅ Page title: #{title}"
    
    browser.close
    puts "✅ Browser closed"
  end
  
  puts "\n🎉 Playwright is working correctly!"
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end