--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-12-24 15:53:11
]]

local BaseActivityData = require "baseActivity.BaseActivityData"
local LotteryOpenData = class("LotteryOpenData", BaseActivityData)

function LotteryOpenData:ctor(_data)
    LotteryOpenData.super.ctor(self,_data)
    self.p_open = true
end

return LotteryOpenData
