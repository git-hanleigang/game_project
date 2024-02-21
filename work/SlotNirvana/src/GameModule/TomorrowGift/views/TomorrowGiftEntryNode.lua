--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-04 15:17:21
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-04 17:18:53
FilePath: /SlotNirvana/src/GameModule/TomorrowGift/views/TomorrowGiftEntryNode.lua
Description: 次日礼物 关卡右边条入口
--]]
local TomorrowGiftEntryNode = class("TomorrowGiftEntryNode", BaseView)
local TomorrowGiftConfig = util_require("GameModule.TomorrowGift.config.TomorrowGiftConfig")

function TomorrowGiftEntryNode:initCsbNodes()
    TomorrowGiftEntryNode.super.initCsbNodes(self)
    
    self.m_lbTime = self:findChild("BitmapFontLabel_1")
    self.m_spTime = self:findChild("sp_time")
    self.m_spTime:setVisible(false)
end

function TomorrowGiftEntryNode:getCsbName()
    return "Activity/TomorrowGift/csb/Node_tomorrowGift.csb"
end

function TomorrowGiftEntryNode:initUI()
    TomorrowGiftEntryNode.super.initUI(self)

    self.m_data = G_GetMgr(G_REF.TomorrowGift):getRunningData()
    self.m_unlockTime = self.m_data:getUnlockTime()

    self._curUnlockLevelData = self.m_data:getUnlockLevelData()

    -- 倒计时
    self.m_bUnlock = self.m_data:checkIsUnlock()
    if not self.m_bUnlock then
        gLobalNoticManager:addObserver(self, "onPlaySpinAddActEvt", TomorrowGiftConfig.EVENT_NAME.NOTICE_PLAY_TOMORROW_GIFT_SPIN_COUNT_ADD_ANI)
        self.m_spTime:setVisible(true)
        self:updateTimeLbUI()
        schedule(self.m_lbTime, util_node_handler(self, self.updateTimeLbUI), 1)

        -- 气泡
        self:initBubbleUI()
    end
    self:initActState()
end

function TomorrowGiftEntryNode:onEnterFinish()
    TomorrowGiftEntryNode.super.onEnterFinish(self)

    gLobalNoticManager:postNotification(TomorrowGiftConfig.EVENT_NAME.NOTICE_SHOW_TOMORROW_GIFT_MACHINE_ENTRY)
end

-- 气泡
function TomorrowGiftEntryNode:initBubbleUI()
    local parent = self:findChild("node_bubble")
    local view = util_createView("GameModule.TomorrowGift.views.TomorrowGiftEntryBubble")
    parent:addChild(view)
    self._bubbleView = view
end

-- 倒计时
function TomorrowGiftEntryNode:updateTimeLbUI()
    local timeStr, bOver = util_daysdemaining(self.m_unlockTime, true)
    if bOver then
        self:unlockGiftBenefit()
        self.m_lbTime:stopAllActions()
        return
    end
    self.m_lbTime:setString(timeStr)
end

function TomorrowGiftEntryNode:initActState()
    local actName = "idle"
    if self.m_bUnlock then
        actName = "start"
    end
    self:runCsbAction(actName, true)
end

function TomorrowGiftEntryNode:unlockGiftBenefit()
    self.m_bUnlock = true
    self.m_spTime:setVisible(false)
    gLobalNoticManager:removeAllObservers(self)
    self:runCsbAction("start", true)
    gLobalNoticManager:postNotification(TomorrowGiftConfig.EVENT_NAME.NOTICE_SHOW_TOMORROW_GIFT_MACHINE_ENTRY)
end

function TomorrowGiftEntryNode:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_entry" then
        G_GetMgr(G_REF.TomorrowGift):showMainLayer()
    end
end

-- 返回右边栏 entry 大小
function TomorrowGiftEntryNode:getRightFrameSize()
    local btnEntry = self:findChild("btn_entry")
    local size = btnEntry:getContentSize()
    return {widht = size.width, height = size.height}
end

-- 每次spin 增加播放spin动画
function TomorrowGiftEntryNode:onPlaySpinAddActEvt()
    if self.m_bUnlock then
        return
    end

    self:runCsbAction("souji")
    
    -- 有新进度 解锁 显示气泡
    local newLevelData = self.m_data:getUnlockLevelData()
    if self._curUnlockLevelData then
        local preLevelIdx = self._curUnlockLevelData:getIdx()
        local curLevelIdx = newLevelData:getIdx()
        if preLevelIdx ~= curLevelIdx and self._bubbleView then
            self._bubbleView:playShowAct()
        end
    end 
    self._curUnlockLevelData = newLevelData
end

return TomorrowGiftEntryNode