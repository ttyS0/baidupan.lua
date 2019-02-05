return function(str)
    if type(str) == "string" then return str:gsub("^%s*(.-)%s*$", "%1")
    else return nil
    end
end
