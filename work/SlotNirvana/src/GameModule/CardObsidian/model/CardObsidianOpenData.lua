--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-10-17 16:43:38
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local CardSpecialOpenData = class("CardSpecialOpenData", BaseActivityData)

function CardSpecialOpenData:ctor()
    CardSpecialOpenData.super.ctor(self)
    self.p_open = true
end

return CardSpecialOpenData