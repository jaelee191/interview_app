#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.enums import TA_LEFT, TA_JUSTIFY
import os

# 한글 폰트 설정
font_paths = [
    '/System/Library/Fonts/Supplemental/AppleGothic.ttc',
    '/System/Library/Fonts/AppleSDGothicNeo.ttc',
    '/Library/Fonts/NanumGothic.ttf',
    '/usr/share/fonts/truetype/nanum/NanumGothic.ttf'
]

font_registered = False
for font_path in font_paths:
    if os.path.exists(font_path):
        try:
            pdfmetrics.registerFont(TTFont('Korean', font_path))
            font_registered = True
            print(f"Font registered from: {font_path}")
            break
        except:
            continue

if not font_registered:
    print("Warning: Korean font not found, using default font")

# PDF 생성
doc = SimpleDocTemplate("test_cover_letter_sections.pdf", pagesize=A4)
styles = getSampleStyleSheet()

# 한글 스타일 정의
if font_registered:
    title_style = ParagraphStyle(
        'KoreanTitle',
        parent=styles['Heading1'],
        fontName='Korean',
        fontSize=16,
        spaceAfter=30,
        alignment=TA_LEFT
    )
    
    heading_style = ParagraphStyle(
        'KoreanHeading',
        parent=styles['Heading2'],
        fontName='Korean',
        fontSize=14,
        spaceAfter=12,
        spaceBefore=20,
        alignment=TA_LEFT
    )
    
    body_style = ParagraphStyle(
        'KoreanBody',
        parent=styles['BodyText'],
        fontName='Korean',
        fontSize=11,
        alignment=TA_JUSTIFY,
        spaceAfter=12,
        leading=18
    )
else:
    title_style = styles['Heading1']
    heading_style = styles['Heading2']
    body_style = styles['BodyText']

# 문서 내용
story = []

# 제목
story.append(Paragraph("mmmd PD 지원 자기소개서", title_style))
story.append(Spacer(1, 0.5*cm))

# 1. 지원동기 및 포부
story.append(Paragraph("1. 지원동기 및 포부", heading_style))
story.append(Paragraph("""mmmd의 혁신적인 콘텐츠 제작 방식과 시청자 참여형 미디어 전략에 깊은 관심을 갖고 지원하게 되었습니다. 
특히 데이터 기반 의사결정과 빠른 트렌드 반영이라는 기업 문화가 저의 성장 경험과 일치한다고 생각합니다.
입사 후에는 데이터 분석과 스토리텔링을 융합한 차별화된 콘텐츠로 mmmd의 경쟁력 강화에 기여하고 싶습니다.""", body_style))

# 2. 성장과정
story.append(Paragraph("2. 성장과정", heading_style))
story.append(Paragraph("""어린 시절부터 영상 매체에 관심이 많았고, 대학에서는 방송 동아리 활동을 통해 실무 경험을 쌓았습니다.
3년간 10개 이상의 프로젝트를 진행하며 기획부터 후반 작업까지 전 과정을 경험했습니다.
이 과정에서 팀워크의 중요성과 창의적 문제 해결 능력을 키울 수 있었습니다.""", body_style))

# 3. 직무 관련 경험
story.append(Paragraph("3. 직무 관련 경험", heading_style))
story.append(Paragraph("""대학 영상제에서 '청년들의 도전' 다큐멘터리로 최우수상을 수상했습니다.
OTT 플랫폼 인턴십에서 시청자 데이터 분석을 통한 콘텐츠 전략 수립에 참여했습니다.
프리랜서로 다양한 브랜드 영상을 제작하며 클라이언트 소통 능력을 향상시켰습니다.""", body_style))

# 4. 성격의 장단점
story.append(Paragraph("4. 성격의 장단점", heading_style))
story.append(Paragraph("""저의 장점은 높은 책임감과 창의적 문제 해결 능력입니다.
단점은 완벽주의 성향으로 때로 시간 관리에 어려움을 겪지만, 우선순위를 정해 개선하고 있습니다.""", body_style))

# 5. 입사 후 계획
story.append(Paragraph("5. 입사 후 계획", heading_style))
story.append(Paragraph("""mmmd에서 PD로서 혁신적이고 의미 있는 콘텐츠를 만들어 시청자들에게 감동을 전달하고 싶습니다.
첫 1년은 조직 문화를 익히고 실무 역량을 강화하는 데 집중하겠습니다.
장기적으로는 글로벌 시장을 타겟으로 한 콘텐츠 제작에 참여하고 싶습니다.""", body_style))

# 페이지 구분
story.append(PageBreak())

# 이력서 섹션 추가
story.append(Paragraph("이력서", title_style))
story.append(Spacer(1, 0.5*cm))

story.append(Paragraph("기본 정보", heading_style))
story.append(Paragraph("""이름: 홍길동
생년월일: 1995년 3월 15일
연락처: 010-1234-5678
이메일: hong@example.com""", body_style))

story.append(Paragraph("학력", heading_style))
story.append(Paragraph("""2014.03 - 2020.02 서울대학교 언론정보학과 졸업
2011.03 - 2014.02 서울고등학교 졸업""", body_style))

story.append(Paragraph("경력", heading_style))
story.append(Paragraph("""2020.03 - 2021.12 ABC 프로덕션 조연출
2022.01 - 2023.06 XYZ 미디어 콘텐츠 PD""", body_style))

# PDF 생성
doc.build(story)
print("PDF created: test_cover_letter_sections.pdf")