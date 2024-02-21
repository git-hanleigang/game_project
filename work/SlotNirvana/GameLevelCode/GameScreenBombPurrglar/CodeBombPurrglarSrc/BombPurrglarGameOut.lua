---
--xcyy
--2018年5月23日
--BombPurrglarGameOut.lua

local BombPurrglarGameOut = class("BombPurrglarGameOut", util_require("Levels.BaseLevelDialog"))

function BombPurrglarGameOut:initUI()
    self:createCsbNode("BombPurrglar/OutOfRoom.csb")
    self.m_btn = self:findChild("tb_btn")
    self:runCsbAction("start", false, function(  )
        self:runCsbAction("idle")
    end, 60)
end

function BombPurrglarGameOut:onEnter()
    BombPurrglarGameOut.super.onEnter(self)
end

function BombPurrglarGameOut:onExit()
    BombPurrglarGameOut.super.onExit(self)
end

function BombPurrglarGameOut:setClickEnable(_enabled)
    self.m_btn:setTouchEnabled(_enabled)
end

--默认按钮监听回调
function BombPurrglarGameOut:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then
        self:setClickEnable(false)
        self:closeUI()
    end
end

function BombPurrglarGameOut:closeUI()
    self:runCsbAction("over",false,function()
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        self:removeFromParent()
    end,60)
end

return BombPurrglarGameOut
