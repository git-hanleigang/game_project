---
--xcyy
--2018年5月23日
--PomiFreespinBarView.lua

local PomiFreespinBarView = class("PomiFreespinBarView",util_require("base.BaseView"))

PomiFreespinBarView.m_freespinCurrtTimes = 0

function PomiFreespinBarView:initUI()

    self:createCsbNode("Pomi_Freespin_ban.csb")


end


function PomiFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function PomiFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function PomiFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function PomiFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("ml_b_num2"):setString( curtimes)
    self:findChild("ml_b_num1"):setString(totaltimes)
    
end


return PomiFreespinBarView