module ImmosquareTranslate
  module Translator
    extend SharedMethods
    class << self

      ##============================================================##
      ## Translate Data
      ## ["Bonjour"], "fr", ["en", "es", "it"]
      ## text : array
      ## from : string
      ## to   : array
      ##============================================================##
      def translate(text, from, to)
        begin
          raise("Error: openai_api_key not found in config_dev.yml") if ImmosquareTranslate.configuration.openai_api_key.nil?
          raise("Error: locale from is not a locale")                if !from.is_a?(String) || from.size != 2
          raise("Error: locales is not an array of locales")         if !to.is_a?(Array) || to.empty? || to.any? {|l| !l.is_a?(String) || l.size != 2 }

          model_name    = ImmosquareYaml.configuration.openai_model
          model         = OPEN_AI_MODELS.find {|m| m[:name] == model_name }
          model         = OPEN_AI_MODELS.find {|m| m[:name] == "gpt-4-0125-preview" } if model.nil?
          from_iso      = ISO_639.find_by_code(from).english_name.split(";").first
          to_iso        = to.map {|l| ISO_639.find_by_code(l).english_name.split(";").first }
          prompt_system = "You are a translation tool from #{from_iso} to #{to_iso.join(",")}\n"
          headers       = {
            "Content-Type"  => "application/json",
            "Authorization" => "Bearer #{ImmosquareTranslate.configuration.openai_api_key}"
          }
          prompt = "Translate the following text from #{from_iso} to #{to_iso.join(",")}\n"
          prompt += text.map {|t| "#{t}\n" }.join

          body = {
            :model       => model[:name],
            :messages    => [
              {:role => "system", :content => prompt_system},
              {:role => "user",   :content => prompt}
            ],
            :temperature => 0.0
          }
          t0   = Time.now
          call = HTTParty.post("https://api.openai.com/v1/chat/completions", :body => body.to_json, :headers => headers, :timeout => 500)

          puts("responded in #{(Time.now - t0).round(2)} seconds")
          raise(call["error"]["message"]) if call.code != 200

          ##============================================================##
          ## We check that the result is complete
          ##============================================================##
          response  = JSON.parse(call.body)
          choice    = response["choices"][0]
          raise("Result is not complete") if choice["finish_reason"] != "stop"

          ##============================================================##
          ## We calculate the estimate price of the call
          ##============================================================##
          input_price   = response["usage"]["prompt_tokens"]     * (model[:input_price_for_1m] / 1_000_000)
          output_price  = response["usage"]["completion_tokens"] * (model[:output_price_for_1m] / 1_000_000)
          price         = input_price + output_price
          puts("Estimate price => #{input_price.round(3)} + #{output_price.round(3)} = #{price.round(3)} USD")

          puts(choice["message"]["content"])
        rescue StandardError => e
          puts(e.message)
          puts(e.backtrace)
          false
        end
      end






    end
  end
end
