--[[
    author:{author}
    time:2019-04-18 21:53:40
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local LevelRushGameData = require("data.miniGameData.MiniGameLevelFishData")
local LevelRushData = class("LevelRushData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")
local LevelRushPhaseData = util_require("data.levelRush.LevelRushPhaseData")

LevelRushData.p_activityId = nil
LevelRushData.p_expireAt = nil
LevelRushData.p_expire = nil
LevelRushData.p_startLevel = nil
LevelRushData.p_endLevel = nil
LevelRushData.p_levelRushExpireAt = nil
LevelRushData.p_levelRushExpire = nil
LevelRushData.p_maxCoins = nil
LevelRushData.p_endDayExpireAt = nil
LevelRushData.p_buyKey = nil
LevelRushData.p_price = nil
LevelRushData.p_status = nil
LevelRushData.p_exist = nil
LevelRushData.p_activityStart = nil
---------经验buff 2x---------
LevelRushData.p_buffPopupSwitch = 0
LevelRushData.p_buffPopupDuration = 0
LevelRushData.p_buffPopupCd = 0
LevelRushData.p_openBuffLayerTime = os.time()
LevelRushData.p_buffItemData = nil
---------经验buff 2x---------
LevelRushData.p_phaseRewardList = nil -- 阶段奖励

function LevelRushData:ctor()
    LevelRushData.super.ctor(self)
    self.p_exist = false
    self.p_bGameClose = true -- 判断游戏开启弹窗是否弹出 --

    self.p_bHalfLevelShow = false
end

function LevelRushData:getIsExist()
    --看代码是根据促销关联下载的活动是代码 所以检测 这三个资源有正在下载的就不开
    if
        globalDynamicDLControl:checkDownloading("Activity_LevelRush") or globalDynamicDLControl:checkDownloading("Activity_LevelRush_Code") or
            globalDynamicDLControl:checkDownloading("Activity_LevelRush_loading")
     then
        return false
    end
    return true
end

-- message LevelRushConfig {
--     optional int64 expireAt = 1; //活动结束时间
--     optional int64 expire = 2; //活动剩余时间
--     optional int32 startLevel = 3; //开始等级
--     optional int32 endLevel = 4; //完成等级
--     optional int64 levelRushExpireAt = 5; //level dash 截止时间
--     optional int64 levelRushExpire = 6; //level dash 剩余时间
--     optional int64 endDayExpireAt = 7; //当日截止时间
--     optional string activityId = 8; //活动id
--     optional string activityName = 9; //活动名称
--     repeated LevelRushGame games = 10; //小游戏数据
--     optional int64 activityStart = 11; //活动开始时间

--     optional int32 popupSwitch = 12; //ExpX2弹窗开关(1表示开启，0表示关闭)
--     optional int32 popupDuration = 13; //ExpX2弹窗显示时长(单位：s)
--     optional int32 popupCd = 14; //ExpX2弹窗CD(-1 无cd,单位：s)
--     optional ShopItem item = 15; // 具体buff的信息
--     repeated LevelRushPhase phases = 16;//阶段奖励
--   }

function LevelRushData:parseData(data)
    LevelRushData.super.parseData(self, data)
    self.p_activityId = data.activityId
    self.p_activityName = data.activityName
    self.p_expireAt = tonumber(data.expireAt)
    self.p_expire = tonumber(data.expire)
    self.p_startLevel = tonumber(data.startLevel)
    self.p_endLevel = tonumber(data.endLevel)

    self.p_levelRushExpireAt = tonumber(data.levelRushExpireAt)
    self.p_levelRushExpire = tonumber(data.levelRushExpire)
    self.p_endDayExpireAt = tonumber(data.endDayExpireAt)
    self.p_activityStart = tonumber(data.activityStart)

    ---------经验buff 2x---------
    self.p_buffPopupSwitch = tonumber(data.popupSwitch) or 0
    self.p_buffPopupDuration = tonumber(data.popupDuration) or 0
    self.p_buffPopupCd = tonumber(data.popupCd) or 0
    self.p_buffItemData = self:parseBuffItemData(data.item)
    ---------经验buff 2x---------

    self.p_phaseRewardList = self:parsePhaseRewardList(data.phases) -- 阶段奖励

    self.m_lastGameIndex = nil
    if data.games then
        self.p_gameData = {}
        for i = 1, #data.games do
            local data = data.games[i]
            local gameData = LevelRushGameData.new()
            gameData:parseGameData(data)
            local nIndexGame = gameData:getGameIndex()
            self.p_gameData[nIndexGame] = gameData
            self.m_lastGameIndex = nIndexGame
        end
    else
        self.p_gameData = nil
    end

    ------------------cxc 2021年09月08日17:37:02 延迟levelrush活动时间------------------
    self:setExpireAt(math.max(self.p_expireAt, self.p_levelRushExpireAt))
    self.p_expire = math.max(self.p_expire, self.p_levelRushExpire)
    ------------------cxc 2021年09月08日17:37:02 延迟levelrush活动时间------------------
end

function LevelRushData:getLeftBallsCount(_nGameIndex)
    local gameData = self:getGameData(_nGameIndex)
    if gameData then
        return gameData:getLeftBallsCount()
    end

    return nil
end

function LevelRushData:getGameData(_nGameIndex)
    if self.p_gameData == nil then
        return nil
    end

    local gameData = self.p_gameData[_nGameIndex]
    if gameData then
        return gameData
    end

    return nil
end

function LevelRushData:getLastGameData()
    if self.p_gameData == nil then
        return nil
    end
    if self.m_lastGameIndex ~= nil then
        local gameData = self.p_gameData[self.m_lastGameIndex]
        if gameData then
            return gameData
        end
    end
    return nil
end

function LevelRushData:getNowLevelData()
    if self.p_gameData == nil then
        return nil
    end

    local nLevel = globalData.userRunData.levelNum
    local count = table_nums(self.p_gameData)
    for k, v in pairs(self.p_gameData) do
        if v:getGameEndLevel() == nLevel then
            return v
        end
    end

    return nil
end

function LevelRushData:getGameDatas()
    return self.p_gameData
end

-- topgame top buff状态
function LevelRushData:getBuffIsOpen()
    return self.p_levelRushExpire > 0 and globalData.userRunData.levelNum < self.p_endLevel and self.p_expire > 0 and self.p_startLevel ~= self.p_endLevel
end

-- levelrush 是否到达开启条件 buff状态
function LevelRushData:getIsOpen()
    return self.p_levelRushExpire > 0 and globalData.userRunData.levelNum <= self.p_endLevel and self.p_expire > 0 and self.p_startLevel ~= self.p_endLevel
end

function LevelRushData:getActivityOpen()
    return self:getIsExist() == true and self:getIsOpen()
end

function LevelRushData:getBuffOpen()
    local strTime, isOver = self:getLeftTimeStr()
    if isOver then
        return false
    end

    return self:getIsExist() == true and self:getBuffIsOpen()
end

function LevelRushData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_levelRushExpireAt / 1000)
    return strTime, isOver
end

function LevelRushData:getTodayLeftTime()
    local strTime, isOver = util_daysdemaining(self.p_endDayExpireAt / 1000)
    return strTime, isOver
end

function LevelRushData:getLevelDashStatus()
    return self.p_status
end

function LevelRushData:setLevelDashStatus(status)
    self.p_status = status
end

function LevelRushData:getEndLevel()
    return self.p_endLevel
end

function LevelRushData:getStartLevel()
    return self.p_startLevel
end

function LevelRushData:getMidlleLevel()
    local level = math.ceil((self.p_startLevel + self.p_endLevel) * 0.5)
    if level < self.p_endLevel then
        return level
    end
    return -1
end

function LevelRushData:getStartTime()
    return self.p_activityStart
end

-- 重写父类
-- function LevelRushData:isIgnoreExpire()
--     return true
-- end

---------经验buff 2x---------
-- ExpX2弹窗开关(1表示开启，0表示关闭)
function LevelRushData:isOpenDoubleBuff()
    local bDoubleBuff = globalData.buffConfigData:checkBuff()
    if bDoubleBuff then
        -- 有x2buff不弹弹窗
        return false
    end

    if self.p_buffPopupSwitch ~= 1 then
        return false
    end

    if not self:isHadBuffLayerCD() then
        return true
    end

    local openTime = self.p_openBuffLayerTime + self.p_buffPopupCd
    return os.time() >= openTime
end
-- ExpX2弹窗显示时长(单位：s)
function LevelRushData:isControlBuffLayerShowTime()
    return self.p_buffPopupDuration > 0
end
function LevelRushData:getBuffPopupDuration()
    return self.p_buffPopupDuration
end

-- ExpX2弹窗CD(-1 无cd,单位：s)
function LevelRushData:isHadBuffLayerCD()
    return self.p_buffPopupCd > 0
end
function LevelRushData:getBuffPopupCD()
    return self.p_buffPopupCd
end
function LevelRushData:setCurOpenBuffLayerTime()
    self.p_openBuffLayerTime = os.time()
end

function LevelRushData:parseBuffItemData(_itemData)
    if not _itemData or not next(_itemData) then
        return
    end

    local shopItem = ShopItem:create()
    shopItem:parseData(_itemData, true)

    return shopItem
end
function LevelRushData:getBuffItemDurationTime()
    if not self.p_buffItemData then
        return 0
    end

    local duration = 0
    if self.p_buffItemData:isBuff() then
        duration = self.p_buffItemData.p_buffInfo.buffDuration or 0
    end
    return duration --分钟
end
---------经验buff 2x---------

-- function LevelRushData:isRunning()
--     if not LevelRushData.super.isRunning(self) then
--         return false
--     end

--     if self:isCompleted() then
--         return false
--     end

--     return true
-- end

-- function LevelRushData:checkCompleteCondition()
--     return false
-- end

-- 解析 阶段奖励
function LevelRushData:parsePhaseRewardList(_phaseDataList)
    if not _phaseDataList then
        return {}
    end

    local list = {}
    for i, data in ipairs(_phaseDataList) do
        local phaseData = LevelRushPhaseData:create()
        phaseData:parseData(data)
        table.insert(list, phaseData)
    end

    return list
end

-- 获取阶段奖励
function LevelRushData:getPhaseRewardList()
    return self.p_phaseRewardList or {}
end

-- 是否可删除 (还有玩法没玩不删除)
function LevelRushData:isCanDelete()
    if self.p_gameData then
        if gLobalLevelRushManager:getIsEnterGameView() then
            -- 还在游戏内玩着呢 不要删
            return false
        end

        -- 还有 游戏没玩了且时间都没到了
        for i, gameData in pairs(self.p_gameData) do
            local strTime, bOver = gameData:getTodayLeftTime()
            local endLevel = gameData:getGameEndLevel()
            if not bOver and globalData.userRunData.levelNum >= endLevel then
                return false
            end
        end
    end

    return LevelRushData.super.isCanDelete(self)
end

return LevelRushData
