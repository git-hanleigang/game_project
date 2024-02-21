--
-- 气泡下UI
-- Author:{author}
-- Date: 2018-12-22 16:34:48

local GameBottomNode = require "views.gameviews.GameBottomNode"

local MiracleEgyptGameBottomNode = class("MiracleEgyptGameBottomNode", util_require("views.gameviews.GameBottomNode"))

function MiracleEgyptGameBottomNode:setMachine(machine )
    self.m_machine = machine
end

function MiracleEgyptGameBottomNode:updateBetCoin(isLevelUp)

    GameBottomNode.updateBetCoin(self,isLevelUp)

    if globalData.slotRunData.iLastBetIdx ~= nil then
        if isLevelUp ~= true then
            self.m_machine:betChangeUpdateBubbleNode()
        end
        self.m_machine:updateBetInfo()
    end



end

function MiracleEgyptGameBottomNode:updateBetEnable(flag)

    local flag = MiracleEgyptGameBottomNode.super.updateBetEnable(self,flag)
    if self.m_machine.m_BetChoseView then
        self.m_machine.m_BetChoseView:findChild("Button_Activeae"):setBright(flag)
        self.m_machine.m_BetChoseView:findChild("Button_Activeae"):setTouchEnabled(flag)
    end


end

---
-- 增加堵住筹码
function MiracleEgyptGameBottomNode:addBetCoinNum()


    self.m_machine.m_oldBetID = globalData.slotRunData.iLastBetIdx

    MiracleEgyptGameBottomNode.super.addBetCoinNum(self)

end
---
-- 减少赌注筹码
function MiracleEgyptGameBottomNode:subBetCoinNum()

    self.m_machine.m_oldBetID = globalData.slotRunData.iLastBetIdx

    MiracleEgyptGameBottomNode.super.subBetCoinNum(self)

end
function MiracleEgyptGameBottomNode:maxBetCoinNum()

    if globalData.slotRunData.iLastBetIdx ==nil then
        self.m_machine.m_oldBetID = 1
    else
        self.m_machine.m_oldBetID = globalData.slotRunData.iLastBetIdx
    end

     

    MiracleEgyptGameBottomNode.super.maxBetCoinNum(self)
end


return  MiracleEgyptGameBottomNode