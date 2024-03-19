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
          headers       = {
            "Content-Type"  => "application/json",
            "Authorization" => "Bearer #{ImmosquareTranslate.configuration.openai_api_key}"
          }

          prompt_system = "As a sophisticated translation AI, your role is to translate sentences from a specified source language to multiple target languages. " \
                          "It is imperative that you return the translations in a single, pure JSON string format. Use ISO 639-1 language codes for specifying languages. " \
                          "if string is html, you should return the translated html." \
                          "Ensure that the output does not include markdown (```json) or any other formatting characters. Adhere to the JSON structure meticulously."


          prompt = "Translate the following sentences from '#{from_iso}' into the languages #{to_iso.join(", ")}, and format the output as a single, pure JSON string. " \
                   "Follow the structure: {\"datas\":[{\"en\":\"English Translation\",\"es\":\"Spanish Translation\",\"it\":\"Italian Translation\"}]}, using the correct ISO 639-1 language codes for each translation. " \
                   "Your response should strictly conform to this JSON structure without any additional characters or formatting. Sentences to translate are:"

          text.each_with_index do |sentence, index|
            prompt += "\n#{index + 1}: #{sentence}"
          end


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


          p = JSON.parse(choice["message"]["content"])
          p["datas"]
        rescue StandardError => e
          puts(e.message)
          puts(e.backtrace)
          false
        end
      end


    end
  end
end
