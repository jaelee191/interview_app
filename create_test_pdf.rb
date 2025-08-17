require 'prawn'

Prawn::Document.generate("test_resume.pdf") do
  font_families.update("NanumGothic" => {
    :normal => "/System/Library/Fonts/Helvetica.ttc",
  })
  
  text "Resume - Hong Gildong", size: 20, style: :bold
  move_down 20
  
  text "Personal Information", size: 16, style: :bold
  text "Name: Hong Gildong"
  text "Email: hong@example.com"
  text "Phone: 010-1234-5678"
  move_down 15
  
  text "Education", size: 16, style: :bold
  text "2020-2024: Seoul National University, Computer Science"
  move_down 15
  
  text "Experience", size: 16, style: :bold
  text "2023.06-2023.08: ABC Company Intern (Backend Developer)"
  text "- Developed REST API using Spring Boot"
  text "- Designed and optimized MySQL database"
  move_down 15
  
  text "Technical Skills", size: 16, style: :bold
  text "Languages: Java, Python, JavaScript"
  text "Frameworks: Spring Boot, Django, React"
  text "Database: MySQL, PostgreSQL, MongoDB"
  move_down 15
  
  text "Projects", size: 16, style: :bold
  text "1. E-commerce Platform"
  text "   - Role: Backend Developer"
  text "   - Tech: Spring Boot, MySQL, Redis"
  text "   - Achievement: 30% performance improvement"
  move_down 10
  
  text "2. AI Chatbot Service"
  text "   - Role: Full-stack Developer"
  text "   - Tech: Python, React, OpenAI API"
  text "   - Achievement: 85% user satisfaction"
  move_down 15
  
  text "Certifications", size: 16, style: :bold
  text "- Information Processing Engineer (2023.05)"
  text "- SQLD (2023.11)"
end

puts "Test PDF created successfully!"