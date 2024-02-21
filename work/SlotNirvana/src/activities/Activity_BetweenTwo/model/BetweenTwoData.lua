--二选一充值
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseActivityData = require "baseActivity.BaseActivityData"
local BetweenTwoData = class("BetweenTwoData", BaseActivityData)
BetweenTwoData.p_saleItem = nil --促销数据
BetweenTwoData.p_fruits = nil --当前展示水果类型
BetweenTwoData.p_status = nil --促销的状态 [Init,Process,Finish]
BetweenTwoData.p_cardResult = nil --集卡道具
BetweenTwoData.p_select = nil --选择结果
function BetweenTwoData:parseData(data, isNetData)
    BaseActivityData.parseData(self, data, isNetData)
    if data.saleItem then
        local saleItemCfg = SaleItemConfig:create()
        saleItemCfg:parseData(data.saleItem)
        self.p_saleItem = saleItemCfg
    end
    local fruitsData = data.fruits
    if fruitsData ~= nil and #fruitsData > 0 then
        self.p_fruits = {}
        for i = 1, #fruitsData do
            self.p_fruits[i] = fruitsData[i]
        end
    end
    self.p_status = data.status
    if data.cardResult then
        self.p_cardResult = self:parseCardInfoData(data.cardResult) --集卡数据
    end
    self.p_select = data.select
    --刷新数据
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BETWEENTWO_DATA_REFRESH)
end
--获取促销数据
function BetweenTwoData:getSaleItem()
    return self.p_saleItem
end
--获取促销数据中的道具
-- cxc 2021-03-19 10:53:26 二选一的 卡片显示逻辑 cardResult or 促销数据里的道具卡(只配一个)
function BetweenTwoData:getSaleRewardItem()
    if not self.p_saleItem then
        return
    end

    -- 获取第一个
    local rewardItem = self.p_saleItem:getShopItem(1)
    rewardItem.p_mark = nil
    return rewardItem
end

--获取水果id
function BetweenTwoData:getFruitId(index)
    if not index then
        return -1
    end
    if self.p_fruits and #self.p_fruits >= index then
        return self.p_fruits[index]
    end
    return -1
end
--是否没有购买过
function BetweenTwoData:isFirst()
    if self.p_status and self.p_status == "Init" then
        return true
    end
    return false
end
--是否完成
function BetweenTwoData:isActivityFinish()
    if self.p_status and self.p_status == "Finish" then
        return true
    end
    return false
end
--是否是选择的水果
function BetweenTwoData:isSelect(fruitId)
    if fruitId and self.p_select and self.p_select > 0 then
        if fruitId == self.p_select then
            return true
        end
    end
    return false
end
--获取卡片信息
function BetweenTwoData:getCardResult()
    if self.p_cardResult and self.p_cardResult.cardId and #self.p_cardResult.cardId <= 0 then
        return nil
    end

    return self.p_cardResult
end
--CardSysConfigs.CardClone 这里拷贝集卡
function BetweenTwoData:parseCardInfoData(tInfo)
    local card = {}
    card.cardId = tInfo.cardId
    card.number = tInfo.number
    card.year = tInfo.year
    card.season = tInfo.season
    card.clanId = tInfo.clanId
    card.albumId = tInfo.albumId
    card.type = tInfo.type
    card.star = tInfo.star
    card.name = tInfo.name
    card.icon = tInfo.icon
    card.count = tInfo.count
    card.linkCount = tInfo.linkCount
    card.newCard = tInfo.newCard
    card.description = tInfo.description
    card.source = tInfo.source
    card.firstDrop = tInfo.firstDrop
    card.nadoCount = tInfo.nadoCount
    card.gift = tInfo.gift
    card.greenPoint = tInfo.greenPoint
    card.goldPoint = tInfo.goldPoint
    card.exchangeCoins = tonumber(tInfo.exchangeCoins or 0)
    card.round = tInfo.round
    return card
end

function BetweenTwoData:checkCompleteCondition()
    return self:isActivityFinish()
end

function BetweenTwoData:isRunning()
    if not BetweenTwoData.super.isRunning(self) then
        return false
    end

    if self:isActivityFinish() then
        return false
    end

    return true
end

return BetweenTwoData
