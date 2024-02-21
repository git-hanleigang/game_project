--[[
    商店数据
]]
local NewDCStoreData = class("NewDCStoreData")
local productsData = require("activities.Activity_NewDiamondChallenge.model.NewDCProductsData")

-- message LuckyChallengeV2Store {
--     optional int32 cash = 1;
--     repeated LuckyChallengeV2Product products = 2;// 商品列表
--   }

function NewDCStoreData:parseData(data)
    self.p_cash = tonumber(data.cash)
    self.p_products = self:parseProductsData(data.products)
end

function NewDCStoreData:parseProductsData(data)
    local products = {}
    if data and #data > 0 then
        products = {}
        for i,v in ipairs(data) do
            local item = productsData:create()
            item:parseData(v)
            table.insert(products,item)
        end
    end 
    return products
end

--获取道具数
function NewDCStoreData:getCash()
    return self.p_cash 
end

function NewDCStoreData:getProducts()
    return self.p_products
end

function NewDCStoreData:getProductsByIndex(index)
    if index > 0 and index<= #self.p_products then
        return self.p_products[index]
    end
    return nil 
end

return NewDCStoreData