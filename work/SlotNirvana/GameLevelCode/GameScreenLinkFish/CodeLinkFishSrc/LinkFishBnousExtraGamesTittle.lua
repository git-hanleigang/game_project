local LinkFishBnousExtraGamesTittle = class("LinkFishBnousExtraGamesTittle", util_require("base.BaseView"))
-- 构造函数
function LinkFishBnousExtraGamesTittle:initUI(data)
    local resourceFilename = "POP_LinkFish_txt_small.csb"
    self:createCsbNode(resourceFilename)
end

function LinkFishBnousExtraGamesTittle:selected(index)
    self:runCsbAction("animation"..index, true)
end

function LinkFishBnousExtraGamesTittle:unselected(index)
    self:runCsbAction("animation_an"..index, true)
end

function LinkFishBnousExtraGamesTittle:onEnter()
    
end

function LinkFishBnousExtraGamesTittle:onExit()
    
end


return LinkFishBnousExtraGamesTittle