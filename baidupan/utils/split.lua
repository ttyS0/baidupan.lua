return function(str, delimiter)
    local result = {}
    for match in (str .. delimiter:gsub("%%", "")):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end
