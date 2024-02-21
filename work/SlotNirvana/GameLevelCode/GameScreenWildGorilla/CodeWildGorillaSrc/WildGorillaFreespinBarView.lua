---
--xcyy
--2018年5月23日
--WildGorillaFreespinBarView.lua
-- FIX IOS 139
local WildGorillaFreespinBarView = class("WildGorillaFreespinBarView", util_require("base.BaseView"))

function WildGorillaFreespinBarView:initUI()
    self:createCsbNode("WildGorilla_tishiban.csb")
end

function WildGorillaFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function WildGorillaFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function WildGorillaFreespinBarView:changeFreeSpinByCount()
    local leftFsCount =  globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function WildGorillaFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_0"):setString(curtimes)
    self:findChild("m_lb_num_1"):setString(totaltimes)
end

return WildGorillaFreespinBarView
