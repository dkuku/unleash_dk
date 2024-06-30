defmodule Unleash.ClientTest do
  use ExUnit.Case

  alias Unleash.Client

  setup do
    default_config = Application.get_env(:unleash_dk, Unleash, [])

    test_config =
      Keyword.merge(default_config,
        appname: "myapp",
        instance_id: "node@a"
      )

    Application.put_env(:unleash_dk, Unleash, test_config)

    on_exit(fn -> Application.put_env(:unleash_dk, Unleash, default_config) end)

    :ok
  end

  describe "features/1" do
    test "publishes start event" do
      attach_telemetry_event([:unleash, :client, :fetch_features, :start])

      Req.Test.stub(Unleash.Client, fn conn ->
        conn
        |> Map.update!(:resp_headers, fn headers -> [{"etag", "x"}] ++ headers end)
        |> Req.Test.json(%{"version" => "1", "features" => []})
      end)

      assert {"x", %Unleash.Features{}} = Client.features()
      assert_received {:telemetry_metadata, metadata}
      assert_received {:telemetry_measurements, measurements}

      assert metadata[:appname] == "myapp"
      assert metadata[:instance_id] == "node@a"
      assert metadata[:etag] == nil
      assert metadata[:url] =~ "client/features"

      assert is_number(measurements[:system_time])
      assert is_number(measurements[:monotonic_time])
    end

    test "publishes stop event" do
      Req.Test.stub(Unleash.Client, fn conn ->
        conn
        |> Map.update!(:resp_headers, fn headers -> [{"etag", "x"}] ++ headers end)
        |> Req.Test.json(%{"version" => "1", "features" => []})
      end)

      attach_telemetry_event([:unleash, :client, :fetch_features, :stop])

      assert {"x", %Unleash.Features{}} = Client.features()

      assert_received {:telemetry_metadata, metadata}
      assert_received {:telemetry_measurements, measurements}

      assert metadata[:appname] == "myapp"
      assert metadata[:instance_id] == "node@a"
      assert metadata[:etag] == "x"
      assert metadata[:url] =~ "client/features"
      assert metadata[:http_response_status] == 200

      assert is_number(measurements[:duration])
      assert is_number(measurements[:monotonic_time])
    end

    test "publishes stop event with an error" do
      Req.Test.stub(Unleash.Client, fn conn ->
        Req.Test.transport_error(conn, :econnrefused)
      end)

      attach_telemetry_event([:unleash, :client, :fetch_features, :stop])

      assert {nil, :econnrefused} = Client.features()
      assert_received {:telemetry_metadata, metadata}
      assert :econnrefused == metadata[:error]
    end

    test "publishes exception event" do
      Req.Test.stub(Unleash.Client, fn _conn ->
        raise "Unexpected error"
      end)

      attach_telemetry_event([:unleash, :client, :fetch_features, :exception])

      assert_raise RuntimeError, fn -> Client.features() end

      assert_received {:telemetry_metadata, metadata}
      assert_received {:telemetry_measurements, measurements}

      assert metadata[:appname] == "myapp"
      assert metadata[:instance_id] == "node@a"
      assert metadata[:etag] == nil
      assert metadata[:url] =~ "client/features"

      assert metadata[:kind] == :error
      assert is_list(metadata[:stacktrace])
      assert %RuntimeError{} = metadata[:reason]

      assert is_number(measurements[:duration])
      assert is_number(measurements[:monotonic_time])
    end
  end

  describe "register_client/0" do
    test "publishes start event" do
      Req.Test.stub(Unleash.Client, fn conn ->
        Req.Test.json(conn, %{})
      end)

      attach_telemetry_event([:unleash, :client, :register, :start])

      assert {:ok, %Req.Response{}} = Client.register_client()

      assert_received {:telemetry_metadata, metadata}
      assert_received {:telemetry_measurements, measurements}

      assert metadata[:appname] == "myapp"
      assert metadata[:instance_id] == "node@a"

      assert metadata[:url] =~ "client/register"

      assert metadata[:sdk_version] =~ "unleash_ex:"
      assert is_list(metadata[:strategies])
      assert metadata[:interval] == 600_000

      assert is_number(measurements[:system_time])
      assert is_number(measurements[:monotonic_time])
    end

    test "publishes stop event with measurements" do
      Req.Test.stub(Unleash.Client, fn conn ->
        Req.Test.json(conn, %{})
      end)

      attach_telemetry_event([:unleash, :client, :register, :stop])

      assert {:ok, %Req.Response{}} = Client.register_client()

      assert_received {:telemetry_metadata, metadata}
      assert_received {:telemetry_measurements, measurements}

      assert metadata[:appname] == "myapp"
      assert metadata[:instance_id] == "node@a"

      assert metadata[:url] =~ "client/register"
      assert metadata[:http_response_status] == 200

      assert metadata[:sdk_version] =~ "unleash_ex:"
      assert is_list(metadata[:strategies])
      assert metadata[:interval] == 600_000

      assert is_number(measurements[:duration])
      assert is_number(measurements[:monotonic_time])
    end

    test "publishes stop with an error event" do
      Req.Test.stub(Unleash.Client, fn conn ->
        Req.Test.transport_error(conn, :econnrefused)
      end)

      attach_telemetry_event([:unleash, :client, :register, :stop])

      assert {:error, :econnrefused} = Client.register_client()

      assert_received {:telemetry_metadata, metadata}

      assert :econnrefused = metadata[:error]
    end

    test "publishes exception event with measurements" do
      Req.Test.stub(Unleash.Client, fn _conn ->
        raise "Unexpected error"
      end)

      attach_telemetry_event([:unleash, :client, :register, :exception])

      assert_raise RuntimeError, fn -> Client.register_client() end

      assert_received {:telemetry_metadata, metadata}
      assert_received {:telemetry_measurements, measurements}

      assert metadata[:appname] == "myapp"
      assert metadata[:instance_id] == "node@a"

      assert metadata[:url] =~ "client/register"

      assert metadata[:sdk_version] =~ "unleash_ex:"
      assert is_list(metadata[:strategies])
      assert metadata[:interval] == 600_000

      assert is_number(measurements[:duration])
      assert is_number(measurements[:monotonic_time])

      assert metadata[:kind] == :error
      assert is_list(metadata[:stacktrace])
      assert %RuntimeError{} = metadata[:reason]
    end
  end

  describe "metrics/1" do
    test "publishes start event" do
      Req.Test.stub(Unleash.Client, fn conn ->
        Req.Test.json(conn, %{})
      end)

      attach_telemetry_event([:unleash, :client, :push_metrics, :start])

      payload = %{
        bucket: %{
          start: "2023-01-19T15:00:15.269493Z",
          stop: "2023-01-19T15:00:25.270545Z",
          toggles: %{
            "example_toggle" => %{yes: 5, no: 0},
            "example_toggle_2" => %{yes: 55, no: 4}
          }
        }
      }

      assert {:ok, %Req.Response{}} = Client.metrics(payload)

      assert_received {:telemetry_metadata, metadata}
      assert_received {:telemetry_measurements, measurements}

      assert metadata[:appname] == "myapp"
      assert metadata[:instance_id] == "node@a"

      assert metadata[:url] =~ "client/metrics"
      assert metadata[:metrics_payload] == payload

      assert is_number(measurements[:system_time])
      assert is_number(measurements[:monotonic_time])
    end

    test "publishes stop event with measurements" do
      Req.Test.stub(Unleash.Client, fn conn ->
        Req.Test.json(conn, %{})
      end)

      attach_telemetry_event([:unleash, :client, :push_metrics, :stop])

      assert {:ok, %Req.Response{}} = Client.metrics(%{})

      assert_received {:telemetry_metadata, metadata}
      assert_received {:telemetry_measurements, measurements}

      assert metadata[:appname] == "myapp"
      assert metadata[:instance_id] == "node@a"

      assert metadata[:url] =~ "client/metrics"
      assert metadata[:http_response_status] == 200

      assert is_number(measurements[:duration])
      assert is_number(measurements[:monotonic_time])
    end

    test "publishes stop with an error event" do
      Req.Test.stub(Unleash.Client, fn conn ->
        Req.Test.transport_error(conn, :econnrefused)
      end)

      attach_telemetry_event([:unleash, :client, :register, :stop])

      assert {:error, :econnrefused} = Client.register_client()
      assert_received {:telemetry_metadata, metadata}

      assert :econnrefused = metadata[:error]
    end

    test "publishes exception event with measurements" do
      Req.Test.stub(Unleash.Client, fn conn ->
        raise "Unexpected error"
        Req.Test.json(conn, %{})
      end)

      attach_telemetry_event([:unleash, :client, :push_metrics, :exception])

      assert_raise RuntimeError, fn -> Client.metrics(%{}) end

      assert_received {:telemetry_metadata, metadata}
      assert_received {:telemetry_measurements, measurements}

      assert metadata[:appname] == "myapp"
      assert metadata[:instance_id] == "node@a"

      assert metadata[:url] =~ "client/metrics"

      assert is_number(measurements[:duration])
      assert is_number(measurements[:monotonic_time])

      assert metadata[:kind] == :error
      assert is_list(metadata[:stacktrace])
      assert %RuntimeError{} = metadata[:reason]
    end
  end

  defp attach_telemetry_event(event) do
    test_pid = self()

    :telemetry.attach(
      make_ref(),
      event,
      fn
        ^event, measurements, metadata, _config ->
          send(test_pid, {:telemetry_measurements, measurements})
          send(test_pid, {:telemetry_metadata, metadata})
      end,
      []
    )
  end
end
