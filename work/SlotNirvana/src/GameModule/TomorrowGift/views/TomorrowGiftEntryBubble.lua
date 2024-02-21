--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-11 19:23:06
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-11 19:26:14
FilePath: /SlotNirvana/src/GameModule/TomorrowGift/views/TomorrowGiftEntryBubble.lua
Description: 次日礼物 关卡右边条入口 气泡
--]]
local TomorrowGiftEntryBubble = class("TomorrowGiftEntryBubble", BaseView)

function TomorrowGiftEntryBubble:getCsbName()
    return "Activity/TomorrowGift/csb/Tomorrow_qipao.csb"
end

function TomorrowGiftEntryBubble:initUI()
    TomorrowGiftEntryBubble.super.initUI(self)

    self.m_data = G_GetMgr(G_REF.TomorrowGift):getRunningData()

    self:updateMultipleUI()
    self:setVisible(false)
end

-- 任务奖励倍数
function TomorrowGiftEntryBubble:updateMultipleUI()
    local unlockLevelData = self.m_data:getUnlockLevelData()
    if not unlockLevelData then
        return
    end

    local multiple = math.floor(unlockLevelData:getMultiple() * 100)
    local lbMulti = self:findChild("lb_percent")
    lbMulti:setString("" .. multiple .. "%")
    util_scaleCoinLabGameLayerFromBgWidth(lbMulti, 70, 1)
end

function TomorrowGiftEntryBubble:playShowAct()
    self:updateMultipleUI()

    if self._bActing then
        return
    end
    
    local posW = self:convertToWorldSpace(cc.p(0, 0))
    if posW.x > display.width then
        -- 入口隐藏 不显示气泡
        return
    end
    
    self:setVisible(true)
    self._bActing = true
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle")
        self._bActing = false
        performWithDelay(self,function()
            self:playHideAct()
        end,3)
    end, 60)
end
function TomorrowGiftEntryBubble:playHideAct()
    if self._bActing then
        return
    end
    self._bActing = true
    self:stopAllActions()
    self:runCsbAction("over", false, function()
        self:setVisible(false)
        self._bActing = false
    end, 60)
end

return TomorrowGiftEntryBubble