--
-- 过场龙卷风
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgyptGuoChang = class("MiracleEgyptGuoChang", util_require("base.BaseView"))

function MiracleEgyptGuoChang:initUI(  )

    self:createCsbNode("MiracleEgypt_guochang.csb")

    self:findChild("Node_3"):setPositionX(display.width - 1660)

    self:setVisible(false)
end

function MiracleEgyptGuoChang:showAction(func )

    self:setVisible(true)

    local actFunc = function(  )
        if func then
            func()
            self:setVisible(false)
        end
    end
    
    self:runCsbAction("actionframe",false,actFunc,20)
end


return  MiracleEgyptGuoChang