

local ZeusVsHadesGameOut = class("ZeusVsHadesGameOut", util_require("base.BaseView"))

function ZeusVsHadesGameOut:initUI()
    self:createCsbNode("ZeusVsHades/OutOfRoom.csb")
    self.m_btn = self:findChild("tb_btn")
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle")
    end, 60)
end

function ZeusVsHadesGameOut:onEnter()
end

function ZeusVsHadesGameOut:onExit()
end

function ZeusVsHadesGameOut:setClickEnable(_enabled)
    self.m_btn:setTouchEnabled(_enabled)
end

--默认按钮监听回调
function ZeusVsHadesGameOut:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then
        self:setClickEnable(false)
        self:closeUI()
    end
end

function ZeusVsHadesGameOut:closeUI()
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

return ZeusVsHadesGameOut
