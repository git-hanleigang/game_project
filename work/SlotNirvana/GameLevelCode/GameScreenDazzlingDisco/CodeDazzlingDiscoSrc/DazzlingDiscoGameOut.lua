---
--xcyy
--2018年5月23日
--DazzlingDiscoGameOut.lua
local PublicConfig = require "DazzlingDiscoPublicConfig"
local DazzlingDiscoGameOut = class("DazzlingDiscoGameOut", util_require("Levels.BaseLevelDialog"))

function DazzlingDiscoGameOut:initUI()
    --黑色遮罩
    self.m_mask = util_createAnimation("DazzlingDisco_mask.csb")
    self:addChild(self.m_mask)
    self.m_mask:setPosition(display.center)

    self:createCsbNode("DazzlingDisco/DiaoXian.csb")
    self.m_btn = self:findChild("Button_1")
    self.m_mask:runCsbAction("animation0")
    self:runCsbAction("start", false, function(  )
        self:runCsbAction("idle")
    end, 60)
end

function DazzlingDiscoGameOut:onEnter()
    DazzlingDiscoGameOut.super.onEnter(self)
end

function DazzlingDiscoGameOut:onExit()
    DazzlingDiscoGameOut.super.onExit(self)
end

function DazzlingDiscoGameOut:setClickEnable(_enabled)
    self.m_btn:setTouchEnabled(_enabled)
end

--默认按钮监听回调
function DazzlingDiscoGameOut:clickFunc(sender)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_btn_click)
    local name = sender:getName()
    self:setClickEnable(false)
    self:closeUI()
end

function DazzlingDiscoGameOut:closeUI()
    self.m_mask:runCsbAction("animation2")
    self:runCsbAction("over",false,function()
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        self:removeFromParent()
    end,60)
end

return DazzlingDiscoGameOut
