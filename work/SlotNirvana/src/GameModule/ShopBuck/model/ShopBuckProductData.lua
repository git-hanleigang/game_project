--[[
]]
local ShopBuckProductData = class("ShopBuckProductData")

-- message BuckStoreProductResult {
--     optional int32 index = 1; // 索引
--     optional string key = 2; // 档位
--     optional string keyId = 3;// 付费链接
--     optional string price = 4; // 价格
--     optional double buckNum = 5;// 代币数量
--   }
function ShopBuckProductData:parseData(_data, _clientIndex, _isBest)
    self.m_clientIndex = _clientIndex
    self.m_isBest = _isBest

    self.p_index = _data.index -- 注意：该索引是配置，不连续且不是从1开始的，付费时需要传给服务器
    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_buckNum = _data.buckNum
end

function ShopBuckProductData:getClientIndex()
    return self.m_clientIndex
end

function ShopBuckProductData:isBestValue()
    return self.m_isBest
end

function ShopBuckProductData:getIndex()
    return self.p_index
end

function ShopBuckProductData:getKey()
    return self.p_key
end

function ShopBuckProductData:getKeyId()
    return self.p_keyId
end

function ShopBuckProductData:getPrice()
    return self.p_price
end

function ShopBuckProductData:getBuckNum()
    return self.p_buckNum
end

return ShopBuckProductData