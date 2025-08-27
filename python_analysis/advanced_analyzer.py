#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import json
import re
from typing import Dict, List, Any, Tuple
from collections import Counter
import math

try:
    from konlpy.tag import Okt
    KONLPY_AVAILABLE = True
except ImportError:
    KONLPY_AVAILABLE = False

class AdvancedCoverLetterAnalyzer:
    """심층 자소서 분석기"""
    
    def __init__(self):
        self.okt = Okt() if KONLPY_AVAILABLE else None
        
        # AI 문체 패턴
        self.ai_patterns = [
            r'뿐만 아니라',
            r'더불어',
            r'아울러',
            r'나아가',
            r'이를 통해',
            r'이러한',
            r'다양한',
            r'효과적으로',
            r'체계적으로',
            r'종합적으로'
        ]
        
        # 진부한 표현들
        self.cliche_phrases = [
            '열정', '도전정신', '책임감', '성실함', '긍정적',
            '팀워크', '리더십', '글로벌', '창의적', '혁신적'
        ]
        
        # STAR 키워드
        self.star_keywords = {
            'situation': ['상황', '환경', '배경', '문제', '과제', '이슈', '당시', '때'],
            'task': ['목표', '임무', '역할', '담당', '책임', '해야', '필요'],
            'action': ['실행', '수행', '진행', '시도', '노력', '개선', '해결', '적용'],
            'result': ['결과', '성과', '달성', '향상', '개선', '증가', '감소', '완료']
        }
        
    def analyze(self, text: str, company: str = None, position: str = None) -> Dict[str, Any]:
        """통합 분석 수행"""
        results = {
            'basic_stats': self._analyze_basic_stats(text),
            'readability': self._calculate_readability(text),
            'keyword_analysis': self._analyze_keywords(text),
            'ai_detection': self._detect_ai_patterns(text),
            'star_compliance': self._check_star_compliance(text),
            'authenticity': self._evaluate_authenticity(text),
            'quality_score': 0,
            'suggestions': []
        }
        
        # 종합 품질 점수 계산
        results['quality_score'] = self._calculate_quality_score(results)
        
        # 개선 제안 생성
        results['suggestions'] = self._generate_suggestions(results)
        
        # 기업/직무별 분석 (제공된 경우)
        if company and position:
            results['company_fit'] = self._analyze_company_fit(text, company, position)
        
        return results
    
    def _analyze_basic_stats(self, text: str) -> Dict[str, int]:
        """기본 통계 분석"""
        sentences = text.split('.')
        words = text.split()
        
        return {
            'char_count': len(text),
            'word_count': len(words),
            'sentence_count': len([s for s in sentences if s.strip()]),
            'avg_sentence_length': len(words) / max(len(sentences), 1),
            'paragraph_count': len([p for p in text.split('\n') if p.strip()])
        }
    
    def _calculate_readability(self, text: str) -> Dict[str, Any]:
        """가독성 점수 계산"""
        sentences = [s for s in text.split('.') if s.strip()]
        words = text.split()
        
        if not sentences or not words:
            return {'score': 0, 'level': '평가불가'}
        
        # 간단한 한국어 가독성 지표
        avg_sentence_length = len(words) / len(sentences)
        complex_word_ratio = sum(1 for w in words if len(w) > 5) / len(words)
        
        # 가독성 점수 (0-100)
        readability_score = max(0, min(100, 100 - (avg_sentence_length * 2 + complex_word_ratio * 50)))
        
        # 난이도 레벨
        if readability_score >= 80:
            level = '매우 읽기 쉬움'
        elif readability_score >= 60:
            level = '읽기 쉬움'
        elif readability_score >= 40:
            level = '보통'
        elif readability_score >= 20:
            level = '다소 어려움'
        else:
            level = '매우 어려움'
        
        return {
            'score': round(readability_score, 1),
            'level': level,
            'avg_sentence_length': round(avg_sentence_length, 1),
            'complex_word_ratio': round(complex_word_ratio, 2)
        }
    
    def _analyze_keywords(self, text: str) -> Dict[str, Any]:
        """키워드 분석"""
        if KONLPY_AVAILABLE and self.okt:
            # 명사 추출
            nouns = self.okt.nouns(text)
            noun_counts = Counter(nouns)
            
            # 상위 10개 키워드
            top_keywords = [
                {'word': word, 'count': count}
                for word, count in noun_counts.most_common(10)
                if len(word) > 1  # 한 글자 제외
            ]
        else:
            # KoNLPy 없을 때 간단한 단어 빈도 분석
            words = text.split()
            word_counts = Counter(words)
            top_keywords = [
                {'word': word, 'count': count}
                for word, count in word_counts.most_common(10)
                if len(word) > 2
            ]
        
        # 진부한 표현 사용 횟수
        cliche_count = sum(text.count(phrase) for phrase in self.cliche_phrases)
        
        return {
            'top_keywords': top_keywords,
            'cliche_count': cliche_count,
            'keyword_diversity': len(set(text.split())) / max(len(text.split()), 1)
        }
    
    def _detect_ai_patterns(self, text: str) -> Dict[str, Any]:
        """AI 생성 패턴 탐지"""
        ai_pattern_matches = []
        total_matches = 0
        
        for pattern in self.ai_patterns:
            matches = len(re.findall(pattern, text))
            if matches > 0:
                ai_pattern_matches.append({'pattern': pattern, 'count': matches})
                total_matches += matches
        
        # AI 확률 점수 (0-100)
        text_length = len(text.split())
        ai_probability = min(100, (total_matches / max(text_length, 1)) * 1000)
        
        return {
            'ai_probability': round(ai_probability, 1),
            'detected_patterns': ai_pattern_matches,
            'risk_level': self._get_ai_risk_level(ai_probability)
        }
    
    def _get_ai_risk_level(self, probability: float) -> str:
        """AI 위험도 레벨 판단"""
        if probability < 10:
            return '매우 낮음'
        elif probability < 25:
            return '낮음'
        elif probability < 50:
            return '보통'
        elif probability < 75:
            return '높음'
        else:
            return '매우 높음'
    
    def _check_star_compliance(self, text: str) -> Dict[str, Any]:
        """STAR 기법 준수도 체크"""
        star_scores = {}
        
        for component, keywords in self.star_keywords.items():
            count = sum(text.count(keyword) for keyword in keywords)
            # 각 구성요소별 점수 (0-100)
            score = min(100, count * 20)
            star_scores[component] = {
                'score': score,
                'found': count > 0
            }
        
        # 전체 STAR 준수도
        total_score = sum(s['score'] for s in star_scores.values()) / 4
        all_components = all(s['found'] for s in star_scores.values())
        
        return {
            'components': star_scores,
            'total_score': round(total_score, 1),
            'has_all_components': all_components,
            'missing_components': [k for k, v in star_scores.items() if not v['found']]
        }
    
    def _evaluate_authenticity(self, text: str) -> Dict[str, Any]:
        """진정성 평가"""
        # 구체적 숫자나 날짜 언급
        numbers = len(re.findall(r'\d+', text))
        
        # 구체적 프로젝트명, 기술명 등 (대문자나 영문 포함)
        specific_terms = len(re.findall(r'[A-Z][A-Za-z]+|[가-힣]+(?:팀|프로젝트|시스템)', text))
        
        # 개인 경험 표현
        personal_expressions = len(re.findall(r'저는|제가|나는|내가|저의|나의', text))
        
        # 진정성 점수 계산
        text_length = len(text.split())
        specificity_score = min(100, (numbers + specific_terms) * 10)
        personal_score = min(100, (personal_expressions / max(text_length, 1)) * 500)
        
        authenticity_score = (specificity_score + personal_score) / 2
        
        return {
            'score': round(authenticity_score, 1),
            'specific_details': numbers + specific_terms,
            'personal_expressions': personal_expressions,
            'level': self._get_authenticity_level(authenticity_score)
        }
    
    def _get_authenticity_level(self, score: float) -> str:
        """진정성 레벨 판단"""
        if score >= 70:
            return '매우 진정성 있음'
        elif score >= 50:
            return '진정성 있음'
        elif score >= 30:
            return '보통'
        elif score >= 10:
            return '개선 필요'
        else:
            return '진정성 부족'
    
    def _calculate_quality_score(self, results: Dict) -> float:
        """종합 품질 점수 계산"""
        scores = []
        
        # 가독성 점수 (25%)
        scores.append(results['readability']['score'] * 0.25)
        
        # AI 탐지 역점수 (20%)
        scores.append((100 - results['ai_detection']['ai_probability']) * 0.20)
        
        # STAR 준수도 (25%)
        scores.append(results['star_compliance']['total_score'] * 0.25)
        
        # 진정성 (30%)
        scores.append(results['authenticity']['score'] * 0.30)
        
        return round(sum(scores), 1)
    
    def _generate_suggestions(self, results: Dict) -> List[str]:
        """개선 제안 생성"""
        suggestions = []
        
        # 가독성 제안
        if results['readability']['score'] < 60:
            suggestions.append("문장을 더 짧고 간결하게 작성해보세요.")
        
        # AI 패턴 제안
        if results['ai_detection']['ai_probability'] > 30:
            suggestions.append("AI가 작성한 것처럼 보이는 표현을 줄이고, 개인적인 경험을 더 구체적으로 서술하세요.")
        
        # STAR 제안
        missing = results['star_compliance']['missing_components']
        if missing:
            missing_str = ', '.join(missing)
            suggestions.append(f"STAR 기법의 {missing_str} 요소를 보완하세요.")
        
        # 진정성 제안
        if results['authenticity']['score'] < 50:
            suggestions.append("구체적인 수치, 프로젝트명, 성과 등을 추가하여 진정성을 높이세요.")
        
        # 진부한 표현 제안
        if results['keyword_analysis']['cliche_count'] > 5:
            suggestions.append("진부한 표현을 줄이고 자신만의 독특한 경험을 표현하세요.")
        
        return suggestions
    
    def _analyze_company_fit(self, text: str, company: str, position: str) -> Dict[str, Any]:
        """기업/직무 적합도 분석"""
        # 간단한 키워드 매칭 기반 적합도
        company_keywords = company.split()
        position_keywords = position.split()
        
        company_matches = sum(text.count(keyword) for keyword in company_keywords)
        position_matches = sum(text.count(keyword) for keyword in position_keywords)
        
        # 적합도 점수
        fit_score = min(100, (company_matches + position_matches) * 10)
        
        return {
            'company_relevance': company_matches,
            'position_relevance': position_matches,
            'fit_score': fit_score,
            'recommendation': '기업명과 직무를 자소서에 명시적으로 언급하여 관련성을 높이세요.' if fit_score < 50 else '기업과 직무에 대한 이해도가 잘 드러납니다.'
        }

def main():
    """메인 실행 함수"""
    try:
        # stdin에서 입력 받기
        input_data = sys.stdin.read()
        params = json.loads(input_data)
        
        text = params.get('text', '')
        company = params.get('company', None)
        position = params.get('position', None)
        
        # 분석 수행
        analyzer = AdvancedCoverLetterAnalyzer()
        results = analyzer.analyze(text, company, position)
        
        # 결과 출력
        print(json.dumps(results, ensure_ascii=False, indent=2))
        
    except Exception as e:
        error_result = {
            'error': str(e),
            'success': False
        }
        print(json.dumps(error_result, ensure_ascii=False))
        sys.exit(1)

if __name__ == '__main__':
    main()