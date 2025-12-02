# ContentSummarizer

A Ruby gem that intelligently scrapes and summarizes web content using AI, with built-in caching and rate limiting.

## Features (Current & Planned)

- ✅ AI-powered text summarization using Claude API
- ✅ Robust error handling with custom exceptions
- ✅ Comprehensive test coverage with RSpec
- 🚧 Web scraping with content extraction
- 🚧 Redis caching for performance optimization
- 🚧 Rate limiting to respect API quotas
- 🚧 Fallback to multiple AI providers

## Installation
## Usage
### Basic Summarization
```ruby
require 'content_summarizer'

# Initialize with your API key
client = ContentSummarizer::ClaudeClient.new(api_key: ENV['CLAUDE_API_KEY'])
summarizer = ContentSummarizer::Summarizer.new(api_client: client)

# Summarize any text
summary = summarizer.summarize("Your long text here...")
puts summary
```

### Configuration

Set your API key as an environment variable:
```bash
export CLAUDE_API_KEY='your-api-key-here'
```

Get your Claude API key from [Anthropic's Console](https://console.anthropic.com/)

## Development

### Setup
```bash
git clone https://github.com/YOUR_USERNAME/content_summarizer.git
cd content_summarizer
bundle install
```

### Running Tests
```bash
bundle exec rspec
```

### Architecture

This gem follows SOLID principles with clear separation of concerns:

- **Summarizer**: Coordinates summarization with dependency injection
- **ClaudeClient**: Handles Claude API communication
- **WebScraper** (Coming): Extracts content from URLs
- **Cache** (Coming): Redis-based caching layer
- **Service** (Coming): Orchestrates the full pipeline

## Error Handling

The gem provides specific exceptions for different failure scenarios:

- `AuthenticationError`: Invalid API key
- `RateLimitError`: API rate limit exceeded
- `ServerError`: Claude API server issues
- `APIError`: Other API-related errors

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

MIT License - see LICENSE file for details