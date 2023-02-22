defmodule FunnyMetadataProcessor do
  @behaviour LogstashLoggerFormatter.MetadataProcessor

  @impl true
  def process_message(_level, _message, _timestamp, metadata) do
    {:ok, Map.put(metadata, :joe, "hello, Mike")}
  end
end
