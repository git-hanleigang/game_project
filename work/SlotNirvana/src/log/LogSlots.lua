--
-- 发送 iap消息
-- Author:{author}
-- Date: 2019-05-16 18:13:45
--
local NetworkLog = require "network.NetworkLog"
local LogSlots = class("LogSlots", NetworkLog)
LogSlots.betPosition = nil
LogSlots.m_spinCostTime = nil
-- 客户端配置
local EnterGameSiteType = {
    ["Lobby"] = {
        "RecommendedArea",
        "RegularArea",
        "HightArea"
    },
    ["ActivityLobby"] = {
        "QuestLobby"
    },
    ["Popup"] = {
        "NewGame",
        "NewUser",
        "LevelToGame"
    },
    ["Hight"] = {
        "HightLobby"
    },
    ["Game"] = {},
    ["RecommendArea"] = {
        "NewGame",
        "Hottest",
        "Favorite",
        "LatelyPlay",
        "GuessLike",
        "Theme",
        "likePage"
    }
}

local EnterGameLevelTag = {
    ["new"] = "NewGame",
    ["hot"] = "HotGame",
    ["feature"] = "Feature",
    ["link"] = "Link"
}

LogSlots.EnterLevelStepEnum = {
    START = 1, -- 初始化进入关卡
    DOWNLOAD_CODE_START = 2, -- 代码下载-开始
    DOWNLOAD_CODE_END = 3, -- 代码下载-结束
    DECOMPRESS_CODE_END = 4, -- 解压代码-结束
    DOWNLOAD_RES_START = 5, -- 资源下载-开始
    DOWNLOAD_RES_END = 6, -- 资源下载-结束
    DECOMPRESS_RES_END = 7, -- 解压资源-结束
    LOAD_NEW_SCENE = 8, -- 加载场景
    REQ_ENTER_LEVEL = 9, -- 请求进入关卡
    ENTER_LEVEL = 10, -- 进入关卡
    LOADING_LAYER_EXIT = 11, -- loading界面关闭
    ERROR = 99 -- 错误
}
LogSlots.EnterLevelStepErrorEnum = {
    CODE_DOWNLOAD_ERROR = 1, -- 代码下载错误
    RES_DOWNLOAD_ERROR = 2, -- 资源下载错误
    REQ_ENTER_LEVEL = 3, -- 请求进入关卡
    CANCEL = 4, -- 点击返回按钮
    FIX_DOWNLOAD_BACK = 5 -- 点击fix按钮返回
}

function LogSlots:ctor()
    NetworkLog.ctor(self)
end

function LogSlots:sendLogMessage(...)
    local args = {...}
    --TODO 在这里组织你感兴趣的数据

    NetworkLog.sendLogData(self)
end

-- 新字段EnterGame start --------------------------------------------------------------------------------
-- 因为旧数据GameEnter，存在数据污染，因此添加新字段EnterGame
function LogSlots:resetEnterLevel()
    self.m_site = nil
    self.m_siteType = nil
    self.m_siteName = nil
    self.m_levelName = nil
    self.m_levelType = ""
    self.m_name = nil
end
function LogSlots:setEnterLevelSiteType(siteType)
    self.m_siteType = siteType
end
function LogSlots:setEnterLevelSiteName(siteName)
    self.m_siteName = siteName
end

function LogSlots:setEnterLevelSite(site)
    self.m_site = site
end

function LogSlots:setEnterLevelGameType(gameType)
    self.m_gameType = gameType
end

function LogSlots:getEnterSite()
    if self.m_site then
        return self.m_site
    end
    for enterSite, v in pairs(EnterGameSiteType) do
        for i = 1, #v do
            if v[i] == self.m_siteType then
                return enterSite
            end
        end
    end
    -- 关卡
    if self.m_siteType ~= nil then
        return "Game"
    end
    return nil
end

function LogSlots:getGameType()
    local actNameList = gLobalSendDataManager:getLogIap():getActivityNameList()
    if actNameList and #actNameList > 0 then
        return "activity"
    end
    return "normal"
