
@kwdef mutable struct SimulatorPosition
    direction::XO_POSITION_TYPES
    quantity::Float64
    price::Float64
end

@kwdef mutable struct SimulatorFill
    ts::NanoDate
    direction::XO_POSITION_TYPES
    quantity::Float64
    price::Float64
end

@kwdef mutable struct SimulatorState <: AbstractExchangeState
    market::String
    price::Float64
    position::Union{SimulatorPosition,Missing}
    total::Float64
end

@kwdef struct SimulatorSession <: AbstractSession
    responses::Channel = Channel{AbstractResponse}(16)
    state::SimulatorState = SimulatorState(market="BTCUSD",
                                           price=60_000.00,
                                           position=missing,
                                           total=500_000.00)
end

@kwdef struct SimulatorMarketBuy <: AbstractOperation
    quantity::Float64
end

@kwdef struct SimulatorMarketBuyFill <: AbstractResponse
    price::Float64
    quantity::Float64
end

@kwdef struct SimulatorMarketSell <: AbstractOperation
    quantity::Float64
end

@kwdef struct SimulatorMarketSellFill <: AbstractResponse
    price::Float64
    quantity::Float64
end

@kwdef struct SimulatorUpdateStop <: AbstractOperation
    order_id::AbstractString
    price::Float64
end

@kwdef struct SimulatorUpdateStopFill <: AbstractResponse
    order_id::AbstractString
    price::Float64
    quantity::Float64
end

export SimulatorPosition
export SimulatorFill
export SimulatorState
export SimulatorSession

export SimulatorMarketBuy
export SimulatorMarketBuyFill
export SimulatorMarketSell
export SimulatorMarketSellFill
export SimulatorUpdateStop
export SimulatorUpdateStopFill

"""$(TYPEDSIGNATURES)

Send a market buy order to the simulator.
"""
function send(s::SimulatorSession, buy::SimulatorMarketBuy)
    if ismissing(s.state.position)
        # Create new position
        # TODO: Make sure we can afford to long.
        new_position = SimulatorPosition(direction=XO_LONG,
                                         quantity=buy.quantity,
                                         price=s.state.price)
        s.state.position = new_position
        fill = SimulatorMarketBuyFill(;price=s.state.price, quantity=buy.quantity)
        put!(s.responses, fill)
    else
        old_position = s.state.position
        if old_position.direction == XO_LONG
            # Increase long position
            @info "increase long"
            # adjust quanitty and entry price
            new_quantity = old_position.quantity + buy.quantity
            ratio_a = old_position.quantity / new_quantity
            ratio_b = buy.quantity / new_quantity
            new_price = (old_position.price * ratio_a) + (s.state.price * ratio_b)
            s.state.position.price = new_price # mutation
            s.state.position.quantity = new_quantity
            fill = SimulatorMarketBuyFill(;price=s.state.price, quantity=buy.quantity)
            put!(s.responses, fill)
        else
            # Decrease short position
            diff = -1 * profit(s.state.position.price, s.state.price, buy.quantity)
            s.state.total += diff
            if s.state.position.quantity == buy.quantity
                s.state.position = missing
            else
                s.state.position.quantity -= buy.quantity
            end
            fill = SimulatorMarketBuyFill(;price=s.state.price, quantity=buy.quantity)
            put!(s.responses, fill)
            # TODO: Handle the case where buy.quantity > old_position.quantity too.
            # This should close the short, calculate pnl, and open a long.
        end
    end
    return s
end

"""$(TYPEDSIGNATURES)

Send a market sell order to the simulator.
"""
function send(s::SimulatorSession, sell::SimulatorMarketSell)
    if ismissing(s.state.position)
        # Create new position
        # TODO: Make sure we can afford to short.
        new_position = SimulatorPosition(direction=XO_SHORT,
                                quantity=sell.quantity,
                                price=s.state.price)
        s.state.position = new_position
        fill = SimulatorMarketSellFill(;price=s.state.price, quantity=sell.quantity)
        put!(s.responses, fill)
    else
        old_position = s.state.position
        if old_position.direction == XO_SHORT
            # Increase position
            @info "increase short"
            new_quantity = old_position.quantity + sell.quantity
            ratio_a = old_position.quantity / new_quantity
            ratio_b = sell.quantity / new_quantity
            new_price = (old_position.price * ratio_a) + (s.state.price * ratio_b)
            s.state.position.price = new_price # mutation
            s.state.position.quantity = new_quantity
            fill = SimulatorMarketSellFill(;price=s.state.price, quantity=sell.quantity)
            put!(s.responses, fill)
        else
            # Decrease position
            diff = profit(s.state.position.price, s.state.price, sell.quantity)
            # Update structs
            s.state.total += diff
            if s.state.position.quantity == sell.quantity
                # completely close position by removing it
                s.state.position = missing
            else
                # decrease position size
                s.state.position.quantity -= sell.quantity
            end
            fill = SimulatorMarketSellFill(;price=s.state.price, quantity=sell.quantity)
            put!(s.responses, fill)
        end
    end
    return s
end

"""$(TYPEDSIGNATURES)

This is a catchall send method to warn about unimplemented simulator operations.
"""
function send(x::SimulatorSession, op::AbstractOperation)
    message = "A send method for $(typeof(op)) has not been written yet."
    @warn "unimplemented" message
    x
end
