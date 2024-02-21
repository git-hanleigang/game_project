--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-10 20:50:07
-- FIX IOS 139
--
local LevelData = require "data.baseDatas.LevelData"
local LevelOrderData = require "data.baseDatas.LevelOrderData"
local ReturnSignData = require "data.returnSign.ReturnSignData"
local UserRunData = class("UserRunData")
require("socket")
UserRunData.maxLevel = nil -- 最大等级

UserRunData.userUdid = nil -- 用户id， 根据设备提取
UserRunData.isFbLogin = nil
UserRunData.dataVersion = nil
UserRunData.loginUserData = nil -- 用户数据表， 一个table
UserRunData.loginExtendData = nil --用户扩展数据，上线主动请求后返回的信息
UserRunData.lastUpdateVersion = nil
UserRunData.loginOffset = nil
UserRunData.headIcon = nil

UserRunData.coinNum = nil
UserRunData.gemNum = nil
UserRunData.buckNum = nil
UserRunData.levelNum = nil
UserRunData.currLevelExper = nil
UserRunData.vipLevel = nil
UserRunData.vipPoints = nil
UserRunData.nickName = nil --用户名称
UserRunData.mail = nil --用户绑定邮箱
UserRunData.HeadName = nil --头像名字
UserRunData.avatarFrameId = nil --头像框Id
UserRunData.bLoginSaveHead = false -- 是否登录后重新保存用户头像
UserRunData.lastUpdateNickNameTime = nil -- 用户上次换名的时间戳

UserRunData.fbUdid = nil
UserRunData.fbToken = nil
UserRunData.fbName = nil
UserRunData.fbEmail = nil
UserRunData.appleID = nil
UserRunData.isGetFbReward = nil
UserRunData.facebookBindingID = nil

UserRunData.createTime = nil
UserRunData.uid = nil
UserRunData.FB_LOGIN_FIRST_REWARD = nil

-- level 数据
UserRunData.p_preLevelData = nil
UserRunData.p_curLevelData = nil
UserRunData.p_nextLevelDatas = nil
UserRunData.p_rewardOrderDatas = nil --升级奖励显示顺序
--ABTest
UserRunData.p_category = nil --用户分组A B C D
UserRunData.p_categoryNum = nil --用户分组 0~999

UserRunData.p_serverTime = nil -- 服务器时间 单位毫秒
UserRunData.m_loaclLastTime = nil --本地时间用来计算时间间隔

UserRunData.m_fbBindReward = nil --facebook绑定奖励
UserRunData.m_newUserReward = nil --新用户金币不足奖励
-- 关卡进入大厅是否进入更新
UserRunData.m_isEnterUpdateFormLevelToLobby = false

UserRunData.m_userChurnReturnInfo = nil -- 用户流失回归奖励 信息

UserRunData.m_communication = false -- 用户直接反馈标识

--防作弊处理
UserRunData.CHEAT_SAMPLING_RATIO = 1.2
UserRunData.CHEAT_SAMPLING_TOTLE_TIMES = 5

function UserRunData:ctor()
    self.FB_LOGIN_FIRST_REWARD = 1000000

    self.isFbLogin = false
    self.loginUserData = nil
    self.loginExtendData = nil

    self.gemNum = 0
    self.buckNum = 0
    self.coinNum = toLongNumber(0)
    self.vipLevel = 0
    self.vipPoints = 0
    self.levelNum = 0
    self.nickName = nil
    self.mail = nil
    self.HeadName = nil
    self.avatarFrameId = nil

    self.dataVersion = 0
    self.p_serverTime = 0
    self.m_fbBindReward = 0
    self.m_newUserReward = 0
    self.m_intervalTime = self:getIntervalTime()
    self.m_userTrophyData = nil

    self.m_totoleSpanTime = 0
    self.m_totoleDt = 0
    self.m_bSamplingT = {}

    -- self:sysServerTmSchedule()
    -- 最后登陆时间
    self.m_lastLoginTime = 0
end

