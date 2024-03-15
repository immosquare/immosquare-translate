module ImmosquareTranslate
  module Translator
    extend SharedMethods
    class << self

      ##============================================================##
      ## Pour récupérer la liste des channels
      ##============================================================##
      def translate(text, from, to)
        puts(text.inspect)
        puts(from)
        puts(to.inspect)
        puts(ImmosquareTranslate.configuration.openai_api_key)
      end






    end
  end
end
