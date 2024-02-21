---
--xcyy
--2018年5月23日
--FortuneCatsFreespinBarView.lua

local FortuneCatsFreespinBarView = class("FortuneCatsFreespinBarView",util_require("base.BaseView"))
FortuneCatsFreespinBarView.m_freespinCurrtTimes = 0

function FortuneCatsFreespinBarView:initUI()
    self:createCsbNode("FortuneCats_freespin_bar.csb")
end

function FortuneCatsFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function FortuneCatsFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
---
-- 更新freespin 剩余次数
--
function FortuneCatsFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function FortuneCatsFreespinBarView:updateFreespinCount(curtimes,totaltimes)
    local nowTimes = totaltimes - curtimes
    -- self:findChild("m_lb_num"):setString(nowTimes)
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
end

return FortuneCatsFreespinBarView