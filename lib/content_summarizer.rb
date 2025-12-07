# frozen_string_literal: true

require_relative "content_summarizer/version"
require_relative "content_summarizer/summarizer"
require_relative "content_summarizer/claude_client"
require_relative "content_summarizer/scraped_content"
require_relative "content_summarizer/web_scraper"
require_relative "content_summarizer/content_summarization_service"
require_relative "content_summarizer/fallback_api_client"
require_relative "content_summarizer/openai_client"

module ContentSummarizer
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class RateLimitError < Error; end
  class ServerError < Error; end
  class APIError < Error; end
  class InvalidURLError < Error; end
  class EmptyContentError < Error; end
end
