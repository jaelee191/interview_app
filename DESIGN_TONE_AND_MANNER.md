# 서비스 디자인 톤앤매너 가이드라인

## 핵심 디자인 원칙

### 1. 색상 팔레트
- **Primary**: 민트 그린 (#86EFAC, #10B981 계열)
- **Secondary**: 부드러운 그레이 계열
- **Accent**: 포인트 컬러
- **Background**: 밝은 배경 (#F9FAFB, #FFFFFF)
- **Text**: 다크 그레이/블랙 (#111827, #374151)

### 2. 타이포그래피
- **제목**: Bold, Sans-serif 폰트
- **본문**: 읽기 쉬운 Sans-serif
- **강조**: 민트 그린 하이라이트 또는 기울임

### 3. UI 컴포넌트 스타일

#### 버튼
- **Primary Button**: 민트 그린 배경, 둥근 모서리, 호버 시 더 진한 색상
- **Secondary Button**: 투명 배경, 테두리만 있는 스타일
- 부드러운 그림자 효과 사용

#### 카드/컨테이너
- 둥근 모서리 (border-radius: 8-12px)
- 부드러운 그림자
- 충분한 패딩과 여백

#### 아이콘
- 체크 마크 (✓) 같은 간단한 아이콘 사용
- 민트 그린 액센트 컬러 적용

### 4. 레이아웃
- 깔끔하고 미니멀한 디자인
- 충분한 여백 (whitespace) 활용
- 중앙 정렬된 콘텐츠
- 반응형 디자인 필수

### 5. 인터랙션
- 부드러운 트랜지션 효과
- 호버 상태 명확히 표시
- 실시간 미리보기 제공

### 6. 톤앤보이스
- 친근하고 전문적인 어조
- 간결하고 명확한 문구
- 사용자 중심의 설명

## CSS 클래스 예시

```css
/* Primary Button */
.btn-primary {
  @apply bg-emerald-400 hover:bg-emerald-500 text-white font-medium py-3 px-6 rounded-lg transition-colors;
}

/* Card Container */
.card {
  @apply bg-white rounded-xl shadow-sm p-6 border border-gray-100;
}

/* Text Styles */
.heading-main {
  @apply text-4xl font-bold text-gray-900;
}

.text-accent {
  @apply text-emerald-400;
}
```

## 적용 시 체크리스트
- [ ] 민트 그린 컬러 팔레트 사용
- [ ] 충분한 여백과 패딩
- [ ] 둥근 모서리 디자인
- [ ] 부드러운 그림자 효과
- [ ] 명확한 호버 상태
- [ ] 반응형 레이아웃
- [ ] 읽기 쉬운 타이포그래피