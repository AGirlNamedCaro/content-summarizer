module ContentSummarizer
  class ContentSummarizationService
    def initialize(api_key:, summarizer: nil, scraper: WebScraper, cache: nil)
      @scraper = scraper
      @summarizer = summarizer || build_default_summarizer(api_key)
      @cache = cache
    end

    def summarize_url(url)
      if @cache && @cache.exists?(url)
        return @cache.get(url)
      end

      scraped_content = @scraper.scrape(url)
      summary = @summarizer.summarize(scraped_content.content)

      @cache.set(url, summary, ttl: 86400) if @cache

      summary
    end

    private

    def build_default_summarizer(api_key)
      client = ClaudeClient.new(api_key: api_key)
      Summarizer.new(api_client: client)
    end
  end
end
