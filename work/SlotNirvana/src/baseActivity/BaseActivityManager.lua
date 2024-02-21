--[[
    author:JohnnyFred
    time:2019-11-19 10:14:53
]]
local NetWorkBase = util_require("network.NetWorkBase")
local BaseActivityManager = class("BaseActivityManager", NetWorkBase)

function BaseActivityManager:ctor()
    self:setSendMsgCount(0)
end

function BaseActivityManager:setSendMsgCount(count)
    self.sendMsgCount = count
end

function BaseActivityManager:getSendMsgCount()
    return self.sendMsgCount
end

function BaseActivityManager:isSendMsgCountEmpty()
    return self:getSendMsgCount() == 0 and (globalData.slotRunData.spinNetState == GAME_EFFECT_OVER_STATE or globalData.slotRunData.spinNetState == nil)
end

function BaseActivityManager:addSendMsgCount(count)
    self:setSendMsgCount(self:getSendMsgCount() + count)
end

function BaseActivityManager:sendMsgBaseFunc(actionType, actionParam, params, successCallBack, failedCallBack)
    if gLobalSendDataManager:isLogin() then
        local function successFunc(target, resData)
            if self.addSendMsgCount ~= nil then
                self:addSendMsgCount(-1)
            end
            if successCallBack ~= nil then
                successCallBack(resData)
            end
        end

        local function failedFunc(target, code, errorMsg)
            if self.setSendMsgCount ~= nil then
                self:setSendMsgCount(0)
            end
            if failedCallBack then
                failedCallBack(code, errorMsg)
            end
            if code == 500 or code == SYSTEM_ERROR then
                gLobalViewManager:removeLoadingAnima()
                gLobalViewManager:showReConnect(true)
            end
        end

        local actionData = self:getSendActionData(actionType, actionParam)
        local dataInfo = actionData.data
        dataInfo.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
        dataInfo.balanceGems = 0
        dataInfo.rewardCoins = 0 --奖励金币
        dataInfo.rewardGems = 0 --奖励钻石
        dataInfo.version = self:getVersionNum()
        if params ~= nil then
            dataInfo.params = cjson.encode(params)
        end
        self:sendMessageData(actionData, successFunc, failedFunc)
        self:addSendMsgCount(1)
    end
end

function BaseActivityManager:saveUserExtraData(data)
    if data ~= nil then
        local actionData = self:getSendActionData(ActionType.SyncUserExtra)
        local dataInfo = actionData.data
        dataInfo.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
        dataInfo.balanceGems = 0
        dataInfo.rewardCoins = 0 --奖励金币
        dataInfo.rewardGems = 0 --奖励钻石
        dataInfo.version = self:getVersionNum()
        local extraDataKey = self:getExtraDataKey()
        if extraDataKey ~= nil then
            local extraData = {}
            extraData[extraDataKey] = data
            dataInfo.extra = cjson.encode(extraData)
        end
        self:sendMessageData(actionData)
    end
end

function BaseActivityManager:sendMessageData(body, successCallBack, failedCallBack)
    if gLobalSendDataManager:isLogin() then
        NetWorkBase.sendMessageData(self, body, successCallBack, failedCallBack)
    end
end

function BaseActivityManager:getUserDefaultValue()
    return gLobalDataManager:getStringByField(self:getUserDefaultKey(), "")
end

function BaseActivityManager:setUserDefaultValue(value)
    gLobalDataManager:setStringByField(self:getUserDefaultKey(), value)
end
------------------------------------------子类重写---------------------------------------
function BaseActivityManager:getExtraDataKey()
    return nil
end

function BaseActivityManager:getUserDefaultKey()
    return nil
end
------------------------------------------子类重写---------------------------------------
return BaseActivityManager