--是否是新用户
function UserRunData:isNewUser(day, timestamp)
    day = day or 1
    local createTime = globalData.userRunData.createTime or 0
    if timestamp then
        createTime = timestamp
    end

    local serverTime = self.p_serverTime or 86400
    local spanTime = serverTime - createTime
    if spanTime < (day * 86400 * 1000) then
        return true
    end
    return false
end

--[[
    @desc: 解析上一个等级信息
    time:2019-04-11 11:15:19
    --@curData:
    @return:
]]
function UserRunData:parsePrevLevelData(curData)
    if not curData or not curData.level then
        return
    end
    local preLevelData = LevelData:create()
    preLevelData.p_level = curData.level -- 等级
    preLevelData.p_exp = tonumber(curData.exp) -- 升级到下一级所需要经验
    preLevelData.p_coins = tonumber(curData.coins) -- 升级到下一级奖励金币
    preLevelData.p_coinsShow = util_string_split(curData.coinsShow, ";", true)
    preLevelData.p_bronze = preLevelData.p_coinsShow[1] or 0 -- 铜库奖励
    preLevelData.p_treasury = preLevelData.p_coinsShow[2] or 0 -- 银库奖励
    preLevelData.p_wheel = preLevelData.p_coinsShow[3] or 0 -- 转盘奖励
    preLevelData.p_vipPoint = curData.vipPoint or 0 -- 升级奖励vip 点数
    preLevelData.p_clubPoint = curData.clubPoint or 0
    self.p_preLevelData = preLevelData
end
--[[
    @desc: 解析当前等级的信息
    time:2019-04-11 11:15:19
    --@curData:
    @return:
]]
function UserRunData:parseCurLevelData(curData)
    local curLevelData = LevelData:create()
    if not curData or not curData.level or not tonumber(curData.exp) or not tonumber(curData.coins) then
        release_print("UserRunData:parseCurLevelData server error!")
        gLobalBuglyControl:luaException("UserRunData:parseCurLevelData server error!", debug.traceback())
    end
    curLevelData.p_level = curData.level or curLevelData.p_level -- 等级
    curLevelData.p_exp = tonumber(curData.exp) or curLevelData.p_exp -- 升级到下一级所需要经验
    curLevelData.p_coins = tonumber(curData.coins) or curLevelData.p_coins -- 升级到下一级奖励金币
    curLevelData.p_coinsShow = util_string_split(curData.coinsShow, ";", true)
    curLevelData.p_bronze = curLevelData.p_coinsShow[1] or 0 -- 铜库奖励
    curLevelData.p_treasury = curLevelData.p_coinsShow[2] or 0 -- 银库奖励
    curLevelData.p_wheel = curLevelData.p_coinsShow[3] or 0 -- 转盘奖励
    curLevelData.p_vipPoint = curData.vipPoint or 0 -- 升级奖励vip 点数
    curLevelData.p_clubPoint = curData.clubPoint or 0

    self.p_curLevelData = curLevelData
