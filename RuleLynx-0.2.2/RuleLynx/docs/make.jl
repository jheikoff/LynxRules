using Documenter
using RuleLynx

makedocs(
    sitename = "RuleLynx",
    format = Documenter.HTML(),
    modules = [RuleLynx]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
