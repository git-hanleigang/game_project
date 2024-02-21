---
--xcyy
--2018年5月23日
--WarriorAliceFreespinBarView.lua
local PublicConfig = require "WarriorAlicePublicConfig"
local WarriorAliceFreespinBarView = class("WarriorAliceFreespinBarView",util_require("Levels.BaseLevelDialog"))

WarriorAliceFreespinBarView.m_freespinCurrtTimes = 0


function WarriorAliceFreespinBarView:initUI()

    self:createCsbNode("WarriorAlice_free_bar.csb")

    self.totalNum = 0
end


function WarriorAliceFreespinBarView:onEnter()

    WarriorAliceFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
    
end

function WarriorAliceFreespinBarView:onExit()
    WarriorAliceFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

function WarriorAliceFreespinBarView:setCurNum(num)
    self.m_curNum = num
end

---
-- 更新freespin 剩余次数
--
function WarriorAliceFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function WarriorAliceFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num_1"):setString(curtimes)
    if self.m_curNum ~= totaltimes then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_fg_more)
        self:runCsbAction("actionframe")
        self.m_curNum = totaltimes
        self:delayCallBack(15/60,function ()
            self:findChild("m_lb_num_2"):setString(totaltimes)
        end)
    else
        self:findChild("m_lb_num_2"):setString(totaltimes)
    end
    
end

function WarriorAliceFreespinBarView:initFreeSpinCount(curtimes,totaltimes)
    curtimes = totaltimes - curtimes
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
    self.m_curNum = totaltimes
end

--[[
    延迟回调
]]
function WarriorAliceFreespinBarView:delayCallBack(time, func)
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

return WarriorAliceFreespinBarView