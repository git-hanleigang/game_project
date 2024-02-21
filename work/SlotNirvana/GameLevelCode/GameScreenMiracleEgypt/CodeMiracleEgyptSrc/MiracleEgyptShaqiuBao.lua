--
-- 气泡爆炸动画
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgyptShaqiuBao = class("MiracleEgyptShaqiuBao", util_require("base.BaseView"))

function MiracleEgyptShaqiuBao:initUI(  )

    self:createCsbNode("Socre_Shaqiu_Bao.csb")

end

function MiracleEgyptShaqiuBao:showAction(func )


    local actFunc = function(  )
        if func then
            func()
        end
    end
    
    self:runCsbAction("actionframe",false,actFunc,20)
end

function MiracleEgyptShaqiuBao:removeSelf(  )

    self:removeFromParent()
    
end

return  MiracleEgyptShaqiuBao