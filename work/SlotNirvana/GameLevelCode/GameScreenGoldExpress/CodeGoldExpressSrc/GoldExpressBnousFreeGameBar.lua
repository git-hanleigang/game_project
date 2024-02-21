local GoldExpressBnousFreeGameBar = class("GoldExpressBnousFreeGameBar", util_require("base.BaseView"))
-- 构造函数
function GoldExpressBnousFreeGameBar:initUI(data)
    local resourceFilename = "Socre_GoldExpress_iswild.csb"
    self:createCsbNode(resourceFilename)
end

function GoldExpressBnousFreeGameBar:m4IsWild()
    self:runCsbAction("iswild")
end

function GoldExpressBnousFreeGameBar:doubleWins()
    self:runCsbAction("allwins")
end

function GoldExpressBnousFreeGameBar:onEnter()

end

function GoldExpressBnousFreeGameBar:onExit()

end

return GoldExpressBnousFreeGameBar