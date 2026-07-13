module OpenaiConfig
  MODEL = ENV.fetch("OPENAI_MODEL", "gpt-4.1-nano").freeze
end
