defmodule LogstashLoggerFormatterTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  require Logger

  setup do
    Logger.configure_backend(
      :console,
      format: {LogstashLoggerFormatter, :format},
      colors: [enabled: false],
      metadata: :all
    )
  end

  test "logs message in JSON format", %{test: test_name} do
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

    decoded_message = Jason.decode!(message)

    assert decoded_message["message"] == "Test message"
    assert decoded_message["application"] == "logstash_formatter"
    assert decoded_message["otp_application"] == "otp_app"
    assert decoded_message["@timestamp"] =~ ~r[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}\+00:00]
    assert decoded_message["level"] == "warn"
    assert decoded_message["module"] == "Elixir.#{inspect(__MODULE__)}"
    assert decoded_message["function"] == "#{to_string(test_name)}/1"
    assert decoded_message["extra_pid"] == inspect(pid)
    assert decoded_message["extra_ref"] == inspect(ref)
    assert decoded_message["extra_map"] == %{"key" => "value"}
    assert decoded_message["extra_tuple"] == ["el1", "el2"]

    for {key, val} <- decoded_message, is_list(val) do
      # Logstash is unable to parse fields of varied types
      assert all_of_same_type?(val),
             "Metadata element #{key} contains values of varied types: #{inspect(val)}"
    end
  end

  test "logs DateTime as a string" do
    datetime = DateTime.utc_now()

    message =
      capture_log(fn ->
        Logger.warn("Test message", datetime: datetime)
      end)

    decoded_message = Jason.decode!(message)

    assert decoded_message["datetime"] == DateTime.to_iso8601(datetime)
  end

  test "uses encoder protocol whenever possible" do
    datetime = DateTime.utc_now()
    struct = %CustomStruct{value: datetime}

    message =
      capture_log(fn ->
        Logger.warn("Test message", datetime: struct)
      end)

    decoded_message = Jason.decode!(message)

    assert decoded_message["datetime"] == DateTime.to_iso8601(datetime)
  end

  test "logs function as a string" do
    function = &:application_controller.format_log/1

    message =
      capture_log(fn ->
        Logger.warn("Test message", foo: function)
      end)

    decoded_message = Jason.decode!(message)
    assert decoded_message["foo"] == "&:application_controller.format_log/1"
  end

  test "logs unhandled structs" do
    message =
      capture_log(fn ->
        error = %KeyError{
          key: :on_terminate,
          message: nil,
          term: [
            [on_terminate: &:application_controller.format_log/1]
          ]
        }

        Logger.error("Oh no", error: error)
      end)

    decoded_message = Jason.decode!(message)

    assert decoded_message["error"] == %{
             "__struct__" => "Elixir.KeyError",
             "__exception__" => true,
             "key" => "on_terminate",
             "message" => nil,
             "term" => [[["on_terminate", "&:application_controller.format_log/1"]]]
           }
  end

  test "truncates metadata" do
    message = capture_log(fn ->
      Logger.warn(
        "Test message",
        long_list: [
          "some long string in it 1",
          "some long string in it 2",
          "some long string in it 3",
          "some long string in it 4",
          "some long string in it 5",
          "some long string in it 6",
          "some long string in it 7",
          "some long string in it 8",
          "some long string in it 9",
          "some long string in it 10",
          "some long string in it 11",
          "some long string in it 12",
          "some long string in it 13",
          "some long string in it 14",
          "some long string in it 15",
          "some long string in it 16",
          "some long string in it 17",
          "some long string in it 18",
          "some long string in it 19",
          "some long string in it 20"
        ],
        long_list_with_maps: [
          %{thing: "some long string in it 1"},
          %{thing: "some long string in it 2"},
          %{thing: "some long string in it 3"},
          %{thing: "some long string in it 4"},
          %{thing: "some long string in it 5"},
          %{thing: "some long string in it 6"},
          %{thing: "some long string in it 7"},
          %{thing: "some long string in it 8"},
          %{thing: "some long string in it 9"},
          %{thing: "some long string in it 10"},
          %{thing: "some long string in it 11"},
          %{thing: "some long string in it 12"},
          %{thing: "some long string in it 13"},
          %{thing: "some long string in it 14"},
          %{thing: "some long string in it 15"},
          %{thing: "some long string in it 16"},
          %{thing: "some long string in it 17"},
          %{thing: "some long string in it 18"},
          %{thing: "some long string in it 19"},
          %{thing: "some long string in it 20"}
        ],
        short_list_with_very_long_string: [
          "Nam elementum iaculis nisi, vitae lacinia erat lacinia id. Proin in dignissim justo. Sed vel luctus " <>
          "felis. Vestibulum pulvinar tempor commodo. Aenean imperdiet eget nibh vitae scelerisque. Praesent sed " <>
          "viverra dolor, nec consectetur enim. Curabitur tincidunt posuere ante ac maximus. Vestibulum sit amet " <>
          "dui sagittis, tempus odio eu, consequat neque. Etiam urna libero, vestibulum nec turpis sit amet, " <>
          "condimentum venenatis leo. Donec quis ullamcorper mauris. Nunc eget felis velit. Cras molestie est non " <>
          "justo luctus, et cursus sem gravida. Sed pretium urna id ligula malesuada, venenatis vehicula massa " <>
          "dapibus. Nullam gravida nisl mauris, eu ultricies nisi condimentum pulvinar. Ut ac vestibulum turpis."
        ],
        big_map: %{
          a: "some long string in it 1",
          b: "some long string in it 2",
          c: "some long string in it 3",
          d: "some long string in it 4",
          e: "some long string in it 5",
          f: "some long string in it 6",
          g: "some long string in it 7",
          h: "some long string in it 8",
          i: "some long string in it 9",
          j: "some long string in it 10",
          k: "some long string in it 11",
          l: "some long string in it 12",
          m: "some long string in it 13",
          n: "some long string in it 14",
          o: "some long string in it 15",
          p: "some long string in it 16",
          q: "some long string in it 17",
          r: "some long string in it 18",
          s: "some long string in it 19",
          t: "some long string in it 20"
        },
        small_map: %{
          u: "Nam elementum iaculis nisi, vitae lacinia erat lacinia id. Proin in dignissim justo. Sed vel luctus " <>
          "felis. Vestibulum pulvinar tempor commodo. Aenean imperdiet eget nibh vitae scelerisque. Praesent sed " <>
          "viverra dolor, nec consectetur enim. Curabitur tincidunt posuere ante ac maximus. Vestibulum sit amet " <>
          "dui sagittis, tempus odio eu, consequat neque. Etiam urna libero, vestibulum nec turpis sit amet, " <>
          "condimentum venenatis leo. Donec quis ullamcorper mauris. Nunc eget felis velit. Cras molestie est non " <>
          "justo luctus, et cursus sem gravida. Sed pretium urna id ligula malesuada, venenatis vehicula massa " <>
          "dapibus. Nullam gravida nisl mauris, eu ultricies nisi condimentum pulvinar. Ut ac vestibulum turpis."
        },
        nested_map: %{
          v: "some long string in it",
          w: "Nam elementum iaculis nisi, vitae lacinia erat lacinia id. Proin in dignissim justo.",
          hash: %{
            list: [
              "some long string in it 1",
              "some long string in it 2"
            ],
            something: %{
              a: "some long string in it 1",
              b: "some long string in it 2"
            }
          }
        },
        number: 1,
        atom: :atom,
        long_string:
          "Nam elementum iaculis nisi, vitae lacinia erat lacinia id. Proin in dignissim justo. Sed vel luctus " <>
          "felis. Vestibulum pulvinar tempor commodo. Aenean imperdiet eget nibh vitae scelerisque. Praesent sed " <>
          "viverra dolor, nec consectetur enim. Curabitur tincidunt posuere ante ac maximus. Vestibulum sit amet " <>
          "dui sagittis, tempus odio eu, consequat neque. Etiam urna libero, vestibulum nec turpis sit amet, " <>
          "condimentum venenatis leo. Donec quis ullamcorper mauris. Nunc eget felis velit. Cras molestie est non " <>
          "justo luctus, et cursus sem gravida. Sed pretium urna id ligula malesuada, venenatis vehicula massa " <>
          "dapibus. Nullam gravida nisl mauris, eu ultricies nisi condimentum pulvinar. Ut ac vestibulum turpis."
      )
    end)

    decoded_message = Jason.decode!(message)

    assert decoded_message["long_list"] == [
      "some long string in it 1",
      "some long string in it 2",
      "some long string in it 3",
      "some long string in it 4",
      "some long string in it 5",
      "some long string in it 6",
      "-pruned-"
    ]
    assert decoded_message["long_list_with_maps"] == [
      %{"thing" => "some long string in it 1"},
      %{"thing" => "some long string in it 2"},
      %{"thing" => "some long string in it 3"},
      %{"thing" => "some long string in it 4"},
      %{"-pruned-" => true}
    ]
    assert decoded_message["short_list_with_very_long_string"] == [
      "\"Nam elementum iaculis nisi, vitae lacinia erat lacinia id. Proin in dignissim justo. Sed vel luctus felis. " <>
      "Vestibulum pulvinar tempor commodo. Aenean imperdiet eget nibh vitae scelerisque. Praesent s (-pruned-)"
    ]
    assert decoded_message["big_map"] == %{
      "a" => "some long string in it 1",
      "b" => "some long string in it 2",
      "c" => "some long string in it 3",
      "d" => "some long string in it 4",
      "e" => "some long string in it 5",
      "-pruned-" => true
    }
    assert decoded_message["small_map"] == %{
      "u" => "\"Nam elementum iaculis nisi, vitae lacinia erat lacinia id. Proin in dignissim justo. Sed vel luctus " <>
        "felis. Vestibulum pulvinar tempor commodo. Aenean imperdiet eget nibh vitae scelerisque. Praesent s (-pruned-)"
    }
    assert decoded_message["nested_map"] == %{
      "hash" => %{
        "list" => [
          "some long string in it 1",
          "some long string in it 2"
        ],
        "something" => %{
          "a" => "some long string in it 1",
          "b" => "some long string in it 2"
        }
      },
      "v" => "some long string in it",
      "-pruned-" => true
    }
    assert decoded_message["number"] == 1
    assert decoded_message["atom"] == "atom"
    assert decoded_message["long_string"] == "\"Nam elementum iaculis nisi, vitae lacinia erat lacinia id. Proin in " <>
      "dignissim justo. Sed vel luctus felis. Vestibulum pulvinar tempor commodo. Aenean imperdiet eget nibh vitae " <>
      "scelerisque. Praesent s (-pruned-)"
  end

  defp all_of_same_type?(list) when is_list(list) do
    list |> Enum.map(&BasicTypes.typeof(&1)) |> Enum.uniq() |> Enum.count() == 1
  end
end
