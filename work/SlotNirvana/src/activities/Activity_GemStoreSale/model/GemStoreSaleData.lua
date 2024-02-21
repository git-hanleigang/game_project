--[[--
    商城优惠券活动
    活动开启后商场金币后边会增加一个extra的折扣力度标识
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local GemStoreSaleData = class("GemStoreSaleData", BaseActivityData)

function GemStoreSaleData:parseData(data, isNetData)
    GemStoreSaleData.super.parseData(self, data, isNetData)

    self.p_discount = cjson.decode(data.discount)

    self.p_maxDiscount = 0
    for k, v in pairs(self.p_discount) do
        self.p_maxDiscount = math.max(self.p_maxDiscount, v.discount)
    end
end

function GemStoreSaleData:getMaxDiscount()
    return self.p_maxDiscount
end

function GemStoreSaleData:isRunning()
    if not GemStoreSaleData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end
    return true

end

-- 检查完成条件
function GemStoreSaleData:checkCompleteCondition()
    local shopCoinData, shopGemData = globalData.shopRunData:getShopItemDatas()
    if shopGemData then
        local gemStoreSaleDiscount = 0
        for i=1,#shopGemData do
            local shopGemConfig = shopGemData[i]
            if shopGemConfig and shopGemConfig.getCouponDiscount then
                gemStoreSaleDiscount = gemStoreSaleDiscount + shopGemConfig:getCouponDiscount()
            end
        end
        return gemStoreSaleDiscount == 0
    end
    return false
end
return GemStoreSaleData
