---
--xcyy
--2018年5月23日
--PussFreespinBarView.lua

local PussFreespinBarView = class("PussFreespinBarView",util_require("base.BaseView"))

PussFreespinBarView.m_freespinCurrtTimes = 0


function PussFreespinBarView:initUI()

    self:createCsbNode("Puss_tishibar2.csb")


end


function PussFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function PussFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function PussFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function PussFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    
end


return PussFreespinBarView