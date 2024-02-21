--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2020-11-26 17:10:29
]]
local DailySignBonusManager = class("DailySignBonusManager", require "network.NetWorkBase")
local ShopItem = util_require("data.baseDatas.ShopItem")

function DailySignBonusManager:ctor()
    if globalData.dailySignData then
        self.m_dailySignData = globalData.dailySignData
        self.m_isSound = false --是否已有音效
    end
end

function DailySignBonusManager:getInstance()
    if not self._instance then
        self._instance = DailySignBonusManager:create()
    end
    return self._instance
end

function DailySignBonusManager:getDailySignData()
    return self.m_dailySignData
end

function DailySignBonusManager:getDailySignDataDay()
    return self.m_dailySignData:getDay()
end

function DailySignBonusManager:getDailySignDataDays()
    return self.m_dailySignData:getDays()
end

function DailySignBonusManager:getDailySignDataPoint()
    return self.m_dailySignData:getPoint()
end

function DailySignBonusManager:getDailySignDataRewards()
    return self.m_dailySignData:getRewards()
end

function DailySignBonusManager:getDailySignDataBegin()
    return self.m_dailySignData:getBegin()
end

function DailySignBonusManager:getOnThatDayData()
    return self.m_dailySignData:getOnThatDayData()
end

function DailySignBonusManager:setSignDataFlag()
    self.m_dailySignData:setDataFlag(false)
end

function DailySignBonusManager:setSound(_flag)
    self.m_isSound = _flag
end

function DailySignBonusManager:getSound()
    return self.m_isSound
end

--请求服务器数据
function DailySignBonusManager:requestCumulativeData(_collectDay, _successCallFun, _faildCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    -- successCallFun = function(_tager,_resData)
    --     --保存签到完的数据
    --     self.m_dailySignData:parseData(_resData)
    -- end
    -- faildCallFun = function()
    --     gLobalViewManager:showReConnect()
    -- end

    local actionData = self:getSendActionData(ActionType.DailySignCollect)

    local params = {}
    params.collectDay = _collectDay
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, _successCallFun, _faildCallFun)
end

--跨天请求
function DailySignBonusManager:requestSignData()
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local actionData = self:getSendActionData(ActionType.DailySignRefresh)
    local params = {}
    local successCallFun = function(_target, _resData)
        if _resData and _resData.config and _resData.config.dailySign and globalData.dailySignData then
            globalData.dailySignData:parseData(_resData.config.dailySign)
        end
    end
    local faildCallFun = function(_target, errorCode, errorData)
        local errorInfo = {}
        errorInfo.errorCode = errorCode
        errorInfo.errorMsg = errorData
        gLobalViewManager:showReConnect(nil, false, errorInfo)
    end
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, faildCallFun)
end
--当前天是否签到
function DailySignBonusManager:isSign()
    local days = self:getDailySignDataDays()
    local day = self:getDailySignDataDay()
    if days and day and days[day] and days[day].collected == true then
        return true
    end
    return false
end

--处理签到奖励数据
function DailySignBonusManager:getDaysRewardByIndex(_index)
    return self.m_dailySignData:getRewardList(_index)
end

function DailySignBonusManager:showMainLayer()
    if not globalDynamicDLControl:checkDownloaded("DailyBonus") then
        return nil
    end

    local viewPath = "views.Activity_DailyBonus.Activity_DailyBonus"
    local sevenDaySignView = util_createView(viewPath)
    if sevenDaySignView then
        gLobalViewManager:showUI(sevenDaySignView)
    end

    return sevenDaySignView
end

return DailySignBonusManager
