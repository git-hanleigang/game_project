---
--xcyy
--WickedWinsRespinBarView.lua

local WickedWinsMusicConfig = require "WickedWinsPublicConfig"
local WickedWinsRespinBarView = class("WickedWinsRespinBarView", util_require("base.BaseView"))

WickedWinsRespinBarView.m_respinCurrtTimes = 0

function WickedWinsRespinBarView:initUI()
    self:createCsbNode("WickedWins_RespinLeft.csb")
    self:runCsbAction("idle")
    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function WickedWinsRespinBarView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function()
            -- 显示 freespin count
            self:updateLeftCount(globalData.slotRunData.iReSpinCount, false)
        end,
        ViewEventType.SHOW_RESPIN_SPIN_NUM
    )
end

function WickedWinsRespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function WickedWinsRespinBarView:showRespinBar(curRespin, totalRespin)
    self:updateLeftCount(curRespin, totalRespin)
end

-- 更新 respin 次数
function WickedWinsRespinBarView:updateLeftCount(respinCount, totalRespinCount)
    if self.m_respinCurrtTimes == respinCount then
        return
    end
    self.m_respinCurrtTimes = respinCount
    local isRun = false
    local delayTime = 0
    if respinCount and totalRespinCount and respinCount == totalRespinCount then
        isRun = true
        delayTime = 2/60
    end
    
    local updateCount = function()
        local timesNode = nil
        timesNode = self:findChild("m_lb_num")
        if timesNode then
            timesNode:setString(respinCount)
        end
    end
    if isRun then
        gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_RG_Refresh_Count)
        self:runCsbAction("actionframe")
    end
    performWithDelay(self.m_scWaitNode, function()
        updateCount()
    end, delayTime)
end

return WickedWinsRespinBarView
