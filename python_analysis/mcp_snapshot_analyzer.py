#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MCP Playwright를 활용한 채용공고 스냅샷 분석
사람인 등 복사 방지 사이트를 스크린샷으로 분석
"""

import asyncio
import json
import base64
import sys
from playwright.async_api import async_playwright
from pathlib import Path
import tempfile
import os

async def capture_job_posting_snapshot(url):
    """
    Playwright를 사용하여 채용공고 페이지 스냅샷 캡처
    """
    async with async_playwright() as p:
        # 브라우저 실행 (headless 모드)
        browser = await p.chromium.launch(
            headless=True,
            args=['--no-sandbox', '--disable-setuid-sandbox']
        )
        
        context = await browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            user_agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        )
        
        page = await context.new_page()
        
        try:
            print(f"📸 페이지 로딩 중: {url}", file=sys.stderr)
            
            # 페이지 로드
            await page.goto(url, wait_until='networkidle', timeout=30000)
            
            # 팝업/모달 닫기 시도
            popup_selectors = [
                '[class*="close"]',
                '[class*="modal_close"]',
                '[class*="btn_close"]',
                '.layer_close'
            ]
            
            for selector in popup_selectors:
                try:
                    await page.click(selector, timeout=1000)
                    print(f"✅ 팝업 닫기: {selector}", file=sys.stderr)
                except:
                    pass
            
            # 채용공고 컨텐츠 영역 대기
            content_selectors = [
                '.wrap_jv_cont',  # 사람인
                '.content',
                '.job_content',
                '[class*="recruit"]',
                '[class*="posting"]'
            ]
            
            content_found = False
            for selector in content_selectors:
                try:
                    await page.wait_for_selector(selector, timeout=5000)
                    content_found = True
                    print(f"✅ 컨텐츠 발견: {selector}", file=sys.stderr)
                    break
                except:
                    continue
            
            if not content_found:
                print("⚠️ 채용공고 컨텐츠를 찾을 수 없습니다", file=sys.stderr)
            
            # 페이지 스크롤하여 모든 컨텐츠 로드
            await page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
            await page.wait_for_timeout(2000)
            await page.evaluate("window.scrollTo(0, 0)")
            
            # 스크린샷 캡처 (전체 페이지)
            screenshot_bytes = await page.screenshot(
                full_page=True,
                type='png'
            )
            
            # Base64 인코딩
            screenshot_base64 = base64.b64encode(screenshot_bytes).decode('utf-8')
            
            # 텍스트 추출 시도 (가능한 경우)
            text_content = ""
            try:
                # 본문 텍스트 추출
                text_elements = await page.query_selector_all('p, li, h1, h2, h3, h4, span, div')
                texts = []
                for element in text_elements[:500]:  # 너무 많은 요소 방지
                    try:
                        text = await element.inner_text()
                        if text and len(text.strip()) > 5:
                            texts.append(text.strip())
                    except:
                        continue
                
                text_content = "\n".join(texts)
                print(f"✅ 텍스트 추출: {len(text_content)} 글자", file=sys.stderr)
            except Exception as e:
                print(f"⚠️ 텍스트 추출 실패: {e}", file=sys.stderr)
            
            # 메타데이터 추출
            metadata = {}
            try:
                metadata['title'] = await page.title()
                metadata['url'] = page.url
                
                # Open Graph 태그 추출
                og_tags = await page.evaluate("""
                    () => {
                        const tags = {};
                        const metas = document.querySelectorAll('meta[property^="og:"]');
                        metas.forEach(meta => {
                            const property = meta.getAttribute('property').replace('og:', '');
                            tags[property] = meta.getAttribute('content');
                        });
                        return tags;
                    }
                """)
                metadata['og'] = og_tags
            except:
                pass
            
            result = {
                'success': True,
                'screenshot': screenshot_base64,
                'text': text_content,
                'metadata': metadata,
                'url': url,
                'screenshot_size': len(screenshot_bytes)
            }
            
            print(f"✅ 스냅샷 캡처 완료: {len(screenshot_bytes)} bytes", file=sys.stderr)
            return result
            
        except Exception as e:
            print(f"❌ 스냅샷 캡처 실패: {str(e)}", file=sys.stderr)
            return {
                'success': False,
                'error': str(e),
                'url': url
            }
        
        finally:
            await browser.close()

def main():
    """메인 실행 함수"""
    if len(sys.argv) < 2:
        print(json.dumps({
            'success': False,
            'error': 'URL이 필요합니다'
        }))
        sys.exit(1)
    
    url = sys.argv[1]
    
    # 비동기 함수 실행
    loop = asyncio.get_event_loop()
    result = loop.run_until_complete(capture_job_posting_snapshot(url))
    
    # JSON으로 출력
    print(json.dumps(result, ensure_ascii=False))

if __name__ == "__main__":
    main()