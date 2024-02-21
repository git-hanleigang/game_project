--[[
    4格连续充值
]]

local KeepRecharge4Config = require("activities.Activity_KeepRecharge4.config.KeepRecharge4Config")
local BaseNetModel = require("net.netModel.BaseNetModel")
local KeepRecharge4Net = class("KeepRecharge4Net", BaseNetModel)

function KeepRecharge4Net:getInstance()
    if self.instance == nil then
        self.instance = KeepRecharge4Net.new()
    end
    return self.instance
end

function KeepRecharge4Net:sendFreeReward(_index)
    local tbData = {
        data = {
            params = {
                saleIndex = _index - 1
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()        
        gLobalNoticManager:postNotification(KeepRecharge4Config.notify_free_reward, {success = true, index = _index})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(KeepRecharge4Config.notify_free_reward, {index = _index})
    end

    self:sendActionMessage(ActionType.FreeKeepRechargeSales,tbData,successCallback,failedCallback)
end

-- 付费
function KeepRecharge4Net:buySale(_params)
    local _data = _params.data
    local _index = _params.index - 1
    local _activityId = _params.activityId

    if not _data then
        gLobalNoticManager:postNotification(KeepRecharge4Config.notify_buy_sale, {index = _params.index})
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = _data.p_discounts
    goodsInfo.goodsId = _data.p_key
    goodsInfo.goodsPrice = _data.p_price
    goodsInfo.totalCoins = _data.p_coins
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo, _index)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    gLobalSendDataManager:getLogIap():setItemList(itemList)

    gLobalSaleManager:purchaseActivityGoods(
        _activityId,
        _index,
        BUY_TYPE.KEEPRECHARGE4,
        _data.p_key,
        _data.p_price,
        _data.p_coins,
        _data.p_discounts,
        function()
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(KeepRecharge4Config.notify_buy_sale, {success = true, index = _params.index})
            end)
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(KeepRecharge4Config.notify_buy_sale, {errorInfo = _errorInfo, index = _params.index})
        end
    )
end

function KeepRecharge4Net:sendIapLog(_goodsInfo, _index)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "KeepRechargeFourSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = _goodsInfo.discount
    goodsInfo.totalCoins = _goodsInfo.totalCoins
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "KeepRechargeFourSale"
    purchaseInfo.purchaseStatus = "site" .. _index
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return KeepRecharge4Net
