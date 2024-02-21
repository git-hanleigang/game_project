---
--xcyy
--2018年5月23日
--HalosandHornsFreespinBarView.lua

local HalosandHornsFreespinBarView = class("HalosandHornsFreespinBarView",util_require("base.BaseView"))

HalosandHornsFreespinBarView.m_freespinCurrtTimes = 0


function HalosandHornsFreespinBarView:initUI()

    -- self:createCsbNode("Socre_HalosandHorns_jcakpot_3.csb")

end


function HalosandHornsFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function HalosandHornsFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function HalosandHornsFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function HalosandHornsFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    
end


return HalosandHornsFreespinBarView