Framework = {}

local Detectable = {
    { Name = 'qbx', Resource = 'qbx_core' },
    { Name = 'qbcore', Resource = 'qb-core' },
    { Name = 'esx', Resource = 'es_extended' },
}

local ValidNames = { esx = true, qbcore = true, qbx = true, custom = true }

local function isRunning(Resource)
    local State = GetResourceState(Resource)

    return State == 'started' or State == 'starting'
end

local function detectFramework()
    for Index = 1, #Detectable do
        local Candidate = Detectable[Index]

        if isRunning(Candidate.Resource) then return Candidate.Name end
    end

    return 'custom'
end

local function resolveFramework()
    local Configured = Config.framework

    if Configured == nil or Configured == 'auto' then return detectFramework() end

    if not ValidNames[Configured] then
        print(('^1[ars_ambulancejob] unknown Config.framework "%s", falling back to auto detection^7'):format(tostring(Configured)))
        return detectFramework()
    end

    return Configured
end

Framework.Name = resolveFramework()

function Framework.isFramework(...)
    local Names = { ... }

    for Index = 1, #Names do
        if Framework.Name == Names[Index] then return true end
    end

    return false
end

function Framework.matchesJob(Current, Jobs)
    if type(Jobs) ~= 'table' then return Current == Jobs end

    for Index = 1, #Jobs do
        if Jobs[Index] == Current then return true end
    end

    return false
end
