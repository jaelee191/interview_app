#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import sys
import re
from typing import Dict, List, Tuple, Optional

class KoreanTextAnalyzer:
    """한글 자소서 텍스트 구조 분석 및 파싱"""
    
    def __init__(self):
        # 다양한 섹션 헤더 패턴들
        self.section_patterns = {
            'numbered_headers': [
                r'###\s+(.+?)\s+(\d+):\s*(.+)',  # ### 강점 1: 제목
                r'##\s*(\d+)\.\s*(.+)',           # ## 1. 제목
                r'\*\*(.+?)\s+(\d+):\s*(.+?)\*\*', # **강점 1: 제목**
                r'(\d+)\.\s*\*\*(.+?)\*\*',       # 1. **제목**
                r'(\d+)\.\s*(.+?)[:：]',          # 1. 제목:
            ],
            'section_markers': [
                r'첫\s*인상',
                r'전체\s*평가', 
                r'잘\s*쓴\s*부분',
                r'강점',
                r'개선\s*부분',
                r'아쉬운\s*부분',
                r'숨은\s*보석',
                r'놓치고\s*있는',
                r'격려',
                r'응원'
            ]
        }
        
        # 한글 조사 패턴 (띄어쓰기 오류 보정용)
        self.josa_patterns = ['은', '는', '이', '가', '을', '를', '의', '에', '에서', '으로', '로', '와', '과']
        
    def extract_sections(self, text: str) -> Dict[str, str]:
        """텍스트에서 주요 섹션 추출"""
        sections = {
            'first_impression': None,
            'strengths': None,
            'improvements': None,
            'hidden_gems': None,
            'encouragement': None
        }
        
        # 특수문자 정리
        cleaned_text = re.sub(r'[═─]{3,}', '', text).strip()
        
        # 섹션별 매칭 패턴 정의
        section_patterns = {
            'first_impression': [
                r'##\s*1\.\s*첫\s*인상.*?\n(.*?)(?=##\s*2\.|$)',
                r'첫\s*인상\s*&\s*전체.*?\n(.*?)(?=##|$)'
            ],
            'strengths': [
                r'##\s*2\.\s*잘\s*쓴\s*부분.*?\n(.*?)(?=##\s*3\.|$)',
                r'강점\s*\d+개.*?\n(.*?)(?=##|개선|$)'
            ],
            'improvements': [
                r'##\s*3\.\s*(?:아쉬운|개선)\s*부분.*?\n(.*?)(?=##\s*4\.|$)'
            ],
            'hidden_gems': [
                r'##\s*4\.\s*(?:놓치고\s*있는\s*)?숨은\s*보석.*?\n(.*?)(?=##\s*5\.|$)'
            ],
            'encouragement': [
                r'##\s*5\.\s*격려.*?\n(.*?)(?=$)'
            ]
        }
        
        for key, patterns in section_patterns.items():
            for pattern in patterns:
                match = re.search(pattern, cleaned_text, re.DOTALL | re.MULTILINE)
                if match:
                    sections[key] = match.group(1).strip() if match.lastindex else match.group(0).strip()
                    break
        
        # 섹션이 없으면 전체를 첫인상으로
        if not any(sections.values()):
            sections['first_impression'] = cleaned_text
            
        return sections
    
    def parse_numbered_items(self, text: str) -> List[Dict[str, str]]:
        """번호가 매겨진 항목들 파싱 (강점, 개선점, 숨은 보석 등)"""
        if not text:
            return []
        
        items = []
        
        # 다양한 형식 시도
        # 1. ### 헤더 형식 (숨은 보석 처럼 띄어쓰기 있는 경우도 처리)
        pattern1 = r'###\s+([가-힣]+(?:\s+[가-힣]+)*)\s+(\d+):\s*([^\n]+)\n+([^#]+?)(?=###|$)'
        matches = re.findall(pattern1, text, re.MULTILINE | re.DOTALL)
        
        if matches:
            for category, num, title, content in matches:
                items.append({
                    'number': num,
                    'title': f'{category} {num}: {title}'.strip(),
                    'content': content.strip()
                })
            return items
        
        # 2. ** 볼드 형식
        pattern2 = r'\*\*([가-힣]+)\s+(\d+):\s*([^*]+)\*\*\s*([^*]+?)(?=\*\*[가-힣]+\s+\d+:|$)'
        matches = re.findall(pattern2, text, re.MULTILINE | re.DOTALL)
        
        if matches:
            for category, num, title, content in matches:
                items.append({
                    'number': num,
                    'title': f'{category} {num}: {title}'.strip(),
                    'content': content.strip()
                })
            return items
        
        # 3. 숫자로 시작하는 리스트
        pattern3 = r'^(\d+)\.\s*(?:\*\*)?(.*?)(?:\*\*)?\s*[:：]\s*(.*?)(?=^\d+\.|$)'
        matches = re.findall(pattern3, text, re.MULTILINE | re.DOTALL)
        
        if matches:
            for num, title, content in matches:
                items.append({
                    'number': num,
                    'title': title.strip(),
                    'content': content.strip()
                })
        
        return items
    
    def normalize_korean_spacing(self, text: str) -> str:
        """한글 띄어쓰기 정규화"""
        # 조사 앞 불필요한 띄어쓰기 제거
        for josa in self.josa_patterns:
            text = re.sub(rf'\s+{josa}\b', josa, text)
        
        # 중복 공백 제거
        text = re.sub(r'\s+', ' ', text)
        
        return text.strip()
    
    def detect_section_structure(self, text: str) -> Dict[str, any]:
        """자소서의 구조 자동 감지"""
        structure = {
            'has_numbered_sections': False,
            'section_count': 0,
            'section_titles': [],
            'format_type': 'unknown'  # 'markdown', 'plain', 'mixed'
        }
        
        # 마크다운 헤더 체크
        markdown_headers = re.findall(r'^#{1,3}\s+(.+)$', text, re.MULTILINE)
        if markdown_headers:
            structure['format_type'] = 'markdown'
            structure['section_titles'] = markdown_headers
        
        # 번호 매기기 체크
        numbered_sections = re.findall(r'^\d+\.\s*(.+?)[:：]', text, re.MULTILINE)
        if numbered_sections:
            structure['has_numbered_sections'] = True
            structure['section_count'] = len(numbered_sections)
            if structure['format_type'] == 'unknown':
                structure['format_type'] = 'plain'
            else:
                structure['format_type'] = 'mixed'
            structure['section_titles'].extend(numbered_sections)
        
        return structure
    
    def smart_split_sections(self, text: str) -> List[Dict[str, str]]:
        """지능형 섹션 분리 (다양한 형식 자동 인식)"""
        sections = []
        
        # 우선 구조 감지
        structure = self.detect_section_structure(text)
        
        if structure['format_type'] == 'markdown':
            # 마크다운 기반 분리
            pattern = r'^(#{1,3})\s+(.+?)$\n(.*?)(?=^#{1,3}|\Z)'
            matches = re.findall(pattern, text, re.MULTILINE | re.DOTALL)
            for level, title, content in matches:
                sections.append({
                    'level': len(level),
                    'title': title.strip(),
                    'content': content.strip()
                })
        else:
            # 일반 텍스트 기반 분리
            # 빈 줄 2개 이상을 섹션 구분자로 사용
            parts = re.split(r'\n{2,}', text)
            for i, part in enumerate(parts):
                if part.strip():
                    # 첫 줄을 제목으로 추정
                    lines = part.strip().split('\n', 1)
                    title = lines[0] if lines else f'섹션 {i+1}'
                    content = lines[1] if len(lines) > 1 else ''
                    
                    sections.append({
                        'level': 1,
                        'title': title.strip(),
                        'content': content.strip()
                    })
        
        return sections

