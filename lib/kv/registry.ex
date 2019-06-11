defmodule KV.Registry do
  use GenServer
  require Logger
  ## Client API

  @doc """
  Starts the registry.

  A registry requires a name
  """
  @default %{}
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    Logger.info("Start_link in #{__MODULE__} with name #{server}")
    GenServer.start_link(__MODULE__, server, opts)
  end

  @defaults %{color: "black", shape: "circle"}
  def draw(options \\ [] ) do
    %{color: color, shape: shape} = Enum.into(options, @defaults)
    IO.puts("Draw a #{color} #{shape}")
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

  def handle_call({:put, name, key, value}, from, {names, refs} = state) do
    Logger.debug "#{__MODULE__} (GenServer) got a K/V put from #{inspect from} for bucket #{name}, key #{key} and value #{value}"
    case KV.Registry.lookup(names, name) do
      {:ok, bucket} -> {:reply, "got something" , state}
      {:error, :no_such_bucket } ->
        Logger.warn "new bucket needed"
        case execute_creation(name, names, refs) do
          {:reply, pid, {names, refs}} -> {:reply, pid, {names, refs}}
          y ->
            Logger.error "booms2 - #{inspect y}"
        end
      x ->
        Logger.error "booms - #{inspect x}"
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
      {:error, :no_such_bucket} -> execute_creation(name, names, refs)
    end
  end

  def execute_creation(name, names, refs) do
    Logger.debug "creating new bucket #{name}"
    {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
    ref = Process.monitor(pid)
    refs = Map.put(refs, ref, name)
    :ets.insert(names, {name, pid})
    Logger.info "returning {:reply #{inspect pid}, {#{inspect names}, #{inspect refs}}"
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
