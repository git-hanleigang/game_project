--[[
Author: cxc
Date: 2021-02-19 15:29:44
LastEditTime: 2021-02-19 15:29:45
LastEditors: your name
Description: 常规促销小游戏
FilePath: /SlotNirvana/src/data/baseDatas/SuperSaleLuckyChooseData.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local SuperSaleLuckyChooseData = class("SuperSaleLuckyChooseData", BaseActivityData)

function SuperSaleLuckyChooseData:ctor()
    SuperSaleLuckyChooseData.super.ctor(self)
    self.p_open = true
end

--  首购促销存在的时候 隐藏这个弹板
function SuperSaleLuckyChooseData:isRunning()
    local bOpen = SuperSaleLuckyChooseData.super.isRunning(self)
    if not bOpen then
        return false
    end
    
    -- 首冲促销
    local bOpenFirstSale = G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData()
    if bOpenFirstSale then
        return false
    end

    -- 常规促销
    local commSaleData = G_GetMgr(G_REF.SpecialSale):getRunningData()
    if not commSaleData then
        return false
    end

    local miniGameUsd = commSaleData:getMiniGameUsd()
    if tonumber(miniGameUsd) <= 0 then
        -- 没有 小游戏专用 数值
        return false
    end

    return true
end

return SuperSaleLuckyChooseData
