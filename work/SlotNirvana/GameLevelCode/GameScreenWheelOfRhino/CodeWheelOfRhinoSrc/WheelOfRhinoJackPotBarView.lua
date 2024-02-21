

local WheelOfRhinoJackPotBarView = class("WheelOfRhinoJackPotBarView",util_require("base.BaseView"))

function WheelOfRhinoJackPotBarView:initUI()
    self:createCsbNode("WheelOfRhino_Jackpot.csb")
    self:runCsbAction("actionframe",true)
end


function WheelOfRhinoJackPotBarView:onExit()
 
end

function WheelOfRhinoJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function WheelOfRhinoJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function WheelOfRhinoJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    for i = 1,5 do
        self:changeNode(self:findChild("BitmapFontLabel_"..i),i,true)
    end

    self:updateSize()
end

function WheelOfRhinoJackPotBarView:updateSize()
    local label1 = self:findChild("BitmapFontLabel_1")
    local info1 = {label = label1,sx = 1,sy = 1}
    local label2 = self:findChild("BitmapFontLabel_2")
    local info2 = {label = label2,sx = 1,sy = 1}
    local label3 = self:findChild("BitmapFontLabel_3")
    local info3 = {label = label3,sx = 0.9,sy = 0.9}
    local label4 = self:findChild("BitmapFontLabel_4")
    local info4 = {label = label4,sx = 0.9,sy = 0.9}
    local label5 = self:findChild("BitmapFontLabel_5")
    local info5 = {label = label5,sx = 0.9,sy = 0.9}

    self:updateLabelSize(info1,389)
    self:updateLabelSize(info2,319)
    self:updateLabelSize(info3,291)
    self:updateLabelSize(info4,263)
    self:updateLabelSize(info5,235)
end

function WheelOfRhinoJackPotBarView:changeNode(label,index,isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString("$ "..util_formatCoins(value,20,nil,nil,true))
end

function WheelOfRhinoJackPotBarView:toAction(actionName)
    self:runCsbAction(actionName)
end


return WheelOfRhinoJackPotBarView