---
--xcyy
--2018年5月23日
--FloweryPixieFreespinBarView.lua

local FloweryPixieFreespinBarView = class("FloweryPixieFreespinBarView",util_require("base.BaseView"))

FloweryPixieFreespinBarView.m_freespinCurrtTimes = 0


function FloweryPixieFreespinBarView:initUI()

    self:createCsbNode("FloweryPixie_FS_title.csb")


    self:findChild("Node_Lab"):setVisible(false)
    self:findChild("FrogPrince_zi"):setVisible(false)
    
end


function FloweryPixieFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function FloweryPixieFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function FloweryPixieFreespinBarView:changeFreeSpinByCount()
    local leftFsCount =  globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function FloweryPixieFreespinBarView:updateFreespinCount( curtimes,totaltimes )

    self:findChild("Node_Lab"):setVisible(false)
    self:findChild("FrogPrince_zi"):setVisible(false)

    if curtimes == totaltimes then
        self:findChild("FrogPrince_zi"):setVisible(true)
    else
        self:findChild("Node_Lab"):setVisible(true)
    end
    
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num1"):setString(totaltimes)
    
end


return FloweryPixieFreespinBarView