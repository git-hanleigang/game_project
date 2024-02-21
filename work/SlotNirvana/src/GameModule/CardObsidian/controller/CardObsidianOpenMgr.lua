--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-10-17 16:40:00
]]
local CardObsidianOpenMgr = class("CardObsidianOpenMgr", BaseActivityControl)

function CardObsidianOpenMgr:ctor()
    CardObsidianOpenMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CardObsidianOpen)
end

return CardObsidianOpenMgr