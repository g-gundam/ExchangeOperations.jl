# ExchangeOperations

Exchange Operations as Data

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://g-gundam.github.io/ExchangeOperations.jl/dev/)
[![Build Status](https://github.com/g-gundam/XO.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/g-gundam/ExchangeOperations.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/g-gundam/XO.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/g-gundam/ExchangeOperations.jl)

## This is an experiment in API design.

- The main idea is to use structs to express the actions that are possible through an Exchange's API.
  + Treat exchange operations as data.
- There is a `send!(session, operation)` method that gets overloaded for different exchanges and their exchange operations (or API calls).

## Goals

- The first exchange interface to be implemented in this style will be a simple simulator exchange.
  + It'll only know how to do market-buy, market-sell, stop-market-buy, and stop-market-sell.
  + It's just enough for backtesting simple strategies.
  + It's deliberately dumb so that I could implement it easily.
- If that goes well enough, the next exchange interface to be implemented will be for PancakeSwap.
  + Let's give [Web3.jl](https://github.com/lambda-mechanics/Web3.jl) a spin.

