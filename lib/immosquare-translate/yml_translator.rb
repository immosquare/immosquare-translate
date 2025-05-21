require "iso-639"
require "httparty"
require "immosquare-yaml"

module ImmosquareTranslate
  module YmlTranslator
    extend SharedMethods

    class << self

      def translate(file_path, locale_to,  options = {})
        begin
          ##============================================================##
          ## options
          ## ---------
          ##============================================================##
          options = {
            :reset_translations => false
          }.merge(options)
          options[:reset_translations] = false  if ![true, false].include?(options[:reset_translations])


          ##============================================================##
          ## Load config keys from config_dev.yml
          ## ---------
          ##============================================================##
          raise("Error: openai_api_key not found in config_dev.yml") if ImmosquareTranslate.configuration.openai_api_key.nil?
          raise("Error: File #{file_path} not found")                if !File.exist?(file_path)
          raise("Error: locale is not a locale")                     if !locale_to.is_a?(String) || locale_to.size != 2

          ##============================================================##
          ## We clean the file before translation
          ##============================================================##
          ImmosquareYaml.clean(file_path)

          ##============================================================##
          ## We parse the clean input file
          ##============================================================##
          hash_from = ImmosquareYaml.parse(file_path)
          raise("#{file_path} is not a correct yml translation file") if !hash_from.is_a?(Hash) && hash_from.keys.size > 1

          ##============================================================##
          ## Check if the locale is present in the file
          ##============================================================##
          locale_from = hash_from.keys.first.to_s
          raise("Error: The destination file (#{locale_to}) is the same as the source file (#{locale_from}).")    if locale_from == locale_to
          raise("Error: Expected the source file (#{file_path}) to end with '#{locale_from}.yml' but it didn't.") if !file_path.end_with?("#{locale_from}.yml")


          ##============================================================##
          ## Prepare the output file
          ##============================================================##
          file_basename        = File.basename(file_path)
          file_dirname         = File.dirname(file_path)
          translated_file_path = "#{file_dirname}/#{file_basename.gsub("#{locale_from}.yml", "#{locale_to}.yml")}"

          ##============================================================##
          ## We create a hash with all keys from the source file
          ##============================================================##
          hash_to = {locale_to => hash_from.delete(locale_from)}

          ##============================================================##
          ## We create a array with all keys from the source file
          ##============================================================##
          array_to = translatable_array(hash_to)
          array_to = array_to.map {|k, v| [k, v, nil] }

          ##============================================================##
          ## If we already have a translation file for the language
          ## we get the values in it and put it in our
          ## file... You have to do well with !nil?
          ## to retrieve the values "" and " "...
          ##============================================================##
          if File.exist?(translated_file_path) && options[:reset_translations] == false
            temp_hash = ImmosquareYaml.parse(translated_file_path)
            raise("#{translated_file_path} is not a correct yml translation file") if !temp_hash.is_a?(Hash) && temp_hash.keys.size > 1

            ##============================================================##
            ## t can be nil if the key is not present in the source file
            ##============================================================##
            translatable_array(temp_hash).each do |key, value|
              t    = array_to.find {|k, _v| k == key }
              t[2] = value if !t.nil? && !value.nil?
            end
          end

          ##============================================================##
          ## Here we have to do all the translation logic...
          ## For the moment we use the OPENAI API, but we can imagine
          ## using other translation APIs in the future.
          ##============================================================##
          translated_array = translate_with_open_ai(array_to, locale_from, locale_to)

          ##============================================================##
          ## Then we have to reformat the output yml file
          ##============================================================##
          final_array = translated_array.map do |k, _from, to|
            parsed_to = !to.nil? && to.start_with?("[") && to.end_with?("]") ? JSON.parse(to) : to
            [k, parsed_to]
          end
          final_hash = translatable_hash(final_array)


          ##============================================================##
          ## We write the output file and clean it
          ##============================================================##
          File.write(translated_file_path, ImmosquareYaml.dump(final_hash))
          ImmosquareYaml.clean(translated_file_path)
        rescue StandardError => e
          puts(e.message)
          puts(e.backtrace)
          false
        end
      end


      private

      ##============================================================##
      ## To translatable hash to array
      ## opitons are :
      ## :format    => "string" or "array"
      ## :keys_only => true or false
      ## {:fr=>{"demo1"=>"demo1", "demo2"=>{"demo2-1"=>"demo2-1"}}}
      ## format = "string" and keys_only = false => [["fr.demo1", "demo1"], ["fr.demo2.demo2-1", "demo2-1"]]
      ## format = "string" and keys_only = true  => ["fr.demo1", "fr.demo2.demo2-1"]
      ## format = "array"  and keys_only = false => [[["fr", "demo1"], "demo1"], [["fr", "demo2", "demo2-1"], "demo2-1"]]
      ## format = "array"  and keys_only = true  => [["fr", "demo1"], ["fr", "demo2", "demo2-1"]]
      ## ---------
      ##============================================================##
      def translatable_array(hash, key = nil, result = [], **options)
        options = {
          :format    => "string",
          :keys_only => false
        }.merge(options)
        options[:keys_only] = false    if ![true, false].include?(options[:keys_only])
        options[:format]    = "string" if !["string", "array"].include?(options[:format])


        if hash.is_a?(Hash)
          hash.each_key do |k|
            translatable_array(hash[k], "#{key}#{":" if !key.nil?}#{k}", result, **options)
          end
        else
          r2 = options[:format] == "string" ? key.split(":").join(".") : key.split(":")
          result << (options[:keys_only] ? r2 : [r2, hash.is_a?(Array) ? hash.to_json : hash])
        end
        result
      end

      ##============================================================##
      ## We can do the inverse of the previous function
      ##============================================================##
      def translatable_hash(array)
        data_hash = array.to_h
        final     = {}
        data_hash.each do |key, value|
          key_parts     = key.split(".")
          leaf          = key_parts.pop
          parent        = key_parts.inject(final) {|h, k| h[k] ||= {} }
          parent[leaf]  = value
        end
        final
      end

      ##============================================================##
      ## Translate with OpenAI
      ## [["en.mlsconnect.contact_us", "Nous contacter", "Contact us"],
      ## ["en.mlsconnect.description", "Description", nil]]
      ##============================================================##
      def translate_with_open_ai(array, from, to)
        ##============================================================##
        ## https://platform.openai.com/docs/models/
        ## https://openai.com/pricing
        ##============================================================##
        model_name = ImmosquareTranslate.configuration.openai_model
        model      = OPEN_AI_MODELS.find {|m| m[:name] == model_name || m[:nickname] == model_name }
        model      = OPEN_AI_MODELS.find {|m| m[:default] == true } if model.nil?

        ##============================================================##
        ## Manage blank values
        ##============================================================##
        blank_values       = [NOTHING, SPACE, "\"\"", "\"#{SPACE}\""]
        cant_be_translated = "CANNOT-BE-TRANSLATED"
        array              = array.map do |key, from, to|
          [key, from, blank_values.include?(from) ? from : to]
        end


        ##============================================================##
        ## we want to send as little data as possible to openAI because
        ## we pay for the volume of data sent. So we're going to send. We put
        ## a number rather than a string for the translations to be made.
        ## ---------
        ## Remove the translations that have already been made
        ##============================================================##
        data_open_ai = array.clone
        data_open_ai = data_open_ai.map.with_index {|(_k, from, to), index| [index, from, to] }
        data_open_ai = data_open_ai.select {|_index, from, to| !from.nil? && to.nil? }

        ##============================================================##
        ## Remove quotes surrounding the value if they are present.
        ## and remove to to avoid error in translation
        ##============================================================##
        data_open_ai = data_open_ai.map do |index, from, _to|
          from = from.to_s
          from = from[1..-2] while (from.start_with?(DOUBLE_QUOTE) && from.end_with?(DOUBLE_QUOTE)) || (from.start_with?(SIMPLE_QUOTE) && from.end_with?(SIMPLE_QUOTE))
          [index, from]
        end

        return array if data_open_ai.empty?


        ##============================================================##
        ## Call OpenAI API
        ##============================================================##
        index         = 0
        group_size    = model[:group_size]
        from_iso      = ISO_639.find_by_code(from).english_name.split(";").first
        to_iso        = ISO_639.find_by_code(to).english_name.split(";").first
        ai_resuslts   = []
        prompt_system = "You are a translation tool from #{from_iso} to #{to_iso}\n" \
                        "The input is an array of pairs, where each pair contains an index and a string to translate, formatted as [index, string_to_translate]\n" \
                        "Your task is to create an output ARRAY where each element is a pair consisting of the index and the translated string, formatted as [index, 'string_translated']\n" \
                        "If a string_to_translate starts with [ and ends with ], it is considered a special string that should be treated as a JSON object. Otherwise, it's a normal string.\n" \
                        "\nRules to respect for JSON objects:\n" \
                        "- You need to translate ONLY the values of the JSON object, not the keys. Do not change anything in the format, just translate the values.\n" \
                        "- Respect all following rules for normal strings to translate the values\n" \
                        "\nRules to respect for normal strings:\n" \
                        "- Do not escape apostrophes in translated strings; leave them as they are.\n" \
                        "- Special characters, except apostrophes, that need to be escaped in translated strings should be escaped using a single backslash (\\), not double (\\\\).\n" \
                        "- If a string cannot be translated use the string '#{cant_be_translated}' translated as the translation value witouth quote (simple or double) quote, just the string\n" \
                        "- If you dont know the correct translatation use the #{cant_be_translated} strategy of the preceding point\n" \
                        "- Use only double quotes (\") to enclose translated strings and avoid using single quotes (').\n" \
                        "- Your output must ONLY be an array with the same number of pairs as the input, without any additional text or explanation. DO NOT COMMENT!\n" \
                        "- You need to check that the globle array is correctly closed at the end of the response. (the response must therefore end with ]] to to be consistent)"
        prompt_init   = "Please proceed with translating the following array:"
        headers       = {
          "Content-Type"  => "application/json",
          "Authorization" => "Bearer #{ImmosquareTranslate.configuration.openai_api_key}"
        }


        ##============================================================##
        ## Estimate the number of window_tokens
        ## https://platform.openai.com/tokenizer
        ## English: 75 words => 100 tokens
        ## French : 55 words => 100 tokens
        ## ---------
        ## For each array value we add 5 tokens for the array format.
        ## [1, "my_word"],
        ## [  => first token
        ## 2  => second token
        ## ,  => third token
        ## "  => fourth token
        ## ]" => fifth token
        ## ---------
        ## data_open_ai.inspect.size => to get the total number of characters in the array
        ## with the array structure [""],
        ##============================================================##
        estimation_for_100_tokens = from == "fr" ? 55 : 75
        prompt_tokens_estimation  = (((prompt_system.split.size + prompt_init.split.size + data_open_ai.map {|_index, from| from.split.size }.sum) / estimation_for_100_tokens * 100.0) + (data_open_ai.size * 5)).round
        split_array               = (prompt_tokens_estimation / model[:window_tokens].to_f).ceil
        slice_size                = (data_open_ai.size / split_array.to_f).round
        data_open_ai_sliced       = data_open_ai.each_slice(slice_size).to_a


        ##============================================================##
        ## Now each slice of the array should no be more than window_tokens
        ## of the model.... We can now translate each slice.
        ## ---------
        ## Normally we could send the whole slice at once and tell the api to continue if its response is not tarnished...
        ## But it should manage if a word is cut etc...
        ## For the moment we cut it into small group for which we are sure not to exceed the limit
        ##============================================================##
        puts("fields to translate from #{from_iso} (#{from}) to #{to_iso} (#{to}) : #{data_open_ai.size}#{" by group of #{group_size}" if data_open_ai.size > group_size}")
        while index < data_open_ai.size
          data_group = data_open_ai[index, group_size]


          begin
            puts("call OPENAI Api (with model #{model[:name]}) #{" for #{data_group.size} fields (#{index}-#{index + data_group.size})" if data_open_ai.size > group_size}")
            prompt = "#{prompt_init}:\n\n#{data_group.inspect}\n\n"
            body   = {
              :model       => model[:name],
              :messages    => [
                {:role => "system", :content => prompt_system},
                {:role => "user",   :content => prompt}
              ],
              :temperature => 0.0
            }
            t0   = Time.now
            url  = "https://api.openai.com/v1/chat/completions"
            call = HTTParty.post(url, :body => body.to_json, :headers => headers, :timeout => 500)

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
            ## We check that the result is an array
            ##============================================================##
            content = eval(choice["message"]["content"])
            raise("Is not an array") if !content.is_a?(Array)

            ##============================================================##
            ## We save the result
            ##============================================================##
            content.each do |index, translation|
              ai_resuslts << [index, translation == cant_be_translated ? nil : translation]
            end
          rescue StandardError => e
            puts("error OPEN AI API => #{e.message}")
            puts(e.message)
            puts(e.backtrace)
          end
          index += group_size
        end


        ##============================================================##
        ## We put the translations in the original array
        ##============================================================##
        ai_resuslts.each do |index, translation|
          begin
            array[index.to_i][2] = translation
          rescue StandardError => e
            puts(e.message)
          end
        end

        ##============================================================##
        ## We return the modified array
        ##============================================================##
        array.map.with_index do |(k, from, to), index|
          from = from.to_s
          to   = "#{DOUBLE_QUOTE}#{to}#{DOUBLE_QUOTE}" if ai_resuslts.find {|i, _t| i == index } && ((from.start_with?(DOUBLE_QUOTE) && from.end_with?(DOUBLE_QUOTE)) || (from.start_with?(SIMPLE_QUOTE) && from.end_with?(SIMPLE_QUOTE)))
          [k, from, to]
        end
      end


    end
  end
end
