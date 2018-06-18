__precompile__()

module NicheMap

using RCall
using DataFrames
using Unitful

export nichemap_global, 
       niche_setup, 
       niche_interpolate, 
       lin_interpolate, 
       NicheMapMicroclimate, 
       NicheMapGlobal

const nichemap_increments = (0.0,2.5,5.0,10.0,15.0,20.0,30.0,50.0,100.0,200.0) .* u"cm"

abstract type NicheMapMicroclimate end

struct NicheMapGlobal <: NicheMapMicroclimate
  soil::DataFrame
  shadsoil::DataFrame
  metout::DataFrame
  shadmet::DataFrame
  soilmoist::DataFrame
  shadmoist::DataFrame
  humid::DataFrame
  shadhumid::DataFrame
  soilpot::DataFrame
  shadpot::DataFrame
  plant::DataFrame
  shadplant::DataFrame
  RAINFALL::Vector{Float64}
  dim::Int
  ALTT::Float64
  REFL::Float64
  MAXSHADES::Vector{Float64}
  longlat::Vector{Float64}
  nyears::Int
  timeinterval::Int
  minshade::Float64
  maxshade::Float64
  DEP::Vector{Float64}
end

struct NicheInterp
    lower::Int
    upper::Int
    lowerfrac::Float64
    upperfrac::Float64
end

"""
    nichemap_global(location; [years, runmoist, timeinterval])

Runs the micro_global function formm the R package NicheMapR with passed in args.
Returns a nested dataframe of the results with correct column names.

# TODO allow vararg keyword splats
"""
function nichemap_global(location; years = 1, runmoist=1, timeinterval=365)
    @rput years location runmoist timeinterval
    R"""
    library(NicheMapR)
    micro <- micro_global(timeinterval=timeinterval, nyears=years, runmoist=runmoist, loc=location)

    # Convert R matrices to dataframes to preserve column names.
    for (name in names(micro)) {
        if (is.matrix(micro[[name]])) {
          micro[[name]] <- as.data.frame(micro[[name]])
        }
    }
    """
    @rget micro

    return NicheMapGlobal(values(micro)...)
end

" Calculate current interpolation layers and fraction from NicheMapR data"
niche_setup(height) = begin
    for (i, upper) in enumerate(nichemap_increments)
        if upper > height
            lower = nichemap_increments[i - 1]
            p = (height-lower)/(upper-lower)
            return NicheInterp(i + 1, i + 2, p, 1.0 - p)
        end
    end
    # Otherwise its taller/deeper than we have data, use the largest we have.
    max = length(nichemap_increments) + 2
    return NicheInterp(max, max, 1.0, 0.0)
end

" Interpolate between two layers of environmental data. "
niche_interpolate(i, data, pos) = begin
    lin_interpolate(data[i.lower], pos) * i.lowerfrac +
    lin_interpolate(data[i.upper], pos) * i.upperfrac
end

" Linear interpolation "
lin_interpolate(array, pos::Number) = begin
    int = floor(Int64, pos)
    frac::Float64 = pos - int
    array[int] * (1 - frac) + array[int + 1] * frac
end
lin_interpolate(array, pos::Int) = array[pos]

end # module
