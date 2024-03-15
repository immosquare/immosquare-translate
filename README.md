# ImmosquareTranslate

ImmosquareTranslate is a versatile Ruby gem that leverages artificial intelligence to provide comprehensive translation capabilities across a variety of content types. From YAML files to arrays and web pages, it equips developers with the tools needed to easily make their applications multilingual.

## Key Features

- **Versatile Translations**: Supports translating multiple content types, enabling broader application internationalization.

- **AI Integration**: Offers integration with various AI services, allowing you to choose the best AI for your translation needs.

- **Easy Configuration**: Simplifies setup with customizable options for seamless integration into Ruby applications.

- **Dynamic Content Management**: Enables efficient translation updates and management for maintaining up-to-date multilingual content.

Stay tuned for more details on how to configure, install, and utilize ImmosquareTranslate to make your Ruby applications truly global.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'immosquare-translate'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install immosquare-translate
```

---

## Configuration

Set up your OpenAI API key and specify the OpenAI model in a Rails initializer.

```ruby
# config/initializers/immosquare-translate.rb

# =======================================
# Available models:
# https://platform.openai.com/docs/models/
# gpt-3.5-turbo-0125
# gpt-4-0125-preview
# =======================================
ImmosquareTranslate.config do |config|
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", nil)
  config.openai_model   = "gpt-4-0125-preview"
end
```

---

## Usage

### Translate YAML Files

Translate your YAML files into the desired language with ease. Specify the file path and the target language code:

```ruby
ImmosquareTranslate::YmlTranslator.translate("path/to/your/file.yml", "fr")
```

To reset translations in the target file before translating:

```ruby
ImmosquareTranslate::YmlTranslator.translate("path/to/your/file.yml", "fr", reset_translations: true)
```

---

## Rake Tasks

Simplify YML file management with provided rake tasks:

1. **Translation**: Translates all translation files within your Rails application. By default, `SOURCE_LOCALE` is French (fr), and `RESET_TRANSLATIONS` is false.

```bash
rake immosquare_translate:translate
```

```bash
rake immosquare_translate:translate SOURCE_LOCALE=en RESET_TRANSLATIONS=true
```

---

## Contributing

Contributions are welcome! Open an issue or submit a pull request on our [GitHub repository](https://github.com/IMMOSQUARE/immosquare-translate).

## License

This gem is available under the terms of the [MIT License](https://opensource.org/licenses/MIT).
