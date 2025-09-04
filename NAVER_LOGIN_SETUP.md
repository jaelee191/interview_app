# 네이버 소셜 로그인 구현 가이드

## 1. 네이버 개발자 센터 앱 등록

### 1.1 네이버 개발자 센터 접속
- https://developers.naver.com 접속
- 로그인 후 "애플리케이션 등록" 클릭

### 1.2 애플리케이션 정보 입력
- **애플리케이션 이름**: jachui
- **사용 API**: 네이버 로그인
- **제공 정보 선택**:
  - 필수: 이메일 주소
  - 선택: 이름, 프로필 사진

### 1.3 서비스 환경 설정
- **서비스 URL**: 
  - 개발: http://localhost:3004
  - 운영: https://your-domain.com
  
- **Callback URL** (중요!):
  - 개발: http://localhost:3004/users/auth/naver/callback
  - 운영: https://your-domain.com/users/auth/naver/callback

### 1.4 Client ID/Secret 확인
등록 완료 후 발급받은 정보를 저장:
- Client ID: (발급받은 ID)
- Client Secret: (발급받은 Secret)

## 2. Rails 앱 설정

### 2.1 Gemfile에 필요한 젬 추가

```ruby
# Gemfile
gem 'omniauth'
gem 'omniauth-naver'
gem 'omniauth-rails_csrf_protection'
```

설치:
```bash
bundle install
```

### 2.2 환경변수 설정

`.env` 파일 또는 Rails credentials에 추가:
```bash
# .env
NAVER_CLIENT_ID=your_client_id
NAVER_CLIENT_SECRET=your_client_secret
```

### 2.3 Devise 설정 업데이트

```ruby
# config/initializers/devise.rb
config.omniauth :naver, 
  ENV['NAVER_CLIENT_ID'], 
  ENV['NAVER_CLIENT_SECRET'],
  {
    scope: 'email,name',
    callback_url: "http://localhost:3004/users/auth/naver/callback"
  }
```

### 2.4 User 모델 업데이트

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:naver]
         
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      # user.image = auth.info.image # 프로필 이미지 저장 시
    end
  end
end
```

### 2.5 Migration 추가

```bash
rails generate migration AddOmniauthToUsers provider:string uid:string
rails db:migrate
```

### 2.6 Omniauth Callbacks Controller 생성

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def naver
    @user = User.from_omniauth(request.env["omniauth.auth"])
    
    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "네이버") if is_navigational_format?
    else
      session["devise.naver_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url
    end
  end
  
  def failure
    redirect_to root_path, alert: "로그인에 실패했습니다."
  end
end
```

### 2.7 Routes 설정

```ruby
# config/routes.rb
devise_for :users, controllers: { 
  omniauth_callbacks: 'users/omniauth_callbacks' 
}
```

## 3. 프론트엔드 버튼 구현

현재 회원가입 페이지에 이미 네이버 버튼이 있으므로, 클릭 이벤트만 연결:

```erb
<!-- app/views/devise/registrations/new.html.erb -->
<%= link_to user_naver_omniauth_authorize_path, method: :post, 
    data: { turbo: false },
    class: "w-full inline-flex justify-center py-2.5 px-4 border border-gray-300 rounded-lg shadow-sm bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 transition" do %>
  <!-- 네이버 아이콘 SVG -->
  <span class="ml-2">Naver</span>
<% end %>
```

## 4. 보안 고려사항

1. **CSRF 보호**: `omniauth-rails_csrf_protection` 젬 필수
2. **환경변수**: Client ID/Secret은 절대 코드에 직접 입력하지 않기
3. **HTTPS**: 운영 환경에서는 반드시 HTTPS 사용
4. **Callback URL**: 정확한 URL 설정 필수

## 5. 테스트

1. Rails 서버 재시작
2. 회원가입/로그인 페이지에서 네이버 버튼 클릭
3. 네이버 로그인 페이지로 리다이렉트 확인
4. 로그인 후 콜백으로 돌아오는지 확인
5. 새 사용자가 생성되거나 기존 사용자로 로그인되는지 확인

## 6. 트러블슈팅

### 문제 1: "Invalid redirect_uri" 에러
- 네이버 개발자 센터의 Callback URL과 Rails 설정이 정확히 일치하는지 확인

### 문제 2: "Missing required parameter: client_id" 에러
- 환경변수가 제대로 설정되었는지 확인
- Rails 서버 재시작

### 문제 3: 로그인 후 리다이렉트 안됨
- Routes 설정 확인
- OmniauthCallbacksController 경로 확인

## 참고 자료
- [네이버 로그인 개발가이드](https://developers.naver.com/docs/login/devguide/)
- [Omniauth-Naver Gem](https://github.com/kimsuelim/omniauth-naver)
- [Devise Omniauth 가이드](https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview)