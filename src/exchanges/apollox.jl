module ApolloX

# Docs:
# https://apollox-finance.gitbook.io/apollox-finance/welcome/trading-on-v2/how-to-interact-directly-with-the-contract

#=
using ..ExchangeOperations
import ..ExchangeOperations as XO # pull in exports from parent module

using Dates
using Web3
using Web3: UInt256

@kwdef struct Session <: XO.AbstractSession
    whatever::Any
end

@kwdef struct OpenMarketTrade <: XO.AbstractOperation
    address::Any # XXX find appropriate type for addresses
    is_long::Bool
    token_in::Any              # 1e10
    amount_in::UInt256         # 1e8
    # Limit Order: limit price
    # Market Trade: worst price acceptable
    price::UInt256             # 1e8
    stop_loss::UInt256         # 1e8
    take_profit::UInt256       # 1e8
    broker::UInt256 = 1
end

@kwdef struct OpenMarketTradeResponse <: XO.AbstractResponse
    ts::DateTime
    trade_hash::String
    token_in::Any              # 1e10
    amount_in::UInt256         # 1e8
    # Limit Order: limit price
    # Market Trade: worst price acceptable
    price::UInt256             # 1e8
    stop_loss::UInt256         # 1e8
    take_profit::UInt256       # 1e8
    broker::UInt256 = 1
end

@kwdef struct UpdateTradeTPSL
    trade_hash::String
    take_profit_price::UInt256
    stop_loss_price::UInt256
end

@kwdef struct UpdateTradeTPSLResponse <: XO.AbstractResponse
    ts::DateTime
    trade_hash::String
    take_profit_price::UInt256
    stop_loss_price::UInt256
end

@kwdef struct ClosePosition <: XO.AbstractOperation
    trade_hash::String
end

@kwdef struct ClosePositionResponse <: XO.AbstractResponse
    ts::DateTime
    trade_hash::String
end

function XO.send!(s::Session, op::OpenMarketTrade)
end

function XO.send!(s::Session, op::UpdateTradeTPSL)
end

function XO.send!(s::Session, op::ClosePosition)
end
=#

end
