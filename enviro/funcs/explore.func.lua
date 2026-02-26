local function explore_function(f, known_name)
    if type(f) ~= "function" then return tostring(f) end
    local info = debug.getinfo(f, "nSlu")
    if not info then return "function" end
    
    -- try to find 'real' name in _G
    local name = nil
    for k, v in pairs(_G) do
        if v == f and k ~= known_name and type(k) == "string" then
            name = k
            break
        end
    end
    
    if not name then
        for libname, lib in pairs(_G) do
            if type(lib) == "table" and libname ~= "_G" and libname ~= "package" then
                for k, v in pairs(lib) do
                    if v == f and k ~= known_name and type(k) == "string" then
                        name = libname .. "." .. k
                        break
                    end
                end
            end
            if name then break end
        end
    end

    name = name or info.name or known_name
    
    if not name then
        for level = 3, 10 do
            local info = debug.getinfo(level, "f")
            if not info then break end
            local i = 1
            while true do
                local n, v = debug.getlocal(level, i)
                if not n then break end
                if v == f then 
                    name = n 
                    break 
                end
                i = i + 1
            end
            if name then break end
        end
    end
    
    if info.what == "C" then 
        return name or "anonymous" 
    end
    
    local probe_info = probe_function(f)
    
    local lines = get_source_lines()
    local src_body = nil
    if lines and info.linedefined > 0 and info.lastlinedefined > 0 then
        local body = {}
        local min_indent = 999
        
        for i = info.linedefined, info.lastlinedefined do
            local line = lines[i]
            if line and line:match("%S") then
                local indent = line:match("^%s*")
                if #indent < min_indent then min_indent = #indent end
            end
            table.insert(body, line or "")
        end
        
        for i = 1, #body do
            body[i] = body[i]:sub(min_indent + 1)
        end
        
        local full_body = table.concat(body, " ")
        full_body = full_body:gsub("%s+", " ")
        full_body = full_body:match("^%s*(.-)%s*$") or full_body
        
        src_body = full_body
    end
    
    local body_display = src_body or "[no source]"
    
    -- upvals
    local upvalues = {}
    local i = 1
    while true do
        local n, v = debug.getupvalue(f, i)
        if not n then break end
        if n ~= "" then
            local v_str = serialize_table(v, 3, true) 
            table.insert(upvalues, n .. "=" .. v_str)
        end
        i = i + 1
    end
    
    -- func hash
    local hash_str = ""
    if string.dump then
        local ok, dump = pcall(string.dump, f)
        if ok then
            local hash = 5381
            for i = 1, #dump do
                hash = bit32.bor(bit32.lshift(hash, 5) + hash, string.byte(dump, i))
            end
            hash_str = string.format(" #%08X", hash)
        end
    end
    
    local upval_comment = #upvalues > 0 and (" [uv: " .. table.concat(upvalues, ", ") .. "]") or ""
    local src_info = ""
    
    if info.source and info.source:sub(1,1) == "@" then
        src_info = string.format(" %s:%d", info.source:sub(2), info.linedefined)
    else
        src_info = string.format(" line:%d", info.linedefined)
    end
    
    return string.format("function(%s) %s%s%s%s%s", 
        table.concat(table.create(info.nparams or 0, "_"), ", "), 
        body_display, 
        src_info, 
        hash_str,
        upval_comment, 
        probe_info)
end
mark_internal(explore_function)


--[[
                              NOTE
    This is ripped from unvelir 1.0.6 but modified slightly.
--]]
