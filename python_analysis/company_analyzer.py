#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
기업 분석기
- 플레이라이트 MCP와 연동하여 기업 정보 분석
- 뉴스 분석, 재무 정보, 기업 문화, 성장성 분석
"""

import os
import sys
import json
import re
from collections import Counter, defaultdict
from typing import Dict, List, Tuple, Any, Optional
import requests
from bs4 import BeautifulSoup
import nltk
from datetime import datetime, timedelta
from dotenv import load_dotenv

# 환경변수 로드
load_dotenv()

class CompanyAnalyzer:
    """기업 분석기 클래스"""
    
    def __init__(self):
        """초기화"""
        self.industry_keywords = {
            'tech': ['기술', '개발', 'AI', '인공지능', '빅데이터', '클라우드', 'IoT', '블록체인', '5G'],
            'finance': ['금융', '은행', '증권', '보험', '투자', '자산관리', 'fintech', '핀테크'],
            'manufacturing': ['제조', '생산', '공장', '자동차', '반도체', '화학', '철강', '조선'],
            'retail': ['유통', '소매', '쇼핑', '이커머스', '백화점', '마트', '편의점'],
            'healthcare': ['의료', '병원', '제약', '바이오', '헬스케어', '의료기기'],
            'education': ['교육', '학원', '대학', '연구소', 'edtech', '에듀테크']
        }
        
        self.company_size_indicators = {
            'large': ['대기업', '글로벌', '상장', '코스피', '코스닥', '그룹', '계열사'],
            'medium': ['중견기업', '중소기업', '성장기업'],
            'startup': ['스타트업', '벤처', '신생', '창업', '초기기업']
        }
        
        self.positive_keywords = [
            '성장', '확장', '투자', '혁신', '개발', '출시', '성공', '증가', '상승', '개선',
            '수상', '인증', '파트너십', '협력', '신규', '런칭', '확대', '강화'
        ]
        
        self.negative_keywords = [
            '감소', '하락', '손실', '적자', '위기', '문제', '논란', '소송', '제재',
            '구조조정', '인력감축', '폐쇄', '중단', '연기', '취소'
        ]
    
    def analyze_company(self, company_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        기업 종합 분석
        
        Args:
            company_data: 기업 데이터
            
        Returns:
            분석 결과 딕셔너리
        """
        try:
            # 기본 정보 분석
            basic_info = self._analyze_basic_info(company_data)
            
            # 산업 분류
            industry_analysis = self._classify_industry(company_data)
            
            # 기업 규모 분석
            size_analysis = self._analyze_company_size(company_data)
            
            # 뉴스 분석
            news_analysis = self._analyze_news_sentiment(company_data.get('news_data', []))
            
            # 재무 정보 분석
            financial_analysis = self._analyze_financial_info(company_data.get('financial_data', {}))
            
            # 채용 트렌드 분석
            hiring_analysis = self._analyze_hiring_trends(company_data.get('job_postings', []))
            
            # 기업 문화 분석
            culture_analysis = self._analyze_company_culture(company_data)
            
            # 경쟁사 분석
            competitor_analysis = self._analyze_competitors(company_data.get('competitors', []))
            
            # 종합 점수 계산
            overall_score = self._calculate_company_score(
                news_analysis, financial_analysis, hiring_analysis, culture_analysis
            )
            
            return {
                'basic_info': basic_info,
                'industry': industry_analysis,
                'company_size': size_analysis,
                'news_sentiment': news_analysis,
                'financial_health': financial_analysis,
                'hiring_trends': hiring_analysis,
                'company_culture': culture_analysis,
                'competitor_analysis': competitor_analysis,
                'overall_score': overall_score,
                'analysis_date': self._get_current_datetime(),
                'recommendations': self._generate_recommendations(news_analysis, financial_analysis, hiring_analysis)
            }
            
        except Exception as e:
            return {
                'error': str(e),
                'analysis_date': self._get_current_datetime()
            }
    
    def _analyze_basic_info(self, company_data: Dict[str, Any]) -> Dict[str, Any]:
        """기본 정보 분석"""
        return {
            'company_name': company_data.get('name', ''),
            'founded_year': company_data.get('founded', ''),
            'headquarters': company_data.get('location', ''),
            'ceo': company_data.get('ceo', ''),
            'website': company_data.get('website', ''),
            'employee_count': company_data.get('employees', ''),
            'business_description': company_data.get('description', '')
        }
    
    def _classify_industry(self, company_data: Dict[str, Any]) -> Dict[str, Any]:
        """산업 분류"""
        company_text = ' '.join([
            company_data.get('name', ''),
            company_data.get('description', ''),
            company_data.get('business_areas', '')
        ])
        
        industry_scores = {}
        for industry, keywords in self.industry_keywords.items():
            score = 0
            for keyword in keywords:
                score += len(re.findall(rf'\b{re.escape(keyword)}\b', company_text, re.IGNORECASE))
            industry_scores[industry] = score
        
        primary_industry = max(industry_scores.items(), key=lambda x: x[1])[0] if industry_scores else 'general'
        
        return {
            'primary_industry': primary_industry,
            'industry_scores': industry_scores,
            'industry_keywords_found': [kw for kw in self.industry_keywords[primary_industry] if kw in company_text.lower()]
        }
    
    def _analyze_company_size(self, company_data: Dict[str, Any]) -> Dict[str, Any]:
        """기업 규모 분석"""
        company_text = ' '.join([
            company_data.get('name', ''),
            company_data.get('description', ''),
            str(company_data.get('employees', ''))
        ])
        
        size_scores = {}
        for size, indicators in self.company_size_indicators.items():
            score = 0
            for indicator in indicators:
                score += len(re.findall(rf'\b{re.escape(indicator)}\b', company_text, re.IGNORECASE))
            size_scores[size] = score
        
        # 직원 수 기반 분류
        employee_count = company_data.get('employees', '')
        if isinstance(employee_count, str) and employee_count.isdigit():
            count = int(employee_count)
            if count >= 1000:
                employee_based_size = 'large'
            elif count >= 100:
                employee_based_size = 'medium'
            else:
                employee_based_size = 'startup'
        else:
            employee_based_size = 'unknown'
        
        keyword_based_size = max(size_scores.items(), key=lambda x: x[1])[0] if size_scores else 'unknown'
        
        return {
            'estimated_size': keyword_based_size if size_scores[keyword_based_size] > 0 else employee_based_size,
            'employee_count': employee_count,
            'size_indicators_found': size_scores
        }
    
    def _analyze_news_sentiment(self, news_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """뉴스 감정 분석"""
        if not news_data:
            return {
                'sentiment_score': 0,
                'positive_news_count': 0,
                'negative_news_count': 0,
                'neutral_news_count': 0,
                'recent_news_summary': [],
                'key_topics': []
            }
        
        positive_count = 0
        negative_count = 0
        neutral_count = 0
        all_topics = []
        recent_summaries = []
        
        for news in news_data[:20]:  # 최근 20개 뉴스만 분석
            title = news.get('title', '')
            content = news.get('content', '')
            news_text = f"{title} {content}"
            
            # 감정 점수 계산
            positive_score = sum(1 for keyword in self.positive_keywords if keyword in news_text)
            negative_score = sum(1 for keyword in self.negative_keywords if keyword in news_text)
            
            if positive_score > negative_score:
                positive_count += 1
                sentiment = 'positive'
            elif negative_score > positive_score:
                negative_count += 1
                sentiment = 'negative'
            else:
                neutral_count += 1
                sentiment = 'neutral'
            
            # 토픽 추출
            topics = re.findall(r'[가-힣]{3,}', title)
            all_topics.extend(topics)
            
            # 최근 뉴스 요약
            if len(recent_summaries) < 5:
                recent_summaries.append({
                    'title': title,
                    'date': news.get('date', ''),
                    'sentiment': sentiment,
                    'url': news.get('url', '')
                })
        
        total_news = len(news_data)
        sentiment_score = (positive_count - negative_count) / total_news if total_news > 0 else 0
        
        # 주요 토픽 추출
        topic_counter = Counter(all_topics)
        key_topics = [topic for topic, count in topic_counter.most_common(10) if count >= 2]
        
        return {
            'sentiment_score': round(sentiment_score, 3),
            'positive_news_count': positive_count,
            'negative_news_count': negative_count,
            'neutral_news_count': neutral_count,
            'total_news_analyzed': total_news,
            'recent_news_summary': recent_summaries,
            'key_topics': key_topics
        }
    
    def _analyze_financial_info(self, financial_data: Dict[str, Any]) -> Dict[str, Any]:
        """재무 정보 분석"""
        if not financial_data:
            return {
                'financial_health_score': 0,
                'revenue_trend': 'unknown',
                'profitability': 'unknown',
                'growth_indicators': []
            }
        
        # 매출 트렌드 분석
        revenue_trend = 'stable'
        if financial_data.get('revenue_growth', 0) > 10:
            revenue_trend = 'growing'
        elif financial_data.get('revenue_growth', 0) < -5:
            revenue_trend = 'declining'
        
        # 수익성 분석
        profit_margin = financial_data.get('profit_margin', 0)
        if profit_margin > 15:
            profitability = 'excellent'
        elif profit_margin > 5:
            profitability = 'good'
        elif profit_margin > 0:
            profitability = 'moderate'
        else:
            profitability = 'poor'
        
        # 성장 지표
        growth_indicators = []
        if financial_data.get('revenue_growth', 0) > 0:
            growth_indicators.append('매출 증가')
        if financial_data.get('employee_growth', 0) > 0:
            growth_indicators.append('인력 확대')
        if financial_data.get('rd_investment', 0) > 0:
            growth_indicators.append('R&D 투자')
        
        # 재무 건전성 점수 (0-100)
        health_score = 0
        health_score += min(financial_data.get('revenue_growth', 0) * 2, 40)  # 최대 40점
        health_score += min(profit_margin * 2, 30)  # 최대 30점
        health_score += min(len(growth_indicators) * 10, 30)  # 최대 30점
        
        return {
            'financial_health_score': max(0, min(100, round(health_score, 1))),
            'revenue_trend': revenue_trend,
            'profitability': profitability,
            'growth_indicators': growth_indicators,
            'key_metrics': {
                'revenue_growth': financial_data.get('revenue_growth', 0),
                'profit_margin': profit_margin,
                'employee_growth': financial_data.get('employee_growth', 0)
            }
        }
    
    def _analyze_hiring_trends(self, job_postings: List[Dict[str, Any]]) -> Dict[str, Any]:
        """채용 트렌드 분석"""
        if not job_postings:
            return {
                'hiring_activity_score': 0,
                'active_positions': 0,
                'top_hiring_departments': [],
                'required_skills': [],
                'hiring_trend': 'stable'
            }
        
        # 부서별 채용 현황
        departments = []
        all_skills = []
        
        for job in job_postings:
            dept = job.get('department', '기타')
            departments.append(dept)
            
            skills = job.get('required_skills', [])
            all_skills.extend(skills)
        
        dept_counter = Counter(departments)
        skill_counter = Counter(all_skills)
        
        # 채용 활성도 점수
        active_positions = len(job_postings)
        hiring_score = min(active_positions * 5, 100)  # 최대 100점
        
        # 채용 트렌드 판단
        if active_positions >= 10:
            hiring_trend = 'expanding'
        elif active_positions >= 5:
            hiring_trend = 'active'
        elif active_positions >= 1:
            hiring_trend = 'stable'
        else:
            hiring_trend = 'minimal'
        
        return {
            'hiring_activity_score': hiring_score,
            'active_positions': active_positions,
            'top_hiring_departments': dept_counter.most_common(5),
            'required_skills': skill_counter.most_common(10),
            'hiring_trend': hiring_trend
        }
    
    def _analyze_company_culture(self, company_data: Dict[str, Any]) -> Dict[str, Any]:
        """기업 문화 분석"""
        culture_text = ' '.join([
            company_data.get('culture_description', ''),
            company_data.get('values', ''),
            company_data.get('benefits', '')
        ])
        
        # 문화 키워드
        culture_keywords = {
            'innovation': ['혁신', '창의', '도전', '실험', '변화'],
            'collaboration': ['협업', '소통', '팀워크', '파트너십', '공유'],
            'growth': ['성장', '발전', '학습', '교육', '역량'],
            'work_life_balance': ['워라밸', '유연근무', '재택근무', '휴가', '복지'],
            'diversity': ['다양성', '포용', '평등', '존중', '개성']
        }
        
        culture_scores = {}
        found_keywords = {}
        
        for category, keywords in culture_keywords.items():
            score = 0
            found = []
            for keyword in keywords:
                if keyword in culture_text:
                    score += 1
                    found.append(keyword)
            culture_scores[category] = score
            found_keywords[category] = found
        
        # 주요 문화 특성
        top_cultures = sorted(culture_scores.items(), key=lambda x: x[1], reverse=True)[:3]
        
        return {
            'culture_scores': culture_scores,
            'dominant_culture_traits': [trait for trait, score in top_cultures if score > 0],
            'culture_keywords_found': found_keywords,
            'culture_strength_score': sum(culture_scores.values()) * 10  # 0-100 스케일
        }
    
    def _analyze_competitors(self, competitors: List[str]) -> Dict[str, Any]:
        """경쟁사 분석"""
        return {
            'main_competitors': competitors[:5],
            'competitive_landscape': 'competitive' if len(competitors) > 5 else 'moderate',
            'market_position': self._estimate_market_position(len(competitors))
        }
    
    def _estimate_market_position(self, competitor_count: int) -> str:
        """경쟁사 수를 기반으로 시장 위치 추정"""
        if competitor_count >= 10:
            return 'highly_competitive'
        elif competitor_count >= 5:
            return 'competitive'
        elif competitor_count >= 2:
            return 'moderate_competition'
        else:
            return 'market_leader'
    
    def _calculate_company_score(self, news_analysis: Dict, financial_analysis: Dict, 
                                hiring_analysis: Dict, culture_analysis: Dict) -> Dict[str, Any]:
        """기업 종합 점수 계산"""
        # 각 영역별 점수 (0-100)
        news_score = max(0, min(100, (news_analysis.get('sentiment_score', 0) + 1) * 50))
        financial_score = financial_analysis.get('financial_health_score', 0)
        hiring_score = hiring_analysis.get('hiring_activity_score', 0)
        culture_score = min(100, culture_analysis.get('culture_strength_score', 0))
        
        # 가중평균 계산
        weights = {'news': 0.25, 'financial': 0.35, 'hiring': 0.25, 'culture': 0.15}
        
        overall_score = (
            news_score * weights['news'] +
            financial_score * weights['financial'] +
            hiring_score * weights['hiring'] +
            culture_score * weights['culture']
        )
        
        # 등급 계산
        if overall_score >= 80:
            grade = 'A'
            rating = 'Excellent'
        elif overall_score >= 70:
            grade = 'B+'
            rating = 'Very Good'
        elif overall_score >= 60:
            grade = 'B'
            rating = 'Good'
        elif overall_score >= 50:
            grade = 'C+'
            rating = 'Fair'
        elif overall_score >= 40:
            grade = 'C'
            rating = 'Below Average'
        else:
            grade = 'D'
            rating = 'Poor'
        
        return {
            'overall_score': round(overall_score, 1),
            'grade': grade,
            'rating': rating,
            'component_scores': {
                'news_sentiment': round(news_score, 1),
                'financial_health': round(financial_score, 1),
                'hiring_activity': round(hiring_score, 1),
                'company_culture': round(culture_score, 1)
            }
        }
    
    def _generate_recommendations(self, news_analysis: Dict, financial_analysis: Dict, 
                                hiring_analysis: Dict) -> List[str]:
        """추천사항 생성"""
        recommendations = []
        
        # 뉴스 기반 추천
        if news_analysis.get('sentiment_score', 0) > 0.2:
            recommendations.append("✅ 최근 긍정적인 뉴스가 많아 기업 이미지가 좋습니다.")
        elif news_analysis.get('sentiment_score', 0) < -0.2:
            recommendations.append("⚠️ 최근 부정적인 뉴스가 있어 주의가 필요합니다.")
        
        # 재무 기반 추천
        if financial_analysis.get('revenue_trend') == 'growing':
            recommendations.append("📈 매출이 성장하고 있어 안정적인 기업입니다.")
        elif financial_analysis.get('revenue_trend') == 'declining':
            recommendations.append("📉 매출 감소 추세로 신중한 지원을 고려하세요.")
        
        # 채용 기반 추천
        if hiring_analysis.get('hiring_trend') == 'expanding':
            recommendations.append("🚀 활발한 채용 중으로 성장하는 기업입니다.")
        elif hiring_analysis.get('hiring_trend') == 'minimal':
            recommendations.append("💼 채용 활동이 적어 기회가 제한적일 수 있습니다.")
        
        return recommendations
    
    def _get_current_datetime(self) -> str:
        """현재 날짜시간 반환"""
        return datetime.now().isoformat()
    
    def generate_company_report(self, analysis_result: Dict[str, Any]) -> str:
        """기업 분석 리포트 생성"""
        if 'error' in analysis_result:
            return f"분석 중 오류가 발생했습니다: {analysis_result['error']}"
        
        report = []
        
        # 기본 정보
        basic = analysis_result.get('basic_info', {})
        report.append(f"# 🏢 기업 분석 리포트")
        report.append(f"**회사명**: {basic.get('company_name', 'N/A')}")
        report.append(f"**설립년도**: {basic.get('founded_year', 'N/A')}")
        report.append(f"**본사**: {basic.get('headquarters', 'N/A')}")
        report.append(f"**직원 수**: {basic.get('employee_count', 'N/A')}")
        report.append(f"**분석일시**: {analysis_result.get('analysis_date', 'N/A')}")
        report.append("")
        
        # 종합 점수
        score_info = analysis_result.get('overall_score', {})
        report.append(f"## 🎯 종합 평가")
        report.append(f"**점수**: {score_info.get('overall_score', 0)}/100 ({score_info.get('grade', 'N/A')})")
        report.append(f"**등급**: {score_info.get('rating', 'N/A')}")
        report.append("")
        
        # 산업 분류
        industry = analysis_result.get('industry', {})
        report.append(f"## 🏭 산업 분류")
        report.append(f"**주요 산업**: {industry.get('primary_industry', 'N/A')}")
        report.append("")
        
        # 뉴스 감정 분석
        news = analysis_result.get('news_sentiment', {})
        report.append(f"## 📰 뉴스 분석")
        report.append(f"**감정 점수**: {news.get('sentiment_score', 0)}")
        report.append(f"**긍정 뉴스**: {news.get('positive_news_count', 0)}개")
        report.append(f"**부정 뉴스**: {news.get('negative_news_count', 0)}개")
        if news.get('key_topics'):
            report.append(f"**주요 토픽**: {', '.join(news['key_topics'][:5])}")
        report.append("")
        
        # 채용 동향
        hiring = analysis_result.get('hiring_trends', {})
        report.append(f"## 👥 채용 동향")
        report.append(f"**채용 활성도**: {hiring.get('hiring_activity_score', 0)}/100")
        report.append(f"**활성 포지션**: {hiring.get('active_positions', 0)}개")
        report.append(f"**채용 트렌드**: {hiring.get('hiring_trend', 'N/A')}")
        report.append("")
        
        # 기업 문화
        culture = analysis_result.get('company_culture', {})
        if culture.get('dominant_culture_traits'):
            report.append(f"## 🎨 기업 문화")
            report.append(f"**주요 특성**: {', '.join(culture['dominant_culture_traits'])}")
            report.append("")
        
        # 추천사항
        recommendations = analysis_result.get('recommendations', [])
        if recommendations:
            report.append(f"## 💡 추천사항")
            for rec in recommendations:
                report.append(f"- {rec}")
            report.append("")
        
        return "\n".join(report)

def main():
    """메인 함수 - 테스트용"""
    analyzer = CompanyAnalyzer()
    
    # 테스트 데이터
    test_company_data = {
        'name': '삼성전자',
        'founded': '1969',
        'location': '경기도 수원시',
        'ceo': '한종희',
        'employees': '267937',
        'description': '글로벌 전자기업으로 반도체, 스마트폰, 가전제품을 제조하는 기술 혁신 기업',
        'business_areas': '반도체, 모바일, 가전, 디스플레이',
        'news_data': [
            {
                'title': '삼성전자, AI 반도체 투자 확대 발표',
                'content': '삼성전자가 인공지능 반도체 개발에 대규모 투자를 확대한다고 발표했다.',
                'date': '2024-01-15',
                'url': 'https://example.com/news1'
            },
            {
                'title': '삼성전자 3분기 실적 개선',
                'content': '삼성전자의 3분기 영업이익이 전년 대비 크게 증가했다.',
                'date': '2024-01-10',
                'url': 'https://example.com/news2'
            }
        ],
        'financial_data': {
            'revenue_growth': 12.5,
            'profit_margin': 18.2,
            'employee_growth': 5.3,
            'rd_investment': 15.8
        },
        'job_postings': [
            {'department': '개발', 'required_skills': ['Java', 'Python', 'AI']},
            {'department': '마케팅', 'required_skills': ['디지털마케팅', '데이터분석']},
            {'department': '개발', 'required_skills': ['React', 'Node.js']},
        ],
        'culture_description': '혁신과 도전을 중시하며, 창의적 사고와 협업을 통해 성장하는 기업문화',
        'competitors': ['LG전자', '애플', 'TSMC', '인텔', '퀄컴']
    }
    
    # 분석 실행
    result = analyzer.analyze_company(test_company_data)
    
    # 리포트 생성
    report = analyzer.generate_company_report(result)
    
    print("=== 기업 분석 결과 ===")
    print(report)
    print("\n=== JSON 결과 ===")
    print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
