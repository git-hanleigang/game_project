---
--xcyy
--2018年5月23日
--VegasFreespinBarView.lua

local VegasFreespinBarView = class("VegasFreespinBarView",util_require("base.BaseView"))

VegasFreespinBarView.m_freespinCurrtTimes = 0


function VegasFreespinBarView:initUI()

    self:createCsbNode("vegas_freegame.csb")

    
    self:findChild("normal_img"):setVisible(true)
    self:findChild("super_img"):setVisible(false)

end


function VegasFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function VegasFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function VegasFreespinBarView:changeFreeSpinByCount()
    local leftFsCount =  globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function VegasFreespinBarView:updateFreespinCount( curtimes,totaltimes )

    local str = curtimes .. " of " .. totaltimes
    self:findChild("BitmapFontLabel_2"):setString(str)
    
end


return VegasFreespinBarView