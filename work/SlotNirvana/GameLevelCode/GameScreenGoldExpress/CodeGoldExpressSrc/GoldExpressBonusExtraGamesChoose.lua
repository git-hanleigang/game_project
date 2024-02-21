local GoldExpressBonusExtraGamesChoose = class("GoldExpressBonusExtraGamesChoose", util_require("base.BaseView"))
-- 构造函数
function GoldExpressBonusExtraGamesChoose:initUI(data)
    local resourceFilename = "Bonus_GoldExpress_img.csb"
    self:createCsbNode(resourceFilename)
end

function GoldExpressBonusExtraGamesChoose:animation(index)
    self:runCsbAction("animation"..index)
end

function GoldExpressBonusExtraGamesChoose:selected(index)
    self:runCsbAction("selected"..index)
end

function GoldExpressBonusExtraGamesChoose:unselected(index)
    self:runCsbAction("animation"..index.."_an")
end

function GoldExpressBonusExtraGamesChoose:onEnter()

end

function GoldExpressBonusExtraGamesChoose:onExit()

end


return GoldExpressBonusExtraGamesChoose