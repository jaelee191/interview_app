#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Rails 연동 모듈
- Rails 애플리케이션과 파이썬 분석 스크립트 연동
- JSON 입출력으로 데이터 교환
"""

import sys
import json
import os
from pathlib import Path
from job_posting_analyzer import JobPostingAnalyzer
from company_analyzer import CompanyAnalyzer

def analyze_job_posting_from_rails(json_input: str) -> str:
    """
    Rails에서 전달받은 채용공고 데이터를 분석
    
    Args:
        json_input: JSON 형태의 채용공고 데이터
        
    Returns:
        JSON 형태의 분석 결과
    """
    try:
        # JSON 파싱
        job_data = json.loads(json_input)
        
        # 분석기 초기화
        analyzer = JobPostingAnalyzer()
        
        # 분석 실행
        result = analyzer.analyze_job_posting(job_data)
        
        # 리포트 생성
        report = analyzer.generate_analysis_report(result)
        result['report'] = report
        
        # JSON 반환
        return json.dumps(result, ensure_ascii=False, indent=2)
        
    except Exception as e:
        error_result = {
            'success': False,
            'error': str(e),
            'error_type': type(e).__name__
        }
        return json.dumps(error_result, ensure_ascii=False, indent=2)

def analyze_company_from_rails(json_input: str) -> str:
    """
    Rails에서 전달받은 기업 데이터를 분석
    
    Args:
        json_input: JSON 형태의 기업 데이터
        
    Returns:
        JSON 형태의 분석 결과
    """
    try:
        # JSON 파싱
        company_data = json.loads(json_input)
        
        # 분석기 초기화
        analyzer = CompanyAnalyzer()
        
        # 분석 실행
        result = analyzer.analyze_company(company_data)
        
        # 리포트 생성
        report = analyzer.generate_company_report(result)
        result['report'] = report
        
        # JSON 반환
        return json.dumps(result, ensure_ascii=False, indent=2)
        
    except Exception as e:
        error_result = {
            'success': False,
            'error': str(e),
            'error_type': type(e).__name__
        }
        return json.dumps(error_result, ensure_ascii=False, indent=2)

def main():
    """메인 함수 - 커맨드라인에서 호출"""
    if len(sys.argv) < 3:
        print("Usage: python rails_integration.py <command> <json_data>")
        print("Commands: analyze_job_posting, analyze_company")
        sys.exit(1)
    
    command = sys.argv[1]
    json_data = sys.argv[2]
    
    if command == "analyze_job_posting":
        result = analyze_job_posting_from_rails(json_data)
        print(result)
    elif command == "analyze_company":
        result = analyze_company_from_rails(json_data)
        print(result)
    else:
        error_result = {
            'success': False,
            'error': f'Unknown command: {command}',
            'available_commands': ['analyze_job_posting', 'analyze_company']
        }
        print(json.dumps(error_result, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
