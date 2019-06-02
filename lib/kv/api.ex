defmodule LRUCache.API do
  IO.puts "#{__MODULE__} is being evaluated (on compilation)"
  use Plug.Router
  IO.puts "#{__MODULE__} used Plug"
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  @doc """

  """
  def put(key, value) do
    GenServer.call(CacheServer, {:put, key, value})
  end

  post "/cache" do
    IO.inspect conn
    %{"key" => key, "value" => value} = conn.body_params
    IO.puts "got #{key} => #{value}"
    send_resp(conn, 200, "POST success!")
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
    IO.puts "API's start_link executing"
    Plug.Cowboy.http(__MODULE__, [])
  end

  IO.puts "#{__MODULE__} done evaluating"
end
