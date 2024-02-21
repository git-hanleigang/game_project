---
--xcyy
--2018年5月23日
--ZeusBonusPressView.lua

local ZeusBonusPressView = class("ZeusBonusPressView",util_require("base.BaseView"))

function ZeusBonusPressView:initUI(bonusMain)

    self:createCsbNode("BonusView/Zeus_bonus_press.csb")

    self.m_bonusMain = bonusMain

    self:addClick(self:findChild("click"))  

end


function ZeusBonusPressView:onEnter()
 

end


function ZeusBonusPressView:onExit()
 
end


--默认按钮监听回调
function ZeusBonusPressView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        
        self.m_bonusMain:beginSendData()

    end

end




return ZeusBonusPressView