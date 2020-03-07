defmodule Exchange do
  @moduledoc """
  Public interface to access the main program.
  """

  alias Exchange.{Event, Server}

  @argument_error {:error, "Invalid Arguments"}

  @doc """
    Starts a new Exchange Process.
  """
  @spec start_link() :: {:ok, pid()} | {:error, any()}
  def start_link do
    Server.start_link()
  end

  @doc """
  Sends an instruction to the Exchange Process.

  Example of a valid Event:

  %{
    instruction: :new | :update | :delete,
    side: :bid | :ask,
    price_level_index: integer()
    price: float()
    quantity: integer()
  }
  """
  @spec send_instruction(pid(), map()) :: :ok | {:error, any()}
  def send_instruction(pid, event)
      when is_pid(pid) and is_map(event) do
    changeset =
      Event.changeset(
        %Event{},
        Map.put(event, :datetime, NaiveDateTime.utc_now())
      )

    if changeset.valid? do
      Server.execute(pid, Event.new(changeset.changes))
    else
      {:error, Event.format_validation_errors(changeset)}
    end
  end

  @doc """
  Returns error for any other case.
  """
  def send_instruction(_pid, _event), do: @argument_error

  @doc """
  Gets list of orders from the Exchange Process.
  """
  @spec order_book(pid(), integer()) :: list(map()) | {:error, any()}
  def order_book(pid, depth)
      when is_pid(pid) and is_integer(depth) do
    Server.get_output(pid, depth)
  end

  @doc """
  Returns error for any other case.
  """
  def order_book(_pid, _depth), do: @argument_error
end
