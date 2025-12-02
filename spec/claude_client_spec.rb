require "spec_helper"

RSpec.describe ContentSummarizer::ClaudeClient do
  describe "#summarize" do
    let(:client) { described_class.new(api_key: api_key) }

    context "when API returns a successful response" do
      let(:api_key) { "test_key_123" }
      it "returns the summary text " do
        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .to_return(
            status: 200,
            body: { content: [{ type: "text", text: "This is a summary" }] }.to_json,
            headers: { "Content-Type" => "application/json" },
          )

        result = client.summarize("long article text here")

        expect(result).to eq("This is a summary")
      end
    end

    context "when API returns 401 unauthorized" do
      let(:api_key) { "wrong_key" }
      it "raises an AuthenticationError" do
        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .to_return(
            status: 401,
            body: { error: { message: "Invalid API key" } }.to_json,
          )

        expect { client.summarize("text") }.to raise_error(ContentSummarizer::AuthenticationError)
      end
    end
  end
end
