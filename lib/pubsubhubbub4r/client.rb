begin
  require 'digest/sha1'
rescue LoadError
  require 'sha1'
end

module Pubsubhubbub4r
  class Client
    HTTP_TIMEOUT = 60
    attr_accessor :cache, :logger, :headers, :post_data_overrides

    def initialize(cache, logger = nil, headers = nil, post_data_overrides = nil)
      # "cache" and "logger" must respond like Rails.cache / Rails.logger
      @cache = cache
      @logger = logger
      @headers = headers
      # e.g. {'hub.verify' => 'sync'}
      @post_data_overrides = post_data_overrides
    end

    def subscribe(hub_url, topic, callback_url, lease_seconds = 2592000, ack_timeout_seconds = 86400)
      post('subscribe', hub_url, topic, callback_url, lease_seconds, ack_timeout_seconds)
    end

    def unsubscribe(hub_url, topic, callback_url, lease_seconds = 2592000, ack_timeout_seconds = 86400)
      post('unsubscribe', hub_url, topic, callback_url, lease_seconds, ack_timeout_seconds)
    end

    def verify(params)
      cache_key = verification_cache_key(params['hub.verify_token'])
      cached_secret = self.cache.read(cache_key)
      new_secret = verification_secret(params['hub.mode'], params['hub.topic'])
      self.logger.debug "verifying #{cache_key.inspect}: #{cached_secret.inspect} vs #{new_secret.inspect}" if self.logger
      if cached_secret && cached_secret == new_secret
        self.cache.delete(cache_key)
        params['hub.challenge']
      else
        false
      end
    end

    protected

      def verification_cache_key(verify_token)
        "verify_token-#{verify_token}"
      end

      def verification_secret(mode, topic)
        [mode, topic].join("#")
      end

      def post(mode, hub_url, topic, callback_url, lease_seconds, ack_timeout_seconds)
        verify_token = SHA1.hexdigest("#{[mode, topic, callback_url, lease_seconds, rand(ack_timeout_seconds), Time.now.to_f].join('.')}")
        cache_key = verification_cache_key(verify_token)
        self.cache.write(cache_key, verification_secret(mode, topic))
        uri = URI.parse(hub_url)
        request_headers = { 'User-Agent' => 'Pubsubhubbub4r::Client' }.merge(self.headers || {})
        request = Net::HTTP::Post.new(uri.request_uri, request_headers)
        request.form_data = {
          'hub.mode' => mode,
          'hub.callback' => callback_url,
          'hub.topic' => topic,
          'hub.verify_token' => verify_token,
          'hub.lease_seconds' => lease_seconds,
          'hub.verify' => 'async',
        }.merge(self.post_data_overrides || {})
        session = Net::HTTP.new(uri.host, uri.port)
        session.use_ssl = true if uri.scheme == "https"
        response = session.start do |http|
          http.read_timeout = HTTP_TIMEOUT
          yield http if block_given?
          http.request(request)
        end
        case response && response.code.to_s
        when "204"
          self.cache.delete(cache_key)
          self.logger.debug "#{mode} : verified" if self.logger
          lease_seconds
        when "202"
          self.logger.debug "#{mode} : accepted, verify later" if self.logger
          nil
        else
          raise "#{response.code} #{response.message} #{response.body}".strip
        end
      end
  end
end
