---
--xcyy
--2018年5月23日
--OwlsomeWizardFreespinBarView.lua
local OwlsomeWizardPublicConfig = require "OwlsomeWizardPublicConfig"
local OwlsomeWizardFreespinBarView = class("OwlsomeWizardFreespinBarView", util_require("base.BaseView"))

OwlsomeWizardFreespinBarView.m_freespinCurrtTimes = 0

function OwlsomeWizardFreespinBarView:initUI()
    self:createCsbNode("OwlsomeWizard_free_bar.csb")
end

function OwlsomeWizardFreespinBarView:onEnter()
    OwlsomeWizardFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function OwlsomeWizardFreespinBarView:onExit()
    OwlsomeWizardFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function OwlsomeWizardFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount --globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function OwlsomeWizardFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_2"):setString(curtimes)
    self:findChild("m_lb_num_1"):setString(totaltimes)
end

--[[
    显示动画
]]
function OwlsomeWizardFreespinBarView:showAni()
    self:setVisible(true)
    self:runCsbAction("start")
end

return OwlsomeWizardFreespinBarView
