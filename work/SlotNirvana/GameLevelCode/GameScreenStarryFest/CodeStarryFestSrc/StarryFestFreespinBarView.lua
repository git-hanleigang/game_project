---
--xcyy
--2018年5月23日
--StarryFestFreespinBarView.lua
local StarryFestPublicConfig = require "StarryFestPublicConfig"
local StarryFestFreespinBarView = class("StarryFestFreespinBarView", util_require("base.BaseView"))

StarryFestFreespinBarView.m_freespinCurrtTimes = 0
StarryFestFreespinBarView.m_isSuper = false

function StarryFestFreespinBarView:initUI()
    self:createCsbNode("StarryFest_freeBar.csb")
end

function StarryFestFreespinBarView:onEnter()
    StarryFestFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function StarryFestFreespinBarView:onExit()
    StarryFestFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function StarryFestFreespinBarView:setFreeState(_isSuper)
    self.m_isSuper = _isSuper
    if _isSuper then
        self:runCsbAction("idle_super", true)
    else
        self:runCsbAction("idle_free", true)
    end
end

---
-- 更新freespin 剩余次数
--
function StarryFestFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function StarryFestFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_free_1"):setString(curtimes)
    self:findChild("m_lb_num_super_1"):setString(curtimes)
    self:findChild("m_lb_num_free_2"):setString(totaltimes)
    self:findChild("m_lb_num_super_2"):setString(totaltimes)
end

return StarryFestFreespinBarView
