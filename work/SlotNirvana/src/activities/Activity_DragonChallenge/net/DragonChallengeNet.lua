--[[
    -- 组队打BOSS
]]
local DragonChallengeConfig = require("activities.Activity_DragonChallenge.config.DragonChallengeConfig")
local BaseNetModel = require("net.netModel.BaseNetModel")
local DragonChallengeNet = class("DragonChallengeNet", BaseNetModel)

function DragonChallengeNet:refreshData(_loading)
    local tbData = {
        data = {
            params = {}
        }
    }

    if _loading then
        gLobalViewManager:addLoadingAnima(true)
    end

    local successCallback = function(_result)
        if _loading then
            gLobalViewManager:removeLoadingAnima()
        end
        gLobalNoticManager:postNotification(DragonChallengeConfig.notify_refresh_data, {result = _result})
    end

    local failedCallback = function(errorCode, errorData)
        if _loading then
            gLobalViewManager:removeLoadingAnima()
        end
        gLobalNoticManager:postNotification(DragonChallengeConfig.notify_refresh_data)
    end

    self:sendActionMessage(ActionType.DragonChallengeRefresh, tbData, successCallback, failedCallback)
end

function DragonChallengeNet:sendAttack(_bet, _parts)
    local tbData = {
        data = {
            params = {
                bet = _bet,
                parts = _parts
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(DragonChallengeConfig.notify_wheel_spin, {result = _result})
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(DragonChallengeConfig.notify_wheel_spin)
    end

    self:sendActionMessage(ActionType.DragonChallengePlay, tbData, successCallback, failedCallback)
end

function DragonChallengeNet:buyBuffSale()
    local tbData = {
        data = {
            params = {}
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
        gLobalNoticManager:postNotification(DragonChallengeConfig.notify_buy_buff_sale, {success = true})
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(DragonChallengeConfig.notify_buy_buff_sale)
    end

    self:sendActionMessage(ActionType.DragonChallengeBuyBuff, tbData, successCallback, failedCallback)
end

function DragonChallengeNet:buyWheelSale(_data, _index)
    if not _data then
        gLobalNoticManager:postNotification(DragonChallengeConfig.notify_buy_wheel_sale)
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
        DragonChallengeConfig.buy_type,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function(_result)
            gLobalViewManager:removeLoadingAnima()
            gLobalViewManager:checkBuyTipList(
                function()
                    gLobalNoticManager:postNotification(DragonChallengeConfig.notify_buy_wheel_sale, {success = true, index = _index})
                end
            )
        end,
        function(_errorInfo)
            gLobalViewManager:removeLoadingAnima()
            gLobalNoticManager:postNotification(DragonChallengeConfig.notify_buy_wheel_sale, {errorInfo = _errorInfo, index = _index})
        end
    )
end

function DragonChallengeNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}

    goodsInfo.goodsTheme = "LineSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "LineSale"
    purchaseInfo.purchaseStatus = "LineSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo)
end

--- pass ---
-- 领奖
function DragonChallengeNet:sendPassCollect(_data,successCallback,failedCallback)
    local tbData = {
        data = {
            params = {
                level = _data.p_level,
                free = _data.p_free,
                passSeq = _data.p_passSeq
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)
    self:sendActionMessage(ActionType.DragonChallengePassReward, tbData, successCallback, failedCallback)
end

-- 付费
function DragonChallengeNet:buyPassUnlock(_data)
    if not _data then
        -- gLobalNoticManager:postNotification("NOTIFY_DRAGON_PASS_PAY_UNLOCK")
        return
    end
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data:getKeyId()
    goodsInfo.goodsPrice = _data:getPrice()
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    -- local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    -- gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.DRAGON_CHALLENGE_PASS_UNLOCK, 
        _data:getValue(),
        _data:getPrice(),
        0,
        0,
        function()
            gLobalViewManager:checkBuyTipList(
                function()
                    gLobalNoticManager:postNotification("NOTIFY_DRAGON_PASS_PAY_UNLOCK", {success = true})
                end
            )
        end,
        function()
            gLobalNoticManager:postNotification("NOTIFY_DRAGON_PASS_PAY_UNLOCK")
        end
    )
end

return DragonChallengeNet
