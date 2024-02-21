---
--xcyy
--2018年5月23日
--AquaQuestFreespinBarView.lua
local PublicConfig = require "AquaQuestPublicConfig"
local AquaQuestFreespinBarView = class("AquaQuestFreespinBarView", util_require("base.BaseView"))

AquaQuestFreespinBarView.m_freespinCurrtTimes = 0

function AquaQuestFreespinBarView:initUI()
    self:createCsbNode("AquaQuest_freebar.csb")
end

function AquaQuestFreespinBarView:onEnter()
    AquaQuestFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function AquaQuestFreespinBarView:onExit()
    AquaQuestFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function AquaQuestFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount --globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function AquaQuestFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num1"):setString(curtimes)
    self:findChild("m_lb_num2"):setString(totaltimes)

    local label1 = self:findChild("m_lb_num1")
    local info1 = {label = label1, sx = 0.85, sy = 0.85}
    self:updateLabelSize(info1, 50) 

    local label2 = self:findChild("m_lb_num2")
    local info2 = {label = label2, sx = 0.85, sy = 0.85}
    self:updateLabelSize(info2, 50)

    
end

--[[
    增加次数动效
]]
function AquaQuestFreespinBarView:addFreeCountAni()
    self:runCsbAction("actionframe")
end

return AquaQuestFreespinBarView