end
--[[
    @desc: 解析接下来的level列表
    time:2019-04-11 11:15:01
    --@nextLevelList:
    @return:
]]
function UserRunData:parseNextLevelData(nextLevelList)
    self.p_nextLevelDatas = {}
    for i = 1, #nextLevelList do
        local levelData = nextLevelList[i]
        local nextLevelData = LevelData:create()
        nextLevelData.p_level = levelData.level -- 等级
        nextLevelData.p_exp = tonumber(levelData.exp) -- 升级到下一级所需要经验
        nextLevelData.p_coins = tonumber(levelData.coins) -- 升级到下一级奖励金币
        nextLevelData.p_coinsShow = util_string_split(levelData.coinsShow, ";", true)
        nextLevelData.p_bronze = nextLevelData.p_coinsShow[1] or 0 -- 铜库奖励
        nextLevelData.p_treasury = nextLevelData.p_coinsShow[2] or 0 -- 银库奖励
        nextLevelData.p_wheel = nextLevelData.p_coinsShow[3] or 0 -- 转盘奖励
        nextLevelData.p_vipPoint = levelData.vipPoint or 0 -- 升级奖励vip 点数
        nextLevelData.p_clubPoint = levelData.clubPoint or 0

        self.p_nextLevelDatas[#self.p_nextLevelDatas + 1] = nextLevelData
    end
    -- dump(self.p_nextLevelDatas,"self.p_nextLevelDatas",3)
end

function UserRunData:parseSimpleUserInfo(simpleUserInfo)
    if not simpleUserInfo then
        return
    end
    
    local newBucks = tonumber(simpleUserInfo.bucks)
    local newGems = tonumber(simpleUserInfo.gems)
    local newCoins = simpleUserInfo.coinsV2
    local newLevel = tonumber(simpleUserInfo.level)
    local newExp = tonumber(simpleUserInfo.exp)

    self:setBucks(newBucks)
    self:setGems(newGems)
    self:setCoins(newCoins)
    self.levelNum = newLevel
    self.currLevelExper = newExp

    self.vipLevel = simpleUserInfo.vipLevel
    self.vipPoints = simpleUserInfo.vipPoint

    self.rcId = simpleUserInfo.rcId
end

-- 金钻数量（第三货币、代币）
function UserRunData:setBucks(buckNum)
    buckNum = buckNum or 0
    self.buckNum = math.max(0, buckNum)
end

function UserRunData:getBucks()
    return math.max(0, self.buckNum)
end


-- 钻石数量
function UserRunData:setGems(gemNum)
    gemNum = gemNum or 0
    self.gemNum = math.max(0, gemNum)
end

function UserRunData:getGems()
    return math.max(0, self.gemNum)
end

--[[
    @desc: 获得持有金币
    @return: toLongNumber
]]
function UserRunData:getCoins()
    return self.coinNum
end
--[[
    @desc: 获得持有金币字符串
    @return: string
]]
function UserRunData:getCoinsStr()
    return tostring(self.coinNum)
end

--[[
    @desc: 设置持有金币
    @strCoins: string
]]
function UserRunData:setCoins(strCoins)
    -- self.coinNum = tonumber(strCoins)
    if DEBUG == 2 then
        assert(strCoins ~= "", "error strCoins!!!!")
    end
    if strCoins == "" then
        util_sendToSplunkMsg("coinsError", "strCoins is error!!!!")
    end
    if iskindof(self.coinNum,"LongNumber") then
        self.coinNum:setNum(strCoins)
    else
        self.coinNum = toLongNumber(strCoins)
    end
end

-- 添加金币
-- function UserRunData:addCoins(_coins)
--     local totalCoins = ""

--     self.coinNum = self.coinNum + _coins
--     totalCoins = tostring(self.coinNum)

--     return totalCoins
-- end

--升级奖励顺序数据
function UserRunData:parseRewardOrderData(rewardDataList)
    if not rewardDataList or #rewardDataList == 0 then
        return
    end
    self.p_rewardOrderDatas = {}
    for i = 1, #rewardDataList do
        local data = rewardDataList[i]
        local rewardData = LevelOrderData:create()
        rewardData.p_position = data.position -- 顺序
        rewardData.p_name = data.name -- 名字 类型
        rewardData.p_openLevel = data.showLeft -- 开启等级
        rewardData.p_closeLevel = data.showRight -- 开启等级
        rewardData.p_open = data.condition -- 是否开启
        self.p_rewardOrderDatas[#self.p_rewardOrderDatas + 1] = rewardData
    end
end
--升级奖励顺序数据
function UserRunData:getLevelOrderDatas()
    if not self.p_rewardOrderDatas then
        return
    end
    local orderList = {}
    for i = 1, #self.p_rewardOrderDatas do
        local data = self.p_rewardOrderDatas[i]
        if data:isOpen() then
            orderList[#orderList + 1] = data
        end
    end
    if #orderList >= 2 then
        table.sort(
            orderList,
            function(a, b)
                return a.p_position < b.p_position
            end
        )
    end
    return orderList
end
--升级数据
function UserRunData:getLevelUpRewardInfo(levelIdx)
    if levelIdx == nil then
        return nil
    end
    if self.p_preLevelData and self.p_preLevelData.p_level == levelIdx then
        return self.p_preLevelData
    elseif self.p_curLevelData.p_level == levelIdx then
        return self.p_curLevelData
    else
        for i = 1, #self.p_nextLevelDatas do
            local levelData = self.p_nextLevelDatas[i]
            if levelData.p_level == levelIdx then
                return levelData
            end
        end
    end
    return nil
end

--[[
    @desc: 获取当前等级升级到下一级所需要的经验值
    time:2019-04-12 11:37:55
    --@levelIdx:
    @return:
]]
function UserRunData:getLevelUpgradeNeedExp(levelIdx)
    if levelIdx == nil then
        return 0
    end
    if self.p_preLevelData and self.p_preLevelData.p_level == levelIdx then
        return self.p_preLevelData.p_exp
    elseif self.p_curLevelData.p_level == levelIdx then
        return self.p_curLevelData.p_exp
    else
        for i = 1, #self.p_nextLevelDatas do
            local levelData = self.p_nextLevelDatas[i]
            if levelData.p_level == levelIdx then
                return levelData.p_exp
            end
        end
    end

    return 0
end

---
-- 获取当前关卡过关需要的经验值
--
function UserRunData:getPassLevelNeedExperienceVal()
    local needExp = self:getLevelUpgradeNeedExp(self.levelNum)
    return needExp
end

--[[
    @desc: 同步服务器时间
    time:2019-04-23 17:22:28
    --@serverTime:
    @return:
]]
local schedulerUpdateTimeID = nil
function UserRunData:syncServerTime(serverTime, isNotifyTimeUpdate)
    self.p_serverTime = tonumber(serverTime) or 0
    self.m_loaclLastTime = socket.gettime()

    isNotifyTimeUpdate = true

    if isNotifyTimeUpdate == true then
        -- 通知更新服务器时间
        gLobalNoticManager:postNotification(GlobalEvent.ServerTime_Status)
    end
end

-- 全局时间定时器
function UserRunData:sysServerTmSchedule()
    if schedulerUpdateTimeID == nil then
        schedulerUpdateTimeID =
            scheduler.scheduleUpdateGlobal(
            function(dt)
                local spanTime = 0
                local curTimes = 0
                if self.m_loaclLastTime then
                    if gLobalViewManager.transitionSceneFlag then
                        return
                    end
                    spanTime, curTimes = self:getSpanTimes()
                    self.m_loaclLastTime = curTimes
                    self:checkAccCheat(spanTime, dt)
                    local timeOutSecs = RESET_GAME_TIME
                    if spanTime >= timeOutSecs then
                        --不是因为广告 邮件等操作进入后台
                        if not globalData.skipForeGround then
                            gLobalDataManager:setNumberByField("ReStartGameStatus", 4)
                            if gLobalGameHeartBeatManager then
                                gLobalGameHeartBeatManager:stopHeartBeat()
                            end

                            scheduler.unscheduleGlobal(schedulerUpdateTimeID)
                            schedulerUpdateTimeID = nil
                            util_restartGame()
                            return
                        end
                    end
                end
                local newServerTime = self.p_serverTime + spanTime * 1000
                -- 检测零点时刻
                self:checkMidNightMoment(self.p_serverTime, newServerTime)
                self.p_serverTime = newServerTime
            end
        )
    end
end

function UserRunData:getSpanTimes()
    local _cur = socket.gettime()
    if self.m_loaclLastTime then
        return (_cur - self.m_loaclLastTime), _cur
    else
        return 0, _cur
    end
end

function UserRunData:stopServerTmSchedule()
    if schedulerUpdateTimeID ~= nil then
        scheduler.unscheduleGlobal(schedulerUpdateTimeID)
        schedulerUpdateTimeID = nil
    end
end

-- 检测零点时刻
function UserRunData:checkMidNightMoment(oldTime, newTime)
    local oldSecs = (math.floor(oldTime / 1000))
    local newSecs = (math.floor(newTime / 1000))
    -- 服务器时间戳转本地时间
    local oldTM = os.date("!*t", (oldSecs - 8 * 3600))
    local newTM = os.date("!*t", (newSecs - 8 * 3600))

    if oldTM.day ~= newTM.day and gLobalSendDataManager:isLogin() then
        -- 零点时间
        -- 刷新倍增器
        if self.m_expireHandlerId5 ~= nil then
            scheduler.unscheduleGlobal(self.m_expireHandlerId5)
        end
        self.m_expireHandlerId5 =
            scheduler.performWithDelayGlobal(
            function()
                local callFunc = function()
                    if self.m_expireHandlerId5 ~= nil then
                        scheduler.unscheduleGlobal(self.m_expireHandlerId5)
                        self.m_expireHandlerId5 = nil
                    end
                end
                G_GetMgr(G_REF.CashBonus):refreshMultiply(callFunc)
            end,
            2,
            "refreshCashBonusMultiply"
        )

        if self.m_expireHandlerId ~= nil then
            scheduler.unscheduleGlobal(self.m_expireHandlerId)
        end
        self.m_expireHandlerId =
            scheduler.performWithDelayGlobal(
            function()
                local callFunc = function(resData)
                    self:dailyFreshSuccess(resData)
                    if self.m_expireHandlerId ~= nil then
                        scheduler.unscheduleGlobal(self.m_expireHandlerId)
                        self.m_expireHandlerId = nil
                    end
                end
                gLobalSendDataManager:getNetWorkFeature():sendDailyRefresh(callFunc)
            end,
            5,
            "dailyRefresh"
        )
        -- 清理记录的插屏广告的播放次数
        gLobalAdsControl:resetTodayPlayAdTimes()

        -- 清理弹板CD数据
        globalData.popCdData:clearLocalData()

        -- 零点统一事件
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SERVER_TIME_ZERO)

        -- 零点关掉活动入口界面
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ENTRENCE_CLOSE_LAYER)

        -- 在线情况下零点需要记录更新标签，用于下一次退出关卡自动登陆热更
        self.m_isEnterUpdateFormLevelToLobby = true
        -- 零点关闭第二货币的二级弹板
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZERO_CLOSE_GEM_POP_UI)
    end
