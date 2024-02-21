
local FortuneCatsSuperMul = class("FortuneCatsSuperMul",util_require("base.BaseView"))


function FortuneCatsSuperMul:initUI()
    self:createCsbNode("FortuneCats_zjm_shuzi_1.csb")
end

function FortuneCatsSuperMul:onEnter()
    
end

function FortuneCatsSuperMul:show(num)
    local node=self:findChild("fenshu_1")
    node:setString("X" .. util_formatCoins(num,4))
    self:runCsbAction("show",false,function (  )
        self:runCsbAction("idle",true)
    end)
end

function FortuneCatsSuperMul:hide(func)
    self:runCsbAction("over",false,function ()
        func()
    end)
end

function FortuneCatsSuperMul:onExit()

end

return FortuneCatsSuperMul