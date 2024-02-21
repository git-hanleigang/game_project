---
--xcyy
--2018年5月23日
--RollingJackpotFreespinBarView.lua

local RollingJackpotFreespinBarView = class("RollingJackpotFreespinBarView",util_require("Levels.BaseLevelDialog"))

RollingJackpotFreespinBarView.m_freespinCurrtTimes = 0


function RollingJackpotFreespinBarView:initUI()

    -- self:createCsbNode("Puss_tishibar2.csb")


end


function RollingJackpotFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function RollingJackpotFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function RollingJackpotFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function RollingJackpotFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    
end


return RollingJackpotFreespinBarView