end

function UserRunData:dailyFreshSuccess(data)
    if data then
        if data.multiple then
            G_GetMgr(G_REF.CashBonus):parseMultipleData(data.multiple)
            gLobalNoticManager:postNotification(ViewEventType.CASHBONUS_UPDATE_MULTIPLE)
        end
    end

    -- 零点通知刷新活动
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ENTRENCE_HOT_TODAY_NUM)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_ZERO_REFRESH)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYTIP_CLOSE)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CONFIG_ZERO_REFRESH)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_REWARDS_END)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AFTER_REQUEST_ZERO_REFRESH)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MEMORYLANE_ZERO_REFRESH)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_ZERO_REFRESH)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_ZERO_REFRESH) -- 活动刷新（之后活动都用这条消息，不用新加了）
end

function UserRunData:getIntervalTime()
    return math.random(8, 15)
end
--检查加速作弊
function UserRunData:checkAccCheat(_spanTime, _dt)
    self.m_totoleSpanTime = self.m_totoleSpanTime + _spanTime
    self.m_totoleDt = self.m_totoleDt + _dt
    -- release_print("_spanTime ".. _spanTime .. " _dt ".._dt)
    --取一次样归零
    if self.m_totoleSpanTime >= self.m_intervalTime then
        --如果误差大于1.1 认为不正常
        self.m_bSamplingT[#self.m_bSamplingT + 1] = self.m_totoleDt / self.m_totoleSpanTime > self.CHEAT_SAMPLING_RATIO

        if table.nums(self.m_bSamplingT) > self.CHEAT_SAMPLING_TOTLE_TIMES then
            table.remove(self.m_bSamplingT, 1)
        end

        self.m_totoleSpanTime = 0
        self.m_totoleDt = 0
        self.m_intervalTime = self:getIntervalTime()
    end

    -- release_print("-----------------------------------")
    -- for i=1,#self.m_bSamplingT do
    --     if self.m_bSamplingT[i] then
    --         release_print("self.m_bSamplingT " .. "cheat")
    --     else
    --         release_print("self.m_bSamplingT " .. "nocheat")
    --     end
    -- end
end

function UserRunData:checkIsCheatUser()
    --取样次数小于 5次 默认正常用户
    if table.nums(self.m_bSamplingT) < self.CHEAT_SAMPLING_TOTLE_TIMES then
        return false
    end

    --如果取样中有一次不满足作弊(为false) 则认为不是作弊 全满足则是作弊
    for i = 1, #self.m_bSamplingT do
        if self.m_bSamplingT[i] == false then
            return false
        end
    end
    return true
end

function UserRunData:getFbBindReward()
    return self.m_fbBindReward
end

function UserRunData:setFbBindReward(reward)
    self.m_fbBindReward = tonumber(reward)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FBREWARD_UPDATE)
