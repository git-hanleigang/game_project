---
--xcyy
--2018年5月23日
--SpacePupRespinBarView.lua

local PublicConfig = require "SpacePupPublicConfig"
local SpacePupRespinBarView = class("SpacePupRespinBarView",util_require("Levels.BaseLevelDialog"))

function SpacePupRespinBarView:initUI(machine, index)

    self:createCsbNode("SpacePup_respinbar.csb")

    self.m_machine = machine
    self.m_index = index

    self.m_changeAni = util_createAnimation("SpacePup_respinbar_qehuan.csb")
    self:addChild(self.m_changeAni)
    self.m_changeAni:setVisible(false)

    self:resetBarData()
    
    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function SpacePupRespinBarView:onEnter()
    SpacePupRespinBarView.super.onEnter(self)
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function()
    --         -- 显示 freespin count
    --         self:updateLeftCount(globalData.slotRunData.iReSpinCount, false)
    --     end,
    --     ViewEventType.SHOW_RESPIN_SPIN_NUM
    -- )
end

function SpacePupRespinBarView:onExit()
    SpacePupRespinBarView.super.onExit(self)
    -- gLobalNoticManager:removeAllObservers(self)
end

function SpacePupRespinBarView:resetBarData()
    self.m_respinLastTimes = 0
    self.m_isBlack = false
    self.m_isWin = false
    self.m_changeAni:setVisible(false)
end

function SpacePupRespinBarView:unlockReward(isInit)
    if self.m_isWin then
        return
    end
    self.m_isWin = true
    if isInit then
        self:findChild("Node_over1"):setVisible(false)
        self:findChild("Node_start1"):setVisible(false)
        self:findChild("Node_over2"):setVisible(true)
        self:runCsbAction("idleframe1", true)
        self.m_machine:setTopJackpotAct(self.m_index, true)
    else
        self.m_changeAni:setVisible(true)
        self.m_changeAni:runCsbAction("switch", false)
        performWithDelay(self.m_scWaitNode, function()
            self:findChild("Node_over1"):setVisible(false)
            self:findChild("Node_start1"):setVisible(false)
            self:findChild("Node_over2"):setVisible(true)
            self:runCsbAction("idleframe1", true)
            self.m_machine:setTopJackpotAct(self.m_index)
        end, 8/60)
    end
end

--[[
    刷新剩余次数
]]
function SpacePupRespinBarView:refreshTimes(_respinCount, _isInit)
    local respinCount = _respinCount
    local isInit = _isInit
    self:findChild("Node_over1"):setVisible(false)
    self:findChild("Node_over2"):setVisible(false)
    self:findChild("Node_start1"):setVisible(true)

    if isInit then
        local idleName = "idleframe" .. respinCount
        self:runCsbAction(idleName, true)
    else
        if self.m_respinLastTimes == respinCount then
            return
        end
        
        if respinCount == 3 then
            gLobalSoundManager:playSound(PublicConfig.Music_Repin_AddTimes)
            local particle = self:findChild("Particle_1")
            if self.m_respinLastTimes == 0 then
                particle:resetSystem()
                self:runCsbAction("act0_3", false, function()
                    particle:stopSystem()
                    self:runCsbAction("idleframe3", true)
                end)
            elseif self.m_respinLastTimes == 1 then
                particle:resetSystem()
                self:runCsbAction("act1_3", false, function()
                    particle:stopSystem()
                    self:runCsbAction("idleframe3", true)
                end)
            elseif self.m_respinLastTimes == 2 then
                particle:resetSystem()
                self:runCsbAction("act2_3", false, function()
                    particle:stopSystem()
                    self:runCsbAction("idleframe3", true)
                end)
            end
        elseif respinCount == 2 then
            if self.m_respinLastTimes == 0 then
                self:runCsbAction("idleframe2", true)
            elseif self.m_respinLastTimes == 3 then
                self:runCsbAction("act3_2", false, function()
                    self:runCsbAction("idleframe2", true)
                end)
            end
        elseif respinCount == 1 then
            if self.m_respinLastTimes == 0 then
                self:runCsbAction("idleframe1", true)
            elseif self.m_respinLastTimes == 2 then
                self:runCsbAction("act2_1", false, function()
                    self:runCsbAction("idleframe1", true)
                end)
            end
        elseif respinCount == 0 then
            if self.m_respinLastTimes == 0 then
                self:runCsbAction("idleframe1", true)
            elseif self.m_respinLastTimes == 1 then
                self:runCsbAction("act1_0", false, function()
                    self:runCsbAction("idleframe0", true)
                end)
            end
        else
            local test = 0
        end
        self.m_respinLastTimes = respinCount
    end
end

function SpacePupRespinBarView:turnToBlack(isInit)
    if self.m_isBlack then
        return
    end
    self.m_isBlack = true
    if isInit then
        self:findChild("Node_over1"):setVisible(true)
        self:findChild("Node_start1"):setVisible(false)
        self:findChild("Node_over2"):setVisible(false)
        self:runCsbAction("idleframe1", true)
    else
        self:findChild("Node_over1"):setVisible(true)
        self:findChild("Node_start1"):setVisible(true)
        self:findChild("Node_over2"):setVisible(false)
        self:runCsbAction("switch", false, function()
            self:findChild("Node_over1"):setVisible(true)
            self:findChild("Node_start1"):setVisible(false)
            self:findChild("Node_over2"):setVisible(false)
            self:runCsbAction("idleframe1", true)
        end)
    end
end
    
return SpacePupRespinBarView
