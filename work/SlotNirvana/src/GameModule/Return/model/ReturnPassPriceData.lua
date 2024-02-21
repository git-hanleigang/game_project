--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-04-19 11:13:05
]]

local ReturnPassPriceData = class("ReturnPassPriceData")

-- message ReturnSignPay {
--     optional string key = 1;
--     optional string keyId =2;
--     optional string price = 3;
--     optional int64 addVipPoints = 4;
--   }
function ReturnPassPriceData:parseData(_netData)
    self.p_key = _netData.key
    self.p_keyId = _netData.keyId
    self.p_price = _netData.price
    self.p_addVipPoints = tonumber(_netData.addVipPoints)
end

function ReturnPassPriceData:getKey()
    return self.p_key
end

function ReturnPassPriceData:getKeyId()
    return self.p_keyId
end

function ReturnPassPriceData:getPrice()
    return self.p_price
end

function ReturnPassPriceData:getAddVipPoints()
    return self.p_addVipPoints
end

return ReturnPassPriceData