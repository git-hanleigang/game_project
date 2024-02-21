---
--island
--2018年6月5日
--FortuneBrickBonusWinView.lua

local FortuneBrickBonusWinView = class("FortuneBrickBonusWinView", util_require("base.BaseView"))

function FortuneBrickBonusWinView:initUI(data)

    local resourceFilename="Socre_FortuneBrick_Top.csb"
    self:createCsbNode(resourceFilename)
    
    -- self.m_lightAction = util_createView("CodeFortuneBrickSrc.FortuneBrickBonusWinAction")
    -- self:findChild("Node_Top_2"):addChild(self.m_lightAction)

    self:runCsbAction("init",false,function(  )
        
        self:runCsbAction("animation0",true)
        -- self.m_lightAction:showAction(nil,true)
    end)
    

    
    
end

function FortuneBrickBonusWinView:onEnter()
    
    -- body
end



function FortuneBrickBonusWinView:setFadeInAction()
    self.m_csbNode:runAction(cc.FadeIn:create(1))
end

---
-- 显示收集赢钱效果和数量
--
function FortuneBrickBonusWinView:showCollectCoin(winCoin)
    local score = util_formatCoins(winCoin,20) 

    self:runCsbAction("SettlementStart")
    --performWithDelay(self,function()
        self:updateLabelSize({label=self:findChild("m_lb_coin"),sx=1,sy=1},549)
        self:findChild("m_lb_coin"):setString(score) 
    --end, 0.1 )
    
end

---
-- 显示开始收集
--
function FortuneBrickBonusWinView:showStartCollect(func)
    self:findChild("m_lb_coin"):setString("")
    self:runCsbAction("Start",false,func)
end
---
-- 显示结束收集
--
function FortuneBrickBonusWinView:showOverCollect(func)
    self:runCsbAction("Over",false,func)
end



function FortuneBrickBonusWinView:onExit()
    
end


return FortuneBrickBonusWinView