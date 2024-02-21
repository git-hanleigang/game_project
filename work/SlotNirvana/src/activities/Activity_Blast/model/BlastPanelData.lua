--blast每章节的数据
local ShopItem = require "data.baseDatas.ShopItem"
local BlastPanelData = class("BlastPanelData")

-- message BlastPanelDetail {
--   optional int32 stage = 1; // 对应的第几章节
--   optional string status = 2; //状态  COMPLETED,PLAY,LOCKED
--   optional int64 coins = 3; //奖励金币
--   repeated ShopItem rewards = 4; //其他奖励物品
--   repeated int32 boxes = 5; //箱子数据
--   optional string icons = 6; //图标 200事件箱子
--   optional int32 stageCoins = 7; //章节奖励加成
--   optional int64 baseCoins = 8; //基础奖励金币
--   optional int32 currentClearItems = 9;
--   optional int32 totalClearItems = 10;
--   optional bool affairPick = 11; // 三选一
--   repeated int32 affairOpen = 12; // 连续开箱子
--   repeated int32 affairLight = 13; // 高亮箱子
--   optional string baseCoinsV2 = 14; //基础奖励金币V2
--   optional string coinsV2 = 15; //奖励金币V2
-- }

function BlastPanelData:ctor()
    self.m_coins = toLongNumber(0)
    self.m_baseCoins = toLongNumber(0)
end

function BlastPanelData:parseData(data)
    self.m_stage = data.stage
    self.m_status = data.status
    if data.coinsV2 and data.coinsV2 ~= "" and data.coinsV2 ~= "0" then
        self.m_coins:setNum(data.coinsV2)
    else
        self.m_coins:setNum(data.coins)
    end
    if data.baseCoinsV2 and data.baseCoinsV2 ~= "" and data.baseCoinsV2 ~= "0" then
        self.m_baseCoins:setNum(data.baseCoinsV2)
    else
        self.m_baseCoins:setNum(data.baseCoins)
    end
    self.m_stageCoins = data.stageCoins
    self.m_currentClearItems = data.currentClearItems
    self.m_totalClearItems = data.totalClearItems
    self.m_affairPick = data.affairPick
    self.m_affOpen = {}
    if data.affairOpen and #data.affairOpen > 0 then
        for i,v in ipairs(data.affairOpen) do
            table.insert(self.m_affOpen,v)
        end
    end
    self.m_affairLight = {}
    if data.affairLight and #data.affairLight > 0 then
        for i,v in ipairs(data.affairLight) do
            table.insert(self.m_affairLight,v)
        end
    end
    self.m_rewards = {}
    if data.rewards and #data.rewards > 0 then
        for i,v in ipairs(data.rewards) do
            local shopItem = ShopItem:create()
            shopItem:parseData(v, true)
            table.insert(self.m_rewards,shopItem)
        end
    end
    self:parseBoxesData(data)
end

function BlastPanelData:parseBoxesData(_data)
    local iconList = string.split(_data.icons,";")
    self.m_box = {}
    for i,v in ipairs(_data.boxes) do
        local box_data = {}
        box_data.state = v -- 箱子状态
        box_data.iconId = 0
        if iconList and iconList[i] and iconList[i] ~= "" then
            box_data.iconId = tonumber(iconList[i]) -- 箱子图标
        end
        table.insert(self.m_box,box_data)
    end
end

function BlastPanelData:getStage()
    return self.m_stage or 1
end

function BlastPanelData:getStatus()
    return self.m_status or "PLAY"
end

function BlastPanelData:getCoins()
    return self.m_coins
end

function BlastPanelData:getBaseCoins()
    return self.m_baseCoins
end

function BlastPanelData:getStageCoins()
    return self.m_stageCoins or 0
end

function BlastPanelData:getCurrentClear()
    return self.m_currentClearItems or 0
end

function BlastPanelData:getTotalClear()
    return self.m_totalClearItems or 0
end

function BlastPanelData:getAffairPick()
    return self.m_affairPick or false
end

function BlastPanelData:getAffOpen()
    return self.m_affOpen
end

function BlastPanelData:getAffairLight()
    return self.m_affairLight
end

function BlastPanelData:getRewards()
    return self.m_rewards
end

function BlastPanelData:getBoxs()
    return self.m_box
end
return BlastPanelData
