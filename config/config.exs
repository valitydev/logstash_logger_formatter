use Mix.Config

config :logger,
       :logstash_formatter,
       extra_fields: %{application: :logstash_formatter},
       max_metadata_size: 500,
       max_metadata_item_size: 200,
       level_field: "@severity"

if Mix.env() == :test do
  import_config "test.exs"
end
