# JACHUI 제품 기획서

## Executive Summary

JACHUI는 단순한 AI 자소서 작성 도구를 넘어, 기업의 진짜 니즈를 파악하고 지원자의 경험을 전략적으로 매칭하는 차별화된 취업 솔루션입니다.

## 시장 분석

### 문제 정의

#### 구직자의 Pain Points
1. **시간 소모**: 자소서 한 개 작성에 평균 2-3시간
2. **반복 작업**: 비슷한 내용을 회사마다 다시 작성
3. **키워드 파악 어려움**: 기업이 원하는 것이 무엇인지 불명확
4. **AI 탐지 우려**: ChatGPT로 작성 시 AI 탐지기에 걸림

#### 기존 서비스의 한계
1. **단순 키워드 매칭**: 채용공고 텍스트만 분석
2. **템플릿 의존**: 천편일률적인 자소서 양산
3. **맥락 무시**: 기업이 왜 지금 채용하는지 모름
4. **AI 티 남**: 명백히 AI가 작성한 문체

### 시장 기회
- 국내 구직자 수: 연 200만명
- 평균 자소서 작성 횟수: 15개
- 시장 규모: 연 3,000억원 추정

## 제품 전략

### 핵심 가치 제안 (Value Proposition)

> "기업이 찾는 인재가 되는 가장 빠른 방법"

### 차별화 전략

#### 1. 맥락 인식 (Context Awareness)
**"왜 지금, 이 인재가 필요한가?"**

- **What**: 채용공고 + 기업 상황 + 시장 동향 종합 분석
- **How**: 
  - 실시간 뉴스 크롤링
  - 경쟁사 채용 동향 분석
  - 산업 트렌드 매핑
- **Why**: 단순 자격요건 충족을 넘어 기업의 진짜 니즈 파악

#### 2. AI 탐지 회피 (Anti-Detection)
**"인간이 쓴 것처럼 자연스럽게"**

- **What**: GPT Killer 등 AI 탐지기 우회
- **How**:
  - 문장 패턴 다양화
  - 자연스러운 불완전성
  - 개인적 어투 강화
- **Why**: 서류 탈락 리스크 제거

#### 3. 지식 그래프 개인화 (Knowledge Graph)
**"당신의 모든 경험이 연결되는 스토리"**

- **What**: 경험을 구조화하여 최적 매칭
- **How**:
  - 스킬-성과-학습 연결
  - 경험 간 시너지 발견
  - 성장 스토리 구축
- **Why**: 일관되고 설득력 있는 자소서

## 기능 명세

### Core Features

#### 1. 채용공고 심층 분석
```
입력: 채용공고 URL
처리: 
  - 기본 정보 추출 (회사, 직무, 자격요건)
  - 기업 맥락 수집 (뉴스, 투자, 사업 동향)
  - 채용 의도 분석 (타이밍, 목적, 기대)
  - 경쟁사 벤치마킹
출력:
  - 핵심 키워드 Top 5
  - 숨겨진 요구사항
  - 전략적 어필 포인트
  - 리스크 요소
```

#### 2. AI 자소서 생성
```
입력: 
  - 채용공고 분석 결과
  - 개인 경험 데이터
  - 작성 스타일 선택
처리:
  - 경험-요구사항 매칭
  - 스토리 구조 설계
  - AI 작성 (GPT-4)
  - 탐지 회피 처리
  - 개인화 강화
출력:
  - 800-1000자 자소서
  - AI 탐지 리스크 점수
  - 개선 제안사항
```

#### 3. 대화형 작성 도우미
```
프로세스:
  1. 기본 정보 수집
  2. 핵심 경험 파악
  3. 성과 구체화
  4. 도전과 극복
  5. 성장과 학습
  6. 지원 동기
  7. 미래 비전
특징:
  - 단계별 가이드
  - 실시간 프리뷰
  - 답변 품질 피드백
```

#### 4. 3단계 심층 분석
```
Level 1: 구조 분석
  - 논리 흐름
  - 단락 구성
  - 가독성
  
Level 2: 내용 분석
  - 키워드 포함도
  - 구체성 평가
  - 직무 적합도
  
Level 3: 차별화 분석
  - 독창성 점수
  - 기억 포인트
  - 개선 우선순위
```

### Advanced Features

#### 1. 온톨로지 기반 역량 매핑
- ESCO (European Skills/Competences) 표준 활용
- 2,942개 직업 × 13,485개 스킬 매핑
- 역량 간 관계 그래프

#### 2. 실시간 기업 인텔리전스
- 네이버/구글 뉴스 API 연동
- 잡플래닛 기업 리뷰 분석
- 공시 정보 모니터링

#### 3. 경쟁력 스코어링
- 지원 난이도 (★1-5)
- 예상 경쟁률
- 합격 가능성 %
- 추천 지원 시기

## 사용자 경험 (UX)

### User Journey

