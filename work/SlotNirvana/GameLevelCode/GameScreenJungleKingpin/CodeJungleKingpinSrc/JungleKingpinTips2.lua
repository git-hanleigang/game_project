local JungleKingpinTips2 = class("JungleKingpinTips2", util_require("base.BaseView"))

function JungleKingpinTips2:initUI()
    local csbName = "JungleKingpin_tip_1.csb"
    self:createCsbNode(csbName)
end

function JungleKingpinTips2:onEnter()

end

function JungleKingpinTips2:onExit()

end

function JungleKingpinTips2:ShowTip()
    self:runCsbAction("idle",true)
end

return JungleKingpinTips2
