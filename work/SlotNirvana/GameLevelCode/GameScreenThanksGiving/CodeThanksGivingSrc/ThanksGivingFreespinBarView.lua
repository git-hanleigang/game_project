local ThanksGivingFreespinBarView = class("ThanksGivingFreespinBarView",util_require("base.BaseView"))

function ThanksGivingFreespinBarView:initUI()
    self:createCsbNode("ThanksGiving_tishitiao_1.csb")
end

function ThanksGivingFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function ThanksGivingFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function ThanksGivingFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ThanksGivingFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("m_lb_num_1"):setString(totaltimes - curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end

return ThanksGivingFreespinBarView