require "spec_helper"

RSpec.describe ContentSummarizer::ContentSummarizationService do
  describe "#summarize_url" do
    let(:api_key) { "test-key-123" }
    let(:url) { "https://example.com/article" }
    let(:service) { ContentSummarizer::ContentSummarizationService.new(api_key: api_key) }
    let(:scraped_content) do
      ContentSummarizer::ScrapedContent.new(
        title: "Test Article",
        content: "This is the article content.",
        images: [],
      )
    end

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
end
