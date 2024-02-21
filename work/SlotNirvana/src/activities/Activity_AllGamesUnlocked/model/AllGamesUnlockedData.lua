--[[--
    商城优惠券活动
    活动开启后商场金币后边会增加一个extra的折扣力度标识
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local AllGamesUnlockedData = class("AllGamesUnlockedData", BaseActivityData)

function AllGamesUnlockedData:ctor()
    AllGamesUnlockedData.super.ctor(self)
    self.p_open = true
end

return AllGamesUnlockedData
