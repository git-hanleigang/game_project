--
-- 气泡下UI
-- Author:{author}
-- Date: 2018-12-22 16:34:48

local GameBottomNode = require "views.gameviews.GameBottomNode"

local BlazingMotorsGameBottomNode = class("BlazingMotorsGameBottomNode", util_require("views.gameviews.GameBottomNode"))



function BlazingMotorsGameBottomNode:setMachine(machine )
    self.m_machine = machine
end


function BlazingMotorsGameBottomNode:updateWinCount(goldCountStr)
    -- print("----------"..goldCountStr)
    self.m_normalWinLabel:setString(goldCountStr)



    -- if self.m_runSpinResultData.p_selfMakeData then
    --     local gameType = self.m_runSpinResultData.p_selfMakeData.type
    --     if gameType  then
            -- 更新当前的Jackpot部分ui显示的钱数
            if self.m_machine then
                self.m_machine.m_LocalTopView:findChild("m_lb_coins"):setString(goldCountStr)
                self.m_machine.m_LocalTopView:findChild("m_lb_coins1"):setString(goldCountStr)
                local Label1 = self.m_machine.m_LocalTopView:findChild("m_lb_coins")
                local Label2 = self.m_machine.m_LocalTopView:findChild("m_lb_coins1")
                self.m_machine.m_LocalTopView:updateLabelSize({label=Label1,sx=1,sy=1},383)
                self.m_machine.m_LocalTopView:updateLabelSize({label=Label2,sx=1,sy=1},383)
            end
            
    --     end
    -- end


end

return  BlazingMotorsGameBottomNode