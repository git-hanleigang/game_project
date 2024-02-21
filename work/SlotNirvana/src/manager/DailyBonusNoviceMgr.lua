--[[
    新手期每日签到 - 管理器
]]
local DailyBonusNoviceMgr = class("DailyBonusNoviceMgr", require "network.NetWorkBase")

function DailyBonusNoviceMgr:ctor()
    if globalData.dailyBonusNoviceData then
        self.m_dailyBonusNoviceData = globalData.dailyBonusNoviceData
    end
end

function DailyBonusNoviceMgr:getInstance()
    if not self._instance then
        self._instance = DailyBonusNoviceMgr:create()
    end
    return self._instance
end

function DailyBonusNoviceMgr:getDailyBonusNoviceData()
    return self.m_dailyBonusNoviceData
end

function DailyBonusNoviceMgr:getDailyBonusNoviceDataDay()
    return self.m_dailyBonusNoviceData:getDay()
end

function DailyBonusNoviceMgr:getDailyBonusNoviceDataDays()
    return self.m_dailyBonusNoviceData:getDays()
end

function DailyBonusNoviceMgr:getOnThatDayData()
    return self.m_dailyBonusNoviceData:getOnThatDayData()
end

--请求服务器数据
function DailyBonusNoviceMgr:requestCumulativeData(_day)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(_target, _resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYBONUSNOVICE_SIGN_SUC, {resData = _resData, index = _day})
    end

    local failedCallback = function(_target, _errorCode, _errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    local actionData = self:getSendActionData(ActionType.NoviceCheckSignIn)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallback, failedCallback)
end

--当前天是否能够签到
function DailyBonusNoviceMgr:isSign()
    local days = self:getDailyBonusNoviceDataDays()
    local day = self:getDailyBonusNoviceDataDay()
    if days and day and days[day] and days[day].collect == false then
        return true
    end
    return false
end

function DailyBonusNoviceMgr:showMainLayer()
    if not globalDynamicDLControl:checkDownloaded("DailyBonusNovice") then
        return nil
    end

    local viewPath = "DailyBonusNoviceCode.DailyBonusNovice"
    local view = util_createView(viewPath)
    if view then
        gLobalViewManager:showUI(view)
    end

    return view
end

function DailyBonusNoviceMgr:showRewardLayer(_rewardData, _cb)
    local viewPath = "DailyBonusNoviceCode.DailyBonusNoviceReward"
    local view = util_createView(viewPath, _rewardData, _cb)
    if view then
        gLobalViewManager:showUI(view)
    end

    return view
end

return DailyBonusNoviceMgr
