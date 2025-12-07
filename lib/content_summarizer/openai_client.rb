require "httparty"

module ContentSummarizer
  class OpenAIClient
    API_URL = "https://api.openai.com/v1/chat/completions"
    DEFAULT_MODEL = "gpt-4o-mini"
    DEFAULT_MAX_TOKENS = 1024

    def initialize(api_key:)
      @api_key = api_key
    end

    def summarize(text)
      response = HTTParty.post(
        API_URL,
        headers: {
          "Authorization" => "Bearer #{@api_key}",
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
        response.parsed_response["choices"][0]["message"]["content"]
      when 401
        raise AuthenticationError, "Invalid API key"
      when 429
        raise RateLimitError, "Too many requests"
      when 500..599
        raise ServerError, "Open AI API server error (#{response.code})"
      else
        raise APIError, "Unexpected response: #{response.code}"
      end
    end
  end
end
