
local FlamingPompeiiFreespinBarView = class("FlamingPompeiiFreespinBarView",util_require("Levels.BaseLevelDialog"))

function FlamingPompeiiFreespinBarView:initUI()
    self:createCsbNode("FlamingPompeii_spinTimesBar.csb")
    
    self:findChild("free"):setVisible(true)
end


function FlamingPompeiiFreespinBarView:onEnter()
    FlamingPompeiiFreespinBarView.super.onEnter(self)

    -- 由父类释放
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

---
-- 更新freespin 剩余次数
--
function FlamingPompeiiFreespinBarView:changeFreeSpinByCount()
    local leftFsCount  = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 

    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function FlamingPompeiiFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    local leftLab  = self:findChild("m_lb_freeNum_1")
    local rightLab = self:findChild("m_lb_freeNum_2")

    leftLab:setString(curtimes)
    rightLab:setString(totaltimes)

    self:updateLabelSize({label=leftLab,  sx=0.8, sy=0.8}, 75)
    self:updateLabelSize({label=rightLab, sx=0.8, sy=0.8}, 75)
end

--[[
    出现
    次数增加
    消失
]]
function FlamingPompeiiFreespinBarView:playStartAnim()
    self:runCsbAction("start", false)
end
function FlamingPompeiiFreespinBarView:playAddTimesAnim(_fun)
    self:runCsbAction("animation", false, _fun)
end
function FlamingPompeiiFreespinBarView:playOverAnim(_fun)
    self:runCsbAction("over", false, _fun)
end

return FlamingPompeiiFreespinBarView