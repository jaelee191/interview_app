// 브라우저 콘솔에서 실행할 수 있는 테스트 코드
// http://localhost:3004/cover_letters/job_posting 페이지에서 실행

// 테스트 1: 파이썬 분석 사용
async function testPythonAnalysis() {
  const url = "https://www.saramin.co.kr/zf_user/jobs/relay/pop-view?rec_idx=51628653";
  
  console.log("파이썬 분석 테스트 시작...");
  
  try {
    const response = await fetch('/cover_letters/analyze_job_posting', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        url: url,
        job_title: "개발자",
        use_enhanced: 'false',
        use_python: 'true'
      })
    });
    
    const data = await response.json();
    console.log("파이썬 분석 결과:", data);
    
    if (data.success) {
      console.log("✅ 파이썬 분석 성공!");
      console.log("회사명:", data.company_name);
      console.log("포지션:", data.position);
      console.log("분석 타입:", data.analysis_type);
    } else {
      console.error("❌ 파이썬 분석 실패:", data.error);
    }
  } catch (error) {
    console.error("네트워크 오류:", error);
  }
}

// 테스트 2: Enhanced 분석 사용
async function testEnhancedAnalysis() {
  const url = "https://www.saramin.co.kr/zf_user/jobs/relay/pop-view?rec_idx=51628653";
  
  console.log("Enhanced 분석 테스트 시작...");
  
  try {
    const response = await fetch('/cover_letters/analyze_job_posting', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        url: url,
        job_title: "개발자",
        use_enhanced: 'true',
        use_python: 'false'
      })
    });
    
    const data = await response.json();
    console.log("Enhanced 분석 결과:", data);
    
    if (data.success) {
      console.log("✅ Enhanced 분석 성공!");
      console.log("회사명:", data.company_name);
      console.log("포지션:", data.position);
      console.log("분석 타입:", data.is_enhanced ? "Enhanced" : "Basic");
    } else {
      console.error("❌ Enhanced 분석 실패:", data.error);
    }
  } catch (error) {
    console.error("네트워크 오류:", error);
  }
}

// 테스트 3: 폼에서 직접 테스트
function fillFormAndSubmit() {
  const urlInput = document.getElementById('job_url');
  const titleInput = document.getElementById('job_title');
  const form = document.getElementById('jobAnalysisForm');
  
  if (urlInput && titleInput) {
    urlInput.value = "https://www.saramin.co.kr/zf_user/jobs/relay/pop-view?rec_idx=51628653";
    titleInput.value = "개발자";
    console.log("폼 입력 완료. 제출 중...");
    
    // 폼 제출
    if (form) {
      form.dispatchEvent(new Event('submit'));
    }
  } else {
    console.error("폼 요소를 찾을 수 없습니다.");
  }
}

console.log("=== 채용공고 크롤링 테스트 도구 ===");
console.log("사용 가능한 함수:");
console.log("1. testPythonAnalysis() - 파이썬 분석 테스트");
console.log("2. testEnhancedAnalysis() - Enhanced 분석 테스트");
console.log("3. fillFormAndSubmit() - 폼에 자동 입력 후 제출");