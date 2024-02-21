---
--xcyy
--2018年5月23日
--PussCollectLoadingBarView.lua

local PussCollectLoadingBarView = class("PussCollectLoadingBarView",util_require("base.BaseView"))


function PussCollectLoadingBarView:initUI()

    self:createCsbNode("Puss_jindutiao_loading.csb")

    self.PROGRESS_WIDTH = self:findChild("Panel_1"):getContentSize().width
    
end


function PussCollectLoadingBarView:onEnter()
 

end

function PussCollectLoadingBarView:setPercent(percent)
    self:findChild("Puss_jindu_coins_1"):setPositionX(self.PROGRESS_WIDTH * percent * 0.01)
end

function PussCollectLoadingBarView:updatePercent(percent)
    self:findChild("Puss_jindu_coins_1"):stopAllActions()
    self:runCsbAction("actionframe")
    self:findChild("Puss_jindu_coins_1"):runAction(cc.MoveTo:create(0.5, cc.p(self.PROGRESS_WIDTH * percent * 0.01, 4)))
end

function PussCollectLoadingBarView:onExit()
 
end




return PussCollectLoadingBarView