__precompile__()

module NicheMap

using RCall
using DataFrames
using Unitful
using Microclimate

export nichemap_global 

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

    return MicroclimateData(values(micro)...)
end

end # module
