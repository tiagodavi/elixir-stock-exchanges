defmodule Exchange.Server do
  @moduledoc """
  Handles everything related to an Exchange.
  """
  use GenServer

  alias Exchange.{Event, Output, Stash}

  @argument_error {:error, "Invalid Arguments"}
  @index_error {:error, "Index has not been found"}

  def start_link(state \\ nil) do
    state = state || Stash.get_state()
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:get_current_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:get_output, depth}, _from, state) do
    values =
      Stream.iterate(0, &(&1 + 1))
      |> Stream.map(fn i ->
        try do
          map = elem(state, i)

          case map do
            %{ask: nil, bid: nil} ->
              build_empty_output()

            %{ask: %Event{price: price, quantity: quantity}, bid: nil} ->
              Output.new(%{
                ask_price: price,
                ask_quantity: quantity,
                bid_price: 0,
                bid_quantity: 0
              })

            %{ask: nil, bid: %Event{price: price, quantity: quantity}} ->
              Output.new(%{
                ask_price: 0,
                ask_quantity: 0,
                bid_price: price,
                bid_quantity: quantity
              })

            _ ->
              Output.new(%{
                ask_price: map.ask.price,
                ask_quantity: map.ask.quantity,
                bid_price: map.bid.price,
                bid_quantity: map.bid.quantity
              })
          end
        rescue
          ArgumentError ->
            build_empty_output()
        end
      end)
      |> Enum.take(depth)

    {:reply, values, state}
  end

  @impl true
  def handle_call({:new, event}, _from, state) do
    key = event.price_level_index - 1

    result =
      Stream.iterate(0, &(&1 + 1))
      |> Enum.take(event.price_level_index)
      |> Enum.reduce(state, fn i, acc ->
        try do
          _ = elem(state, i)
          acc
        rescue
          ArgumentError ->
            Tuple.append(acc, %{ask: nil, bid: nil})
        end
      end)

    map = elem(result, key)

    state =
      cond do
        map[event.side] == nil ->
          map = Map.put(map, event.side, event)

          result
          |> Tuple.delete_at(key)
          |> Tuple.insert_at(key, map)

        true ->
          map = Map.put(%{ask: nil, bid: nil}, event.side, event)
          Tuple.insert_at(result, key, map)
      end

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:delete, event}, _from, state) do
    key = event.price_level_index - 1

    try do
      map = elem(state, key)

      state =
        cond do
          map == %{ask: nil, bid: nil} ->
            raise ArgumentError

          map[event.side] == nil ->
            state

          true ->
            map = Map.put(map, event.side, nil)

            state =
            state
            |> Tuple.delete_at(key)
            |> Tuple.insert_at(key, map)

            Stream.iterate(event.price_level_index, &(&1 + 1))
            |> Enum.take(tuple_size(state) - key)
            |> Enum.reduce(state, fn i, acc ->
                prev_idx = i - 1

                try do
                  current = elem(acc, i)
                  previous = elem(acc, prev_idx)

                  previous = Map.put(previous, event.side, current[event.side])
                  current = Map.put(current, event.side, nil)

                  acc
                  |> Tuple.delete_at(prev_idx)
                  |> Tuple.insert_at(prev_idx, previous)
                  |> Tuple.delete_at(i)
                  |> Tuple.insert_at(i, current)
                rescue
                  ArgumentError ->
                    acc
                end

            end)
        end

      {:reply, :ok, state}
    rescue
      ArgumentError ->
        {:reply, @index_error, state}
    end
  end

  @impl true
  def handle_call({:update, event}, _from, state) do
    key = event.price_level_index - 1

    try do
      map = elem(state, key)

      case map do
        %{ask: nil, bid: nil} ->
          {:reply, @index_error, state}

        _ ->
          map = Map.put(map, event.side, event)

          state =
            state
            |> Tuple.delete_at(key)
            |> Tuple.insert_at(key, map)

          {:reply, :ok, state}
      end
    rescue
      ArgumentError ->
        {:reply, @index_error, state}
    end
  end

  @impl true
  def terminate(_reason, state) do
    Stash.set_state(state)
  end

  @doc """
  Inserts an event into the Exchange Process.
  """
  @spec execute(pid(), Event.t()) :: :ok | {:error, any()}
  def execute(pid, %Event{instruction: :new} = event)
      when is_pid(pid) do
    GenServer.call(pid, {:new, event})
  end

  @doc """
  Removes an event from the Exchange Process.
  """
  @spec execute(pid(), Event.t()) :: :ok | {:error, any()}
  def execute(pid, %Event{instruction: :delete} = event)
      when is_pid(pid) do
    GenServer.call(pid, {:delete, event})
  end

  @doc """
  Updates an event into the Exchange Process.
  """
  @spec execute(pid(), Event.t()) :: :ok | {:error, any()}
  def execute(pid, %Event{instruction: :update} = event)
      when is_pid(pid) do
    GenServer.call(pid, {:update, event})
  end

  @doc """
  Returns error for any other case.
  """
  def execute(_pid, _event), do: @argument_error

  @doc """
  Gets Exchange's current state.
  """
  @spec get_current_state(pid()) :: tuple() | {:error, any()}
  def get_current_state(pid)
      when is_pid(pid) do
    GenServer.call(pid, :get_current_state)
  end

  @doc """
  Returns error for any other case.
  """
  def get_current_state(_pid), do: @argument_error

  @doc """
  Gets Exchange's output.
  """
  @spec get_output(pid(), integer()) :: list(Output.t()) | {:error, any()}
  def get_output(pid, depth)
      when is_pid(pid) and is_integer(depth) and depth > 0 do
    GenServer.call(pid, {:get_output, depth})
  end

  @doc """
  Returns error for any other case.
  """
  def get_output(_pid, _depth), do: @argument_error

  defp build_empty_output do
    Output.new(%{
      ask_price: 0,
      ask_quantity: 0,
      bid_price: 0,
      bid_quantity: 0
    })
  end
end
