---
--xcyy
--2018年5月23日
--RobinIsHoodFreespinBarView.lua
local PublicConfig = require "RobinIsHoodPublicConfig"
local RobinIsHoodFreespinBarView = class("RobinIsHoodFreespinBarView", util_require("base.BaseView"))

RobinIsHoodFreespinBarView.m_freespinCurrtTimes = 0

function RobinIsHoodFreespinBarView:initUI()
    self:createCsbNode("RobinIsHood_Free_freebar.csb")
end

function RobinIsHoodFreespinBarView:onEnter()
    RobinIsHoodFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function RobinIsHoodFreespinBarView:onExit()
    RobinIsHoodFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function RobinIsHoodFreespinBarView:showUI(isSuper)
    self:setVisible(true)
    self:updateSuperShow(isSuper)
end

function RobinIsHoodFreespinBarView:updateSuperShow(isSuper)
    self:findChild("Node_Free"):setVisible(not isSuper)
    self:findChild("Node_Super_Free"):setVisible(isSuper)
end

---
-- 更新freespin 剩余次数
--
function RobinIsHoodFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount --globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function RobinIsHoodFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num1"):setString(curtimes)
    self:findChild("m_lb_num2"):setString(totaltimes)

    self:findChild("m_lb_num_super_1"):setString(curtimes)
    self:findChild("m_lb_num_super_2"):setString(totaltimes)
end

return RobinIsHoodFreespinBarView
