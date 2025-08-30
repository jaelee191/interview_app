#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
향상된 한글 NLP 분석기 (외부 라이브러리 사용 예시)
주의: 이 파일을 사용하려면 먼저 다음 라이브러리를 설치해야 합니다:
pip install konlpy kiwipiepy
"""

import json
import sys
import re

try:
    # Kiwi 사용 (순수 Python, 설치가 쉬움)
    from kiwipiepy import Kiwi
    kiwi = Kiwi()
    NLP_AVAILABLE = True
except ImportError:
    NLP_AVAILABLE = False
    print("Warning: Kiwi not installed. Using regex-based parsing.", file=sys.stderr)

class EnhancedKoreanAnalyzer:
    """향상된 한글 텍스트 분석기"""
    
    def __init__(self):
        if NLP_AVAILABLE:
            self.kiwi = Kiwi()
    
    def extract_key_phrases(self, text):
        """핵심 구문 추출 (명사구 중심)"""
        if not NLP_AVAILABLE:
            return self._regex_extract_phrases(text)
        
        result = self.kiwi.tokenize(text)
        phrases = []
        
        for token in result:
            # 명사류 추출 (NNG: 일반명사, NNP: 고유명사)
            if token.tag.startswith('NN'):
                phrases.append(token.form)
        
        return phrases
    
    def correct_spacing(self, text):
        """띄어쓰기 교정"""
        if not NLP_AVAILABLE:
            return text
        
        # Kiwi의 띄어쓰기 교정 기능 사용
        result = self.kiwi.space(text)
        if result:
            return result[0][0]  # 가장 높은 확률의 결과 반환
        return text
    
    def analyze_sentiment(self, text):
        """감정 분석 (긍정/부정/중립)"""
        # 간단한 규칙 기반 감정 분석
        positive_words = ['훌륭', '탁월', '우수', '좋', '잘', '성공', '달성', '혁신']
        negative_words = ['부족', '아쉬', '개선', '미흡', '실패', '어려', '문제']
        
        pos_count = sum(1 for word in positive_words if word in text)
        neg_count = sum(1 for word in negative_words if word in text)
        
        if pos_count > neg_count:
            return 'positive'
        elif neg_count > pos_count:
            return 'negative'
        else:
            return 'neutral'
    
    def extract_entities(self, text):
        """개체명 인식 (회사명, 직무명 등)"""
        entities = {
            'companies': [],
            'positions': [],
            'skills': []
        }
        
        # 회사명 패턴
        company_patterns = [
            r'([가-힣]+(?:그룹|회사|은행|증권|보험|전자|화학|제약|엔터테인먼트|커머스))',
            r'([A-Z][A-Za-z]+(?:Corp|Inc|Ltd|Co)\.?)'
        ]
        
        # 직무명 패턴
        position_patterns = [
            r'([가-힣]+(?:매니저|엔지니어|개발자|디자이너|마케터|기획자|분석가))',
            r'(PM|PO|UX|UI|QA|DevOps|Frontend|Backend)'
        ]
        
        # 기술 스킬 패턴
        skill_patterns = [
            r'(Python|Java|JavaScript|React|Vue|Django|Spring|Docker|Kubernetes|AWS|GCP)',
            r'([가-힣]+(?:분석|설계|기획|운영|관리|개발))'
        ]
        
        for pattern in company_patterns:
            entities['companies'].extend(re.findall(pattern, text))
        
        for pattern in position_patterns:
            entities['positions'].extend(re.findall(pattern, text))
        
        for pattern in skill_patterns:
            entities['skills'].extend(re.findall(pattern, text))
        
        # 중복 제거
        entities = {k: list(set(v)) for k, v in entities.items()}
        
        return entities
    
    def _regex_extract_phrases(self, text):
        """정규식 기반 구문 추출 (폴백)"""
        # 명사로 추정되는 패턴
        pattern = r'[가-힣]{2,}(?:적|인|적인|의|를|을|이|가)?\s'
        phrases = re.findall(pattern, text)
        return [phrase.strip() for phrase in phrases]
    
    def analyze_document_quality(self, text):
        """문서 품질 분석"""
        quality_metrics = {
            'length': len(text),
            'sentence_count': len(re.split(r'[.!?]\s', text)),
            'paragraph_count': len(re.split(r'\n\n+', text)),
            'has_numbers': bool(re.search(r'\d+', text)),
            'has_english': bool(re.search(r'[A-Za-z]+', text)),
            'repetition_score': self._calculate_repetition(text),
            'readability_score': self._calculate_readability(text)
        }
        
        return quality_metrics
    
    def _calculate_repetition(self, text):
        """반복도 계산 (0-1, 낮을수록 좋음)"""
        words = re.findall(r'[가-힣]+', text)
        if not words:
            return 0
        
        unique_words = set(words)
        return 1 - (len(unique_words) / len(words))
    
    def _calculate_readability(self, text):
        """가독성 점수 계산 (0-100, 높을수록 좋음)"""
        # 문장 길이 기반 간단한 가독성 점수
        sentences = re.split(r'[.!?]\s', text)
        if not sentences:
            return 0
        
        avg_length = sum(len(s) for s in sentences) / len(sentences)
        
        # 이상적인 문장 길이: 40-60자
        if 40 <= avg_length <= 60:
            return 100
        elif avg_length < 40:
            return max(0, 100 - (40 - avg_length) * 2)
        else:
            return max(0, 100 - (avg_length - 60) * 1.5)

def main():
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'No command provided'}))
        sys.exit(1)
    
    command = sys.argv[1]
    analyzer = EnhancedKoreanAnalyzer()
    
    try:
        text = sys.stdin.read()
        
        if command == 'extract_phrases':
            result = analyzer.extract_key_phrases(text)
            print(json.dumps({'phrases': result}, ensure_ascii=False))
            
        elif command == 'correct_spacing':
            result = analyzer.correct_spacing(text)
            print(json.dumps({'text': result}, ensure_ascii=False))
            
        elif command == 'analyze_sentiment':
            result = analyzer.analyze_sentiment(text)
            print(json.dumps({'sentiment': result}, ensure_ascii=False))
            
        elif command == 'extract_entities':
            result = analyzer.extract_entities(text)
            print(json.dumps(result, ensure_ascii=False))
            
        elif command == 'analyze_quality':
            result = analyzer.analyze_document_quality(text)
            print(json.dumps(result, ensure_ascii=False))
            
        else:
            print(json.dumps({'error': f'Unknown command: {command}'}))
            sys.exit(1)
            
    except Exception as e:
        print(json.dumps({'error': str(e)}))
        sys.exit(1)

if __name__ == '__main__':
    main()