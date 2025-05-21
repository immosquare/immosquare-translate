namespace :immosquare_translate do
  ##============================================================##
  ## Function to translate translation files in rails app
  ## rake immosquare_translate:translate SOURCE_LOCALE=fr
  ##============================================================##
  desc "Translate translation files in rails app"
  task :translate_rails_locales => :environment do
    begin
      source_locale      = ENV.fetch("SOURCE_LOCALE", nil)      || I18n.default_locale.to_s
      reset_translations = ENV.fetch("RESET_TRANSLATIONS", nil) || false
      reset_translations = reset_translations == "true"

      raise("Please provide a valid locale")                         if !I18n.available_locales.map(&:to_s).include?(source_locale)
      raise("Please provide a valid boolean for reset_translations") if ![true, false].include?(reset_translations)

      locales = I18n.available_locales.map(&:to_s).reject {|l| l == source_locale }
      return puts("Any translation asked") if locales.empty?

      puts("Translations asked :")
      locales.each do |locale|
        puts("#{source_locale} => #{locale}")
      end

      translation_path = "#{Rails.root}/config/locales/"

      Dir.glob("#{translation_path}**/*#{source_locale}.yml").each do |file|
        file_name = file.gsub(translation_path, "")
        puts(("=" * 30).to_s.colorize(:blue))
        puts("Translating file : #{file_name}".colorize(:blue))
        locales.each do |locale|
          ImmosquareTranslate::YmlTranslator.translate(file, locale, :reset_translations => reset_translations)
        end
      end
      puts("Translations done")
    rescue StandardError => e
      puts(e.message)
    end
  end
end
