defmodule Exchange.Stash do
  @moduledoc """
  Useful cache to store server state in case of a crash.
  """
  use Agent

  @initial_state {}

  @doc """
    Starts a new Exchange Process.
  """
  @spec start_link(any()) :: {:ok, pid()} | {:error, any()}
  def start_link(_) do
    Agent.start_link(fn -> @initial_state end, name: __MODULE__)
  end

  @doc """
    Gets cache's state
  """
  @spec get_state() :: any()
  def get_state do
    Agent.get(__MODULE__, & &1)
  end

  @doc """
    Updates cache's state.
  """
  @spec set_state(any()) :: any()
  def set_state(state) do
    Agent.update(__MODULE__, fn _current_state -> state end)
  end
end