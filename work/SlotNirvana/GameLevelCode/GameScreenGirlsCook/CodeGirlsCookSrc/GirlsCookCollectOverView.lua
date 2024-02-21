---
--xcyy
--2018年5月23日
--GirlsCookCollectOverView.lua

local GirlsCookCollectOverView = class("GirlsCookCollectOverView",util_require("base.BaseView"))


function GirlsCookCollectOverView:initUI(params)
    self.m_data = params.data
    self.m_callBack = params.callBack
    local viewType = params.viewType
    if viewType == "TIME" then
        self:createCsbNode("GirlsCook/CollectOver_time.csb")
    else
        self:createCsbNode("GirlsCook/CollectOver_spinleft_1.csb")
    end
    

    -- self:setPosition(cc.p(display.width / 2,display.height / 2))

    local collectData = self.m_data.oldCollect or self.m_data.dishCollect
    local collectWinCoin,baseWinCoins,extraWinCoins = 0,0,0
    for index = 1,3 do
        local dishData = collectData[index]
        if dishData and dishData.collectType == viewType and dishData.newCount > 0 and dishData.amount and dishData.amount > 0 then
            collectWinCoin = collectWinCoin + (dishData.amount or 0)
            baseWinCoins = baseWinCoins + (dishData.baseAmount or 0)
            extraWinCoins = extraWinCoins + (dishData.extraAmount or 0)
        end
    end

    self:findChild("m_lb_coin"):setString(util_formatCoins(baseWinCoins,50))
    self:findChild("m_lb_coin_0_0"):setString(util_formatCoins(extraWinCoins,50))
    self:findChild("m_lb_coin_0"):setString(util_formatCoins(collectWinCoin,50))

    self:updateLabelSize({label=self:findChild("m_lb_coin"),sx=1,sy=1},470)
    self:updateLabelSize({label=self:findChild("m_lb_coin_0_0"),sx=1,sy=1},374)
    self:updateLabelSize({label=self:findChild("m_lb_coin_0"),sx=1,sy=1},374)

    self.m_isClicked = true

    gLobalSoundManager:playSound("GirlsCookSounds/sound_GirlsCook_collect_over.mp3")
    self:runCsbAction("start",false,function()
        self.m_isClicked = false
        self:runCsbAction("idle",true)
    end)
end


function GirlsCookCollectOverView:onEnter()

end


function GirlsCookCollectOverView:onExit()
 
end

--默认按钮监听回调
function GirlsCookCollectOverView:clickFunc(sender)
    --防止重复点击
    if self.m_isClicked then
        return
    end
    self.m_isClicked = true
    local name = sender:getName()
    local tag = sender:getTag()

    self:runCsbAction("over",false,function()
        if type(self.m_callBack) == "function" then
            self.m_callBack()
        end
    
        self:removeFromParent()
    end)
end


return GirlsCookCollectOverView