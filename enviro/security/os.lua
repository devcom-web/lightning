local _safe_os = {}
if os then
    _safe_os.clock = os.clock
    _safe_os.time = os.time
    _safe_os.difftime = os.difftime
end
rawset(_G, "os", _safe_os)
