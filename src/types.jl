#       ------------------------------------------------
#            Defining types to be used in the model
#       ------------------------------------------------

mutable struct Case
    nStgs::Int;
    nTher::Int;
    nHydr::Int;
    nDem::Int;
    nScen::Int;
    Case() = new();
end

mutable struct Hydros
    Name::Array{String}
    Bus::Array{Int}
    MaxVol::Array{Float64};
    IniVol::Array{Float64};
    MaxGen::Array{Float64};
    Inflow::Array{Float64};
    Vol::Array{Float64};
    Gen::Array{Float64};
    Spil::Array{Float64};
    Hydros() = new();
end

mutable struct Thermals
    Name::Array{String}
    Bus::Array{Int}
    Cost::Array{Float64};
    MaxGen::Array{Float64};
    Gen::Array{Float64}
    Thermals() = new();
end

mutable struct Demands
    Name::Array{String};
    Bus::Array{Int};
    Load::Array{Float64};
    Demands() = new();
end


