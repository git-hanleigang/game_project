---
--xcyy
--2018年5月23日
--FruitPartyGameOut.lua

local FruitPartyGameOut = class("FruitPartyGameOut", util_require("base.BaseView"))

function FruitPartyGameOut:initUI()
    self:createCsbNode("FruitParty/OutOfRoom.csb")
    self.m_btn = self:findChild("tb_btn")
    self:runCsbAction("start", false, function(  )
        self:runCsbAction("idle")
    end, 60)

    -- performWithDelay(self,function(  )
    --     self:clickFunc(self.m_btn)
    -- end,3)
end

function FruitPartyGameOut:onEnter()
end

function FruitPartyGameOut:onExit()
end

function FruitPartyGameOut:setClickEnable(_enabled)
    self.m_btn:setTouchEnabled(_enabled)
end

--默认按钮监听回调
function FruitPartyGameOut:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then
        self:setClickEnable(false)
        self:closeUI()
    end
end

function FruitPartyGameOut:closeUI()
    self:runCsbAction(
        "over",
        false,
        function()
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
            self:removeFromParent()
        end,
        60
    )
end

return FruitPartyGameOut
