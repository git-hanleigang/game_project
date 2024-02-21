---
--xcyy
--2018年5月23日
--HouseOfBurgerCollectCopyView.lua

local HouseOfBurgerCollectCopyView = class("HouseOfBurgerCollectCopyView",util_require("base.BaseView"))

-- HouseOfBurger_shouji
function HouseOfBurgerCollectCopyView:initUI(data)
    self.m_machine = data
    self:createCsbNode("HouseOfBurger_shouji.csb")


end

function HouseOfBurgerCollectCopyView:onEnter()


end


function HouseOfBurgerCollectCopyView:onExit()

end

--默认按钮监听回调
function HouseOfBurgerCollectCopyView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return HouseOfBurgerCollectCopyView