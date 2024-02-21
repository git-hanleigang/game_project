--[[
    LEVEL UP PASS
]]

local LevelUpPassConfig = require("activities.Activity_LevelUpPass.config.LevelUpPassConfig")
local BaseNetModel = require("net.netModel.BaseNetModel")
local LevelUpPassNet = class("LevelUpPassNet", BaseNetModel)

function LevelUpPassNet:sendCollect(_data, _type)
    local tbData = {
        data = {
            params = {
                index = _data.p_index,
                type = _type
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(LevelUpPassConfig.notify_collect, {success = true, data = _data, type = _type})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(LevelUpPassConfig.notify_collect, {success = false, _data = _data, type = _type})
    end

    self:sendActionMessage(ActionType.LevelUpPassCollect,tbData,successCallback,failedCallback)
end

-- 付费
function LevelUpPassNet:buyUnlock(_data)
    if not _data then
        gLobalNoticManager:postNotification(LevelUpPassConfig.notify_pay_unlock)
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
        LevelUpPassConfig.buy_type,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function()
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(LevelUpPassConfig.notify_pay_unlock, {success = true})
            end)
        end,
        function()
            gLobalNoticManager:postNotification(LevelUpPassConfig.notify_pay_unlock)
        end
    )
end

function LevelUpPassNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "LevelUpPassSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "LevelUpPassSale"
    purchaseInfo.purchaseStatus = "LevelUpPassSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return LevelUpPassNet
