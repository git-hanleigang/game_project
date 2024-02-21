--[[
    集装箱大亨
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local BlindBoxNet = class("BlindBoxNet", BaseNetModel)

function BlindBoxNet:sendActionRank(_flag)
    if _flag then
        gLobalViewManager:addLoadingAnima()
    end
    local function failedFunc(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    local function successFunc(resultData)
        gLobalViewManager:removeLoadingAnima()
        if resultData ~= nil then
            local rankData = resultData
            local act_data = G_GetMgr(ACTIVITY_REF.BlindBox):getRunningData()
            if act_data and rankData then
                act_data:parseRankConfig(rankData)
                act_data:setRankJackpotCoins(0)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.BlindBox})
                -- if _flag then
                --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ _RANK)
                -- end
            end
        else
            failedFunc()
        end
    end

    -- local actionData = self:getSendActionData(ActionType.BlindBoxRank)
    -- local params = {}
    -- actionData.data.params = json.encode(params)
    -- self:sendMessageData(actionData, successFunc, failedFunc)
    local tbData = {
        data = {
            params = {
            }
        }
    }
    self:sendActionMessage(ActionType.BlindBoxRank,tbData,successFunc,failedFunc)
end

function BlindBoxNet:sendBlindBoxNext()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()        
        gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_NEXT, {success = true})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_NEXT)
    end

    self:sendActionMessage(ActionType.BlindBoxNext,tbData,successCallback,failedCallback)
end

function BlindBoxNet:sendBlindBoxOpen()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()        
        gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_OPEN, {success = true})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_OPEN)
    end

    self:sendActionMessage(ActionType.BlindBoxOpen,tbData,successCallback,failedCallback)
end

function BlindBoxNet:sendBlindBoxMissionCollect(_missionId, _success)
    gLobalViewManager:addLoadingAnima(false)
    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_MISSION_COLLECT, {success = true})
        if _success then
            _success()
        end
    end
    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_MISSION_COLLECT, {success = false})
    end
    local tbData = {data = {params = {}}}
    tbData.data.params.index = _missionId
    self:sendActionMessage(ActionType.BlindBoxMissionReward,tbData,successCallback,failedCallback)
end

function BlindBoxNet:sendBlindBoxGetData(_succ, _fail)
    gLobalViewManager:addLoadingAnima(false)
    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()    
        if _succ then
            _succ()
        end
    end
    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _fail then
            _fail()
        end
    end
    local tbData = {data = {params = {}}}
    self:sendActionMessage(ActionType.BlindBoxGetData,tbData,successCallback,failedCallback)
end

function BlindBoxNet:buySale(_data, _index)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_BUY_SALE)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data.p_keyId
    goodsInfo.goodsPrice = _data.p_price
    goodsInfo.totalCoins = _data.p_coins

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, _data.p_items)
    gLobalSendDataManager:getLogIap():setItemList(itemList)

    gLobalSaleManager:purchaseActivityGoods(
        "",
        tostring(_index),
        BUY_TYPE.BLIND_BOX_SALE,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function(_result)
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_BUY_SALE, {success = true, index = _index})
            end)
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_BUY_SALE, {success = false, errorInfo = _errorInfo, index = _index})
        end
    )
end

function BlindBoxNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "BlindBoxSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "BlindBoxSale"
    purchaseInfo.purchaseStatus = "BlindBoxSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

function BlindBoxNet:sendCollect(_point, _type, _index)
    local tbData = {
        data = {
            params = {
                point = _point,
                type = _type
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()        
        gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_PASS_COLLECT, {success = true, index = _index, type = _type, data = _result})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_PASS_COLLECT)
    end

    self:sendActionMessage(ActionType.BlindBoxPassReward,tbData,successCallback,failedCallback)
end

function BlindBoxNet:buyUnlock(_data)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_PASS_UNLOCK)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data:getKeyId()
    goodsInfo.goodsPrice = _data:getPrice()
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendUnlockIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.BLIND_BOX_PASS_UNLOCK,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function()
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_PASS_UNLOCK, {success = true})
            end)
        end,
        function()
            gLobalNoticManager:postNotification(ViewEventType.BLIND_BOX_PASS_UNLOCK)
        end
    )
end

function BlindBoxNet:sendUnlockIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "BlindBoxPassSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "BlindBoxPassSale"
    purchaseInfo.purchaseStatus = "BlindBoxPassSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return BlindBoxNet
