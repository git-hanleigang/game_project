--[[
    三指针转盘促销
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local DiyFeatureData = class("DiyFeatureData",BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"

-- message DiyFeature {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数

--     optional string userPoint = 4; //玩家总点数
--     optional int32 spinTimes = 5; //获得spin次数

--     optional int32 normalFreeGame = 6; //低级freeGame次数
--     optional int32 highFreeGame = 7; //高级freeGame次数

    -- optional string normalFreeProgress = 8; //低级freeGame进度
    -- optional string highFreeProgress = 9; //高级freeGame进度
    -- repeated DiyFeatureBuff normalBuffs = 10; //已获取的低级buff
    -- repeated DiyFeatureBuff highBuffs = 11; //已获取的高级buff
    -- optional int32 normalEnergy = 12; //低级能量个数
    -- optional int32 highEnergy = 13; //高级能量个数
    -- optional int32 totEnergy = 14; //低级总能量条
    -- optional int32 totHighEnergy = 15; //高级总能量条
    -- optional bool normalTrigger = 16; //低级触发
    -- optional bool highTrigger = 17; //高级触发
    -- optional string betMult = 18;//bet系数
    -- optional DiyFeatureSale sale = 19; //促销
    -- repeated DiyFeatureBuff buffPool = 20; //奖池
    -- optional string maxPoint = 21; //最大点数
    -- optional bool normalEntered = 22; //低级已进入关卡标识
    -- optional bool highEntered = 23; //高级已进入关卡标识
    -- optional int64 gameBet = 24; // 关卡bet
    -- repeated int64 spinBetProcess = 25; //掉落点数气泡进度
    -- optional int64 highGameBet = 26; // 高级关卡bet
    -- optional int64 doubleSaleShowExTimeAt = 27; // double促销弹板过期时间
    -- optional string gameBetV2 = 33; // 低级关卡betV2
    -- optional string highGameBetV2 = 34; // 高级关卡betV2
    -- repeated string spinBetProcessV2 = 35; //掉落点数气泡进度V2

-- }

-- optional DiyFeatureBuffSale buffSaleData = 28; // buff促销
-- optional DiyFeatureBuffRecycle normalRecycle = 29; // 低级buff回收
-- optional DiyFeatureBuffRecycle highRecycle = 30; // 高级buff回收
-- optional int32 doubleSpin = 31; //双倍SpinBuff次数
-- optional int32 buffLvUp = 32; //等级提升Buff次数

function DiyFeatureData:parseData(_data)
    DiyFeatureData.super.parseData(self,_data)

    self.p_userPoint = tonumber(_data.userPoint) or 0 --玩家总点数
    self.p_spinTimes = _data.spinTimes  --获得spin次数
    if not self.p_spinTimes_front  then
        self.p_spinTimes_front = self.p_spinTimes
    else
        if self.p_spinTimes >  self.p_spinTimes_front then
            self.m_isGainSpinTimes = true
        end
        self.p_spinTimes_front = self.p_spinTimes
    end
    self.p_normalFreeGame = _data.normalFreeGame  --低级freeGame次数
    self.p_highFreeGame = _data.highFreeGame  --低级freeGame次数

    self.p_normalFreeProgress = tonumber(_data.normalFreeProgress) --低级freeGame进度
    self.p_highFreeProgress = tonumber(_data.highFreeProgress) --高级freeGame进度

    
    if not self.p_normalBuffs then
        self.p_normalBuffs = self:parseLevelBuff(_data.normalBuffs) --已获取的低级buff
    else
        if _data.normalBuffs and #_data.normalBuffs > 0 then 
            for i,v in ipairs(_data.normalBuffs) do
                if self.p_normalBuffs[v.buffType] then
                    if v.level > self.p_normalBuffs[v.buffType].p_level then
                        self.p_normalBuffs[v.buffType].p_level_front = self.p_normalBuffs[v.buffType].p_level
                    end
                    self.p_normalBuffs[v.buffType].p_level = v.level
                    self.p_normalBuffs[v.buffType].p_value = tonumber(v.value)
                end
            end
        end
    end

    if not self.p_highBuffs then
        self.p_highBuffs = self:parseLevelBuff(_data.highBuffs) -- 已获取的高级buff
    else
        if _data.highBuffs and #_data.highBuffs > 0 then 
            for i,v in ipairs(_data.highBuffs) do
                if self.p_highBuffs[v.buffType] then
                    if v.level > self.p_highBuffs[v.buffType].p_level then
                        self.p_highBuffs[v.buffType].p_level_front = self.p_highBuffs[v.buffType].p_level
                    end
                    self.p_highBuffs[v.buffType].p_level = v.level
                    self.p_highBuffs[v.buffType].p_value = tonumber(v.value)
                end
            end
        end
    end

    self.p_normalEnergy = _data.normalEnergy  --低级能量个数
    self.p_highEnergy = _data.highEnergy  --高级能量个数
    
    self.p_totEnergy = _data.totEnergy  --低级总能量条
    self.p_totHighEnergy = _data.totHighEnergy  --高级总能量条

    if self.p_normalTrigger ~= nil and not self.p_normalTrigger and _data.normalTrigger then
        self.p_normalGameActivateThisTime = true --当前激活普通游戏
    else
        self.p_normalGameActivateThisTime = false
    end
    self.p_normalTrigger = _data.normalTrigger  --低级触发 关卡玩法

    if self.p_highTrigger ~= nil and not self.p_highTrigger and _data.highTrigger then
        self.p_highGameActivateThisTime = true --当前激活高级游戏游戏
    else
        self.p_highGameActivateThisTime = false
    end
    self.p_highTrigger = _data.highTrigger  --高级触发 关卡玩法

    self.p_extraBetPercent = tonumber(_data.betMult) --bet消耗加成
    
    -- self.p_sale = self:parseSale(_data.sale) --  促销数据（已经将活动中的促销数据单独做成了促销活动）
    
    
    self.p_buffPoolMap,self.p_buffPoolVec = self:parseLevelBuff(_data.buffPool) --奖池

    self.p_maxPoint = tonumber(_data.maxPoint) -- 掉落满点数集满最多值

    self.p_normalGameActivated = _data.normalEntered -- 低级已进入关卡标识
    self.p_highGameActivated = _data.highEntered -- 高级已进入关卡标识

    self.m_allBet = {} 
    if _data.spinBetProcess and #_data.spinBetProcess > 0 then
        for i,v in ipairs(_data.spinBetProcess) do
            self.m_allBet[i] = toLongNumber(v)
        end
    end
    self.p_gameBet_normal = toLongNumber(_data.gameBetV2) -- 掉落满点数集满最多值
    self.p_gameBet_hight  = toLongNumber(_data.highGameBetV2) -- 掉落满点数集满最多值

    self.p_mLayerClosePopSaleLayerLimitAt = tonumber(_data.doubleSaleShowExTimeAt) or 0 -- 活动主界面SPIN次数消耗完毕后，第一次返回关卡时弹出促销主界面 限制时间
    G_GetMgr(ACTIVITY_REF.DiySale):parseData(_data.buffSaleData)

    if not self.p_normalRecycle then
        self.p_normalRecycle = {}
    end
    if self.p_normalRecycle.p_cur then
        self.p_normalRecycle.p_front = self.p_normalRecycle.p_cur 
    end
    self.p_normalRecycle.p_cur = _data.normalRecycle.cur
    self.p_normalRecycle.p_max = _data.normalRecycle.max
    self.p_normalRecycle.p_items = self:parseItems(_data.normalRecycle.items)
    if not self.p_normalRecycle.p_front then
        self.p_normalRecycle.p_front = self.p_normalRecycle.p_cur 
    end
    self.p_doubleSpin = _data.doubleSpin
    self.p_buffLvUp = _data.buffLvUp
end

function DiyFeatureData:getDoubleSpin()
    return self.p_doubleSpin
end

function DiyFeatureData:getDoubleSpinMax()
    return 9999
end

function DiyFeatureData:getBuffLvUp()
    return self.p_buffLvUp    
end

function DiyFeatureData:getBuffLvUpMax()
    return 9999
end

function DiyFeatureData:getNormalRecycleData()
    return self.p_normalRecycle
end

function DiyFeatureData:getHighRecycleData()
    return self.p_highRecycle
end

function DiyFeatureData:updateSlotData(_data)
    self.p_dropNum = tonumber(_data.dropNum) --  掉落点数
    self.p_dropPoint = tonumber(_data.dropPoint) --  掉落点数
    self.p_userPoint = tonumber(_data.userPoint) --  玩家点数
    self.p_maxPoint = tonumber(_data.maxPoint) --  掉落满点数集满最多值

    self.p_criticalMult = tonumber(_data.criticalMult) --  暴击倍数

    self.m_position = _data.positions
    -- if self.p_criticalMult > 1 then
    --     self.m_position = nil
    -- end

    self.p_rewardSpinTimes = _data.rewardSpinTimes --  本次掉落的spin 次数
    self.p_spinTimes = _data.totalSpinTimes  --获得spin次数
    if self.p_spinTimes >  self.p_spinTimes_front then
        self.m_isGainSpinTimes = true
    end
    self.p_spinTimes_front = self.p_spinTimes

    self.p_buffDropMult = tonumber(_data.buffDropMult)  --buff倍数
end

-- message DiyFeatureBuff{
--     optional string buffType = 1; //buff类型
--     optional string desc = 2; //buff描述
--     optional string value = 3; //buff值
--     optional int32 level = 4; //buff等级
-- }

function DiyFeatureData:parseLevelBuff(buflist)
    local listMap = {}
    local listVec = {}
    if buflist and #buflist > 0 then 
        for i,v in ipairs(buflist) do
            local temp = {}
            temp.p_level = v.level
            temp.p_buffType = v.buffType
            temp.p_value = tonumber(v.value)
            listMap[v.buffType] = temp
            listVec[#listVec + 1] = temp
        end
    end
    return listMap ,listVec
end


-- -- message DiyFeatureSale {
-- --     optional string key = 1;
-- --     optional string keyId = 2;
-- --     optional string price = 3;
-- --     optional string coins = 4;
-- --     repeated ShopItem item = 5;
-- --     optional int64 buffExpireAt = 6; //buff过期时间
-- --     optional string activityId = 7; //活动id
-- --     optional int64 expireAt = 8; //过期时间
-- --     optional int32 expire = 9; //剩余秒数
-- -- }
-- function DiyFeatureData:parseSale(_data)
--     local saleData = {}
--     saleData.p_key = _data.key
--     saleData.p_keyId = _data.keyId
--     saleData.p_price = _data.price
    
--     saleData.p_coins = toLongNumber(0)
--     saleData.p_coins:setNum(_data.coins)
    
--     saleData.p_times = self:parseItems(_data.item)
--     saleData.p_buffExpireAt = tonumber(_data.buffExpireAt) or 0   
--     return saleData
-- end

-- message DiyFeatureBuffRecycle {
--     optional int32 cur = 1; //当前回收buff个数
--     optional int32 max = 2; //最大回收buff个数
--     repeated ShopItem items = 3; //奖励物品
-- }
function DiyFeatureData:parseRecycle(_data)
    local recycleData = {}
    recycleData.p_cur = _data.cur
    recycleData.p_max = _data.max
    recycleData.p_items = self:parseItems(_data.items)
    return recycleData
end

function DiyFeatureData:clearRecycleRememberData()
    self.p_normalRecycle.p_front = self.p_normalRecycle.p_cur 
end

function DiyFeatureData:parseItems(_items)
    -- 通用道具
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

-- dif_type 1 普通  2 高级
function DiyFeatureData:getEnergyStatus(dif_type)
    if dif_type == 1 then
        return self.p_normalEnergy , self.p_totEnergy 
    else
        return self.p_highEnergy , self.p_totHighEnergy
    end
end

-- dif_type 1 普通  2 高级
function DiyFeatureData:getBuffsByType(dif_type)
    if dif_type == 1 then
        return self.p_normalBuffs
    else
        return self.p_highBuffs
    end
end

-- dif_type 1 普通  2 高级  freeGame次数
function DiyFeatureData:getFreeGameNumByType(dif_type)
    if dif_type == 1 then
        return self.p_normalFreeGame
    else
        return self.p_highFreeGame
    end
end

function DiyFeatureData:getFreeGameProgressByType(dif_type)
    if dif_type == 1 then
        return self.p_normalFreeProgress or 0
    else
        return self.p_highFreeProgress or 0
    end
end

--玩家总点数
function DiyFeatureData:getPointRate()
    local _percent = math.min(math.max(self.p_userPoint/(self.p_maxPoint or 100), 0.001), 1)
    return self.p_userPoint, self.p_maxPoint, _percent
end

--获得spin次数
function DiyFeatureData:getSpinTimes()
    return self.p_spinTimes
end

-- 获得额外bet倍数
function DiyFeatureData:getExtraBetPercent()
    return self.p_extraBetPercent
end

function DiyFeatureData:getSpinRewardBuffPool()
    return self.p_buffPoolVec ,self.p_buffPoolMap
end

--获取入口位置 1：左边，0：右边
function DiyFeatureData:getPositionBar()
    return 1
end

-- 获取本次spin位置和点数
function DiyFeatureData:getPointData()
    return self.m_position
end

-- 清空本次spin数据
function DiyFeatureData:clearSlotData()
    self.p_dropPoint = 0
    self.m_position = nil
end

function DiyFeatureData:getSlotData()
    local act_data = self:getRunningData()
    if not act_data then
        return 0, 0
    end
    return #self.m_position,self.p_dropPoint
end

function DiyFeatureData:isInGame()
    return self.p_normalGameActivated or self.p_highGameActivated
end

function DiyFeatureData:getInGameLevelId()
    if self.p_normalTrigger then
        return "10230"
    end
    if self.p_highTrigger then
        return "10231"
    end
    return "10230"
end

--  是否正好触发玩法
function DiyFeatureData:getIsActivateGameThisTime(dif_type)
    if not dif_type then
        return self.p_normalGameActivateThisTime or self.p_highGameActivateThisTime
    elseif dif_type == 1 then
        return self.p_normalGameActivateThisTime
    elseif dif_type == 2 then
        return self.p_highGameActivateThisTime
    end
    return false
end

function DiyFeatureData:getIsActivateGame(dif_type)
    if not dif_type then
        return self.p_normalTrigger or self.p_highTrigger
    elseif dif_type == 1 then
        return self.p_normalTrigger
    elseif dif_type == 2 then
        return self.p_highTrigger
    end
    return false
end

function DiyFeatureData:getGameBet(dif_type)
    if dif_type == 1 then
        return self.p_gameBet_normal
    elseif dif_type == 2 then
        return self.p_gameBet_hight
    end
end

-- 关卡内bet气泡的bet值
function DiyFeatureData:getBubbleAllBet()
    return self.m_allBet
end

-- 活动主界面SPIN次数消耗完毕后，第一次返回关卡时弹出促销主界面 限制时间(cd内不弹)
function DiyFeatureData:checkMLayerClosePopSaleLayerTimeEnabled()
    local limitAt = self.p_mLayerClosePopSaleLayerLimitAt or 0
    local curTime = util_getCurrnetTime() * 1000
    return curTime > limitAt
end

function DiyFeatureData:isGainSpinTimes()
    local result = not not self.m_isGainSpinTimes
    -- self.m_isGainSpinTimes = false
    return result
end

function DiyFeatureData:clearGainState()
    self.m_isGainSpinTimes = false
end

function DiyFeatureData:checkHasMaxLevelBuff(dif_type)
    local result = false
    if dif_type == 1 then
        for k,v in pairs(self.p_normalBuffs) do
            if v.p_level >= 4 then
                result = true
                break
            end
        end
    elseif dif_type == 2 then
        for k,v in pairs(self.p_highBuffs) do
            if v.p_level >= 4 then
                result = true
                break
            end
        end
    end
    return result
end

function DiyFeatureData:getRememberLevelMap()
    local result = {}
    for k,v in pairs(self.p_normalBuffs) do
        result[v.p_buffType] = v.p_level
    end
    for k,v in pairs(self.p_highBuffs) do
        result[v.p_buffType] = v.p_level
    end
    return result
end

return DiyFeatureData
