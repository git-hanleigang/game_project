---
--xcyy
--2018年5月23日
--ColorfulCircusFreespinBarView.lua

local ColorfulCircusFreespinBarView = class("ColorfulCircusFreespinBarView",util_require("Levels.BaseLevelDialog"))

ColorfulCircusFreespinBarView.m_freespinCurrtTimes = 0


function ColorfulCircusFreespinBarView:initUI()

    self:createCsbNode("ColorfulCircus_free_bar.csb")


end


function ColorfulCircusFreespinBarView:onEnter()

    ColorfulCircusFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function ColorfulCircusFreespinBarView:onExit()

    ColorfulCircusFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function ColorfulCircusFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ColorfulCircusFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num_2"):setString(curtimes)
    self:findChild("m_lb_num_1"):setString(totaltimes)
    
    self:updateLabelSize({label=self:findChild("m_lb_num_2"),sx=0.6,sy=0.6},67)
    self:updateLabelSize({label=self:findChild("m_lb_num_1"),sx=0.6,sy=0.6},67)
end


return ColorfulCircusFreespinBarView