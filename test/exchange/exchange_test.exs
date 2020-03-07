defmodule ExchangeTest do
  use ExUnit.Case

  alias Exchange.{Event, Server}

  describe ".send_instruction" do
    test "ensures it receives only valid inputs" do
      {:ok, pid} = Server.start_link()

      event = %{
        instruction: :new,
        side: :ask,
        price_level_index: 1,
        price: 1.2,
        quantity: 2
      }

      assert {:error, _error} =
               Exchange.send_instruction(
                 pid,
                 %{event | instruction: :neu}
               )

      assert {:error, _error} =
               Exchange.send_instruction(
                 pid,
                 %{event | side: "ask"}
               )

      assert {:error, _error} =
               Exchange.send_instruction(
                 pid,
                 %{event | price_level_index: "abc"}
               )

      assert {:error, _error} =
               Exchange.send_instruction(
                 pid,
                 %{event | price: "abc"}
               )

      assert {:error, _error} =
               Exchange.send_instruction(
                 pid,
                 %{event | quantity: "abc"}
               )

      assert {:error, _error} =
               Exchange.send_instruction(
                 pid,
                 %{event | price_level_index: -1}
               )

      assert {:error, _error} =
               Exchange.send_instruction(
                 10,
                 event
               )

      assert {:error, _error} =
               Exchange.send_instruction(
                 pid,
                 ""
               )

      assert {:error, _error} =
               Exchange.send_instruction(
                 pid,
                 %{}
               )
    end

    test "delete instruction returns error when index has not been found" do
      {:ok, pid} = Server.start_link({%{ask: nil, bid: nil}})

      event = %{
        instruction: :delete,
        side: :ask,
        price_level_index: 1,
        price: 1.2,
        quantity: 2
      }

      assert {:error, "Index has not been found"} =
               Exchange.send_instruction(
                 pid,
                 event
               )

      assert {:error, "Index has not been found"} =
               Exchange.send_instruction(
                 pid,
                 %{event | price_level_index: 2}
               )
    end

    test "delete instruction removes an index when state is not empty" do
      state = {
        %{
          ask: %Event{price: Decimal.cast(1.1)},
          bid: %Event{price: Decimal.cast(1.2)}
        },
        %{ask: %Event{}, bid: nil},
        %{
          ask: %Event{price: Decimal.cast(1.3)},
          bid: %Event{price: Decimal.cast(1.6)}
        }
      }

      {:ok, pid} = Server.start_link(state)

      event = %{
        instruction: :delete,
        side: :ask,
        price_level_index: 2,
        price: 1.2,
        quantity: 2
      }

      assert :ok =
               Exchange.send_instruction(
                 pid,
                 event
               )

      assert {_, %{ask: %Event{price: price}, bid: nil}, %{ask: nil, bid: _}} 
      = Server.get_current_state(pid)

      assert price == Decimal.cast(1.3)
    end

    test "update instruction returns error when index has not been found" do
      {:ok, pid} = Server.start_link({%{ask: nil, bid: nil}})

      event = %{
        instruction: :update,
        side: :ask,
        price_level_index: 1,
        price: 1.2,
        quantity: 2
      }

      assert {:error, "Index has not been found"} =
               Exchange.send_instruction(
                 pid,
                 event
               )

      assert {:error, "Index has not been found"} =
               Exchange.send_instruction(
                 pid,
                 %{event | price_level_index: 2}
               )
    end

    test "update instruction updates an index when state is not empty" do
      state = {
        %{ask: %Event{}, bid: nil},
        %{ask: %Event{}, bid: %Event{}},
        %{ask: nil, bid: %Event{}}
      }

      {:ok, pid} = Server.start_link(state)

      event = %{
        instruction: :update,
        side: :bid,
        price_level_index: 3,
        price: 1.9,
        quantity: 2
      }

      assert :ok =
               Exchange.send_instruction(
                 pid,
                 event
               )

      assert {_, _, %{ask: nil, bid: %Event{price: price}}} 
      = Server.get_current_state(pid)

      assert price == Decimal.cast(1.9)
    end

    test "new instruction inserts an index when state is empty" do
      {:ok, pid} = Server.start_link()

      event = %{
        instruction: :new,
        side: :ask,
        price_level_index: 3,
        price: 1.75,
        quantity: 2
      }

      assert :ok =
               Exchange.send_instruction(
                 pid,
                 event
               )

      assert {_, _, %{ask: %Event{price: price}, bid: nil}}
      = Server.get_current_state(pid)

      assert price == Decimal.cast(1.75)
    end

    test "new instruction inserts an index when state is not empty" do
      state = {
        %{ask: %Event{}, bid: nil},
        %{ask: %Event{}, bid: %Event{}},
        %{ask: nil, bid: %Event{}}
      }

      {:ok, pid} = Server.start_link(state)

      event = %{
        instruction: :new,
        side: :ask,
        price_level_index: 2,
        price: 1.75,
        quantity: 2
      }

      assert :ok =
               Exchange.send_instruction(
                 pid,
                 event
               )

      assert {_, %{ask: ask, bid: _}, _, _} 
      = Server.get_current_state(pid)

      assert ask.price == Decimal.cast(1.75)
    end
  end

  describe ".order_book" do
    test "ensures it receives only valid inputs" do
      {:ok, pid} = Server.start_link()

      assert {:error, _error} =
               Exchange.order_book(
                 pid,
                 -2
               )

      assert {:error, _error} =
               Exchange.order_book(
                 pid,
                 -2
               )

      assert {:error, _error} =
               Exchange.order_book(
                 10,
                 3
               )

      assert {:error, _error} =
               Exchange.order_book(
                 10,
                 "3"
               )

      assert {:error, _error} =
               Exchange.order_book(
                 pid,
                 -1
               )
    end

    test "price level that have not been provided should have values of zero" do
      {:ok, pid} = Server.start_link()

      result = Exchange.order_book(pid, 4)

      assert Enum.count(result, &is_zero_output/1) == 4
    end

    test "gets valid order books" do
      {:ok, pid} = Server.start_link()

      Exchange.send_instruction(
        pid,
        %{
          instruction: :new,
          side: :bid,
          price_level_index: 1,
          price: 50.0,
          quantity: 30
        }
      )

      Exchange.send_instruction(
        pid,
        %{
          instruction: :new,
          side: :bid,
          price_level_index: 2,
          price: 40.0,
          quantity: 40
        }
      )

      Exchange.send_instruction(
        pid,
        %{
          instruction: :new,
          side: :ask,
          price_level_index: 1,
          price: 60.0,
          quantity: 10
        }
      )

      Exchange.send_instruction(
        pid,
        %{
          instruction: :new,
          side: :ask,
          price_level_index: 2,
          price: 70.0,
          quantity: 10
        }
      )

      Exchange.send_instruction(
        pid,
        %{
          instruction: :update,
          side: :ask,
          price_level_index: 2,
          price: 70.0,
          quantity: 20
        }
      )

      Exchange.send_instruction(
        pid,
        %{
          instruction: :update,
          side: :bid,
          price_level_index: 1,
          price: 50.0,
          quantity: 40
        }
      )

      assert [first, second | []] 
      = Exchange.order_book(pid, 2)

      assert first == %Exchange.Output{
               ask_price: Decimal.cast(60.0),
               ask_quantity: 10,
               bid_price: Decimal.cast(50.0),
               bid_quantity: 40,
               id: nil
             }

      assert second == %Exchange.Output{
               ask_price: Decimal.cast(70.0),
               ask_quantity: 20,
               bid_price: Decimal.cast(40.0),
               bid_quantity: 40,
               id: nil
             }
    end
  end

  defp is_zero_output(output) do
    output.ask_price == 0 &&
      output.ask_quantity == 0 &&
      output.bid_price == 0 &&
      output.bid_quantity == 0
  end
end
