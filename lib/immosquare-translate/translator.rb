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
          to_iso        = to.map {|iso| [iso, ISO_639.find_by_code(iso).english_name.split(";").first] }
          headers       = {
            "Content-Type"  => "application/json",
            "Authorization" => "Bearer #{ImmosquareTranslate.configuration.openai_api_key}"
          }

          prompt_system = "As a sophisticated translation AI, your role is to translate sentences from a specified source language to multiple target languages.\n" \
                          "Rules to respect:\n" \
                          "- Use ISO 639-1 language codes for specifying languages." \
                          "- Respond with an array of a flat objects in JSON (minified, without any extraneous characters or formatting)\n" \
                          "- Format the translation output as a JSON string adhering to the following structure: {\"datas\":[{\"locale_iso\": \"Translated Text\"}]}" \
                          "- Ensure that the output does not include markdown (```json) or any other formatting characters. Adhere to the JSON structure meticulously.\n" \
                          "- Correct any spelling or grammatical errors in the source text before translating.\n" \
                          "- If the source language is also a target language, include the corrected version of the sentence for that language as well, if not dont include it.\n" \
                          "- If string to translate is html, you should return the translated html.\n" \
                          "- If string to translate contains underscores in row, keep them, don't remove them\n" \



          prompt = "Translate the #{text.size} following #{text.size == 1 ? "sentence" : "sentences"} from the source language (ISO 639-1 code: #{from}) to the target languages specified: #{to_iso.map {|iso, language| "#{language} (ISO 639-1 code: #{iso})" }.join(", ")}. "


          ##============================================================##
          ## we replace the \n \t by ___ to avoid JSON parsing errors
          ## We use the same symbol to replace the \n and \t because
          ## if we use different symbols sometimes the API inverse them.
          ##============================================================##
          text.each_with_index do |sentence, index|
            prompt += "\n#{index + 1}: #{sentence.gsub("\n", "___").gsub("\t", "____")}"
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


          ##============================================================##
          ## On s'assure de ne renvoyer que les locales demandées
          ## car l'API peut renvoyer des locales non demandées...
          ##============================================================##
          content = JSON.parse(choice["message"]["content"])
          datas   = content["datas"]
          datas.map do |hash|
            hash
              .select {|key, _| to.include?(key) }
              .transform_values {|value| value.gsub("____", "\t").gsub("___", "\n") }
          end.reject(&:empty?)
        rescue StandardError => e
          puts(e.message)
          puts(e.backtrace)
          false
        end
      end


    end
  end
end
