---
--xcyy
--2018年5月23日
--Christmas2021FreespinBarView.lua

local Christmas2021FreespinBarView = class("Christmas2021FreespinBarView",util_require("base.BaseView"))

Christmas2021FreespinBarView.m_freespinCurrtTimes = 0


function Christmas2021FreespinBarView:initUI()

    self:createCsbNode("Christmas2021_freeandrespincishu.csb")
    self:findChild("Node_free"):setVisible(true)
    self:findChild("Node_respin"):setVisible(false)

end

function Christmas2021FreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function Christmas2021FreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function Christmas2021FreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function Christmas2021FreespinBarView:updateFreespinCount( leftCount,totaltimes )
    
    self:findChild("m_lb_num_1"):setString(leftCount)
    self:findChild("m_lb_num_2"):setString(totaltimes)
    
end

return Christmas2021FreespinBarView