end

--新用户金币不足奖励
function UserRunData:getNewUserReward()
    return self.m_newUserReward or 0
end
function UserRunData:setNewUserReward(reward)
    self.m_newUserReward = tonumber(reward)
end

--是否去领取流失回归奖励
function UserRunData:getIsChurnReturn()
    if self.m_userChurnReturnInfo and (self.m_userChurnReturnInfo.p_returnUser or self.m_userChurnReturnInfo.p_churnUser) then
        return true
    end
    return false
end
function UserRunData:isReturnUser()
    if self.m_userChurnReturnInfo and self.m_userChurnReturnInfo:isReturnUser() then
        return true
    end
    return false
end

function UserRunData:getUserChurnReturnInfo()
    return self.m_userChurnReturnInfo
end
function UserRunData:setUserChurnReturnInfo(churnReturn)
    -- message ChurnReturn {
    --     optional bool returnUser = 1; //是否回归
    --     optional bool churnUser = 2; //是否流失
    --   }
    if not self.m_userChurnReturnInfo then
        self.m_userChurnReturnInfo = ReturnSignData:create()
    end
    self.m_userChurnReturnInfo:parseData(churnReturn)
end
function UserRunData:removeUserChurnReturnInfo()
    self.m_userChurnReturnInfo = nil
