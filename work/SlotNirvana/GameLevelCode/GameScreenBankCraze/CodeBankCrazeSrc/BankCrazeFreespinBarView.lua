---
--xcyy
--2018年5月23日
--BankCrazeFreespinBarView.lua
local PublicConfig = require "BankCrazePublicConfig"
local BankCrazeFreespinBarView = class("BankCrazeFreespinBarView", util_require("base.BaseView"))

BankCrazeFreespinBarView.m_freespinCurrtTimes = 0

function BankCrazeFreespinBarView:initUI()
    self:createCsbNode("BankCraze_FreeBar.csb")
end

function BankCrazeFreespinBarView:onEnter()
    BankCrazeFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(self, function(params) -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end, ViewEventType.SHOW_FREE_SPIN_NUM)
end

function BankCrazeFreespinBarView:onExit()
    BankCrazeFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function BankCrazeFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function BankCrazeFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num1"):setString(curtimes)
    self:findChild("m_lb_num2"):setString(totaltimes)
end

return BankCrazeFreespinBarView
