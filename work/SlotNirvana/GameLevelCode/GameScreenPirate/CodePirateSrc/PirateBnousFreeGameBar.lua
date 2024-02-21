local PirateBnousFreeGameBar = class("PirateBnousFreeGameBar", util_require("base.BaseView"))
-- 构造函数
function PirateBnousFreeGameBar:initUI(data)
    local resourceFilename = "Socre_Pirate_iswild.csb"
    self:createCsbNode(resourceFilename)
end

function PirateBnousFreeGameBar:m4IsWild()
    self:runCsbAction("iswild")
end

function PirateBnousFreeGameBar:doubleWins()
    self:runCsbAction("allwins")
end

function PirateBnousFreeGameBar:onEnter()

end

function PirateBnousFreeGameBar:onExit()

end

return PirateBnousFreeGameBar