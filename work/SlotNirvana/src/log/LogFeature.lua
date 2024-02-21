--
-- 发送 各个系统的消息 ，如果系统木块过大 则开分出来独立的
-- Author:{author}
-- Date: 2019-05-16 18:13:45
--
local NetworkLog = require "network.NetworkLog"
local LogFeature = class("LogFeature", NetworkLog)
LogFeature.m_logTaskType = nil
LogFeature.m_logTaskData = nil
function LogFeature:ctor()
    NetworkLog.ctor(self)
end

function LogFeature:sendLogMessage(...)
    local args = {...}
    --TODO 在这里组织你感兴趣的数据

    NetworkLog.sendLogData(self)
end
--gLobalSendDataManager:getLogFeature():
--fb登录
function LogFeature:sendBindFB(position, result)
    gL_logData:syncUserData()
    gL_logData:syncEventData("BindFB")
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.BindFB)
    end
    local messageData = {
        bindTime = util_getymdhms_format(),
        facebookId = globalData.userRunData.fbUdid,
        new = globalData.userRunData:isNewUser(),
        position = position,
        result = result,
        awardId = "FBReward",
        awardDetails = globalData.userRunData.FB_LOGIN_FIRST_REWARD
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end
function LogFeature:updateStartTime()
end
--loading1.加载类型 2.资源名称 3.加载状态  ---弃用不再发
function LogFeature:sendGameLoadLog(loadType, loadName, result)
end
--是否是动态下载
function LogFeature:checkDynamicDownload()
end
--1.加载步骤 2.更新步骤 3.资源文件 4.检测状态 5.失败原因
function LogFeature:setGameLoadInfo(key, value)
end
--邮件相关log
function LogFeature:sendInboxLog(inboxData, readTime, drawTime)
    gL_logData:syncUserData()
    gL_logData:syncEventData("Inbox")
    local logType = 2 --inboxData.logType

    if not inboxData then
        inboxData = {}
        logType = nil
    end

    local coins = nil
    if inboxData.awards then
        coins = inboxData.awards.coins
    end

    local itemType = 1
    local vipPoints = nil
    local extra = inboxData.extra
    local activityName = nil
    if extra ~= nil and extra ~= "" then
        local missionData = cjson.decode(extra)
        if missionData and missionData.activityName then
            activityName = missionData.activityName
        end
        local buffs = missionData.buff
    -- if buffs then
    --       for i = 1, #buffs, 1 do
    --             local buff = {}
    --             buff.buffID = data[i].id                         -- buff 唯一ID
    --             buff.buffType = data[i].type                     -- buff 类型
    --             buff.buffDescription = data[i].description       -- buff 描述
    --             buff.buffDuration = data[i].duration             -- buff 持续时间
    --             buff.buffExpire = data[i].expire                 -- buff 剩余时间
    --             buff.buffMultiple = data[i].multiple             -- buff 加成
    --             buff.buffSysTime = os.time()
    --             self.p_allBuffs[buff.buffType] = buff
    --       end
    -- end
    end

    -- if inboxData.type ==

    local messageData = {
        sendTime = inboxData.validStart,
        readTime = util_chaneTimeFormat(readTime),
        drawTime = util_chaneTimeFormat(drawTime),
        logType = logType, --官方发送=1、运营发送=9、用户领取=2
        inboxType = itemType, --通知=0、金币=1、活动奖励=2
        item = itemType, --1金币 2vip
        expireAt = inboxData.validEnd,
        --过期时间
        coins = coins,
        mailType = inboxData.type,
        mailTitle = inboxData.title,
        mailContent = inboxData.content,
        activityName = activityName,
        vipPoints = nil
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end
--cashBonusLog
function LogFeature:sendCashBonusLog(type, coinsData, multiple, multipleExp)
    if not coinsData then
        coinsData = {}
    end

    gL_logData:syncUserData()
    gL_logData:syncEventData("FreeCoins")
    local messageData = {
        task = "CashBonus",
        type = type,
        rewardCoins = coinsData.rewardCoins,
        rewardStatus = coinsData.rewardStatus,
        tapTimes = coinsData.tapTimes,
        addCoinsVip = coinsData.addCoinsVip,
        addCoinsDaily = coinsData.addCoinsDaily,
        addCoinsMultiple = coinsData.addCoinsMultiple,
        days = coinsData.days,
        multipleVip = coinsData.multipleVip,
        multipleDaily = coinsData.multipleDaily,
        multiple = multiple,
        multipleExp = multipleExp
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end
--wheelLog
function LogFeature:sendCashBonusWheelLog(actionType)
    gL_logData:syncUserData()
    gL_logData:syncEventData("FreeCoins")
    local messageData = {
        task = "Wheel",
        type = 5,
        actionType = actionType
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

function LogFeature:setDailyMissionInfo(type, taskData)
    self.m_logTaskType = type
    self.m_logTaskData = taskData
end

--dailymission
function LogFeature:sendDailyMissionLog(rewardCoins, buffs, actionType)
    local taskData = self.m_logTaskData
    local type = self.m_logTaskType
    if not taskData then
        taskData = {}
    end

    local weekTaskInfo = globalData.missionRunData.p_weekTaskInfo
    local allCollectPoints = nil
    if weekTaskInfo[2] then
        local process, params = weekTaskInfo[2]:getTaskSchedule()
        allCollectPoints = process
    end

    local items = {}
    if buffs and #buffs > 0 then
        for i = 1, #buffs do
            local buff = buffs[i]
            items[#items + 1] = buff.type .. "|" .. buff.id .. "|" .. buff.multiple .. "|" .. buff.expire * 1000 --道具类型|道具ID|道具加成|道具时长
        end
    end

    gL_logData:syncUserData()
    gL_logData:syncEventData("FreeCoins")

    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}

    local messageData = {
        task = "DailyMission",
        time = util_chaneTimeFormat(os.time()),
        type = type,
        -- taskId = taskData.p_taskId,
        rewardCoins = rewardCoins,
        tasksCollectPoints = taskData.p_taskPoint,
        addTasksCollectPoints = allCollectPoints,
        taskLevel = globalData.missionRunData.p_taskInfo.p_difficulty,
        -- taskType = globalData.missionRunData.p_taskInfo.p_taskType,
        actionType = actionType,
        entryType = entryData.entryType
    }
    for i = 1, #items do
        if i >= 6 then
            break
        else
            messageData["item" .. i] = items[i]
        end
    end
    gL_logData.p_data = messageData
    self:sendLogData()
end

--shopGift
function LogFeature:sendShopGiftLog(rewardCoins)
    -- gL_logData:syncUserData()
    -- gL_logData:syncEventData("FreeCoins")
    -- local messageData = {
    --     task = "ShopGift",
    --     type = 13,
    --     rewardCoins = rewardCoins
    -- }
    -- gL_logData.p_data = messageData
    -- self:sendLogData()
end

--levelUP
function LogFeature:sendLevelUp(prevLevel, currentLevel, rewardCoins, vipPoint)
    gL_logData:syncUserData()
    gL_logData:syncEventData("FreeCoins")

    local multiple = globalData.buffConfigData:getAllCoinBuffMultiple(globalData.userRunData.levelNum)
    local buff = 0
    local activityName = nil
    local buffId = nil
    if multiple > 1 then
        buff = 1
    end
    local levelBoomData = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPY_LEVEL_BOOM)
    local levelBurstData = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPY_LEVEL_BURST)
    if levelBoomData and levelBoomData.buffID then
        buffId = levelBoomData.buffID
        local datas = globalData.commonActivityData:getActivitys()
        for key, value in pairs(datas) do
            if value:getRefName() == "Activity_LevelBoom" and value.p_start then
                if string.len(value.p_start) >= 10 then
                    activityName = "levelBoom" .. string.sub(value.p_start, 1, 4) .. string.sub(value.p_start, 6, 7) .. string.sub(value.p_start, 9, 10)
                else
                    activityName = "levelBoom" .. value.p_start
                end
                break
            end
        end
    elseif levelBurstData and levelBurstData.buffID then
        buffId = levelBurstData.buffID
    end
    local messageData = {
        task = "LevelUp",
        type = 14,
        prevLevel = prevLevel,
        currentLevel = currentLevel,
        rewardCoins = rewardCoins,
        vipPoints = vipPoint,
        buff = buff,
        activityName = activityName,
        buffId = buffId,
        multipler = multiple
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

--新手任务
function LogFeature:sendNewTask(taskId, rewardCoins)
    -- gL_logData:syncUserData()
    -- gL_logData:syncEventData("FreeCoins")
    -- local messageData = {
    --     task = "NewTask",
    --     type = 16,
    --     taskId = taskId,
    --     rewardCoins = rewardCoins
    -- }
    -- gL_logData.p_data = messageData
    -- self:sendLogData()
end
--初始金币奖励
function LogFeature:sendNewUserCoins(rewardCoins)
    -- gL_logData:syncUserData()
    -- gL_logData:syncEventData("FreeCoins")
    -- local messageData = {
    --     task = "StartUp",
    --     type = 17,
    --     rewardCoins = rewardCoins
    -- }
    -- gL_logData.p_data = messageData
    -- self:sendLogData()
end
--版本更新
function LogFeature:sendNewVersion(rewardCoins, lastVerision)
    gL_logData:syncUserData()
    gL_logData:syncEventData("FreeCoins")
    local messageData = {
        task = "VersionUp",
        type = 18,
        lastVerision = lastVerision,
        rewardCoins = rewardCoins
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

function LogFeature:sendFBCoins(rewardCoins)
    gL_logData:syncUserData()
    gL_logData:syncEventData("FreeCoins")
    local messageData = {
        task = "BindFBCoins",
        type = 19,
        rewardCoins = rewardCoins
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end
-- 高倍场积分兑换金币打点接口
function LogFeature:sendClubPointExchangeCoin(pointsNum, rewardCoins)
    -- gL_logData:syncUserData()
    -- gL_logData:syncEventData("FreeCoins")
    -- local messageData = {
    --     task = "ClubPoints",
    --     taskId = 21,
    --     pointsNum = pointsNum,
    --     rewardCoins = rewardCoins
    -- }
    -- gL_logData.p_data = messageData
    -- self:sendLogData()
end

function LogFeature:getTimeStamp(unixTime)
    -- body
    local tb = nil

    if unixTime and unixTime >= 0 then
        tb = {}
        tb.year = tonumber(os.date("%Y", unixTime))
        tb.month = tonumber(os.date("%m", unixTime))
        tb.day = tonumber(os.date("%d", unixTime))
        tb.hour = tonumber(os.date("%H", unixTime))
        tb.minute = tonumber(os.date("%M", unixTime))
        tb.second = tonumber(os.date("%S", unixTime))
    end
    return tb
end

--一系列动作的sid
function LogFeature:createUIActionSid(SessionType, isForce)
    self.m_uiActionSid = globalData.userRunData.uid .. "_" .. SessionType .. "_" .. os.time()
    if isForce then
        self.m_uiActionStatus = "Force"
    else
        self.m_uiActionStatus = "Free"
    end
end

--一系列动作的资源文件名称
function LogFeature:createUIActionNameDetailed(nameDetailed)
    if nameDetailed then
        self.m_uiActionNameDetailed = nameDetailed
    end
end
--一系列动作log
function LogFeature:sendUIActionLog(name, type, isForce)
    if not self.m_uiActionSid then
        return
    end
    if isForce then
        self.m_uiActionStatus = "Force"
    end
    gL_logData:syncUserData()
    gL_logData:syncEventData("UIAction")
    local messageData = {
        sid = self.m_uiActionSid,
        name = name,
        type = type,
        status = self.m_uiActionStatus,
        nameDetailed = self.m_uiActionNameDetailed
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

--通过推送进入游戏log
function LogFeature:sendNotifyLog(_logData)
    if not _logData then
        return
    end

    gL_logData:syncUserData()
    gL_logData:syncEventData("PushLogin")
    gL_logData.p_data = _logData

    self:sendLogData()
end

--广告召回
function LogFeature:sendADCallBackLog(type, coins)
    gL_logData:syncUserData()
    gL_logData:syncEventData("UserBack")
    local messageData = {
        actionType = type,
        rewardCoins = coins
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

function LogFeature:sendBonusHuntLog(type)
    gL_logData:syncUserData()
    gL_logData:syncEventData("BonusHunt")
    local messageData = {
        type = type
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

function LogFeature:sendLuckyChallengeLog(type, pageName)
    local data = G_GetMgr(ACTIVITY_REF.LuckyChallenge):getRunningData()
    if not data then
        return
    end

    gL_logData:syncUserData()
    gL_logData:syncEventData("GemPage")
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}

    local messageData = {
        tp = type,
        pn = pageName,
        lv = data.level,
        s = data.season
    }
    if entryData.entryType then
        messageData.et = entryData.entryType
    end
    if entryData.entryType then
        messageData.en = entryData.entryName
    end
    if entryData.entryType then
        messageData.eo = entryData.entryOpen
    end
    gL_logData.p_data = messageData
    self:sendLogData()
end
--充值抽奖活动
function LogFeature:sendLuckyChipsDrawLog()
    gL_logData:syncUserData()
    gL_logData:syncEventData("LuckyChipsPopup")
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    local messageData = {
        tp = "Open",
        s = CardSysRuntimeMgr:getCurAlbumID(),
        et = entryData.entryType,
        en = entryData.entryName,
        eo = entryData.entryOpen,
        pn = "LuckyChipsLobby"
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

--repart活动打点 action:(FreeSpinReturn,JackpotReturn) type(Open.Clikc)
function LogFeature:sendRepartActivity(action, type, activityName)
    if activityName then
        activityName = string.gsub(activityName, "-", "")
    end
    gL_logData:syncUserData()
    gL_logData:syncEventData(action)
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    local messageData = {
        tp = type,
        name = activityName,
        s = CardSysRuntimeMgr:getCurAlbumID(),
        et = entryData.entryType,
        en = entryData.entryName,
        eo = entryData.entryOpen
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

-- 商城4个折扣券活动
function LogFeature:sendSaleTicketLog()
    local data = G_GetMgr(ACTIVITY_REF.SaleTicket):getRunningData()
    if not data then
        return
    end
    if data.p_start == nil then
        return
    end
    gL_logData:syncUserData()
    gL_logData:syncEventData("SaleTicket")
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    local messageData = {
        tp = "Open",
        et = entryData.entryType,
        en = entryData.entryName,
        eo = entryData.entryOpen,
        name = "SaleTicket" .. string.sub(data.p_start, 1, 4) .. string.sub(data.p_start, 6, 7) .. string.sub(data.p_start, 9, 10)
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

-- 剁手星期一打点
function LogFeature:sendCyberMondayLog(logType)
    local data = G_GetActivityDataByRef(ACTIVITY_REF.CyberMonday)
    if not data then
        return
    end
    if data.p_start == nil then
        return
    end
    gL_logData:syncUserData()
    gL_logData:syncEventData("MondayCoupon")
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    local messageData = {
        tp = logType,
        et = entryData.entryType,
        en = entryData.entryName,
        eo = entryData.entryOpen,
        pn = "Activity_CyberMonday",
        name = "MondaySale" .. string.sub(data.p_start, 1, 4) .. string.sub(data.p_start, 6, 7) .. string.sub(data.p_start, 9, 10)
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

-- 新关开启打点
function LogFeature:sendOpenNewLevelLog(logType, params)
    params = params or {}
    gL_logData:syncUserData()
    gL_logData:syncEventData("NewPopup")
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    local messageData = {
        tp = logType,
        et = entryData.entryType,
        en = entryData.entryName,
        eo = entryData.entryOpen,
        pn = params.pn or "NewGame",
        ts = params.ts or "0"
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

-- 点击AIHelp打点
function LogFeature:sendClickAIHelpLog(_clickType)
    if not _clickType then
        return
    end

    gL_logData:syncUserData()
    gL_logData:syncEventData("FeedBack")
    local messageData = {
        clickType = _clickType
    }
    gL_logData.p_data = messageData

    self:sendLogData()
end

-- 拉新活动打点
function LogFeature:sendInviteLog(logType, logAtp, entryName, source)
    local data = G_GetMgr(G_REF.Invite):getData()
    if not data then
        return
    end
    gL_logData:syncUserData()
    gL_logData:syncEventData("InvitePage")
    local messageData = {
        tp = logType,
        atp = logAtp,
        en = entryName,
        s = source
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

function LogFeature:sendLinkLog(logType, logAtp, entryName, source,price)
    gL_logData:syncUserData()
    gL_logData:syncEventData("NewPopup")
    local messageData = {
        tp = logType,
        atp = logAtp,
        en = entryName,
        et = source,
        pn = "LevelLink",
        index = price
    }
    gL_logData.p_data = messageData
    self:sendLogData()
end

-- 公会查看grand分享图片
function LogFeature:sendPopGrandShareImgLog(_msgId, _clickType, _clanId, _clanName)
    if not _msgId or not _clickType then
        return
    end

    gL_logData:syncUserData()
    gL_logData:syncEventData("BoundarClick")
    local messageData = {
        tp = "Enlarge",
        atp = _clickType,
        cs = "TeamClan",
        cInfo = {
            tid = _clanId,
            name = _clanName,
            msgId = _msgId,
        }
    }
    gL_logData.p_data = messageData

    self:sendLogData()
end

return LogFeature
