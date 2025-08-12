# 🎨 AI 자소서 도우미 - 디자인 시스템 & 톤앤매너 가이드

## 1. 브랜드 아이덴티티

### 브랜드 포지셔닝
- **핵심 가치**: 신뢰성, 전문성, 혁신성, 친근함
- **타겟 사용자**: 취업 준비생, 이직 준비자, 대학생 및 신입/경력직 구직자
- **차별화 포인트**: AI 기술 기반의 정확하고 개인화된 자소서 분석

### 브랜드 톤
- **Professional**: 전문적이지만 딱딱하지 않은
- **Approachable**: 친근하고 접근하기 쉬운
- **Innovative**: 최신 AI 기술을 활용한 혁신적인
- **Supportive**: 사용자의 성공을 돕는 든든한 파트너

## 2. 컬러 시스템

### Primary Colors
```css
--primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
--primary-500: #667eea;  /* Indigo */
--primary-600: #5a67d8;
--primary-700: #4c51bf;
```

### Secondary Colors
```css
--secondary-pink: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
--secondary-blue: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
--secondary-green: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
--secondary-yellow: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
```

### Neutral Colors
```css
--gray-50: #f9fafb;
--gray-100: #f3f4f6;
--gray-200: #e5e7eb;
--gray-300: #d1d5db;
--gray-400: #9ca3af;
--gray-500: #6b7280;
--gray-600: #4b5563;
--gray-700: #374151;
--gray-800: #1f2937;
--gray-900: #111827;
```

### Semantic Colors
```css
--success: #10b981;  /* Green */
--warning: #f59e0b;  /* Amber */
--error: #ef4444;    /* Red */
--info: #3b82f6;     /* Blue */
```

## 3. 타이포그래피

### Font Family
```css
font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', 
             'Roboto', 'Helvetica Neue', 'Arial', sans-serif;
```

### Font Scale
```css
--text-xs: 0.75rem;    /* 12px */
--text-sm: 0.875rem;   /* 14px */
--text-base: 1rem;     /* 16px */
--text-lg: 1.125rem;   /* 18px */
--text-xl: 1.25rem;    /* 20px */
--text-2xl: 1.5rem;    /* 24px */
--text-3xl: 1.875rem;  /* 30px */
--text-4xl: 2.25rem;   /* 36px */
```

### Font Weight
```css
--font-light: 300;
--font-normal: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;
```

## 4. 레이아웃 원칙

### Spacing System
```css
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-5: 1.25rem;   /* 20px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
```

### Border Radius
```css
--radius-sm: 0.25rem;   /* 4px */
--radius-md: 0.375rem;  /* 6px */
--radius-lg: 0.5rem;    /* 8px */
--radius-xl: 0.75rem;   /* 12px */
--radius-2xl: 1rem;     /* 16px */
--radius-full: 9999px;  /* Fully rounded */
```

### Shadow System
```css
--shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
--shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
--shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
--shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
--shadow-2xl: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
```

## 5. UI 컴포넌트 스타일

### Cards
- **배경**: 흰색 또는 매우 연한 그레이
- **테두리**: 1px solid #e5e7eb 또는 그림자만 사용
- **모서리**: 12-16px radius
- **그림자**: shadow-md for elevation
- **호버 효과**: 살짝 올라오는 효과 (translateY(-2px))

### Buttons
```css
/* Primary Button */
.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  transition: all 0.3s ease;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

/* Secondary Button */
.btn-secondary {
  background: white;
  color: #4b5563;
  border: 2px solid #e5e7eb;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  transition: all 0.3s ease;
}
```

### Forms
- **Input 스타일**: 깔끔한 테두리, 충분한 패딩
- **Focus 상태**: 보라색 테두리 + 그림자
- **Label**: 작고 명확한 폰트
- **Helper text**: 회색 작은 글씨

## 6. 인터랙션 & 애니메이션

### Transitions
```css
--transition-fast: 150ms ease;
--transition-base: 250ms ease;
--transition-slow: 350ms ease;
```

### Hover Effects
- **Cards**: 살짝 올라오기 + 그림자 강화
- **Buttons**: 배경색 진해지기 + scale(1.02)
- **Links**: 언더라인 또는 색상 변경

### Loading States
- **Skeleton screens**: 콘텐츠 로딩 시
- **Spinner**: 작업 진행 중
- **Progress bar**: 단계별 진행 상황

## 7. 페이지별 톤앤매너

### 홈페이지
- **Hero Section**: 그라데이션 배경, 큰 타이틀, CTA 버튼
- **Features**: 아이콘 + 카드 형태로 기능 소개
- **Trust Signals**: 사용자 수, 성공 사례 등

### 채용공고 분석
- **모던 카드 레이아웃**: 섹션별 구분
- **컬러풀한 태그**: 키워드 강조
- **데이터 시각화**: 차트, 프로그레스 바

### 자소서 작성
- **클린한 에디터**: 집중할 수 있는 환경
- **실시간 피드백**: 우측 사이드바
- **단계별 가이드**: 상단 프로그레스 바

## 8. 콘텐츠 가이드라인

### 문구 톤
- **격려하는**: "잘하고 있어요!", "거의 다 왔어요!"
- **명확한**: "다음 단계", "분석 시작"
- **친근한**: 존댓말 사용, 이모지 적절히 활용

### 에러 메시지
- **친절한 설명**: 왜 에러가 발생했는지
- **해결 방법 제시**: 어떻게 해결할 수 있는지
- **긍정적 톤**: "다시 시도해보세요" vs "실패했습니다"

### 성공 메시지
- **축하 메시지**: "축하합니다! 🎉"
- **다음 단계 안내**: "이제 무엇을 할 수 있어요"

## 9. 반응형 디자인

### Breakpoints
```css
--mobile: 640px;    /* sm */
--tablet: 768px;    /* md */
--laptop: 1024px;   /* lg */
--desktop: 1280px;  /* xl */
```

### Mobile First
- 모바일 우선 디자인
- 터치 친화적 UI (최소 44px 터치 영역)
- 단순화된 네비게이션

## 10. 접근성

### WCAG 2.1 AA 준수
- **색상 대비**: 최소 4.5:1 (텍스트)
- **키보드 네비게이션**: 모든 기능 접근 가능
- **스크린 리더**: 적절한 ARIA 레이블
- **포커스 인디케이터**: 명확한 포커스 표시

## 11. 성능 최적화

### 로딩 전략
- **Lazy loading**: 이미지와 컴포넌트
- **Code splitting**: 페이지별 번들 분리
- **캐싱**: 정적 자산 캐싱

### 애니메이션
- **GPU 가속**: transform, opacity 사용
- **60fps 유지**: 부드러운 애니메이션
- **Reduce motion**: 접근성 옵션 지원

## 12. 일관성 유지

### 디자인 토큰
- 모든 스타일 값을 변수로 관리
- 컴포넌트 재사용
- 스타일 가이드 문서화

### 품질 관리
- 디자인 리뷰 프로세스
- A/B 테스트
- 사용자 피드백 수집

---

이 디자인 시스템은 **전문적이면서도 친근한** AI 자소서 도우미 서비스의 브랜드 아이덴티티를 구축하는 기반이 됩니다. 
사용자가 신뢰할 수 있고, 쉽게 사용할 수 있으며, 긍정적인 경험을 제공하는 것이 핵심 목표입니다.