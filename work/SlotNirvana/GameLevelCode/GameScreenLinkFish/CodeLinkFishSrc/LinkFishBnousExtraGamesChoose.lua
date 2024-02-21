local LinkFishBnousExtraGamesChoose = class("LinkFishBnousExtraGamesChoose", util_require("base.BaseView"))
-- 构造函数
function LinkFishBnousExtraGamesChoose:initUI(data)
    local resourceFilename = "Bonus_LinkFish_img.csb"
    self:createCsbNode(resourceFilename)
end

function LinkFishBnousExtraGamesChoose:animation(index)
    self:runCsbAction("animation"..index)
end

function LinkFishBnousExtraGamesChoose:selected(index)
    self:runCsbAction("selected"..index)
end

function LinkFishBnousExtraGamesChoose:unselected(index)
    self:runCsbAction("animation"..index.."_an")
end

function LinkFishBnousExtraGamesChoose:onEnter()
    
end

function LinkFishBnousExtraGamesChoose:onExit()
    
end


return LinkFishBnousExtraGamesChoose