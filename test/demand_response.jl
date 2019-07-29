using Dates
using PowerSystems
using Test
using TimeSeries

const EVIPRO_DATA = abspath(joinpath(dirname(Base.find_package("PowerSystems")), "..", "data", "evi-pro", "FlexibleDemand_1000.mat"))


@testset "Reading EVIpro dataset" begin
    @test begin
       bevs = populate_BEV_demand(EVIPRO_DATA)
       length(bevs) == 1000
    end
end


function checkcharging(f)
    bevs = populate_BEV_demand(EVIPRO_DATA)
    i = 0
    for bev in bevs
        i += 1
        @test begin
            charging = f(bev)
            delta = shortfall(bev, charging)
            result = abs(delta) <= 1
            if !result
                @warn string("BEV ", i, " in '", EVIPRO_DATA, "' has charging discrepancy of ", delta, " kWh.")
            end
            result
        end
    end
end

@testset "Earliest demands on EVIpro dataset" begin
    checkcharging(earliestdemands)
end

@testset "Latest demands on EVIpro dataset" begin
    checkcharging(latestdemands)
end
