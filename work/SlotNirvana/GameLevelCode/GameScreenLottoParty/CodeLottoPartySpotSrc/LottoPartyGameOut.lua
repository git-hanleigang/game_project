---
--xcyy
--2018年5月23日
--LottoPartyGameOut.lua
local BaseLevelDialog = util_require("Levels.BaseLevelDialog")
local LottoPartyGameOut = class("LottoPartyGameOut", BaseLevelDialog)

function LottoPartyGameOut:initUI()
    self:createCsbNode("LottoParty/OutOfRoom.csb")
    self.m_btn = self:findChild("tb_btn")
    self:runCsbAction("start", false, nil, 60)
end

function LottoPartyGameOut:setClickEnable(_enabled)
    self.m_btn:setTouchEnabled(_enabled)
end

--默认按钮监听回调
function LottoPartyGameOut:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then
        self:setClickEnable(false)
        self:closeUI()
    end
end

function LottoPartyGameOut:closeUI()
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

return LottoPartyGameOut
