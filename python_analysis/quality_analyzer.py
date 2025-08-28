#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import sys
import re
import numpy as np
import os

# Java 경로 설정
os.environ['JAVA_HOME'] = '/opt/homebrew/opt/openjdk@17'
os.environ['PATH'] = f"/opt/homebrew/opt/openjdk@17/bin:{os.environ.get('PATH', '')}"

# KoNLPy 옵션 처리
KONLPY_AVAILABLE = False
try:
    from konlpy.tag import Okt
    KONLPY_AVAILABLE = True
except:
    KONLPY_AVAILABLE = False

class QualityAnalyzer:
    def __init__(self):
        self.okt = Okt() if KONLPY_AVAILABLE else None
        
        # AI 특유 패턴들
        self.ai_patterns = [
            (r'저는\s+.*?라고\s+생각합니다', ''),
            (r'또한[,，]\s*', ''),
            (r'그리고\s+', ''),
            (r'하지만\s+', ''),
            (r'따라서[,，]\s*', '그래서 '),
            (r'뿐만\s+아니라', '그리고'),
            (r'것입니다\.', '습니다.'),
            (r'할\s+수\s+있습니다', '하겠습니다'),
            (r'인\s+것\s+같습니다', '입니다'),
            (r'되고자\s+합니다', '되겠습니다'),
        ]
    
    def analyze_only(self, text, company_name=''):
        """텍스트 품질만 분석 (변경 없음)"""
        try:
            # 가독성 분석
            readability = self.calculate_readability(text)
            
            # AI 패턴 감지
            ai_patterns_detected = self.detect_ai_patterns(text)
            
            # STAR 구조 점수
            star_score = self.evaluate_star_structure(text)
            
            # 키워드 분석
            keyword_info = self.analyze_keywords(text, company_name)
            
            return {
                'success': True,
                'text': text,  # 원본 그대로 반환
                'ai_patterns_detected': ai_patterns_detected,
                'before_metrics': {
                    'readability': readability,
                    'length': len(text),
                    'sentences': len(text.split('.'))
                },
                'after_metrics': {
                    'readability': readability,
                    'length': len(text),
                    'sentences': len(text.split('.'))
                },
                'improvements': {
                    'readability_change': 0,
                    'ai_naturalness': 100 - min(ai_patterns_detected * 5, 100),
                    'keyword_optimization': keyword_info['optimization_score'],
                    'structure_score': star_score
                },
                'suggestions': self.generate_suggestions(
                    readability['score'],
                    ai_patterns_detected,
                    star_score
                )
            }
        except Exception as e:
            return {'error': f'분석 중 오류: {str(e)}'}
    
    def remove_ai_patterns(self, text):
        """AI 패턴만 제거 (최소 변경)"""
        try:
            cleaned_text = text
            patterns_removed = 0
            
            for pattern, replacement in self.ai_patterns:
                matches = len(re.findall(pattern, cleaned_text))
                if matches > 0:
                    cleaned_text = re.sub(pattern, replacement, cleaned_text)
                    patterns_removed += matches
            
            # 연속된 공백 정리
            cleaned_text = re.sub(r'\s+', ' ', cleaned_text)
            cleaned_text = re.sub(r'\.\s*\.', '.', cleaned_text)
            
            return {
                'success': True,
                'text': cleaned_text,
                'patterns_removed': patterns_removed
            }
        except Exception as e:
            return {'error': f'AI 패턴 제거 중 오류: {str(e)}'}
    
    def calculate_readability(self, text):
        """한국어 가독성 점수 계산"""
        sentences = text.split('.')
        
        if self.okt:
            words = self.okt.morphs(text)
        else:
            words = text.split()
        
        # 평균 문장 길이
        avg_sentence_length = np.mean([len(s.split()) for s in sentences if s])
        
        # 평균 단어 길이
        avg_word_length = np.mean([len(w) for w in words if w])
        
        # 가독성 지수
        readability = 100 - (avg_sentence_length * 2 + avg_word_length * 5)
        readability = max(0, min(100, readability))
        
        return {
            'score': round(readability, 1),
            'avg_sentence_length': round(avg_sentence_length, 1),
            'avg_word_length': round(avg_word_length, 1)
        }
    
    def detect_ai_patterns(self, text):
        """AI 패턴 개수 감지"""
        count = 0
        for pattern, _ in self.ai_patterns:
            matches = re.findall(pattern, text)
            count += len(matches)
        return count
    
    def evaluate_star_structure(self, text):
        """STAR 구조 평가"""
        has_situation = bool(re.search(r'(상황|환경|배경|당시|때)', text))
        has_task = bool(re.search(r'(과제|목표|해결|문제|임무)', text))
        has_action = bool(re.search(r'(시도|노력|실행|진행|구체적으로)', text))
        has_result = bool(re.search(r'(결과|성과|달성|개선|%|배)', text))
        
        star_score = sum([has_situation, has_task, has_action, has_result]) * 25
        return star_score
    
    def analyze_keywords(self, text, company_name):
        """키워드 분석"""
        company_keywords = {
            '삼성': ['도전', '혁신', '글로벌', '최고', '책임'],
            'LG': ['고객가치', '정도경영', '인재', '혁신'],
            '현대': ['도전정신', '창의', '협력', '글로벌'],
            'SK': ['행복', '성장', '혁신', '사회적가치'],
        }
        
        target_keywords = []
        for company, keywords in company_keywords.items():
            if company in company_name:
                target_keywords = keywords
                break
        
        if not target_keywords:
            target_keywords = ['도전', '성장', '혁신', '책임', '협력']
        
        # 키워드 존재 여부 확인
        found_keywords = sum(1 for kw in target_keywords if kw in text)
        optimization_score = min(100, (found_keywords / len(target_keywords)) * 100)
        
        return {
            'target_keywords': target_keywords,
            'found_keywords': found_keywords,
            'optimization_score': round(optimization_score)
        }
    
    def generate_suggestions(self, readability_score, ai_patterns, star_score):
        """개선 제안 생성"""
        suggestions = []
        
        if readability_score < 70:
            suggestions.append("문장을 더 짧고 명확하게 다듬으면 좋겠습니다")
        
        if ai_patterns > 5:
            suggestions.append("AI 특유의 표현이 남아있습니다. 더 자연스럽게 수정해보세요")
        
        if star_score < 75:
            suggestions.append("STAR 구조로 경험을 정리하면 더 설득력이 높아집니다")
        
        if not suggestions:
            suggestions.append("전반적으로 잘 작성되었습니다")
        
        return suggestions

def main():
    try:
        # 입력 받기
        input_data = json.loads(sys.stdin.read())
        
        analyzer = QualityAnalyzer()
        
        # 모드에 따라 다른 처리
        mode = input_data.get('mode', 'analyze_only')
        
        if mode == 'analyze_only':
            result = analyzer.analyze_only(
                input_data.get('text', ''),
                input_data.get('company', '')
            )
        elif mode == 'remove_ai_only':
            result = analyzer.remove_ai_patterns(input_data.get('text', ''))
        else:
            result = {'error': f'Unknown mode: {mode}'}
        
        # 결과 출력
        print(json.dumps(result, ensure_ascii=False))
        
    except Exception as e:
        error_result = {'error': str(e)}
        print(json.dumps(error_result, ensure_ascii=False))
        sys.exit(1)

if __name__ == "__main__":
    main()