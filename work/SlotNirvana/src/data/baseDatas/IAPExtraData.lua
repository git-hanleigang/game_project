--支付存储信息
local IAPExtraData = class("IAPExtraData")
IAPExtraData.buyType = nil                 --支付类型
IAPExtraData.iapId = nil                   --支付信息
IAPExtraData.buyPrice = nil                --支付价格
IAPExtraData.totalCoin = nil               --支付金额
IAPExtraData.discounts = nil               --折扣信息
IAPExtraData.activityId = nil              --关联活动ID
IAPExtraData.contentId = nil               --关联促销数据ID
IAPExtraData.items  = nil                  --购买获得的道具
IAPExtraData.vipPoint = nil                --vippoint
IAPExtraData.buff = nil                    --buff
function IAPExtraData:ctor()
    
end
--创建数据
function IAPExtraData:createIAPExtraData(buyType, iapId, buyPrice, totalCoin, discounts, activityId, contentId)
    self.buyType = buyType                    --支付类型
    self.iapId = iapId                        --支付信息
    self.buyPrice = buyPrice                  --支付价格
    self.totalCoin = totalCoin                --支付金额
    self.discounts = discounts                --折扣信息
    self.activityId = activityId              --关联活动ID
    self.contentId = contentId                --关联促销数据ID
    
    -- self:createItems()
    -- itmelist 
    -- 除了 itmelist 外的给玩家加的数据
end
--根据json结构解析数据
function IAPExtraData:parseData(jsonData)
    self.buyType = jsonData.buyType                    --支付类型
    self.iapId = jsonData.iapId                        --支付信息
    self.buyPrice = jsonData.buyPrice                  --支付价格
    self.totalCoin = jsonData.totalCoin                --支付金额
    self.discounts = jsonData.discounts                --折扣信息
    self.activityId = jsonData.activityId              --关联活动ID
    self.contentId = jsonData.contentId                --关联促销数据ID
    -- self.items = jsonData.items
    self.vipPoint = jsonData.vipPoint
    self.buff = jsonData.buff
end
--获取json结构数据
function IAPExtraData:getJsonData()
    local jsonData = {
        buyType = self.buyType,                         --支付类型
        iapId = self.iapId,                             --支付信息
        buyPrice = self.buyPrice,                       --支付价格
        totalCoin = self.totalCoin,                     --支付金额
        discounts = self.discounts,                     --折扣信息
        activityId = self.activityId,                   --关联活动ID
        contentId = self.contentId,                     --关联促销数据ID
        -- items = cjson.decode(self.items),
        vipPoint = self.vipPoint,
        buff = self.buff
    }
    return jsonData
end

-- 根据传入的数据生成对应的items
function IAPExtraData:createItems( )
    -- 暂时处理 quest_sale
    -- if self.buyType == BUY_TYPE.QUEST_SALE then
    --       local saleData = globalData.saleRunData:getPromotionData(ACTIVITY_TYPE.SEVENDAY,self.activityId)
    --       if saleData.p_items and #saleData.p_items>0 then
    --             self.items = cjson.encode(saleData.p_items)
    --       end
    -- end
end

function IAPExtraData:setExtraData(extraData)
    if extraData.vippoint == nil then
        local purchaseData = gLobalItemManager:getCardPurchase(nil, self.buyPrice)
        if not purchaseData then
            return
        end
        self.vipPoint = purchaseData.p_vipPoints
    else
        self.vipPoint = extraData.vippoint
    end

    if extraData.buff then
        self.buff = extraData.buff
    end
end

return  IAPExtraData