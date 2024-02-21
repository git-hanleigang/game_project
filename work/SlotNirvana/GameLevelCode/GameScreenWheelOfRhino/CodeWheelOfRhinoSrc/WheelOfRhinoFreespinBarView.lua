
local WheelOfRhinoFreespinBarView = class("WheelOfRhinoFreespinBarView",util_require("base.BaseView"))

WheelOfRhinoFreespinBarView.m_freespinCurrtTimes = 0


function WheelOfRhinoFreespinBarView:initUI()
    self:createCsbNode("WheelOfRhino_freespin_tishi.csb")
end


function WheelOfRhinoFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function WheelOfRhinoFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function WheelOfRhinoFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function WheelOfRhinoFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("BitmapFontLabel_1"):setString(totaltimes - curtimes)
    self:findChild("BitmapFontLabel_1_0"):setString(totaltimes)
end


return WheelOfRhinoFreespinBarView