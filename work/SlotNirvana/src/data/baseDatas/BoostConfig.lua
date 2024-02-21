--
-- 商城里面的boost 功能
-- Author:{author}
-- Date: 2019-06-18 14:41:32
--
local BoostConfig = class("BoostConfig")

BoostConfig.p_id = nil 
BoostConfig.p_keyId = nil   -- 商品value
BoostConfig.p_key = nil     -- 商品key
BoostConfig.p_days = nil     -- 持续天数
BoostConfig.p_discountsDays = nil  --第一次购买折扣持续天数，没有未0
BoostConfig.p_boughtTimes = nil  -- 已经购买的次数
BoostConfig.p_price = nil  -- 价格 
BoostConfig.p_items = nil   -- 商品
BoostConfig.p_displayList = nil -- 
BoostConfig.p_type = nil  -- 类型

function BoostConfig:ctor()
    
end
--[[
    @desc: 获取 vip点数信息
    time:2019-04-13 14:12:45
    @return:
]]
function BoostConfig:getRewardVipPoint( )
      for i=1,#self.p_displayList do
            local shopItemData = self.p_displayList[i]
            if shopItemData.p_item == ITEMTYPE.ITEMTYPE_VIPPOINT then
                  return shopItemData.p_num
            end
      end

      return 0
end

--获取额外道具数据
function BoostConfig:getExtraPropList( )
    local ret = {}
    for i=1,#self.p_displayList do
          local shopItemData = self.p_displayList[i]
          if shopItemData.p_item ~= ITEMTYPE.ITEMTYPE_COIN then
                ret[#ret+1] = shopItemData
          end
    end

    return ret
end

return  BoostConfig