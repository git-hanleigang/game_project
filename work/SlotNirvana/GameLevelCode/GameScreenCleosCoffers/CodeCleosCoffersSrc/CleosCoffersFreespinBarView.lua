---
--xcyy
--2018年5月23日
--CleosCoffersFreespinBarView.lua
local PublicConfig = require "CleosCoffersPublicConfig"
local CleosCoffersFreespinBarView = class("CleosCoffersFreespinBarView", util_require("base.BaseView"))

CleosCoffersFreespinBarView.m_freespinCurrtTimes = 0

function CleosCoffersFreespinBarView:initUI()
    self:createCsbNode("CleosCoffers_freebar.csb")
end

function CleosCoffersFreespinBarView:onEnter()
    CleosCoffersFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(self, function(params) -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end, ViewEventType.SHOW_FREE_SPIN_NUM)
end

function CleosCoffersFreespinBarView:onExit()
    CleosCoffersFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function CleosCoffersFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function CleosCoffersFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end

return CleosCoffersFreespinBarView
