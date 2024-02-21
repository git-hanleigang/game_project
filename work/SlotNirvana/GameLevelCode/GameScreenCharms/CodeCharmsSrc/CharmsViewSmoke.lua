---
--xcyy
--2018年5月23日
--CharmsViewSmoke.lua

local CharmsViewSmoke = class("CharmsViewSmoke",util_require("base.BaseView"))


function CharmsViewSmoke:initUI()

    self:createCsbNode("Socre_Charms_bonus_smoke.csb")

end


function CharmsViewSmoke:onEnter()
 

end

function CharmsViewSmoke:showAnimation(typeid,func)
    if typeid == 2 then
        self:runCsbAction("actionframe2",false,function(  )
            if func then
                func()
            end
        end) -- 两格
    else
         self:runCsbAction("actionframe",false,function(  )
            if func then
                func()
            end
         end) -- 一格
    end
end
function CharmsViewSmoke:onExit()
 
end

--默认按钮监听回调
function CharmsViewSmoke:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return CharmsViewSmoke