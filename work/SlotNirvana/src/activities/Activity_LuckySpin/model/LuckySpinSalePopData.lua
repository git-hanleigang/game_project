--[[
Author: cxc
Date: 2021-04-01 15:21:53
LastEditTime: 2021-04-08 14:57:40
LastEditors: Please set LastEditors
Description: In User Settings Edit
FilePath: /SlotNirvana/src/data/luckySpin/LuckySpinSalePopData.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local LuckySpinSalePopData = class("LuckySpinSalePopData", BaseActivityData)
function LuckySpinSalePopData:ctor()
    LuckySpinSalePopData.super.ctor(self)

    self.p_open = true
end

function LuckySpinSalePopData:isRunning()
    if not LuckySpinSalePopData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end
    return true
end

-- 检查完成条件
function LuckySpinSalePopData:checkCompleteCondition()
    return not globalData.shopRunData:getLuckySpinIsOpen()  
end

return LuckySpinSalePopData