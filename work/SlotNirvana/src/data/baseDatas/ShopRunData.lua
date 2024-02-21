--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-10 21:18:39
--
--fixNewIos
local ShopConfig = require "data.baseDatas.ShopConfig"
local ShopRunData = class("ShopRunData")

ShopRunData.shopRewardTime = nil

ShopRunData.shopLevelBurstEndTime = nil -- （升级buff）
ShopRunData.shopCoinsBurstEndTime = nil -- （金币抽成buff）
ShopRunData.shopDoubleBurstEndTime = nil -- （双重buff）

ShopRunData.p_shopData = nil
ShopRunData.m_expireHandlerId = nil -- 倒计时刷新的 id

ShopRunData.m_luckySpinLevel = nil

ShopRunData.m_showShopPageIndex = nil -- 商城当前显示的页签
ShopRunData.SHOP_PAGE_CONFIG = {
    {index = 1, type = "COIN"},
    {index = 2, type = "GEM"}
}

function ShopRunData:ctor()
    self.shopRewardTime = 0
    self.shopLevelBurstEndTime = 0
    self.shopCoinsBurstEndTime = 0 -- （金币抽成buff）
    self.shopDoubleBurstEndTime = 0 -- （双重buff）
    self.m_showShopPageIndex = 1
end

function ShopRunData:parseShopData(data)
    if self.p_shopData == nil then
        self.p_shopData = ShopConfig:create()
    end
    self.p_shopData:parseData(data)

    self:updateExpireTime()
end

function ShopRunData:syncShopGift(data)
    local giftData = self.p_shopData.p_giftData
    giftData.p_rewadCoin = data.coins
    giftData.p_coolDown = data.coolDown

    giftData:checkUpdateCoolDown()
end

--[[
    @desc: 获取领取礼包后的奖励金币
    time:2019-04-18 15:32:24
    @return:
]]
function ShopRunData:getShpGiftRewardCoins()
    return self.p_shopData.p_giftData.p_rewadCoin
end
--[[
    @desc: 获得奖励cd时间
    time:2019-04-18 15:32:13
    @return:
]]
function ShopRunData:getShpGiftCD()
    return self.p_shopData.p_giftData.p_coolDown
end

--[[ 
    @desc: 获取商城物品列表
    time:2019-04-15 15:42:37
    @return:
]]
function ShopRunData:getShopItemDatas()
    return self.p_shopData:getCoinData(), self.p_shopData:getGemData() ,self.p_shopData:getHotSaleData(),self.p_shopData:getPetData()
end

function ShopRunData:getShopItemDatasExchange(headIcon)
    if not headIcon then
        return self.p_shopData.p_coins, self.p_shopData.p_gems
    end
    local function swapFunc(tempList)
        local index
        for i = 1, #tempList do
            local disPlayList = tempList[i].p_displayList
            for j = 1, #disPlayList do
                if disPlayList[j].p_icon == headIcon then
                    index = j
                    break
                end
            end
            local clover = disPlayList[index]
            table.remove(disPlayList, index)
            table.insert(disPlayList, 1, clover)
        end
    end
    swapFunc(self.p_shopData.p_coins)
    swapFunc(self.p_shopData.p_gems)
    return self.p_shopData.p_coins, self.p_shopData.p_gems
end

function ShopRunData:isShopFirstBuyed()
    if not self.p_shopData then
        printError("shop data is nil!!!!")
        return true
    end
    return self.p_shopData.p_shopFirstBuyed
end

--添加cd时间
function ShopRunData:isShowFirstBuyLayer(_bIgnoreNoobLevel)
    -- local CDTIME = 15*60
    if not self:isShopFirstBuyed() then
        if globalNoviceGuideManager:isNoobUsera(_bIgnoreNoobLevel) then --新用户
            -- if not self.m_firstBuyCDtime then
            --       self.m_firstBuyCDtime = gLobalDataManager:getNumberByField("firstBuyCDtime",0)
            -- end
            -- if os.time()-self.m_firstBuyCDtime>=CDTIME then
            --       self.m_firstBuyCDtime = os.time()
            --       gLobalDataManager:setNumberByField("firstBuyCDtime",self.m_firstBuyCDtime)
            --       return true
            -- end
            return true
        end
    end
    return false
