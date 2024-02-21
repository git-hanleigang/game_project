--[[--
    FB小组宣传活动 数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local FBGroupData = class("FBGroupData", BaseActivityData)

function FBGroupData:ctor()
    FBGroupData.super.ctor(self)
    self.p_open = true
end

return FBGroupData