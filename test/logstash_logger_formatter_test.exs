defmodule LogstashLoggerFormatterTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  require Logger

  setup do
    Logger.configure_backend(
      :console,
      format: {LogstashLoggerFormatter, :format},
      colors: [enabled: false],
      metadata: [:application, :extra_pid, :extra_map, :extra_tuple, :extra_ref, :datetime]
    )
  end

  test "logs message in JSON format" do
    ref = make_ref()
    pid = self()

    message =
      capture_log(fn ->
        Logger.warn(
          "Test message",
          application: :otp_app,
          extra_pid: pid,
          extra_map: %{key: "value"},
          extra_tuple: {"el1", "el2"},
          extra_ref: ref
        )
      end)

    decoded_message = Poison.decode!(message)

    assert decoded_message["message"] == "Test message"
    assert decoded_message["application"] == "logstash_formatter"
    assert decoded_message["otp_application"] == "otp_app"
    assert decoded_message["@timestamp"] =~ ~r[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}\+00:00]
    assert decoded_message["level"] == "warn"
    assert decoded_message["extra_pid"] == inspect(pid)
    assert decoded_message["extra_ref"] == inspect(ref)
    assert decoded_message["extra_map"] == %{"key" => "value"}
    assert decoded_message["extra_tuple"] == ["el1", "el2"]
  end

  test "logs DateTime as a string" do
    datetime = DateTime.utc_now()

    message =
      capture_log(fn ->
        Logger.warn("Test message", datetime: datetime)
      end)

    decoded_message = Poison.decode!(message)

    assert decoded_message["datetime"] == DateTime.to_iso8601(datetime)
  end
end
