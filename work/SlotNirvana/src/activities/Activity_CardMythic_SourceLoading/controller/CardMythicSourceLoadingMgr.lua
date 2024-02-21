--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-06-29 17:21:54
]]
local CardMythicSourceLoadingMgr = class("CardMythicSourceLoadingMgr", BaseActivityControl)

function CardMythicSourceLoadingMgr:ctor()
    CardMythicSourceLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CardMythicSourceLoading)
end

function CardMythicSourceLoadingMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName .. "HallNode"
end

function CardMythicSourceLoadingMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName .. "SlideNode"
end

function CardMythicSourceLoadingMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return CardMythicSourceLoadingMgr
