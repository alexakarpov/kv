defmodule KV.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {KV.Registry,
       name: Cache},
      {DynamicSupervisor,
       name: KV.BucketSupervisor,
       strategy: :one_for_one},
      {KV.API,
       name: KV.API,
      strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
