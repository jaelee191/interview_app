#!/usr/bin/env ruby

require_relative 'config/environment'

# Test PDF extraction service with debug
pdf_path = "test_cover_letter.pdf"

if File.exist?(pdf_path)
  puts "Testing PDF extraction for: #{pdf_path}"
  puts "File size: #{File.size(pdf_path)} bytes"
  puts "=" * 50
  
  service = PdfAnalyzerService.new(pdf_path)
  result = service.analyze_resume
  
  if result[:error]
    puts "\n❌ Error occurred:"
    puts result[:error]
    puts "\nError message: #{result[:message]}" if result[:message]
  else
    puts "\n✅ Extraction successful!"
    puts "Raw text length: #{result[:raw_pdf_text]&.length || 0}"
  end
  
  # Try direct Python execution
  puts "\n" + "=" * 50
  puts "Testing direct Python extraction:"
  
  python_result = `python3 lib/python/korean_text_analyzer.py "#{pdf_path}" 2>&1`
  puts python_result
else
  puts "Error: PDF file not found at #{pdf_path}"
end