--[[
    红蓝对决
]]

local BaseActivityRankCfg = require "baseActivity.BaseActivityRankCfg"
local BaseActivityData = require("baseActivity.BaseActivityData")
local FactionFightData = class("FactionFightData", BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"

-- message FactionFight {
--     optional int32 expire = 1;
--     optional int64 expireAt = 2;
--     optional string activityId = 3;
    -- optional string name = 4;
    -- optional string mySide = 5;// 我的阵营
    -- repeated string sides = 6;// 所有阵营
    -- optional int64 winnerPool = 7;// 阵营获胜方奖池
    -- optional int64 consolationPool = 8;// 阵营失败方奖池
    -- optional int32 progress = 9;// 彩金条进度
    -- optional int32 zone = 10;  //排行榜 赛区
    -- optional int32 roomType = 11;  //排行榜 房间类型
    -- optional int32 roomNum = 12;  //排行榜 房间数
    -- optional int32 rankUp = 13; //排行榜排名上升的幅度
    -- optional int32 rank = 14; //排行榜排名
    -- optional int64 points = 15; //排行榜点数
    -- repeated FactionFightPassLevel levels = 16; //pass
    -- repeated FactionFightSale sale = 17; //pass
--   }
function FactionFightData:parseData(_data)
    FactionFightData.super.parseData(self,_data)

    self.p_mySide  = _data.mySide
    self.p_sides  = _data.sides
    self.p_winnerPool  = tonumber(_data.winnerPool)
    self.p_consolationPool  = tonumber(_data.consolationPool)
    self.p_progress  = _data.progress
    self.p_rank = _data.rank
    self.p_points = tonumber(_data.points)
    self.p_passData  = self:parseLevesData(_data.levels)  
    self.p_saleData = self:parseSaleData(_data.sale)
end

-- message FactionFightPassLevel {
--     optional int64 points = 1; //当前阶段的点数
--     optional bool collect = 2; // 是否已收集
--     optional int64 coins = 3; // 金币
--     optional ShopItem items = 4; // 物品
--     optional string title = 5; // 标题
--     optional string mark = 6; // 奖励标记
--   }
function FactionFightData:parseLevesData(_data)
    local list = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_index = i
            temp.p_points = tonumber(v.points)
            temp.p_collect = v.collect
            temp.p_coins = tonumber(v.coins)
            temp.p_title = v.title
            temp.p_mark = v.mark
            temp.p_num = v.num or 1
            temp.p_items = self:parseItemsData(v.items)
            table.insert(list, temp)
        end
    end
    return list
end

-- message FactionFightSale {
    -- optional int32 gems = 1; //钻石
    -- repeated ShopItem items = 2; // 物品
--   }
function FactionFightData:parseSaleData(_data)
    local saleData = nil
    if _data and #_data > 0 then 
        saleData = {}
        for i,v in ipairs(_data) do
            saleData.p_gems = v.gems
            saleData.p_items = self:parseItemsData(v.items)
        end
    end
    return saleData
end

-- 解析道具数据
function FactionFightData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function FactionFightData:getMySide()
    return self.p_mySide or ""
end

function FactionFightData:setProgress(_progress)
    self.p_progress = _progress
end

function FactionFightData:getProgress()
    return self.p_progress ~= 0 and self.p_progress or 1
end

function FactionFightData:getSides()
    return self.p_sides or {}
end

function FactionFightData:getWinCoins()
    return self.p_winnerPool or 0
end

function FactionFightData:setWinCoins(_coins)
    self.p_winnerPool = _coins
end

function FactionFightData:getLoseCoins()
    return self.p_consolationPool or 0
end

function FactionFightData:setLoseCoins(_coins)
    self.p_consolationPool = _coins 
end

function FactionFightData:getMyRank()
    return self.p_rank or 0
end

function FactionFightData:setPoints(_points)
    self.p_points = _points
end

function FactionFightData:getPoints()
    return self.p_points or 0
end

function FactionFightData:getPassData()
    return self.p_passData or {}
end

function FactionFightData:getPositionBar()
    return 1
end

function FactionFightData:getPassRewardList()
    local list = {}
    for i,v in ipairs(self.p_passData) do
        local points = v.p_points
        if self.p_points >= points then 
            if not v.p_collect then 
                table.insert(list, v)
            end
        else
            break
        end
    end
    return list
end

function FactionFightData:parseRankData(_data)
    self.m_RankConfig = BaseActivityRankCfg:create()
    self.m_RankConfig:parseData(_data)
end

function FactionFightData:getRankCfg()
    return self.m_RankConfig
end

function FactionFightData:setSpinScore(_score)
    self.m_tempScore = _score
end

function FactionFightData:setTempData(_score, _progress, _points)
    self.m_tempScore = _score
    self.m_tempProgress = _progress
    self.m_tempPoints = _points
end

function FactionFightData:getSpinScore()
    return self.m_tempScore or 0
end

function FactionFightData:parseSpinData(_data)
    local score = _data.collect or 0
    local progress = _data.progress or 0
    local points = _data.points or 0
    self:setProgress(progress)
    self:setPoints(points)
    if score > 0 then
        self:setTempData(score)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_SPIN_SCORE, score)
    end
end

function FactionFightData:getSaleData()
    return self.p_saleData
end

function FactionFightData:refreshData(_data)
    if _data then
        if _data.progress then
            self:setProgress(_data.progress)
        end
        if _data.winnerPool then
            self:setWinCoins(_data.winnerPool)
        end
        if _data.consolationPool then
            self:setLoseCoins(_data.consolationPool)
        end
    end
end

return FactionFightData
