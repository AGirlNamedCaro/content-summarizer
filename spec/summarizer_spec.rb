require 'spec_helper'

RSpec.describe ContentSummarizer::Summarizer do
    describe "#summarize" do
        it 'returns a summary of the given text' do
            fake_api_client = double('APIClient')
            allow(fake_api_client).to receive(:summarize)
            .with("Long text here")
            .and_return("This is a summary")

            summarizer = ContentSummarizer::Summarizer.new(api_client: fake_api_client)

            result = summarizer.summarize("Long text here")

            expect(result).to eq("This is a summary")
        end
    end
end