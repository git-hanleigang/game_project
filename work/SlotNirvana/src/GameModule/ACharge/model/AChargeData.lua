--[[
    AppCharge数据
    author:{author}
    time:2023-10-24 18:26:18
]]
-- message AppCharge {
--     optional string voucher = 1;//代金券数量
--     repeated AppChargeProduct products = 2;
-- }
local BaseGameModel = require("GameBase.BaseGameModel")
local AppChargeProduct = import(".AChargeProduct")
local AppChargeData = class("AppChargeData", BaseGameModel)

function AppChargeData:ctor()
    self.m_voucher = 0
    -- 兑换商品信息列表
    self.m_products = {}
end

function AppChargeData:parseData(data)
    self.m_voucher = data.voucher or 0

    self.m_products = {}

    -- data.products = {
    --     {
    --         id = "1", 
    --         price = "0.99",
    --         coins = "9000090000"
    --     },
    --     {
    --         id = "2", 
    --         price = "4.99",
    --         coins = "9999999990000"
    --     },
    -- }
    for i = 1, #(data.products or {}) do
        local _product = AppChargeProduct:create()
        _product:parseData(data.products[i])
        self.m_products["" .. _product:getId()] = _product
    end
end

function AppChargeData:getProducts()
    return self.m_products
end

function AppChargeData:getProductById(id)
    if not id then
        return 
    end
    return self.m_products["" .. id]
end

return AppChargeData
