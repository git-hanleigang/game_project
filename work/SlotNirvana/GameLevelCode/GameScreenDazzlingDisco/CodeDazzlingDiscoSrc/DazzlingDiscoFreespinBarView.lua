---
--xcyy
--2018年5月23日
--DazzlingDiscoFreespinBarView.lua

local DazzlingDiscoFreespinBarView = class("DazzlingDiscoFreespinBarView",util_require("Levels.BaseLevelDialog"))

DazzlingDiscoFreespinBarView.m_freespinCurrtTimes = 0


function DazzlingDiscoFreespinBarView:initUI()

    -- self:createCsbNode("Puss_tishibar2.csb")


end


function DazzlingDiscoFreespinBarView:onEnter()

    DazzlingDiscoFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function DazzlingDiscoFreespinBarView:onExit()
    DazzlingDiscoFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function DazzlingDiscoFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function DazzlingDiscoFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    
end


return DazzlingDiscoFreespinBarView