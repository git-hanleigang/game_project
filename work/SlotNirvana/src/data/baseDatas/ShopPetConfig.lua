--
--
local ShopItem = require "data.baseDatas.ShopItem"
local ShopTag = require "data.baseDatas.ShopTag"
local ShopPetConfig = class("ShopPetConfig")

-- message ShopSidekicks {
--   optional int32 id = 1;
--   optional string keyId = 2;
--   optional string key = 3;
--   optional string price = 4;
--   repeated ShopItem displayList = 5;
--   optional string display = 6;// 客户端展示数据
--   optional ShopTag tag = 7;
-- }

function ShopPetConfig:ctor()

end

--索引
function ShopPetConfig:setIndex(index)
    self.m_index = index
end

function ShopPetConfig:parseData(data)
    if not data then
        return
    end
    
    self.p_id = data.id
    self.p_keyId = data.keyId
    self.p_key = data.key
    self.p_price = data.price
    self.p_display = data.display
    self.p_petNum = 0

    self.p_displayList = {}
    local items = data.displayList
    if items and #items > 0 then
        for i = 1, #items do
            local _item = ShopItem:create()
            _item:parseData(items[i])
            table.insert(self.p_displayList, _item)
            if string.find(_item.p_icon, "Sidekicks_levelUp") then
                self.p_petNum = _item.p_num
            end
            if string.find(_item.p_icon, "Sidekicks_starUp") then
                self.p_petNum = _item.p_num
            end
        end
    end
    --地板类型
    self.m_hotSaleType = data.plateType
    if data:HasField("tag") == true then
        local shopTag = ShopTag:create()
        shopTag.p_id = data.tag.id
        shopTag.p_description = data.tag.description
        shopTag.p_icon = data.tag.icon

        self.p_tag = shopTag
    end
end

function ShopPetConfig:getBuyType()
    return self.m_buyType or  BUY_TYPE.StorePet
end

-- 返回促销额外的奖励
function ShopPetConfig:getRewards()
    local rewards = {}
    if tonumber(self.p_coins) > 0 then
        rewards.coins = tonumber(self.p_coins)
    end
    rewards.items = self.p_displayList
    return rewards
end

--获取额外道具数据
function ShopPetConfig:getExtraPropList()
    local ret = {}
    for i = 1, #self.p_displayList do
        local shopItemData = self.p_displayList[i]
        if shopItemData.p_item ~= ITEMTYPE.ITEMTYPE_COIN and shopItemData.p_item ~= ITEMTYPE.ITEMTYPE_SENDCOUPON then
            ret[#ret + 1] = shopItemData
        end
    end

    return ret
end

function ShopPetConfig:getBenefitDisplayList()
    return self.p_displayList
end

-- 登录 活动在 商城数据后解析 需要判断弄下新手cashback道具
function ShopPetConfig:updateNoviceCashBackItem()
   
end

function ShopPetConfig:getDiscount()
    local value = 0
    return value
end

function ShopPetConfig:getStorePrice()
    return self.m_storePrice
end

function ShopPetConfig:getIsShowStorePrice()
    return self.m_showStore
end

function ShopPetConfig:setStorePrice(_price)
    if _price then
        self.m_storePrice = _price
    else
        self.m_storePrice = self.old_storePrice
    end
end

function  ShopPetConfig:isGoldenPet()
    if self.m_hotSaleType == "V_GOLD" or self.m_hotSaleType == "H_GOLD" then
        return true
    end
    return true --false
end

function ShopPetConfig:getStoreBuyId()
    return tostring(self.p_id)
end

function ShopPetConfig:getPrice()
    return self.p_price
end

function ShopPetConfig:getCoins()
    return 0
end

function ShopPetConfig:isMonthlyCard()
    return false
end

function ShopPetConfig:isScratchCard()
    return false
end

function  ShopPetConfig:isBig()
    return false
end

function  ShopPetConfig:isGolden()
    return false
end

function ShopPetConfig:isPetSale()
    return true
end

function ShopPetConfig:getDisPlay()
    return self.p_display or 0
end

function ShopPetConfig:getPetNum()
    return self.p_petNum
end

-- 可以删除
function ShopPetConfig:getFirstBuyDiscount()
    return 0
end

return ShopPetConfig