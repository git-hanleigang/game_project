---
--xcyy
--2018年5月23日
--PudgyPandaFreespinBarView.lua
local PublicConfig = require "PudgyPandaPublicConfig"
local PudgyPandaFreespinBarView = class("PudgyPandaFreespinBarView", util_require("base.BaseView"))

function PudgyPandaFreespinBarView:initUI()
    self:createCsbNode("PudgyPanda_spinbar.csb")
    self:runCsbAction("idle", true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function PudgyPandaFreespinBarView:onEnter()
    PudgyPandaFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(self, function(params) -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end, ViewEventType.SHOW_FREE_SPIN_NUM)
end

function PudgyPandaFreespinBarView:onExit()
    PudgyPandaFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

--free相关
function PudgyPandaFreespinBarView:setFreeAni(_isFreeMore)
    self.m_isFreeMore = _isFreeMore
end

---
-- 更新freespin 剩余次数
--
function PudgyPandaFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function PudgyPandaFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    local delayTime = 0
    if self.m_isFreeMore then
        delayTime = 7/60
        self.m_isFreeMore = false
        self:runCsbAction("actionframe", false, function()
            self:runCsbAction("idle", true)
        end)
    end

    performWithDelay(self.m_scWaitNode, function()
        self:findChild("m_lb_num1"):setString(curtimes)
        self:findChild("m_lb_num2"):setString(totaltimes)
    end, delayTime)
end

-- 触发轮盘那次用轮盘次数
function PudgyPandaFreespinBarView:refreshWheelSpinCount(totaltimes)
    local delayTime = 7/60
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idle", true)
    end)
    performWithDelay(self.m_scWaitNode, function()
        self:findChild("m_lb_num2"):setString(totaltimes)
    end, delayTime)
end

return PudgyPandaFreespinBarView
