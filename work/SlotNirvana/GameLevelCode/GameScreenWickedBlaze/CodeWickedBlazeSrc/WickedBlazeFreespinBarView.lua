

local WickedBlazeFreespinBarView = class("WickedBlazeFreespinBarView",util_require("base.BaseView"))

function WickedBlazeFreespinBarView:initUI()
    self:createCsbNode("WickedBlaze_fscounter.csb")
end

function WickedBlazeFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function WickedBlazeFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function WickedBlazeFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function WickedBlazeFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("m_lb_num"):setString(totaltimes - curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end


return WickedBlazeFreespinBarView