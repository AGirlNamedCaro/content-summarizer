require "nokogiri"
require "httparty"

module ContentSummarizer
  class WebScraper
    def self.scrape(url)
      html = fetch_html(url)
      doc = Nokogiri::HTML(html)

      title = extract_title(doc)
      content = extract_content(doc)
      images = extract_images(doc)

      if content.strip.empty?
        raise EmptyContentError, "No content found at #{url}"
      end

      ScrapedContent.new(title: title, content: content, images: images)
    end

    private

    def self.fetch_html(url)
      # Validate URL format
      uri = URI.parse(url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        raise InvalidURLError, "Invalid URL: #{url}"
      end

      response = HTTParty.get(url)

      unless response.success?
        raise InvalidURLError, "Failed to fetch URL: HTTP #{response.code}"
      end

      response.body
    rescue URI::InvalidURIError
      raise InvalidURLError, "Malformed URL: #{url}"
    rescue SocketError, Errno::ECONNREFUSED, Errno::ENOENT => e
      raise InvalidURLError, "Cannot reach URL: #{e.message}"
    end

    def self.extract_title(doc)
      doc.css("h1").first&.text || doc.css("title").first&.text || "Untitled"
    end

    def self.extract_content(doc)
      content = doc.css("article p").map(&:text).join(" ")
      return content unless content.strip.empty?

      content = doc.css("main p").map(&:text).join(" ")
      return content unless content.strip.empty?

      doc.css("p").map(&:text).join(" ")
    end

    def self.extract_images(doc)
      doc.css("img").map { |img| img["alt"] }.compact
    end
  end
end
