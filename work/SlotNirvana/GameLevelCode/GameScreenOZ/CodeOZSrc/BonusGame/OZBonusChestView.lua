---
--xcyy
--2018年5月23日
--OZBonusChestView.lua

local OZBonusChestView = class("OZBonusChestView",util_require("base.BaseView"))

local btnStates = {
    notTouch = 0,
    Touch = 1,
}

OZBonusChestView.m_states = btnStates.Touch
function OZBonusChestView:initUI(game)

    self.m_game = game
    self:createCsbNode("OZ_baoxiang.csb")
    self:addClick(self:findChild("Panel_1"))

end

function OZBonusChestView:setChestViewStates( canTouch)
    if canTouch then
        self.m_states = btnStates.Touch
    else

        self.m_states = btnStates.notTouch
    end

end


function OZBonusChestView:onEnter()
 

end


function OZBonusChestView:onExit()
 
end

--默认按钮监听回调
function OZBonusChestView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()


    if self.m_game:isTouch() then
        return
    end

    if self.m_states == btnStates.notTouch then
        return
    end

    if name == "Panel_1" then
        
        if self.m_ClickCall then
            self.m_ClickCall()
        end
        self:setChestViewStates( false)
    end

end

function OZBonusChestView:setClickCall( func )
    
    self.m_ClickCall = function(  )
        if func then
            func()
        end
    end
end


return OZBonusChestView