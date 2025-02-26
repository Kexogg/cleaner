import Config

config :cleaner, CleanerBot.Dispatcher, telegram_token: System.get_env("TELEGRAM_TOKEN")

if config_env() == :prod do
  config :cleaner, Cleaner.Repo,
    url: System.get_env("DATABASE_URL", "ecto://postgres:postgres@database/cleaner_prod"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :cleaner, Cleaner.AI.OpenAIClient,
    api_url: System.get_env("OPENAI_URL", "https://api.openai.com/v1"),
    api_key: System.fetch_env!("OPENAI_KEY"),
    model: System.get_env("MODEL", "gpt-4o-mini")
end
