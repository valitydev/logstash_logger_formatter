defmodule LogstashLoggerFormatter.MetadataProcessor do
  @callback process_message(
              level :: Logger.level(),
              message :: Logger.message(),
              timestamp :: Logger.Formatter.time(),
              metadata :: Map.t()
            ) :: {:ok, metadata :: Map.t()}
end
