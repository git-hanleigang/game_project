---
--xcyy
--2018年5月23日
--AtlantisFreespinBarView.lua

local AtlantisFreespinBarView = class("AtlantisFreespinBarView",util_require("base.BaseView"))

AtlantisFreespinBarView.m_freespinCurrtTimes = 0


function AtlantisFreespinBarView:initUI()

    self:createCsbNode("FreeSpins_Atlantis.csb")


end


function AtlantisFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function AtlantisFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function AtlantisFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function AtlantisFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_cur"):setString(curtimes)
    self:findChild("m_lb_total"):setString(totaltimes)
end


return AtlantisFreespinBarView