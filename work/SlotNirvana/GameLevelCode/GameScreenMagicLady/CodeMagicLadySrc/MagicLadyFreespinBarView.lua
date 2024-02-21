---
--xcyy
--2018年5月23日
--MagicLadyFreespinBarView.lua

local MagicLadyFreespinBarView = class("MagicLadyFreespinBarView",util_require("base.BaseView"))

MagicLadyFreespinBarView.m_freespinCurrtTimes = 0


function MagicLadyFreespinBarView:initUI()

    self:createCsbNode("MagicLady_freespin.csb")


end


function MagicLadyFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MagicLadyFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function MagicLadyFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MagicLadyFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(totaltimes - curtimes)
    self:findChild("BitmapFontLabel_1_0"):setString(totaltimes)
end
-- 更新并显示FreeSpin剩余次数  没加新触发前的次数
function MagicLadyFreespinBarView:updateNoAddFreespinCount(curtimes,totaltimes)
    self:findChild("BitmapFontLabel_1"):setString(totaltimes - curtimes)
    self:findChild("BitmapFontLabel_1_0"):setString(totaltimes)
end

return MagicLadyFreespinBarView