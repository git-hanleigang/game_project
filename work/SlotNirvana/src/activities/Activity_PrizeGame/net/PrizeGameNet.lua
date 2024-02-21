--[[
    充值抽奖池
]]
local PrizeGameConfig = require("activities.Activity_PrizeGame.config.PrizeGameConfig")
local BaseNetModel = require("net.netModel.BaseNetModel")
local PrizeGameNet = class("PrizeGameNet", BaseNetModel)

function PrizeGameNet:getInstance()
    if self.instance == nil then
        self.instance = PrizeGameNet.new()
    end
    return self.instance
end

function PrizeGameNet:buySale(_data)
    if not _data then
        gLobalNoticManager:postNotification(PrizeGameConfig.notify_prize_game_buy)
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
    gLobalSaleManager:purchaseGoods(
        PrizeGameConfig.buy_type,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function(_result)
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(PrizeGameConfig.notify_prize_game_buy, {success = true})
            end)
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(PrizeGameConfig.notify_prize_game_buy)
        end
    )
end

function PrizeGameNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "PrizeGame"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "PrizeGame"
    purchaseInfo.purchaseStatus = "PrizeGame"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

function PrizeGameNet:sendCollect()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(PrizeGameConfig.notify_prize_game_collect, {success = true})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(PrizeGameConfig.notify_prize_game_collect)
    end

    self:sendActionMessage(PrizeGameConfig.net_type_collect, tbData, successCallFun, failedCallFun)
end

function PrizeGameNet:refreshData()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    local function successCallFun(_result)
        gLobalNoticManager:postNotification(PrizeGameConfig.notify_prize_game_refresh)
    end

    local function failedCallFun(code, errorMsg)

    end

    self:sendActionMessage(PrizeGameConfig.net_type_refresh, tbData, successCallFun, failedCallFun)
end

return PrizeGameNet
