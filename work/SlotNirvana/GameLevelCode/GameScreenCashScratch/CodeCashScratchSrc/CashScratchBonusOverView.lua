local CashScratchBonusOverView = class("CashScratchBonusOverView",util_require("Levels.BaseLevelDialog"))

function CashScratchBonusOverView:onExit()
    CashScratchBonusOverView.super.onExit(self)
    self:stopUpDateCoins()

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

--[[
    _initData = {
        isSecondView = nil,
        count = 0,
        coins = 0,
    }
]]
function CashScratchBonusOverView:initUI(_initData)
    self.m_initData = _initData

    self.m_allowClick = false
    
    self:createCsbNode("CashScratch/CardBonusOver.csb")

    self:findChild("m_lb_coins"):setString("0")

    self:jumpCoins(self.m_initData.coins)
end

--点击回调
function CashScratchBonusOverView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    local name = sender:getName()

    if name == "Button_collect" then
        self:clickCollectBtn(sender)
    end
end

function CashScratchBonusOverView:clickCollectBtn(_sender)
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setFinalWinCoins()
    else
        self.m_allowClick = false
        self:playOverAnim()
    end

end


function CashScratchBonusOverView:initViewData(...)
     self:runCsbAction("start", false, function()
         self:runCsbAction("idle", true)
    end)
end

function CashScratchBonusOverView:jumpCoins(coins)
    local coinRiseNum =  coins / (4 * 60)

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0

    local node=self:findChild("m_lb_coins")
    --  数字上涨音效
    if self.m_initData.isSecondView then
        self.m_soundId = gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_bonusView_jumpCoin.mp3",true)
    end

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum

        curCoins = curCoins < coins and curCoins or coins
        node:setString(util_formatCoins(curCoins,50))
        self:updateLabelSize({label=node,sx=1,sy=1},548)

        if curCoins >= coins then
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            self:stopUpDateCoins()
        end
    end,0.008)
end

function CashScratchBonusOverView:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil

        if self.m_initData.isSecondView then
            gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_bonusView_jumpCoinStop.mp3")
        end
    end
end

function CashScratchBonusOverView:setFinalWinCoins()
    if not self.m_initData then
        return
    end
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(self.m_initData.coins,50))
    self:updateLabelSize({label=labCoins,sx=1,sy=1},548)
end



function CashScratchBonusOverView:playOverAnim()
    if self.m_btnClickFunc then
        self.m_btnClickFunc()
        self.m_btnClickFunc = nil
    end

    self:runCsbAction("over", false)

    -- 放在自身的延时动作内，防一手 m_overRuncallfunc 内有移除当前节点或当前节点的父节点操作
    performWithDelay(
        self,
        function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end
    
            self:removeFromParent()
        end,
        32/60
    )

end

--[[
    模仿一下 BaseDialog 的点击结束流程
]]
function CashScratchBonusOverView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end
function CashScratchBonusOverView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

return CashScratchBonusOverView