end

-- 关卡返回大厅是否需要跳转热更
function UserRunData:isEnterUpdateFormLevelToLobby()
    return self.m_isEnterUpdateFormLevelToLobby
end

function UserRunData:setEnterUpdateFormLevelToLobby(flag)
    self.m_isEnterUpdateFormLevelToLobby = flag
end

function UserRunData:setUserCommunication(_communication)
    self.m_communication = _communication
end

function UserRunData:getUserCommunication()
    return self.m_communication
end

-- 巅峰竞技场奖杯数据 登录显示 个人信息页里展示
function UserRunData:parseLeagueTrophyData(_data)
    local userTrophyData = self:getLeagueTrophyData()
    userTrophyData:parseData(_data)
end
function UserRunData:getLeagueTrophyData()
    if not self.m_userTrophyData then
        local LeagueTrophyData = require "activities.Activity_Leagues.model.LeagueTrophyData"
        self.m_userTrophyData = LeagueTrophyData:create()
    end

    return self.m_userTrophyData
end

-- 保存关卡进大厅重启信息
function UserRunData:saveLeveToLobbyRestartInfo()
    -- if self.m_isEnterUpdateFormLevelToLobby then
    local tbData = {
        url = DATA_SEND_URL,
        log = LOG_RecordServer, --日志服地址
        hotUpdate = Android_VERSION_URL, --热更服地址
        level = LEVELS_ZIP_URL, --关卡下载地址
        dynamic = DYNAMIC_DOWNLOAD_URL --动态下载地址
    }

    local strData = cjson.encode(tbData)
    gLobalDataManager:setStringByField("LeveToLobbyRestartInfo", strData)

    -- end
end

return UserRunData
