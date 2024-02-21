---
--xcyy
--2018年5月23日
--DemonessFairFreespinBarView.lua
local PublicConfig = require "DemonessFairPublicConfig"
local DemonessFairFreespinBarView = class("DemonessFairFreespinBarView", util_require("base.BaseView"))

DemonessFairFreespinBarView.m_freespinCurrtTimes = 0

function DemonessFairFreespinBarView:initUI()
    self:createCsbNode("DemonessFair_FreeBar.csb")

    self:setIdle()

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function DemonessFairFreespinBarView:setIdle()
    self:runCsbAction("idle", true)
end

function DemonessFairFreespinBarView:onEnter()
    DemonessFairFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(self, function(params) -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end, ViewEventType.SHOW_FREE_SPIN_NUM)
end

function DemonessFairFreespinBarView:onExit()
    DemonessFairFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function DemonessFairFreespinBarView:setFreeAni(_isFreeMore)
    self.m_isFreeMore = _isFreeMore
end

---
-- 更新freespin 剩余次数
--
function DemonessFairFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function DemonessFairFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    local delayTime = 0
    if self.m_isFreeMore then
        delayTime = 10/60
        self.m_isFreeMore = false
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_FgTime_Add)
        self:runCsbAction("actionframe", false, function()
            self:setIdle()
        end) 
    end

    performWithDelay(self.m_scWaitNode, function()
        self:findChild("m_lb_num_1"):setString(curtimes)
        self:findChild("m_lb_num_2"):setString(totaltimes)
    end, delayTime)
end

return DemonessFairFreespinBarView
