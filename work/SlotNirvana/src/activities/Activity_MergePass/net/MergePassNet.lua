--[[
    合成pass
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local MergePassNet = class("MergePassNet", BaseNetModel)

function MergePassNet:sendPassCollect(_data, _type)
    local tbData = {
        data = {
            params = {
                level = _data.p_level,
                type = _type
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        local data = {}
        data.p_level = _data.p_level
        data.p_coins = tonumber(_result.coins) or 0
        data.p_items = _result.items or {}
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MERGE_PASS_COLLECT, {success = true, data = data, type = _type})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MERGE_PASS_COLLECT, {success = false, type = _type})
    end

    self:sendActionMessage(ActionType.MergePassCollect,tbData,successCallback,failedCallback)
end

function MergePassNet:sendPassBoxCollect(_data, _type)
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima()

    local successCallback = function (_result)
        local data = {}
        data.p_level = _data.p_level
        data.p_coins = tonumber(_result.coins) or 0
        data.p_items = _result.items or {}
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MERGE_PASS_COLLECT, {success = true, data = data, type = _type})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MERGE_PASS_COLLECT, {success = false, type = _type})
    end

    self:sendActionMessage(ActionType.MergePassCollectBox,tbData,successCallback,failedCallback)
end

-- 付费
function MergePassNet:buyPassUnlock(_data)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MERGE_PASS_PAY_UNLOCK)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data:getKeyId()
    goodsInfo.goodsPrice = _data:getPrice()
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.MERGE_PASS_UNLOCK,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function()
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MERGE_PASS_PAY_UNLOCK, {success = true})
            end)
        end,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MERGE_PASS_PAY_UNLOCK)
        end
    )
end

function MergePassNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "MergePassSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "MergePassSale"
    purchaseInfo.purchaseStatus = "MergePassSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return MergePassNet
