class CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :crawl]
  
  def index
    @companies = Company.all.order(:name)
  end

  def search
    @query = params[:q]
    
    if @query.present?
      # 기존 회사 검색
      @companies = Company.search(@query)
      
      # 검색 결과가 없으면 새 회사 생성 옵션 제공
      if @companies.empty?
        @new_company = Company.new(name: @query)
      end
    else
      @companies = Company.none
    end
  end

  def show
    @recent_news = @company.company_news.recent.limit(20)
    @positive_count = @company.company_news.positive.count
    @negative_count = @company.company_news.negative.count
    @neutral_count = @company.company_news.neutral.count
  end
  
  def new
    @company = Company.new
  end
  
  def create
    @company = Company.new(company_params)
    
    if @company.save
      # 생성 후 바로 크롤링 시작
      CompanyNewsCrawlerJob.perform_later(@company)
      redirect_to @company, notice: '기업이 등록되었고 뉴스 크롤링을 시작합니다.'
    else
      render :new
    end
  end

  def crawl
    # 크롤링 작업을 백그라운드로 실행
    CompanyNewsCrawlerJob.perform_later(@company)
    
    respond_to do |format|
      format.html { redirect_to @company, notice: '뉴스 크롤링이 시작되었습니다. 잠시 후 새로고침해주세요.' }
      format.json { render json: { status: 'started', message: '크롤링이 시작되었습니다.' } }
    end
  end
  
  private
  
  def set_company
    @company = Company.find(params[:id])
  end
  
  def company_params
    params.require(:company).permit(:name, :ticker, :description, :industry, :website)
  end
end