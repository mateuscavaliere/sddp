
ZSUP = ones(  max_iter ) * Inf
ZINF = zeros( max_iter )

γ = Array{Float64}( CASE.nStgs + 1 , CASE.nScen , max_iter )
π = Array{Float64}( CASE.nStgs + 1 , CASE.nHydr , max_iter )

γ[ : , : , 1 ]  = 0
π[ : , : , 1 ]  = 0

γ[ end , : , : ] = 0
π[ end , : , : ] = 0

# First cut
nCut = 1
aux_ZINF = zeros(CASE.nScen)
thermal_cost = Array{Float64}( CASE.nStgs , CASE.nScen )

for iter in 1:(max_iter-1)

    @show iter

    #- Forward step

    for t in 1:CASE.nStgs
        for scen in 1:CASE.nScen
            thermal_cost[ t , scen ] = sddp( "forward" , scen , t , nCut , γ , π , INFLOW , CASE , HYDRO , THERM , DEMAND , 1)
        end
    end

    ZSUP[ iter ] = mean( sum( thermal_cost[ t , : ] for t in 1:CASE.nStgs ) )

    # conv = check_convergency( iter , ZSUP , ZINF , ϵ , 0)

    # if conv == 1
    #     break
    # end

    # Next cut
    nCut = nCut + 1

    #- Backward

    for t in CASE.nStgs:-1:2
        aux_π    = zeros( CASE.nHydr , CASE.nScen )
        aux_cost = zeros( CASE.nScen )

        for scen in 1:CASE.nScen
            aux_π[ : , scen ] , aux_cost[ scen ] = sddp( "backward" , scen , t , nCut , γ , π , INFLOW , CASE , HYDRO , THERM , DEMAND )
        end

        π[ t , : , nCut ] = mean( aux_π , 2)
        
        for scen in 1:CASE.nScen
            γ[ t , scen , nCut ] = mean( aux_cost ) - sum( π[t , : , nCut ] .* HYDRO.Vol[ t , : , scen ])
        end

    end

    ZINF[iter] = sddp( "backward" , 1 , 1 , nCut , γ , π , INFLOW , CASE , HYDRO , THERM , DEMAND )[2]

    

    print( string("Z_INF = $(ZINF[iter])  |  Z_SUP = $(ZSUP[iter]) \n"))
end



