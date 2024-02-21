--[[
    装修网络层
    author: 徐袁
    time: 2021-09-09 11:28:23
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local ColoringNet = class(" ColoringNet", BaseNetModel)

function ColoringNet:getInstance()
    if self.instance == nil then
        self.instance = ColoringNet.new()
    end
    return self.instance
end

-- 颜料选择
function ColoringNet:selectPigments(_index, _color)
    local tbData = {
        data = {
            params = {
                index = _index,
                color = _color
            }
        }
    }
    
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            -- 失败
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COLORING_SELECT_PIGMENTS, false)
            return
        end
        local params = {index = _index, color = _color}
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COLORING_SELECT_PIGMENTS, params)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COLORING_SELECT_PIGMENTS, false)
    end

    self:sendActionMessage(ActionType.PaintPlay, tbData, successCallback, failedCallback)
end

-- 购买解锁
function ColoringNet:payUnlock(_index)
    local actData = G_GetMgr(ACTIVITY_REF.Coloring):getRunningData()
    if not actData then
        return 
    end
    
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = actData:getGoodsId()
    goodsInfo.goodsPrice = tostring(actData:getPrice())
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo, _index)

    local buySuccess = function ()
        gLobalViewManager:checkBuyTipList(function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COLORING_BUY, true)
        end)
    end

    local buyFailed = function ()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COLORING_BUY, false)
    end

    gLobalSaleManager:purchaseGoods(BUY_TYPE.COLORING,  goodsInfo.goodsId, goodsInfo.goodsPrice, 0, 0, buySuccess, buyFailed)
end

function ColoringNet:sendIapLog(_goodsInfo, _index)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "ColoringContest"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "ColoringContest"
    purchaseInfo.purchaseStatus = tostring(_index)
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return ColoringNet
