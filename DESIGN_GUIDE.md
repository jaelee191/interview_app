# JACHUI 디자인 가이드라인

## 브랜드 아이덴티티
- **서비스명**: JACHUI (자취를 남기다)
- **슬로건**: "자기소개로 취업하다"
- **미션**: AI 기술로 구직자의 경험을 완벽한 자기소개서로 변환

## 색상 팔레트

### 주요 색상
```css
--primary-blue: #5865F2;      /* 메인 브랜드 색상 */
--primary-hover: #4752C4;     /* 호버 상태 */
--accent-purple: #8B5CF6;     /* 강조 색상 */
--accent-indigo: #6366F1;     /* 보조 강조 */
```

### 텍스트 색상
```css
--text-primary: #111827;      /* gray-900: 제목, 중요 텍스트 */
--text-secondary: #374151;    /* gray-700: 본문 */
--text-tertiary: #6B7280;     /* gray-500: 보조 텍스트 */
--text-muted: #9CA3AF;        /* gray-400: 비활성 텍스트 */
```

### 배경 색상
```css
--bg-primary: #FFFFFF;        /* 메인 배경 */
--bg-secondary: #F9FAFB;      /* gray-50: 섹션 배경 */
--bg-tertiary: #F3F4F6;       /* gray-100: 카드 배경 */
--bg-gradient: linear-gradient(to bottom right, #EEF2FF, #FAF5FF); /* indigo-50 to purple-100 */
```

### 상태 색상
```css
--success: #10B981;           /* green-500 */
--warning: #F59E0B;           /* amber-500 */
--error: #EF4444;             /* red-500 */
--info: #3B82F6;              /* blue-500 */
```

## 타이포그래피

### 폰트 패밀리
```css
font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, system-ui, Roboto, 'Helvetica Neue', 'Segoe UI', sans-serif;
```

### 텍스트 크기 및 굵기
- **h1**: `text-4xl font-bold` (2.25rem, 700)
- **h2**: `text-3xl font-bold` (1.875rem, 700)
- **h3**: `text-2xl font-semibold` (1.5rem, 600)
- **h4**: `text-xl font-semibold` (1.25rem, 600)
- **body**: `text-base` (1rem, 400)
- **small**: `text-sm` (0.875rem, 400)

## 컴포넌트 스타일

### 버튼
```html
<!-- Primary Button -->
<button class="px-6 py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-medium rounded-lg transition-colors shadow-md hover:shadow-lg">
  버튼 텍스트
</button>

<!-- Secondary Button -->
<button class="px-6 py-3 bg-white hover:bg-gray-50 text-gray-700 font-medium rounded-lg border border-gray-300 transition-colors">
  버튼 텍스트
</button>

<!-- Danger Button -->
<button class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-medium rounded-lg transition-colors">
  삭제
</button>
```

### 카드
```html
<div class="bg-white rounded-xl shadow-md hover:shadow-lg transition-shadow p-6">
  <!-- 카드 내용 -->
</div>
```

### 입력 필드
```html
<input type="text" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent">
```

### 드롭다운
```html
<div class="relative group">
  <button class="text-gray-600 hover:text-gray-900 transition-colors font-medium flex items-center px-3 py-2">
    메뉴명
    <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
    </svg>
  </button>
  <div class="absolute top-full left-0 mt-2 w-56 bg-white rounded-lg shadow-lg border border-gray-200 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50">
    <!-- 드롭다운 아이템 -->
  </div>
</div>
```

## 레이아웃 원칙

### 간격 (Spacing)
- **섹션 간격**: `py-12` (3rem)
- **컨테이너 패딩**: `px-4 sm:px-6 lg:px-8`
- **요소 간격**: `space-y-4` 또는 `gap-4`
- **카드 내부 패딩**: `p-6`

### 최대 너비
- **메인 컨테이너**: `max-w-7xl mx-auto`
- **컨텐츠 영역**: `max-w-4xl mx-auto`
- **폼 영역**: `max-w-2xl mx-auto`

### 그리드 시스템
```html
<!-- 2 컬럼 -->
<div class="grid md:grid-cols-2 gap-6">

<!-- 3 컬럼 -->
<div class="grid md:grid-cols-3 gap-6">

<!-- 4 컬럼 -->
<div class="grid lg:grid-cols-4 gap-6">
```

## 인터랙션 가이드라인

### 호버 효과
- 버튼: 색상 변경 + 그림자 증가
- 카드: 그림자 증가
- 링크: 색상 변경
- 모든 전환: `transition-colors` 또는 `transition-all duration-200`

### 포커스 상태
- 입력 필드: `focus:ring-2 focus:ring-indigo-500 focus:border-transparent`
- 버튼: `focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500`

### 로딩 상태
```html
<button disabled class="px-6 py-3 bg-gray-400 text-white font-medium rounded-lg cursor-not-allowed">
  <span class="animate-pulse">처리 중...</span>
</button>
```

## 아이콘 사용 규칙
- 기업 분석: 🏢
- 채용공고: 💼
- 저장된 항목: 📚, 📋
- AI 기능: 🤖, 🧠
- 맥락 분석: 🎯
- 심층 분석: 📊
- 작성: ✍️
- 삭제: 🗑️ (또는 빨간색 버튼)
- 성공: ✅
- 경고: ⚠️
- 정보: 💡

## 페이지 구조 템플릿

```erb
<div class="min-h-screen bg-gradient-to-br from-indigo-50 to-purple-100 py-12">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="text-center mb-12">
      <h1 class="text-4xl font-bold text-gray-900 mb-4">
        🏢 페이지 제목
      </h1>
      <p class="text-lg text-gray-600 max-w-2xl mx-auto">
        페이지 설명
      </p>
    </div>
    
    <!-- Main Content -->
    <div class="bg-white rounded-xl shadow-lg p-8">
      <!-- 컨텐츠 -->
    </div>
  </div>
</div>
```

## 반응형 디자인 원칙
- 모바일 우선 접근 (Mobile First)
- 브레이크포인트:
  - sm: 640px
  - md: 768px
  - lg: 1024px
  - xl: 1280px

## 접근성 고려사항
- 충분한 색상 대비 유지
- 포커스 인디케이터 제공
- 의미있는 alt 텍스트
- 키보드 네비게이션 지원
- ARIA 레이블 활용

## 적용 우선순위
1. **일관성**: 모든 페이지에서 동일한 스타일 적용
2. **가독성**: 명확한 텍스트 계층 구조
3. **사용성**: 직관적인 인터랙션
4. **접근성**: 모든 사용자가 이용 가능
5. **성능**: 빠른 로딩과 부드러운 애니메이션