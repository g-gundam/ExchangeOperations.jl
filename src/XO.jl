module XO

using DocStringExtensions
using Dates
using NanoDates

abstract type AbstractExchangeState end
abstract type AbstractSession end
abstract type AbstractOperation end
abstract type AbstractResponse end 

@enum XO_POSITION_TYPES begin
    XO_NEUTRAL = 0
    XO_LONG = 1
    XO_SHORT = 2
end

export AbstractExchangeState
export AbstractSession
export AbstractOperation
export AbstractResponse
export XO_POSITION_TYPES
export XO_NEUTRAL
export XO_LONG
export XO_SHORT

function send(x::AbstractSession, op::AbstractOperation)
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

export send

include("exchanges/simulator.jl")

end
