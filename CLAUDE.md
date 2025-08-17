# Interview App - AI Assistant Instructions

## 🎯 Service Philosophy
우리는 자소서 "생성기"가 아닌 "코칭 파트너"입니다.
AI는 도구일 뿐, 진짜 이야기는 지원자 본인만이 쓸 수 있습니다.

## 📌 Core Values
- **진정성**: 지원자의 실제 경험과 감정을 담는다
- **차별화**: 천편일률적 표현을 피하고 개인의 고유함을 부각
- **코칭**: AI가 대신 쓰는 것이 아니라 함께 발굴하고 다듬는다

## 🚀 Key Features

### 1. Cover Letter Analysis (2단계 분석)
- **Location**: `/cover_letters/advanced`
- **Service**: `AdvancedCoverLetterService`
- **특징**: 
  - 병렬처리로 22초 내 분석 완료 (70% 속도 개선)
  - 15년차 HR 멘토 페르소나
  - 강점 5개, 개선점 5개, 숨은 보석 3개 상세 분석

### 2. Cover Letter Rewrite (3단계 리라이트)
- **Location**: `/cover_letters/:id/rewrite_with_feedback`
- **Service**: `generate_improved_letter` method
- **특징**:
  - 2단계 피드백 100% 반영
  - STAR 기법 자동 적용
  - AI 티 제거

### 3. Job Posting Analysis
- **Location**: `/cover_letters/job_posting`
- **Services**: 
  - `JobPostingAnalyzerService` (기본)
  - `EnhancedJobPostingAnalyzerService` (강화)
- **특징**:
  - URL 자동 크롤링
  - 6개 섹션 병렬 분석
  - 직무 요구사항 추출

## 🔧 Technical Details

### Environment Variables
```bash
OPENAI_API_KEY=your_key
OPENAI_MODEL=gpt-4o
USE_PARALLEL_ANALYSIS=true
```

### Database
- PostgreSQL with JSONB fields for analysis data
- Models: CoverLetter, JobAnalysis, CompanyAnalysis

### Performance
- 순차 처리: 76초
- 병렬 처리: 22초 (Thread-based)
- API Timeout: 180초

## 📝 Prompting Guidelines

### HR Mentor Persona
- 15년차 대기업 인사팀 경력
- 실전 경험 기반 조언
- 따뜻하지만 직설적인 피드백

### Analysis Structure
1. 첫인상 & 전체 느낌
2. 잘 쓴 부분 (강점 5개)
3. 개선 필요 (개선점 5개)
4. 숨은 보석 (3개)
5. 격려와 응원

### Rewrite Principles
- 경험 나열 → 스토리텔링
- 추상적 표현 → 구체적 사례
- 일반적 역량 → 직무 맞춤
- AI 문체 → 자연스러운 대화체

## ⚠️ Disabled Features
- GPT-5 Deep Analysis (너무 복잡, 실용성 낮음)
- Ontology Analysis
- Company Analysis (1단계)

## 📊 Success Metrics
- 분석 시간: 22초 이내
- 피드백 길이: 8000자 이상
- 개선점 반영률: 100%
- 사용자 만족도: 85% 이상

## 🎨 UI/UX Principles
- 대화형 인터페이스 지향
- 단계별 가이드 제공
- 진정성 체크리스트 표시
- AI 티 제거 인디케이터

## 💡 Future Roadmap
1. 대화형 경험 발굴 모듈
2. 진정성 스코어링 시스템
3. 실패 경험 스토리텔링 가이드
4. "내 이야기 찾기" 브랜딩

---
Remember: "합격의 열쇠는 완벽한 문장이 아니라 진정성 있는 당신의 이야기입니다"