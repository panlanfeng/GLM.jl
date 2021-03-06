using Base.Cartesian

abstract Link             # Link types define linkfun!, linkinv!, and mueta!

type CauchitLink <: Link end
type CloglogLink  <: Link end
type IdentityLink <: Link end
type InverseLink  <: Link end
type LogitLink <: Link end
type LogLink <: Link end
type ProbitLink <: Link end
type SqrtLink <: Link end

linkfun(::CauchitLink, μ) = tan(pi*(μ - oftype(μ, 0.5)))
linkinv(::CauchitLink, η) = oftype(η, 0.5) + atan(η)/pi
mueta(::CauchitLink, η) = one(η)/(pi*(one(η) + abs2(η)))

linkfun(::CloglogLink, μ) = log(-log1p(-μ))
linkinv(::CloglogLink, η) = -expm1(-exp(η))
mueta(::CloglogLink, η) = exp(η)*exp(-exp(η))

linkfun(::IdentityLink, μ) = μ
linkinv(::IdentityLink, η) = η
mueta(::IdentityLink, η) = 1

linkfun(::InverseLink, μ) = 1/μ
linkinv(::InverseLink, η) = 1/η
mueta(::InverseLink, η) = -inv(abs2(η))

linkfun(::LogitLink, μ) = logit(μ)
linkinv(::LogitLink, η) = logistic(η)
mueta(::LogitLink, η) = (e = exp(-abs(η)); f = one(η) + e; e / (f * f))

linkfun(::LogLink, μ) = log(μ)
linkinv(::LogLink, η) = exp(η)
mueta(::LogLink, η) = exp(η)

linkfun(::ProbitLink, μ) = -sqrt2*erfcinv(2*μ)
linkinv(::ProbitLink, η) = erfc(-η/sqrt2)/2
mueta(::ProbitLink, η) = exp(-η^2/2)/sqrt2π

linkfun(::SqrtLink, μ) = sqrt(μ)
linkinv(::SqrtLink, η) = abs2(η)
mueta(::SqrtLink, η) = 2η

canonicallink(::Binomial) = LogitLink()
canonicallink(::Gamma) = InverseLink()
canonicallink(::Normal) = IdentityLink()
canonicallink(::Poisson) = LogLink()

# For the "odd" link functions we evaluate the linear predictor such that mu is closest to zero where the precision is higher
function glmvar(::Binomial, link::@compat(Union{CauchitLink,InverseLink,LogitLink,ProbitLink}), μ, η)
    μ = linkinv(link, ifelse(η < 0, η, -η))
    μ*(1-μ)
end
glmvar(::Binomial, ::Link, μ, η) = μ*(1-μ)
glmvar(::Gamma, ::Link, μ, η) = abs2(μ)
glmvar(::Normal, ::Link, μ, η) = 1
glmvar(::Poisson, ::Link, μ, η) = μ

mustart(::Binomial, y, wt) = (wt*y + oftype(y,0.5))/(wt + one(y))
mustart(::Gamma, y, wt) = y
mustart(::Normal, y, wt) = y
mustart(::Poisson, y, wt) = y + oftype(y, 0.1)

function devresid(::Binomial, y, μ, wt)
    if y == 1
        return 2.0*wt*-log(μ)
    elseif y == 0
        return -2.0*wt*log1p(-μ)
    else
        return 2.0*wt*(y*(log(y) - log(μ)) + (1 - y)*(log1p(-y) - log1p(-μ)))
    end
end
devresid(::Gamma, y, μ, wt) = -2wt * (log(y/μ) - (y - μ)/μ)
devresid(::Normal, y, μ, wt) = wt * abs2(y - μ)
devresid(::Poisson, y, μ, wt) = 2wt * (xlogy(y,y/μ) - (y - μ))
