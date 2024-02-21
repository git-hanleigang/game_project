--
-- 商城 boost 数据信息
-- Author:{author}
-- Date: 2019-06-18 14:39:28
--

local BoostConfig = require "data.baseDatas.BoostConfig"
local ShopItem = require "data.baseDatas.ShopItem"

local StoreBoostConfig = class("StoreBoostConfig")

StoreBoostConfig.allBoosts = nil -- boost 列表

-- 以下两个倒计时，如果获取数据为空，则表明无倒计时
StoreBoostConfig.p_cashBackExpire = nil --  cash back 倒计时 秒
StoreBoostConfig.p_levelBurstExprie = nil -- level booom 倒计时秒

StoreBoostConfig.p_cashBackBoosts = nil -- boost 列表
StoreBoostConfig.p_levelBurstBoosts = nil -- boost 列表
StoreBoostConfig.p_bundleBoosts = nil -- boost 列表

BOOST_TYPES = {

      TYPE_CASHBACK = "CASHBACK",
      TYPE_LEVELBURST = "LEVEL_BURST",
      TYPE_BUNDLE = "BUNDLE",

}

function StoreBoostConfig:ctor()
    
end

--[[
    @desc: 解析 store  boost 配置信息
    time:2019-06-18 14:40:29
    --@data: 
    @return:
]]
function StoreBoostConfig:parseData( datas )
      local boostList = datas.boost
      if boostList == nil then
            return
      end

      self.p_cashBackExpire = datas.cashBackExpire or 0 
      self.p_levelBurstExprie = datas.levelBurstExpire or 0

      self.allBoosts = {}

      self.p_cashBackBoosts = {} -- boost 列表
      self.p_levelBurstBoosts = {} -- boost 列表
      self.p_bundleBoosts = {} -- boost 列表

      for i=1,#boostList do
            local data = boostList[i]
            
            local config = BoostConfig:create()
            config.p_id =  data.id
            config.p_keyId = data.keyId   -- 商品value
            config.p_key = data.key     -- 商品key
            config.p_days = data.days     -- 持续天数
            config.p_discountsDays = tonumber(data.discountsDays) or 0  --第一次购买折扣持续天数，没有未0
            config.p_boughtTimes = data.boughtTimes or 0 -- 已经购买的次数
            config.p_price = data.price  -- 价格 
            config.p_items = data.items   -- 商品
            config.p_displayList = {} -- 
            config.p_type = data.type  -- 类型

            -- 解析 boost me里面的道具列表
            if data.displayList ~= nil then
                  for j=1,#data.displayList do
                        local itemData = data.displayList[j]
                        local itemConfig = ShopItem:create()
                        itemConfig:parseData(itemData)
      
                        config.p_displayList[#config.p_displayList + 1] = itemConfig
                  end
            end

            self.allBoosts[#self.allBoosts + 1] = config

            if config.p_type == BOOST_TYPES.TYPE_CASHBACK then
                  self.p_cashBackBoosts[#self.p_cashBackBoosts + 1] = config
            elseif config.p_type == BOOST_TYPES.TYPE_LEVELBURST then
                  self.p_levelBurstBoosts[#self.p_levelBurstBoosts + 1] = config
            elseif config.p_type == BOOST_TYPES.TYPE_BUNDLE then
                  self.p_bundleBoosts[#self.p_bundleBoosts + 1] = config
            end
      end

end

return  StoreBoostConfig