---
--xcyy
--2018年5月23日
--AZTECFreespinBarView.lua

local AZTECFreespinBarView = class("AZTECFreespinBarView",util_require("base.BaseView"))

AZTECFreespinBarView.m_freespinCurrtTimes = 0


function AZTECFreespinBarView:initUI()

    -- self:createCsbNode("Puss_tishibar2.csb")


end


function AZTECFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function AZTECFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function AZTECFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function AZTECFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    
end


return AZTECFreespinBarView