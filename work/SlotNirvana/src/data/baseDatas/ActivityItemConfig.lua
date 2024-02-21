--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-05-09
--
local ActivityBetCondition = require "data.baseDatas.ActivityBetCondition"
local ActivityItemConfig = class("ActivityItemConfig")

--促销数据表
function ActivityItemConfig:ctor()
    self.p_id = nil --活动id
    self.p_start = nil --开始日期
    self.p_end = nil --结束日期
    self.p_repeat = nil --是否可重复购买
    self.p_order = nil --活动开放顺序
    self.p_duration = nil --促销持续时间
    self.p_expire = nil --促销剩余时间
    self.p_expireAt = nil --促销到期
    self.p_contents = nil --促销内容
    self.p_reference = nil --程序引用名
    self.p_themeRes = nil --主题资源名
    self.p_popupImage = nil --推送弹板
    self.p_slideImage = nil --大厅轮播图
    self.p_hallImages = nil --大厅展示图
    self.p_inboxImage = nil --邮箱推送图
    self.p_activityType = nil --活动类型
    self.p_betCondition = {} --解锁活动bet条件
    self.p_openLevel = nil --活动开启等级
    self.p_gameIds = nil --开放关卡
    self.p_phase = nil --促销档位
end

function ActivityItemConfig:parseData(data, activityType)
    self.p_id = data.activityId
    self.p_start = data.start
    self.p_end = data["end"]
    self.p_repeat = data["repeat"]
    self.p_order = data.sequence
    self.p_duration = data.countdown
    self.p_expire = data.expire
    self.p_expireAt = tonumber(data.expireAt) or 0
    self.p_contents = data.contentId
    self.p_themeRes = data.activityName
    self.p_reference = data.referenceName or ""
    self.p_popupImage = data.popupImage
    self.p_phase = data.sequence or 0 --活动阶段 服务器存储在sequence字段里面
    self.p_slideImage = data.slideImage
    self.p_hallImages = util_string_split(data.hallImage, ";")
    self.p_inboxImage = data.inboxImage
    self.p_activityType = activityType
    self.p_serverActivityType = data.activityType
    if data.betCondition ~= nil and data.betCondition ~= "" then
        local d = data.betCondition
        if d ~= nil and #d > 0 then
            for i = 1, #d do
                local item = ActivityBetCondition:create()
                item:parseData(d[i])
                self.p_betCondition[#self.p_betCondition + 1] = item
            end
        end
    end

    self.p_openLevel = tonumber(data.openLevel) or 0
    self.p_gameIds = data.gameIds
end

-- 获得ID
function ActivityItemConfig:getActivityID()
    return self.p_id
end

-- 获得引用名
function ActivityItemConfig:getRefName()
    if self.p_reference ~= "" then
        return self.p_reference
    else
        -- 没有用主题资源名代替，兼容老表
        return self.p_themeRes or ""
    end
end

-- 主题资源名
function ActivityItemConfig:getThemeName()
    return self.p_themeRes or ""
end

function ActivityItemConfig:getExpireAt()
    return (self.p_expireAt or 0) / 1000
end

function ActivityItemConfig:getServerActivityType()
    return self.p_serverActivityType
end

--获取满足等级条件的Bte条件
function ActivityItemConfig:getNeedBetIndex(level)
    if level == nil then
        return 0
    end

    for i = 1, #self.p_betCondition do
        local betData = self.p_betCondition[i]
        if betData ~= nil and (betData.p_minLevel ~= nil and betData.p_minLevel <= level) and (betData.p_maxLevel ~= nil and betData.p_maxLevel >= level) then
            return betData.p_betGear
        end
    end

    return 0
end

--是否满足等级开启条件
function ActivityItemConfig:checkOpenLevel()
    local curLevel = globalData.userRunData.levelNum
    if curLevel == nil then
        return false
    end

    local needLevel = self.p_openLevel

    -- if self.p_reference == "Activity_Quest" then
    --     --常量表开启等级
    --     needLevel = globalData.constantData.OPENLEVEL_NEWQUEST or 40
    -- end

    if self:getRefName() == "Activity_CardOpen" or self:getRefName() == "Activity_CardOpen2" or self:getRefName() == "Activity_CardOpen3" --[[or self.p_reference == "Activity_PreCard"]] then
        if not CC_CAN_ENTER_CARD_COLLECTION then
            return false
        end
        --常量表开启等级
        needLevel = globalData.constantData.CARD_OPEN_LEVEL or 20
    end

    if self:getRefName() == "Activity_CardOpen_NewUser" then
        --常量表开启等级
        needLevel = globalData.constantData.NEW_CARD_OPEN_LEVEL or 5
    end

    if globalData.spinBonusData and self.p_id == globalData.spinBonusData.p_activityId then
        if not globalData.spinBonusData:isTaskOpen() then --spinBonus 已经完成了
            return false
        end
    end

    if
        self:getRefName() == "Activity_LuckyChallengeRule" or self:getRefName() == "Activity_LuckyChallengeOver" or self:getRefName() == "Activity_LuckyChallenge" or
            self:getRefName() == "Promotion_LuckyChallenge"
     then
        needLevel = globalData.constantData.CHALLENGE_OPEN_LEVEL
    end

    if curLevel >= needLevel then
        return true
    end

    return false
end

--是否满足bet条件
function ActivityItemConfig:IsBetCondition(level, betIndex)
    local needBetIndex = self:getNeedBetIndex(level)
    if needBetIndex == nil then
        return false
    end

    if needBetIndex == 0 then
        return false
    end

    if needBetIndex > betIndex then
        return false
    end

    return true
end

--获取满足开启条件的关卡
function ActivityItemConfig:getLevelNameByOpenLevel(data)
    local ret = {}
    local curLevel = globalData.userRunData.levelNum
    if data == nil or #data < 1 or curLevel == nil then
        return ret
    end

    local machineDatas = globalData.slotRunData.p_machineDatas
    if machineDatas == nil and #machineDatas < 1 then
        return ret
    end

    for i = 1, #machineDatas do
        local d = machineDatas[i]
        if d ~= nil then
            local isIn = table_indexof(data, tostring(d.p_id))
            if isIn and curLevel >= d.p_openLevel then
                ret[#ret + 1] = d.p_levelName
            end
        end
    end

    return ret
end

--获取活动跳转关卡
function ActivityItemConfig:getActivityToLevelName()
    if self.p_gameIds == nil or self.p_gameIds == "" or self.p_gameIds == "-1" then
        return globalData.slotRunData:getFirstJackpotBet()
    end

    local verStrs = util_string_split(self.p_gameIds, ";")
    local verLen = #verStrs
    if verLen == 1 then
        return verStrs[1]
    end

    local tempLevels = self:getLevelNameByOpenLevel(verStrs)
    local tempLen = #tempLevels
    if tempLen > 0 then
        local index = math.random(1, tempLen)
        return tempLevels[index]
    end

    return globalData.slotRunData:getFirstJackpotBet()
end

-- function ActivityItemConfig:checkDependentCondition()
--       local result = true
--       return result
-- end

-- 活动配置是否过期
function ActivityItemConfig:isTimeout()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    if curTime > self:getExpireAt() then
        return true
    else
        return false
    end
end

return ActivityItemConfig
