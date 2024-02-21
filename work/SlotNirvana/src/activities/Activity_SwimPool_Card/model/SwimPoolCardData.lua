--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-06-30 14:11:59
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local SwimPoolCardData = class("SwimPoolCardData", BaseActivityData)

function SwimPoolCardData:ctor()
    SwimPoolCardData.super.ctor(self)
    self.p_open = true
end

return SwimPoolCardData
