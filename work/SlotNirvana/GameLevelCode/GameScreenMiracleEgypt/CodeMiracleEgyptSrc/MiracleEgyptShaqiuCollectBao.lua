--
-- 气泡爆炸动画
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgyptShaqiuCollectBao = class("MiracleEgyptShaqiuCollectBao", util_require("base.BaseView"))

function MiracleEgyptShaqiuCollectBao:initUI(  )

    self:createCsbNode("MiracleEgypt_ShaQiuCollectBao.csb")

end

function MiracleEgyptShaqiuCollectBao:showAction(func )


    local actFunc = function(  )
        if func then
            func()
        end
    end
    
    self:runCsbAction("actionframe",false,actFunc,20)
end

function MiracleEgyptShaqiuCollectBao:removeSelf(  )

    self:removeFromParent()
    
end

return  MiracleEgyptShaqiuCollectBao