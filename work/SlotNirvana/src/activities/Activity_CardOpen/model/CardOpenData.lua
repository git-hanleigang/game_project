--[[--
    集卡新赛季开启 数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local CardOpenData = class("CardOpenData", BaseActivityData)
function CardOpenData:ctor()
    CardOpenData.super.ctor(self)
    self.p_open = true
end
return CardOpenData
