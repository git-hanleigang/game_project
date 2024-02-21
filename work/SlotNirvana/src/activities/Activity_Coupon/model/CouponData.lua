--[[--
    商城优惠券活动
    活动开启后商场金币后边会增加一个extra的折扣力度标识
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require "baseActivity.BaseActivityData"
local CouponData = class("CouponData", BaseActivityData)

function CouponData:parseData(data, isNetData)
    CouponData.super.parseData(self, data, isNetData)

    self.p_discount = cjson.decode(data.discount)

    self.p_maxDiscount = 0
    for k, v in pairs(self.p_discount) do
        self.p_maxDiscount = math.max(self.p_maxDiscount, v.discount)
    end
end

function CouponData:getMaxDiscount()
    return self.p_maxDiscount
end

function CouponData:isKeyIdInShop(_keyId)
    local coinsShopData = globalData.shopRunData:getShopItemDatas()
    if coinsShopData and #coinsShopData > 0 then
        for i = 1, #coinsShopData do
            local coinData = coinsShopData[i]
            local shopCardDis = coinData:getCouponDiscount()
            if shopCardDis > 0 and coinData.p_keyId == _keyId then
                return true
            end
        end
    end
    return false
end

-- 商城折扣送的道具
function CouponData:getShopGifts()
    local items = {}
    if self.p_discount and table.nums(self.p_discount) > 0 then
        for _keyId, v in pairs(self.p_discount) do
            -- 筛选档位
            if self:isKeyIdInShop(_keyId) then
                if v.simpleItems and #v.simpleItems > 0 then
                    for i=1,#v.simpleItems do
                        local shopItem = ShopItem:create()
                        shopItem:parseData(v.simpleItems[i])
                        table.insert(items, shopItem)
                    end
                end
            end
        end
    end
    return items
end

function CouponData:getMaxShopGift()
    local shopGifts = self:getShopGifts()
    if shopGifts and #shopGifts > 0 then
        -- 取一个
        local shopGiftIcon = shopGifts[1].p_icon
        
        -- 获取最大
        local maxIndex = nil
        local maxNum = 0
        for i = 1, #shopGifts do
            local shopItemData = shopGifts[i]
            if shopItemData.p_icon == shopGiftIcon then
                if shopItemData.p_num >= maxNum then
                    maxNum = shopItemData.p_num
                    maxIndex = i
                end
            end
        end
        if maxIndex > 0 then
            return shopGifts[maxIndex]
        end
    end
    return nil
end

function CouponData:isRunning()
    if not CouponData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end
    return true

end

-- 检查完成条件
function CouponData:checkCompleteCondition()
    local shopCoinData, shopGemData = globalData.shopRunData:getShopItemDatas()
    if shopCoinData then
        local couponDiscount = 0
        for i=1,#shopCoinData do
            local shopCoinsConfig = shopCoinData[i]
            if shopCoinsConfig and shopCoinsConfig.getCouponDiscount then
                couponDiscount = couponDiscount + shopCoinsConfig:getCouponDiscount()
            end
        end
        return couponDiscount == 0
    end
    return false
end
return CouponData
