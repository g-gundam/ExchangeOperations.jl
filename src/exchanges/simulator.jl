@kwdef mutable struct SimulatorPosition
    direction::TradeDirection.T
    amount::Union{Missing,Float64}
    price::Union{Missing,Float64}
end

@kwdef mutable struct SimulatorState <: AbstractExchangeState
    market::String
    ts::Union{DateTime,Missing}
    price::Float64
    position::Union{SimulatorPosition,Missing}
    total::Float64
end

@kwdef struct SimulatorSession <: AbstractSession
    responses::Channel = Channel{AbstractResponse}(16)
    state::SimulatorState = SimulatorState(market="BTCUSD",
                                           ts=missing,
                                           price=60_000.00,
                                           position=missing,
                                           total=500_000.00)
    order_log::Vector{AbstractResponse} = []
end

@kwdef struct SimulatorMarketBuy <: AbstractOperation
    amount::Float64
end

@kwdef struct SimulatorMarketBuyFill <: AbstractResponse
    ts::DateTime
    price::Float64
    amount::Float64
end

@kwdef struct SimulatorMarketSell <: AbstractOperation
    amount::Float64
end

@kwdef struct SimulatorMarketSellFill <: AbstractResponse
    ts::DateTime
    price::Float64
    amount::Float64
end

export SimulatorPosition
export SimulatorState
export SimulatorSession

export SimulatorMarketBuy
export SimulatorMarketBuyFill
export SimulatorMarketSell
export SimulatorMarketSellFill

"""$(TYPEDSIGNATURES)

Update the current time and current price of the asset in the simulator session.
"""
function update!(s::SimulatorSession, ts::DateTime, price::Float64)
    s.state.ts = ts
    s.state.price = price
end

"""$(TYPEDSIGNATURES)

Send a market buy order to the simulator.
"""
function send!(s::SimulatorSession, buy::SimulatorMarketBuy)
    if ismissing(s.state.position)
        # Create new position
        # TODO: Make sure we can afford to long.
        new_position = SimulatorPosition(direction=TradeDirection.Long,
                                         amount=buy.amount,
                                         price=s.state.price)
        s.state.position = new_position
        fill = SimulatorMarketBuyFill(;ts=s.state.ts, price=s.state.price, amount=buy.amount)
        put!(s.responses, fill)
        push!(s.order_log, fill)
    else
        old_position = s.state.position
        if old_position.direction == TradeDirection.Long
            # Increase long position
            # adjust quanitty and entry price
            new_amount = old_position.amount + buy.amount
            ratio_a = old_position.amount / new_amount
            ratio_b = buy.amount / new_amount
            new_price = (old_position.price * ratio_a) + (s.state.price * ratio_b)
            s.state.position.price = new_price # mutation
            s.state.position.amount = new_amount
            fill = SimulatorMarketBuyFill(;ts=s.state.ts, price=s.state.price, amount=buy.amount)
            put!(s.responses, fill)
            push!(s.order_log, fill)
        else
            # Decrease short position
            diff = -1 * profit(s.state.position.price, s.state.price, buy.amount)
            s.state.total += diff
            if s.state.position.amount == buy.amount
                s.state.position = missing
            else
                s.state.position.amount -= buy.amount
            end
            fill = SimulatorMarketBuyFill(;ts=s.state.ts, price=s.state.price, amount=buy.amount)
            put!(s.responses, fill)
            push!(s.order_log, fill)
            # TODO: Handle the case where buy.amount > old_position.amount too.
            # This should close the short, calculate pnl, and open a long.
        end
    end
    return s
end

"""$(TYPEDSIGNATURES)

Send a market sell order to the simulator.
"""
function send!(s::SimulatorSession, sell::SimulatorMarketSell)
    if ismissing(s.state.position)
        # Create new position
        # TODO: Make sure we can afford to short.
        new_position = SimulatorPosition(direction=TradeDirection.Short,
                                amount=sell.amount,
                                price=s.state.price)
        s.state.position = new_position
        fill = SimulatorMarketSellFill(;ts=s.state.ts, price=s.state.price, amount=sell.amount)
        put!(s.responses, fill)
        push!(s.order_log, fill)
    else
        old_position = s.state.position
        if old_position.direction == TradeDirection.Short
            # Increase position
            new_amount = old_position.amount + sell.amount
            ratio_a = old_position.amount / new_amount
            ratio_b = sell.amount / new_amount
            new_price = (old_position.price * ratio_a) + (s.state.price * ratio_b)
            s.state.position.price = new_price # mutation
            s.state.position.amount = new_amount
            fill = SimulatorMarketSellFill(;ts=s.state.ts, price=s.state.price, amount=sell.amount)
            put!(s.responses, fill)
            push!(s.order_log, fill)
        else
            # Decrease position
            diff = profit(s.state.position.price, s.state.price, sell.amount)
            # Update structs
            s.state.total += diff
            if s.state.position.amount == sell.amount
                # completely close position by removing it
                s.state.position = missing
            else
                # decrease position size
                s.state.position.amount -= sell.amount
            end
            fill = SimulatorMarketSellFill(;ts=s.state.ts, price=s.state.price, amount=sell.amount)
            put!(s.responses, fill)
            push!(s.order_log, fill)
        end
    end
    return s
end

"""$(TYPEDSIGNATURES)

This is a catchall send method to warn about unimplemented simulator operations.
"""
function send!(x::SimulatorSession, op::AbstractOperation)
    message = "A send method for $(typeof(op)) has not been written yet."
    @warn "unimplemented" message
    x
end
