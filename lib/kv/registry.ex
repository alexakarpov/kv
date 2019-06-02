defmodule KV.Registry do
  use GenServer
  require Logger
  ## Client API

  @doc """
  Starts the registry.

  A registry requires a name
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:no_such_bucket` otherwise.
  """
  def lookup(server, name) do
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> {:error, :no_such_bucket}
    end
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  @doc """
  Stops the registry.
  """
  def stop(server) do
    GenServer.stop(server)
  end

  def count(server) do
    case GenServer.call(server, :count) do
      {:ok, n} -> n
      x ->
        IO.puts x
        :error
    end
  end

  ## Server Callbacks

  def init(table) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  def handle_call({:lookup, name}, _from, {names, _} = state) do
    {:reply, Map.fetch(names, name), state}
  end

  def handle_call({:put, name, key, value}, from, {names, _} = state) do
    Logger.info "#{__MODULE__} (GenServer) got a K/V put from #{inspect from} for bucket #{name}, key #{key} and value #{value}"
    case KV.Registry.lookup(names, name) do
      {:ok, bucket} -> {:reply, "got something" , state}
      x ->
        Logger.error "what? #{inspect x}"
        create(KV.Registry, name)
    end
  end

  def handle_call(:count, _from, {names, refs}) do
    {:ok, count} = Keyword.fetch(:ets.info(names),
      :size)
    {:reply, {:ok , count}, {names, refs}}
  end

  def handle_call({:create, name}, _from, state = {names, refs}) do
    case lookup(names, name) do
      {:ok, pid} ->
        {:reply, pid, {names, refs}}
      {:error, :no_such_bucket} -> execute_creation(name, names, refs)    end
  end

  def execute_creation(name, names, refs) do
    {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
    ref = Process.monitor(pid)
    refs = Map.put(refs, ref, name)
    :ets.insert(names, {name, pid})
    {:reply, pid, {names, refs}}
  end

  def handle_cast({:create, name}, {names, refs}) do
    # 5. Read and write to the ETS table instead of the map
    case lookup(names, name) do
      {:ok, _pid} ->
        {:noreply, {names, refs}}
      {:error, :no_such_bucket} ->
        {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:noreply, {names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
     {:noreply, state}
  end
end
