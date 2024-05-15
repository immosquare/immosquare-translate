module ImmosquareTranslate
  module SharedMethods
    NOTHING      = "".freeze
    SPACE        = " ".freeze
    SIMPLE_QUOTE = "'".freeze
    DOUBLE_QUOTE = '"'.freeze


    OPEN_AI_MODELS     = [
      {:name => "gpt-3.5-turbo-0125", :window_tokens => 16_385,  :output_tokens => 4096, :input_price_for_1m => 0.50,   :output_price_for_1m => 1.50,  :group_size => 75},
      {:name => "gpt-4-turbo",        :window_tokens => 128_000, :output_tokens => 4096, :input_price_for_1m => 10.00,  :output_price_for_1m => 30.00, :group_size => 75}
      {:name => "gpt-4o",             :window_tokens => 128_000, :output_tokens => 4096, :input_price_for_1m => 5.00,   :output_price_for_1m => 15.00, :group_size => 75}
    ].freeze
  end
end
