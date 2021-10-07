defmodule Sphynx.Router do
  @moduledoc ~S"""
  Router for `sphynx` application
  """
  alias Plug.Conn
  use Plug.Router

  plug Plug.Parsers,
       parsers: [:json],
       pass: ["application/json", "text/json"],
       json_decoder: Jason
  plug :match
  plug :dispatch

  @spec json(Conn.t, Integer.t, Map.t) :: Conn.t
  def json(%Conn{} = conn, status, data) when is_integer(status) do
    data = if is_map(data), do: Jason.encode!(data), else: data
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, data)
  end

  post "/" do
    json(conn, 200, %{result: true})
  end

  match _, do: json(conn, 404, %{result: false, data: %{message: "page not found"}})
end
