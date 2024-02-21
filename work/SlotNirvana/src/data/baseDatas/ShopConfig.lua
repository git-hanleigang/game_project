--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 12:36:02
--
local ShopGift = require "data.baseDatas.ShopGift"
local ShopCoinsConfig = require "data.baseDatas.ShopCoinsConfig"
local ShopPetConfig = require "data.baseDatas.ShopPetConfig"
local ShopGemsConfig = require "data.baseDatas.ShopGemsConfig"
local ShopDailySaleConfig = require "data.baseDatas.ShopDailySaleConfig"
local StoreBoostConfig = require "data.baseDatas.StoreBoostConfig"
local ShopConfig = class("ShopConfig")

ShopConfig.p_expireAt = nil
ShopConfig.p_coins = nil

ShopConfig.p_giftData = nil
ShopConfig.p_shopFirstBuyed = nil

ShopConfig.p_storeBoost = nil  -- 商城里面boost 功能信息

function ShopConfig:ctor()
      self.m_storeHotSale = {}
      self.m_storePet = {}
end
--[[
    @desc: 解析 data
    time:2019-04-13 12:36:31
    --@data:
    @return:
]]
function ShopConfig:parseData( data )
      self.p_shopFirstBuyed = data.shopFirstBuyed
      self.p_expireAt = tonumber(data.expireAt)
      self.p_coinTicketExpireAt = tonumber(data.coinTicketExpireAt) or self.p_expireAt --金币商城促销券过期时间
      self.p_gemTicketExpireAt = tonumber(data.gemTicketExpireAt) or self.p_expireAt --钻石商城促销券过期时间
      self._coinTicketType = "All"
      local coins = data.coins
      self.p_coins = {}
      local tempCoinTicketCount = 0
      for i=1,#coins do
            local coinData = coins[i]
            local shopCoinConfig = ShopCoinsConfig:create(true)
            shopCoinConfig:parseData(coinData)
            local coinTicketCount = shopCoinConfig:getTicketDiscount() 
            if i == 1 then
                  tempCoinTicketCount = coinTicketCount
            end
            if tempCoinTicketCount ~= coinTicketCount then
                  self._coinTicketType = "Single"
            end
            self.p_coins[#self.p_coins + 1] = shopCoinConfig
      end

      -- 第二货币
      self._gemTicketType = "All"
      local tempGemTicketCount = 0
      local gems = data.gems
      if gems and #gems > 0 and next(gems) ~= nil then
            self.p_gems = {}
            for i=1,#gems do
                  local gemData = gems[i]
                  local shopGemConfig = ShopGemsConfig:create()
                  shopGemConfig:parseData(gemData)
                  local gemTicketCount = ShopGemsConfig:getTicketDiscount() 
                  if i == 1 then
                        tempGemTicketCount = gemTicketCount
                  end
                  if tempGemTicketCount ~= gemTicketCount then
                        self._coinTicketType = "Single"
                  end
                  self.p_gems[#self.p_gems + 1] = shopGemConfig
            end
      end


      -- 商城热卖
      local hotSale = data.storeHotSale
      if hotSale and #hotSale > 0   then
            self.m_storeHotSale = {}
            for index, value in ipairs(hotSale) do
                  local shopDailySaleConfig = ShopDailySaleConfig:create()
                  shopDailySaleConfig:parseData(value)
                  shopDailySaleConfig:setIndex(index)
                  self.m_storeHotSale[#self.m_storeHotSale + 1] = shopDailySaleConfig
            end
            self.m_initShopMonthlyCard = false
      end

      if not self.m_initShopMonthlyCard then
            self.m_initShopMonthlyCard = true
            local shopMonthlyCardConfig = ShopDailySaleConfig:create()
            shopMonthlyCardConfig:setIsMonthlyCard(true)
            shopMonthlyCardConfig:setIndex(#self.m_storeHotSale + 1)
            self.m_storeHotSale[#self.m_storeHotSale + 1] = shopMonthlyCardConfig
      end

      -- 商城宠物
      local sidekicks  = data.sidekicks
      if sidekicks and #sidekicks > 0   then
            self.m_storePet = {}
            for index, value in ipairs(sidekicks) do
                  local shopPetConfig = ShopPetConfig:create()
                  shopPetConfig:parseData(value)
                  shopPetConfig:setIndex(index)
                  self.m_storePet[#self.m_storePet + 1] = shopPetConfig
            end
      end

      if self.p_giftData == nil then
            self.p_giftData = ShopGift:create()
      end
      self.p_giftData.p_rewadCoin = tonumber(data.gift.coins)  -- 奖励金币
      self.p_giftData.p_coolDown = data.gift.coolDown -- 倒计时时间

      if self.p_storeBoost == nil then
            self.p_storeBoost = StoreBoostConfig:create()
      end
      if data:HasField("storeBoost") == true then
            self.p_storeBoost:parseData(data.storeBoost)
      end
      -- self.p_giftData.p_coolDown = 10
      self.p_giftData:checkUpdateCoolDown()
      print("...")
end


function ShopConfig:getCoinData()
      return self.p_coins
end

function ShopConfig:getGemData()
      return self.p_gems
end

function ShopConfig:getHotSaleData()
      local result = {}
      if self.m_storeHotSale then
            for i,v in ipairs(self.m_storeHotSale) do
                  if v:getLeftBuyTimes() > 0 then
                        result[#result + 1] = v
                  end
            end
      end
      return result
end

function ShopConfig:getPetData()
      return self.m_storePet
end

function ShopConfig:getTicketExpireAt()
      return self.p_coinTicketExpireAt or self.p_expireAt, self.p_gemTicketExpireAt or self.p_expireAt
end

function ShopConfig:getTicketType(_pageType)
      if _pageType == SHOP_VIEW_TYPE.COIN then
            return self._coinTicketType or "Single"
      elseif _pageType == SHOP_VIEW_TYPE.GEMS then
            return self._gemTicketType or "Single"
      end

      return "Single"
end

return  ShopConfig