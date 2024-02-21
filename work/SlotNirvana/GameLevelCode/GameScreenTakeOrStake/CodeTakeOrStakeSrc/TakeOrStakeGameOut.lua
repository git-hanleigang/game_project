---
--xcyy
--2018年5月23日
--TakeOrStakeGameOut.lua

local TakeOrStakeGameOut = class("TakeOrStakeGameOut", util_require("Levels.BaseLevelDialog"))

function TakeOrStakeGameOut:initUI()
    self:createCsbNode("TakeOrStake/OutOfRoom.csb")
    self.m_btn = self:findChild("Btn_OK")
    self:runCsbAction("start", false, function(  )
        self:runCsbAction("idle")
    end, 60)
end

function TakeOrStakeGameOut:onEnter()
    TakeOrStakeGameOut.super.onEnter(self)
end

function TakeOrStakeGameOut:onExit()
    TakeOrStakeGameOut.super.onExit(self)
end

function TakeOrStakeGameOut:setClickEnable(_enabled)
    self.m_btn:setTouchEnabled(_enabled)
end

--默认按钮监听回调
function TakeOrStakeGameOut:clickFunc(sender)
    local name = sender:getName()
    if name == "Btn_OK" then
        self:setClickEnable(false)
        self:closeUI()
    end
end

function TakeOrStakeGameOut:closeUI()
    self:runCsbAction("over",false,function()
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        self:removeFromParent()
    end,60)
end

return TakeOrStakeGameOut
