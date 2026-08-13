branch = {
    alpha = 'Alpha',
    beta = 'Beta',
    release = 'Release'
}

version = {
    major = 4,
    minor = 0,
    branch = branch.alpha
}

function getVersionString()
    return version.major .. '.' .. version.minor .. ' ' .. version.branch
end

function getVersionNumber()
    return version.major * 1000 + version.minor
end