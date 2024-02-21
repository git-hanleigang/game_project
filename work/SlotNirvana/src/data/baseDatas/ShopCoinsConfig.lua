--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:23:33
-- fix ios 1231
local ShopTag = require "data.baseDatas.ShopTag"
local ShopItem = require "data.baseDatas.ShopItem"
local ShopCoinsConfig = class("ShopCoinsConfig")

ShopCoinsConfig.p_id = nil
ShopCoinsConfig.p_keyId = nil
ShopCoinsConfig.p_key = nil -- 购买key ， 对应后台申请的购买id
ShopCoinsConfig.p_originalCoins = nil -- 原始价格
ShopCoinsConfig.p_coins = nil -- 最终金币数
ShopCoinsConfig.p_discount = nil --  折扣
ShopCoinsConfig.p_price = nil -- 消耗美金价格， 显示在购买按钮上
ShopCoinsConfig.p_tag = nil -- 目前用来表示 best value 、 popular
ShopCoinsConfig.p_displayList = nil -- 用来显示购买后额外获得的内容， 目前只有 vip 和 lucky charm
ShopCoinsConfig.p_baseCoins = nil
ShopCoinsConfig.p_couponDiscount = nil
ShopCoinsConfig.p_ticketDiscount = nil
ShopCoinsConfig.p_shopCardDiscount = nil -- 金币商城送卡折扣起始档位
ShopCoinsConfig.p_hotSaleType = nil -- 热卖底板类型
ShopCoinsConfig.p_hotSaleIcon = nil -- 热卖icon

-- 关卡比赛加成
ShopCoinsConfig.m_arenaDiscount = nil

function ShopCoinsConfig:ctor(_bCoinsType)
    self.m_bCoinsType = _bCoinsType
end
--[[
    @desc: 根据折扣率， 来计算本次购买的最终倍率 rate
    time:2019-04-15 18:05:28
    @return:
]]
function ShopCoinsConfig:getBuyRate()
    if self.p_discount == nil then
        return 1
    end
    local rate = self.p_discount / 100 + 1
    return rate
end

