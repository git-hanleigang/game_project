---
--island
--2018年6月5日
--HowlingMoonWonThings.lua

local HowlingMoonWonThings = class("HowlingMoonWonThings", util_require("base.BaseView"))

function HowlingMoonWonThings:initUI(data)

    local resourceFilename="Socre_HowlingMoon_Light_big.csb"
    self:createCsbNode(resourceFilename)

    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)
    
end

function HowlingMoonWonThings:onEnter()
    
    -- body
    util_setCascadeOpacityEnabledRescursion(self,true)
end



function HowlingMoonWonThings:setFadeInAction()
    self.m_csbNode:runAction(cc.FadeIn:create(1))
end

---
-- 显示收集赢钱效果和数量
--
function HowlingMoonWonThings:showCollectCoin(winCoin)
    self:runCsbAction("link_tip",false,function(  )
        
    end)
    
    self:updateLabelSize({label=self:findChild("m_lb_coin"),sx=0.8,sy=0.8},590)
    self:findChild("m_lb_coin"):setString(winCoin)
    

end



function HowlingMoonWonThings:onExit()
    
end


return HowlingMoonWonThings