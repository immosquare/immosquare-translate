require_relative "lib/immosquare-translate/version"

Gem::Specification.new do |spec|
  spec.license       = "MIT"
  spec.name          = "immosquare-translate"
  spec.version       = ImmosquareTranslate::VERSION.dup
  spec.authors       = ["immosquare"]
  spec.email         = ["jules@immosquare.com"]

  spec.summary       = "AI-powered translations for Ruby applications, supporting a wide range of formats."
  spec.description   = "ImmosquareTranslate brings the power of OpenAI to Ruby applications, offering the ability to translate not just YAML files, but also arrays, web pages, and other data structures. Tailored for developers in multilingual settings, it streamlines the translation workflow, ensuring accurate, context-aware translations across different content types."

  spec.homepage      = "https://github.com/immosquare/immosquare-translate"

  spec.files         = Dir["lib/**/*"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Gem::Requirement.new(">= 3.1.6")

  spec.add_dependency("httparty",             "> 0", "<= 100")
  spec.add_dependency("immosquare-yaml",      "> 0", "<= 100")
  spec.add_dependency("immosquare-constants", "> 0", "<= 100")
  spec.add_dependency("iso-639",              "> 0", "<= 100")
  spec.add_dependency("countries",            "> 0", "<= 100")

end
