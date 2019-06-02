defmodule KV.API do
  require Logger

  IO.puts "#{__MODULE__} is being evaluated (compiled)"
  use Plug.Router
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  #GenServer.call(KV.Registry, {:hello, key})

  post "/cache" do
    %{"key" => key, "value" => value} = conn.body_params
    Logger.info "API got #{key} -> #{value} request, calling the server"
    GenServer.call(KV.Registry, {:put, key, value})
    send_resp(conn, 200, "POST of #{key} > #{value} was a success!")
  end

  get "/cache/:key" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(message(key)))
  end

  defp message(key) do
    %{
      time: DateTime.utc_now(),
      msg: "Hello #{key}"
    }
  end

  match _ do
    send_resp(conn, 404, "Requested url not found!")
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(_opts) do
    IO.puts "#{__MODULE__}.start_link/1 executing"
    Plug.Cowboy.http(__MODULE__, [])
  end

  IO.puts "#{__MODULE__} done evaluating"
end
