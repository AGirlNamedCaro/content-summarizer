module ContentSummarizer
  class ContentSummarizationService
    def initialize(api_key:, summarizer: nil, scraper: WebScraper)
      @scraper = scraper
      @summarizer = summarizer || build_default_summarizer(api_key)
    end

    def summarize_url(url)
      scraped_content = @scraper.scrape(url)
      @summarizer.summarize(scraped_content.content)
    end

    private

    def build_default_summarizer(api_key)
      client = ClaudeClient.new(api_key: api_key)
      Summarizer.new(api_client: client)
    end
  end
end
