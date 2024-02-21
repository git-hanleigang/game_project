--
--
local ShopItem = require "data.baseDatas.ShopItem"
local ShopCoinsConfig = require "data.baseDatas.ShopCoinsConfig"
local ShopDailySaleConfig = class("ShopDailySaleConfig")

-- optional string type = 1; //促销商品类型 0 1
-- optional string description = 2; //描述
-- optional int64 expireAt = 3; //剩余时间
-- optional string icon = 4; //对应图片
-- optional int64 coins = 5;//商品配置对应金币
-- repeated ShopItem items = 6; // 商品配置对应物品
-- optional int32 payTimes = 7;//可购买次数
-- optional int32 isPayTimes = 8;//已购买次数
-- optional string storePrice = 9;//商城推荐档位价格
-- optional bool show = 10;//是否展示商城档位
-- optional ShopCoinsConfig shopCoinResult = 11;
-- optional string plateType = 12;//底板类型;
--optional string buyType = 13;//购买类型;
function ShopDailySaleConfig:ctor()

end

--索引
function ShopDailySaleConfig:setIndex(index)
    self.m_index = index
end

function ShopDailySaleConfig:parseData(data)
    if not data then
        return
    end
    
    self.m_type = data.type
    self.m_description = data.description
    self.m_expireAt = tonumber(data.expireAt)
    
    -- 解析背景图icon
    self.m_hotSaleIcon = data.icon
    -- 配置的奖励 金币 、 道具
    self.p_coins = tonumber(data.coins or 0)
    self.p_displayList = {}
    local items = data.items
    if items and #items > 0 then
        for i = 1, #data.items do
            local _item = ShopItem:create()
            _item:parseData(data.items[i])
            table.insert(self.p_displayList, _item)
        end
    end
    self.m_maxPayTimes = data.payTimes or 0
    self.m_payTimes = data.isPayTimes or 0
    self.m_storePrice = data.storePrice
    self.m_showStore = data.show

    self.m_hotSaleType = data.plateType
    self.m_buyType = data.buyType

    self.m_shopBuyData = nil
    if data.shopCoinResult then
        local shopCoinConfig = ShopCoinsConfig:create()
        shopCoinConfig:parseData(data.shopCoinResult)
        self.m_shopBuyData = shopCoinConfig

        self.p_key = shopCoinConfig.p_key
        self.p_price = shopCoinConfig.p_price
        self.p_discount = shopCoinConfig.p_discount
        if not self:isGolden() then
            self.p_displayList = shopCoinConfig.p_displayList
        end
    end
end

function ShopDailySaleConfig:getBuyType()
    return self.m_buyType or  BUY_TYPE.StoreHotSale
end

function ShopDailySaleConfig:getExpireAt()
    return (self.m_expireAt or 0) / 1000
end

function ShopDailySaleConfig:getBuyShopData()
    return self.m_shopBuyData
end

-- 返回促销额外的奖励
function ShopDailySaleConfig:getRewards()
    local rewards = {}
    if tonumber(self.p_coins) > 0 then
        rewards.coins = tonumber(self.p_coins)
    end
    rewards.items = self.p_displayList
    return rewards
end

--获取额外道具数据
function ShopDailySaleConfig:getExtraPropList()
    local ret = {}
    for i = 1, #self.p_displayList do
        local shopItemData = self.p_displayList[i]
        if shopItemData.p_item ~= ITEMTYPE.ITEMTYPE_COIN and shopItemData.p_item ~= ITEMTYPE.ITEMTYPE_SENDCOUPON then
            ret[#ret + 1] = shopItemData
        end
    end

    return ret
end

function ShopDailySaleConfig:getBenefitDisplayList()
    return self.m_shopBuyData.p_displayList
end

-- 登录 活动在 商城数据后解析 需要判断弄下新手cashback道具
function ShopDailySaleConfig:updateNoviceCashBackItem()
    if self.m_shopBuyData then
        self.m_shopBuyData:updateNoviceCashBackItem()
    end
end

function ShopDailySaleConfig:getDiscount()
    local value = 0
 
    -- value = value + self:getBaseDiscount()
    -- value = value + self:getCouponDiscount()
    -- value = value + self:getArenaDiscount()
    -- value = value + self:getShopCardDiscount()

    return value
end

function ShopDailySaleConfig:getBgIcon()
    return self.m_hotSaleIcon
end

function ShopDailySaleConfig:getMaxPayTimes()
    return self.m_maxPayTimes
end

function ShopDailySaleConfig:getPayTimes()
    return self.m_payTimes
end

function ShopDailySaleConfig:getStorePrice()
    return self.m_storePrice
end

function ShopDailySaleConfig:getIsShowStorePrice()
    return self.m_showStore
end

function ShopDailySaleConfig:setStorePrice(_price)
    if _price then
        self.m_storePrice = _price
    else
        self.m_storePrice = self.old_storePrice
    end
end

function  ShopDailySaleConfig:isBig()
    if self.m_hotSaleType == "V_BIG" or self.m_hotSaleType == "H_BIG" then
        return true
    end
    return false
end

function  ShopDailySaleConfig:isGolden()
    if self.m_hotSaleType == "V_GOLD" or self.m_hotSaleType == "H_GOLD" then
        return true
    end
    return false
end

function ShopDailySaleConfig:isUseSpecialPath()
    if self.m_hotSaleIcon and  self.m_hotSaleIcon ~= "" then
        return true
    end
    return false
end

function ShopDailySaleConfig:getSpecialPath()
    return self.m_hotSaleIcon
end

function ShopDailySaleConfig:getStoreBuyId()
    local result = 0
    if self.m_shopBuyData then
        result = self.m_shopBuyData.p_id
    end
    return tostring(result)
end

function ShopDailySaleConfig:getPrice()
    return self.m_shopBuyData:getPrice()
end


function ShopDailySaleConfig:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function ShopDailySaleConfig:getLeftBuyTimes()
    if self:isMonthlyCard() then
        return 1
    end
    local times = tonumber(self.m_maxPayTimes) -  tonumber(self.m_payTimes)
   return times
end

function ShopDailySaleConfig:getExpireAt()
    return (self.m_expireAt or 0) / 1000 
end

function ShopDailySaleConfig:getCoins()
    return self.p_coins
end

function ShopDailySaleConfig:isHotSale()
    return true
end

function ShopDailySaleConfig:setIsMonthlyCard(isMonthlyCard)
    self.m_isMonthlyCard = isMonthlyCard
end

function ShopDailySaleConfig:isMonthlyCard()
    return not not self.m_isMonthlyCard
end

function ShopDailySaleConfig:setIsScratchCard(_isScratchCard)
    self.m_isScratchCard = _isScratchCard
end
function ShopDailySaleConfig:isScratchCard()
    return self.m_isScratchCard
end

function ShopDailySaleConfig:isPetSale()
    local result = false
    if string.find(self.m_hotSaleIcon, "pet") then
        result = true
    end
    return result
end

return ShopDailySaleConfig