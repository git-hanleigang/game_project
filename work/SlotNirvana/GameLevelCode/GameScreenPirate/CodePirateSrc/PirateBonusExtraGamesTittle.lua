local PirateBonusExtraGamesTittle = class("PirateBonusExtraGamesTittle", util_require("base.BaseView"))
-- 构造函数
function PirateBonusExtraGamesTittle:initUI(data)
    local resourceFilename = "POP_Pirate_txt_small.csb"
    self:createCsbNode(resourceFilename)
end

function PirateBonusExtraGamesTittle:selected(index)
    self:runCsbAction("animation"..index, true)
end

function PirateBonusExtraGamesTittle:unselected(index)
    self:runCsbAction("animation_an"..index, true)
end

function PirateBonusExtraGamesTittle:onEnter()

end

function PirateBonusExtraGamesTittle:onExit()

end


return PirateBonusExtraGamesTittle