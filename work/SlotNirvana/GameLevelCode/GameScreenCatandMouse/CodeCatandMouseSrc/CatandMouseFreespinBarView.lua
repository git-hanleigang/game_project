---
--xcyy
--2018年5月23日
--CatandMouseFreespinBarView.lua

local CatandMouseFreespinBarView = class("CatandMouseFreespinBarView",util_require("Levels.BaseLevelDialog"))

CatandMouseFreespinBarView.m_freespinCurrtTimes = 0


function CatandMouseFreespinBarView:initUI()

    self:createCsbNode("CatandMouse_freejishukuang.csb")
    self.m_freespinCurrtTimes = 0

end


function CatandMouseFreespinBarView:onEnter()

    CatandMouseFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function CatandMouseFreespinBarView:onExit()

    CatandMouseFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function CatandMouseFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function CatandMouseFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num1"):setString(curtimes)
    self:findChild("m_lb_num2"):setString(totaltimes)
    
end


return CatandMouseFreespinBarView