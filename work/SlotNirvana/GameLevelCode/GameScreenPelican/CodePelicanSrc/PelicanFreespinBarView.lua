---
--xcyy
--2018年5月23日
--PelicanFreespinBarView.lua

local PelicanFreespinBarView = class("PelicanFreespinBarView",util_require("Levels.BaseLevelDialog"))

PelicanFreespinBarView.m_freespinCurrtTimes = 0


function PelicanFreespinBarView:initUI()

    self:createCsbNode("Pelican_freespin_bar.csb")


end


function PelicanFreespinBarView:onEnter()

    PelicanFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function PelicanFreespinBarView:onExit()

    PelicanFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function PelicanFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function PelicanFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("lbs_curNum"):setString(curtimes)
    self:findChild("lbs_sumNum"):setString(totaltimes)
    
end


return PelicanFreespinBarView