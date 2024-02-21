
local GameBottomNode = require "views.gameviews.GameBottomNode"

local KittysCatchGameBottomNode = class("KittysCatchGameBottomNode", util_require("views.gameviews.GameBottomNode"))

--重写
function KittysCatchGameBottomNode:playCoinWinEffectUI(callBack)
    KittysCatchGameBottomNode.super.playCoinWinEffectUI(self, callBack)
    
    -- if self.coinBottomEffectNode then
    --     local numRootNode = util_getChildByName(self.coinBottomEffectNode, "Node_1")
    --     if numRootNode then
            
    --         local upNumLabel = util_getChildByName(numRootNode, "upNumLabel")
    --         if not upNumLabel then
    --             upNumLabel = util_createAnimation("KittysCatch_totalwinshuzi.csb")
    --             numRootNode:addChild(upNumLabel, 10)
    --             upNumLabel:setName("upNumLabel")
    --             upNumLabel:setPosition(cc.p(0, 0))

    --             util_setCascadeOpacityEnabledRescursion(numRootNode, true)
    --         end
    --         upNumLabel:findChild("m_lb_num"):setString("+" .. util_formatCoins(self.m_machine:getEatFishTotalWinNum(), 50))
    --     end
    -- end
    
end

function KittysCatchGameBottomNode:getCoinsShowTimes(winCoin)
    if self.m_winJumpTimesFixed == nil then
        self.m_winJumpTimesFixed = false
    end

    if self.m_winJumpTimesFixed == true then
        return 0.2
    end

    return KittysCatchGameBottomNode.super.getCoinsShowTimes(self, winCoin)

end

function KittysCatchGameBottomNode:setCoinsShowTimesIsFixed(_isFixed)
    self.m_winJumpTimesFixed = _isFixed
end

return  KittysCatchGameBottomNode