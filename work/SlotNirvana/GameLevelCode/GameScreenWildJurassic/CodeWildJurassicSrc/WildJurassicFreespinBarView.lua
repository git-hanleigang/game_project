---
--xcyy
--2018年5月23日
--WildJurassicFreespinBarView.lua

local WildJurassicFreespinBarView = class("WildJurassicFreespinBarView",util_require("Levels.BaseLevelDialog"))

WildJurassicFreespinBarView.m_freespinCurrtTimes = 0


function WildJurassicFreespinBarView:initUI()

    self:createCsbNode("WildJurassic_FGbar.csb")
    self.m_barNumNodePosX = self:findChild("m_lb_num"):getPositionX()
end


function WildJurassicFreespinBarView:onEnter()
    WildJurassicFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function WildJurassicFreespinBarView:onExit()
    WildJurassicFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function WildJurassicFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function WildJurassicFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    if curtimes > 99 then
        self:findChild("m_lb_num"):setPositionX(self.m_barNumNodePosX - 14)
    else
        self:findChild("m_lb_num"):setPositionX(self.m_barNumNodePosX)
    end
    
end

--[[
    播放增加free次数的效果
]]
function WildJurassicFreespinBarView:playAddNumsEffect( )
    self:runCsbAction("fankui")
end


return WildJurassicFreespinBarView