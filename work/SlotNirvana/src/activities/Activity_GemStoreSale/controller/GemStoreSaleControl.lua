--[[
    第二货币商城折扣
]]
--
local Activity_GemStoreSale = class("Activity_GemStoreSale", BaseActivityControl)

function Activity_GemStoreSale:ctor()
    Activity_GemStoreSale.super.ctor(self)
    self:setRefName(ACTIVITY_REF.GemStoreSale)
end

function Activity_GemStoreSale:getMaxDiscount()
    local data = self:getRunningData()
    if data then
        -- csc 2022-02-08 12:02:25 改为从商城最大档位获取
        local maxDiscount = data:getMaxDiscount()
        local coinsShopData, gemsShopData = globalData.shopRunData:getShopItemDatas()
        for i = #gemsShopData, 1, -1 do
            local gemData = gemsShopData[i]
            local shopGemsDis = gemData:getCouponDiscount()
            if shopGemsDis > 0 then
                maxDiscount = shopGemsDis
                break
            end
        end
        return maxDiscount
    end
    return 0
end
return Activity_GemStoreSale
