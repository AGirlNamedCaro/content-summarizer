require "spec_helper"

RSpec.describe ContentSummarizer::Cache do
  let(:cache) { described_class.new }
  let(:key) { "test_key" }
  let(:value) { "test_value" }

  describe "#set and #get" do
    it "stores and retrieves a value" do
      cache.set(key, value)
      retrieved_value = cache.get(key)
      expect(retrieved_value).to eq(value)
    end

    it "returns nil for non-existent keys" do
      cached_value = cache.get("non_existent_key")
      expect(cached_value).to be_nil
    end
  end

  describe "#exists?" do
    it "returns true when key exists" do
      cache.set(key, value)
      expect(cache.exists?(key)).to be true
    end

    it "returns false when key does not exist" do
      cache.set(key, value)
      expect(cache.exists?("nonexistent_key")).to be false
    end
  end

  describe "Time to live" do
    it "expires keys after TTL" do
      cache.set(key, value, ttl: 1)
      cached_value = cache.get(key)
      expect(cached_value).to eq(value)
      sleep(2)
      expect(cache.get(key)).to be_nil
    end
  end

  describe "#clear" do
    it "removes all cached values" do
      cache.set(key, value)
      cache.clear
      expect(cache.get(key)).to be_nil
    end
  end
end
