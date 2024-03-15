module ImmosquareTranslate
  class Configuration

    attr_accessor :openai_api_key, :openai_model

    def initialize
      @openai_api_key = nil
      @openai_model   = nil
    end

  end
end
