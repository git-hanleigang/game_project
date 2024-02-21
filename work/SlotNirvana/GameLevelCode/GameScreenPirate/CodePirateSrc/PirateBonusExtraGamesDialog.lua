local PirateBonusExtraGamesDialog = class("PirateBonusExtraGamesDialog", util_require("base.BaseView"))
-- 构造函数
function PirateBonusExtraGamesDialog:initUI(data)
    local resourceFilename = "POP_Pirate_txt.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("animation"..data, true)
end

function PirateBonusExtraGamesDialog:onEnter()

end

function PirateBonusExtraGamesDialog:onExit()

end


return PirateBonusExtraGamesDialog