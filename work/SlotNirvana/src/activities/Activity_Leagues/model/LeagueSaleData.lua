--[[
    关卡比赛促销
    author: 徐袁
    time: 2021-02-18 16:16:55
]]
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseActivityData = require("baseActivity.BaseActivityData")
local LeagueSaleData = class("LeagueSaleData", BaseActivityData)

function LeagueSaleData:parseData(data)
    if not data then
        return
    end

    LeagueSaleData.super.parseData(self, data)

    -- 促销信息
    self.m_saleItems = {}
    for i = 1, #data.sales do
        local _item = SaleItemConfig:create()
        _item:parseData(data.sales[i])

        table.insert(self.m_saleItems, _item)
    end
end

-- 促销档位信息
function LeagueSaleData:getSaleItems()
    return self.m_saleItems or {}
end

-- 获得促销商品信息
function LeagueSaleData:getSaleItemByIndex(index)
    if not index then
        return nil
    end
    return self.m_saleItems[index]
end

function LeagueSaleData:isRunning()
    if not LeagueSaleData.super.isRunning(self) then
        return false
    end

    return G_GetMgr(G_REF.LeagueCtrl):checkHadRunningData()
end

return LeagueSaleData
