--[[
Author: cxc
Date: 2021-06-11 12:03:09
LastEditTime: 2021-07-09 18:22:37
LastEditors: Please set LastEditors
Description: RippleDash 活动(LevelRush挑战活动) 管理器
FilePath: /SlotNirvana/src/activities/Activity_RippleDash/net/RippleDashNet.lua
--]]
local RippleDashNet = class("RippleDashNet", util_require("baseActivity.BaseActivityManager"))
local Activity_RippleDashConfig = util_require("activities.Activity_RippleDash.config.Activity_RippleDashConfig")

function RippleDashNet:getInstance()
    if self.m_instance == nil then
        self.m_instance = RippleDashNet.new()
	end
	return self.m_instance
end

function RippleDashNet:goPurchase()
    -- local actData = self:getActivityData()
    local actData = G_GetMgr(ACTIVITY_REF.RippleDash):getRunningData()
    if not actData or not actData:isRunning() then
        return 
    end
    
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = actData:getGoodsKeyId()
    goodsInfo.goodsPrice = tostring(actData:getPrice())
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)

    self:sendIapLog(goodsInfo, actData:getCurPhase())

    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(actData)
    gLobalSaleManager:purchaseGoods(BUY_TYPE.RIPPLE_DASH,  goodsInfo.goodsId, goodsInfo.goodsPrice, 0, 0, handler(self, self.buySuccess), handler(self, self.buyFailed))
end
function RippleDashNet:buySuccess()
    -- self:getActivityData(true)
    G_GetMgr(ACTIVITY_REF.RippleDash):getActivityData(true)
    gLobalViewManager:checkBuyTipList(function()
        gLobalNoticManager:postNotification(Activity_RippleDashConfig.EventName.NOTIFY_RIPPLE_DASH_BUY_SUCCESS)
    end)
end
function RippleDashNet:buyFailed()
    
end

-- 请求中 标识
function RippleDashNet:setReqIngSign(_bIng)
    self.m_bReqIng = _bIng
end
function RippleDashNet:getReqIngSign()
    return self.m_bReqIng
end

-- 领取奖励
function RippleDashNet:sendCollectReward(_phase, _bPay)
    if self.m_bReqIng then
        return
    end
    gLobalViewManager:addLoadingAnima(true)
    self.m_bReqIng = true
    
	local function successCallFunc(target, resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(Activity_RippleDashConfig.EventName.NOTIFY_COLLECT_RD_REWARD_SUCCESS)
    end

    local function failedCallFunc(target, code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        self.m_bReqIng = false
    end

    local actionData = self:getSendActionData(ActionType.RippleDashCollect)
    local params = {}
    params["times"] = _phase
    params["type"] = _bPay and "pay" or "free"
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFunc, failedCallFunc)
end

function RippleDashNet:sendIapLog(_goodsInfo, _curPhase)
    if not _goodsInfo or not _curPhase then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "RippleDashUnlock"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "RippleDashUnlock"
    purchaseInfo.purchaseStatus = _curPhase

    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo,nil,nil,self)
end
return RippleDashNet 