---
--xcyy
--2018年5月23日
--TreasureToadFreespinBarView.lua

local TreasureToadFreespinBarView = class("TreasureToadFreespinBarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "TreasureToadPublicConfig"

TreasureToadFreespinBarView.m_freespinCurrtTimes = 0


function TreasureToadFreespinBarView:initUI()

    self:createCsbNode("TreasureToad_FreeSpinBar.csb")

    self.totaltimes = 0
end


function TreasureToadFreespinBarView:onEnter()

    TreasureToadFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function TreasureToadFreespinBarView:onExit()
    TreasureToadFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function TreasureToadFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function TreasureToadFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    self:updateLabelSize({label=self:findChild("m_lb_num"),sx=1,sy=1}, 46)
    
    if self.totaltimes ~= totaltimes then
        self:runCsbAction("actionframe")
        self:delayCallBack(10/60,function ()
            self:findChild("m_lb_num_0"):setString(totaltimes)
            self:updateLabelSize({label=self:findChild("m_lb_num_0"),sx=1,sy=1}, 46)
            self.totaltimes = totaltimes
        end)
    end
    
    
end

--[[
    延迟回调
]]
function TreasureToadFreespinBarView:delayCallBack(time, func)
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

return TreasureToadFreespinBarView