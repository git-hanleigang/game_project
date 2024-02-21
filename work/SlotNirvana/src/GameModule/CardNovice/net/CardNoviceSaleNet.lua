--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-17 15:01:35
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-17 15:41:55
FilePath: /SlotNirvana/src/GameModule/CardNovice/net/CardNoviceSaleNet.lua
Description: 新手期集卡 促销双倍奖励  net
--]]
local BaseNetModel = import("net.netModel.BaseNetModel")
local CardNoviceSaleNet = class("CardNoviceSaleNet", BaseNetModel)

-- 充值
function CardNoviceSaleNet:goPurchase(_gameData)
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _gameData:getKeyId()
    goodsInfo.goodsPrice = tostring(_gameData:getPrice())
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_gameData)
    gLobalSaleManager:purchaseGoods(BUY_TYPE.CARD_NOVICE_SALE,  goodsInfo.goodsId, goodsInfo.goodsPrice, 0, 0, handler(self, self.buySuccess), handler(self, self.buyFailed))

end
function CardNoviceSaleNet:buySuccess()
    local layer = gLobalViewManager:getViewByName("CardNoviceSaleMainLayer")
    if layer then
        gLobalNoticManager:postNotification(CardNoviceCfg.EVENT_NAME.CARD_NOVICE_SALE_BUY_SUCCESS)
    else
        gLobalViewManager:checkBuyTipList()
    end

    gLobalNoticManager:postNotification(CardNoviceCfg.EVENT_NAME.REMOVE_CARD_NOVICE_SALE_HALL_SLIDE)
end
function CardNoviceSaleNet:buyFailed()
    print("CardNoviceSaleNet--buy--failed")
end

function CardNoviceSaleNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = BUY_TYPE.CARD_NOVICE_SALE
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = BUY_TYPE.CARD_NOVICE_SALE
    purchaseInfo.purchaseStatus = BUY_TYPE.CARD_NOVICE_SALE
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo,nil,nil,self)
end

return CardNoviceSaleNet