defmodule Exchange.Output do
  @moduledoc """
  Special structure to represent an Exchange Output.
  """

  use Ecto.Schema

  @type t :: __MODULE__

  embedded_schema do
    field(:ask_price, :decimal)
    field(:ask_quantity, :integer)
    field(:bid_price, :decimal)
    field(:bid_quantity, :integer)
  end

  @doc """
  Creates a new Output.
  """
  def new(attrs) do
    struct(__MODULE__, attrs)
  end
end
