---
--xcyy
--2018年5月23日
--WingsOfPhoelinxCollectView.lua

local WingsOfPhoelinxCollectView = class("WingsOfPhoelinxCollectView",util_require("Levels.BaseLevelDialog"))


function WingsOfPhoelinxCollectView:initUI(index)

    self:createCsbNode("WingsOfPhoelinx_jinbidui.csb")

    local imgName = {"WingsOfPhoelinx_jinbi1_1 ","WingsOfPhoelinx_jinbi2_2","WingsOfPhoelinx_jinbi3_3"}
    for k,v in pairs(imgName) do
        local img =  self:findChild(v)
        if img then
            if k == index then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
            
        end
    end
end



function WingsOfPhoelinxCollectView:initMachine(machine)
    self.m_machine = machine
end

function WingsOfPhoelinxCollectView:onEnter()

    WingsOfPhoelinxCollectView.super.onEnter(self)
end

function WingsOfPhoelinxCollectView:onExit()
    WingsOfPhoelinxCollectView.super.onExit(self)
end

function WingsOfPhoelinxCollectView:changeGoldNum(index)
    
end

return WingsOfPhoelinxCollectView