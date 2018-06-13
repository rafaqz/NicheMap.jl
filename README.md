# NicheMap

A Simple wrapper for the R package
[NicheMaprR](https://github.com/mrke/NicheMapR), which provides local
microclimates for niche modelling given GPS coordinates.

Currently it only supports a subset of the options.

```julia
nichemap_global(location; years = 1, runmoist=1, timeinterval=365)
```

Where location can be a string or coordinate.

NicheMapR is not yet available on Cran, so install it manually.
