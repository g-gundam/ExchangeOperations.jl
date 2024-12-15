using ExchangeOperations
using Documenter

DocMeta.setdocmeta!(ExchangeOperations, :DocTestSetup, :(using ExchangeOperations); recursive=true)

makedocs(;
    modules=[ExchangeOperations],
    authors="gg <gg@nowhere> and contributors",
    sitename="ExchangeOperations.jl",
    format=Documenter.HTML(;
        canonical="https://g-gundam.github.io/ExchangeOperations.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/g-gundam/ExchangeOperations.jl",
    devbranch="main",
)
