module ImmosquareTranslate
  class Railtie < Rails::Railtie

    rake_tasks do
      load "tasks/immosquare-translate.rake"
    end

  end
end
