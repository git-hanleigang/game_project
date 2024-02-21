---
--xcyy
--2018年5月23日
--MagikMirrorFreespinBarView.lua
local MagikMirrorPublicConfig = require "MagikMirrorPublicConfig"
local MagikMirrorFreespinBarView = class("MagikMirrorFreespinBarView", util_require("base.BaseView"))

MagikMirrorFreespinBarView.m_freespinCurrtTimes = 0

function MagikMirrorFreespinBarView:initUI()
    self:createCsbNode("MagikMirror_fgbar.csb")
end

function MagikMirrorFreespinBarView:onEnter()
    MagikMirrorFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function MagikMirrorFreespinBarView:onExit()
    MagikMirrorFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function MagikMirrorFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount --globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MagikMirrorFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end

function MagikMirrorFreespinBarView:changeFreeImage(isSuper)
    if isSuper then
        self:findChild("MagikMirror_free_zi_1_2"):setVisible(false)
        self:findChild("MagikMirror_superfree_zi_1"):setVisible(true)
    else
        self:findChild("MagikMirror_free_zi_1_2"):setVisible(true)
        self:findChild("MagikMirror_superfree_zi_1"):setVisible(false)
    end
end

return MagikMirrorFreespinBarView
