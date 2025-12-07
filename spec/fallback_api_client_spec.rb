require "spec_helper"
RSpec.describe ContentSummarizer::FallbackAPIClient do
  describe "#summarize" do
    let(:primary_client) { instance_double(ContentSummarizer::ClaudeClient) }
    let(:fallback_client) { instance_double(ContentSummarizer::OpenAIClient) }
    let(:client) { described_class.new(primary: primary_client, fallback: fallback_client) }
    let(:text) { "Long text to summarize" }

    context "when primary client succeeds" do
      before do
        allow(primary_client).to receive(:summarize).with(text).and_return("This is a summary")
      end

      it "returns the summary from the primary client" do
        result = client.summarize(text)
        expect(result).to eq("This is a summary")
      end
    end

    context "when primary client fails with ServerError and fallback client succeeds" do
      before do
        allow(primary_client).to receive(:summarize).with(text).and_raise(ContentSummarizer::ServerError)
        allow(fallback_client).to receive(:summarize).with(text).and_return("This is a summary")
      end

      it "returns the summary from the fallback client" do
        result = client.summarize(text)
        expect(result).to eq("This is a summary")
      end
    end

    context "when primary client fails with Authentication error and fallback client succeeds" do
      before do
        allow(primary_client).to receive(:summarize).with(text).and_raise(ContentSummarizer::AuthenticationError)
        allow(fallback_client).to receive(:summarize).with(text).and_return("This is a summary")
      end

      it "returns the summary from the fallback client" do
        result = client.summarize(text)
        expect(result).to eq("This is a summary")
      end
    end

    context "when both clients fail" do
      before do
        allow(primary_client).to receive(:summarize).with(text).and_raise(ContentSummarizer::ServerError)
        allow(fallback_client).to receive(:summarize).with(text).and_raise(ContentSummarizer::ServerError)
      end

      it "raises the error" do
        expect { client.summarize(text) }.to raise_error(ContentSummarizer::ServerError)
      end
    end
  end
end
