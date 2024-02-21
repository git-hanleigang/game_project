---
--xcyy
--2018年5月23日
--WallballFreespinBarView.lua

local WallballFreespinBarView = class("WallballFreespinBarView",util_require("base.BaseView"))

WallballFreespinBarView.m_freespinCurrtTimes = 0


function WallballFreespinBarView:initUI()

    self:createCsbNode("Wallball_Freespin.csb")


end


function WallballFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function WallballFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function WallballFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function WallballFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num1"):setString(totaltimes)
end


return WallballFreespinBarView