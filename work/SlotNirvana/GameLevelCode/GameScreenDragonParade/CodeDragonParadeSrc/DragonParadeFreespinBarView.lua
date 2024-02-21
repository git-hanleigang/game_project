---
--xcyy
--2018年5月23日
--DragonParadeFreespinBarView.lua

local DragonParadeFreespinBarView = class("DragonParadeFreespinBarView",util_require("Levels.BaseLevelDialog"))

DragonParadeFreespinBarView.m_freespinCurrtTimes = 0


function DragonParadeFreespinBarView:initUI()

    -- self:createCsbNode("Puss_tishibar2.csb")


end


function DragonParadeFreespinBarView:onEnter()

    DragonParadeFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function DragonParadeFreespinBarView:onExit()

    DragonParadeFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function DragonParadeFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function DragonParadeFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    
end


return DragonParadeFreespinBarView