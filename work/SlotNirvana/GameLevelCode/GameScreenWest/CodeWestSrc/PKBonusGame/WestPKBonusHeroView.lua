---
--xcyy
--2018年5月23日
--WestPKBonusHeroView.lua

local WestPKBonusHeroView = class("WestPKBonusHeroView",util_require("base.BaseView"))


function WestPKBonusHeroView:initUI()

    self:createCsbNode("West_bonusgame_hp1.csb")

    self:initHealthValue( )

end

function WestPKBonusHeroView:initHealthValue( )
    
    for i=1,3 do
        
        local hp = util_createAnimation("West_bonusgame_hp_xin.csb")
        self:findChild("West_hp_"..i):addChild(hp)
        self["HealthValue_" .. i]  = hp

    end
end

function WestPKBonusHeroView:updateHealthValue( num )
    

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

function WestPKBonusHeroView:onEnter()
 

end


function WestPKBonusHeroView:onExit()
 
end

--默认按钮监听回调
function WestPKBonusHeroView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return WestPKBonusHeroView