--[[
    合成转盘
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local MagicGardenNet = class("MagicGardenNet", BaseNetModel)

function MagicGardenNet:getInstance()
    if self.instance == nil then
        self.instance = MagicGardenNet.new()
    end
    return self.instance
end

function MagicGardenNet:sendFreeTimes()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            -- 失败
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MAGIC_GARDEN_PLAY)
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MAGIC_GARDEN_PLAY, {result = _result})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MAGIC_GARDEN_PLAY)
    end

    self:sendActionMessage(ActionType.MagicGardenFreeDraw, tbData, successCallback, failedCallback)
end

function MagicGardenNet:sendRewardCollect(_index, _type)
    local tbData = {
        data = {
            params = {
                index = _index,
                type = _type
            }
        }
    }
    
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MAGIC_GARDEN_COLLECT_REWARD, {success = true})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MAGIC_GARDEN_COLLECT_REWARD)
    end

    self:sendActionMessage(ActionType.MagicGardenCollect, tbData, successCallback, failedCallback)
end

function MagicGardenNet:buySale(_data)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MAGIC_GARDEN_PLAY)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data.p_keyId
    goodsInfo.goodsPrice = _data.p_price

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    gLobalSendDataManager:getLogIap():setItemList(itemList)

    gLobalViewManager:addLoadingAnima(false, 1)

    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.MAGIC_GARDEN_SALE,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function(_result)
            gLobalViewManager:removeLoadingAnima()
            local result = {}
            if _result then
                result = cjson.decode(_result)
            end
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MAGIC_GARDEN_PLAY, {result = result})
            end)
        end,
        function(_errorInfo)
            gLobalViewManager:removeLoadingAnima()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MAGIC_GARDEN_PLAY)
        end
    )
end

function MagicGardenNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = " MagicGarden"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = " MagicGarden"
    purchaseInfo.purchaseStatus = " MagicGarden"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return MagicGardenNet
