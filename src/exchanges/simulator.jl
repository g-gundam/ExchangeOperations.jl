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
                                           ts=now(),
                                           price=60_000.00,
                                           position=missing,
                                           total=500_000.00)
    stops::Vector{AbstractOperation} = []
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

@kwdef mutable struct SimulatorStopMarketBuy <: AbstractOperation
    id::UUID = uuid4(RNG)
    price::Float64
    amount::Float64
end

# TODO: Make use of this.
@kwdef struct SimulatorStopMarketBuyResponse <:  AbstractResponse
    ts::DateTime
    id::UUID
    iscreated::Bool
    price::Float64
    amount::Float64
end

@kwdef mutable struct SimulatorStopMarketSell <: AbstractOperation
    id::UUID = uuid4(RNG)
    price::Float64
    amount::Float64
end

# TODO: Make use of this.
@kwdef struct SimulatorStopMarketSellResponse <:  AbstractResponse
    ts::DateTime
    id::UUID
    iscreated::Bool
    price::Float64
    amount::Float64
end

@kwdef struct SimulatorStopMarketUpdate <: AbstractOperation
    id::UUID
    price::Union{Float64,Missing} = missing
    amount::Union{Float64,Missing} = missing
end

@kwdef struct SimulatorStopMarketCancel <: AbstractOperation
    id::UUID
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
function update!(s::SimulatorSession, ts::DateTime, next_price::Float64)
    current_price = s.state.price
    # mutate {
    s.state.ts = ts
    s.state.price = next_price
    # }
    for order in s.stops
        trigger!(s, order, current_price, next_price)
    end
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

# buy gets triggered when price rises to the stop.price
function trigger!(s::SimulatorSession, stopmarketbuy::SimulatorStopMarketBuy, current_price::Float64, next_price::Float64)
    if current_price < stopmarketbuy.price && next_price >= stopmarketbuy.price
        marketbuy = SimulatorMarketBuy(amount=stopmarketbuy.amount)
        send!(s, marketbuy)
    end
    return s
end

# sell gets triggered when price lowers to the stop.price
function trigger!(s::SimulatorSession, stopmarketsell::SimulatorStopMarketSell, current_price::Float64, next_price::Float64)
    if current_price > stopmarketsell.price && next_price <= stopmarketsell.price
        marketsell = SimulatorMarketSell(amount=stopmarketsell.amount)
        send!(s, marketsell)
    end
    return s
end

function send!(s::SimulatorSession, stopmarketbuy::SimulatorStopMarketBuy)
    # XXX: What are some sanity checks I should do first?
    push!(s.stops, stopmarketbuy)
    response = SimulatorStopMarketBuyResponse(
        ts=s.state.ts,
        id=stopmarketbuy.id,
        iscreated=true,
        price=stopmarketbuy.price,
        amount=stopmarketbuy.amount
    )
    put!(s.responses, response)
    return s
end

function send!(s::SimulatorSession, stopmarketsell::SimulatorStopMarketSell)
    # XXX: Add sanity checks before performing operations
    push!(s.stops, stopmarketsell)
    response = SimulatorStopMarketSellResponse(
        ts=s.state.ts,
        id=stopmarketsell.id,
        iscreated=true,
        price=stopmarketsell.price,
        amount=stopmarketsell.amount
    )
    put!(s.responses, response)
    return s
end

function send!(s::SimulatorSession, stopmarketupdate::SimulatorStopMarketUpdate)
    id = stopmarketupdate.id
    order = findfirst(n -> n.id == id, s.stops)
    if ismissing(order)
        @warn :missing
    else
        # XXX: What if this causes the stop to be triggered?
        if !ismissing(stopmarketupdate.price)
            s.stops[order].price = stopmarketupdate.price
        end
        if !ismissing(stopmarketupdate.amount)
            s.stops[order].amount = stopmarketupdate.amount
        end
    end
    return s
end

function send!(s::SimulatorSession, stopmarketcancel::SimulatorStopMarketCancel)
    id = stopmarketcancel.id
    filter!(n -> n.id != id, s.stops)
    return s
end

"""$(TYPEDSIGNATURES)

This is a catchall send method to warn about unimplemented simulator operations.
"""
function send!(x::SimulatorSession, op::AbstractOperation)
    message = "A send! method for $(typeof(op)) has not been written yet."
    @warn "unimplemented" message
    x
end
