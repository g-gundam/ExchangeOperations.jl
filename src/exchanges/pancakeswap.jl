using Web3

# I'm conficted on whether I should name this PancakeSwap or ApolloX.
# ApolloX is the group who actually built it.
# PancakeSwap is just a a white-label branding on top of the ApolloX DEX.
# They are the exact same exchange (literally) with 2 different names.
# - Orders in one show up in the other.

@kwdef mutable struct PancakeSwapSession <: AbstractSession
    responses::Channel = Channel{AbstractResponse}(16)
    order_log::Vector{AbstractResponse} = []
end

@kwdef struct PancakeSwapMarketLong <: AbstractOperation
    amount::Float64
    currency::Any
end

@kwdef struct PancakeSwapMarketLongFill <: AbstractResponse
    ts::DateTime
    price::Float64
    amount::Float64
    currency::Any
end

@kwdef struct PancakeSwapMarketShort <: AbstractOperation
    amount::Float64
    currency::Any
end

@kwdef struct PancakeSwapMarketShortFill <: AbstractResponse
    ts::DateTime
    price::Float64
    amount::Float64
    currency::Any
end

export PancakeSwapSession
export PancakeSwapMarketLong
export PancakeSwapMarketLongFill
export PancakeSwapMarketShort
export PancakeSwapMarketShortFill
