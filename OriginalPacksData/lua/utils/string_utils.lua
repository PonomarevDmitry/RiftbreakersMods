function StringTable(str)
    strc = {}
    for i = 1, #str do
        table.insert(strc, string.sub(str, i, i))
    end
    return strc
end

function IsNullOrEmpty( str )
    if str == nil then
        return true
    end

    return str == ""
end

function Split(string, separator)
    if separator == nil then
            separator = "%s"
    end
    
    local tokens = {} ; index = 1
    for token in string.gmatch(string, "([^"..separator.."]+)") do
        tokens[index] = token
        index = index + 1
    end
    
    return tokens
end


return function(...)
end