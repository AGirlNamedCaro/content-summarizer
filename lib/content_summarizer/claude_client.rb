require "httparty"
require "json"

module ContentSummarizer
  class ClaudeClient
    API_URL = "https://api.anthropic.com/v1/messages"
    API_VERSION = "2023-06-01"
    DEFAULT_MODEL = "claude-sonnet-4-20250514"
    DEFAULT_MAX_TOKENS = 1024

    def initialize(api_key:)
      @api_key = api_key
    end

    def summarize(text)
      response = HTTParty.post(
        API_URL,
        headers: {
          "x-api-key" => @api_key,
          "anthropic-version" => API_VERSION,
          "content-type" => "application/json",
        },
        body: {
          model: DEFAULT_MODEL,
          max_tokens: DEFAULT_MAX_TOKENS,
          messages: [
            { role: "user", content: "Summarize this: #{text}" },
          ],
        }.to_json,
      )
      case response.code
      when 200
        response.parsed_response["content"][0]["text"]
      when 401
        raise AuthenticationError, "Invalid API key"
      when 429
        raise RateLimitError, "Too many requests"
      when 500..599
        raise ServerError, "Claude API server error (#{response.code})"
      else
        raise APIError, "Unexpected response: #{response.code}"
      end
    end
  end
end
