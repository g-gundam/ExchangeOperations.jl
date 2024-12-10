import ExchangeOperations as XO
using Test

@testset "simulator" begin
    # instantiate a default session
    session = XO.SimulatorSession()
    @test session.state.market == "BTCUSD"
end
