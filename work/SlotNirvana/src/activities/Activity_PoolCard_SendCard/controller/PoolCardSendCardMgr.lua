--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-07-03 11:14:22
]]

local PoolCardSendCardMgr = class("PoolCardSendCardMgr", BaseActivityControl)

function PoolCardSendCardMgr:ctor()
    PoolCardSendCardMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PoolCard_SendCard)
end

return PoolCardSendCardMgr
