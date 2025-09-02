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
        """번호가 매겨진 항목들 파싱 (GPT 응답 패턴 자동 감지)"""
        if not text:
            return []
        
        items = []
        
        # 패턴 감지 및 우선순위 결정
        patterns = self._detect_gpt_patterns(text)
        
        for pattern_info in patterns:
            pattern_type = pattern_info['type']
            matches = pattern_info['matches']
            
            if matches:
                for match in matches:
                    if pattern_type == 'gpt41_section':
                        # ### 1. **제목** 형식
                        number, title, content = match
                        items.append({
                            'number': number,
                            'title': title.strip(),
                            'content': self._clean_content(content.strip())
                        })
                    elif pattern_type == 'gpt41_subsection':
                        # **소제목** 형식 하위 섹션
                        subtitle, content = match
                        items.append({
                            'number': str(len(items) + 1),
                            'title': subtitle.strip(),
                            'content': self._clean_content(content.strip())
                        })
                    elif pattern_type == 'legacy_numbered':
                        # 기존 번호 매기기 형식
                        number, title, content = match
                        items.append({
                            'number': number,
                            'title': title.strip(),
                            'content': self._clean_content(content.strip())
                        })
                
                if items:  # 패턴 매칭 성공시 바로 반환
                    break
        
        return items
    
    def _detect_gpt_patterns(self, text: str) -> List[Dict]:
        """GPT 출력 패턴 자동 감지 (실제 2025-08-31 GPT 응답 분석)"""
        patterns = []
        
        # 실제 GPT 출력 구조:
        # ### 1. 고객 중심적 사고와 실질적 성과 도출 능력
        # **(자소서 인용 및 첫인상)**
        # 내용...
        
        # 1. 현재 GPT 패턴: ### N. **제목** (실제 2025-08-31 구조)
        current_pattern = r'###\s*(\d+)\.\s*\*\*([^*]+)\*\*\s*\n+(.*?)(?=###\s*\d+\.|---|\n{3,}|$)'
        current_matches = re.findall(current_pattern, text, re.MULTILINE | re.DOTALL)
        
        if current_matches:
            for number, title, content in current_matches:
                patterns.append({
                    'type': 'gpt41_section',
                    'priority': 1,
                    'matches': [(number, title.strip(), content.strip())],
                    'description': f'현재 GPT 볼드 패턴: {title}'
                })
            return patterns
            
        # 1-2. 현재 GPT 패턴: ### N. 제목 (볼드 없음)
        simple_pattern = r'###\s*(\d+)\.\s*([^\n]+)\s*\n+(.*?)(?=###\s*\d+\.|---\s*$|$)'
        simple_matches = re.findall(simple_pattern, text, re.MULTILINE | re.DOTALL)
        
        if simple_matches:
            for number, title, content in simple_matches:
                patterns.append({
                    'type': 'gpt41_section',
                    'priority': 2,
                    'matches': [(number, title.strip(), content.strip())],
                    'description': f'현재 GPT 단순 패턴: {title}'
                })
            return patterns
        
        # 1-2. 첫 번째 항목 특수 처리 (### 1. 이 생략된 경우)
        # 텍스트가 바로 제목으로 시작하는 경우
        if text.strip().startswith('중심적 사고'):
            # "중심적 사고와 실질적 성과 도출 능력" 같은 패턴
            first_item_pattern = r'^([^\n]+능력)\s*\n+(.*?)(?=###\s*\d+\.|---\s*$|$)'
            match = re.search(first_item_pattern, text, re.MULTILINE | re.DOTALL)
            if match:
                title, content = match.groups()
                patterns.append({
                    'type': 'gpt41_section',
                    'priority': 1,
                    'matches': [("1", "고객 " + title.strip(), content.strip())],
                    'description': f'첫 번째 항목 특수 처리: {title}'
                })
                return patterns
        
        # 2. 이전 GPT 패턴: ### N. **제목**
        legacy_bold_pattern = r'###\s*(\d+)\.\s*\*\*([^*]+)\*\*\s*\n+(.*?)(?=###\s*\d+\.|---\s*$|$)'
        legacy_matches = re.findall(legacy_bold_pattern, text, re.MULTILINE | re.DOTALL)
        
        if legacy_matches:
            for number, title, content in legacy_matches:
                patterns.append({
                    'type': 'gpt41_section',
                    'priority': 2,
                    'matches': [(number, title.strip(), content.strip())],
                    'description': f'레거시 GPT 볼드 패턴: {title}'
                })
            return patterns
        
        # 3. 단순 번호 패턴들
        simple_patterns = [
            (r'(\d+)\.\s*\*\*([^*]+)\*\*\s*\n+(.*?)(?=\d+\.\s*\*\*|---|\n{3,}|$)', '번호 볼드'),
            (r'(\d+)\.\s*([^\n]+)\s*\n+(.*?)(?=\d+\.\s*[^\n]|---|\n{3,}|$)', '단순 번호'),
            (r'(\d+)\)\s*([^\n]+)\s*\n+(.*?)(?=\d+\)|---|\n{3,}|$)', '괄호 번호'),
        ]
        
        for pattern, desc in simple_patterns:
            matches = re.findall(pattern, text, re.MULTILINE | re.DOTALL)
            if matches:
                patterns.append({
                    'type': 'legacy_numbered',
                    'priority': 3,
                    'matches': matches,
                    'description': f'{desc} 형식'
                })
        
        return patterns
    
    def _clean_content(self, content: str) -> str:
        """내용 정리 (placeholder 제거하되 실제 내용은 유지)"""
        if not content:
            return ""
        
        # 디버깅을 위한 로그
        original_length = len(content)
        
        # 빈 placeholder만 제거 (실제 내용이 있는 부분은 유지)
        # "**자소서 인용 및 첫인상**" 같은 헤더는 제거하되, 
        # 그 뒤의 실제 내용은 보존
        
        # 1. placeholder 헤더만 제거하고 실제 내용은 보존
        # GPT가 생성한 실제 구조:
        # #### 1) 자소서 내용 인용과 첫인상
        # #### 2) HR 관점에서 왜 좋은지
        # #### 3) 차별화 포인트와 실무 연결
        # #### 4) 면접 활용 전략
        
        # 가장 간단한 접근: placeholder 헤더만 제거하고 나머지는 모두 보존
        # "#### 1) 자소서 내용 인용과 첫인상" 같은 첫 번째 소제목만 제거
        content = re.sub(r'^####\s*\d+\)\s*자소서[^\n]*\n+', '', content, count=1)
        
        # 하지만 실제 분석 내용이 시작되는 부분부터는 모두 보존
        
        # 2. 연속된 줄바꿈 정리
        content = re.sub(r'\n{3,}', '\n\n', content)
        
        # 3. 앞뒤 공백 제거
        content = content.strip()
        
        # 디버깅 정보 (stderr로 출력) - 실제 내용이 있을 때만
        if len(content) > 50:
            import sys
            print(f"DEBUG: 원본 {original_length}자 → 정리 후 {len(content)}자", file=sys.stderr)
            print(f"DEBUG: 내용 시작: {content[:150]}...", file=sys.stderr)
        
        return content
    
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
    """CLI 인터페이스 - JSON 입력 처리"""
    analyzer = KoreanTextAnalyzer()
    
    try:
        # JSON 입력 받기
        input_data = json.loads(sys.stdin.read())
        text = input_data.get('text', '')
        action = input_data.get('action', 'parse_numbered_items')
        
        if action == 'extract_sections':
            result = analyzer.extract_sections(text)
            print(json.dumps({
                'success': True,
                'sections': result
            }, ensure_ascii=False))
            
        elif action == 'parse_numbered_items':
            result = analyzer.parse_numbered_items(text)
            print(json.dumps({
                'success': True,
                'items': result
            }, ensure_ascii=False))
            
        elif action == 'normalize':
            result = analyzer.normalize_korean_spacing(text)
            print(json.dumps({
                'success': True,
                'text': result
            }, ensure_ascii=False))
            
        elif action == 'detect_structure':
            result = analyzer.detect_section_structure(text)
            print(json.dumps({
                'success': True,
                'structure': result
            }, ensure_ascii=False))
            
        elif action == 'smart_split':
            result = analyzer.smart_split_sections(text)
            print(json.dumps({
                'success': True,
                'sections': result
            }, ensure_ascii=False))
            
        else:
            print(json.dumps({
                'success': False,
                'error': f'Unknown action: {action}'
            }))
            sys.exit(1)
            
    except json.JSONDecodeError as e:
        print(json.dumps({
            'success': False,
            'error': f'JSON 파싱 오류: {str(e)}'
        }))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({
            'success': False,
            'error': str(e)
        }))
        sys.exit(1)

if __name__ == '__main__':
    main()