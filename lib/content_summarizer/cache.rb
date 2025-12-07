require "redis"

module ContentSummarizer
  class Cache
    def initialize(redis_client: nil)
      @redis = redis_client || Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379/0")
    end

    def set(key, value, ttl: nil)
      if ttl
        @redis.set(key, value, ex: ttl)
      else
        @redis.set(key, value)
      end
    end

    def get(key)
      @redis.get(key)
    end

    def exists?(key)
      @redis.exists?(key)
    end

    def clear
      @redis.flushdb
    end
  end
end
