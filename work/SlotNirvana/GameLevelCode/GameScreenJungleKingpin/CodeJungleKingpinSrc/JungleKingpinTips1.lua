local JungleKingpinTips1 = class("JungleKingpinTips1", util_require("base.BaseView"))

function JungleKingpinTips1:initUI()
    local csbName = "JungleKingpin_tip.csb"
    self:createCsbNode(csbName)
    self:addClick(self:findChild("Panel_1"))
end

function JungleKingpinTips1:onEnter()
end

function JungleKingpinTips1:onExit()
end

function JungleKingpinTips1:ShowTip()
    self:runCsbAction("open")
end
function JungleKingpinTips1:HideTip()
    self:runCsbAction(
        "over",
        false,
        function()
            self:setVisible(false)
        end
    )
end
function JungleKingpinTips1:clickFunc(sender)
    local name = sender:getName()

    if name == "Panel_1" then
        if self:isVisible() == true then
            self:runCsbAction(
                "over",
                false,
                function()
                    self:setVisible(false)
                end
            )
        end
    end
end
return JungleKingpinTips1
