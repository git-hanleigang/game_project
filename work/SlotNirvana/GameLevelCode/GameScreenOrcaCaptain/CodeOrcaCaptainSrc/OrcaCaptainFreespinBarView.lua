---
--xcyy
--2018年5月23日
--OrcaCaptainFreespinBarView.lua
local OrcaCaptainPublicConfig = require "OrcaCaptainPublicConfig"
local OrcaCaptainFreespinBarView = class("OrcaCaptainFreespinBarView", util_require("Levels.BaseLevelDialog"))

OrcaCaptainFreespinBarView.m_freespinCurrtTimes = 0

function OrcaCaptainFreespinBarView:initUI()
    self:createCsbNode("OrcaCaptain_FGbar.csb")
    self.totaltimes = 0
end

function OrcaCaptainFreespinBarView:onEnter()
    OrcaCaptainFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function OrcaCaptainFreespinBarView:onExit()
    OrcaCaptainFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function OrcaCaptainFreespinBarView:initTotalTimes(time)
    self.totaltimes = time
end

---
-- 更新freespin 剩余次数
--
function OrcaCaptainFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount --globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function OrcaCaptainFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_1"):setString(curtimes)
    if self.totaltimes ~= totaltimes then
        gLobalSoundManager:playSound(OrcaCaptainPublicConfig.SoundConfig.sound_OrcaCaptain_free_addnum)
        self:runCsbAction("switch")
        self:delayCallBack(5/60,function ()
            self:findChild("m_lb_num_2"):setString(totaltimes)
            self.totaltimes = totaltimes
        end)
    else
        self:findChild("m_lb_num_2"):setString(totaltimes)
        self.totaltimes = totaltimes
    end
    
end

--[[
    延迟回调
]]
function OrcaCaptainFreespinBarView:delayCallBack(time, func)
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

return OrcaCaptainFreespinBarView
