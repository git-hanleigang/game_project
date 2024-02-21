---
--xcyy
--2018年5月23日
--LuckyRacingGameOut.lua

local LuckyRacingGameOut = class("LuckyRacingGameOut", util_require("base.BaseView"))

function LuckyRacingGameOut:initUI()
    self:createCsbNode("LuckyRacing/KeepSpinning.csb")
    self.m_btn = self:findChild("Button")
    self:runCsbAction("start", false, function(  )
        self:runCsbAction("idle")
    end, 60)
end

function LuckyRacingGameOut:onEnter()
    LuckyRacingGameOut.super.onEnter(self)
end

function LuckyRacingGameOut:onExit()
    LuckyRacingGameOut.super.onExit(self)
end

function LuckyRacingGameOut:setClickEnable(_enabled)
    self.m_btn:setTouchEnabled(_enabled)
end

--默认按钮监听回调
function LuckyRacingGameOut:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        self:setClickEnable(false)
        self:closeUI()
    end
end

function LuckyRacingGameOut:closeUI()
    self:runCsbAction("over",false,function()
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        self:removeFromParent()
    end,60)
end

return LuckyRacingGameOut
