---
--island
--2018年4月12日
--FiveDragonLowerBetIcon.lua
--
-- FiveDragonLowerBetIcon top bar

local FiveDragonLowerBetIcon = class("FiveDragonLowerBetIcon", util_require("base.BaseView"))
-- 构造函数
function FiveDragonLowerBetIcon:initUI(machine)
    self.m_machine=machine
    local resourceFilename="FiveDragon_NudgeIcon.csb"
    self:createCsbNode(resourceFilename)
    self:setVisible(false)
end

function FiveDragonLowerBetIcon:show()
    if self:isVisible() == false then
        self:setVisible(true)
    end
    self:runCsbAction("actionframestart", false, function()
        -- self:runCsbAction("idleframe")
    end)
end

function FiveDragonLowerBetIcon:hide()
    self:runCsbAction("actionframeover")
end

function FiveDragonLowerBetIcon:onEnter()
    gLobalNoticManager:addObserver(self,function(self,params)  
        self:updateBetEnable(params)
    end,"BET_ENABLE")
end

function FiveDragonLowerBetIcon:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function FiveDragonLowerBetIcon:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self.m_machine:showLowerBetLayer()
end

function FiveDragonLowerBetIcon:updateBetEnable(flag)
    if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
        flag=false
    end
    local btn = self:findChild("Button_1")
    btn:setBright(flag)
    btn:setTouchEnabled(flag)
end

return FiveDragonLowerBetIcon