def main():
    """CLI 인터페이스"""
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'No command provided'}))
        sys.exit(1)
    
    command = sys.argv[1]
    analyzer = KoreanTextAnalyzer()
    
    try:
        if command == 'extract_sections':
            text = sys.stdin.read()
            result = analyzer.extract_sections(text)
            print(json.dumps(result, ensure_ascii=False))
            
        elif command == 'parse_items':
            text = sys.stdin.read()
            result = analyzer.parse_numbered_items(text)
            print(json.dumps(result, ensure_ascii=False))
            
        elif command == 'normalize':
            text = sys.stdin.read()
            result = analyzer.normalize_korean_spacing(text)
            print(json.dumps({'text': result}, ensure_ascii=False))
            
        elif command == 'detect_structure':
            text = sys.stdin.read()
            result = analyzer.detect_section_structure(text)
            print(json.dumps(result, ensure_ascii=False))
            
        elif command == 'smart_split':
            text = sys.stdin.read()
            result = analyzer.smart_split_sections(text)
            print(json.dumps(result, ensure_ascii=False))
            
        else:
            print(json.dumps({'error': f'Unknown command: {command}'}))
            sys.exit(1)
            
    except Exception as e:
        print(json.dumps({'error': str(e)}))
        sys.exit(1)

if __name__ == '__main__':
    main()