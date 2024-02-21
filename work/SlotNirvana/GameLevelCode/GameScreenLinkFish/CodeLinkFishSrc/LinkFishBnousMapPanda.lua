local LinkFishBnousMapPanda = class("LinkFishBnousMapPanda", util_require("base.BaseView"))
-- 构造函数
function LinkFishBnousMapPanda:initUI(data)
    local resourceFilename = "Bonus_LinkFish_Map_Panda.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idleframe", true)
end

function LinkFishBnousMapPanda:onEnter()
    
end

function LinkFishBnousMapPanda:onExit()
    
end


return LinkFishBnousMapPanda