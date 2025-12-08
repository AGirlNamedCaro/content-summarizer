# ContentSummarizer 📰

> An intelligent web content summarization engine with AI-powered analysis, Redis caching, and multi-provider fallback strategies.

[![Ruby](https://img.shields.io/badge/ruby-3.4.5-red.svg)](https://www.ruby-lang.org/)
[![RSpec](https://img.shields.io/badge/tested%20with-rspec-green.svg)](https://rspec.info/)
[![Redis](https://img.shields.io/badge/cache-redis-red.svg)](https://redis.io/)

**Built to demonstrate:** Production-grade Ruby architecture, TDD practices, API integration patterns, and performance optimization strategies.

---

## 🎯 The Problem

Reading long articles takes time. Developers, researchers, and busy professionals need quick summaries to decide if content is worth deep-diving into. Existing solutions either:
- Require copy-pasting content manually
- Don't cache results (wasting API calls and money)
- Lack fallback strategies when APIs fail
- Can't handle complex HTML structures

**ContentSummarizer solves all of these.**

---

## ✨ Features

- 🤖 **Multi-AI Provider Support**: Claude (Anthropic) and OpenAI with automatic fallback
- ⚡ **Redis Caching**: 24-hour cache prevents duplicate API calls, saving costs
- 🕷️ **Smart Web Scraping**: Extracts article content while filtering navigation, ads, and footers
- 🔄 **Graceful Degradation**: Automatic fallback from Claude → OpenAI if primary fails
- 🧪 **100% Test Coverage**: Built with TDD using RSpec
- 🎭 **Demo Mode**: Test without API costs
- 📦 **Clean Architecture**: SOLID principles, dependency injection throughout

## 🏗️ Architecture
ContentSummarizer follows **SOLID principles** with clear separation of concerns. Each component has a single responsibility and can be tested in isolation
### Component Breakdwon
#### 1. ContentSummarizationService
**Responsibilities:**
- Check cache before expensive operations
- Coordinate scraping and summarization
- Store results with 24-hour TTL
- Handle errors gracefully

```ruby
service = ContentSummarizationService.new(api_key: key, cache: cache)
summary = service.summarize_url(url)
```

#### 2. WebScraper
**Features:**
- Progressive fallback: `<article>` -> `<main>` -> all `<p>` tags
- Extracts images with alt text for context
- Validates content exists before returning
- Handles malformed URLs and netword errors

I chose a class method instead of an instance because scraping is stateless and each scrape is <i>independent.</i>

#### 3. Summarizer
It's implemented using the **Strategy Pattern**: same interface, swappable implementations
```ruby
# Production
client = ClaudeClient.new(api_key: key)
summarizer = Summarizer.new(api_client: client)

# Testing
fake_client = double('APIClient', summarize: 'fake summary')
summarizer = Summarizer.new(api_client: fake_client)
```

#### 4. FallbackAPIClient
- I wanted to add an automatic failover between AI providers in case Claude API is down or rate limited etc

```ruby
client = FallbackAPIClient.new(
  primary: ClaudeClient.new(api_key: claude_key),
  fallback: OpenAIClient.new(api_key: openai_key)
)
```

**Errors that trigger fallback:**
- `AuthenticationError` (bad API key)
- `ServerError` (500-599 status codes)
- `RateLimitError` (429 - too many requests)

**Why not just rescue all errors?** Some errors shouldn't fallback:
- `InvalidURLError` - both providers would fail the same way
- `EmptyContentError` - no content to summarize

#### 5. Cache 
**Key design decisions:**

**Q: Should cache be per-user or global?**  
**A: Global.** Same URL = same content = same summary for everyone.

**Q: What's the cache key?**  
**A: The URL itself.** Simple, effective, human-readable in Redis.

**Q: TTL (Time To Live)?**  
**A: 24 hours.** Balances freshness vs. cost savings. Articles don't change that often.

**Impact:**
- Second request for same URL: **~2000x faster** (no scraping, no API call)
- Cost savings: **$0.003 per cached hit avoided**
```ruby
# First request: 2.5 seconds, costs $0.003
summary = service.summarize_url(url)

# Second request: 0.001 seconds, costs $0
summary = service.summarize_url(url)  # Cache hit! ⚡
```

## 🧪 Test-Driven Development

Every component was built **test-first**:
**Testing strategies used:**
- **Unit tests**: Each class in isolation with mocked dependencies
- **WebMock**: Stub HTTP requests without hitting real APIs
- **Dependency injection**: Makes everything mockable and testable

**Test coverage:** 100% (run `bundle exec rspec` to verify)

## Design Tradeoffs
### Why Ruby?
- **Gem ecosystem:** Nokogiri (HTML parsing), HTTParty, Redis
- **Expressive syntax:** Clean, readable code
- **Strong testing culture:** RSpec is industry standard

### Why Redis over in-memory cache?
- **Persistence:** Survives app restarts
- **Scalability:** can scale horizontally across multiple servers
- **Production-ready:** Used by GitHub, Stack Overflow, Twitter

### Why not use a background job queue?
- **Simplicity:** For a portfolio project, synchronous processing is clearer
- **Real-world:** Would add Sidekiq for production at scale

### Why dependency injection everywhere?
- **Testability:** Can inject mocks/stubs easily
- **Flexibility:** Swap implementations without changing calling code
- **SOLID:** Follows Dependency Inversion Principle

## 🚀 Installation

### Prerequisites

- **Ruby 3.0+** (tested on 3.4.5)
- **Redis** (for caching)
- **API Keys** (at least one):
  - Claude API key from [Anthropic Console](https://console.anthropic.com/)
  - OpenAI API key from [OpenAI Platform](https://platform.openai.com/) (optional, for fallback)

### Setup

1. **Clone the repository**
```bash
   git clone https://github.com/YOUR_USERNAME/content-summarizer.git
   cd content-summarizer
```

2. **Install dependencies**
```bash
   bundle install
```

3. **Start Redis** (if not already running)
```bash
   # macOS
   brew services start redis
   
   # Linux
   sudo systemctl start redis
   
   # Docker
   docker run -d -p 6379:6379 redis
   
   # Verify it's running
   redis-cli ping  # Should return "PONG"
```

4. **Set environment variables**
```bash
   # Required
   export CLAUDE_API_KEY='sk-ant-your-key-here'
   
   # Optional (for fallback)
   export OPENAI_API_KEY='sk-your-key-here'
   
   # Optional (custom Redis)
   export REDIS_URL='redis://localhost:6379/0'
```

5. **Run tests to verify setup**
```bash
   bundle exec rspec
```
   
   You should see all tests passing! ✅

---

## 📖 Usage

### Command Line Interface

**Basic usage:**
```bash
ruby bin/summarize "https://example.com/article"
```

**Demo mode** (no API key required):
```bash
ruby bin/summarize "https://example.com/article" --demo
```

**Output:**
```
🚀 Starting summarization...
📰 URL: https://example.com/article

============================================================
📝 SUMMARY
============================================================
This article discusses the evolution of web technologies...
[AI-generated summary appears here]
============================================================
```

---

### As a Ruby Gem
```ruby
require 'content_summarizer'

# 1. Set up cache
cache = ContentSummarizer::Cache.new

# 2. Create service
service = ContentSummarizer::ContentSummarizationService.new(
  api_key: ENV['CLAUDE_API_KEY'],
  cache: cache
)

# 3. Summarize!
summary = service.summarize_url('https://example.com/article')
puts summary
```

---

### Advanced Usage

#### With Fallback (Claude → OpenAI)
```ruby
# Create clients
claude = ContentSummarizer::ClaudeClient.new(
  api_key: ENV['CLAUDE_API_KEY']
)
openai = ContentSummarizer::OpenAIClient.new(
  api_key: ENV['OPENAI_API_KEY']
)

# Wrap in fallback
fallback_client = ContentSummarizer::FallbackAPIClient.new(
  primary: claude,
  fallback: openai
)

# Create summarizer with fallback
summarizer = ContentSummarizer::Summarizer.new(
  api_client: fallback_client
)

# Create service
service = ContentSummarizer::ContentSummarizationService.new(
  api_key: 'not-used',  # Using custom summarizer
  summarizer: summarizer,
  cache: cache
)

# Now if Claude fails, automatically tries OpenAI!
summary = service.summarize_url(url)
```

#### Without Caching
```ruby
# Skip cache initialization
service = ContentSummarizationService.new(
  api_key: ENV['CLAUDE_API_KEY']
  # No cache parameter = no caching
)
```

#### Custom Scraping
```ruby
# Use WebScraper directly
scraped = ContentSummarizer::WebScraper.scrape(url)

puts scraped.title      # => "Article Title"
puts scraped.content    # => "Full article text..."
puts scraped.images     # => ["image alt text 1", "image alt text 2"]

# Then summarize just the content
client = ContentSummarizer::ClaudeClient.new(api_key: key)
summarizer = ContentSummarizer::Summarizer.new(api_client: client)
summary = summarizer.summarize(scraped.content)
```

---

## 🧪 Running Tests
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/web_scraper_spec.rb

# Run with documentation format
bundle exec rspec --format documentation

# Run with coverage report (if you add SimpleCov)
COVERAGE=true bundle exec rspec
```

**Expected output:**
```
ContentSummarizer::Cache
  #set and #get
    stores and retrieves a value
    returns nil for non-existent keys
  #exists?
    returns true when key exists
    returns false when key does not exist
  ...

Finished in 0.5 seconds (files took 0.2 seconds to load)
42 examples, 0 failures
```

---

## 🐛 Troubleshooting

### Redis Connection Error
```
Error connecting to Redis on localhost:6379 (Errno::ECONNREFUSED)
```

**Solution:** Make sure Redis is running:
```bash
redis-cli ping  # Should return "PONG"
```

### Authentication Error
```
ContentSummarizer::AuthenticationError: Invalid API key
```

**Solution:** Check your API key is set correctly:
```bash
echo $CLAUDE_API_KEY  # Should print your key
```

### Empty Content Error
```
ContentSummarizer::EmptyContentError: No content found at URL
```

**Solution:** The page might not have standard HTML structure. Try a different URL or check if the site blocks scrapers.

### Low Credit Balance (400 Error)
```
Your credit balance is too low to access the Anthropic API
```

**Solution:** Add credits at [Anthropic Console](https://console.anthropic.com/settings/billing) or use `--demo` mode.

## ⚡ Performance & Cost Optimization

### Caching Benefits
Without caching, every identical URL request:
- Scrapes the website again (network latency)
- Calls the AI API again (costs money)
- Takes several seconds

With Redis caching (24-hour TTL):
- **Subsequent requests:** Near-instant (Redis lookup)
- **Cost savings:** Eliminates duplicate API calls
- **Speed improvement:** Orders of magnitude faster

**Why 24-hour TTL?** Articles rarely change within a day, balancing freshness with efficiency.

### Design Choices for Efficiency
- **Fallback strategy:** Reduces failed requests when primary API is unavailable
- **Global cache:** All users benefit from any cached summary