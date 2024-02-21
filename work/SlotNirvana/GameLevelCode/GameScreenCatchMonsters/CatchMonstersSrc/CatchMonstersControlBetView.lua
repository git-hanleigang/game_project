---
--xcyy
--2018年5月23日
--CatchMonstersControlBetView.lua

local CatchMonstersControlBetView = class("CatchMonstersControlBetView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CatchMonstersPublicConfig"

function CatchMonstersControlBetView:initUI(_params)
    self.m_machine = _params.machine
    self:createCsbNode("CatchMonsters_BaseBet_control.csb")
    self:addClick(self:findChild("Panel_chooseBet"))

    self.m_controlTxNode = util_createAnimation("CatchMonsters_BaseBet_control_tx.csb")
    self:findChild("Node_tx"):addChild(self.m_controlTxNode)
    self.m_controlTxNode:setVisible(false)

    self:runCsbAction("idle", true)
end

function CatchMonstersControlBetView:onEnter()
    CatchMonstersControlBetView.super.onEnter(self)
end

function CatchMonstersControlBetView:onExit()
    CatchMonstersControlBetView.super.onExit(self)
end

--默认按钮监听回调
function CatchMonstersControlBetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_chooseBet" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_click)
        self:setUI()
    end
end

function CatchMonstersControlBetView:setUI()
    gLobalNoticManager:postNotification("OPEN_CHOOSEVIEW")
end

--[[
    压暗
]]
function CatchMonstersControlBetView:playDarkEffect( )
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
end

--[[
    变亮
]]
function CatchMonstersControlBetView:playUnDarkEffect( )
    self:runCsbAction("over", false, function()
        
    end)
end

--[[
    播放切换动画
]]
function CatchMonstersControlBetView:playChangeEffect()
    self.m_controlTxNode:setVisible(true)
    self.m_controlTxNode:runCsbAction("switch", false, function()
        self.m_controlTxNode:setVisible(false)
    end)
    self:runCsbAction("idle2", false, function()
        self:runCsbAction("idle", true)
    end)
    performWithDelay(self, function()
        self:playSelectBetEffect()
    end, 15/60)
end

--[[
    不同betLevel 下 显示不同
]]
function CatchMonstersControlBetView:playSelectBetEffect()
    for i = 1, 4 do
        self:findChild("CatchMonsters_reel_"..i):setVisible((self.m_machine.m_iBetLevel+1) == i)
    end
end

return CatchMonstersControlBetView