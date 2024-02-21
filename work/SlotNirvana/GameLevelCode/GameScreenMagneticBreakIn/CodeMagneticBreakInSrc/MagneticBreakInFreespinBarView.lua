---
--xcyy
--2018年5月23日
--MagneticBreakInFreespinBarView.lua

local MagneticBreakInFreespinBarView = class("MagneticBreakInFreespinBarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MagneticBreakInPublicConfig"

MagneticBreakInFreespinBarView.m_freespinCurrtTimes = 0
MagneticBreakInFreespinBarView.m_freespinTotalTimes = 0

function MagneticBreakInFreespinBarView:initUI()

    self:createCsbNode("MagneticBreakIn_FreeSpinBar.csb")
    self.m_freespinCurrtTimes = 0
    self.m_freespinTotalTimes = 0
end


function MagneticBreakInFreespinBarView:onEnter()

    MagneticBreakInFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MagneticBreakInFreespinBarView:onExit()

    MagneticBreakInFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function MagneticBreakInFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    if totalFsCount ~= self.m_freespinTotalTimes then
        self.m_freespinTotalTimes = totalFsCount
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_free_num_add)
        self:runCsbAction("actionframe")
        self:delayCallBack(5/30,function ()
            self:findChild("m_lb_num1"):setString(totalFsCount)
        end)
    end
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MagneticBreakInFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
end

--[[
    延迟回调
]]
function MagneticBreakInFreespinBarView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return MagneticBreakInFreespinBarView