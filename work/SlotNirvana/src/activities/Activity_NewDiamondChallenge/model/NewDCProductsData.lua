--[[
    商店商品数据
]]
local ShopItem = require "data.baseDatas.ShopItem"
local NewDCProductsData = class("NewDCProductsData")

-- message LuckyChallengeV2Product {
--     optional int32 seq = 1;// 商品序号
--     optional string type = 2;// 商品类型
--     optional string coins = 3;// 金币
--     repeated ShopItem items = 4;// 物品
--     optional int32 cash = 5;// 需要的货币
--     optional int32 limit = 6;// 购买次数限制 -1不限次数
--     optional int32 buyTimes = 7;// 购买次数
--   }

function NewDCProductsData:parseData(data)
    self.p_seq = tonumber(data.seq) --商品序号
    self.p_type = data.type --商品类型
    self.p_coins = data.coins --金币

    -- if nil == self.p_items then
    --     self.p_items = ShopItem:create() --物品
    -- end
    self.p_items = self:parseItemData(data.items)

    self.p_cash = tonumber(data.cash) --需要的货币 
    self.p_limit = tonumber(data.limit) --购买次数限制 -1不限次数
    self.p_buyTimes= tonumber(data.buyTimes) --购买次数
end

-- 是否售完
function NewDCProductsData:isSellOut()
    if self.p_limit == -1 then --不限
        return false
    elseif self.p_buyTimes < self.p_limit then
        return false
    else
        return true
    end
end

function NewDCProductsData:parseItemData(data)
    local itemList = {}
    if data and #data > 0 then
        for i,v in ipairs(data) do
            local shop = ShopItem:create()
            shop:parseData(v)
            table.insert(itemList,shop)
        end
    end
    return itemList
end

--获取商品序号
function NewDCProductsData:getSeq()
    return self.p_seq
end

--获取购买次数限制
function NewDCProductsData:getLimit()
    return self.p_limit
end
--获取购买次数
function NewDCProductsData:getBuyTimes()
    return self.p_buyTimes
end

--获取金币 
function NewDCProductsData:getCoins()
    return self.p_coins
end

--道具 
function NewDCProductsData:getItems()
    return self.p_items
end

--获取需要的货币 
function NewDCProductsData:getCash()
    return self.p_cash
end

return NewDCProductsData