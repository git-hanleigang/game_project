--[[
Author: cxc
Date: 2022-01-26 14:34:41
LastEditTime: 2022-01-26 14:34:43
LastEditors: cxc
Description: bingo 比赛 宣传活动 数据
FilePath: /SlotNirvana/src/activities/Activity_BingoRush/model/BingoRushLoadingData.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local BingoRushLoadingData = class("BingoRushLoadingData", BaseActivityData)

function BingoRushLoadingData:ctor()
    BingoRushLoadingData.super.ctor(self)
    self.p_open = true
end

-- 是否可显示弹板
function BingoRushLoadingData:isCanShowPopView()
    if not BingoRushLoadingData.super.isCanShowPopView(self) then
        return false
    end

    local mrg = G_GetMgr(ACTIVITY_REF.BingoRush)
    if mrg then
        return mrg:isRunning() 
    end

    return true
end

return BingoRushLoadingData