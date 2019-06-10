defmodule KV.API.Test do
  use ExUnit.Case, async: true
  use Plug.Test
  require Logger

  @opts KV.API.init([])

  test "get to /size returns size of 0 (in JSON format)" do
    # Create a test connection
    conn = conn(:get, "/size")

    # Invoke the plug
    conn = KV.API.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    #assert conn.resp_body == "{\"size\":0}"
    assert {:ok, conn.resp_body} == Poison.encode %{"size" => 0}
  end

  test "adding works as expected" do
    conn = conn(:get, "/size")

    # Invoke the plug
    conn = KV.API.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    #assert conn.resp_body == "{\"size\":0}"
    assert {:ok, conn.resp_body} == Poison.encode %{"size" => 0}

    conn = conn(:post, "/cache", %{name: "B1", key: "K1", value: "V1" })

    # Invoke the plug
    conn = KV.API.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200

    conn = conn(:get, "/size")

    # Invoke the plug
    conn = KV.API.call(conn, @opts)
    Logger.warn inspect(conn)
    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert {:ok, conn.resp_body} == Poison.encode %{"size" => 1}
  end

end
