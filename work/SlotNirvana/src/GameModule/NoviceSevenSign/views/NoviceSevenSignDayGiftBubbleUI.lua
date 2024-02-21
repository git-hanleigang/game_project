--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-20 10:28:24
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-20 10:40:06
FilePath: /SlotNirvana/src/GameModule/NoviceSevenSign/views/NoviceSevenSignDayGiftBubbleUI.lua
Description: 新手期 7日签到V2  礼包 气泡
--]]
local NoviceSevenSignDayGiftBubbleUI = class("NoviceSevenSignDayGiftBubbleUI", BaseView)

function NoviceSevenSignDayGiftBubbleUI:initDatas(_day)
    NoviceSevenSignDayGiftBubbleUI.super.initDatas(self)

    self._day = _day
    local _data = G_GetMgr(G_REF.NoviceSevenSign):getRunningData()
    self._dayData = _data:getDayData(_day) 
end

function NoviceSevenSignDayGiftBubbleUI:getCsbName()
    return "DailyBonusNoviceResV2/csd/node_qipao.csb"
end

function NoviceSevenSignDayGiftBubbleUI:initCsbNodes()
    self._spBubble = self:findChild("Image_1")
    self._bubbleSize = self._spBubble:getContentSize()
end

function NoviceSevenSignDayGiftBubbleUI:initUI()
    NoviceSevenSignDayGiftBubbleUI.super.initUI(self)

    -- 礼包 奖励道具
    self:initBubbleUI()

    self:setVisible(false)
end

function NoviceSevenSignDayGiftBubbleUI:initBubbleUI()
    local parent = self:findChild("node_item")
    local itemList = self._dayData:getRewrdItemList()
    parent:removeAllChildren()
    local count = #itemList
    local itemDesignWidth = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
    local itemListNode = gLobalItemManager:addPropNodeList(itemList, ITEM_SIZE_TYPE.TOP, 1, itemDesignWidth)
    parent:addChild(itemListNode)
    
    local spBubble = self:findChild("Image_1")
    spBubble:setContentSize(cc.size(count * itemDesignWidth + 80, self._bubbleSize.height))
end

function NoviceSevenSignDayGiftBubbleUI:switchBubbleVisible()
    if self:isVisible() then
        self:hideTip()
    else
        self:showTip()
    end
end

function NoviceSevenSignDayGiftBubbleUI:showTip()
    if self._bActing then
        return
    end
    self._bActing = true
    
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self._bActing = false
        performWithDelay(self, function()
            self:hideTip()
        end, 2)
    end, 60)
end

function NoviceSevenSignDayGiftBubbleUI:hideTip(_bForce)
    if not _bForce and self._bActing then
        return
    end
    if self._bHide then
        return
    end
    self._bHide = true
    self._bActing = true

    self:stopAllActions()
    self:setVisible(true)
    self:runCsbAction("over", false, function()
        self._bActing = false
        self:setVisible(false)

        self:removeSelf() -- 要求同时只存在一个气泡

    end, 60)
end

function NoviceSevenSignDayGiftBubbleUI:getDay()
    return self._day
end

return NoviceSevenSignDayGiftBubbleUI