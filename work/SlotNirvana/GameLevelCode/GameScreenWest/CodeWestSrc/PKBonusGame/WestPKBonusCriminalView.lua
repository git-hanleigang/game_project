---
--xcyy
--2018年5月23日
--WestPKBonusCriminalView.lua

local WestPKBonusCriminalView = class("WestPKBonusCriminalView",util_require("base.BaseView"))


function WestPKBonusCriminalView:initUI()

    self:createCsbNode("West_bonusgame_hp2.csb")

    self:initHealthValue( )

end

function WestPKBonusCriminalView:initHealthValue( )
    
    for i=1,3 do
        
        self["HealthValue_" .. i] = util_createAnimation("West_bonusgame_hp_xin.csb")
        self:findChild("West_hp_"..i):addChild(self["HealthValue_" .. i])

    end
end


function WestPKBonusCriminalView:updateHealthValue( num )
    

    for i=1,3 do
        local hp = self["HealthValue_" .. i]
        if hp then
            if i > num then
                hp:setVisible(false)
            else
                hp:setVisible(true)
            end
        end
    end

end

function WestPKBonusCriminalView:onEnter()
 

end

function WestPKBonusCriminalView:showAdd()
    
end
function WestPKBonusCriminalView:onExit()
 
end

--默认按钮监听回调
function WestPKBonusCriminalView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return WestPKBonusCriminalView