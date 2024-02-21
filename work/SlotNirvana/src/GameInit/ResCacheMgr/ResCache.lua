--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-01-18 14:26:58
]]
local ResCache = class("ResCache")

function ResCache:ctor()
    self.m_ref = 0
    self.m_name = ""
end

function ResCache:parseData(path)
    self.m_name = path
end

function ResCache:cleanup()
end

function ResCache:getName()
    return self.m_name
end

function ResCache:getRef()
    return self.m_ref
end

function ResCache:addRef()
    self.m_ref = self.m_ref + 1
end

function ResCache:decRef()
    self.m_ref = self.m_ref - 1
    if self.m_ref < 0 then
        self.m_ref = 0
    end
end

return ResCache
