--[[
Author: cxc
Date: 2022-02-14 15:29:48
LastEditTime: 2022-02-14 15:29:49
LastEditors: cxc
Description: 高倍场 合成小游戏 合成周卡活动 网络类
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/net/MergeWeekNet.lua
--]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local MergeWeekNet = class("MergeWeekNet", BaseNetModel)
local ActivityMergeWeekConfig = require("activities.Activity_DeluxeMerge.config.ActivityMergeWeekConfig")

-- 周卡领取奖励
function MergeWeekNet:sendCollectReq()
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            -- 失败
            return
        end
        gLobalNoticManager:postNotification(ActivityMergeWeekConfig.EVENT_NAME.MERGE_WEEK_COLLECT_SUCCESS, _result)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
    end

    self:sendActionMessage(ActionType.MergeWeekCollect, nil, successCallback, failedCallback)
end

-- 充值
function MergeWeekNet:goPurchase()
    local actData = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeWeek):getRunningData()
    if not actData then
        return 
    end
    
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = actData:getGoodsId()
    goodsInfo.goodsPrice = tostring(actData:getPrice())
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(actData)
    gLobalSaleManager:purchaseGoods(BUY_TYPE.MERGE_WEEK,  goodsInfo.goodsId, goodsInfo.goodsPrice, 0, 0, handler(self, self.buySuccess), handler(self, self.buyFailed))
end
function MergeWeekNet:buySuccess()
    gLobalViewManager:checkBuyTipList(function()
        gLobalNoticManager:postNotification(ActivityMergeWeekConfig.EVENT_NAME.MERGE_WEEK_BUY_SUCCESS)
    end)
end
function MergeWeekNet:buyFailed()
    
end

function MergeWeekNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "MergeWeekUnlock"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "MergeWeekUnlock"
    purchaseInfo.purchaseStatus = "MergeWeekUnlock"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo,nil,nil,self)
end
return MergeWeekNet 