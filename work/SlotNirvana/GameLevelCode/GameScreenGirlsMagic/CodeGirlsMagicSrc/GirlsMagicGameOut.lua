---
--xcyy
--2018年5月23日
--GirlsMagicGameOut.lua

local GirlsMagicGameOut = class("GirlsMagicGameOut", util_require("base.BaseView"))

function GirlsMagicGameOut:initUI()
    self:createCsbNode("GirlsMagic/OutOfRoom.csb")
    self.m_btn = self:findChild("tb_btn")
    self:runCsbAction("start", false, function(  )
        self:runCsbAction("idle")
    end, 60)

    -- performWithDelay(self,function(  )
    --     self:clickFunc(self.m_btn)
    -- end,3)
end

function GirlsMagicGameOut:onEnter()
end

function GirlsMagicGameOut:onExit()
end

function GirlsMagicGameOut:setClickEnable(_enabled)
    self.m_btn:setTouchEnabled(_enabled)
end

--默认按钮监听回调
function GirlsMagicGameOut:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then
        self:setClickEnable(false)
        self:closeUI()
    end
end

function GirlsMagicGameOut:closeUI()
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

return GirlsMagicGameOut