```
1. Landing (3초)
   → "AI로 완성하는 자소서, 경험으로 차별화되는 합격"
   → 실시간 AI 작성 시뮬레이션 보기

2. 채용공고 입력 (10초)
   → URL 붙여넣기 or 텍스트 입력
   → "분석 시작" 클릭

3. 분석 결과 확인 (30초)
   → 핵심 인사이트 카드 뷰
   → 시각적 키워드 클라우드
   → "이 분석으로 자소서 작성" CTA

4. 개인 정보 입력 (3분)
   → 대화형 or 폼 입력 선택
   → 주요 경험 3-5개
   → 핵심 역량 태깅

5. AI 생성 및 편집 (2분)
   → 실시간 생성 애니메이션
   → 바로 편집 가능한 에디터
   → AI 탐지 리스크 표시

6. 최종 검토 (1분)
   → 체크리스트 확인
   → 다운로드/복사
   → 면접 예상 질문 제공
```

### Design System

#### Visual Identity
- **Primary Color**: #5865F2 (Trust Blue)
- **Secondary**: #8B5CF6 (Creative Purple)
- **Typography**: Pretendard (한글), Inter (영문)
- **Tone**: Professional yet Approachable

#### UI Components
- **Card Based Layout**: 정보 구조화
- **Progress Indicators**: 단계별 진행 상황
- **Interactive Animations**: 참여도 증대
- **Real-time Feedback**: 즉각적 반응

## 기술 아키텍처

### Tech Stack
```
Frontend:
  - Framework: Rails + Hotwire
  - Styling: Tailwind CSS 4
  - JS: Stimulus + Turbo
  
Backend:
  - Language: Ruby 3.3
  - Framework: Rails 8.0
  - Database: PostgreSQL
  
AI/ML:
  - LLM: OpenAI GPT-4.1
  - Embeddings: text-embedding-3
  - Vector DB: Pinecone
  
Infrastructure:
  - Hosting: AWS/Heroku
  - CDN: CloudFlare
  - Monitoring: Sentry
```

### System Architecture
```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Client    │────▶│   Rails App  │────▶│  OpenAI API │
└─────────────┘     └──────────────┘     └─────────────┘
                            │
                    ┌───────▼────────┐
                    │   PostgreSQL   │
                    └────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼──────┐   ┌────────▼────────┐ ┌───────▼──────┐
│ News APIs    │   │ Job Portal APIs │ │ Vector DB    │
└──────────────┘   └─────────────────┘ └──────────────┘
```

## 비즈니스 모델

### Revenue Streams

#### 1. Freemium
- **Free**: 월 3회 기본 분석
- **Pro** (₩9,900/월): 무제한 + 고급 분석
- **Team** (₩29,900/월): 팀 협업 + API

#### 2. B2B/B2G
- 대학 진로센터 구독
- 기업 HR 부서 라이선스
- 정부 일자리 센터 제휴

### Growth Strategy

#### Phase 1: PMF (0-6개월)
- Target: 대학생/신입
- Channel: 대학 커뮤니티
- Goal: MAU 10,000

#### Phase 2: Scale (6-12개월)
- Target: 경력직 확대
- Channel: 잡코리아/사람인 제휴
- Goal: MAU 100,000

#### Phase 3: Expand (12개월+)
- Target: 글로벌 진출
- Channel: LinkedIn 연동
- Goal: MAU 1,000,000

## Success Metrics

### North Star Metric
**합격 자소서 수** (Monthly Accepted Applications)

### Key Metrics
- Activation: 첫 자소서 생성률 (>60%)
- Retention: 30일 재방문율 (>40%)
- Revenue: Paid Conversion (>5%)
- Referral: 추천율 (NPS >50)

### Quality Metrics
- AI 탐지 회피율 (>80%)
- 자소서 합격률 (>30%)
- 생성 시간 (<3분)
- 만족도 (>4.5/5)

## Risk Management

### Technical Risks
- OpenAI API 의존도 → 멀티 LLM 지원
- 채용 사이트 크롤링 차단 → 공식 API 제휴
- AI 탐지 기술 발전 → 지속적 알고리즘 개선

### Business Risks
- 경쟁사 진입 → 데이터 moat 구축
- 규제 리스크 → 개인정보보호 준수
- 시장 포화 → 버티컬 확장 (이력서, 포트폴리오)

## Roadmap

### 2025 Q1
- [x] MVP 출시
- [x] 맥락 분석 엔진 구현
- [x] AI 탐지 회피 시스템
- [ ] 온톨로지 통합

### 2025 Q2
- [ ] 기업 인텔리전스 API
- [ ] 모바일 앱 출시
- [ ] B2B 세일즈 시작
- [ ] 면접 준비 기능

### 2025 Q3
- [ ] 영문 자소서 지원
- [ ] 포트폴리오 빌더
- [ ] AI 면접 시뮬레이터
- [ ] Series A 펀딩

### 2025 Q4
- [ ] 일본 진출
- [ ] 커리어 코칭 AI
- [ ] 기업 채용 솔루션
- [ ] MAU 100만 달성

## Team & Resources

### Core Team
- Product: 1명 (CEO)
- Engineering: 2명 (CTO + Dev)
- AI/ML: 1명
- Design: 1명
- Marketing: 1명

### Budget (연간)
- 인건비: 3.6억
- 인프라: 0.6억
- 마케팅: 1.2억
- 운영비: 0.6억
- **Total: 6억**

### Funding
- Seed: 10억 목표
- 사용처: 제품 개발(40%), 마케팅(30%), 팀 빌딩(30%)

---

*Version: 1.0*  
*Date: 2025-01-13*  
*Status: In Development*