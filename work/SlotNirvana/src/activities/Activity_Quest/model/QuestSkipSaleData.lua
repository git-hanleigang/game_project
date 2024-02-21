local ShopItem = util_require("data.baseDatas.ShopItem")
local QuestSkipSaleData = class("QuestSkipSaleData")

--message QuestSkipSale {
--    optional string price = 1;     //促销价格
--    optional string storeKey = 2;  //购买 key  1p99
--    optional int64 coins = 3;      //金币
--    optional int32 vipPoints = 4;  //vip 点
--    optional int32 clubPoints = 5; //高倍场点数
--    repeated ShopItem items = 6;   //道具
--    optional bool open = 7;        //是否弹出
--    optional bool active = 8;        //是否开启
--    optional bool skip = 9;        //是否买
--    optional string discountPrice = 10;//折扣价格
--    optional string discountStoreKey = 11;// //购买 key  1p99
--}
function QuestSkipSaleData:parseData(data)
    if data then
        self.p_price = data.price
        self.p_storeKey = data.storeKey
        self.p_coins = tonumber(data.coins)
        self.p_vipPoints = tonumber(data.vipPoints)
        self.p_clubPoints = tonumber(data.clubPoints)
        self.p_items = {}
        if data.items ~= nil and #data.items > 0 then
            local shopItems = data.items
            for i = 1, #shopItems do
                local itemData = shopItems[i]
                local shopItem = ShopItem:create()
                shopItem:parseData(itemData)

                self.p_items[#self.p_items + 1] = shopItem
            end
        end

        self.p_open = data.open
        self.p_active = data.active
        self.p_skip = data.skip

        self:parseDiscountData(data)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = "QuestSkip"})
    end
end

-- 初始化折扣信息
function QuestSkipSaleData:parseDiscountData(data)
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

function QuestSkipSaleData:getIsOpen()
    return self.p_open
end

function QuestSkipSaleData:setIsOpen(bl_open)
    if bl_open ~= nil then
        self.p_open = bl_open
    end
end

-- 已经激活或需要弹板
function QuestSkipSaleData:getIsActive()
    return self.p_active or self.p_open
end

return QuestSkipSaleData
