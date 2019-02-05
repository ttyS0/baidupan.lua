return function(t1, t2)
    local t = {}
    for k, v in pairs(t1) do t[k] = v end
    for k, v in pairs(t2) do t[k] = v end
    return t
end
