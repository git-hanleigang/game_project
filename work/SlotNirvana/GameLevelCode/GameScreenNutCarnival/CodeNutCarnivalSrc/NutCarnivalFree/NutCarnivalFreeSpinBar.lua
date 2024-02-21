--[[
    free计数栏
]]
local NutCarnivalFreeSpinBar = class("NutCarnivalFreeSpinBar",util_require("Levels.BaseLevelDialog"))

function NutCarnivalFreeSpinBar:initUI()
    self.m_curTimes   = 0
    self.m_totalTimes = 0

    self:createCsbNode("NutCarnival_freespin.csb")
end


function NutCarnivalFreeSpinBar:onEnter()
    NutCarnivalFreeSpinBar.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

--
-- 更新freespin 剩余次数
--
function NutCarnivalFreeSpinBar:changeFreeSpinByCount()
    local leftFsCount  = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function NutCarnivalFreeSpinBar:updateFreespinCount(_curTimes, _totalTimes)
    self.m_curTimes   = _curTimes
    self.m_totalTimes = _totalTimes
    local label1 = self:findChild("m_lb_num_1")
    local label2 = self:findChild("m_lb_num_2")
    label1:setString(_curTimes)
    label2:setString(_totalTimes)
    self:updateLabelSize({label=label1, sx=1, sy=1}, 42)
    self:updateLabelSize({label=label2, sx=1, sy=1}, 42)
end

--[[
    时间线
]]
function NutCarnivalFreeSpinBar:playStartAnim()
    self:runCsbAction("chuxian", false)
end

return NutCarnivalFreeSpinBar