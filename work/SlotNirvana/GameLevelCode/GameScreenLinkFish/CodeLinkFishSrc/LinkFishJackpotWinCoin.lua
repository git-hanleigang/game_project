---
--island
--2018年6月5日
--LinkFishJackpotWinCoin.lua

local LinkFishJackpotWinCoin = class("LinkFishJackpotWinCoin", util_require("base.BaseView"))

function LinkFishJackpotWinCoin:initUI(data)

    local resourceFilename="Socre_LinkFish_Chip_Light_big.csb"
    self:createCsbNode(resourceFilename)

    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)
    self:findChild("m_lb_coin"):setString("0")
end

function LinkFishJackpotWinCoin:onEnter()
    self:runCsbAction("jiesuan")
    self:findChild("m_lb_coin"):setString("0")
    -- body
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function LinkFishJackpotWinCoin:setFadeInAction()
    self.m_csbNode:runAction(cc.FadeIn:create(1))
end

---
-- 显示收集赢钱效果和数量
--
function LinkFishJackpotWinCoin:showCollectCoin(winCoin)

    self:runCsbAction("link_tip",false,function()
        self:runCsbAction("jiesuan",true)
    end)                    

    self:updateLabelSize({label=self:findChild("m_lb_coin"),sx=0.8,sy=0.8},590)
    self:findChild("m_lb_coin"):setString(winCoin)

    

end

function LinkFishJackpotWinCoin:onExit()

end


return LinkFishJackpotWinCoin