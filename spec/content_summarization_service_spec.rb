require "spec_helper"

RSpec.describe ContentSummarizer::ContentSummarizationService do
  let(:api_key) { "test-key-123" }
  let(:url) { "https://example.com/article" }

  let(:scraped_content) do
    ContentSummarizer::ScrapedContent.new(
      title: "Test Article",
      content: "This is the article content.",
      images: [],
    )
  end

  describe "#summarize_url" do
    let(:service) { ContentSummarizer::ContentSummarizationService.new(api_key: api_key) }

    def stub_successful_claude_api
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(
          status: 200,
          body: { content: [{ type: "text", text: "This is a summary" }] }.to_json,
          headers: { "Content-Type" => "application/json" },
        )
    end

    context "when everything works" do
      before do
        allow(ContentSummarizer::WebScraper).to receive(:scrape)
                                                  .with(url)
                                                  .and_return(scraped_content)

        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .to_return(
            status: 200,
            body: { content: [{ type: "text", text: "This is a summary" }] }.to_json,
            headers: { "Content-Type" => "application/json" },
          )
        stub_successful_claude_api
      end

      it "scrapes the URL and returns a summary" do
        result = service.summarize_url(url)

        expect(result).to eq "This is a summary"
      end
    end

    context "when scraping fails" do
      before do
        allow(ContentSummarizer::WebScraper).to receive(:scrape)
                                                  .with(url)
                                                  .and_raise(ContentSummarizer::InvalidURLError, "Invalid URL")
      end

      it "raises the scraping error" do
        expect { service.summarize_url(url) }.to raise_error(ContentSummarizer::InvalidURLError, /Invalid URL/)
      end

      context "when scraping returns empty content" do
        before do
          allow(ContentSummarizer::WebScraper).to receive(:scrape)
                                                    .with(url)
                                                    .and_raise(ContentSummarizer::EmptyContentError, "No content found")
        end
        it "raises the empty content error" do
          expect { service.summarize_url(url) }.to raise_error(ContentSummarizer::EmptyContentError, /No content found/)
        end
      end

      describe "when Claude API fails" do
        before do
          allow(ContentSummarizer::WebScraper).to receive(:scrape)
                                                    .with(url)
                                                    .and_return(scraped_content)
        end

        context "when Claude API fails with auth error" do
          before do
            stub_request(:post, "https://api.anthropic.com/v1/messages")
              .to_return(
                status: 401,
                body: { error: { message: "Invalid API key" } }.to_json,
              )
          end

          it "raises an authentication error" do
            expect { service.summarize_url(url) }.to raise_error(ContentSummarizer::AuthenticationError)
          end
        end

        context "when Claude API fails with server error" do
          before do
            stub_request(:post, "https://api.anthropic.com/v1/messages")
              .to_return(
                status: 500,
                body: { error: { message: "Server Error" } }.to_json,
              )
          end

          it "raises a standard error " do
            expect { service.summarize_url(url) }.to raise_error(ContentSummarizer::ServerError)
          end
        end
      end
    end
  end

  describe "caching behaviour" do
    let(:cache) { ContentSummarizer::Cache.new }
    let(:service) { described_class.new(api_key: api_key, cache: cache) }

    before do
      cache.clear

      allow(ContentSummarizer::WebScraper).to receive(:scrape).with(url).and_return(scraped_content)

      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(
          status: 200,
          body: { content: [{ type: "text", text: "This is a summary" }] }.to_json,
          headers: { "Content-Type" => "application/json" },
        )
    end

    context "when summary is not cached" do
      it "scrapes, summarizes, and caches result" do
        expect(cache.exists?(url)).to be false

        result = service.summarize_url(url)

        expect(result).to eq "This is a summary"
        expect(cache.exists?(url)).to be true
        expect(cache.get(url)).to eq "This is a summary"
      end
    end

    context "when summary is cached" do
      before do
        cache.set(url, "Cached summary")
      end

      it "returns cached result without scraping or calling API" do
        result = service.summarize_url(url)

        expect(result).to eq "Cached summary"
        expect(ContentSummarizer::WebScraper).not_to have_received(:scrape)
        expect(WebMock).not_to have_requested(:post, "https://api.anthropic.com/v1/messages")
      end
    end
  end
end
