--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:26:09
--
local DeluexeClubData = class("DeluexeClubData")
local ShopItem = util_require("data.baseDatas.ShopItem")

DeluexeClubData.p_open = nil
DeluexeClubData.p_currPoint = nil
DeluexeClubData.p_totalPoint = nil
DeluexeClubData.p_expire = nil
DeluexeClubData.p_expireAt = nil
DeluexeClubData.p_coins = nil
DeluexeClubData.p_highBetLevels = nil
DeluexeClubData.p_spinOffsetTimes = nil
DeluexeClubData.p_spinTimes = nil
DeluexeClubData.p_minBet = nil
DeluexeClubData.p_bOpenByExperienceCard = false -- 是否是掉落开启道具开启的高倍场
DeluexeClubData.p_experienceCardItemList = {} --高倍场开启道具
DeluexeClubData.p_crownCount = 0 --皇冠数量
DeluexeClubData.p_itemsCoins = {} --体验卡换算金币数
function DeluexeClubData:ctor()

end

function DeluexeClubData:parseData(data)
    self.p_open = data.open
    self:changeClubOpenLevelConstantValue()
    self.p_currPoint = data.currentPoint
    self.p_totalPoint = data.totalPoint
    self.p_expire = tonumber(data.expire)
    self.p_expireAt = tonumber(data.expireAt)
    self.p_minBet = tonumber(data.minBet)
    self.p_crownCount = tonumber(data.openTimes) or 0
    -- self.p_itemsCoins = data.itemsCoins

    if data.coins then
        self.p_coins = tonumber(data.coins)
    end
    if data.spinOffsetTimes then
        self.p_spinOffsetTimes = data.spinOffsetTimes
    end
    if data.spinTimes then
        self.p_spinTimes = data.spinTimes
    end

    if data.items and #data.items > 0 then
        self.p_experienceCardItemList = self:parseShopItem(data.items)
        self.p_bOpenByExperienceCard = self.p_open and not globalData.deluexeStatus  --之前未开启现在开启
        
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM) -- 不要数据更新就弹板子(根据自己的功能去整理弹板顺序)
    end 

    if data.itemsCoins and #data.itemsCoins > 0 then
        for i = 1,#data.itemsCoins do
            table.insert(self.p_itemsCoins,tonumber(data.itemsCoins[i]))
        end
    end

    if globalData.deluexeStatus == nil then
        globalData.deluexeStatus = self.p_open
    end
    if self.p_open == true and globalData.deluexeStatus ~= self.p_open then
        gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig()
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUEXECLUB_POINT_UPDATE)
end

function DeluexeClubData:getDeluexeClubStatus()
    --cxc 2021-07-17 20:16:25 忽略等级判断 就看服务器说开没开
    return self.p_open
end

-- 获取皇冠数量
function DeluexeClubData:getDeluexeClubCrownNum()
    return self.p_crownCount or 0
end

function DeluexeClubData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_expireAt / 1000, false)
    if isOver == true then
        self.p_open = false
        globalData.deluexeStatus = false
    end
    return strTime, isOver
end

function DeluexeClubData:getChangeCoinNum()
    if self.p_coins == nil then
        return 0
    end
    return self.p_coins
end

-- 解析高倍场 体验卡道具
function DeluexeClubData:parseShopItem(_items)
    local itemList = {}
    for _, data in ipairs(_items) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data, true)

        table.insert(itemList, shopItem)
    end

    return itemList
end

-- 重新封装一个接口对外返回,为了避免外部调用修改太多
function DeluexeClubData:getExperienceCardItemList()
    return self.p_experienceCardItemList
end
-- 获取高倍场体验卡信息 
-- csc 2021-09-16 16:33:14 注释* 默认返回的是list 第一位
function DeluexeClubData:getExperienceCardItem()
    return self.p_experienceCardItemList[1]
end
function DeluexeClubData:resetExperienceCardItem()
    if #self.p_experienceCardItemList == 0 then
        self.p_experienceCardItemList = {}
    end
end

-- 获取是否是体验卡开启的高倍场
function DeluexeClubData:checkIsOpenByExperienceCard( )
    if self.p_bOpenByExperienceCard then
        return true
    end

    local item = globalData.deluexeClubData:getExperienceCardItem()
    if not item then
        return false
    end 
    local icon = item.p_icon or "1"
    local day = tonumber(string.sub(icon, -1)) or 1
    local leftTime = util_getLeftTime(self.p_expireAt - day * 86400000)

    return leftTime <= 0
end
-- reset 高倍场体验卡 时候开启高倍场 标识
function DeluexeClubData:resetIsOpenByExperienceCard()
    self.p_bOpenByExperienceCard = false
end

-- 获取到期时间
function DeluexeClubData:getExpireAt()
    return self.p_expireAt / 1000
end

-- cxc 2021-07-15 21:04:39
-- 更新高倍场开启等级 常量(高倍场体验卡 开的 高倍场直接开， 其他地方用到相关等级的限制 直接忽略等级限制)
function DeluexeClubData:changeClubOpenLevelConstantValue()
    if self:getDeluexeClubStatus() then
        globalData.constantData.CLUB_OPEN_LEVEL = 1
    else
        globalData.constantData.CLUB_OPEN_LEVEL = globalData.constantData.CLUB_OPEN_LEVEL_COPY
    end
end

-- csc 返回高倍场体验卡对应的金币价值
function DeluexeClubData:getItemsCoinsList()
    return self.p_itemsCoins
end

function DeluexeClubData:resetItemsCoins()
    if #self.p_itemsCoins == 0 then
        self.p_itemsCoins = {}
    end
end

function DeluexeClubData:removeCurrExperienceCardData()
    if #self.p_experienceCardItemList > 0 then
        table.remove(self.p_experienceCardItemList,1)     
    end
    if #self.p_itemsCoins > 0 then
        table.remove(self.p_itemsCoins,1)     
    end
end
return  DeluexeClubData