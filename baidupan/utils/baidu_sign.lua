local sign2 = function(j, r)
    local a = {}
    local p = {}
    local o = ""
    local v = string.len(j)
    local u, q, i
    for q = 0, 255 do
        a[q] = j:byte(q % v + 1)
        p[q] = q
    end
    u = 0; q = 0
    while true do
        if q >= 256 then break end
        u = (u + p[q] + a[q]) % 256
        local t = p[q]
        p[q] = p[u]
        p[u] = t
        q = q + 1
    end
    i = 0; u = 0; q = 0
    while true do
        if q >= string.len(r) then break end
        i = (i + 1) % 256
        u = (u + p[i]) % 256
        local t = p[i]
        p[i] = p[u];
        p[u] = t;
        k = p[(p[i] + p[u]) % 256]
        o = o .. string.char(r:byte(q + 1) ~ k)
        q = q + 1
    end
    return o
end

return {
    sign2 = sign2
}
