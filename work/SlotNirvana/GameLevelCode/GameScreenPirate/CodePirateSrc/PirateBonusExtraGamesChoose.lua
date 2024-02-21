local PirateBonusExtraGamesChoose = class("PirateBonusExtraGamesChoose", util_require("base.BaseView"))
-- 构造函数
function PirateBonusExtraGamesChoose:initUI(data)
    local resourceFilename = "Bonus_Pirate_img.csb"
    self:createCsbNode(resourceFilename)
end

function PirateBonusExtraGamesChoose:animation(index)
    self:runCsbAction("animation"..index)
end

function PirateBonusExtraGamesChoose:selected(index)
    self:runCsbAction("selected"..index)
end

function PirateBonusExtraGamesChoose:unselected(index)
    self:runCsbAction("animation"..index.."_an")
end

function PirateBonusExtraGamesChoose:onEnter()

end

function PirateBonusExtraGamesChoose:onExit()

end


return PirateBonusExtraGamesChoose