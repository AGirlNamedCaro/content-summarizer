require "spec_helper"

RSpec.describe ContentSummarizer::WebScraper do
  describe ".scrape" do
    let(:url) { "https://example.com/article" }

    it "returns scraped content with title and body" do
      html_content = <<~HTML
        <html>
          <head><title>Test Article Title</title></head>
          <body>
            <article>
              <h1>Test Article Title</h1>
              <p>This is the main article content.</p>
              <p>More content here.</p>
            </article>
          </body>
        </html>
      HTML

      stub_request(:get, url)
        .to_return(
          status: 200,
          body: html_content,
          headers: { "Content-Type" => "text/html" },
        )

      result = ContentSummarizer::WebScraper.scrape(url)
      expect(result.title).to eq("Test Article Title")
      expect(result.content).to include("This is the main article content")
      expect(result.content).to include("More content here")
    end

    context "when there is no article tag" do
      it "falls back to main tag or all paragraphs" do
        html_content = <<~HTML
          <html>
            <head><title>No Article Tag</title></head>
            <body>
              <main>
                <p>This is content in main tag.</p>
                <p>More content here.</p>
              </main>
            </body>
          </html>
        HTML

        stub_request(:get, url)
          .to_return(status: 200, body: html_content, headers: { "Content-Type" => "text/html" })

        result = ContentSummarizer::WebScraper.scrape(url)

        expect(result.title).to eq("No Article Tag")
        expect(result.content).to include("This is content in main tag")
        expect(result.content).to include("More content here")
      end
    end

    context "when URL is invalid" do
      it "raises a meaningful error" do
        expect { ContentSummarizer::WebScraper.scrape("not-a-url") }.to raise_error(ContentSummarizer::InvalidURLError)
      end
    end

    context "when page has no extractable content" do
      it "raises an error" do
        html_content = <<~HTML
          <html>
            <head><title>Empty Page</title></head>
            <body>
              <nav>Navigation only</nav>
            </body>
          </html>
        HTML

        stub_request(:get, url)
          .to_return(status: 200, body: html_content, headers: { "Content-Type" => "text/html" })

        expect { ContentSummarizer::WebScraper.scrape(url) }.to raise_error(ContentSummarizer::EmptyContentError, /No content found/)
      end
    end
  end
end
