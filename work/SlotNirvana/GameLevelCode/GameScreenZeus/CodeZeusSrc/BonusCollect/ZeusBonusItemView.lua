---
--xcyy
--2018年5月23日
--ZeusBonusItemView.lua

local ZeusBonusItemView = class("ZeusBonusItemView",util_require("base.BaseView"))

function ZeusBonusItemView:initUI(bonusMain)

    self:createCsbNode("BonusView/Zeus_bonus.csb")

    self.m_bonusMain = bonusMain


end


function ZeusBonusItemView:onEnter()
 

end


function ZeusBonusItemView:onExit()
 
end






return ZeusBonusItemView