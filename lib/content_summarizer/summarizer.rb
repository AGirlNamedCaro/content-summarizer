module ContentSummarizer
    class Summarizer
      def initialize(api_client:)
        @api_client = api_client
      end
  
      def summarize(text)
        @api_client.summarize(text)
      end
    end
  end