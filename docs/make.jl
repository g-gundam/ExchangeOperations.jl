using XO
using Documenter

DocMeta.setdocmeta!(XO, :DocTestSetup, :(using XO); recursive=true)

makedocs(;
    modules=[XO],
    authors="gg <gg@nowhere> and contributors",
    sitename="XO.jl",
    format=Documenter.HTML(;
        canonical="https://g-gundam.github.io/XO.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/g-gundam/XO.jl",
    devbranch="main",
)
