local GoldExpressBonusMapPanda = class("GoldExpressBonusMapPanda", util_require("base.BaseView"))
-- 构造函数
function GoldExpressBonusMapPanda:initUI(data)
    local resourceFilename = "Bonus_GoldExpress_Map_huoche.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idleframe", true)
end

function GoldExpressBonusMapPanda:onEnter()

end

function GoldExpressBonusMapPanda:onExit()

end


return GoldExpressBonusMapPanda