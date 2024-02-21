local BaseActivityData = require "baseActivity.BaseActivityData"
local TwoChooseOneGift = require "activities.Promotion_TornadoMagicStore.model.TwoChooseOneGift"
local PromotionTornadoMagicStoreData = class("PromotionTornadoMagicStoreData", BaseActivityData)

function PromotionTornadoMagicStoreData:ctor()
    PromotionTornadoMagicStoreData.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TornadoMagicStore)
    self._saleItems = {}
    self.m_isBuy = false
end

function PromotionTornadoMagicStoreData:parseData(data)
    if data.giftList and #data.giftList > 0 then
        for i = 1, #data.giftList do
            local config = TwoChooseOneGift:create()
            config:parseData(data.giftList[i])
            table.insert(self._saleItems, config)
        end
    end
    PromotionTornadoMagicStoreData.super.parseData(self, data)
    -- if data:HasField("buy") and data.buy == true then
    --     self:setOpenFlag(false)
    -- end
    if data:HasField("buy") then
        self.m_isBuy = data.buy or false
    end
end

function PromotionTornadoMagicStoreData:getItemByIndex(index)
    return self._saleItems[index]
end

function PromotionTornadoMagicStoreData:checkCompleteCondition()
    return self.m_isBuy
end

function PromotionTornadoMagicStoreData:isRunning()
    if not PromotionTornadoMagicStoreData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end

    return true
end

-- function PromotionTornadoMagicStoreData:getRefName()
--     return ACTIVITY_REF.TornadoMagicStore
-- end

return PromotionTornadoMagicStoreData
