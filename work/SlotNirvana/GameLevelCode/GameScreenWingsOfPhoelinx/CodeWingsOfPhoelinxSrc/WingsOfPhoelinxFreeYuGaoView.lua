---
--xcyy
--2018年5月23日
--WingsOfPhoelinxFreeYuGaoView.lua

local WingsOfPhoelinxFreeYuGaoView = class("WingsOfPhoelinxFreeYuGaoView",util_require("Levels.BaseLevelDialog"))


function WingsOfPhoelinxFreeYuGaoView:initUI()

    self:createCsbNode("WingsOfPhoelinx_free_yugao.csb")
    
    self.yuGaoView = util_spineCreate("Socre_WingsOfPhoelinx_yugao",true,true)
    self:findChild("Node_yugao"):addChild(self.yuGaoView)
    self.yuGaoView:setVisible(true)
end


function WingsOfPhoelinxFreeYuGaoView:onEnter()

    WingsOfPhoelinxFreeYuGaoView.super.onEnter(self)

end

function WingsOfPhoelinxFreeYuGaoView:onExit()
    WingsOfPhoelinxFreeYuGaoView.super.onExit(self)
end

function WingsOfPhoelinxFreeYuGaoView:showYuGao(func)
    self.yuGaoView:setVisible(true)
    self:runCsbAction("actionframe")
    util_spinePlay(self.yuGaoView,"actionframe",false)
    util_spineEndCallFunc(self.yuGaoView,"actionframe",function (  )
        self.yuGaoView:setVisible(false)
        if func then
            func()
        end
    end)
end

return WingsOfPhoelinxFreeYuGaoView