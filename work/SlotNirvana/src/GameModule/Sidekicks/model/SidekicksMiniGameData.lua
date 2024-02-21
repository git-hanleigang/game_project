--[[
    
]]

local ShopItem = require "data.baseDatas.ShopItem"
local SidekicksMiniGameData = class("SidekicksMiniGameData")

function SidekicksMiniGameData:ctor()
    self.p_canPlay = false
    self.p_wheels = {}
end

-- message SidekicksDailyReward {
--     optional bool canPlay = 1;// 是否可玩
--     repeated SidekicksDailyRewardWheel wheels = 2;// 转盘
--     optional int32 unlockLevel = 3;// 等级经验
--     repeated SidekicksDailyRewardWheel lastWheels = 4;// 上一等级的转盘
--     optional int64 expireAt = 5;// 过期时间
--   }
function SidekicksMiniGameData:parseData(_data)
    self.p_canPlay = _data.canPlay
    self.p_unlockLevel = _data.unlockLevel
    self.p_expireAt = _data.expireAt
    self.p_wheels = self:parseWheelData(_data.wheels)
    self.p_lastWheels = self:parseWheelData(_data.lastWheels)
end

-- message SidekicksDailyRewardWheel {
--     optional int32 wheel = 1;// 转盘层级
--     optional bool lock = 2;// 是否上锁
--     repeated SidekicksDailyRewardCell cells = 3;// 本层转盘的格子
--   }
function SidekicksMiniGameData:parseWheelData(_data)
    local list = {}
    for i,v in ipairs(_data) do
        local temp = {}
        temp.p_wheel = v.wheel
        temp.p_lock = v.lock
        temp.p_cells = self:parseCellData(v.cells)
        table.insert(list, temp)
    end
    return list
end

-- message SidekicksDailyRewardCell {
--     optional string type = 1;// 奖励类型 MULTIPLE COINS ITEM
--     repeated ShopItem items = 2;// 物品
--     optional int32 multiple = 3;// 倍数
--     optional string coins = 4;// 金币
--     optional string display = 5;// 展示数据
--   }
function SidekicksMiniGameData:parseCellData(_data)
    local list = {}
    for i,v in ipairs(_data) do
        local temp = {}
        temp.p_type = v.type
        temp.p_multiple = v.multiple
        temp.p_coins = v.coins
        temp.p_display = v.display
        temp.p_items = self:parseItemData(v.items)
        table.insert(list, temp)
    end
    return list
end

function SidekicksMiniGameData:parseItemData(_items)
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function SidekicksMiniGameData:isCanPlay()
    return self.p_canPlay
end

function SidekicksMiniGameData:getWheels()
    return self.p_wheels
end

function SidekicksMiniGameData:getUnlockLevel()
    return self.p_unlockLevel
end

function SidekicksMiniGameData:getLastWheels()
    return self.p_lastWheels
end

function SidekicksMiniGameData:getExpireAt()
    return (self.p_expireAt or 0) / 1000
end

return SidekicksMiniGameData