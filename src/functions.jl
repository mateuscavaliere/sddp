


function check_convergency( iter , zsup , zinf , criteria , flag )

    criteria_1 = 0
    criteria_2 = 0

    #- Criteria 1
    diff      = zsup[ iter , : ] .- zinf[ iter , : ]
    sort_diff = sort( diff )
    ave_diff  = mean( sort_diff[ 2:( length( diff ) - 1 ) ] )
    if ave_diff < criteria
        criteria_1 = 1
    end

    #- Criteria 2
    if flag == 1
        test_period = collect(Int , iter-1:-1:iter-3)
        test_period = test_period[ find( test_period .> 0)]
        if length( test_period) > 0 
            for i in test_period
                if sum( ( ( zsup[ iter , : ] .- zsup[ i , : ] ) .< criteria ) .* ( ( zinf[ iter , : ] .- zinf[ i , : ] ) .< criteria) )  == length( zsup[ iter , :] )
                    criteria_2 = 1
                end
            end
        end
    end

    if (criteria_1 == 1) | (criteria_2 == 1)
        return 1
    end
end




#--- sddp: This function calculates the operative decision on forward step

function sddp( sim_type::String , scen::Int , t::Int , nCuts::Int , γ::Array{Float64} , π::Array{Float64} , inflow::Array{Float64} , 
    case::Case , hydro::Hydros , therm::Thermals , demand::Demands , flag::Int = 0 , path::String = PATH_CASE )

    if ( sim_type != "forward" ) & ( sim_type != "backward" ) & ( sim_type != "simulation" )
        error( " First argument must be: forward or backward")
    end

    #------------------------------
    #---     Creating model     ---
    #------------------------------

    master = Model( solver = ClpSolver() )

    #- Creating variables
    @variable( master , 0 <= g[ j = 1:case.nTher ] <= therm.MaxGen[ j ] )
    @variable( master , 0 <= u[ i = 1:case.nHydr ] <= hydro.MaxGen[ i ] )
    @variable( master , 0 <= v[ i = 1:case.nHydr ] <= hydro.MaxVol[ i ] )
    @variable( master , s[ 1:case.nHydr ] >= 0 )
    @variable( master , α                 >= 0 )

    #- Creating constraints references
    @constraintref load_balance_cstr[  1            ]
    @constraintref hydro_balance_cstr[ 1:case.nHydr ]

    #-------------------------------------------
    #---     Adding constraints to model     ---
    #-------------------------------------------

    #- Load balance constraint
    load_balance_cstr[ 1 ] = @constraint( master , sum( g[ j ] for j in 1:case.nTher ) + sum( u[ i ] for i in 1:case.nHydr ) == demand.Load[ t ] )

    #- Hydros constraint
    for i in 1:case.nHydr
        hydro_balance_cstr[ i ] = @constraint( master , v[ i ] + u[ i ] + s[ i ] == hydro.Vol[ t , i , scen ] + inflow[ t , scen ] )
    end

    #- Cuts
    for k in 1:nCuts
        @constraint( master , α >= γ[ t + 1 , scen , k ]  + sum( π[ t + 1 , i , k ] * v[ i ] for i in 1:case.nHydr ) )
    end

    #------------------------------------------
    #---     Setting objective function     ---
    #------------------------------------------

    therm_cost = sum( therm.Cost[ j ] * g[ j ] for j in 1:case.nTher )
    obj_fun    = therm_cost + α
    @objective( master , Min , obj_fun )

    #- Writing LP

    if flag == 1
        if sim_type == "forward"
            writeLP( master , joinpath( path , "forward_$(scen).lp" ) , genericnames = false )
        else
            writeLP( master , joinpath( path , "backward_$(scen).lp" ) , genericnames = false )
        end
    end

    #- Solving
    solve( master )

    #- Returning values

    @show( getvalue(α) )

    if sim_type == "forward"
        
        therm.Gen[ t     , : , scen ] = getvalue( g )
        hydro.Gen[ t     , : , scen ] = getvalue( u )
        hydro.Vol[ t + 1 , : , scen ] = getvalue( v )
        hydro.Spil[ t    , : , scen ] = getvalue( s )

        return( getvalue( therm_cost ) )
    else
        return( getdual( hydro_balance_cstr ) , getvalue(obj_fun) )
    end

end


