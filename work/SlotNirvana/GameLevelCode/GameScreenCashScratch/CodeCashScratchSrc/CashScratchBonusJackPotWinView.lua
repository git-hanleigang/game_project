local CashScratchBonusJackPotWinView = class("CashScratchBonusJackPotWinView",util_require("Levels.BaseLevelDialog"))

function CashScratchBonusJackPotWinView:onExit()
    CashScratchBonusJackPotWinView.super.onExit(self)
    self:stopUpDateCoins()

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

--[[
    _initData = {
        isSecondView = true,
        machine = machine,
        cardSymbolType = 0,
        coins = 0,
    }
]]
function CashScratchBonusJackPotWinView:initUI(_initData)
    self.m_initData = _initData
    self.m_machine  = _initData.machine
    self.m_jackpotIndex = _initData.jockPotIndex

    self.m_allowClick = false

    self:createCsbNode("CashScratch/JackpotWinView_card.csb")

    self:findChild("m_lb_coins"):setString("0")
    self:jumpCoins(self.m_initData.coins)
    self:upDateWinType()

    if _initData.isSecondView then
        self:createGrandShare(self.m_machine)
    end
end

--点击回调
function CashScratchBonusJackPotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end
    if not self.m_allowClick then
        return
    end

    local name = sender:getName()

    if name == "Button_collect" then
        self:clickCollectBtn(sender)
    end
end


--[[
    根据信号刷新顶部展示
]]
function CashScratchBonusJackPotWinView:upDateWinType()
    local icon1x = self:findChild("1x")
    local icon2x = self:findChild("2x")
    local icon3x = self:findChild("3x")
    local icon5x = self:findChild("5x")
    local icon2x3x5x = self:findChild("2x3x5x")
    local cards  = self:findChild("cards")
    

    local cardSymbolType = self.m_initData.cardSymbolType

    icon1x:setVisible(cardSymbolType== self.m_machine.SYMBOL_Bonus_1)
    icon2x:setVisible(cardSymbolType== self.m_machine.SYMBOL_Bonus_2)
    icon3x:setVisible(cardSymbolType== self.m_machine.SYMBOL_Bonus_3)
    icon5x:setVisible(cardSymbolType== self.m_machine.SYMBOL_Bonus_4)
    icon2x3x5x:setVisible(cardSymbolType== self.m_machine.SYMBOL_Bonus_5)
    cards:setVisible(cardSymbolType ~= self.m_machine.SYMBOL_Bonus_5)
end

function CashScratchBonusJackPotWinView:initViewData(...)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
   end)
end

function CashScratchBonusJackPotWinView:jumpCoins(coins)
    local coinRiseNum =  coins / (4 * 60)

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0

    local node=self:findChild("m_lb_coins")
    --  数字上涨音效
    if self.m_initData.isSecondView then
        self.m_soundId = gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_jackpot_jumpCoin.mp3",true)
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
            self:jumpCoinsFinish()
        end
    end,0.008)
end


function CashScratchBonusJackPotWinView:clickCollectBtn(_sender)
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setFinalWinCoins()
        self:jumpCoinsFinish()
    else
        self.m_allowClick = false
        self:jackpotViewOver(function()
            self:playOverAnim()
        end)
    end

end

function CashScratchBonusJackPotWinView:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil

        if self.m_initData.isSecondView then
            gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_jackpot_jumpCoinStop.mp3")
        end
    end
end

function CashScratchBonusJackPotWinView:setFinalWinCoins()
    if not self.m_initData then
        return
    end
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(self.m_initData.coins,50))
    self:updateLabelSize({label=labCoins,sx=1,sy=1},548)
end

function CashScratchBonusJackPotWinView:playOverAnim()
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
function CashScratchBonusJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end
function CashScratchBonusJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end


--[[
    自动分享 | 手动分享
]]
function CashScratchBonusJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function CashScratchBonusJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function CashScratchBonusJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function CashScratchBonusJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return CashScratchBonusJackPotWinView