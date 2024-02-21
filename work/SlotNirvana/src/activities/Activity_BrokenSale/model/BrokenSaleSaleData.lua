local BankruptcySaleConfig = require("activities.Activity_BrokenSale.model.BankruptcySaleConfig")
local BaseActAndSale = require("baseActivity.BaseActAndSale")
local BrokenSaleSaleData = class("BrokenSaleSaleData", BaseActAndSale)

function BrokenSaleSaleData:parseData(data)
    if not data then
        return
    end

    BrokenSaleSaleData.super.parseData(self, data)

    self.p_keyId = '';

    -- 促销信息
    self.m_saleItems = {}

    self.m_isHasSale = false
    self.m_isHasBrokenSale = false

    if data.configs and #data.configs > 0 then
        local configs = data.configs
        for i = 1,3 do
            local config = BankruptcySaleConfig:create()
            config:parseData(configs[i])
            table.insert(self.m_saleItems, config)
        end
        self.m_isHasBrokenSale = #data.configs >= 3
        self.m_isHasSale = true
    end

    if data:HasField("firstSale") then
        G_GetMgr(G_REF.FirstCommonSale):parseData(data.firstSale, true)
        self.m_isHasSale = true
    end
end

function BrokenSaleSaleData:isHasBrokenSale()
    return self.m_isHasBrokenSale
end

function BrokenSaleSaleData:isHasSale()
    return self.m_isHasSale
end

--获取奖励信息List
function BrokenSaleSaleData:getExtraPropList(index)
    return self:getSaleItemByIndex(index):getExtraPropList()
end

-- 促销档位信息
function BrokenSaleSaleData:getSaleItems()
    return self.m_saleItems or {}
end

-- 获得促销商品信息
function BrokenSaleSaleData:getSaleItemByIndex(index)
    if not index then
        return nil
    end
    return self.m_saleItems[index]
end

return BrokenSaleSaleData
