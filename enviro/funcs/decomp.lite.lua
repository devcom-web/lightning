local _source_lines = nil
local function get_source_lines()
    if _source_lines then return _source_lines end
    if not __script_source then return nil end
    _source_lines = {}
    for line in __script_source:gmatch("([^\10]*)\10?") do
        table.insert(_source_lines, line)
    end
    return _source_lines
end
mark_internal(get_source_lines)

--[[
                      NOTE
  This barely works and is rarely used in production.
--]]
