---
--xcyy
--2018年5月23日
--AladdinFreespinBarView.lua

local AladdinFreespinBarView = class("AladdinFreespinBarView",util_require("base.BaseView"))

AladdinFreespinBarView.m_freespinCurrtTimes = 0


function AladdinFreespinBarView:initUI()

    self:createCsbNode("Aladdin_FS_cishu.csb")


end


function AladdinFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function AladdinFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function AladdinFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function AladdinFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    
end


return AladdinFreespinBarView