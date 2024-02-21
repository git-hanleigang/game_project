--[[
    鲨鱼游戏道具化促销
]]

local MythicGameSaleConfig = require("activities.Activity_CardGame_Sale.config.MythicGameSaleConfig")
local BaseNetModel = require("net.netModel.BaseNetModel")
local MythicGameSaleNet = class("MythicGameSaleNet", BaseNetModel)

function MythicGameSaleNet:buySale(_data)
    if not _data then
        gLobalNoticManager:postNotification(MythicGameSaleConfig.notify_mythic_game_sale_buy)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data:getKeyId()
    goodsInfo.goodsPrice = _data:getPrice()

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, _data:getItems())
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        MythicGameSaleConfig.buy_type,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function(_result)
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(MythicGameSaleConfig.notify_mythic_game_sale_buy, {success = true})
            end)
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(MythicGameSaleConfig.notify_mythic_game_sale_buy)
        end
    )
end

function MythicGameSaleNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "MythicGameSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "MythicGameSale"
    purchaseInfo.purchaseStatus = "MythicGameSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return MythicGameSaleNet
