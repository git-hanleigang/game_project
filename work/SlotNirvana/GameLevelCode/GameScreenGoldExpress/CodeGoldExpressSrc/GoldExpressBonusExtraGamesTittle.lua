local GoldExpressBonusExtraGamesTittle = class("GoldExpressBonusExtraGamesTittle", util_require("base.BaseView"))
-- 构造函数
function GoldExpressBonusExtraGamesTittle:initUI(data)
    local resourceFilename = "POP_GoldExpress_txt_small.csb"
    self:createCsbNode(resourceFilename)
end

function GoldExpressBonusExtraGamesTittle:selected(index)
    self:runCsbAction("animation"..index, true)
end

function GoldExpressBonusExtraGamesTittle:unselected(index)
    self:runCsbAction("animation_an"..index, true)
end

function GoldExpressBonusExtraGamesTittle:onEnter()

end

function GoldExpressBonusExtraGamesTittle:onExit()

end


return GoldExpressBonusExtraGamesTittle