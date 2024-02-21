---
--xcyy
--2018年5月23日
--JackpotElvesCollectBar.lua

local JackpotElvesCollectBar = class("JackpotElvesCollectBar",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "JackpotElvesPublicConfig"

function JackpotElvesCollectBar:initUI(params)
    self.m_color = params.color
    self.m_machine = params.machine
    self.m_spinNode = util_spineCreate("JackpotElves_daizi_"..self.m_color, true, true)
    self.m_spinNode:setSkin(self.m_color)
    self:addChild(self.m_spinNode)

    self.m_collectEffect = util_createAnimation("JackpotElves_juesetx.csb")
    self:addChild(self.m_collectEffect, 2)
    self.m_collectEffect:setVisible(false)
end

function JackpotElvesCollectBar:onEnter()
    -- local _isPortrait = globalData.slotRunData.isPortrait
    -- local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    -- if _isPortrait ~= _isPortraitMachine then
    --     gLobalNoticManager:addObserver(
    --         self,
    --         function(self)
    --             assert(self.m_csbNode, "csbNode is nill !!! cname is " .. self.__cname)
                
    --             local csbNodeName = self.m_csbNode:getName()
    --             if csbNodeName == "Layer" then
    --                 self:changeVisibleSize(display.size)
    --             else
    --                 if not self.m_isUserDefPos then
    --                     -- 使用的屏幕大小换算的坐标
    --                     local posX, posY = self:getPosition()
    --                     self:setPosition(cc.p(posY, posX))
    --                 end
    --             end
    --         end,
    --         ViewEventType.NOTIFY_RESET_SCREEN
    --     )
    -- end
end

function JackpotElvesCollectBar:initBarStatus(level)
    if self.m_barLevel ~= level then
        self:updateBarStatus(level)
    end
end

function JackpotElvesCollectBar:updateBarStatus(level)
    self:playSpineAnim(self.m_spinNode, "idleframe"..level, true)
    self.m_barLevel = level
end

function JackpotElvesCollectBar:collectAnim(level, func)
    self.m_collectEffect:setVisible(true)
    self.m_collectEffect:playAction("shouji",false,function ()
        self.m_collectEffect:setVisible(false)
    end)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_wildCollectFankui)
    if self.m_barLevel == level then
        
        self:playSpineAnim(self.m_spinNode, "shouji"..self.m_barLevel, false, function()
            self:updateBarStatus(level)
            if func then
                func()
            end
        end)
    else
        self:playSpineAnim(self.m_spinNode, "shouji"..self.m_barLevel, false, function()
            self.m_collectEffect:playAction("switch",false,function ()
                self.m_collectEffect:setVisible(false)
            end)
            local switchName = "switch"..self.m_barLevel
            if level - self.m_barLevel > 1 then  --- 1级触发玩法
                switchName = "switch3"
            end
            self:playSpineAnim(self.m_spinNode, switchName, false, function()
                self:updateBarStatus(level)
                if func then
                    func()
                end
            end)
        end)
    end
end

function JackpotElvesCollectBar:collectCompleted(func)
    self.m_collectEffect:setVisible(true)
    self.m_collectEffect:playAction("actionframe",false,function ()
        self.m_collectEffect:setVisible(false)
    end)
    self:playSpineAnim(self.m_spinNode, "actionframe", false, function()
        if func then
            func()
        end
    end)
end

--[[
    spine 动画
]]
function JackpotElvesCollectBar:playSpineAnim(spNode, animName, isLoop, func)
    util_spinePlay(spNode, animName, isLoop == true)
    if func ~= nil then
        util_spineEndCallFunc(spNode, animName, function()
            func()
        end)
    end
end

return JackpotElvesCollectBar