#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os

# 간단한 PDF 생성 (reportlab 없이)
# PDF 파일의 기본 구조를 직접 작성
pdf_content = """%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /Resources 4 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>
endobj
4 0 obj
<< /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >>
endobj
5 0 obj
<< /Length 200 >>
stream
BT
/F1 12 Tf
50 700 Td
(Cover Letter Test) Tj
0 -20 Td
(1. Motivation) Tj
0 -20 Td
(I am passionate about software development) Tj
0 -20 Td
(2. Experience) Tj
0 -20 Td
(Various projects during university) Tj
ET
endstream
endobj
xref
0 6
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
0000000230 00000 n
0000000328 00000 n
trailer
<< /Size 6 /Root 1 0 R >>
startxref
597
%%EOF"""

# PDF 파일 저장
with open('test_cover_letter.pdf', 'wb') as f:
    f.write(pdf_content.encode('latin-1'))

print("PDF 파일이 생성되었습니다: test_cover_letter.pdf")
print(f"파일 경로: {os.path.abspath('test_cover_letter.pdf')}")
print(f"파일 크기: {os.path.getsize('test_cover_letter.pdf')} bytes")

