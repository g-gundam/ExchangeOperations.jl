module ApolloX

# Docs:
# https://apollox-finance.gitbook.io/apollox-finance/welcome/trading-on-v2/how-to-interact-directly-with-the-contract

using ..ExchangeOperations # pull in exports from parent module

using Web3
using Web3: UInt256

@kwdef struct Session <: AbstractSession
    whatever::Any
end

@kwdef struct OpenMarketTrade
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

end
