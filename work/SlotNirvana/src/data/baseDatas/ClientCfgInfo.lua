--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-04-03 20:52:56
]]
local ClientCfgInfo = class("")

function ClientCfgInfo:ctor()
end

function ClientCfgInfo:parseData(info)
    self.m_key = info.clientKey
    self.m_value = info.clientValue
    self.m_start = info.start or ""
    self.m_over = info["end"] or ""
end

function ClientCfgInfo:getKey()
    return self.m_key
end

function ClientCfgInfo:getValue()
    return self.m_value
end

function ClientCfgInfo:isExpire()
    if self.m_start == "" and self.m_over == "" then
        return true
    end

    local _curTime = math.floor(util_getCurrnetTime())
    local _startT = 0
    local _overT = 0
    if self.m_start ~= "" then
        _startT = util_getymd_time(self.m_start)
        if _curTime < _startT then
            return false
        end
    end
    if self.m_over ~= "" then
        _overT = util_getymd_time(self.m_over)
        if _curTime > _overT then
            return false
        end
    end

    return true
end

return ClientCfgInfo
