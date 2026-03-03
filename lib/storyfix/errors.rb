module Storyfix
  class StoryfixError < StandardError; end
  
  class MissingApiKeyError < StoryfixError
    def initialize(msg = "OpenRouter API key is missing. Set OPENROUTER_API_KEY environment variable or 'api-key' setting.")
      super(msg)
    end
  end
  
  class ApiError < StoryfixError
    attr_reader :status, :body
    
    def initialize(status, body)
      @status = status
      @body = body
      super("API Error (#{status}): #{body}")
    end
  end
  
  class EmptyResponseError < StoryfixError
    def initialize(msg = "The API returned an empty response.")
      super(msg)
    end
  end
  
  class TimeoutError < StoryfixError
    def initialize(msg = "The API request timed out. You may want to retry.")
      super(msg)
    end
  end
end
