---
--xcyy
--2018年5月23日
--WingsOfPhoelinxFreespinStart.lua

local WingsOfPhoelinxFreespinStart = class("WingsOfPhoelinxFreespinStart",util_require("Levels.BaseLevelDialog"))



function WingsOfPhoelinxFreespinStart:initUI()

    self:createCsbNode("WingsOfPhoelinx/FreeSpinStart.csb")

    self.guangNode,self.guang = util_csbCreate("FreeSpinStart_guang.csb")
    self:findChild("guang"):addChild(self.guangNode)
    util_csbPlayForKey(self.guang,"idle",true)

    self.callFunc = nil
end


function WingsOfPhoelinxFreespinStart:onEnter()

    WingsOfPhoelinxFreespinStart.super.onEnter(self)

end

function WingsOfPhoelinxFreespinStart:onExit()
    WingsOfPhoelinxFreespinStart.super.onExit(self)

end

function WingsOfPhoelinxFreespinStart:initView(num,func)
    self:findChild("m_lb_num"):setString(num)
    self.callFunc = func
end

function WingsOfPhoelinxFreespinStart:showFreeAct( )
    
    self:runCsbAction("start",false,function (  )
        self:runCsbAction("idle",true)
    end)
end

--默认按钮监听回调
function WingsOfPhoelinxFreespinStart:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button" then
        self:runCsbAction("over",false,function (  )
            if self.callFunc then
                self.callFunc()
            end
            self:removeFromParent()
        end)
    end
end


return WingsOfPhoelinxFreespinStart