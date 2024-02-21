--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-05-24 12:28:27
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local ScratchCardsCountDownData = class("ScratchCardsCountDownData", BaseActivityData)

function ScratchCardsCountDownData:ctor()
    ScratchCardsCountDownData.super.ctor(self)
    self.p_open = true
end

return ScratchCardsCountDownData