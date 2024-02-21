---
--xcyy
--2018年5月23日
--FishManiaFreespinBarView.lua

local FishManiaFreespinBarView = class("FishManiaFreespinBarView",util_require("base.BaseView"))

FishManiaFreespinBarView.m_freespinCurrtTimes = 0

function FishManiaFreespinBarView:initUI(_data)
    local ccbName = _data[1]
    self:createCsbNode(ccbName)
end 


function FishManiaFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

    FishManiaFreespinBarView.super.onEnter(self)
end

function FishManiaFreespinBarView:onExit()
    FishManiaFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function FishManiaFreespinBarView:changeFreeSpinByCount()
    local leftFsCount =  globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function FishManiaFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end

return FishManiaFreespinBarView