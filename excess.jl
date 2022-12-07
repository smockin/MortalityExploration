module ExcessMortality

using DataFrames
using Arrow
using CSV
using Dates
using Preferences
using ZipFile
using ShiftedArrays
using DBInterface
using SQLite
using Markdown
using Printf

export Site,
    setinputdir, setoutputdir, setworkdir, setlegalstarts, getlegalstarts, setlegalends, seteventsequence, setendyear, setearlydobyr,
    getoutputpath, getdatapath, getlegalends, setlegaltransitions, getlegaltransitions, getsites, geteventsequence, getendyear, getearlydob,
    getmicrodata, isvalidtransition,
    eventsummary, starteventsummary, endeventsummary, eventtransitionsummary, eventyearsummary, sexsummary, dobsummary, mortalitysummary,
    eventtransitioncrosstab, create_censoredepisodes, create_age_yearepisodes, monthsummary,
    getqcdatabase, save_starteventsummary, save_endeventsummary, save_transitionsummary, save_eventsummary, save_sexsummary, save_dobsummary, save_mortalitysummary,
    get_qcmetric_summary, get_event_summary, get_startevents, get_endevents, get_transitionmatrix, get_sex, get_dob, 
    get_mortality, get_mortality_summary, get_annual_summary,
    markdown_transitionmatrix, markdown_qcsummary, markdown_eventsummary, markdown_events, markdown_sex, markdown_dob,
    render_sitereport, markdown_mortality, markdown_annual_mortality, markdown_monthsummary,
    split_data_tst

struct Site
    site::String
    country::String
    name::String
    start::Int64
    hasdata::Bool
end
"Set the last valid year for the data"
function setendyear(year::Integer)
    @set_preferences!("endyear" => year)
end
"Get the last valid year for the data"
function getendyear()::Integer
    @load_preference("endyear", 2022)
end
"Set earliest valid DoB"
function setearlydobyr(year::Integer)
    @set_preferences!("earlydobyr" => year)
end
"Get earliest valid DoB"
function getearlydob()::Date
    yr = @load_preference("earlydobyr", 1850)
    return Date(yr)
end
"Set the data directory"
function setinputdir(path::String)
    @set_preferences!("inputdirectory" => path)
end
function getinputdir()
    @load_preference("inputdirectory", "D:\\Data\\ExcessMortality.input")
end
"Set the directory within data directory where output files are stored"
function setoutputdir(directory::String)
    @set_preferences!("outputdirectory" => directory)
end
function getoutputdir()
    @load_preference("outputdirectory","D:\\Data\\ExcessMortality.output")
end
function setworkdir(directory::String)
    @set_preferences!("workingdirectory" => directory)
end
function getworkdir()
    path = @load_preference("workingdirectory","D:\\Data\\ExcessMortality.work\\OutputData")
    if !ispath(path)
        mkpath(path)
    end
    return path
end
function getoutputpath(work=false)
    return work ? getworkdir() : getoutputdir()
end
"Construct data path from site name"
function getdatapath(site::String, work = true)
    path = joinpath(getoutputpath(work), site)
    if !ispath(joinpath(path,"QA"))
        mkpath(joinpath(path,"QA"))
    end
    return path
end
"Set legal starting events"
function setlegalstarts(legalstarts)
    @set_preferences!("legal_start_events" => legalstarts)
end
"Get legal starting events"
function getlegalstarts()
    @load_preference("legal_start_events", [])
end
"Set legal end events"
function setlegalends(legalends)
    @set_preferences!("legal_end_events" => legalends)
end
"Get legal end events"
function getlegalends()
    @load_preference("legal_end_events", [])
end
"Set legal transitions"
function setlegaltransitions(legaltransitions::Dict)
    @set_preferences!("legal_transitions" => (legaltransitions))
end
"""
Get a dictionary of event codes and each dictionary valye containing an array with the allowed eventcodes which follow this event, 
a ""MIS"" eventcode signifies that this can be the last event in a sequence.
"""
function getlegaltransitions()::Dict{String,Vector{String}}
    @load_preference("legal_transitions", Dict([]))
end
"Set event sequence"
function seteventsequence(eventsequence)
    @set_preferences!("event_sequence" => eventsequence)
end
"Get event sequence"
function geteventsequence()
    @load_preference("event_sequence", [])
end
function getsites()::Dict{String,Site}
    sitedict = @load_preference("sites", Dict())
    sites = Dict{String,Site}()
    for (key, value) in sitedict
        if value != nothing
            push!(sites, key => Site(key, value["Country"], value["Name"], value["StartYear"], false))
        end
    end
    return sites
end
"Calculates age in completed years at referefence date"
function age(dob::Date, date::Date)
    return Dates.year(date) - Dates.year(dob) - ((Dates.Month(date) < Dates.Month(dob)) || (Dates.Month(date) == Dates.Month(dob) && Dates.Day(date) < Dates.Day(dob)))
end
include("readdata.jl")
include("qcdatabase.jl")
include("qcdisplay.jl")

end # module
