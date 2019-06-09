defmodule KV.API.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts KV.API.init([])

  test "get to /size returns size of 0 (in JSON format)" do
    # Create a test connection
    conn = conn(:get, "/size")

    # Invoke the plug
    conn = KV.API.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "{\"size\":0}"
  end
end
