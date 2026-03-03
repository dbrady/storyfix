require "net/http"
require "json"
require "uri"

module Storyfix
  class ApiClient
    ENDPOINT = "https://openrouter.ai/api/v1/chat/completions"

    def initialize(api_key, model, timeout = 60)
      @api_key = api_key
      @model = model
      @timeout = timeout.to_i
    end

    def call(system_prompt, user_content)
      raise MissingApiKeyError if @api_key.nil? || @api_key.strip.empty?

      uri = URI(ENDPOINT)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"
      request["HTTP-Referer"] = "https://github.com/dbrady/storyfix"
      request["X-Title"] = "StoryFix"

      request.body = JSON.generate({
        model: @model,
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_content }
        ]
      })

      begin
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: @timeout) do |http|
          http.request(request)
        end
      rescue Net::ReadTimeout, Net::OpenTimeout
        raise TimeoutError
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise ApiError.new(response.code, response.body)
      end

      data = JSON.parse(response.body)
      choices = data["choices"]
      
      if choices.nil? || choices.empty? || choices.first.dig("message", "content").nil? || choices.first.dig("message", "content").strip.empty?
        raise EmptyResponseError
      end

      choices.first.dig("message", "content")
    end
  end
end
