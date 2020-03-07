defmodule Exchange.Event do
  @moduledoc """
  Special structure to represent an Exchange Event.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: __MODULE__

  embedded_schema do
    field(:instruction, Ecto.Atom)
    field(:side, Ecto.Atom)
    field(:price_level_index, :integer)
    field(:price, :decimal)
    field(:quantity, :integer)
    field(:datetime, :naive_datetime)
  end

  @fields [
    :instruction,
    :side,
    :price_level_index,
    :price,
    :quantity,
    :datetime
  ]

  @doc """
  Creates a new Event.
  """
  def new(attrs) do
    struct(__MODULE__, attrs)
  end

  @doc """
  Creates an Ecto changeset.
  """
  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> validate_inclusion(:instruction, [:new, :update, :delete])
    |> validate_inclusion(:side, [:bid, :ask])
    |> validate_number(:price_level_index, greater_than: 0, message: "must be greater than zero")
  end

  @doc """
  Formats the errors in a easy-reading way.
  """
  def format_validation_errors(changeset) do
    traverse_errors(changeset, fn {msg, _opts} ->
      msg
    end)
  end
end
