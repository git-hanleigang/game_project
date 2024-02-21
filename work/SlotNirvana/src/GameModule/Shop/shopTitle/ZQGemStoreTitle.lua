local BaseStoreTitle = util_require("GameModule.Shop.shopTitle.BaseStoreTitle")
local ZQGemStoreTitle = class("ZQGemStoreTitle", BaseStoreTitle)

local ShopItem = util_require("data.baseDatas.ShopItem")

ZQGemStoreTitle.SHOP_RES_PATH = "shop_title_gem/"

-- 子类重写
function ZQGemStoreTitle:getTitleResPath()
    return "shop_title_gem/"
end

-- 子类重写
function ZQGemStoreTitle:getTitleInfos()
    return {
        {handler(self, self.getShowCoupon), "ShopGemCoupon", handler(self, self.updateCoupon), ACTIVITY_REF.ShopGemCoupon},
        {handler(self, self.getShowCoupon), "ShopGemCoupon_LunarNewYear", handler(self, self.updateCoupon), "Activity_ShopGemCoupon_LunarNewYear"},
        {handler(self, self.getShowCoupon), "ShopGemCoupon_CyberMonday", handler(self, self.updateCoupon), "Activity_ShopGemCoupon_CyberMonday"},
        {handler(self, self.getShowStatueBuff), "CardStatueBuff", handler(self, self.updateCardStatueBuff)},
        {handler(self, self.getShowLuckyStampExtraCard), "LuckyStamp_ExtraCard", handler(self, self.updateLuckyStampExtraCardInfo)},
        {handler(self, self.getShowGemStoreSale), "GemStoreSale", nil, "Activity_GemStoreSale"},
        {handler(self, self.getShowGemStoreSale), "GemStoreSale_Halloween", nil, "Activity_GemStoreSale_Halloween"},
        {handler(self, self.getShowGemStoreSale), "GemStoreSale_ThanksGiving", nil, "Activity_GemStoreSale_ThanksGiving"},
        {handler(self, self.getShowNormalTitle), "NormalTitle"}
    }
end

function ZQGemStoreTitle:getShowNormalTitle()
    return true
end

function ZQGemStoreTitle:getShowStatueBuff()
    -- if not globalDynamicDLControl:checkDownloaded("CardsShopTitle") then
    --     return false
    -- end

    if CardSysManager and CardSysManager.getBuffDataByType then
        local statueBuff = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_GEMSHOP_GEM_BONUS)
        if statueBuff > 0 then
            return true
        end
    end
    return false
end

function ZQGemStoreTitle:updateCardStatueBuff(_actNode)
    if CardSysManager and CardSysManager.getBuffDataByType then
        local statueBuff = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_GEMSHOP_GEM_BONUS)
        local fntBuff = _actNode:findChild("lb_number")
        if statueBuff and statueBuff > 0 then
            local buffMul = (statueBuff - 1) * 100
            if globalData.slotRunData.isPortrait == true then
                fntBuff:setString(buffMul .. "%")
            else
                fntBuff:setString(buffMul .. "% MORE GEMS")
            end
        end
    end
end

-- 钻石商城送优惠券活动
function ZQGemStoreTitle:getShowCoupon(refName)
    -- 如果当前优惠券没激活,不开启活动
    local hasSaleTicket = G_GetMgr(ACTIVITY_REF.ShopGemCoupon):getActiveStatus(2)
    local data = G_GetMgr(ACTIVITY_REF.ShopGemCoupon):getRunningData()
    if data and data.isRunning and data:isRunning() then
        if data:getThemeName() == refName then
            return (data:getDiscount() > 0 and hasSaleTicket)
        end
    end
    return false
end

function ZQGemStoreTitle:updateCoupon(actNode)
    local data = G_GetMgr(ACTIVITY_REF.ShopGemCoupon):getRunningData()
    if data and data.isRunning and data:isRunning() then
        local saleNumLB = actNode:findChild("lb_number")
        if saleNumLB then
            saleNumLB:setString(data:getDiscount() .. "% MORE GEMS")
        end
    end
end

-- --第二货币商城折扣
function ZQGemStoreTitle:getShowGemStoreSale(refName)
    if not refName then
        return false
    end

    local gemStoreSaleData = G_GetMgr(ACTIVITY_REF.GemStoreSale):getRunningData()
    if gemStoreSaleData and gemStoreSaleData.isRunning and gemStoreSaleData:isRunning() then
        if gemStoreSaleData:getThemeName() == refName then
            return gemStoreSaleData:getMaxDiscount() > 0
        end
    end
    return false
end

function ZQGemStoreTitle:getShowLuckyStampExtraCard()
    -- local data = G_GetActivityDataByRef(ACTIVITY_REF.LuckyStampCard)
    local data = G_GetMgr(ACTIVITY_REF.LuckyStampCard):getRunningData()
    if data and data.isRunning and data:isRunning() then
        return true
    end
    return false
end

function ZQGemStoreTitle:updateLuckyStampExtraCardInfo(_actNode)
    local cardNode = _actNode:findChild("sp_card")
    if cardNode then
        -- local data = G_GetActivityDataByRef(ACTIVITY_REF.LuckyStampCard)
        local data = G_GetMgr(ACTIVITY_REF.LuckyStampCard):getRunningData()
        if data and data:isRunning() then
            local rewardData = data:getRewards()
            if rewardData and rewardData[1] then
                local shopItem = ShopItem:create()
                shopItem:parseData(rewardData[1], true)
                if shopItem.p_mark and shopItem.p_mark[1] and shopItem.p_mark[1] == 4 then
                    -- 特殊卡
                else
                    shopItem:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
                end
                local shopItemUI = gLobalItemManager:createRewardNode(shopItem, ITEM_SIZE_TYPE.REWARD)
                if shopItemUI ~= nil then
                    cardNode:removeAllChildren()
                    cardNode:addChild(shopItemUI)
                    shopItemUI:setScale(0.9)
                end
            end
        end
    end
end

return ZQGemStoreTitle
