local function binary(sym)
    return function(a, b)
        _tick_ops(1, sym)
        a = _unwrap(a)
        b = _unwrap(b)
        local ok, res = pcall(function()
            return ({
                ["+"] = function() return a + b end,
                ["-"] = function() return a - b end,
                ["*"] = function() return a * b end,
                ["/"] = function() return a / b end,
                ["^"] = function() return a ^ b end,
                [".."] = function() return a .. b end,
            })[sym]()
        end)
        -- log("OP", string.format("[HOOK] %s %s %s => %s", _stringify(a), sym, _stringify(b), ok and _stringify(res) or "error"))
        if ok then return _spy_value(res, rawget(t, "__name") .. sym) end
    end
end
