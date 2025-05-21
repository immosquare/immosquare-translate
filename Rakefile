require "immosquare-translate"
require "yaml"


namespace :immosquare_translate do
  desc "Translate tasks"

  namespace :sample do
    ##============================================================##
    ## Load config keys from config_dev.yml
    ##============================================================##
    def load_config
      path = "#{File.dirname(__FILE__)}/config_dev.yml"
      abort("Error: config_dev.yml not found") if !File.exist?(path)

      ##============================================================##
      ## Load config keys from config_dev.yml
      ##============================================================##
      dev_config = YAML.load_file(path)
      abort("Error config_dev.yml is empty") if dev_config.nil?

      ImmosquareTranslate.config do |config|
        config.openai_api_key = dev_config["openai_api_key"]
      end
    end

    ##============================================================##
    ## Translate the sample YAML file
    ## rake immosquare_translate:sample:translate_yml
    ##============================================================##
    desc "Translate the sample file"
    task :translate_yml do
      load_config
      input_path = "#{File.dirname(__FILE__)}/spec/input/sample.en.yml"
      ImmosquareTranslate::YmlTranslator.translate(input_path, "fr")
    end



    ##============================================================##
    ## Transalate text from English to French + fix spelling
    ## rake immosquare_translate:sample:translate
    ##============================================================##
    desc "Translate texts"
    task :translate do
      load_config
      texts            = ["Bonjour mes ami", "O revoir", "je vais au supermarché", "je vais acheter des chaussettes"]
      target_languages = ["en", "es", "fr", "it", "fr-ca"]
      datas            = ImmosquareTranslate::Translator.translate(texts, "fr", target_languages)
      datas.each do |data|
        puts("-" * 100)
        puts(data.inspect)
      end
    end
  end
end
