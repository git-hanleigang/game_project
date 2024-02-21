---
--xcyy
--2018年5月23日
--AfricaRiseAddRowEffect.lua

local AfricaRiseAddRowEffect = class("AfricaRiseAddRowEffect",util_require("base.BaseView"))

function AfricaRiseAddRowEffect:initUI()

    self:createCsbNode("AfricaRise_shenglunlizi.csb")
end


function AfricaRiseAddRowEffect:onEnter()
end

function AfricaRiseAddRowEffect:onExit()
end

-- 更新赢钱数
function AfricaRiseAddRowEffect:playAddRowEffect(func)
   
    self:runCsbAction("animation",false,function (  )
        if func then
            func()
        end
        -- self:removeFromParent()

    end)
end

return AfricaRiseAddRowEffect