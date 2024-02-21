-- 活动任务(只是一个弹板， 有这个活动open 就为true)
local BaseActivityData = require("baseActivity.BaseActivityData")
local CardsOneKeyRecoverData = class("CardsOneKeyRecoverData", BaseActivityData)

function CardsOneKeyRecoverData:ctor()
    CardsOneKeyRecoverData.super.ctor(self)
    self.p_open = true
end
return CardsOneKeyRecoverData


