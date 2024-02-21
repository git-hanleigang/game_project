--[[
]]

local ShopItem = util_require("data.baseDatas.ShopItem")
local ObsidianWheelGridData = import(".ObsidianWheelGridData")
local ObsidianWheelPayData = import(".ObsidianWheelPayData")

local BaseActivityData = require("baseActivity.BaseActivityData")
local ObsidianWheelData = class("ObsidianWheelData",BaseActivityData)

function ObsidianWheelData:ctor()
    ObsidianWheelData.super.ctor(self)
end


-- // 黑曜卡 抽奖转盘
-- message ShortCardDraw {
--     optional string name = 1;
--     optional string activityId = 2;
--     optional int32 process = 3;//进度
--     optional int32 total = 4;// 进度最大值
--     repeated ShopItem items = 5; //累计奖励
--     optional int32 leftFreeTime = 6;// 免费奖励可领取剩余次数
--     optional ShortCardDrawPayConfig lowPrice = 7; //单抽价格
--     optional ShortCardDrawPayConfig highPrice = 8; //连抽价格
--     optional int32 discount = 9; // 连抽折扣
--     optional int32 hitIndex = 10; // 单抽命中索引,（不是免费的索引，免费的现算）
--     repeated int32 hitTenIndex = 11; //连抽的命中索引
--     repeated ShortCardDrawReward girds = 12; //格子奖励
--     optional int32 highSpinNum = 13; // 连抽付费可以抽几次
--     optional int32 luckyDogs = 14; //可或得全卡册的人数
--     optional int64 expireAt = 15;
--     optional int32 expire = 16;
--   }
function ObsidianWheelData:parseData(_netData)
    ObsidianWheelData.super.parseData(self, _netData)

    self.p_name = _netData.name
    self.p_activityId = _netData.activityId
    self.p_process = _netData.process
    self.p_total = _netData.total

    self.p_progressItems = {}
    if _netData.items and #_netData.items > 0 then
        for i = 1, #_netData.items do
            local itemData = ShopItem:create()
            itemData:parseData(_netData.items[i])
            table.insert(self.p_progressItems, itemData)
        end
    end

    self.p_leftFreeTime = _netData.leftFreeTime

    self.p_lowPrice = nil
    if _netData:HasField("lowPrice") then
        local payData = ObsidianWheelPayData:create()
        payData:parseData(_netData.lowPrice)
        self.p_lowPrice = payData
    end
    
    self.p_highPrice = nil
    if _netData:HasField("highPrice") then
        local payData = ObsidianWheelPayData:create()
        payData:parseData(_netData.highPrice)
        self.p_highPrice = payData
    end

    self.p_discount = _netData.discount
    self.p_hitIndex = _netData.hitIndex + 1 -- 从0开始
    
    self.p_hitTenIndex = {}
    if _netData.hitTenIndex and #_netData.hitTenIndex > 0 then
        for i = 1, #_netData.hitTenIndex do
            table.insert(self.p_hitTenIndex, _netData.hitTenIndex[i] + 1) -- 从0开始
        end
    end
    
    self.p_grids = {}
    if _netData.girds and #_netData.girds > 0 then
        for i = 1, #_netData.girds do
            local grid = ObsidianWheelGridData:create()
            grid:parseData(_netData.girds[i])
            table.insert(self.p_grids, grid)
        end
    end

    self.p_highSpinNum = _netData.highSpinNum
    self.p_luckyDogs = _netData.luckyDogs
end

function ObsidianWheelData:getName()
    return self.p_name
end

function ObsidianWheelData:getActivityId()
    return self.p_activityId
end

function ObsidianWheelData:getProcess()
    return self.p_process
end

function ObsidianWheelData:getTotal()
    return self.p_total
end

function ObsidianWheelData:getProgressItems()
    return self.p_progressItems
end

function ObsidianWheelData:getLeftFreeTime()
    return self.p_leftFreeTime
end

function ObsidianWheelData:getLowPrice()
    return self.p_lowPrice
end

function ObsidianWheelData:getHighPrice()
    return self.p_highPrice
end

function ObsidianWheelData:getDiscount()
    return self.p_discount
end

function ObsidianWheelData:getHitIndex()
    return self.p_hitIndex
end

function ObsidianWheelData:getHitTenIndex()
    return self.p_hitTenIndex
end

function ObsidianWheelData:getGrids()
    return self.p_grids
end

function ObsidianWheelData:getHighSpinNum()
    return self.p_highSpinNum
end

function ObsidianWheelData:getLuckyDogs()
    return self.p_luckyDogs
end

function ObsidianWheelData:isRunning()
    return ObsidianWheelData.super.isRunning(self)
end

function ObsidianWheelData:getGridByIndex(_index)
    local grids = self:getGrids()
    if _index and grids and #grids > 0 and _index <= #grids then
        return grids[_index]
    end
    return nil
end



return ObsidianWheelData
