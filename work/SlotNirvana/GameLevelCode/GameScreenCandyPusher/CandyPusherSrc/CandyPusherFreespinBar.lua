---
--xcyy
--2018年5月23日
--CandyPusherFreespinBar.lua

local CandyPusherFreespinBar = class("CandyPusherFreespinBar",util_require("base.BaseView"))


function CandyPusherFreespinBar:initUI()

    self:createCsbNode("CandyPusher_FreeSpinBar.csb")

end

function CandyPusherFreespinBar:onEnter()

    CandyPusherFreespinBar.super.onEnter(self)
    
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

---
-- 更新freespin 剩余次数
--
function CandyPusherFreespinBar:changeFreeSpinByCount()
    local leftFsCount =  globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function CandyPusherFreespinBar:updateFreespinCount( curtimes,totalFsCount )
    self:findChild("m_lb_num1"):setString(totalFsCount - curtimes)  
    self:findChild("m_lb_num2"):setString(totalFsCount)
end

function CandyPusherFreespinBar:onExit()
    CandyPusherFreespinBar.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return CandyPusherFreespinBar