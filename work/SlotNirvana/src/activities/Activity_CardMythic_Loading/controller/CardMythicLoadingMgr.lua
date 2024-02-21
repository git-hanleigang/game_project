--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-06-29 17:21:54
]]
local CardMythicLoadingMgr = class("CardMythicLoadingMgr", BaseActivityControl)

function CardMythicLoadingMgr:ctor()
    CardMythicLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CardMythicLoading)
end

function CardMythicLoadingMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function CardMythicLoadingMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function CardMythicLoadingMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return CardMythicLoadingMgr
