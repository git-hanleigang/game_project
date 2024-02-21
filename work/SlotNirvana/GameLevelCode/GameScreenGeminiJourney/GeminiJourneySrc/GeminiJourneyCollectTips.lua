---
--xcyy
--2018年5月23日
--GeminiJourneyCollectTips.lua
local PublicConfig = require "GeminiJourneyPublicConfig"
local GeminiJourneyCollectTips = class("GeminiJourneyCollectTips",util_require("Levels.BaseLevelDialog"))

function GeminiJourneyCollectTips:initUI(_collectBar, _machine)

    self:createCsbNode("GeminiJourney_RespinCounter_Tips.csb")
    self:runCsbAction("idle", true)
    self:setVisible(false)

    self.m_collectBar = _collectBar
    self.m_machine = _machine
    self.m_isExplainClick = true

    self.m_btnText = self:findChild("m_lb_coins")
end

--默认按钮监听回调
function GeminiJourneyCollectTips:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" and self.m_isExplainClick then
        if self.m_machine:tipsBtnIsCanClick() then
            if self.m_machine.m_iBetLevel == 0 then
                if globalData.betFlag then
                    self.m_machine.m_bottomUI:changeBetCoinNumToUnLock(1)
                end
            else
                -- self.m_isExplainClick = false
                -- self:showTips()
            end
        end
    end
end

function GeminiJourneyCollectTips:setHighBetLevelCoins(_highBetLevelCoins)
    local strCoins = util_formatCoins(_highBetLevelCoins, 50)
    self.m_btnText:setString(strCoins)
    self:updateLabelSize({label=self.m_btnText, sx=1.0, sy=1.0}, 180)  
end

function GeminiJourneyCollectTips:showTips(_onEnter)
    util_resetCsbAction(self.m_csbAct)
    self:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_BetPlay_Show)
    self:runCsbAction("start",false, function()
        self.m_isExplainClick = true
        self:runCsbAction("idle",true)
    end)
end

function GeminiJourneyCollectTips:closeTips()
    util_resetCsbAction(self.m_csbAct)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_BetPlay_Close)
    self:runCsbAction("over",false, function()
        self.m_isExplainClick = false
        self:setVisible(false)
    end)
end

return GeminiJourneyCollectTips
