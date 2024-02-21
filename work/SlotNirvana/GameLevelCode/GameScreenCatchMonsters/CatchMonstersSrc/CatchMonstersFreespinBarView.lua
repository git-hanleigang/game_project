---
--xcyy
--2018年5月23日
--CatchMonstersFreespinBarView.lua
local PublicConfig = require "CatchMonstersPublicConfig"
local CatchMonstersFreespinBarView = class("CatchMonstersFreespinBarView", util_require("base.BaseView"))

CatchMonstersFreespinBarView.m_freespinCurrtTimes = 0

function CatchMonstersFreespinBarView:initUI()
    self:createCsbNode("CatchMonsters_freebar.csb")
end

function CatchMonstersFreespinBarView:onEnter()
    CatchMonstersFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function CatchMonstersFreespinBarView:onExit()
    CatchMonstersFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function CatchMonstersFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount --globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function CatchMonstersFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end

return CatchMonstersFreespinBarView
