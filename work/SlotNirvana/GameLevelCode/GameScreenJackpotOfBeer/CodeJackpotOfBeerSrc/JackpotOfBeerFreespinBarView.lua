---
--xcyy
--2018年5月23日
--JackpotOfBeerFreespinBarView.lua

local JackpotOfBeerFreespinBarView = class("JackpotOfBeerFreespinBarView",util_require("Levels.BaseLevelDialog"))

JackpotOfBeerFreespinBarView.m_freespinCurrtTimes = 0


function JackpotOfBeerFreespinBarView:initUI()

    self:createCsbNode("JackpotOfBeer_freebar.csb")


end


function JackpotOfBeerFreespinBarView:onEnter()

    JackpotOfBeerFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function JackpotOfBeerFreespinBarView:onExit()
    JackpotOfBeerFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function JackpotOfBeerFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function JackpotOfBeerFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self.m_csbOwner["m_lb_num"]:setString(totaltimes - curtimes)
    self.m_csbOwner["m_lb_num_0"]:setString(totaltimes)
    
end


return JackpotOfBeerFreespinBarView