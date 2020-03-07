# Stock Exchanges

## You have Elixir/Erlang installed 

  * Install dependencies with `mix deps.get`
  * Run tests `MIX_ENV=test mix test`

## You prefer to use Docker

* Build the image and container `docker-compose up -d`
* Start the container `docker container exec -it app sh` 
* Install dependencies `mix deps.get` 
* Run tests `MIX_ENV=test mix test`

## Settings

- Elixir 1.10
- Erlang/OTP 22 
- Default Environment variables: MIX_ENV as dev
- Database: no
- Libraries: Ecto (Just for validation)

## How to use it? 

* Run the program `iex -S mix`

```elixir

 #Example of a valid Event:

  %{
    instruction: :new | :update | :delete,
    side: :bid | :ask,
    price_level_index: integer()
    price: float()
    quantity: integer()
  }

iex(1)> {:ok, exchange_pid} = Exchange.start_link()
{:ok, #PID<0.141.0>}
iex(2)> Exchange.send_instruction(exchange_pid, %{
  instruction: :new,
  side: :bid,
  price_level_index: 1, 
  price: 50.0,
  quantity: 30
})
:ok
iex(3)> Exchange.send_instruction(exchange_pid, %{
  instruction: :new,
  side: :bid,
  price_level_index: 2, 
  price: 40.0,
  quantity: 40
})
:ok
iex(4)> Exchange.send_instruction(exchange_pid, %{
  instruction: :new,
  side: :ask,
  price_level_index: 1, 
  price: 60.0,
  quantity: 10
})
:ok
iex(5)> Exchange.send_instruction(exchange_pid, %{
  instruction: :new,
  side: :ask,
  price_level_index: 2, 
  price: 70.0,
  quantity: 10
})
:ok
iex(6)> Exchange.send_instruction(exchange_pid, %{
  instruction: :update,
  side: :ask,
  price_level_index: 2, 
  price: 70.0,
  quantity: 20
})
:ok
iex(7)> Exchange.send_instruction(exchange_pid, %{
  instruction: :update,
  side: :bid,
  price_level_index: 1, 
  price: 50.0,
  quantity: 40
})
:ok
iex(8)> Exchange.order_book(exchange_pid, 2)
[
  %{ask_price: 60.0, ask_quantity: 10, bid_price: 50.0, bid_quantity: 40},
  %{ask_price: 70.0, ask_quantity: 20, bid_price: 40.0, bid_quantity: 40}
]
```
