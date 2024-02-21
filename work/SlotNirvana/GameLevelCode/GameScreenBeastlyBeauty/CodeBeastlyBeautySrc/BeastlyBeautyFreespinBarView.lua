---
--xcyy
--2018年5月23日
--BeastlyBeautyFreespinBarView.lua

local BeastlyBeautyFreespinBarView = class("BeastlyBeautyFreespinBarView",util_require("Levels.BaseLevelDialog"))

BeastlyBeautyFreespinBarView.m_freespinCurrtTimes = 0


function BeastlyBeautyFreespinBarView:initUI()

    self:createCsbNode("BeastlyBeauty_freegameBar.csb")


end


function BeastlyBeautyFreespinBarView:onEnter()
    BeastlyBeautyFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function BeastlyBeautyFreespinBarView:onExit()
    BeastlyBeautyFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function BeastlyBeautyFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function BeastlyBeautyFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num_2"):setString(curtimes)
    self:findChild("m_lb_num_1"):setString(totaltimes)
    
end


return BeastlyBeautyFreespinBarView