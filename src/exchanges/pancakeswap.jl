using Web3
using Decimals
using FixedPointDecimals

# I'm conficted on whether I should name this PancakeSwap or ApolloX.
# ApolloX is the group who actually built it.
# PancakeSwap is just a a white-label branding on top of the ApolloX DEX.
# They are the exact same exchange (literally) with 2 different names.
# - Orders in one show up in the other.
# https://apollox-finance.gitbook.io/apollox-finance/welcome/trading-on-v2/how-to-interact-directly-with-the-contract

@kwdef mutable struct PancakeSwapSession <: AbstractSession
    responses::Channel = Channel{AbstractResponse}(16)
    order_log::Vector{AbstractResponse} = []
end

@kwdef struct PancakeSwapMarketLong <: AbstractOperation
    amount::Decimal
    currency::Any
end

@kwdef struct PancakeSwapMarketLongFill <: AbstractResponse
    ts::DateTime
    price::Decimal
    amount::Decimal
    currency::Any
end

@kwdef struct PancakeSwapMarketShort <: AbstractOperation
    amount::Decimal
    currency::Any
end

@kwdef struct PancakeSwapMarketShortFill <: AbstractResponse
    ts::DateTime
    price::Decimal
    amount::Decimal
    currency::Any
end

export PancakeSwapSession
export PancakeSwapMarketLong
export PancakeSwapMarketLongFill
export PancakeSwapMarketShort
export PancakeSwapMarketShortFill
