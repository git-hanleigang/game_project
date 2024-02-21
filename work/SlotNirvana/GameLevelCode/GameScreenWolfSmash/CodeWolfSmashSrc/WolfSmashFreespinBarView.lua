---
--xcyy
--2018年5月23日
--WolfSmashFreespinBarView.lua

local WolfSmashFreespinBarView = class("WolfSmashFreespinBarView",util_require("Levels.BaseLevelDialog"))

WolfSmashFreespinBarView.m_freespinCurrtTimes = 0


function WolfSmashFreespinBarView:initUI()

    self:createCsbNode("WolfSmash_free_bar.csb")


end


function WolfSmashFreespinBarView:onEnter()

    WolfSmashFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        -- self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function WolfSmashFreespinBarView:onExit()

    WolfSmashFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function WolfSmashFreespinBarView:changeFreeSpinByCount()
    
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    -- self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function WolfSmashFreespinBarView:updateFreespinCount( curtimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    
end


return WolfSmashFreespinBarView