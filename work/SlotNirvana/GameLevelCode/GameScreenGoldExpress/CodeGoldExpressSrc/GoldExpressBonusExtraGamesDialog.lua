local GoldExpressBonusExtraGamesDialog = class("GoldExpressBonusExtraGamesDialog", util_require("base.BaseView"))
-- 构造函数
function GoldExpressBonusExtraGamesDialog:initUI(data)
    local resourceFilename = "POP_GoldExpress_txt.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("animation"..data, true)
end

function GoldExpressBonusExtraGamesDialog:onEnter()

end

function GoldExpressBonusExtraGamesDialog:onExit()

end


return GoldExpressBonusExtraGamesDialog