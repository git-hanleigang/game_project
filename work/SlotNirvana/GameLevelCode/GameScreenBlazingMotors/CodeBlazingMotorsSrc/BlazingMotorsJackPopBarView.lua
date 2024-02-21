---
--xcyy
--2018年5月23日
--BlazingMotorsJackPopBarView.lua

local BlazingMotorsJackPopBarView = class("BlazingMotorsJackPopBarView",util_require("base.BaseView"))


function BlazingMotorsJackPopBarView:initUI()

    self:createCsbNode("BlazingMotors_Jackpot_Move.csb")

    for i=9,5,-1 do

        local name = "JackPotAction_" .. i
        self[name] = util_createView("CodeBlazingMotorsSrc.BlazingMotorsJackPotAction",i)
        self:findChild(tostring(i)):addChild(self[name])
        self[name]:setVisible(false)
    end

end

function BlazingMotorsJackPopBarView:showjackPotAction(id,isShow )

    if id < 5 then
       return
    end
    
    local name = "JackPotAction_" .. id
    local node = self[name]
    if node then

        if isShow then
            node:setVisible(true)
            node:runCsbAction("actionframe",true)
        else
            node:setVisible(false)
            node:runCsbAction("actionframe",false)
        end
    end
    

end


function BlazingMotorsJackPopBarView:onEnter()
 

end

function BlazingMotorsJackPopBarView:showAdd()
    
end
function BlazingMotorsJackPopBarView:onExit()
 
end


return BlazingMotorsJackPopBarView