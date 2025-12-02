module ContentSummarizer
  class ScrapedContent
    attr_reader :title, :content, :images

    def initialize(title:, content:, images: [])
      @title = title
      @content = content
      @images = images
    end

    def to_s
      "ScrapedContent(title: #{title}, content: #{content[0..50]}..., images: #{images.count})"
    end
  end
end
