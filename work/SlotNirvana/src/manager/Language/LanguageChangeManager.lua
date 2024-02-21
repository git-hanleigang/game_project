--[[
    多语言却换控制
]]
local LanguageChangeManager = class("LanguageChangeManager")

function LanguageChangeManager:ctor()
    self.m_systemLanguage = "English"
    local languageListPath = "Language/Language" .. self.m_systemLanguage
    if util_IsFileExist(languageListPath .. ".lua") or util_IsFileExist(languageListPath .. ".luac") then
        local path, count = string.gsub(languageListPath, "/", ".")
        self.m_systemLanguageList = require(path)
    end
end

function LanguageChangeManager:getInstance()
    if not self._instance then
        self._instance = LanguageChangeManager:create()
    end
    return self._instance
end

function LanguageChangeManager:getStringByKey(_key)
    local string = ""
    if self.m_systemLanguageList then
        string = self.m_systemLanguageList[_key] or ""
    end
    return string
end

function LanguageChangeManager:getLanguageType()
    return self.m_systemLanguage
end

return LanguageChangeManager
