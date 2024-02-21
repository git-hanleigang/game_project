--[[--
    第二货币商城折扣送道具
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require "baseActivity.BaseActivityData"
local GemCouponData = class("GemCouponData", BaseActivityData)

-- message StoreGemGift {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional bool over = 4; //购买后结束标识
--     repeated ShopItem item = 5;
--     optional int32 discount = 6; //最大折扣
-- }
function GemCouponData:parseData(_data)
    GemCouponData.super.parseData(self, _data)

    self.p_over = _data.over
    self.p_discount = _data.discount or 0
    self.p_items = self:parseItemsData(_data.item)
end

function GemCouponData:parseItemsData(_items)
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function GemCouponData:getMaxDiscount()
    return self.p_discount
end

function GemCouponData:getItem()
    if #self.p_items > 0 then
        return self.p_items[#self.p_items]
    end
end

-- function GemCouponData:isRunning()
--     if not GemCouponData.super.isRunning(self) then
--         return false
--     end

--     if self:isCompleted() then
--         return false
--     end
--     return true

-- end

-- -- 检查完成条件
-- function GemCouponData:checkCompleteCondition()
--     local shopCoinData, shopGemData = globalData.shopRunData:getShopItemDatas()
--     if shopGemData then
--         local couponDiscount = 0
--         for i=1, #shopGemData do
--             local shopConfig = shopGemData[i]
--             if shopConfig and shopConfig.getCouponDiscount then
--                 couponDiscount = couponDiscount + shopConfig:getCouponDiscount()
--             end
--         end
--         return couponDiscount == 0
--     end
--     return false
-- end

return GemCouponData
