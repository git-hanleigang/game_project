---
--xcyy
--2018年5月23日
--FrogPrinceFreespinBarView.lua

local FrogPrinceFreespinBarView = class("FrogPrinceFreespinBarView",util_require("base.BaseView"))

FrogPrinceFreespinBarView.m_freespinCurrtTimes = 0


function FrogPrinceFreespinBarView:initUI()

    self:createCsbNode("FrogPrince_jushu.csb")


end


function FrogPrinceFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function FrogPrinceFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function FrogPrinceFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function FrogPrinceFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    
end


return FrogPrinceFreespinBarView