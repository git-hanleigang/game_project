--[[
]]
local ShopBuckProductData = import(".ShopBuckProductData")

local BaseGameModel = require("GameBase.BaseGameModel")
local ShopBuckData = class("ShopBuckData", BaseGameModel)

-- message BuckStore {
--     optional double bucks = 1; // 代币数量
--     repeated BuckStoreProductResult product = 2;// 价格 对应 代币数量
--   }
function ShopBuckData:parseData(_data)
    ShopBuckData.super.parseData(self, _data)
    self.p_bucks = string.format("%.2f", _data.bucks) 
    self.p_products = {}
    if _data.products and #_data.products > 0 then
        for i=1,#_data.products do
            local prData = ShopBuckProductData:create()
            prData:parseData(_data.products[i], i, i==#_data.products)
            table.insert(self.p_products, prData)
        end
    end
end

function ShopBuckData:getBucks()
    return self.p_bucks
end

function ShopBuckData:isBuckEnough(_dollor)
    if self.p_bucks ~= nil and self.p_bucks ~= "" and _dollor ~= nil and _dollor ~= "" then
        if tonumber(self.p_bucks) >= tonumber(_dollor) then
            return true
        end
    end
    return false
end

function ShopBuckData:getProducts()
    return self.p_products
end

function ShopBuckData:getProductByIndex(_index)
    if _index and self.p_products and #self.p_products > 0 then
        for i=1,#self.p_products do
            local prData = self.p_products[i]
            if prData:getClientIndex() == _index then
                return prData
            end
        end
    end
    return nil
end

return ShopBuckData