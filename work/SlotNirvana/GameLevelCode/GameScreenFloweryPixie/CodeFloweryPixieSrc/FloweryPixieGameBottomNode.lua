---
--xcyy
--2018年5月23日
--FloweryPixieGameBottomNode.lua

local FloweryPixieGameBottomNode = class("FloweryPixieGameBottomNode",util_require("views.gameviews.GameBottomNode"))

function FloweryPixieGameBottomNode:setMachine( machine )
    self.m_machine = machine
end

function FloweryPixieGameBottomNode:clickFunc(sender)

    local senderName = sender:getName()
    local isCanClick = true
    if "btn_add" == senderName then
        if self.m_machine then
            if self.m_machine.m_Bonus1ActNode then
                local childs = self.m_machine.m_Bonus1ActNode:getChildren() 
                if childs and #childs > 0 then
                    isCanClick = false
                end
            end
        end

    elseif "btn_sub" == senderName then

        if self.m_machine then
            if self.m_machine.m_Bonus1ActNode then
                local childs = self.m_machine.m_Bonus1ActNode:getChildren() 
                if childs and #childs > 0 then
                    isCanClick = false
                end
            end
        end

       
    elseif "btn_MaxBet" == senderName or "btn_MaxBet1" == senderName then

        if self.m_machine then
            if self.m_machine.m_Bonus1ActNode then
                local childs = self.m_machine.m_Bonus1ActNode:getChildren() 
                if childs and #childs > 0 then
                    isCanClick = false
                end
            end
        end
    end

    if isCanClick then
        FloweryPixieGameBottomNode.super.clickFunc(self,sender)
    end
    

    
end



return FloweryPixieGameBottomNode