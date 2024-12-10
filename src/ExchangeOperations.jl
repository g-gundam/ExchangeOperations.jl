module ExchangeOperations

using DocStringExtensions
using Dates
using NanoDates
using EnumX

abstract type AbstractExchangeState end
abstract type AbstractSession end
abstract type AbstractOperation end
abstract type AbstractResponse end 

@enumx TradeDirection Neutral Long Short

export AbstractExchangeState
export AbstractSession
export AbstractOperation
export AbstractResponse
export TradeDirection

function send!(x::AbstractSession, op::AbstractOperation)
    @warn "Unimplemented"
end

function update!(x::AbstractSession, price::Float64)
    @warn "Unimplemented"
end

"""$(TYPEDSIGNATURES)

This is a utility function to help calculate profit or loss.
"""
function profit(a::Number, b::Number, q::Number)
    #percent_change = ((b - a) / a) * 100
    profit = (b * q) - (a * q)
    profit
end

export send!

include("exchanges/simulator.jl")
include("exchanges/pancakeswap.jl")

end
