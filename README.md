# ExchangeOperations

Exchange Operations as Data


[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://g-gundam.github.io/ExchangeOperations.jl/dev/)
[![Build Status](https://github.com/g-gundam/XO.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/g-gundam/ExchangeOperations.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/g-gundam/XO.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/g-gundam/ExchangeOperations.jl)

## Warning

- The main reason for registering this is to make it available to public Pluto notebooks that I might write in the near future.
- If you want a sane and normal client library for interacting with cryptocurrency exchanges, I recommend [bhftbootcamp/CryptoExchangeAPIs.jl](https://github.com/bhftbootcamp/CryptoExchangeAPIs.jl).

## What is this?

- ExchangeOperations (or XO) is an experimental client library for interacting with cryptocurrency exchanges.
  + It also comes with a simple exchange simulator.
- The main interface is the `send!(session, operation)` function.
- It gets overloaded a lot for different exchanges and their exchange operations (or API calls).
- Every operation gets its own struct, so learning how to use this involves getting familiar with the available structs.
- Every session will provide a `responses` channel where asynchronous responses from the exchange can be found.
  + You can put an order in, but you don't know when the fill is going to happen if ever.

Here's what it looks like to interact with a simulator exchange.

```julia-repl
julia> import ExchangeOperations as XO

julia> session = XO.SimulatorSession() # set up a simulator session

julia> session.state.price # current price of BTCUSD
60000.0

julia> XO.send!(session, XO.SimulatorMarketBuy(1.0)) # buy 1 BTC

julia> XO.update!(session, now(), 100000.0) # pump the price of BTCUSD to 100000.0

julia> XO.send!(session, XO.SimulatorMarketSell(0.5)) # sell 0.5 BTC

julia> take!(session.responses)
ExchangeOperations.SimulatorMarketBuyFill(DateTime("2024-12-16T10:28:16.638"), 60000.0, 1.0)

julia> take!(session.responses)
ExchangeOperations.SimulatorMarketSellFill(DateTime("2024-12-16T10:28:50.977"), 100000.0, 0.5)
```

Interacting with normal exchanges will look similar, but you'll be
using exchange-specific types for the sessions and operations.  The
first real exchange interface I plan to implement is for PancakeSwap,
but as of v0.0.1, all you get is the super simple exchange simulator
that only knows market orders.

## This is experimental.

Don't take anything here too seriously.
