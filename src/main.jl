#       ------------------------------------------------
#                        Dispatch Model 
#       ------------------------------------------------

#- Author: Mateus Cavaliere ( PUC - 2018 )
#- Description: This is the main module of the dispatch model created to emulate a hydrithermal system optimal dispatch

#-----------------------------------------
#----           Loading libs          ----
#-----------------------------------------

using JuMP
using Clp

#-------------------------------------------
#----           Defining paths          ----
#-------------------------------------------

# ROOT = joinpath(dirname(@__FILE__),"..")

# const PATH_SRC  = joinpath( ROOT , "src" )

const PATH_SRC = "D:\\repositories\\sddp\\src";
PATH_CASE      = "D:\\repositories\\sddp\\examples\\example_3";

const TYPES     = joinpath( PATH_SRC , "types.jl"     );
const FUNCTIONS = joinpath( PATH_SRC , "functions.jl" );
const SDDP      = joinpath( PATH_SRC , "run_sddp.jl"  );

#-------------------------------------------
#----       Loading other modules       ----
#-------------------------------------------

include( TYPES     );
include( FUNCTIONS );

#-------------------------------------------
#----        Running main module        ----
#-------------------------------------------

const max_iter = 10;
const ϵ        = 0.1;

#-----------------------------
#---    Case parameters    ---
#-----------------------------

CASE       = Case();
CASE.nStgs = 3;
CASE.nTher = 2;
CASE.nHydr = 1;
CASE.nScen = 1;

#--------------------------------
#---    Initial conditions    ---
#--------------------------------

INFLOW = Array{Float64}( CASE.nStgs , CASE.nHydr );
INFLOW = [ 50.0 ; 50.0 ; 50.0 ]
#INFLOW = readcsv( joinpath( PATH_CASE , "dat_inflow.csv" ) );

#------------------------------
#---    Hydro parameters    ---
#------------------------------

HYDRO        = Hydros();
HYDRO.MaxVol = Array{Float64}( CASE.nHydr );
HYDRO.MaxGen = Array{Float64}( CASE.nHydr );
HYDRO.Vol    = Array{Float64}( CASE.nStgs + 1 , CASE.nHydr , CASE.nScen );
HYDRO.Gen    = Array{Float64}( CASE.nStgs     , CASE.nHydr , CASE.nScen );
HYDRO.Spil   = Array{Float64}( CASE.nStgs     , CASE.nHydr , CASE.nScen );

HYDRO.MaxVol = [ 200.0 ]
HYDRO.MaxGen = [ 150.0 ]
HYDRO.Vol[ 1 , : , : ] = 150.0

#---------------------------------
#---    Thermals parameters    ---
#---------------------------------

THERM        = Thermals();
THERM.MaxGen = Array{Float64}( CASE.nTher );
THERM.Cost   = Array{Float64}( CASE.nTher );
THERM.Gen    = Array{Float64}( CASE.nStgs , CASE.nTher , CASE.nScen ) ;

THERM.MaxGen = [ 50.0 , 50.0 ];
THERM.Cost   = [ 100.0 , 1000.0 ];

#-------------------------------
#---    Demand parameters    ---
#-------------------------------

DEMAND      = Demands();
DEMAND.Load = [ 150 ; 150 ; 150 ]
#DEMAND.Load = readcsv( joinpath( PATH_CASE , "dat_demand.csv" ) );



include( SDDP )


for i in 1:CASE.nHydr
    writecsv( joinpath(PATH_CASE , "gerhid_$(i).csv" ) , HYDRO.Gen[: , i , : ] )
end

for j in 1:CASE.nTher
    writecsv( joinpath(PATH_CASE , "gerter_$(j).csv" ) , THERM.Gen[: , j , : ] )
end

writecsv( joinpath(PATH_CASE , "zsup.csv" ) , ZSUP )
writecsv( joinpath(PATH_CASE , "zinf.csv" ) , ZINF )

