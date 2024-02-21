--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-31 14:51:47
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-31 15:06:37
FilePath: /SlotNirvana/src/GameModule/IcebreakerSale/views/IcebreakerSaleRewardLayer.lua
Description: 新版 破冰促销 奖励面板
--]]
local ItemRewardLayer = util_require("PBCode2.ItemRewardLayer")
local ShopItem = util_require("data.baseDatas.ShopItem")
local IcebreakerSaleConfig = util_require("GameModule.IcebreakerSale.config.IcebreakerSaleConfig")
local IcebreakerSaleRewardLayer = class("IcebreakerSaleRewardLayer", ItemRewardLayer)

function IcebreakerSaleRewardLayer:initDatas(_result)
    self.m_coins = tonumber(_result.coins) or 0
    self.m_itemList = {}
    self.m_mergePropsBagList = {}

    if self.m_coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(self.m_coins, 6))
        table.insert(self.m_itemList, itemData)
    end
    for k, data in ipairs(_result.items or {}) do
        local shopItemData = ShopItem:create()
        shopItemData:parseData(data)

        -- 合成小游戏掉落弹板
        if string.find(shopItemData.p_icon, "Pouch") then
            table.insert(self.m_mergePropsBagList, shopItemData)
        end

        table.insert(self.m_itemList, shopItemData)
    end

    self:setHideActionEnabled(false)
    self:setName("IcebreakerSaleRewardLayer")
    IcebreakerSaleRewardLayer.super.initDatas(self, self.m_itemList, nil, self.m_coins, true)
end

function IcebreakerSaleRewardLayer:closeUI()
    if self.bClose then
        return
    end
    self.bClose = true

    self:triggerDropCrads()
end

function IcebreakerSaleRewardLayer:closeLayer()
    local saleData = G_GetMgr(G_REF.IcebreakerSale):getData()
    if not saleData or not saleData:isRunning() then
        gLobalNoticManager:postNotification(IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_OVER)
    end

    IcebreakerSaleRewardLayer.super.closeUI(self)
end 

-- 掉卡
function IcebreakerSaleRewardLayer:triggerDropCrads()
    if not CardSysManager:needDropCards("Ice Broken Sale") then
        self:triggerDropMergePropsBag()
        return
    end

    gLobalNoticManager:addObserver(
        self,
        function(sender, func)
            self:triggerDropMergePropsBag()
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
        end,
        ViewEventType.NOTIFY_CARD_SYS_OVER
    )
    CardSysManager:doDropCards("Ice Broken Sale")
end
-- 掉落 合成福袋
function IcebreakerSaleRewardLayer:triggerDropMergePropsBag()
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    mergeManager:popMergePropsBagRewardPanel(self.m_mergePropsBagList, util_node_handler(self, self.closeLayer))
end

return IcebreakerSaleRewardLayer