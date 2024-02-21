--[[--
    装修活动
    转盘滚动结果
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local RedecorTreasureData = import(".RedecorTreasureData")
local RedecorWheelResultData = class("RedecorWheelResultData")

function RedecorWheelResultData:ctor()
end

function RedecorWheelResultData:parseData(_netData)
    -- 章节奖励金币
    self.p_chapterCoins = 0
    if _netData.chapterCoins and _netData.chapterCoins > 0 then
        self.p_chapterCoins = _netData.chapterCoins
    end
    -- 章节奖励道具
    self.p_chapterItems = {}
    if _netData.chapterItems and #_netData.chapterItems > 0 then
        for i = 1, #_netData.chapterItems do
            local cItem = ShopItem:create()
            cItem:parseData(_netData.chapterItems[i])
            table.insert(self.p_chapterItems, cItem)
        end
    end
    -- 轮次奖励金币
    if _netData.roundCoins and _netData.roundCoins > 0 then
        self.p_roundCoins = _netData.roundCoins
    end
    -- 轮次奖励道具
    self.p_roundItems = {}
    if _netData.roundItems and #_netData.roundItems > 0 then
        for i = 1, #_netData.roundItems do
            local rItem = ShopItem:create()
            rItem:parseData(_netData.roundItems[i])
            table.insert(self.p_roundItems, rItem)
        end
    end
    -- 轮盘停止index
    self.p_hitIndex = {}
    for i = 1, #_netData.hitIndex do
        local index = _netData.hitIndex[i] + 1 -- 服务器是从0开始的
        table.insert(self.p_hitIndex, index)
    end
    -- 轮盘奖励金币
    self.p_wheelCoins = tonumber(_netData.wheelCoins)
    -- 轮盘奖励钻石
    self.p_wheelGems = tonumber(_netData.wheelGems)
    -- 轮盘奖励物品
    self.p_wheelItems = {}
    if _netData.wheelItems and #_netData.wheelItems > 0 then
        for i = 1, #_netData.wheelItems do
            local wItem = ShopItem:create()
            wItem:parseData(_netData.wheelItems[i])
            table.insert(self.p_wheelItems, wItem)
        end
    end
    -- 装修成功赠送的宝箱：立马开启宝箱
    self.p_openNowTreasureOrders = {}
    if _netData.lastTreasures and #_netData.lastTreasures > 0 then
        if #_netData.lastTreasures > 1 then
            release_print("WARNING[MAQUN]:_netData.lastTreasures dont deal multi showTreasureInfoUI")
        end
        for i = 1, #_netData.lastTreasures do
            table.insert(self.p_openNowTreasureOrders, _netData.lastTreasures[i].order)
        end
    end
    -- 装修成功赠送的宝箱：新增宝箱
    self.p_newTreasureOrders = {}
    if _netData.treasures and #_netData.treasures > 0 then
        for i = 1, #_netData.treasures do
            table.insert(self.p_newTreasureOrders, _netData.treasures[i].order)
        end
    end
    -- 轮盘获得的宝箱
    self.p_wheelTreasureOrders = {}
    if _netData.wheelTreasures and #_netData.wheelTreasures > 0 then
        for i = 1, #_netData.wheelTreasures do
            table.insert(self.p_wheelTreasureOrders, _netData.wheelTreasures[i].order)
        end
    end
    -- B组用的，轮盘结束，直接送的礼盒奖励
    self.p_wheelTreasureResult = {}
    if _netData.wheelTreasureResult and #_netData.wheelTreasureResult > 0 then
        for i = 1, #_netData.wheelTreasureResult do
            local trData = RedecorTreasureData:create()
            trData:parseData(_netData.wheelTreasureResult[i])
            table.insert(self.p_wheelTreasureResult, trData)
        end
    end
    -- B组用的，节点完成后，直接送的礼盒奖励
    self.p_nodeTreasureResult = {}
    if _netData.nodeTreasureResult and #_netData.nodeTreasureResult > 0 then
        for i = 1, #_netData.nodeTreasureResult do
            local trData = RedecorTreasureData:create()
            trData:parseData(_netData.nodeTreasureResult[i])
            table.insert(self.p_nodeTreasureResult, trData)
        end
    end
end

function RedecorWheelResultData:getHitIndex()
    -- 服务器从0 开始的
    return self.p_hitIndex
end

function RedecorWheelResultData:getOpenNowTreasureOrders()
    return self.p_openNowTreasureOrders
end

function RedecorWheelResultData:getNewTreasureOrders()
    return self.p_newTreasureOrders
end

function RedecorWheelResultData:getWheelTreasureOrders()
    return self.p_wheelTreasureOrders
end

function RedecorWheelResultData:getWheelTreasureResult()
    return self.p_wheelTreasureResult
end

function RedecorWheelResultData:getNodeTreasureResult()
    return self.p_nodeTreasureResult
end

function RedecorWheelResultData:getTreasures()
    if self.p_openNowTreasureOrders and #self.p_openNowTreasureOrders > 0 then
        return self.p_openNowTreasureOrders
    end
    if self.p_newTreasureOrders and #self.p_newTreasureOrders > 0 then
        return self.p_newTreasureOrders
    end
end

function RedecorWheelResultData:hasChapterCompleteData()
    if self.p_chapterCoins and self.p_chapterCoins > 0 then
        return true
    end
    if self.p_chapterItems and #self.p_chapterItems > 0 then
        return true
    end
    return false
end

function RedecorWheelResultData:hasRoundCompleteData()
    if self.p_roundCoins and self.p_roundCoins > 0 then
        return true
    end
    if self.p_roundItems and #self.p_roundItems > 0 then
        return true
    end
    return false
end

return RedecorWheelResultData
