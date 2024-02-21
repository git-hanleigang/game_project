
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require("baseActivity.BaseActivityData")
local ShopCoinsConfig = require "data.baseDatas.ShopCoinsConfig"
local ShopDailySaleData = class("ShopDailySaleData", BaseActivityData)
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
function ShopDailySaleData:ctor()
    ShopDailySaleData.super.ctor(self)
    self.m_shopBuyData = {}

    self.m_bgIcon = ""
    self.m_vipPoints = 0   
    self.m_maxPayTimes = 0
    self.m_payTimes = 0
    self.m_storePrice = 0
    self.m_showStore = false
    self.m_isInitData = "false"
    self.m_hasSetPrice  = "false"
end

function ShopDailySaleData:parseData(data)
    if not data then
        return
    end
    BaseActivityData.parseData(self, data)
    -- self.p_id = data.id
    -- self.p_key = data.key
    -- self.p_keyId = data.keyId
    -- self.p_price = data.price
    -- self.p_baseCoins = tonumber(data.baseCoins or 0)
    -- self.p_originalCoins = tonumber(data.originalCoins or 0)
    -- self.p_discount = tonumber(data.discount) * 100

    
    self.m_shopBuyData = nil
    if data.shopCoinResult then
        local shopCoinConfig = ShopCoinsConfig:create()
        shopCoinConfig:parseData(data.shopCoinResult)
        self.m_shopBuyData = shopCoinConfig
    end

    self.m_vipPoints = tonumber(data.vipPoint)
    self.m_maxPayTimes = data.payTimes
    self.m_payTimes = data.isPayTimes
    self.m_storePrice = data.storePrice
    self.old_storePrice = data.storePrice
    self.m_showStore = data.show
    self.m_isInitData = "true"
    -- 解析背景图icon
    self.m_bgIcon = data.icon
    -- 配置的奖励 金币 、 道具
    self.p_coins = tonumber(data.coins or 0)
    self.p_displayList = {}
    if #data.items > 0 then
        for i = 1, #data.items do
            local _item = ShopItem:create()
            _item:parseData(data.items[i])
            table.insert(self.p_displayList, _item)
        end
    end

    -- 特殊处理,等级不够的时候也要认为活动存在，忽略过期时间
    if self.m_shopBuyData and self.m_shopBuyData.p_keyId == "" and self.m_shopBuyData.p_price == "" then
        self:setIgnoreExpire(true)
    else
        self:setIgnoreExpire(false)
    end
end

function ShopDailySaleData:getBuyShopData()
    -- return {
    -- p_id = self.p_id,
    -- p_keyId = self.p_keyId,
    -- p_key = self.p_key,
    -- p_originalCoins = self.p_originalCoins,
    -- p_coins = self.p_coins == 0 and self.p_originalCoins or self.p_coins,
    -- p_discount = self.p_discount,
    -- p_price = self.p_price,
    -- p_baseCoins = self.p_baseCoins,
    -- p_displayList = self.p_displayList
    -- }
    return self.m_shopBuyData
end

-- 返回促销额外的奖励
function ShopDailySaleData:getRewards()
    local rewards = {}
    if tonumber(self.p_coins) > 0 then
        rewards.coins = tonumber(self.p_coins)
    end
    rewards.items = self.p_displayList
    return rewards
end

function ShopDailySaleData:getBgIcon()
    return self.m_bgIcon
end

function ShopDailySaleData:getMaxPayTimes()
    return self.m_maxPayTimes
end

function ShopDailySaleData:getPayTimes()
    return self.m_payTimes
end

function ShopDailySaleData:getStorePrice()
    if self.m_storePrice and (self.m_storePrice == 0 or self.m_storePrice == "0") then
        local msg = "ShopDailySaleData 商场对应档位为0时----是否初始化:" .. self.m_isInitData .. "--是否有手动设置:" ..self.m_hasSetPrice .. "----Icon为:" ..self.m_bgIcon
        util_sendToSplunkMsg("ShopDailySaleData", msg)
    end
    return self.m_storePrice
end

function ShopDailySaleData:getIsShowStorePrice()
    return self.m_showStore
end

function ShopDailySaleData:setStorePrice(_price)
    self.m_hasSetPrice  = "true"
    if _price then
        self.m_storePrice = _price
    else
        self.m_storePrice = self.old_storePrice
    end
end
return ShopDailySaleData
