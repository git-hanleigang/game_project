--[[
Author: cxc
Date: 2021-03-09 19:53:25
LastEditTime: 2021-07-26 14:51:55
LastEditors: Please set LastEditors
Description: 点击宝箱弹出的气泡
FilePath: /SlotNirvana/src/views/clan/baseInfo/ClanBoxRewardBubbleTip.lua
--]]
local ClanBoxRewardBubbleTip = class("ClanBoxRewardBubbleTip", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanBoxRewardBubbleTip:initUI(_rewardInfo)
    local csbName = "Club/csd/Main/ClubBoxRewardBubbleTip.csb"
    self:createCsbNode(csbName)

    self.m_idx = _rewardInfo.level

    local items = clone(_rewardInfo.items or {})

    local coins = tonumber(_rewardInfo.coins) or 0
    if coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(coins, 3))
        table.insert(items, 1, itemData)
    end

    local nodeItems = self:findChild("node_rewards")
    local sourceW = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP) + 8
    local shopItemUI = gLobalItemManager:addPropNodeList(items, ITEM_SIZE_TYPE.TOP, 1, sourceW)
    shopItemUI:addTo(nodeItems)

    self:updateBubbltTipSize(shopItemUI, sourceW)
    self:setVisible(false)
end

function ClanBoxRewardBubbleTip:onEnter()
    gLobalNoticManager:addObserver(self, "hideOtherBubbleEvt", ClanConfig.EVENT_NAME.HIDE_OTHER_BUBBLE_TIP_VIEW)
end

function ClanBoxRewardBubbleTip:switchShowState()
    local visible = self:isVisible()
    if not visible then
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.HIDE_OTHER_BUBBLE_TIP_VIEW, self.m_idx) -- 隐藏其他的 气泡提示
        performWithDelay(self, function(  )
            self:switchShowState()
        end, 3)
    else
        self:stopAllActions() 
    end

    local actName = "idle"
    local cb = nil
    if not visible then
        actName = "start"
        self:setVisible(true)
        cb = function()
            self:runCsbAction("idle", false)
        end
    else
        actName = "over"
        cb= function()
            self:setVisible(false)
        end
    end
    self:runCsbAction(actName, false, cb, 60) 
end

function ClanBoxRewardBubbleTip:updateBubbltTipSize(_refNode, _refNodeW)
    if not _refNode then
        return
    end

    local children = _refNode:getChildren()
    local lastNode = children[#children]

    if not lastNode then
        return
    end

    local lastPosX = lastNode:getPositionX()
    local w = (lastPosX + _refNodeW * 0.5 + 8) * 2 -- 居中模式所以 * 2
    local spBg = self:findChild("sp_bubble1")
    spBg:setContentSize(cc.size(w, _refNodeW + 8))
end

function ClanBoxRewardBubbleTip:hideOtherBubbleEvt(_idx)
    if self.m_idx == _idx then
        return
    end

    self:stopAllActions()
    self:setVisible(false)
end

return ClanBoxRewardBubbleTip
