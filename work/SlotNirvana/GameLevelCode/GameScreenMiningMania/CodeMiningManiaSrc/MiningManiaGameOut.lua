---
--xcyy
--2018年5月23日
--MiningManiaGameOut.lua

local MiningManiaGameOut = class("MiningManiaGameOut", util_require("Levels.BaseLevelDialog"))

function MiningManiaGameOut:initUI()
    self:createCsbNode("MiningMania/DuanXianChongLian.csb")
    self.m_btn = self:findChild("Button")
    self:runCsbAction("start", false, function(  )
        self:runCsbAction("idle")
    end, 60)
end

function MiningManiaGameOut:onEnter()
    MiningManiaGameOut.super.onEnter(self)
end

function MiningManiaGameOut:onExit()
    MiningManiaGameOut.super.onExit(self)
end

function MiningManiaGameOut:setClickEnable(_enabled)
    self.m_btn:setTouchEnabled(_enabled)
end

--默认按钮监听回调
function MiningManiaGameOut:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        self:setClickEnable(false)
        self:closeUI()
    end
end

function MiningManiaGameOut:closeUI()
    self:runCsbAction("over",false,function()
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        self:removeFromParent()
    end,60)
end

return MiningManiaGameOut
