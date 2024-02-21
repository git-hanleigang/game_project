---
--xcyy
--2018年5月23日
--DragonsFreespinBarView.lua

local DragonsFreespinBarView = class("DragonsFreespinBarView",util_require("base.BaseView"))

DragonsFreespinBarView.m_freespinCurrtTimes = 0


function DragonsFreespinBarView:initUI()

    self:createCsbNode("Dragons_juanzhou.csb")

    self:runCsbAction("idleframe",true)
end

function DragonsFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function DragonsFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function DragonsFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function DragonsFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    
end


return DragonsFreespinBarView