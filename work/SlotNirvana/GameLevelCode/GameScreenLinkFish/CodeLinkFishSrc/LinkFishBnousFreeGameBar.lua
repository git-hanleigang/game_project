local LinkFishBnousFreeGameBar = class("LinkFishBnousFreeGameBar", util_require("base.BaseView"))
-- 构造函数
function LinkFishBnousFreeGameBar:initUI(data)
    local resourceFilename = "Socre_LinkFish_iswild.csb"
    self:createCsbNode(resourceFilename)
end

function LinkFishBnousFreeGameBar:m4IsWild()
    self:runCsbAction("iswild")
end

function LinkFishBnousFreeGameBar:doubleWins()
    self:runCsbAction("allwins")
end

function LinkFishBnousFreeGameBar:onEnter()
    
end

function LinkFishBnousFreeGameBar:onExit()
    
end

return LinkFishBnousFreeGameBar