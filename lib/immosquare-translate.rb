require_relative "immosquare-translate/configuration"
require_relative "immosquare-translate/shared_methods"
require_relative "immosquare-translate/yml_translator"
require_relative "immosquare-translate/translator"
require_relative "immosquare-translate/railtie" if defined?(Rails)


module ImmosquareTranslate
  class << self

    ##============================================================##
    ## Gem configuration
    ##============================================================##
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def config
      yield(configuration)
    end


  end
end
