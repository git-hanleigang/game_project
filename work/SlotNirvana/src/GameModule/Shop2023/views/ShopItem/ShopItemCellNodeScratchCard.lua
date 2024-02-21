--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-08-14 12:16:37
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-08-14 12:16:47
FilePath: /SlotNirvana/src/GameModule/Shop2023/views/ShopItem/ShopItemCellNodeScratchCard.lua
Description: 刮刮卡入口
--]]
local ShopBaseItemCellNode = util_require(SHOP_CODE_PATH.ShopBaseItemCellNode)
local ShopItemCellNodeScratchCard = class("ShopItemCellNodeScratchCard", ShopBaseItemCellNode)

function ShopItemCellNodeScratchCard:getCsbName()
    if self.m_isPortrait == true then
        return SHOP_RES_PATH.ItemCell_ScratchCard_Vertical
    else
        return SHOP_RES_PATH.ItemCell_ScratchCard
    end
end

function ShopItemCellNodeScratchCard:initCsbNodes()
    self.m_lbTime = self:findChild("lb_time")
    self.m_panelSize = self:findChild("layout_touch")
end

function ShopItemCellNodeScratchCard:initSpineUI()
    ShopItemCellNodeScratchCard.super.initSpineUI(self)

    local nodeSpine = self:findChild("node_spine")
    local spine = util_spineCreate(SHOP_RES_PATH.ItemCell_ScratchCard_Spine, true, true, 1)
    nodeSpine:addChild(spine)
    util_spinePlay(spine, self.m_isPortrait and "idle_vertical" or "idle", true)
end

function ShopItemCellNodeScratchCard:onEnter()
    ShopItemCellNodeScratchCard.super.onEnter(self)

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.ScratchCards then
                -- 刷新热卖 列表
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOP_HOTSALE_REFRESH)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function ShopItemCellNodeScratchCard:updateView()
    self:updateLeftTimeUI()
    if not self.timerAction then
        self.timerAction = schedule(self, util_node_handler(self, self.updateLeftTimeUI), 1)
    end
    self:setButtonLabelContent("btn_go", "GET IT")
    self:runCsbAction("idle", true)
end

function ShopItemCellNodeScratchCard:updateLeftTimeUI()
    local data = G_GetMgr(ACTIVITY_REF.ScratchCards):getRunningData()
    if data then
        local strLeftTime, isOver = util_daysdemaining(data:getExpireAt(), true)
        self.m_lbTime:setString(strLeftTime)
        if isOver then
            self:stopTimerAction()
        end
        return
    end

    self:stopTimerAction()
end
function ShopItemCellNodeScratchCard:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function ShopItemCellNodeScratchCard:clickFunc(_sender)
    local name = _sender:getName()
    if G_GetMgr(G_REF.Shop):getShopClosedFlag() then
        return
    end
    if name == "btn_go" then
        G_GetMgr(ACTIVITY_REF.ScratchCards):showMainLayer({source = "shop"})
    end
end

function ShopItemCellNodeScratchCard:refreshUiData(_index, _itemData)
end

function ShopItemCellNodeScratchCard:doWitchLogic(params)
    
end
-- 子类重写
function ShopItemCellNodeScratchCard:getShowLuckySpinView()
    return false
end

function ShopItemCellNodeScratchCard:initExtra(switchKey)
end

function ShopItemCellNodeScratchCard:initTicket()
end

return ShopItemCellNodeScratchCard
