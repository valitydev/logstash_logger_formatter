import Mix.Config

config :logger, :logstash_formatter,
  metadata_processors: [{FunnyMetadataProcessor, :process_message}]
