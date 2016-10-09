# frozen_string_literal: true
module Hivent

  module Redis

    module Extensions

      LUA_CACHE = Hash.new { |h, k| h[k] = Hash.new }

      def script(file, *args)
        cache = LUA_CACHE[@redis.client.options[:url]]

        sha = if cache.key?(file)
                cache[file]
              else
                cache[file] = @redis.script("LOAD", File.read(file))
              end

        @redis.evalsha(sha, [], args)
      end

    end

  end

end
