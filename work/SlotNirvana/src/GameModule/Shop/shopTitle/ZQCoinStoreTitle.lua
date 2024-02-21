local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseStoreTitle = util_require("GameModule.Shop.shopTitle.BaseStoreTitle")
local ZQCoinStoreTitle = class("ZQCoinStoreTitle", BaseStoreTitle)

-- 子类重写
function ZQCoinStoreTitle:getTitleResPath()
    return "shop_title/"
end

-- 子类重写
function ZQCoinStoreTitle:getTitleInfos()
    return {
        -- 默认商城首充
        {handler(self, self.getFirstBuyType), "FirstPurchase"},
        {handler(self, self.getShowShopRandomCard), "StoreSaleRandomCard", handler(self, self.updateShopRandomCardInfo)},
        {handler(self, self.getShowLuckyStampExtraCard), "LuckyStamp_ExtraCard", handler(self, self.updateLuckyStampExtraCardInfo)},
        {handler(self, self.getShowMulLuckyStamp), "MulLuckyStamp"},
        {handler(self, self.getShowRandomCard), "LuckySpinRandomCard", handler(self, self.updateRandomCardInfo)},
        {handler(self, self.getShowAppointCard), "LuckySpinAppointCard"},
        -- 商城节日折扣券
        {handler(self, self.getShowShopSale), "PresidentDay", handler(self, self.updateShopSaleInfo), "Activity_PresidentDay"},
        {handler(self, self.getShowShopSale), "WomensDay", handler(self, self.updateShopSaleInfo), "Activity_WomensDay"},
        {handler(self, self.getShowShopSale), "EasterCoupon", handler(self, self.updateShopSaleInfo), "Activity_EasterDay"},
        {handler(self, self.getShowShopSale), "TwoCoupons_LunarYear", handler(self, self.updateShopSaleInfo), "Activity_TwoCoupons_LunarYear"},
        {handler(self, self.getShowShopSale), "TwoCoupons_Columbus", handler(self, self.updateShopSaleInfo), "Activity_TwoCoupons_Columbus"},
        {handler(self, self.getShowShopSale), "TwoCoupons_Cincodemayo", handler(self, self.updateShopSaleInfo), "Activity_TwoCoupons_Cincodemayo"},
        {handler(self, self.getShowShopSale), "TwoCoupons_FathersDay", handler(self, self.updateShopSaleInfo), "Activity_TwoCoupons_FathersDay"},
        {handler(self, self.getShowShopSale), "TwoCoupons_July4th", handler(self, self.updateShopSaleInfo), "Activity_TwoCoupons_July4th"},
        {handler(self, self.getShowShopSale), "TwoCoupons_MemorialDay", handler(self, self.updateShopSaleInfo), "Activity_TwoCoupons_MemorialDay"},
        {handler(self, self.getShowShopSale), "TwoCoupons_NewSeason", handler(self, self.updateShopSaleInfo), "Activity_TwoCoupons_NewSeason"},
        {handler(self, self.getShowShopSale), "TwoCoupons_SeaTheSale", handler(self, self.updateShopSaleInfo), "Activity_TwoCoupons_SeaTheSale"},
        {handler(self, self.getShowShopSale), "TwoCoupons_Labor", handler(self, self.updateShopSaleInfo), "Activity_TwoCoupons_Labor"},
        {handler(self, self.getShowShopSale), "TwoCoupons_AustraliaDay", handler(self, self.updateShopSaleInfo), "Activity_TwoCoupons_AustraliaDay"},
        {handler(self, self.getShowShopSale), "TwoCoupons_President22", handler(self, self.updateShopSaleInfo), "Activity_TwoCoupons_President22"},
        -- 商城节日四联
        {handler(self, self.getShowSaleTicket), "SaleTicketNewYear2022", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_NewYear2022"},
        {handler(self, self.getShowSaleTicket), "SaleTicket2022S1New", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_2022S1New"},
        {handler(self, self.getShowSaleTicket), "SaleTicketBlackFriday2021", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_BlackFriday2021"},
        {handler(self, self.getShowSaleTicket), "SaleTicketFreaky", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_Freaky"},
        {handler(self, self.getShowSaleTicket), "SaleTicketChineseNewYear", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_ChineseNewYear"},
        {handler(self, self.getShowSaleTicket), "SaleTicketSuperBowl", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_SuperBowl"},
        {handler(self, self.getShowSaleTicket), "SaleTicketNewYear", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_NewYear"},
        {handler(self, self.getShowSaleTicket), "SaleTicketChristmas", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_Christmas"},
        {handler(self, self.getShowSaleTicket), "SaleTicketEaster", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_Easter"},
        {handler(self, self.getShowSaleTicket), "SaleTicketJuly4th", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_July4th"},
        {handler(self, self.getShowSaleTicket), "SaleTicketHalloween", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_Halloween"},
        {handler(self, self.getShowSaleTicket), "SaleTicketAlbumEnd", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_AlbumEnd"},
        {handler(self, self.getShowSaleTicket), "SaleTicket2Years", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_2Years"},
        {handler(self, self.getShowSaleTicket), "SaleTicketLabor", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_Labor"},
        {handler(self, self.getShowSaleTicket), "SaleTicketChristmas2021", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket_Christmas2021"},
        {handler(self, self.getShowSaleTicket), "SaleTicket", handler(self, self.updateSaleTicketInfo), "Activity_SaleTicket"},
        {handler(self, self.getShowSaleGroup), "SaleGroupMothersDay"},
        -- 商城节日折扣
        {handler(self, self.getShowCoupon), "LunarNewYear", handler(self, self.updateCouponInfo), "Activity_Coupon_LunarNewYear"},
        {handler(self, self.getShowCoupon), "CouponAdTruck", handler(self, self.updateCouponInfo), "Activity_Coupon_AdTruck"},
        {handler(self, self.getShowCoupon), "NewYear2022", handler(self, self.updateCouponInfo), "Activity_Coupon_NewYear2022"},
        {handler(self, self.getShowCoupon), "ThanksGiving", handler(self, self.updateCouponInfo), "Activity_Coupon_ThanksGiving"},
        {handler(self, self.getShowCoupon), "CouponColumbus", handler(self, self.updateCouponInfo), "Activity_Coupon_Columbus"},
        {handler(self, self.getShowCoupon), "CouponVJDay", handler(self, self.updateCouponInfo), "Activity_Coupon_VJDay"},
        {handler(self, self.getShowCoupon), "CouponCoinCrush", handler(self, self.updateCouponInfo), "Activity_Coupon_CoinCrush"},
        {handler(self, self.getShowCoupon), "CouponCincodemayo", handler(self, self.updateCouponInfo), "Activity_Coupon_Cincodemayo"},
        {handler(self, self.getShowCoupon), "CouponJuly4th", handler(self, self.updateCouponInfo), "Activity_Coupon_July4th"},
        {handler(self, self.getShowCoupon), "CouponAlbumEnd", handler(self, self.updateCouponInfo), "Activity_Coupon_AlbumEnd"},
        {handler(self, self.getShowCoupon), "CouponAlbumEnd2", handler(self, self.updateCouponInfo), "Activity_Coupon_AlbumEnd2"},
        {handler(self, self.getShowCoupon), "Coupon2Years", handler(self, self.updateCouponInfo), "Activity_Coupon_2Years"},
        {handler(self, self.getShowCoupon), "CouponAlbumNew", handler(self, self.updateCouponInfo), "Activity_Coupon_AlbumNew"},
        {handler(self, self.getShowCoupon), "ChristmasCoupon", handler(self, self.updateCouponInfo), "Activity_Coupon_Christmas"},
        {handler(self, self.getShowCoupon), "BlackFridayCoupon", handler(self, self.updateCouponInfo), "Activity_Coupon_BlackFriday"},
        {handler(self, self.getShowCoupon), "VeteransDay", handler(self, self.updateCouponInfo), "Activity_Coupon_VeteransDay"},
        {handler(self, self.getShowCoupon), "HallowCoupon", handler(self, self.updateCouponInfo), "Activity_Coupon_Halloween"},
        {handler(self, self.getShowCoupon), "CouponEaster", handler(self, self.updateCouponInfo), "Activity_Coupon_Easter"},
        {handler(self, self.getShowCoupon), "CouponFool", handler(self, self.updateCouponInfo), "Activity_Coupon_Fool"},
        {handler(self, self.getShowCoupon), "CouponFathersDay", handler(self, self.updateCouponInfo), "Activity_Coupon_FathersDay"},
        {handler(self, self.getShowCoupon), "CouponEx", handler(self, self.updateCouponInfo), "Activity_Coupon_Fuelup"},
        {handler(self, self.getShowCoupon), "CouponMemorialDay", handler(self, self.updateCouponInfo), "Activity_Coupon_MemorialDay"},
        {handler(self, self.getShowCoupon), "CouponJulyXmas", handler(self, self.updateCouponInfo), "Activity_Coupon_JulyXmas"},
        {handler(self, self.getShowCoupon), "CouponLabor", handler(self, self.updateCouponInfo), "Activity_Coupon_Labor"},
        {handler(self, self.getShowCoupon), "VeteransDay21", handler(self, self.updateCouponInfo), "Activity_Coupon_VeteransDay21"},
        {handler(self, self.getShowCoupon), "BoxingDay21", handler(self, self.updateCouponInfo), "Activity_Coupon_BoxingDay2021"},
        {handler(self, self.getShowCoupon), "XmasCoupon", handler(self, self.updateCouponInfo), "Activity_Coupon_Xmas"},
        {handler(self, self.getShowCoupon), "CouponAustraliaDay", handler(self, self.updateCouponInfo), "Activity_Coupon_AustraliaDay"},
        {handler(self, self.getShowCoupon), "CouponEx", handler(self, self.updateCouponInfo), "Activity_Coupon"},
        {handler(self, self.getShowCashBack), "CashBack"},
        {handler(self, self.getShowLuckySpinSale), "LuckSpinSale", handler(self, self.updateLuckySpinSaleInfo), "Activity_LuckySpinSale"},
        {handler(self, self.getShowCardStar), "CardStar"},
        {handler(self, self.getShowDoubelCard), "DoubleCard"},
        {handler(self, self.getShowLuckySpinCard), "LuckSpinCard"},
        {handler(self, self.getShowStatueBuff), "CardStatueBuff", handler(self, self.updateCardStatueBuff)},
        {handler(self, self.getShowNormalTitle), "NormalTitle"}
    }
end

function ZQCoinStoreTitle:getFirstBuyType()
    return not globalData.shopRunData:isShopFirstBuyed()
end

function ZQCoinStoreTitle:getShowStatueBuff()
    -- if not globalDynamicDLControl:checkDownloaded("CardsShopTitle") then
    --     return false
    -- end
    if CardSysManager and CardSysManager.getBuffDataByType then
        local chipBuff = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_COINSHOP_CARD_PACKAGE_BONUS)
        local starupBuff = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_COINSHOP_CARD_STAR_BONUS)
        if chipBuff > 0 or starupBuff > 0 then
            return true
        end
    end
    return false
end

function ZQCoinStoreTitle:updateCardStatueBuff(_actNode)
    if CardSysManager and CardSysManager.getBuffDataByType then
        local chipBuff = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_COINSHOP_CARD_PACKAGE_BONUS)
        local starupBuff = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_COINSHOP_CARD_STAR_BONUS)
        local spChip = _actNode:findChild("sp_chips")
        local fntChip = _actNode:findChild("fnt_chips")
        local spStarupChip = _actNode:findChild("sp_starupChips")
        local fntStarupChip = _actNode:findChild("fnt_starupChips")

        spChip:setVisible(false)
        fntChip:setVisible(false)
        spStarupChip:setVisible(false)
        fntStarupChip:setVisible(false)
        if chipBuff > 0 and starupBuff > 0 then
            spStarupChip:setVisible(true)
            fntStarupChip:setVisible(true)
            fntStarupChip:setString("X" .. chipBuff)
        elseif starupBuff > 0 then
            spStarupChip:setVisible(true)
            fntStarupChip:setVisible(true)
            fntStarupChip:setString("X" .. chipBuff)
        elseif chipBuff > 0 then
            spChip:setVisible(true)
            fntChip:setVisible(true)
            fntChip:setString("X" .. chipBuff)
        end
    end
end

function ZQCoinStoreTitle:getShowMulLuckyStamp()
    -- local data = G_GetActivityDataByRef(ACTIVITY_REF.MulLuckyStamp)
    local data = G_GetMgr(ACTIVITY_REF.MulLuckyStamp):getRunningData()
    if data and data.isRunning and data:isRunning() then
        return true
    end
    return false
end

function ZQCoinStoreTitle:getShowRandomCard()
    -- local data = G_GetActivityDataByRef(ACTIVITY_REF.LuckySpinRandomCard)
    local data = G_GetMgr(ACTIVITY_REF.LuckySpinRandomCard):getRunningData()
    if data and data.isRunning and data:isRunning() then
        return true
    end
    return false
end

function ZQCoinStoreTitle:getShowLuckyStampExtraCard()
    -- local data = G_GetActivityDataByRef(ACTIVITY_REF.LuckyStampCard)
    local data = G_GetMgr(ACTIVITY_REF.LuckyStampCard):getRunningData()
    if data and data.isRunning and data:isRunning() then
        return true
    end
    return false
end

function ZQCoinStoreTitle:createCardInfo(cardData)
    local chipUnit = util_createView("GameModule.Card.season201903.MiniChipUnit")
    chipUnit:playIdle()
    chipUnit:reloadUI(cardData, true, true)
    chipUnit:updateTagNew(cardData.count == 0) -- 特殊显示逻辑，当玩家没有这张卡的时候显示new，告诉玩家送给玩家的是新卡
    return chipUnit
end

function ZQCoinStoreTitle:updateLuckyStampExtraCardInfo(_actNode)
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

function ZQCoinStoreTitle:updateRandomCardInfo(_actNode)
    local cardNode = _actNode:findChild("node_cards")
    if cardNode then
        -- local data = G_GetActivityDataByRef(ACTIVITY_REF.LuckySpinRandomCard)
        local data = G_GetMgr(ACTIVITY_REF.LuckySpinRandomCard):getRunningData()
        if data then
            local cardList = {}
            for i = 1, 3 do
                local cardUI = util_createFindView("Activity/LuckySpinRandomCard/LuckySpinRandomCardNode", i)
                if cardUI then
                    cardUI:setScale(0.55)
                    cardNode:addChild(cardUI)
                    local info = {}
                    info.node = cardUI
                    info.size = cc.size(200, 200)
                    info.anchor = cc.p(0.5, 0.5)
                    info.scale = 0.55
                    table.insert(cardList, info)
                end
            end
            if #cardList > 0 then
                util_alignCenter(cardList)
            end
        end
    end
end

function ZQCoinStoreTitle:getShowAppointCard()
    return globalData.luckySpinAppointCardData:isExist() == true and self.m_luckySpinLevel <= #self.m_shopDats
end

function ZQCoinStoreTitle:getShowGoldenCard()
    -- local luckySpinGoldenCardData = G_GetActivityDataByRef(ACTIVITY_REF.LuckySpinGoldenCard)
    local luckySpinGoldenCardData = G_GetMgr(ACTIVITY_REF.LuckySpinGoldenCard):getRunningData()
    if not luckySpinGoldenCardData then
        return false
    end
    return luckySpinGoldenCardData:isExist() == true and self.m_luckySpinLevel <= #self.m_shopDats
end

function ZQCoinStoreTitle:getShowCashBack()
    local config = G_GetMgr(ACTIVITY_REF.CashBack):getRunningData()
    if not config then
        return false
    end
    return config:getOpenFlag() and config:getExpire() > 0
end

function ZQCoinStoreTitle:getShowLuckySpinSale()
    return globalData.luckySpinSaleData:isExist() == true and self.m_luckySpinLevel <= #self.m_shopDats
end

function ZQCoinStoreTitle:getShowCardStar()
    local cardStarData = G_GetActivityDataByRef(ACTIVITY_REF.CardStar)
    if not cardStarData then
        return false
    end

    return cardStarData and cardStarData.isExist and cardStarData:isExist() == true
end

function ZQCoinStoreTitle:getShowDoubelCard()
    local doubleCardData = G_GetActivityDataByRef(ACTIVITY_REF.DoubleCard)
    if not doubleCardData then
        return false
    end
    return doubleCardData and doubleCardData.isExist and doubleCardData:isExist() == true
end

function ZQCoinStoreTitle:getShowLuckySpinCard()
    return globalData.luckySpinCardData:isExist() == true and self.m_luckySpinLevel <= #self.m_shopDats
end

function ZQCoinStoreTitle:getShowCoupon(refName)
    if not refName then
        return false
    end

    local couponData = G_GetActivityDataByRef(ACTIVITY_REF.Coupon)
    if couponData and couponData.isRunning and couponData:isRunning() then
        if couponData:getThemeName() == refName then
            return couponData:getMaxDiscount() > 0
        end
    end
    return false
end

function ZQCoinStoreTitle:getShowShopSale(refName)
    local data = G_GetActivityDataByRef(ACTIVITY_REF.CyberMonday)
    if data and data.isRunning and data:isRunning() and data:getThemeName() == refName then
        return true
    end
    return false
end

function ZQCoinStoreTitle:getShowSaleTicket(refName)
    local saleTicketData = G_GetMgr(ACTIVITY_REF.SaleTicket):getRunningData()
    if saleTicketData and saleTicketData.isRunning and saleTicketData:isRunning() and saleTicketData:getThemeName() == refName then
        return true
    end
    return false
end

function ZQCoinStoreTitle:getShowNormalTitle()
    return true
end

function ZQCoinStoreTitle:updateCouponInfo(actNode)
    local couponData = G_GetActivityDataByRef(ACTIVITY_REF.Coupon)
    if couponData and couponData.isRunning and couponData:isRunning() then
        local lbCoin = actNode:findChild("lb_coin")
        if lbCoin then
            lbCoin:setString(couponData:getMaxDiscount() .. "%")
        end
    end
end

function ZQCoinStoreTitle:updateShopSaleInfo(actNode)
end

function ZQCoinStoreTitle:updateSaleTicketInfo(actNode)
    local saleTicketData = G_GetMgr(ACTIVITY_REF.SaleTicket):getRunningData()
    if saleTicketData and saleTicketData:isRunning() then
    -- local sale = saleTicketData.p_activityTickets[#saleTicketData.p_activityTickets].p_num
    -- actNode:findChild("label"):setString(sale)
    end
end

function ZQCoinStoreTitle:updateLuckySpinSaleInfo(actNode)
    local mulVaule = globalData.luckySpinSaleData:getThreeSameMulValue() or 0
    local lbRaiseMul = actNode:findChild("BitmapFontLabel_1")
    if tolua.isnull(lbRaiseMul) or mulVaule <= 0 then
        return
    end
    lbRaiseMul:setString("X" .. mulVaule)
end
-- 商城缺卡
function ZQCoinStoreTitle:getShowShopRandomCard()
    return G_GetMgr(ACTIVITY_REF.StoreSaleRandomCard):getShopRandomCardIsOpen()
end

function ZQCoinStoreTitle:updateShopRandomCardInfo(_actNode)
    local labelDiscount = _actNode:findChild("lb_discount")
    local maxDiscount = G_GetMgr(ACTIVITY_REF.StoreSaleRandomCard):getShopRandomCardMaxDiscount()
    labelDiscount:setString(maxDiscount .. "%")

    self.m_nodeChipsTable = {}
    for i = 1, 6 do
        local node = _actNode:findChild("node_chip_" .. i)
        table.insert(self.m_nodeChipsTable, node)
    end
    --创建card
    local cardInfoList = G_GetMgr(ACTIVITY_REF.StoreSaleRandomCard):getShopRandomCardInfoList()
    if cardInfoList then
        for i = 1, #cardInfoList do
            local position = cardInfoList[i].position
            local cardResult = cardInfoList[i].cardResult
            -- 用卡牌信息创建卡牌chip
            local chip = util_createView("GameModule.Card.season201903.MiniChipUnit")
            chip:playIdle()
            chip:reloadUI(cardResult, true, true)
            chip:setScale(0.25)
            if globalData.slotRunData.isPortrait == true then
                chip:setScale(0.18)
            end
            chip:updateTagNew(cardResult.newCard == true)
            chip:setTag(position)
            -- 添加
            self.m_nodeChipsTable[position]:addChild(chip)
        end
    end
end

function ZQCoinStoreTitle:getShowSaleGroup()
    local data = G_GetActivityDataByRef(ACTIVITY_REF.SaleGroupMothersDay)
    if data and data.isRunning and data:isRunning() then
        return true
    end
    return false
end
return ZQCoinStoreTitle
