#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
채용공고 분석기
- 플레이라이트 MCP와 연동하여 채용공고 데이터 분석
- 키워드 추출, 요구사항 분석, 트렌드 분석
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
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize, sent_tokenize
from nltk.tag import pos_tag
from nltk.chunk import ne_chunk
from dotenv import load_dotenv

# 환경변수 로드
load_dotenv()

class JobPostingAnalyzer:
    """채용공고 분석기 클래스"""
    
    def __init__(self):
        """초기화"""
        self.korean_stopwords = {
            '이', '그', '저', '것', '들', '에', '를', '은', '는', '이', '가', 
            '으로', '로', '에서', '와', '과', '도', '만', '까지', '부터', '처럼',
            '같이', '보다', '더', '가장', '매우', '정말', '너무', '아주', '잘',
            '좋은', '나쁜', '크다', '작다', '많다', '적다', '높다', '낮다',
            '및', '또는', '그리고', '하지만', '그러나', '따라서', '그래서'
        }
        
        # 기술 스택 키워드
        self.tech_keywords = {
            'languages': ['Python', 'Java', 'JavaScript', 'TypeScript', 'Go', 'Rust', 'C++', 'C#', 'PHP', 'Ruby', 'Swift', 'Kotlin'],
            'frameworks': ['React', 'Vue.js', 'Angular', 'Django', 'Flask', 'Spring', 'Express', 'Next.js', 'Nuxt.js'],
            'databases': ['MySQL', 'PostgreSQL', 'MongoDB', 'Redis', 'Elasticsearch', 'Oracle', 'SQLite'],
            'cloud': ['AWS', 'GCP', 'Azure', 'Docker', 'Kubernetes', 'Jenkins', 'GitHub Actions'],
            'tools': ['Git', 'Jira', 'Slack', 'Figma', 'Sketch', 'Photoshop', 'Illustrator']
        }
        
        # 직무별 키워드
        self.job_categories = {
            'developer': ['개발자', '개발', 'Developer', 'Engineer', '엔지니어', '프로그래머', '코딩'],
            'designer': ['디자이너', '디자인', 'Designer', 'UI', 'UX', '시각디자인', '웹디자인'],
            'marketing': ['마케팅', 'Marketing', '홍보', '브랜딩', 'PR', '광고', '퍼포먼스마케팅'],
            'sales': ['영업', '세일즈', 'Sales', '비즈니스개발', 'BD', '고객관리'],
            'data': ['데이터', 'Data', '분석', 'Analytics', '데이터사이언스', 'ML', '머신러닝']
        }
        
        # NLTK 데이터 다운로드 (필요시)
        self._download_nltk_data()
    
    def _download_nltk_data(self):
        """NLTK 데이터 다운로드"""
        try:
            nltk.data.find('tokenizers/punkt')
            nltk.data.find('corpora/stopwords')
            nltk.data.find('taggers/averaged_perceptron_tagger')
            nltk.data.find('chunkers/maxent_ne_chunker')
            nltk.data.find('corpora/words')
        except LookupError:
            print("NLTK 데이터 다운로드 중...")
            nltk.download('punkt', quiet=True)
            nltk.download('stopwords', quiet=True)
            nltk.download('averaged_perceptron_tagger', quiet=True)
            nltk.download('maxent_ne_chunker', quiet=True)
            nltk.download('words', quiet=True)
    
    def analyze_job_posting(self, job_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        채용공고 종합 분석
        
        Args:
            job_data: 채용공고 데이터
            
        Returns:
            분석 결과 딕셔너리
        """
        try:
            # 텍스트 추출
            text_content = self._extract_text_content(job_data)
            
            # 기본 분석
            basic_analysis = self._basic_text_analysis(text_content)
            
            # 키워드 분석
            keyword_analysis = self._extract_keywords(text_content)
            
            # 기술 스택 분석
            tech_analysis = self._analyze_tech_stack(text_content)
            
            # 요구사항 분석
            requirements_analysis = self._analyze_requirements(text_content)
            
            # 직무 분류
            job_category = self._classify_job_category(text_content)
            
            # 경력 요구사항 분석
            experience_analysis = self._analyze_experience_requirements(text_content)
            
            # 회사 정보 분석
            company_analysis = self._analyze_company_info(job_data)
            
            # 급여 정보 분석
            salary_analysis = self._analyze_salary_info(text_content)
            
            return {
                'basic_info': {
                    'company_name': job_data.get('company_name', ''),
                    'position': job_data.get('position', ''),
                    'job_category': job_category,
                    'analysis_date': self._get_current_datetime()
                },
                'text_analysis': basic_analysis,
                'keywords': keyword_analysis,
                'tech_stack': tech_analysis,
                'requirements': requirements_analysis,
                'experience': experience_analysis,
                'company_info': company_analysis,
                'salary_info': salary_analysis,
                'score': self._calculate_overall_score(keyword_analysis, tech_analysis, requirements_analysis)
            }
            
        except Exception as e:
            return {
                'error': str(e),
                'analysis_date': self._get_current_datetime()
            }
    
    def _extract_text_content(self, job_data: Dict[str, Any]) -> str:
        """채용공고에서 텍스트 내용 추출"""
        content_parts = []
        
        # 제목
        if job_data.get('title'):
            content_parts.append(job_data['title'])
        
        # 회사명
        if job_data.get('company_name'):
            content_parts.append(job_data['company_name'])
        
        # 본문 내용
        if job_data.get('content'):
            content_parts.append(job_data['content'])
        
        # HTML에서 텍스트 추출
        if job_data.get('html_content'):
            soup = BeautifulSoup(job_data['html_content'], 'html.parser')
            content_parts.append(soup.get_text())
        
        return ' '.join(content_parts)
    
    def _basic_text_analysis(self, text: str) -> Dict[str, Any]:
        """기본 텍스트 분석"""
        # 문장 및 단어 수
        sentences = sent_tokenize(text)
        words = word_tokenize(text.lower())
        
        # 한글 단어만 필터링
        korean_words = [word for word in words if re.match(r'^[가-힣]+$', word)]
        
        return {
            'total_characters': len(text),
            'total_sentences': len(sentences),
            'total_words': len(words),
            'korean_words': len(korean_words),
            'avg_sentence_length': len(words) / len(sentences) if sentences else 0,
            'reading_time_minutes': len(words) / 200  # 평균 읽기 속도 200단어/분
        }
    
    def _extract_keywords(self, text: str) -> Dict[str, Any]:
        """키워드 추출 및 분석"""
        # 한글 단어 추출
        korean_words = re.findall(r'[가-힣]{2,}', text)
        
        # 불용어 제거
        filtered_words = [word for word in korean_words if word not in self.korean_stopwords]
        
        # 빈도 분석
        word_freq = Counter(filtered_words)
        
        # 영어 키워드 추출
        english_words = re.findall(r'[A-Za-z]{3,}', text)
        english_freq = Counter([word.lower() for word in english_words])
        
        return {
            'top_korean_keywords': word_freq.most_common(20),
            'top_english_keywords': english_freq.most_common(15),
            'total_unique_words': len(word_freq) + len(english_freq),
            'keyword_density': len(filtered_words) / len(text.split()) if text.split() else 0
        }
    
    def _analyze_tech_stack(self, text: str) -> Dict[str, Any]:
        """기술 스택 분석"""
        found_tech = defaultdict(list)
        
        for category, keywords in self.tech_keywords.items():
            for keyword in keywords:
                # 대소문자 구분 없이 검색
                if re.search(rf'\b{re.escape(keyword)}\b', text, re.IGNORECASE):
                    found_tech[category].append(keyword)
        
        # 기술 스택 점수 계산
        tech_score = sum(len(techs) for techs in found_tech.values())
        
        return {
            'found_technologies': dict(found_tech),
            'tech_diversity_score': len(found_tech),
            'total_tech_count': tech_score,
            'most_required_category': max(found_tech.items(), key=lambda x: len(x[1]))[0] if found_tech else None
        }
    
    def _analyze_requirements(self, text: str) -> Dict[str, Any]:
        """요구사항 분석"""
        # 필수/우대 조건 패턴
        required_patterns = [
            r'필수.*?(?=우대|자격|혜택|근무|$)',
            r'요구사항.*?(?=우대|자격|혜택|근무|$)',
            r'지원자격.*?(?=우대|자격|혜택|근무|$)'
        ]
        
        preferred_patterns = [
            r'우대.*?(?=자격|혜택|근무|복리|$)',
            r'가산점.*?(?=자격|혜택|근무|복리|$)'
        ]
        
        required_items = []
        preferred_items = []
        
        # 필수 조건 추출
        for pattern in required_patterns:
            matches = re.findall(pattern, text, re.DOTALL | re.IGNORECASE)
            for match in matches:
                items = re.split(r'[•\-\*\n]', match.strip())
                required_items.extend([item.strip() for item in items if item.strip()])
        
        # 우대 조건 추출
        for pattern in preferred_patterns:
            matches = re.findall(pattern, text, re.DOTALL | re.IGNORECASE)
            for match in matches:
                items = re.split(r'[•\-\*\n]', match.strip())
                preferred_items.extend([item.strip() for item in items if item.strip()])
        
        return {
            'required_qualifications': required_items[:10],  # 상위 10개만
            'preferred_qualifications': preferred_items[:10],
            'total_requirements': len(required_items) + len(preferred_items)
        }
    
    def _classify_job_category(self, text: str) -> str:
        """직무 분류"""
        category_scores = {}
        
        for category, keywords in self.job_categories.items():
            score = 0
            for keyword in keywords:
                score += len(re.findall(rf'\b{re.escape(keyword)}\b', text, re.IGNORECASE))
            category_scores[category] = score
        
        if category_scores:
            return max(category_scores.items(), key=lambda x: x[1])[0]
        return 'general'
    
    def _analyze_experience_requirements(self, text: str) -> Dict[str, Any]:
        """경력 요구사항 분석"""
        # 경력 관련 패턴
        experience_patterns = [
            r'(\d+)년\s*이상',
            r'경력\s*(\d+)년',
            r'(\d+)년차',
            r'신입|신규|new|junior',
            r'시니어|senior|책임|선임'
        ]
        
        experience_info = {
            'min_years': None,
            'max_years': None,
            'is_entry_level': False,
            'is_senior_level': False,
            'experience_keywords': []
        }
        
        # 년수 추출
        years = []
        for pattern in experience_patterns[:3]:
            matches = re.findall(pattern, text, re.IGNORECASE)
            years.extend([int(match) for match in matches if match.isdigit()])
        
        if years:
            experience_info['min_years'] = min(years)
            experience_info['max_years'] = max(years)
        
        # 신입/시니어 여부
        if re.search(r'신입|신규|new|junior', text, re.IGNORECASE):
            experience_info['is_entry_level'] = True
        
        if re.search(r'시니어|senior|책임|선임', text, re.IGNORECASE):
            experience_info['is_senior_level'] = True
        
        return experience_info
    
    def _analyze_company_info(self, job_data: Dict[str, Any]) -> Dict[str, Any]:
        """회사 정보 분석"""
        company_info = {
            'company_name': job_data.get('company_name', ''),
            'industry': job_data.get('industry', ''),
            'company_size': job_data.get('company_size', ''),
            'location': job_data.get('location', ''),
            'company_type': self._classify_company_type(job_data.get('company_name', ''))
        }
        
        return company_info
    
    def _classify_company_type(self, company_name: str) -> str:
        """회사 유형 분류"""
        if not company_name:
            return 'unknown'
        
        # 대기업 패턴
        large_company_patterns = ['삼성', 'LG', 'SK', '현대', '롯데', 'KT', 'CJ', '한화', '포스코', 'GS']
        if any(pattern in company_name for pattern in large_company_patterns):
            return 'large_enterprise'
        
        # 스타트업 패턴
        startup_patterns = ['스타트업', 'startup', '벤처']
        if any(pattern in company_name.lower() for pattern in startup_patterns):
            return 'startup'
        
        # IT 회사 패턴
        it_patterns = ['테크', 'tech', 'IT', '소프트웨어', 'software']
        if any(pattern in company_name.lower() for pattern in it_patterns):
            return 'tech_company'
        
        return 'general'
    
    def _analyze_salary_info(self, text: str) -> Dict[str, Any]:
        """급여 정보 분석"""
        salary_info = {
            'has_salary_info': False,
            'salary_range': None,
            'salary_type': None,  # annual, monthly, hourly
            'benefits': []
        }
        
        # 급여 패턴
        salary_patterns = [
            r'연봉\s*(\d+(?:,\d+)*)\s*만원',
            r'월급\s*(\d+(?:,\d+)*)\s*만원',
            r'시급\s*(\d+(?:,\d+)*)\s*원'
        ]
        
        for i, pattern in enumerate(salary_patterns):
            matches = re.findall(pattern, text)
            if matches:
                salary_info['has_salary_info'] = True
                salary_info['salary_range'] = matches[0]
                salary_info['salary_type'] = ['annual', 'monthly', 'hourly'][i]
                break
        
        # 복리후생 키워드
        benefit_keywords = ['4대보험', '퇴직금', '연차', '휴가', '교육지원', '식대', '교통비', '건강검진']
        found_benefits = [keyword for keyword in benefit_keywords if keyword in text]
        salary_info['benefits'] = found_benefits
        
        return salary_info
    
    def _calculate_overall_score(self, keywords: Dict, tech: Dict, requirements: Dict) -> float:
        """전체적인 채용공고 점수 계산"""
        score = 0.0
        
        # 키워드 다양성 점수 (0-30)
        keyword_score = min(len(keywords.get('top_korean_keywords', [])) * 1.5, 30)
        
        # 기술 스택 점수 (0-40)
        tech_score = min(tech.get('total_tech_count', 0) * 4, 40)
        
        # 요구사항 명확성 점수 (0-30)
        req_score = min(requirements.get('total_requirements', 0) * 3, 30)
        
        total_score = keyword_score + tech_score + req_score
        return round(total_score, 1)
    
    def _get_current_datetime(self) -> str:
        """현재 날짜시간 반환"""
        from datetime import datetime
        return datetime.now().isoformat()
    
    def generate_analysis_report(self, analysis_result: Dict[str, Any]) -> str:
        """분석 결과 리포트 생성"""
        if 'error' in analysis_result:
            return f"분석 중 오류가 발생했습니다: {analysis_result['error']}"
        
        report = []
        
        # 기본 정보
        basic = analysis_result.get('basic_info', {})
        report.append(f"# 📊 채용공고 분석 리포트")
        report.append(f"**회사명**: {basic.get('company_name', 'N/A')}")
        report.append(f"**직무**: {basic.get('position', 'N/A')}")
        report.append(f"**분류**: {basic.get('job_category', 'N/A')}")
        report.append(f"**분석일시**: {basic.get('analysis_date', 'N/A')}")
        report.append("")
        
        # 전체 점수
        score = analysis_result.get('score', 0)
        report.append(f"## 🎯 종합 점수: {score}/100")
        report.append("")
        
        # 기술 스택
        tech = analysis_result.get('tech_stack', {})
        if tech.get('found_technologies'):
            report.append("## 🛠️ 요구 기술 스택")
            for category, techs in tech['found_technologies'].items():
                if techs:
                    report.append(f"**{category.title()}**: {', '.join(techs)}")
            report.append("")
        
        # 키워드 분석
        keywords = analysis_result.get('keywords', {})
        if keywords.get('top_korean_keywords'):
            report.append("## 🔍 주요 키워드")
            top_keywords = keywords['top_korean_keywords'][:10]
            keyword_list = [f"{word} ({count})" for word, count in top_keywords]
            report.append(", ".join(keyword_list))
            report.append("")
        
        # 경력 요구사항
        exp = analysis_result.get('experience', {})
        report.append("## 👨‍💼 경력 요구사항")
        if exp.get('min_years'):
            report.append(f"**최소 경력**: {exp['min_years']}년")
        if exp.get('is_entry_level'):
            report.append("**신입 가능**: ✅")
        if exp.get('is_senior_level'):
            report.append("**시니어 레벨**: ✅")
        report.append("")
        
        # 급여 정보
        salary = analysis_result.get('salary_info', {})
        if salary.get('has_salary_info'):
            report.append("## 💰 급여 정보")
            report.append(f"**급여 범위**: {salary.get('salary_range', 'N/A')}")
            report.append(f"**급여 유형**: {salary.get('salary_type', 'N/A')}")
            if salary.get('benefits'):
                report.append(f"**복리후생**: {', '.join(salary['benefits'])}")
            report.append("")
        
        return "\n".join(report)

def main():
    """메인 함수 - 테스트용"""
    analyzer = JobPostingAnalyzer()
    
    # 테스트 데이터
    test_job_data = {
        'company_name': '삼성전자',
        'position': '소프트웨어 개발자',
        'title': '삼성전자 소프트웨어 개발자 채용',
        'content': '''
        삼성전자에서 우수한 소프트웨어 개발자를 모집합니다.
        
        [지원자격]
        - 컴퓨터공학 관련 학과 졸업자
        - Java, Python, JavaScript 개발 경험 3년 이상
        - Spring Framework, React 사용 경험
        - AWS 클라우드 서비스 경험
        
        [우대사항]
        - Docker, Kubernetes 경험자
        - 대용량 데이터 처리 경험
        - 영어 회화 가능자
        
        [근무조건]
        - 연봉 5000만원 이상
        - 4대보험, 퇴직금, 연차 제공
        - 교육비 지원
        '''
    }
    
    # 분석 실행
    result = analyzer.analyze_job_posting(test_job_data)
    
    # 리포트 생성
    report = analyzer.generate_analysis_report(result)
    
    print("=== 채용공고 분석 결과 ===")
    print(report)
    print("\n=== JSON 결과 ===")
    print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
