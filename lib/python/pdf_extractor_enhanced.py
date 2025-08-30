#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
향상된 PDF 자소서 추출기 - 전문 라이브러리 활용
"""

import json
import sys
import re
import base64
from typing import Dict, List, Tuple, Optional
from pathlib import Path

# venv 경로 추가
venv_path = Path(__file__).parent.parent.parent / 'venv' / 'lib' / 'python3.13' / 'site-packages'
if venv_path.exists():
    sys.path.insert(0, str(venv_path))

# PDF 처리 라이브러리들
try:
    import PyPDF2
    PYPDF2_AVAILABLE = True
except ImportError:
    PYPDF2_AVAILABLE = False
    print("Warning: PyPDF2 not installed", file=sys.stderr)

try:
    import pdfplumber
    PDFPLUMBER_AVAILABLE = True
except ImportError:
    PDFPLUMBER_AVAILABLE = False
    print("Warning: pdfplumber not installed", file=sys.stderr)

try:
    import fitz  # PyMuPDF
    PYMUPDF_AVAILABLE = True
except ImportError:
    PYMUPDF_AVAILABLE = False
    print("Warning: PyMuPDF not installed", file=sys.stderr)

# 한글 처리 (선택)
try:
    from kiwipiepy import Kiwi
    kiwi = Kiwi()
    KIWI_AVAILABLE = True
except ImportError:
    KIWI_AVAILABLE = False

class EnhancedPdfExtractor:
    """고급 PDF 자소서 추출기"""
    
    def __init__(self):
        self.extraction_method = self._select_best_method()
        
        # 자소서 판별 패턴 (우선순위)
        self.strong_indicators = [
            r'자\s*기\s*소\s*개\s*서',
            r'COVER\s*LETTER',
            r'Personal\s*Statement',
            r'자소서',
            r'지원서'
        ]
        
        self.section_patterns = [
            # 한글 섹션
            r'지원\s*동기',
            r'입사\s*후\s*포부',
            r'성장\s*과정',
            r'직무\s*역량',
            r'협업\s*경험',
            r'장점\s*및\s*단점',
            r'위기\s*극복',
            
            # 영문 섹션
            r'motivation',
            r'career\s*goals?',
            r'strengths?\s*and\s*weakness',
            
            # 번호형
            r'^\s*\d+[\.\)]\s*[가-힣]+',
            r'^\s*Q\d+',
            r'^\s*문항\s*\d+'
        ]
        
        self.resume_indicators = [
            r'이\s*력\s*서',
            r'RESUME',
            r'CV',
            r'학\s*력',
            r'경\s*력',
            r'자\s*격\s*증',
            r'Education',
            r'Experience',
            r'Skills'
        ]
    
    def _select_best_method(self):
        """사용 가능한 최선의 추출 방법 선택"""
        if PDFPLUMBER_AVAILABLE:
            return 'pdfplumber'
        elif PYMUPDF_AVAILABLE:
            return 'pymupdf'
        elif PYPDF2_AVAILABLE:
            return 'pypdf2'
        else:
            return 'fallback'
    
    def extract_from_file(self, pdf_path: str) -> Dict:
        """PDF 파일에서 텍스트 추출"""
        if not Path(pdf_path).exists():
            return {'error': f'File not found: {pdf_path}'}
        
        if self.extraction_method == 'pdfplumber':
            return self._extract_with_pdfplumber(pdf_path)
        elif self.extraction_method == 'pymupdf':
            return self._extract_with_pymupdf(pdf_path)
        elif self.extraction_method == 'pypdf2':
            return self._extract_with_pypdf2(pdf_path)
        else:
            return {'error': 'No PDF library available'}
    
    def _extract_with_pdfplumber(self, pdf_path: str) -> Dict:
        """pdfplumber로 추출 (가장 정확)"""
        pages_data = []
        
        try:
            with pdfplumber.open(pdf_path) as pdf:
                for i, page in enumerate(pdf.pages):
                    # 텍스트 추출
                    text = page.extract_text() or ''
                    
                    # 테이블 추출 (이력서 판별용)
                    tables = page.extract_tables()
                    has_tables = len(tables) > 0 if tables else False
                    
                    # 레이아웃 분석
                    chars = page.chars if hasattr(page, 'chars') else []
                    avg_font_size = sum(c.get('size', 12) for c in chars) / len(chars) if chars else 12
                    
                    pages_data.append({
                        'page_num': i + 1,
                        'text': text,
                        'has_tables': has_tables,
                        'avg_font_size': avg_font_size,
                        'char_count': len(text)
                    })
            
            return self._analyze_pages(pages_data)
            
        except Exception as e:
            return {'error': f'pdfplumber extraction failed: {str(e)}'}
    
    def _extract_with_pymupdf(self, pdf_path: str) -> Dict:
        """PyMuPDF로 추출 (빠름)"""
        pages_data = []
        
        try:
            pdf = fitz.open(pdf_path)
            
            for i, page in enumerate(pdf):
                # 텍스트 추출
                text = page.get_text()
                
                # 이미지 개수 (이력서는 보통 증명사진 포함)
                image_list = page.get_images()
                has_images = len(image_list) > 0
                
                # 링크 추출 (포트폴리오 링크 등)
                links = page.get_links()
                has_links = len(links) > 0
                
                pages_data.append({
                    'page_num': i + 1,
                    'text': text,
                    'has_images': has_images,
                    'has_links': has_links,
                    'char_count': len(text)
                })
            
            pdf.close()
            return self._analyze_pages(pages_data)
            
        except Exception as e:
            return {'error': f'PyMuPDF extraction failed: {str(e)}'}
    
    def _extract_with_pypdf2(self, pdf_path: str) -> Dict:
        """PyPDF2로 추출 (기본)"""
        pages_data = []
        
        try:
            with open(pdf_path, 'rb') as file:
                pdf = PyPDF2.PdfReader(file)
                
                for i, page in enumerate(pdf.pages):
                    text = page.extract_text()
                    
                    pages_data.append({
                        'page_num': i + 1,
                        'text': text,
                        'char_count': len(text)
                    })
            
            return self._analyze_pages(pages_data)
            
        except Exception as e:
            return {'error': f'PyPDF2 extraction failed: {str(e)}'}
    
    def _analyze_pages(self, pages_data: List[Dict]) -> Dict:
        """페이지 분석 및 자소서 추출"""
        result = {
            'total_pages': len(pages_data),
            'has_resume': False,
            'has_cover_letter': False,
            'resume_pages': [],
            'cover_letter_pages': [],
            'cover_letter_text': '',
            'cover_letter_sections': [],
            'extraction_method': self.extraction_method,
            'confidence': 0
        }
        
        # 각 페이지 타입 판별
        page_types = []
        for page in pages_data:
            page_type = self._classify_page(page)
            page_types.append(page_type)
            
            if page_type['type'] == 'resume':
                result['resume_pages'].append(page['page_num'])
                result['has_resume'] = True
            elif page_type['type'] == 'cover_letter':
                result['cover_letter_pages'].append(page['page_num'])
                result['has_cover_letter'] = True
        
        # 자소서 텍스트 합치기
        if result['cover_letter_pages']:
            cover_texts = []
            for page in pages_data:
                if page['page_num'] in result['cover_letter_pages']:
                    cover_texts.append(page['text'])
            
            result['cover_letter_text'] = '\n\n'.join(cover_texts)
            
            # 섹션 추출
            result['cover_letter_sections'] = self._extract_sections(result['cover_letter_text'])
        
        # 신뢰도 계산
        result['confidence'] = self._calculate_confidence(page_types)
        
        return result
    
    def _classify_page(self, page_data: Dict) -> Dict:
        """페이지 타입 분류"""
        text = page_data['text']
        
        # 점수 계산
        cover_score = 0
        resume_score = 0
        
        # 강력한 지표 체크
        for pattern in self.strong_indicators:
            if re.search(pattern, text[:500], re.IGNORECASE):  # 상단 500자만
                cover_score += 10
        
        # 섹션 패턴 체크
        for pattern in self.section_patterns:
            if re.search(pattern, text, re.IGNORECASE | re.MULTILINE):
                cover_score += 2
        
        # 이력서 지표 체크
        for pattern in self.resume_indicators:
            if re.search(pattern, text, re.IGNORECASE):
                resume_score += 3
        
        # 추가 분석
        # 1인칭 표현 (자소서 특징)
        first_person = len(re.findall(r'저는|제가|저의|저에게|제게', text))
        if first_person > 5:
            cover_score += 5
        elif first_person > 2:
            cover_score += 2
        
        # 날짜 패턴 (이력서 특징)
        dates = len(re.findall(r'\d{4}[\.\-년]\s*\d{1,2}', text))
        if dates > 3:
            resume_score += 3
        
        # 표 구조 (이력서 특징)
        if page_data.get('has_tables'):
            resume_score += 5
        
        # 이미지 (증명사진)
        if page_data.get('has_images'):
            resume_score += 2
        
        # 문단 길이 분석
        paragraphs = text.split('\n\n')
        long_paragraphs = sum(1 for p in paragraphs if len(p) > 200)
        if long_paragraphs > 2:
            cover_score += 3
        
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
            'page_num': page_data['page_num']
        }
    
    def _extract_sections(self, text: str) -> List[Dict]:
        """자소서 섹션 추출"""
        sections = []
        
        # 다양한 섹션 패턴으로 시도
        patterns = [
            # 1. 번호 + 제목
            r'(\d+)[\.\)]\s*([가-힣\s]+?)[\s\n]+([^\d]{100,}?)(?=\d+[\.\)]|\Z)',
            
            # 2. Q&A 형식
            r'(Q\d+)[\.:]\s*([^\n]+?)[\s\n]+([^Q]{100,}?)(?=Q\d+|\Z)',
            
            # 3. 대괄호 제목
            r'\[([^\]]+)\]\s*\n+([^\[]{100,}?)(?=\[|\Z)',
            
            # 4. 굵은 제목
            r'^([가-힣]{2,10})\s*\n[-=]+\n+([^\n]{100,}?)(?=^[가-힣]{2,10}\s*\n[-=]|\Z)'
        ]
        
        for pattern in patterns:
            matches = re.finditer(pattern, text, re.MULTILINE | re.DOTALL)
            for match in matches:
                groups = match.groups()
                if len(groups) >= 2:
                    title = groups[0] if len(groups) == 2 else f"{groups[0]}. {groups[1]}"
                    content = groups[-1]
                    
                    # 중복 체크
                    if not any(s['title'] == title for s in sections):
                        sections.append({
                            'title': title.strip(),
                            'content': content.strip()[:1000],  # 처음 1000자
                            'full_content': content.strip()
                        })
        
        # 섹션이 없으면 키워드 기반 분리
        if not sections and len(text) > 500:
            sections = self._keyword_based_extraction(text)
        
        return sections
    
    def _keyword_based_extraction(self, text: str) -> List[Dict]:
        """키워드 기반 섹션 추출"""
        sections = []
        keywords = ['지원동기', '성장과정', '성격', '장점', '단점', '협업', '입사후']
        
        for keyword in keywords:
            pattern = rf'({keyword}[^\n]*)\n+([^가-힣]*(?:[가-힣][^가-힣]*){20,})'
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                sections.append({
                    'title': match.group(1).strip(),
                    'content': match.group(2).strip()[:1000],
                    'full_content': match.group(2).strip()
                })
        
        return sections
    
    def _calculate_confidence(self, page_types: List[Dict]) -> float:
        """추출 신뢰도 계산"""
        if not page_types:
            return 0
        
        # 명확한 구분이 있는 경우
        has_clear_resume = any(p['type'] == 'resume' and p['resume_score'] > 10 for p in page_types)
        has_clear_cover = any(p['type'] == 'cover_letter' and p['cover_score'] > 10 for p in page_types)
        
        if has_clear_resume and has_clear_cover:
            return 95
        elif has_clear_cover:
            return 85
        elif has_clear_resume:
            return 75
        else:
            # 평균 점수 기반
            avg_confidence = sum(max(p['cover_score'], p['resume_score']) for p in page_types) / len(page_types)
            return min(avg_confidence * 5, 70)

def main():
    """CLI 인터페이스"""
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'Usage: python pdf_extractor_enhanced.py <command> [pdf_path]'}))
        sys.exit(1)
    
    command = sys.argv[1]
    extractor = EnhancedPdfExtractor()
    
    try:
        if command == 'extract':
            if len(sys.argv) < 3:
                print(json.dumps({'error': 'PDF path required'}))
                sys.exit(1)
            
            pdf_path = sys.argv[2]
            result = extractor.extract_from_file(pdf_path)
            print(json.dumps(result, ensure_ascii=False, indent=2))
        
        elif command == 'info':
            info = {
                'extraction_method': extractor.extraction_method,
                'libraries': {
                    'pypdf2': PYPDF2_AVAILABLE,
                    'pdfplumber': PDFPLUMBER_AVAILABLE,
                    'pymupdf': PYMUPDF_AVAILABLE,
                    'kiwi': KIWI_AVAILABLE
                }
            }
            print(json.dumps(info, ensure_ascii=False, indent=2))
        
        else:
            print(json.dumps({'error': f'Unknown command: {command}'}))
            sys.exit(1)
            
    except Exception as e:
        print(json.dumps({'error': str(e)}))
        sys.exit(1)

if __name__ == '__main__':
    main()