end

--[[
    @desc: 更新倒计时刷新的
    time:2019-04-15 12:26:59
    @return:
]]
function ShopRunData:updateExpireTime()
    if self.m_expireHandlerId ~= nil then
        scheduler.unscheduleGlobal(self.m_expireHandlerId)
        self.m_expireHandlerId = nil
    end
    -- local expireUpdateTime = math.floor((self.p_shopData.p_expireAt - globalData.userRunData.p_serverTime) / 1000)
    -- if expireUpdateTime <= 0 then
    --     expireUpdateTime = 0
    --     return
    -- end
    -- expireUpdateTime = expireUpdateTime + 3 --加5秒延迟 防止时间不同步拉取前一天数据
    self.m_expireHandlerId =
        scheduler.scheduleGlobal(
        function()
            local leftTime = math.max(util_getLeftTime(self.p_shopData.p_expireAt), 0)
            if leftTime <= 0 then
                gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig()
                scheduler.unscheduleGlobal(self.m_expireHandlerId)
                self.m_expireHandlerId = nil
            end
        end,
        1
    )
end
function ShopRunData:getShopExpireTime()
    if self.p_shopData and self.p_shopData.p_expireAt then
        return self.p_shopData.p_expireAt
    end
    return nil
end

function ShopRunData:getShopTicketExpireTime()
    return self.p_shopData:getTicketExpireAt()
end

function ShopRunData:setLuckySpinLevel(level)
    if level == nil then
        level = 1
    end
    -- 玩完luckyspin时判断luckyspin的活动在大厅里是否要移除
    if globalData.luckySpinCardData:isExist() == true then
        if level ~= self.m_luckySpinLevel and level > 6 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, globalData.luckySpinCardData.p_activityId)
        end
    end
    -- 玩完luckyspin时判断luckyspin的活动在大厅里是否要移除
    -- local goldenCard = G_GetActivityDataByRef(ACTIVITY_REF.LuckySpinGoldenCard)
    local goldenCard = G_GetMgr(ACTIVITY_REF.LuckySpinGoldenCard):getRunningData()
    if goldenCard and goldenCard:isExist() == true then
        if level ~= self.m_luckySpinLevel and level > 6 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, goldenCard:getID())
        end
    end
    self.m_luckySpinLevel = level
end

function ShopRunData:getLuckySpinLevel()
    return self.m_luckySpinLevel
end

function ShopRunData:getLuckySpinIsOpen()
    if self.m_luckySpinLevel and self.m_luckySpinLevel <= 6 then
        return true
    else
        return false
    end
end

function ShopRunData:setShopPageIndex(index)
    self.m_showShopPageIndex = index
end

function ShopRunData:getShopPageIndex()
    return self.m_showShopPageIndex
end

function ShopRunData:getShopType()
    if not self.m_showShopPageIndex then
        self.m_showShopPageIndex = 1
    end
    return self.SHOP_PAGE_CONFIG[self.m_showShopPageIndex].type
end

-- 登录 活动在 商城数据后解析 需要判断弄下新手cashback道具
function ShopRunData:updateNoviceCashBackItem()
    -- 金币页签
    local coinsData = self.p_shopData:getCoinData()
    if coinsData then
        for _, shopCoinConfig in pairs(coinsData) do
            if shopCoinConfig and shopCoinConfig.updateNoviceCashBackItem then
                shopCoinConfig:updateNoviceCashBackItem()
            end
        end
    end

    -- -- 商城热卖
    -- local hotSaleData = self.p_shopData:getHotSaleData()
    -- if hotSaleData then
    --     for _, shopCoinConfig in pairs(hotSaleData) do
    --         if shopCoinConfig and shopCoinConfig.updateNoviceCashBackItem then
    --             shopCoinConfig:updateNoviceCashBackItem()
    --         end
    --     end
    -- end
end

function ShopRunData:getTicketType(_pageType)
    return self.p_shopData:getTicketType(_pageType)
end

return ShopRunData