function ShopCoinsConfig:parseData(data)
    self.m_buyType = BUY_TYPE.STORE_TYPE
    self.p_id = data.id
    self.p_keyId = data.keyId
    self.p_key = data.key
    self.p_originalCoins = tonumber(data.originalCoins or 0)
    self.p_coins = tonumber(data.coins or 0)
    self.p_discount = data.discount -- 商城首购折扣 + 其他折扣（高倍场折扣）
    self.p_price = data.price
    self.p_baseCoins = tonumber(data.baseCoins) or 0
    local shopTag = ShopTag:create()
    if data:HasField("tag") == true then
        shopTag.p_id = data.tag.id
        shopTag.p_description = data.tag.description
        shopTag.p_icon = data.tag.icon

        self.p_tag = shopTag
    end

    local shopItems = data.displayList
    self.p_displayList = {}
    -- local sendCouponData = globalData.sendCouponConfig
    for i = 1, #shopItems do
        local itemData = shopItems[i]
        local shopItem = ShopItem:create()
        shopItem:parseData(itemData)

        self.p_displayList[#self.p_displayList + 1] = shopItem
        -- if shopItem.p_buffInfo ~= nil and shopItem.p_buffInfo.buffType == BUFFTYPY.BUFFTYPE_STORE_COUPON then
        --     if sendCouponData:isExist() == false and globalData.isPurchaseCallback == true then
        --         globalData.sendCouponFlag = true
        --     end
        --     sendCouponData:parseData(shopItem.p_buffInfo, self.p_key)
        -- end
    end
    -- if sendCouponData:isExist() == true and sendCouponData:isContainKey(self.p_key) then
    --     local removeCoupon = true
    --     for i = 1, #self.p_displayList, 1 do
    --         local item = self.p_displayList[i]
    --         if item.p_buffInfo ~= nil and item.p_buffInfo.buffType == BUFFTYPY.BUFFTYPE_STORE_COUPON then
    --             removeCoupon = false
    --             break
    --         end
    --     end
    --     if removeCoupon == true then
    --         sendCouponData:removeSendCoupon()
    --     end
    -- end
    if data.couponDiscount then
        self.p_couponDiscount = data.couponDiscount
    end
    if data.ticketDiscount then
        self.p_ticketDiscount = data.ticketDiscount
    end
    if data.shopCardDiscount then
        self.p_shopCardDiscount = data.shopCardDiscount
    end
    if data.arenaDiscount then
        self.m_arenaDiscount = data.arenaDiscount
    end
    if data.storeDiscount then
        self.p_firstBuyDiscount = data.storeDiscount
    end

    -- 新手期cashback道具需要手动加，服务器无法加
    self:updateNoviceCashBackItem()
end

--[[
    @desc: 获取 vip点数信息
    time:2019-04-13 14:12:45
    @return:
]]
function ShopCoinsConfig:getRewardVipPoint()
    for i = 1, #self.p_displayList do
        local shopItemData = self.p_displayList[i]
        if shopItemData.p_item == ITEMTYPE.ITEMTYPE_VIPPOINT then
            return shopItemData.p_num
        end
    end

    return 0
end

--获取额外道具数据
function ShopCoinsConfig:getExtraPropList()
    local ret = {}
    for i = 1, #self.p_displayList do
        local shopItemData = self.p_displayList[i]
        if shopItemData.p_item ~= ITEMTYPE.ITEMTYPE_COIN and shopItemData.p_item ~= ITEMTYPE.ITEMTYPE_SENDCOUPON then
            ret[#ret + 1] = shopItemData
        end
    end

    return ret
end

-- 新手期cashback道具需要手动加，服务器无法加
function ShopCoinsConfig:addCashBackShopItem()
    local cashBackShopItem = nil
    local cashBackNoviceData = G_GetMgr(ACTIVITY_REF.CashBackNovice):getRunningData()
    if cashBackNoviceData then
        cashBackShopItem = cashBackNoviceData:getCashBackShopItemByKey(self.p_keyId)
    end
    if not cashBackShopItem then
        return
    end

    table.insert(self.p_displayList, cashBackShopItem)
end

-- 登录 活动在 商城数据后解析 需要判断弄下新手cashback道具(只处理商城页签)
function ShopCoinsConfig:updateNoviceCashBackItem()
    if not self.m_bCoinsType then
        return
    end

    local bExitCashBack = false
    for i = 1, #self.p_displayList do
        local shopItemData = self.p_displayList[i]
        if shopItemData.p_icon == "CashBack" then
            bExitCashBack = true
            break
        end
    end

    if not bExitCashBack then
        self:addCashBackShopItem()
    end
end

-- 商城首购折扣
function ShopCoinsConfig:getFirstBuyDiscount()
    return math.max(self.p_firstBuyDiscount or 0, 0)
end

-- 基础加成
function ShopCoinsConfig:getBaseDiscount()
    return math.max(self.p_discount or 0, 0)
end

-- 折扣券加成
function ShopCoinsConfig:getCouponDiscount()
    return math.max(self.p_couponDiscount or 0, 0)
end

-- 促销券加成
function ShopCoinsConfig:getTicketDiscount()
    return self.p_ticketDiscount or 0
end

-- 关卡比赛加成
function ShopCoinsConfig:getArenaDiscount()
    return math.max(self.m_arenaDiscount or 0, 0)
end

-- 商城送卡加成
function ShopCoinsConfig:getShopCardDiscount()
    return math.max(self.p_shopCardDiscount or 0, 0)
end


-- 获得加成
function ShopCoinsConfig:getDiscount()
    local value = 0

    value = value + self:getBaseDiscount()
    value = value + self:getCouponDiscount()
    value = value + self:getArenaDiscount()
    value = value + self:getShopCardDiscount()

    local firstBuyDisc = self:getFirstBuyDiscount()
    if self.m_bCoinsType and firstBuyDisc > 0 then
        value = value - firstBuyDisc
        local ticketType = globalData.shopRunData:getTicketType(SHOP_VIEW_TYPE.COIN)
        if ticketType == "Single" then
            -- 有首购的情况 折扣 加上 优惠劵的 折扣 (单个优惠情况， 全部优惠在主界面topUI有显示)
            value = value + self:getTicketDiscount()
        end
    end

    return value
end

function ShopCoinsConfig:getPrice()
    return self.p_price
end

function ShopCoinsConfig:getBuyType()
    return self.m_buyType
end

function  ShopCoinsConfig:isBig()
    return false
end

function  ShopCoinsConfig:isGolden()
    return false
end

function  ShopCoinsConfig:isGoldenPet()
    return false
end

function ShopCoinsConfig:isUseSpecialPath()
    return false
end

function ShopCoinsConfig:isHotSale()
    return false
end

function ShopCoinsConfig:isMonthlyCard()
    return false
end

function ShopCoinsConfig:isScratchCard()
    return false
end

function ShopCoinsConfig:isPetSale()
    return false
end
return ShopCoinsConfig
