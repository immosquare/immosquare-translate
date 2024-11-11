require "immosquare-constants"
require "iso-639"
require "countries"

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
      def translate(texts, from, to)
        begin
          raise("Error: openai_api_key not found in config_dev.yml") if ImmosquareTranslate.configuration.openai_api_key.nil?
          raise("Error: locale from is not a locale")                if !from.is_a?(String) || from.size != 2
          raise("Error: locales is not an array of locales")         if !to.is_a?(Array) || to.empty? || to.any? {|l| !l.is_a?(String) }

          model_name          = ImmosquareTranslate.configuration.openai_model
          model               = OPEN_AI_MODELS.find {|m| m[:name] == model_name }
          model               = OPEN_AI_MODELS.find {|m| m[:name] == "gpt-4o" } if model.nil?
          from_language_name  = ISO_639.find_by_code(from).english_name.split(";").first
          to_iso              = to
            .reject {|code| ImmosquareConstants::Locale.native_name_for_locale(code).nil? }
            .map do |iso|
            iso_parts             = iso.split("-")
            iso_language          = iso_parts.first.downcase
            iso_country           = iso_parts.size > 1 ? iso_parts.last.downcase : nil
            language_english_name = ISO_639.find_by_code(iso_language)&.english_name&.split(";")&.first
            country_english_name  = iso_country.nil? ? nil : ISO3166::Country.find_country_by_alpha2(iso_country)&.iso_short_name
            [iso, language_english_name, country_english_name]
          end

          puts(to_iso.inspect)

          headers       = {
            "Content-Type"  => "application/json",
            "Authorization" => "Bearer #{ImmosquareTranslate.configuration.openai_api_key}"
          }

          prompt_system = "As a sophisticated translation AI, your role is to translate sentences from a specified source language to multiple target languages.\n" \
                          "We pass you a target languages as array of array with this format [iso_code to  use (2 or 4 letters), language target name , country name (country vocabulary to  use, this paramaeter is optional, can be null)]\n" \
                          "Rules to respect:\n" \
                          "- Use inputed iso codes for specifying languages." \
                          "- Respond with an array of a flat objects in JSON (minified, without any extraneous characters or formatting)\n" \
                          "- Format the translation output as a JSON string adhering to the following structure: {\"datas\":[{\"locale_iso\": \"Translated Text\"}]} where locale_iso is language code for specifying languages." \
                          "- Ensure that the output does not include markdown (```json) or any other formatting characters. Adhere to the JSON structure meticulously.\n" \
                          "- Correct any spelling or grammatical errors in the source text before translating.\n" \
                          "- If the source language is also a target language, include the corrected version of the sentence for that language as well, if not dont include it.\n" \
                          "- If string to translate is html, you should return the translated html.\n" \
                          "- If string to translate contains underscores in row, keep them, don't remove them\n" \

          prompt = "Translate the #{texts.size} following #{texts.size == 1 ? "text" : "texts"} from the source language : #{from_language_name} to the target languages specified #{to_iso}"


          ##============================================================##
          ## we replace the \n \t by ___ to avoid JSON parsing errors
          ## We use the same symbol to replace the \n and \t because
          ## if we use different symbols sometimes the API inverse them.
          ##============================================================##
          texts.each_with_index do |sentence, index|
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
              .select {|key, _| to.map(&:downcase).include?(key.downcase) }
              .transform_values {|value| value.gsub("____", "\t").gsub("___", "\n") }
              .transform_keys do |key|
                key.to_s.split("-").map.with_index do |part, index|
                  index == 0 ? part.downcase : part.upcase
                end.join("-").to_sym
              end
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
