abstract type AbstractCorrection{Tf <: Real} end

abstract type AbstractPrecip{Tf} <: AbstractCorrection{Tf} end

Base.@kwdef struct MaxBiasPrecip{Tf} <: AbstractPrecip{Tf}
    mult::Tf = 1
end

Base.@kwdef struct LinearPrecip{Tf} <: AbstractPrecip{Tf}
    mult::Tf = 0.00014
    cst::Tf = 0.68
end

Base.@kwdef struct LogPrecip{Tf} <: AbstractPrecip{Tf}
    mult1::Tf = 0.008
    mult2::Tf = -0.35
    cst::Tf = 2
end

Base.@kwdef struct LogbisPrecip{Tf} <: AbstractPrecip{Tf}
    mult1::Tf = -0.012
    mult2::Tf = 0.38
    cst::Tf = 45
end

Base.@kwdef struct ExpPrecip{Tf} <: AbstractPrecip{Tf}
    mult1::Tf = -0.002
    mult2::Tf = 2.5
    cst::Tf = 0.9
    
end

Base.@kwdef struct TanhPrecip{Tf} <: AbstractPrecip{Tf}
    mult2::Tf = -0.662
    mult1::Tf = 0.002
    alt0::Tf = 1450/0.76
    cst::Tf = 1.116
end

@inline precip_cor(c::MaxBiasPrecip{Tf}, bias_list) where {Tf} = Tf.(bias_list) .* c.mult

@inline precip_cor(c::LinearPrecip{Tf}, elevation) where {Tf} = Tf.(elevation) .* c.mult .+ c.cst

@inline precip_cor(c::LogPrecip{Tf}, elevation) where {Tf} =
    log.(max.(Tf.(elevation), one(Tf)) .* c.mult1) .* c.mult2 .+ c.cst

@inline precip_cor(c::LogbisPrecip{Tf}, elevation) where {Tf} =
    log.(max.(Tf.(elevation), one(Tf)) .* c.mult1 .+ c.cst) .* c.mult2

@inline precip_cor(c::ExpPrecip{Tf}, elevation) where {Tf} = 1 ./ (c.mult2 .* exp.(Tf.(elevation) .* c.mult1) .+ c.cst)

@inline precip_cor(c::TanhPrecip{Tf}, elevation) where {Tf} =
    c.mult2 .* tanh.((Tf.(elevation) .- c.alt0) .* c.mult1) .+ c.cst

build_precip(::Type{T}, Tf) where {T} = T{Tf}()                        # bare type: defaults
build_precip(s::SchemeSpec{T}, Tf) where {T} = T{Tf}(; s.kwargs...)    # spec: your parameters