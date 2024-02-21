---
--xcyy
--2018年5月23日
--ClawStallFreespinBarView.lua

local ClawStallFreespinBarView = class("ClawStallFreespinBarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "ClawStallPublicConfig"
ClawStallFreespinBarView.m_freespinCurrtTimes = 0


function ClawStallFreespinBarView:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("ClawStall_Respin_RespinBar.csb")

    self.m_collectItems = {}
    for index = 1,15 do
        local item = util_createAnimation("ClawStall_Respin_Collections.csb")
        self:findChild("Collection_"..(index - 1)):addChild(item)
        self.m_collectItems[#self.m_collectItems + 1] = item
    end

    util_setCascadeOpacityEnabledRescursion(self,true)
end


function ClawStallFreespinBarView:onEnter()

    ClawStallFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function ClawStallFreespinBarView:onExit()

    ClawStallFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function ClawStallFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ClawStallFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num1"):setString(curtimes)
    self:findChild("m_lb_num1_0"):setString(totaltimes)
end

--[[
    显示freeUI
]]
function ClawStallFreespinBarView:showFreeUI()
    self:findChild("Node_RespinsLeft"):setVisible(false)
    self:findChild("Node_RespinCollectionsTrall"):setVisible(false)
    self:findChild("Node_SuperFreeGames"):setVisible(true)
    self:findChild("Node_LastSpin"):setVisible(false)
end

--[[
    显示respinUI
]]
function ClawStallFreespinBarView:showRespinUI()
    self:findChild("Node_RespinsLeft"):setVisible(true)
    self:findChild("Node_RespinCollectionsTrall"):setVisible(false)
    self:findChild("Node_SuperFreeGames"):setVisible(false)
    self:findChild("Node_LastSpin"):setVisible(false)
    self:pauseForIndex(0)
end

--[[
    更新respin剩余次数
]]
function ClawStallFreespinBarView:updateRespinCount(count,isInit)
    self:findChild("m_lb_num"):setString(count)
    self:findChild("Node_LastSpin"):setVisible(count == 0)
    self:findChild("Node_RespinsLeft"):setVisible(count > 0)

    if not isInit and count == 3 then
        self:runCsbAction("shuaxin")
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_refresh_respin_count)
    end
end

--[[
    初始化收集状态
]]
function ClawStallFreespinBarView:initCollectStatus()
    for i,item in ipairs(self.m_collectItems) do
        item:findChild("Bonus"):setVisible(false)
        item:findChild("SuperBonus"):setVisible(false)
        item:findChild("m_lb_mul"):setString("")
        item:findChild("m_lb_mul_0"):setString("")
    end
end

--[[
    显示收集条
]]
function ClawStallFreespinBarView:showCollectBar(func)
    self:initCollectStatus()
    self:findChild("Node_RespinCollectionsTrall"):setVisible(true)
    self:runCsbAction("bian",false,function(  )
        self:findChild("Node_RespinsLeft"):setVisible(false)
        self:findChild("Node_RespinCollectionsTrall"):setVisible(true)
        self:findChild("Node_SuperFreeGames"):setVisible(false)
        self:findChild("Node_LastSpin"):setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
    
end

--[[
    刷新收集进度
]]
function ClawStallFreespinBarView:updateCollectBar(curIndex,count,symbolType)
    local item = self.m_collectItems[curIndex]
    item:findChild("Bonus"):setVisible(symbolType == self.m_machine.SYMBOL_BONUS)
    item:findChild("SuperBonus"):setVisible(symbolType == self.m_machine.SYMBOL_BONUS_2)
    item:findChild("m_lb_mul"):setVisible(symbolType == self.m_machine.SYMBOL_BONUS)
    item:findChild("m_lb_mul_0"):setVisible(symbolType == self.m_machine.SYMBOL_BONUS_2)
    item:findChild("m_lb_mul"):setString("X"..count)
    item:findChild("m_lb_mul_0"):setString("X"..count)
end

--[[
    根据索引获取收集item
]]
function ClawStallFreespinBarView:getCollectItemByIndex(index)
    return self.m_collectItems[index]
end

return ClawStallFreespinBarView