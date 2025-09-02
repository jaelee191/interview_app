#!/usr/bin/env ruby

require_relative 'config/environment'

# Test PDF extraction service
pdf_path = "test_cover_letter.pdf"

if File.exist?(pdf_path)
  puts "Testing PDF extraction for: #{pdf_path}"
  puts "=" * 50
  
  service = PdfAnalyzerService.new(pdf_path)
  result = service.analyze_resume
  
  puts "\n📄 Analysis Result Keys:"
  puts result.keys.inspect
  
  puts "\n📝 Raw PDF Text (first 500 chars):"
  if result[:raw_pdf_text]
    puts result[:raw_pdf_text][0..500]
    puts "\nTotal length: #{result[:raw_pdf_text].length} characters"
  else
    puts "No raw PDF text extracted"
  end
  
  puts "\n📊 Metadata:"
  if result[:metadata]
    puts "Has Cover Letter: #{result[:metadata][:has_cover_letter]}"
    puts "Has Resume: #{result[:metadata][:has_resume]}"
    puts "Document Type: #{result[:metadata][:document_type]}"
  end
  
  puts "\n💼 Original Cover Letter (first 500 chars):"
  if result[:original_cover_letter]
    puts result[:original_cover_letter][0..500]
    puts "\nTotal length: #{result[:original_cover_letter].length} characters"
  else
    puts "No cover letter found"
  end
  
  puts "\n📋 Original Resume (first 500 chars):"
  if result[:original_resume]
    puts result[:original_resume][0..500]
    puts "\nTotal length: #{result[:original_resume].length} characters"
  else
    puts "No resume found"
  end
  
  puts "\n✅ Test completed successfully!"
else
  puts "Error: PDF file not found at #{pdf_path}"
end