--[[
    author:{author}
    time:2019-04-18 21:53:40
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local LevelDashData = class("LevelDashData", BaseActivityData)

LevelDashData.p_activityId = nil
LevelDashData.p_expireAt = nil
LevelDashData.p_expire = nil
LevelDashData.p_startLevel = nil
LevelDashData.p_endLevel = nil
LevelDashData.p_levelDashExpireAt = nil
LevelDashData.p_levelDashExpire = nil
LevelDashData.p_maxCoins = nil
LevelDashData.p_endDayExpireAt = nil
LevelDashData.p_buyKey = nil
LevelDashData.p_price = nil
LevelDashData.p_status = nil
LevelDashData.p_exist = nil
GD.LEVEL_DASH_STATUS = {
    WAIT = "WAIT",
    DOING = "DOING",
    PLAY = "PLAY",
    GAME = "GAME",
    REWARD = "REWARD",
    OVER = "OVER"
}
GD.POKER_PLAY_TIMES = 3

function LevelDashData:ctor()
    LevelDashData.super.ctor(self)
    self.p_exist = false
end

function LevelDashData:getIsExist()
    --看代码是根据促销关联下载的活动是代码 所以检测 这三个资源有正在下载的就不开
    if
        globalDynamicDLControl:checkDownloading("Promotion_LevelDash") or globalDynamicDLControl:checkDownloading("Activity_LevelDash") or
            globalDynamicDLControl:checkDownloading("Activity_LevelDash_Code")
     then
        return false
    end
    return self.p_exist
end

function LevelDashData:parseData(data)
    LevelDashData.super.parseData(self, data)
    self.p_activityId = data.activityId
    self.p_activityName = data.activityName
    self.p_totalFinishTimes = tonumber(data.totalFinishTimes)
    self.p_expireAt = tonumber(data.expireAt)
    self.p_expire = tonumber(data.expire)
    self.p_startLevel = tonumber(data.startLevel)
    self.p_endLevel = tonumber(data.endLevel)
    self.p_levelDashExpireAt = tonumber(data.levelDashExpireAt)
    self.p_levelDashExpire = tonumber(data.levelDashExpire)
    self.p_maxCoins = tonumber(data.maxCoins)
    self.p_endDayExpireAt = tonumber(data.endDayExpireAt)
    self.p_buyKey = data.buyKey
    self.p_price = data.price
    self.p_exist = true
    -- globalData.saleRunData:parseLevelDashConfig(data)
    self:initLevelDashStatus()
end

function LevelDashData:initLevelDashStatus()
    local status = self.p_status
    if globalData.userRunData.levelNum == 0 then
        globalData.userRunData.levelNum = globalData.userRunData.loginUserData.user.level
    end
    if self.p_expire <= 0 then
        self.p_status = LEVEL_DASH_STATUS.OVER
    elseif self.p_startLevel == self.p_endLevel then
        if self.p_pokerData == nil then
            local json = gLobalDataManager:getStringByField("levelDashPokerData", "")
            if json ~= "" then
                self:initPokerData(json)
            end
        end
        if self.p_pokerData == nil then
            self.p_status = LEVEL_DASH_STATUS.WAIT
        elseif self:getThisGameEndTime() ~= self.p_endDayExpireAt then
            self.p_status = LEVEL_DASH_STATUS.WAIT
            self:clearPokerData()
        elseif #self.p_pokerData.gameStep < POKER_PLAY_TIMES then
            self.p_status = LEVEL_DASH_STATUS.GAME
        else
            self.p_status = LEVEL_DASH_STATUS.REWARD
        end
    elseif globalData.userRunData.levelNum >= self.p_endLevel then
        if self.p_pokerData == nil then
            local json = gLobalDataManager:getStringByField("levelDashPokerData", "")
            if json ~= "" then
                self:initPokerData(json)
            end
        end
        if self:getThisGameEndTime() ~= self.p_endDayExpireAt then
            self.p_status = LEVEL_DASH_STATUS.WAIT
            self:clearPokerData()
        elseif self.p_pokerData == nil then
            self.p_status = LEVEL_DASH_STATUS.PLAY
        elseif #self.p_pokerData.gameStep < POKER_PLAY_TIMES then
            self.p_status = LEVEL_DASH_STATUS.GAME
        else
            self.p_status = LEVEL_DASH_STATUS.REWARD
        end
    elseif self.p_levelDashExpire <= 0 then
        self.p_status = LEVEL_DASH_STATUS.WAIT
        self:clearPokerData()
    else
        self.p_status = LEVEL_DASH_STATUS.DOING
    end
    if status ~= self.p_status and self.p_status == LEVEL_DASH_STATUS.DOING then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_DASH_START)
    end
end

function LevelDashData:getIsOpen()
    return self.p_status == LEVEL_DASH_STATUS.DOING
end

function LevelDashData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_levelDashExpireAt / 1000)
    if isOver then
        self.p_status = LEVEL_DASH_STATUS.OVER
    end
    return strTime, isOver
end

function LevelDashData:getTodayLeftTime()
    local strTime, isOver = util_daysdemaining(self.p_endDayExpireAt / 1000)
    return strTime, isOver
end

function LevelDashData:getLevelDashStatus()
    return self.p_status
end

function LevelDashData:setLevelDashStatus(status)
    self.p_status = status
end

function LevelDashData:getMidlleLevel()
    local level = math.ceil((self.p_startLevel + self.p_endLevel) * 0.5)
    if level < self.p_endLevel then
        return level
    end
    return -1
end

function LevelDashData:initPokerData(data)
    if self.p_pokerData ~= nil and self.p_pokerData.payFlag == true then
        self:clearPokerData()
        return
    end
    self.p_pokerData = cjson.decode(data)
    -- self.p_pokerData.gameStep = {}
    if self.p_pokerData.gameStep == nil then
        self.p_pokerData.gameStep = {}
        self.p_pokerData.endDayExpireAt = self.p_endDayExpireAt
        self.p_pokerData.payFlag = false
    end
    local vecTemp = {}
    for i = 1, #self.p_pokerData.awards, 1 do
        vecTemp[#vecTemp + 1] = self.p_pokerData.awards[i]
    end
    table.sort(
        vecTemp,
        function(a, b)
            return a > b
        end
    )
    self.p_pokerData.hugeWin = vecTemp[2]
    self:savePokerJson()
end

function LevelDashData:updatePokerData(pos, value)
    local step = {}
    step.pos = pos
    step.value = value
    self.p_pokerData.gameStep[#self.p_pokerData.gameStep + 1] = step
    self:savePokerJson()
end

function LevelDashData:clearPokerData()
    gLobalDataManager:setStringByField("levelDashPokerData", "")
    self.p_pokerData = nil
end

function LevelDashData:savePokerJson()
    local json = cjson.encode(self.p_pokerData)
    gLobalDataManager:setStringByField("levelDashPokerData", json)
end

function LevelDashData:getPokerData()
    return self.p_pokerData
end

function LevelDashData:getPokerCoins(index)
    if self.p_pokerData then
        local result = 0
        for i = 1, index, 1 do
            local info = self.p_pokerData.play[i]
            result = result + info.coins * info.multiple
            if result < 0 then
                result = 0
            end
        end

        return result
    end
    return 0
end

function LevelDashData:setThisGameEndTime()
    gLobalDataManager:setStringByField("thisDashEndTime", tostring(self.p_endDayExpireAt))
end

function LevelDashData:getThisGameEndTime()
    return tonumber(gLobalDataManager:getStringByField("thisDashEndTime", "0"))
end

return LevelDashData
