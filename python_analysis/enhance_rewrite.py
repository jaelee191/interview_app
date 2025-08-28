#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import sys
import re
from collections import Counter
import numpy as np
import warnings
warnings.filterwarnings('ignore')

# KoNLPy는 Java가 필요하므로 옵션으로 처리
KONLPY_AVAILABLE = False
try:
    import os
    # Java 경로 설정
    os.environ['JAVA_HOME'] = '/opt/homebrew/opt/openjdk@17'
    os.environ['PATH'] = f"/opt/homebrew/opt/openjdk@17/bin:{os.environ.get('PATH', '')}"
    
    from konlpy.tag import Okt
    KONLPY_AVAILABLE = True
    # 디버그 메시지는 주석 처리
    # print("KoNLPy 활성화됨", file=sys.stderr)
except Exception as e:
    # print(f"KoNLPy를 사용할 수 없습니다: {e}", file=sys.stderr)
    KONLPY_AVAILABLE = False

class RewriteEnhancer:
    def __init__(self):
        self.okt = Okt() if KONLPY_AVAILABLE else None
        
        # AI 특유 패턴들
        self.ai_patterns = [
            (r'저는\s+.*?라고\s+생각합니다', ''),  # 불필요한 주관 표현
            (r'또한[,，]\s*', ''),  # 과도한 접속사
            (r'그리고\s+', ''),  # 문장 시작 접속사
            (r'하지만\s+', ''),  # 문장 시작 역접
            (r'따라서[,，]\s*', '그래서 '),  # 딱딱한 접속사
            (r'뿐만\s+아니라', '그리고'),  # 복잡한 접속사
            (r'것입니다\.', '습니다.'),  # 불필요한 강조
            (r'할\s+수\s+있습니다', '하겠습니다'),  # 가능성 → 의지
            (r'인\s+것\s+같습니다', '입니다'),  # 불확실 → 확실
            (r'되고자\s+합니다', '되겠습니다'),  # 의지 표현 강화
        ]
        
        # 기업별 선호 키워드
        self.company_keywords = {
            '삼성': ['도전', '혁신', '글로벌', '최고', '책임', '상생'],
            'LG': ['고객가치', '정도경영', '인재', '혁신', '글로벌', '미래'],
            '현대': ['도전정신', '창의', '협력', '글로벌', '고객', '기술'],
            'SK': ['행복', '성장', '혁신', 'VWBE', '사회적가치', '구성원'],
            '카카오': ['사용자', '기술', '임팩트', '도전', '성장', '연결'],
            '네이버': ['연결', '기술', '일상', '도전', '사용자', '플랫폼'],
            '쿠팡': ['고객', 'WOW', '혁신', '속도', '도전', '임팩트'],
            '토스': ['금융', '혁신', '사용자', '간편', '신뢰', '변화'],
        }
        
    def remove_ai_patterns(self, text):
        """AI 특유의 부자연스러운 패턴 제거"""
        original = text
        for pattern, replacement in self.ai_patterns:
            text = re.sub(pattern, replacement, text)
        
        # 연속된 공백 정리
        text = re.sub(r'\s+', ' ', text)
        text = re.sub(r'\.\s*\.', '.', text)
        
        removed_count = len(original) - len(text)
        return text, removed_count
    
    def calculate_readability(self, text):
        """한국어 가독성 점수 계산"""
        sentences = text.split('.')
        
        if self.okt:
            words = self.okt.morphs(text)
        else:
            # KoNLPy 없이 간단한 분리
            words = text.split()
        
        # 평균 문장 길이
        avg_sentence_length = np.mean([len(s.split()) for s in sentences if s])
        
        # 평균 단어 길이
        avg_word_length = np.mean([len(w) for w in words if w])
        
        # 한국어 가독성 지수 (자체 공식)
        # 짧은 문장 + 짧은 단어 = 높은 가독성
        readability = 100 - (avg_sentence_length * 2 + avg_word_length * 5)
        readability = max(0, min(100, readability))  # 0-100 범위
        
        return {
            'score': round(readability, 1),
            'avg_sentence_length': round(avg_sentence_length, 1),
            'avg_word_length': round(avg_word_length, 1)
        }
    
    def optimize_sentence_length(self, text):
        """문장 길이 최적화"""
        sentences = text.split('.')
        optimized = []
        
        for sentence in sentences:
            if not sentence.strip():
                continue
                
            words = sentence.split()
            if len(words) > 20:  # 너무 긴 문장
                # 접속사로 분리
                parts = re.split(r'[,，、및그리고또한]', sentence)
                if len(parts) > 1:
                    optimized.extend([p.strip() + '.' for p in parts if p.strip()])
                else:
                    optimized.append(sentence.strip() + '.')
            else:
                optimized.append(sentence.strip() + '.')
        
        return ' '.join(optimized)
    
    def enhance_keywords(self, text, company_name):
        """기업 맞춤 키워드 강화"""
        enhanced = text
        keyword_count = 0
        
        # 기업명에서 회사 찾기
        target_keywords = []
        for company, keywords in self.company_keywords.items():
            if company in company_name:
                target_keywords = keywords
                break
        
        if not target_keywords:
            # 기본 키워드 사용
            target_keywords = ['도전', '성장', '혁신', '책임', '협력']
        
        # 키워드 자연스럽게 삽입
        for keyword in target_keywords[:3]:  # 상위 3개만
            if keyword not in text:
                # 적절한 위치 찾기
                if '목표' in text:
                    enhanced = enhanced.replace('목표', f'{keyword}적인 목표', 1)
                    keyword_count += 1
                elif '경험' in text:
                    enhanced = enhanced.replace('경험', f'{keyword}의 경험', 1)
                    keyword_count += 1
        
        return enhanced, keyword_count
    
    def structure_to_star(self, text):
        """STAR 구조로 재구성"""
        # 간단한 STAR 패턴 감지
        has_situation = bool(re.search(r'(상황|환경|배경|당시)', text))
        has_task = bool(re.search(r'(과제|목표|해결|문제)', text))
        has_action = bool(re.search(r'(시도|노력|실행|진행)', text))
        has_result = bool(re.search(r'(결과|성과|달성|개선)', text))
        
        star_score = sum([has_situation, has_task, has_action, has_result]) * 25
        
        # STAR 구조 힌트 추가
        if not has_result and '했습니다' in text:
            text = text.replace('했습니다', '하여 00% 개선의 성과를 달성했습니다', 1)
        
        return text, star_score
    
    def calculate_keyword_density(self, text, keywords):
        """키워드 밀도 계산"""
        if self.okt:
            words = self.okt.nouns(text)
        else:
            # 간단한 단어 추출 (공백 기준)
            words = [w for w in text.split() if len(w) > 1]
        
        total_words = len(words)
        
        if total_words == 0:
            return 0
        
        keyword_count = sum(words.count(kw) for kw in keywords)
        density = (keyword_count / total_words) * 100
        
        return round(density, 1)
    
    def enhance_rewrite(self, data):
        """리라이트 텍스트 품질 향상"""
        try:
            text = data.get('text', '')
            company = data.get('company', '')
            
            if not text:
                return {'error': '텍스트가 없습니다'}
            
            # 원본 지표
            before_metrics = {
                'readability': self.calculate_readability(text),
                'length': len(text),
                'sentences': len(text.split('.'))
            }
            
            # 1. AI 패턴 제거
            text, ai_removed = self.remove_ai_patterns(text)
            
            # 2. 문장 길이 최적화
            text = self.optimize_sentence_length(text)
            
            # 3. 기업 키워드 강화
            text, keywords_added = self.enhance_keywords(text, company)
            
            # 4. STAR 구조 강화
            text, star_score = self.structure_to_star(text)
            
            # 개선 후 지표
            after_metrics = {
                'readability': self.calculate_readability(text),
                'length': len(text),
                'sentences': len(text.split('.')),
                'ai_patterns_removed': ai_removed,
                'keywords_added': keywords_added,
                'star_score': star_score
            }
            
            # 개선율 계산
            improvements = {
                'readability_change': after_metrics['readability']['score'] - before_metrics['readability']['score'],
                'ai_naturalness': min(95, 100 - (ai_removed * 2)),  # AI 제거율 기반
                'keyword_optimization': min(100, 70 + keywords_added * 10),
                'structure_score': star_score
            }
            
            return {
                'success': True,
                'enhanced_text': text,
                'before_metrics': before_metrics,
                'after_metrics': after_metrics,
                'improvements': improvements,
                'suggestions': self.generate_suggestions(improvements)
            }
            
        except Exception as e:
            return {'error': f'텍스트 향상 중 오류: {str(e)}'}
    
    def generate_suggestions(self, improvements):
        """추가 개선 제안 생성"""
        suggestions = []
        
        if improvements['readability_change'] < 5:
            suggestions.append("문장을 더 짧고 명확하게 다듬으면 좋겠습니다")
        
        if improvements['ai_naturalness'] < 80:
            suggestions.append("AI 특유의 표현이 남아있습니다. 더 자연스럽게 수정해보세요")
        
        if improvements['structure_score'] < 75:
            suggestions.append("STAR 구조로 경험을 정리하면 더 설득력이 높아집니다")
        
        return suggestions

def main():
    try:
        # 입력 받기
        input_data = json.loads(sys.stdin.read())
        
        # 향상 처리
        enhancer = RewriteEnhancer()
        result = enhancer.enhance_rewrite(input_data)
        
        # 결과 출력
        print(json.dumps(result, ensure_ascii=False))
        
    except Exception as e:
        error_result = {'error': str(e)}
        print(json.dumps(error_result, ensure_ascii=False))
        sys.exit(1)

if __name__ == "__main__":
    main()