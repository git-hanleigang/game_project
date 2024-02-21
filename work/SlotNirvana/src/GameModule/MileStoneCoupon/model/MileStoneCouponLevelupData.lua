--[[
    里程碑优惠券-等级
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local MileStoneCouponLevelupData = class("MileStoneCouponLevelupData")

function MileStoneCouponLevelupData:ctor()
    self.m_popupUI = false
end

function MileStoneCouponLevelupData:parseData(_netData)
    self.m_popupUI = true

    self.p_items = {}
    if _netData and #_netData > 0 then
        for i = 1, #_netData do
            local itemData = _netData[i]
            local shopItem = ShopItem:create()
            shopItem:parseData(itemData, true)
            table.insert(self.p_items, shopItem)
        end
    end
end

function MileStoneCouponLevelupData:getPopupUI()
    return self.m_popupUI
end
function MileStoneCouponLevelupData:setPopupUI(_isPopup)
    self.m_popupUI = _isPopup
end

function MileStoneCouponLevelupData:getItems()
    return self.p_items
end

-- function MileStoneCouponLevelupData:getLevel()
--     local iconName = self.p_items[1]:getItemName()
--     local iconStrs = string.split(iconName, "_")
--     return iconStrs[1] or "0"
-- end

function MileStoneCouponLevelupData:getDiscount()
    return self.p_items[1]:getNum()
end

-- function MileStoneCouponLevelupData:checkLevel()
--     if globalData.userRunData.levelNum == self.p_level then
--     end
-- end

return MileStoneCouponLevelupData
