--
-- 沙盘动画
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgyptShaPan = class("MiracleEgyptShaPan", util_require("base.BaseView"))

function MiracleEgyptShaPan:initUI(  )

    self:createCsbNode("MiracleEgypt_shapan.csb")

end

function MiracleEgyptShaPan:showAction(func,loop )


    local actFunc = function(  )
        if func then
            func()
        end
    end
    
    self:runCsbAction("animation0",loop,actFunc,20)
end

function MiracleEgyptShaPan:removeSelf(  )
    self:removeFromParent()
end

return  MiracleEgyptShaPan