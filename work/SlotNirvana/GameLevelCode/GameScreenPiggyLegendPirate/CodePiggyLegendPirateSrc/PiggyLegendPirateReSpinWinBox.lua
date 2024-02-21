---
--xcyy
--2018年5月23日
--PiggyLegendPirateReSpinWinBox.lua

local PiggyLegendPirateReSpinWinBox = class("PiggyLegendPirateReSpinWinBox",util_require("base.BaseView"))

function PiggyLegendPirateReSpinWinBox:onExit()
    PiggyLegendPirateReSpinWinBox.super.onExit(self)

    self:stopUpDateCoins()
end

function PiggyLegendPirateReSpinWinBox:initUI()
    self:createCsbNode("PiggyLegendPirate_basebaoxiang.csb")

    self.m_respinBoxSpine = util_spineCreate("PiggyLegendPirate_box", true, true)
    self:findChild("Node_baoxiang"):addChild(self.m_respinBoxSpine)
    

    self.m_respinTotalWin = util_createAnimation("PiggyLegendPirate_respintotalwin.csb")
    self:findChild("Node_respintotalwin"):addChild(self.m_respinTotalWin)
    self.m_curWinCoins   = 0
    self.m_labelWinCoins = 0
end

--[[
    show -> idle -> over
]]
function PiggyLegendPirateReSpinWinBox:playStartAnim()
    self:setVisible(true)
    self:playIdleAnim()
end

function PiggyLegendPirateReSpinWinBox:playIdleAnim()
    util_spinePlay(self.m_respinBoxSpine,"idleframe",true)
    self:runCsbAction("idleframe",true)
end

function PiggyLegendPirateReSpinWinBox:playOverAnim()
    self.m_curWinCoins   = 0
    self.m_labelWinCoins = 0
    self:setVisible(false)
end

--[[
    赢钱相关
]]
function PiggyLegendPirateReSpinWinBox:collectWinCoins(_winCoins, isPlay, isJackpot)
    self:stopUpDateCoins()
    self:updateWinCoinsLabel(self.m_curWinCoins)
    if isPlay then
        if isJackpot then
            gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_respin_jackpot_fly_end.mp3")
        else
            gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_respin_jinbi_fly_end.mp3")
        end
        self:runCsbAction("actionframe",false,function()
            self:runCsbAction("idleframe",false)
        end)

        util_spinePlay(self.m_respinBoxSpine,"actionframe",false)
        util_spineEndCallFunc(self.m_respinBoxSpine, "actionframe", function()
            util_spinePlay(self.m_respinBoxSpine, "idleframe", true)
        end)
    end

    self.m_curWinCoins   = self.m_curWinCoins + _winCoins

    self:jumpCoins(self.m_curWinCoins, self.m_labelWinCoins)
end

function PiggyLegendPirateReSpinWinBox:updateWinCoinsLabel(_winCoins)
    self.m_labelWinCoins = _winCoins
    self.m_curWinCoins = _winCoins
    local sCoins = util_formatCoins(_winCoins, 50)
    local label  = self.m_respinTotalWin:findChild("m_lb_coins")
    label:setString(sCoins)
    self:updateLabelSize({label=label,sx=0.85,sy=0.85}, 270)
end

function PiggyLegendPirateReSpinWinBox:jumpCoins(coins, _curCoins)
    local curCoins    = _curCoins or 0
    -- 每秒60帧
    local coinRiseNum =  (coins - _curCoins) / (1 * 60)  

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local node = self.m_respinTotalWin:findChild("m_lb_coins")
    --  数字上涨音效
    -- self.m_soundId = gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_jackpotView_jumpCoin.mp3",true)
    

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < coins and curCoins or coins
        
        -- self:updateWinCoinsLabel(curCoins)
        local sCoins = util_formatCoins(curCoins, 50)
        local label  = self.m_respinTotalWin:findChild("m_lb_coins")
        label:setString(sCoins)
        self:updateLabelSize({label=label,sx=0.85,sy=0.85}, 270)

        if curCoins >= coins then
            self:stopUpDateCoins()
        end
    end,0.008)
end

function PiggyLegendPirateReSpinWinBox:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
    end
    
    if self.m_soundId then
        -- gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_jackpotView_jumpCoinStop.mp3")
        
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

return PiggyLegendPirateReSpinWinBox