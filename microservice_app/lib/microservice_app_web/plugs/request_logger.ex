defmodule MicroserviceAppWeb.Plugs.RequestLogger do
  import Plug.Conn
  require Logger

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> log_request()
    |> log_response()
  end

  defp log_request(conn) do
    request_data = %{
      request: %{
        time: DateTime.utc_now() |> DateTime.to_iso8601(),
        uri: "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}",
        verb: conn.method,
        headers: conn.req_headers |> Enum.into(%{}),
        body: conn.body_params |> Jason.encode!()
      }
    }

    Logger.info("Request Data: #{Jason.encode!(request_data)}")
    conn
  end

  defp log_response(conn) do
    response_data = %{
      response: %{
        time: DateTime.utc_now() |> DateTime.to_iso8601(),
        status: conn.status,
        headers: conn.resp_headers |> Enum.into(%{}),
        body: conn.resp_body |> Jason.encode!()
      },
      transaction_id: UUID.uuid4(),
      direction: "Incoming",
    }

    response = post_to_remote("http://localhost:8080/echo", response_data)
    Logger.info("Response: #{inspect(response)}")

    conn
  end

  defp post_to_remote(url, data) do
    body = Jason.encode!(data)
    Logger.info("Response Data: #{body}")
    headers = [{"Content-Type", "application/json"}]

    HTTPoison.post(url, body, headers)
  end
end
