module ImmosquareTranslate
  module SharedMethods
    NOTHING      = "".freeze
    SPACE        = " ".freeze
    SIMPLE_QUOTE = "'".freeze
    DOUBLE_QUOTE = '"'.freeze

    ##============================================================##
    ## https://platform.openai.com/docs/pricing
    ## List updated on : 21/05/2025
    ##============================================================##
    OPEN_AI_MODELS = [
      {:nickname => "gpt-3.5",      :name => "gpt-3.5-turbo-0125",     :default => false, :window_tokens => 16_385,    :output_tokens => 4_096,  :input_price_for_1m => 0.50,   :output_price_for_1m => 1.50,  :group_size => 75},
      {:nickname => "gpt-4",        :name => "gpt-4-turbo-2024-04-09", :default => false, :window_tokens => 128_000,   :output_tokens => 4_096,  :input_price_for_1m => 10.00,  :output_price_for_1m => 30.00, :group_size => 200},
      {:nickname => "gpt-4o-mini",  :name => "gpt-4o-mini",            :default => false, :window_tokens => 128_000,   :output_tokens => 16_384, :input_price_for_1m => 0.15,   :output_price_for_1m => 0.60,  :group_size => 200},
      {:nickname => "gpt-4o",       :name => "gpt-4o-2024-08-06",      :default => false, :window_tokens => 128_000,   :output_tokens => 16_384, :input_price_for_1m => 2.50,   :output_price_for_1m => 10.00, :group_size => 200},
      {:nickname => "gpt-4.1-nano", :name => "gpt-4.1-nano",           :default => false, :window_tokens => 1_000_000, :output_tokens => 32_768, :input_price_for_1m => 0.10,   :output_price_for_1m => 0.40,  :group_size => 500},
      {:nickname => "gpt-4.1-mini", :name => "gpt-4.1-mini",           :default => false, :window_tokens => 1_000_000, :output_tokens => 32_768, :input_price_for_1m => 0.40,   :output_price_for_1m => 1.60,  :group_size => 500},
      {:nickname => "gpt-4.1",      :name => "gpt-4.1-2025-04-14",     :default => true,  :window_tokens => 1_000_000, :output_tokens => 32_768, :input_price_for_1m => 2.00,   :output_price_for_1m => 8.00,  :group_size => 500}
    ].freeze
  end
end
