import JSON2

function validate_serialization(sys::System)
    path, io = mktemp()
    @info "Serializing to $path"

    try
        to_json(io, sys)
    catch
        close(io)
        rm(path)
        rethrow()
    end
    close(io)

    try
        sys2 = System(path)
        return IS.compare_values(sys, sys2)
    finally
        @debug "delete temp file" path
        rm(path)
    end
end

@testset "Test JSON serialization of CDM data" begin
    sys = create_rts_system()
    @test validate_serialization(sys)
    text = JSON2.write(sys)
    @test length(text) > 0
end

@testset "Test JSON serialization of matpower data" begin
    sys = PowerSystems.parse_standard_files(joinpath(MATPOWER_DIR, "case5_re.m"))

    # Add a Probabilistic forecast to get coverage serializing it.
    bus = Bus(nothing)
    bus.name = "Bus1234"
    add_component!(sys, bus)
    tg = RenewableFix(nothing)
    tg.bus = bus
    tProbabilisticForecast = PSY.Probabilistic(tg, "scalingfactor", Hour(1),
                                           DateTime("01-01-01"), [0.5, 0.5], 24)
    add_component!(sys, tg)
    add_forecast!(sys, tProbabilisticForecast)

    @test validate_serialization(sys)
end

@testset "Test JSON serialization of ACTIVSg2000 data" begin
    sys = PowerSystems.parse_standard_files(joinpath(DATA_DIR, "ACTIVSg2000",
                                                     "ACTIVSg2000.m"))
    validate_serialization(sys)
end

@testset "Test serialization utility functions" begin
    text = "SomeType{ParameterType1, ParameterType2}"
    type_str, parameters = IS.separate_type_and_parameter_types(text)
    @test type_str == "SomeType"
    @test parameters == ["ParameterType1", "ParameterType2"]

    text = "SomeType"
    type_str, parameters = IS.separate_type_and_parameter_types(text)
    @test type_str == "SomeType"
    @test parameters == []
end
