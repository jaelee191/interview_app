#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
대화형 자소서 작성 지원을 위한 NLP 분석 모듈
- 답변 품질 평가
- 키워드 추출 및 역량 매칭
- STAR 기법 준수 여부 체크
- 구체성 및 진정성 평가
"""

import json
import re
import sys
from typing import Dict, List, Tuple, Any
from collections import Counter

# numpy는 선택적으로 사용
try:
    import numpy as np
    USE_NUMPY = True
except ImportError:
    USE_NUMPY = False

# 한국어 형태소 분석
try:
    from konlpy.tag import Okt
    USE_KONLPY = True
except ImportError:
    USE_KONLPY = False
    print("Warning: KoNLPy not installed. Using basic analysis.", file=sys.stderr)

class InteractiveAnalyzer:
    """대화형 자소서 답변 분석기"""
    
    def __init__(self):
        """초기화"""
        if USE_KONLPY:
            self.okt = Okt()
        
        # 직무별 핵심 역량 키워드
        self.job_competencies = {
            "개발자": ["프로그래밍", "알고리즘", "데이터베이스", "협업", "문제해결", "디버깅", "설계", "테스트"],
            "마케팅": ["시장분석", "기획", "프로모션", "데이터분석", "커뮤니케이션", "트렌드", "전략", "캠페인"],
            "영업": ["협상", "고객관리", "목표달성", "프레젠테이션", "네트워킹", "시장개척", "관계구축"],
            "디자인": ["창의성", "툴활용", "UX", "UI", "트렌드", "컨셉", "비주얼", "사용자중심"],
            "기획": ["분석", "전략", "프로젝트", "문서작성", "조사", "아이디어", "실행", "관리"]
        }
        
        # STAR 기법 키워드
        self.star_keywords = {
            "situation": ["상황", "때", "당시", "환경", "배경", "조건", "시기"],
            "task": ["과제", "목표", "문제", "해결", "개선", "미션", "임무", "책임"],
            "action": ["실행", "진행", "수행", "노력", "시도", "접근", "방법", "활동"],
            "result": ["결과", "성과", "달성", "개선", "향상", "효과", "변화", "성공"]
        }
        
        # AI 티나는 표현들
        self.ai_cliches = [
            "귀사", "저는 믿습니다", "열정적인", "도전정신", "성실한",
            "팀워크", "긍정적인", "창의적인", "혁신적인", "글로벌",
            "시너지", "패러다임", "비전", "미션", "핵심가치"
        ]
        
    def analyze_response(self, response: str, position: str = None, 
                        conversation_history: List[Dict] = None) -> Dict[str, Any]:
        """
        사용자 응답 종합 분석
        
        Args:
            response: 사용자 답변
            position: 지원 직무
            conversation_history: 대화 히스토리
            
        Returns:
            분석 결과 딕셔너리
        """
        results = {
            "quality_score": self.calculate_quality_score(response),
            "specificity": self.check_specificity(response),
            "star_compliance": self.check_star_compliance(response),
            "authenticity": self.check_authenticity(response),
            "keywords": self.extract_keywords(response),
            "competencies": self.extract_competencies(response, position),
            "improvement_tips": []
        }
        
        # 개선 제안 생성
        results["improvement_tips"] = self.generate_improvement_tips(results)
        
        # 전체 대화 기반 분석 (히스토리가 있는 경우)
        if conversation_history:
            results["conversation_analysis"] = self.analyze_conversation(
                conversation_history, position
            )
        
        return results
    
    def calculate_quality_score(self, response: str) -> Dict[str, float]:
        """
        답변 품질 점수 계산
        
        Returns:
            각 항목별 점수 (0-100)
        """
        scores = {
            "length": self._score_length(response),
            "specificity": self._score_specificity(response),
            "structure": self._score_structure(response),
            "uniqueness": self._score_uniqueness(response)
        }
        
        scores["overall"] = sum(scores.values()) / len(scores)
        return scores
    
    def _score_length(self, text: str) -> float:
        """답변 길이 점수"""
        word_count = len(text.split())
        if word_count < 30:
            return 30.0
        elif word_count < 50:
            return 50.0
        elif word_count < 150:
            return 80.0
        elif word_count < 300:
            return 100.0
        else:
            return 70.0  # 너무 긴 답변
    
    def _score_specificity(self, text: str) -> float:
        """구체성 점수"""
        score = 0.0
        
        # 숫자 포함 여부 (기간, 성과 등)
        if re.search(r'\d+', text):
            score += 30
        
        # 구체적 시간 표현
        time_patterns = r'(년|개월|월|주|일|시간|분기|학기|회)'
        if re.search(time_patterns, text):
            score += 20
        
        # 구체적 행동 동사
        action_verbs = ["개발", "작성", "분석", "설계", "관리", "진행", "수행", "달성"]
        for verb in action_verbs:
            if verb in text:
                score += 10
                if score >= 50:
                    break
        
        return min(score, 100.0)
    
    def _score_structure(self, text: str) -> float:
        """구조 점수 (STAR 기법 등)"""
        sentences = text.split('.')
        if len(sentences) < 3:
            return 30.0
        
        # 순차적 구조 체크
        has_situation = any(kw in text for kw in ["당시", "때", "상황"])
        has_action = any(kw in text for kw in ["수행", "진행", "실행", "했습니다"])
        has_result = any(kw in text for kw in ["결과", "성과", "달성"])
        
        score = 40.0
        if has_situation:
            score += 20
        if has_action:
            score += 20
        if has_result:
            score += 20
        
        return score
    
    def _score_uniqueness(self, text: str) -> float:
        """독창성 점수 (AI 클리셰 회피)"""
        score = 100.0
        
        # AI 클리셰 체크
        for cliche in self.ai_cliches:
            if cliche in text:
                score -= 10
        
        return max(score, 0.0)
    
    def check_specificity(self, response: str) -> Dict[str, Any]:
        """구체성 상세 분석"""
        return {
            "has_numbers": bool(re.search(r'\d+', response)),
            "has_timeframe": bool(re.search(r'(년|개월|월|주|일)', response)),
            "has_metrics": bool(re.search(r'(%|퍼센트|증가|감소|향상)', response)),
            "has_examples": "예를" in response or "경우" in response,
            "score": self._score_specificity(response)
        }
    
    def check_star_compliance(self, response: str) -> Dict[str, Any]:
        """STAR 기법 준수 여부 체크"""
        compliance = {}
        
        for component, keywords in self.star_keywords.items():
            found = any(kw in response for kw in keywords)
            compliance[component] = found
        
        # 전체 준수율
        compliance_rate = sum(compliance.values()) / len(compliance) * 100
        
        return {
            "components": compliance,
            "compliance_rate": compliance_rate,
            "missing": [k for k, v in compliance.items() if not v]
        }
    
    def check_authenticity(self, response: str) -> Dict[str, Any]:
        """진정성 평가 (AI 티 검사)"""
        ai_score = 0
        detected_cliches = []
        
        for cliche in self.ai_cliches:
            if cliche in response:
                ai_score += 1
                detected_cliches.append(cliche)
        
        # 진정성 점수 (AI 클리셰가 적을수록 높음)
        authenticity_score = max(100 - (ai_score * 15), 0)
        
        return {
            "authenticity_score": authenticity_score,
            "detected_cliches": detected_cliches,
            "is_authentic": authenticity_score >= 70
        }
    
    def extract_keywords(self, response: str) -> List[str]:
        """핵심 키워드 추출"""
        if USE_KONLPY:
            # 형태소 분석 사용
            nouns = self.okt.nouns(response)
            # 2글자 이상 명사만 필터링
            keywords = [noun for noun in nouns if len(noun) >= 2]
        else:
            # 간단한 키워드 추출 (공백 기준)
            words = response.split()
            keywords = [w for w in words if len(w) >= 4]  # 4글자 이상
        
        # 빈도수 기준 상위 10개
        counter = Counter(keywords)
        return [kw for kw, _ in counter.most_common(10)]
    
    def extract_competencies(self, response: str, position: str = None) -> Dict[str, Any]:
        """역량 추출 및 매칭"""
        found_competencies = []
        
        # 직무별 역량 체크
        if position:
            # 직무 키워드 매칭
            for job_type, competencies in self.job_competencies.items():
                if job_type in position:
                    for comp in competencies:
                        if comp in response:
                            found_competencies.append(comp)
                    break
        
        # 일반 역량 체크
        general_competencies = ["리더십", "소통", "협업", "문제해결", "책임감", "도전", "창의"]
        for comp in general_competencies:
            if comp in response:
                found_competencies.append(comp)
        
        return {
            "found": list(set(found_competencies)),
            "count": len(set(found_competencies)),
            "coverage": len(set(found_competencies)) / 5 * 100  # 5개 이상이 이상적
        }
    
    def generate_improvement_tips(self, analysis_results: Dict) -> List[str]:
        """개선 제안 생성"""
        tips = []
        
        # 구체성 부족
        if analysis_results["specificity"]["score"] < 50:
            tips.append("💡 구체적인 숫자나 기간을 추가해보세요. 예: '3개월 동안', '20% 향상'")
        
        # STAR 기법 미준수
        star = analysis_results["star_compliance"]
        if star["compliance_rate"] < 75:
            missing = star["missing"]
            if "situation" in missing:
                tips.append("📝 어떤 상황이었는지 배경을 설명해주세요")
            if "task" in missing:
                tips.append("🎯 해결해야 했던 과제나 목표를 명시해주세요")
            if "action" in missing:
                tips.append("⚡ 구체적으로 어떤 행동을 취했는지 설명해주세요")
            if "result" in missing:
                tips.append("🏆 그 결과 어떤 성과를 얻었는지 추가해주세요")
        
        # 진정성 부족
        if analysis_results["authenticity"]["authenticity_score"] < 70:
            tips.append("✨ 좀 더 자연스럽고 개인적인 표현을 사용해보세요")
        
        # 길이 부족
        if analysis_results["quality_score"]["length"] < 50:
            tips.append("📏 조금 더 자세히 설명해주시면 좋겠어요")
        
        return tips
    
    def analyze_conversation(self, history: List[Dict], position: str = None) -> Dict[str, Any]:
        """전체 대화 분석"""
        all_user_messages = [msg["content"] for msg in history if msg["role"] == "user"]
        full_text = " ".join(all_user_messages)
        
        # 전체 키워드
        all_keywords = self.extract_keywords(full_text)
        
        # 일관성 체크 (반복되는 키워드)
        keyword_freq = Counter(all_keywords)
        consistent_themes = [kw for kw, freq in keyword_freq.items() if freq >= 2]
        
        # 전체 역량 커버리지
        all_competencies = self.extract_competencies(full_text, position)
        
        # 발전도 (답변이 점점 구체적이 되는지)
        quality_progression = []
        for msg in all_user_messages:
            score = self._score_specificity(msg)
            quality_progression.append(score)
        
        is_improving = False
        if len(quality_progression) >= 2:
            is_improving = quality_progression[-1] > quality_progression[0]
        
        return {
            "total_messages": len(all_user_messages),
            "consistent_themes": consistent_themes,
            "overall_competencies": all_competencies,
            "quality_progression": quality_progression,
            "is_improving": is_improving,
            "average_quality": sum(quality_progression) / len(quality_progression) if quality_progression else 0
        }


def main():
    """메인 실행 함수"""
    if len(sys.argv) < 2:
        print(json.dumps({
            "success": False,
            "error": "사용법: python interactive_analyzer.py '<response_json>'"
        }))
        sys.exit(1)
    
    try:
        # JSON 입력 파싱
        input_data = json.loads(sys.argv[1])
        
        response = input_data.get("response", "")
        position = input_data.get("position", None)
        history = input_data.get("conversation_history", [])
        
        # 분석 실행
        analyzer = InteractiveAnalyzer()
        result = analyzer.analyze_response(response, position, history)
        
        # 결과 출력
        output = {
            "success": True,
            "analysis": result
        }
        print(json.dumps(output, ensure_ascii=False, indent=2))
        
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }, ensure_ascii=False))
        sys.exit(1)


if __name__ == "__main__":
    main()