#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PDF에서 자소서 추출 정확도 향상을 위한 Python 모듈
PyPDF2, pdfplumber 등 Python PDF 라이브러리 활용
"""

import json
import sys
import re
from typing import Dict, List, Tuple

class PdfCoverLetterExtractor:
    """PDF에서 자소서 영역을 정확히 추출"""
    
    def __init__(self):
        # 자소서 시작 마커 (우선순위 순)
        self.cover_letter_markers = [
            # 명확한 제목
            r'자\s*기\s*소\s*개\s*서',
            r'COVER\s*LETTER',
            r'Personal\s*Statement',
            
            # 섹션 제목
            r'지원\s*동기\s*및\s*포부',
            r'입사\s*후\s*포부',
            r'성장\s*과정',
            
            # 질문 형식
            r'Q\d+[\.:]\s*지원',
            r'문항\s*\d+',
            r'\d+\.\s*지원\s*동기'
        ]
        
        # 이력서 마커 (자소서와 구분용)
        self.resume_markers = [
            r'이\s*력\s*서',
            r'RESUME',
            r'CV',
            r'학\s*력\s*사\s*항',
            r'경\s*력\s*사\s*항',
            r'자\s*격\s*증'
        ]
    
    def analyze_page_type(self, text: str) -> Dict[str, any]:
        """페이지 타입 분석 (이력서/자소서/혼합)"""
        
        # 텍스트 정규화
        normalized = re.sub(r'\s+', ' ', text)
        
        # 점수 계산
        cover_score = 0
        resume_score = 0
        
        # 마커 체크
        for pattern in self.cover_letter_markers:
            if re.search(pattern, normalized, re.IGNORECASE):
                cover_score += 2
        
        for pattern in self.resume_markers:
            if re.search(pattern, normalized, re.IGNORECASE):
                resume_score += 2
        
        # 내용 기반 추가 분석
        # 자소서 특징: 긴 문단, 1인칭 표현
        if len(text) > 1000:
            first_person_count = len(re.findall(r'저는|제가|저의|나는|내가', text))
            if first_person_count > 5:
                cover_score += 3
        
        # 이력서 특징: 짧은 항목, 날짜, 표 형식
        date_count = len(re.findall(r'\d{4}[년\.\-/]\d{1,2}', text))
        if date_count > 3:
            resume_score += 2
        
        # 타입 결정
        if cover_score > resume_score * 1.5:
            page_type = 'cover_letter'
        elif resume_score > cover_score * 1.5:
            page_type = 'resume'
        elif cover_score > 0 and resume_score > 0:
            page_type = 'mixed'
        else:
            page_type = 'unknown'
        
        return {
            'type': page_type,
            'cover_score': cover_score,
            'resume_score': resume_score,
            'confidence': max(cover_score, resume_score) / (cover_score + resume_score + 1) * 100
        }
    
    def extract_sections(self, text: str) -> List[Dict[str, str]]:
        """자소서 섹션 추출"""
        sections = []
        
        # 다양한 섹션 패턴
        section_patterns = [
            # 번호 + 제목
            r'(\d+[\.\)]\s*)([가-힣\s]+)[\s\n]+([^0-9]{100,}?)(?=\d+[\.\)]|\Z)',
            
            # Q&A 형식
            r'(Q\d+[\.:]\s*)([^\n]+)[\s\n]+([^Q]{100,}?)(?=Q\d+|\Z)',
            
            # 제목만
            r'([가-힣]{2,10})\s*\n+([^가-힣\d]{100,}?)(?=[가-힣]{2,10}\s*\n|\Z)'
        ]
        
        for pattern in section_patterns:
            matches = re.finditer(pattern, text, re.MULTILINE | re.DOTALL)
            for match in matches:
                if len(match.groups()) >= 2:
                    title = match.group(1) + (match.group(2) if len(match.groups()) > 2 else '')
                    content = match.group(-1)
                    
                    sections.append({
                        'title': title.strip(),
                        'content': content.strip()[:500]  # 처음 500자만
                    })
        
        return sections
    
    def smart_split(self, pages: List[str]) -> Dict[str, any]:
        """지능형 이력서/자소서 분리"""
        
        resume_pages = []
        cover_letter_pages = []
        
        # 전환점 찾기
        transition_point = None
        prev_type = None
        
        for i, page_text in enumerate(pages):
            analysis = self.analyze_page_type(page_text)
            current_type = analysis['type']
            
            # 이력서 → 자소서 전환 감지
            if prev_type == 'resume' and current_type == 'cover_letter':
                transition_point = i
            
            # 페이지 분류
            if transition_point is None:
                # 전환점 전: 대부분 이력서
                if current_type in ['resume', 'unknown']:
                    resume_pages.append(i)
                else:
                    cover_letter_pages.append(i)
            else:
                # 전환점 후: 대부분 자소서
                if i >= transition_point:
                    cover_letter_pages.append(i)
                else:
                    resume_pages.append(i)
            
            prev_type = current_type
        
        # 자소서 텍스트 합치기
        cover_letter_text = '\n\n'.join([
            pages[i] for i in cover_letter_pages
        ]) if cover_letter_pages else ''
        
        # 섹션 추출
        sections = self.extract_sections(cover_letter_text) if cover_letter_text else []
        
        return {
            'has_cover_letter': len(cover_letter_pages) > 0,
            'resume_pages': resume_pages,
            'cover_letter_pages': cover_letter_pages,
            'cover_letter_text': cover_letter_text,
            'sections': sections,
            'confidence': 85 if transition_point else 60
        }

def main():
    """CLI 인터페이스"""
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'No command provided'}))
        sys.exit(1)
    
    command = sys.argv[1]
    extractor = PdfCoverLetterExtractor()
    
    try:
        if command == 'analyze_page':
            text = sys.stdin.read()
            result = extractor.analyze_page_type(text)
            print(json.dumps(result, ensure_ascii=False))
            
        elif command == 'extract_sections':
            text = sys.stdin.read()
            result = extractor.extract_sections(text)
            print(json.dumps(result, ensure_ascii=False))
            
        elif command == 'smart_split':
            # JSON 배열로 페이지들 받기
            pages_json = sys.stdin.read()
            pages = json.loads(pages_json)
            result = extractor.smart_split(pages)
            print(json.dumps(result, ensure_ascii=False))
            
        else:
            print(json.dumps({'error': f'Unknown command: {command}'}))
            sys.exit(1)
            
    except Exception as e:
        print(json.dumps({'error': str(e)}))
        sys.exit(1)

if __name__ == '__main__':
    main()