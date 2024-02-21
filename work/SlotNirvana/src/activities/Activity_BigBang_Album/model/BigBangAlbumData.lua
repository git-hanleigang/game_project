--[[
    膨胀宣传 集卡
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local BigBangAlbumData = class("BigBangAlbumData", BaseActivityData)

function BigBangAlbumData:ctor()
    BigBangAlbumData.super.ctor(self)
    self.p_open = true
end

return BigBangAlbumData