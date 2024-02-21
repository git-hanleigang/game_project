local LinkFishBnousExtraGamesDialog = class("LinkFishBnousExtraGamesDialog", util_require("base.BaseView"))
-- 构造函数
function LinkFishBnousExtraGamesDialog:initUI(data)
    local resourceFilename = "POP_LinkFish_txt.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("animation"..data, true)
end

function LinkFishBnousExtraGamesDialog:onEnter()
    
end

function LinkFishBnousExtraGamesDialog:onExit()
    
end


return LinkFishBnousExtraGamesDialog