end

-- 保持跟 LevelNodeControl 同步
function LogSlots:getLevelInfoList()
    local allLevels = globalData.slotRunData.p_machineDatas
    local smallLevels = {}
    local bigLevels = {}
    local highBetLevels = {}
    local isDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
    for k, v in ipairs(allLevels) do
        if isDeluxe then
            if v.p_highBetFlag == true then
                table.insert(highBetLevels, v)
            else
                table.insert(smallLevels, v)
            end
        else
            if v.p_firstOrder then
                table.insert(bigLevels, v)
            else
                table.insert(smallLevels, v)
            end
        end
    end
    return smallLevels, bigLevels, highBetLevels
end

function LogSlots:getEnterLevelOrder(name)
    local smallLevels, bigLevels, highBetLevels = self:getLevelInfoList()
    if #bigLevels > 0 then
        for i = 1, #bigLevels do
            if bigLevels[i].p_name == name then
                return bigLevels[i].p_firstOrder
            end
        end
    end
    if #highBetLevels > 0 then
        for i = 1, #highBetLevels do
            if highBetLevels[i].p_name == name then
                return highBetLevels[i].p_showOrder
            end
        end
    end
    for i = 1, #smallLevels do
        if smallLevels[i].p_name == name then
            return smallLevels[i].p_showOrder + #highBetLevels
        end
    end
end

function LogSlots:setEnterLevelName(clientLevelName, serverLevelname)
    self.m_levelName = clientLevelName
    self.m_name = serverLevelname
end

function LogSlots:sendEnterLevelLog(_stepId, _donwloadInfo, _faildInfo, _cost)
    if not self.m_siteType then
        print("=== LogSlots 'EnterGame' DATA ERROR levelName =, siteType =", self.m_levelName)
        return
    end
    gL_logData:syncUserData()
    gL_logData:syncEventData("EnterGame")

    local order = self:getEnterLevelOrder(self.m_name)

    local messageData = {
        spinSessionId = gL_logData:getNearestGameSessionId(), -- gL_logData:getGameSessionId(), -- spin进入标识
        id = _stepId, -- 进入步骤
        game = self.m_name, -- 关卡名称
        enterInfo = {
            site = self:getEnterSite(), -- 进入位置
            siteType = self.m_siteType, -- 进入关卡入口类型
            siteName = self.m_siteName, -- 关卡分类名
            levelType = self.m_levelType, -- 高倍/普通
            order = order,
            gameType = self.m_gameType or ""
        },
        downloadInfo = _donwloadInfo or {},
        failInfo = _faildInfo or {},
        cost = _cost or 0
    }
    gL_logData.p_data = messageData
    -- self.m_site = nil
    self:sendLogData()
end
-- 新字段EnterGame end --------------------------------------------------------------------------------
-------------------- bet 切换调用 START
--关卡界面调整
function LogSlots:setUIBet()
    self.betPosition = "gameUi"
end
--关卡内
function LogSlots:setGameBet()
    self.betPosition = "game"
end
--maxbet
function LogSlots:setMaxBet()
    self.betPosition = "gameMaxBet"
    self.doLogMaxBet = true
end
--bet提醒
function LogSlots:setRemindBet()
    self.betPosition = "betRemind"
end
-------------------- bet 切换调用 END
--初始化参数
function LogSlots:initSlotLog(machineData, betSite, betNum)
    if not machineData then
        return
    end
    
    local levelName = machineData.p_levelName
    self.order = self:getLevelOrder(levelName)
    self.betSite = betSite or 0
    self.betNum = betNum or 0
    local logTag = machineData.p_Log
    if logTag then
        if logTag == "new" then
            self.recommendType = "new"
        elseif logTag == "hot" then
            self.recommendType = "hot"
        else
            self.recommendType = "normal"
        end
    else
        self.recommendType = "normal"
    end

    -- 普通或高倍场
    if machineData.p_highBetFlag then
        self.m_levelType = "Hight"
    else
        self.m_levelType = "Normal"
    end

