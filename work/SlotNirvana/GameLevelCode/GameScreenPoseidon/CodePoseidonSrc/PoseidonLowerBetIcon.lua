---
--island
--2018年4月12日
--PoseidonLowerBetIcon.lua
--
-- PoseidonLowerBetIcon top bar

local PoseidonLowerBetIcon = class("PoseidonLowerBetIcon", util_require("base.BaseView"))
-- 构造函数
function PoseidonLowerBetIcon:initUI(machine)
    self.m_machine=machine
    local resourceFilename="Poseidon_NudgeIcon.csb"
    self:createCsbNode(resourceFilename)
    self:setVisible(false)
end

function PoseidonLowerBetIcon:show()
    if self:isVisible() == false then
        self:setVisible(true)
    end
    self:runCsbAction("actionframestart", false, function()
        -- self:runCsbAction("idleframe")
    end)
end

function PoseidonLowerBetIcon:hide()
    self:runCsbAction("actionframeover")
end

function PoseidonLowerBetIcon:onEnter()
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        self:updateBetEnable(params)
    end,"BET_ENABLE")
end

function PoseidonLowerBetIcon:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function PoseidonLowerBetIcon:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self.m_machine:showLowerBetLayer()
end

function PoseidonLowerBetIcon:updateBetEnable(flag)
    if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
        flag=false
    end
    local btn = self:findChild("Button_1")
    btn:setBright(flag)
    btn:setTouchEnabled(flag)
end

return PoseidonLowerBetIcon