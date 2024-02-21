--
-- 气泡
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgyptShaqiu = class("MiracleEgyptShaqiu", util_require("base.BaseView"))

function MiracleEgyptShaqiu:initUI(  )

    self:createCsbNode("Socre_Shaqiu.csb")

    self:showAction()
end

function MiracleEgyptShaqiu:showAction(func )


    local actFunc = function(  )
        if func then
            func()
        end
    end
    
    self:runCsbAction("idleframe",true,actFunc,20)
end

function MiracleEgyptShaqiu:removeSelf(  )
    self:removeFromParent()
end

return  MiracleEgyptShaqiu