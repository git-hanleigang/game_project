---
--xcyy
--2018年5月23日
--BingoPriatesFreespinBarView.lua

local BingoPriatesFreespinBarView = class("BingoPriatesFreespinBarView",util_require("base.BaseView"))

BingoPriatesFreespinBarView.m_freespinCurrtTimes = 0


function BingoPriatesFreespinBarView:initUI()

    -- self:createCsbNode("Puss_tishibar2.csb")


end


function BingoPriatesFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function BingoPriatesFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function BingoPriatesFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function BingoPriatesFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    
end


return BingoPriatesFreespinBarView