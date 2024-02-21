local ShopItem = util_require("data.baseDatas.ShopItem")
local QuestSkipSaleData_PlanB = class("QuestSkipSaleData_PlanB")

-- message QuestSkipSaleV3 {
--   optional string key = 1;
--   optional string value = 2;
--   optional string price = 3;
--   optional string coins = 4;
--   optional int32 skipItemReal = 5;  //需要消耗多少skip道具
--   optional int32 itemNum = 6;  //购买获得多少skip道具
-- }
function QuestSkipSaleData_PlanB:parseData(data)
    if data then
        self.p_price = data.price
        self.p_key = data.key
        self.p_coins = tonumber(data.coins)
        self.p_storeKey = data.value
        self.p_skipItemReal = data.skipItemReal or 10000
        self.p_itemNum = data.itemNum or 0
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = "QuestSkip"})
    end
end


function QuestSkipSaleData_PlanB:getSkipThisStageItemCost()
    return self.p_skipItemReal
end

function QuestSkipSaleData_PlanB:getBuySkipItemCount()
    return self.p_itemNum
end

-- 初始化折扣信息
function QuestSkipSaleData_PlanB:parseDiscountData(data)
    if not data.discountStoreKey or data.discountStoreKey == "" then
        self.p_fakePrice = ""
        return
    end

    if not data.discountPrice or data.discountPrice == "" then
        self.p_fakePrice = ""
        return
    end

    if tonumber(data.discountPrice) < tonumber(self.p_price) then
        self.p_fakePrice = data.price
        self.p_price = data.discountPrice
        self.p_storeKey = data.discountStoreKey
    end
end

function QuestSkipSaleData_PlanB:getIsOpen()
    return self.p_open
end

function QuestSkipSaleData_PlanB:setIsOpen(bl_open)
    if bl_open ~= nil then
        self.p_open = bl_open
    end
end

-- 已经激活或需要弹板
function QuestSkipSaleData_PlanB:getIsActive()
    return self.p_active or self.p_open
end

return QuestSkipSaleData_PlanB
