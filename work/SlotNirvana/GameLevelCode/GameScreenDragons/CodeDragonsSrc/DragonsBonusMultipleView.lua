---
--xcyy
--2018年5月23日
--DragonsBonusMultipleView.lua

local DragonsBonusMultipleView = class("DragonsBonusMultipleView",util_require("base.BaseView"))


function DragonsBonusMultipleView:initUI()
    self:createCsbNode("Dragons_wheel_chengbei.csb")
end


function DragonsBonusMultipleView:onEnter()
 

end

function DragonsBonusMultipleView:playMultipleEffect(_multiple)
    self:findChild("Dragons_wheel_2b_1"):setVisible(false)
    self:findChild("Dragons_wheel_3b_2"):setVisible(false)
    self:findChild("Dragons_wheel_5b_3"):setVisible(false)
    self:findChild("Dragons_wheel_8b_4"):setVisible(false)
    self:findChild("Dragons_wheel_10b_5"):setVisible(false)
    if _multiple == "2" then
        self:findChild("Dragons_wheel_2b_1"):setVisible(true)
    elseif _multiple == "3" then
        self:findChild("Dragons_wheel_3b_2"):setVisible(true)
    elseif _multiple == "5" then
        self:findChild("Dragons_wheel_5b_3"):setVisible(true)
    elseif _multiple == "8" then
        self:findChild("Dragons_wheel_8b_4"):setVisible(true)
    elseif _multiple == "10" then
        self:findChild("Dragons_wheel_10b_5"):setVisible(true)
    end
    -- self:runCsbAction("start") -- 播放时间线
end

function DragonsBonusMultipleView:onExit()
 
end

--默认按钮监听回调
function DragonsBonusMultipleView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

return DragonsBonusMultipleView