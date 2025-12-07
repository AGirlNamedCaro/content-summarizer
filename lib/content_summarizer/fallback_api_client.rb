module ContentSummarizer
  class FallbackAPIClient
    def initialize(primary:, fallback:)
      @primary = primary
      @fallback = fallback
    end

    def summarize(text)
      begin
        @primary.summarize(text)
      rescue ContentSummarizer::ServerError, ContentSummarizer::AuthenticationError, ContentSummarizer::APIError
        @fallback.summarize(text)
      end
    end
  end
end