end

--spin附加参数回传给服务器
function LogSlots:addSlotData(paramsData)
    paramsData.order = self.order
    paramsData.activityName = gLobalSendDataManager:getLogIap():getGameActivityName()
    if paramsData.activityName then
        paramsData.gameType = "activity"
    else
        paramsData.gameType = "normal"
    end
    local config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if config and config.m_IsQuestLogin and config:isNewUserQuest() --[[config:isOpen()]] then
        paramsData.gameType = "NewQuest"
    end
    paramsData.betPosition = self.betPosition
    paramsData.recommendType = self.recommendType
    paramsData.betSite = self.betSite
    paramsData.betNum = self.betNum
    paramsData.betIndex = globalData.slotRunData:getCurBetIndex()
    paramsData.findLock = globalData.findLock

    --更新spin消耗时间
    self:udpateSpinCostTime()
end
function LogSlots:udpateSpinCostTime()
    --屏蔽spin耗时打印
    -- self.m_spinCostTime = socket.gettime()
    --添加支付打点不额外增加方法放在这里了
    self.m_curTotalBet = globalData.slotRunData:getCurTotalBet()
end
--spin消耗时间
function LogSlots:checkSendSpinCost(resData)
    if self.m_spinCostTime then
        local costTime = (socket.gettime() - self.m_spinCostTime)
        self.m_spinCostTime = nil
        gL_logData:syncUserData()
        gL_logData:syncEventData("SpinCost")
        local messageData = {
            c = costTime
        }
        gL_logData.p_data = messageData
        -- dump(messageData,"SpinCostTime")
        self:sendLogData()
    end
    if self.m_curTotalBet then
        self:updateSpinIapInfo()
    end
end

function LogSlots:updateSpinIapInfo()
    if gLobalSendDataManager and gLobalSendDataManager.getLogIap and gLobalSendDataManager:getLogIap().setSpinLog then
        gLobalSendDataManager:getLogIap():setSpinLog(globalData.userRunData.coinNum, self.m_curTotalBet)
    end
end

--[[
@description: 进入关卡报送 错误描述
@param LogSlots.EnterLevelStepErrorEnum _errorCode
@param int  _cppErrorCode  下载出错时 cpp给的错误码
--]]
function LogSlots:getEnterLevelLogErrorMsg(_errorCode, _cppErrorCode)
    local msg = ""
    if _errorCode == LogSlots.EnterLevelStepErrorEnum.CODE_DOWNLOAD_ERROR then
        msg = " code download error:"
        if _cppErrorCode then
            msg = tostring(_cppErrorCode) .. msg
        end
    elseif _errorCode == LogSlots.EnterLevelStepErrorEnum.RES_DOWNLOAD_ERROR then
        msg = " res download error:"
        if _cppErrorCode then
            msg = tostring(_cppErrorCode) .. msg
        end
    elseif _errorCode == LogSlots.EnterLevelStepErrorEnum.REQ_ENTER_LEVEL then
        msg = "http request enter level game faild"
    elseif _errorCode == LogSlots.EnterLevelStepErrorEnum.CANCEL then
        msg = "user click back button"
    elseif _errorCode == LogSlots.EnterLevelStepErrorEnum.FIX_DOWNLOAD_BACK then
        msg = "user click fix layer back button"
    end

    return msg
end

--不再使用 先不删除 关卡代码太多用到了
function LogSlots:sendPopupLog(triggerType, winCoins)
end

function LogSlots:sendTimeOutLog()
    if  not globalData.slotRunData.machineData then
        return
    end
    local log_data = {}
    log_data.tp = "Spin"
    if globalData.slotRunData.machineData then
        log_data.g = globalData.slotRunData.machineData.p_levelName
    end
    local logSpinType = "normal"

    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
        logSpinType = "auto"
    end

    log_data.atp = logSpinType
    gL_logData:syncEventData("TimeOut")
    gL_logData.p_data = log_data
    self:sendLogData()
end

return LogSlots
