--[[
    月卡 管理层
]]
local MonthlyCardNet = require("GameModule.MonthlyCard.net.MonthlyCardNet")
local MonthlyCardMgr = class("MonthlyCardMgr", BaseGameControl)

function MonthlyCardMgr:ctor()
    MonthlyCardMgr.super.ctor(self)
    self:setRefName(G_REF.MonthlyCard)

    self.m_netModel = MonthlyCardNet:getInstance() -- 网络模块
end

function MonthlyCardMgr:parseData(_data)
    if not _data then
        return
    end

    local data = self:getData()
    if not data then
        data = require("GameModule.MonthlyCard.model.MonthlyCardData"):create()
        data:parseData(_data)
        data:setRefName(G_REF.MonthlyCard)
        self:registerData(data)
    else
        data:parseData(_data)
    end
end

-- data {type = "standard"} 标准版 or {type = "deluxe"} 豪华版
function MonthlyCardMgr:requestMonthlyCardReward(params) --领取月卡奖励
    local successFunc = function(resData) 
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MONTHLYCARD_REQUEST_REWARD, resData)
    end

    local failedCallFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MONTHLYCARD_REQUEST_REWARD, false)
    end
    self.m_netModel:requestMonthlyCardReward(params, successFunc, failedCallFunc)
end

-- data {type = "standard"} 标准版 or {type = "deluxe"} 豪华版
function MonthlyCardMgr:requestBuyMothlyCard(data)
    local successFunc = function()
        gLobalViewManager:checkBuyTipList(function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MONTHLYCARD_REQUEST_BUY, true)
        end)
    end

    local failedCallFun = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MONTHLYCARD_REQUEST_BUY, false)
    end
    self.m_netModel:requestBuyMothlyCard(data, successFunc, failedCallFun)
end

----------------------------------------------- 华丽分割线 -----------------------------------------------

function MonthlyCardMgr:showMainLayer(_param)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("MonthlyCardMainLayer") then
        return nil
    end
    local data = self:getRunningData()
    local param = {type = 2} -- 默认显示豪华版
    if _param then
        param = _param
    else
        local isHasRewardNormal = data:isHasRewardNormal()
        local isHasRewardDeluxe = data:isHasRewardDeluxe()
        if not isHasRewardDeluxe and isHasRewardNormal then
            param = {type = 1}
        end
    end
    local view = util_createFindView("MonthlyCardCode/MonthlyCardMainLayer", param)
    -- 检查资源完整性
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--帮助界面
function MonthlyCardMgr:showMonthlyCardRuleLayer()
    if gLobalViewManager:getViewByExtendData("MonthlyCardRuleLayer") then
        return nil
    end
    local view = util_createView("MonthlyCardCode.MonthlyCardRuleLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--奖励界面
function MonthlyCardMgr:showMonthlyCardRewardLayer(param)
    if gLobalViewManager:getViewByExtendData("MonthlyCardRewardLayer") then
        return nil
    end
    local view = util_createView("MonthlyCardCode.MonthlyCardRewardLayer", param)
    -- 检查资源完整性
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function MonthlyCardMgr:isCoolDown()
    local bPop = false
    local cdTime = gLobalDataManager:getNumberByField("monthlyCardPopCD", 0)
    local curTime = util_getCurrnetTime()
    if curTime - cdTime > 0 then
        bPop = true
    end
    return bPop
end

function MonthlyCardMgr:setCoolDownTime()
    local curTime = util_getCurrnetTime()
    gLobalDataManager:setNumberByField("monthlyCardPopCD", curTime + 24 * 60 * 60)
end

function MonthlyCardMgr:getMonthlyCardIconDeluxe()
    local data = self:getRunningData()
    if data then
        local isBuyMonthlyCardDeluxe = data:isBuyMonthlyCardDeluxe()
        if isBuyMonthlyCardDeluxe then
            local monthlyCardIcon = util_createFindView("MonthlyCardCode/MonthlyCardIcon", {type = 2})
            return monthlyCardIcon
        end
    end
    return nil
end

function MonthlyCardMgr:getMonthlyCardIconNormal()
    local data = self:getRunningData()
    if data then
        local isBuyMonthlyCard = data:isBuyMonthlyCardNormal()
        if isBuyMonthlyCard then
            local monthlyCardIcon = util_createFindView("MonthlyCardCode/MonthlyCardIcon", {type = 1})
            return monthlyCardIcon
        end
    end
    return nil
end

function MonthlyCardMgr:getMonthlyCardIcon()
    local monthlyCardIcon = nil
    local data = self:getRunningData()
    if data then
        local isBuyMonthlyCard = data:isBuyMonthlyCardNormal()
        local isBuyMonthlyCardDeluxe = data:isBuyMonthlyCardDeluxe()
        if isBuyMonthlyCard then
            if isBuyMonthlyCardDeluxe then
                monthlyCardIcon = util_createFindView("MonthlyCardCode/MonthlyCardIcon", {type = 2})
                return monthlyCardIcon
            else
                monthlyCardIcon = util_createFindView("MonthlyCardCode/MonthlyCardIcon", {type = 1})
                return monthlyCardIcon
            end
        else
            if isBuyMonthlyCardDeluxe then
                monthlyCardIcon = util_createFindView("MonthlyCardCode/MonthlyCardIcon", {type = 2})
                return monthlyCardIcon
            end
        end
    end
    return monthlyCardIcon
end

function MonthlyCardMgr:isFirstEntrySharkGame()
    local bEntry = false
    local data = self:getRunningData()
    if data then
        local isBuyMonthlyCardDeluxe = data:isBuyMonthlyCardDeluxe()
        if isBuyMonthlyCardDeluxe then
            bEntry = gLobalDataManager:getBoolByField("monthlyCardIsFirstEntrySharkGame", true)
        end
    end
    return bEntry
end

function MonthlyCardMgr:setFirstEntrySharkGame()
    gLobalDataManager:setNumberByField("monthlyCardIsFirstEntrySharkGame", false)
end

return MonthlyCardMgr
