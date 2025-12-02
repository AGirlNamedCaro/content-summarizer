# frozen_string_literal: true

require_relative "content_summarizer/version"
require_relative "content_summarizer/summarizer"
require_relative "content_summarizer/claude_client"

module ContentSummarizer
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class RateLimitError < Error; end
  class ServerError < Error; end
  class APIError < Error; end
end
