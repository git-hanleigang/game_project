---
--xcyy
--2018年5月23日
--CookieCrunchJackPotBar.lua

local CookieCrunchJackPotBar = class("CookieCrunchJackPotBar",util_require("CodeCookieCrunchSrc.CookieCrunchRightBar"))

local JackPotNodeName = {
    [1] = "grand",
    [2] = "major",
    [3] = "minor",
    [4] = "mini",
}
function CookieCrunchJackPotBar:onExit()
    CookieCrunchJackPotBar.super.onExit(self)

    self:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

function CookieCrunchJackPotBar:initDatas(_machine, _data)
    CookieCrunchJackPotBar.super.initDatas(self, _machine, _data)

    self.m_curCoins = 0
end

function CookieCrunchJackPotBar:initUI()
    self:createCsbNode("CookieCrunch_Jackpot.csb")

    for _jpIndex,_name in ipairs(JackPotNodeName) do
        local visible = _jpIndex == self.m_initData.jpIndex
        self:findChild(string.format("%s", _name)):setVisible(visible)
        local labBase = self:findChild(string.format("m_lb_%s_base", _name))
        local labFree = self:findChild(string.format("m_lb_%s_free", _name))
        local labWin  = self:findChild(string.format("m_lb_%s_win", _name))
        labBase:setVisible(visible)
        labFree:setVisible(visible)
        labWin:setVisible(visible)
        if visible then
            self.m_lab_base = labBase
            self.m_lab_free = labFree
            self.m_lab_win  = labWin
        end
    end
end

--[[
    状态相关
]]
function CookieCrunchJackPotBar:upDateFinishStateAnim(_playAnim)
    if _playAnim then
        local animName = self.m_finishState and "liang" or "mie"
        self:runCsbAction(animName, false)
    else
        local animName = self.m_finishState and "idle2" or "idle1"
        self:runCsbAction(animName, false)
    end

    self.m_lab_win:setVisible(self.m_finishState) 
    if self.m_finishState then
        self.m_lab_base:setVisible(false) 
        self.m_lab_free:setVisible(false) 
    else
        self.m_lab_base:setVisible(self.MODEL.BASE == self.m_model) 
        self.m_lab_free:setVisible(self.MODEL.FREE == self.m_model) 
    end
end
--[[
    模式相关
]]
function CookieCrunchJackPotBar:upDateModelAnim(_playAnim)
    -- if _playAnim then
    -- else
    -- end

    if self.m_finishState then
        self.m_lab_base:setVisible(false) 
        self.m_lab_free:setVisible(false) 
    else
        self.m_lab_base:setVisible(self.MODEL.BASE == self.m_model) 
        self.m_lab_free:setVisible(self.MODEL.FREE == self.m_model) 
    end
end

-- 更新jackpot 数值信息
function CookieCrunchJackPotBar:updateJackpotInfo(_value, _playAnim)
    if not _playAnim then
        self.m_curCoins = _value
        self.m_lab_base:setString(util_formatCoins(_value, 3))
        self.m_lab_free:setString(util_formatCoins(_value, 3))
        self.m_lab_win:setString(util_formatCoins(_value, 3))
    else
        self:jumpCoins(_value)
    end
    self:updateSize()
end
function CookieCrunchJackPotBar:updateSize()
    local scaleList = {
        1,
        0.95,
        0.87,
        0.8
    }
    local scale = scaleList[self.m_initData.jpIndex]
    self:updateLabelSize({label=self.m_lab_base,sx=scale,sy=scale}, 135)
    self:updateLabelSize({label=self.m_lab_free,sx=scale,sy=scale}, 135)
    self:updateLabelSize({label=self.m_lab_win,sx=scale,sy=scale}, 135)
end

function CookieCrunchJackPotBar:jumpCoins(coins, _curCoins)
    if nil ~= self.m_updateAction then
        self:stopUpDateCoins()
    end
    -- 每秒60帧
    local time = 0.5
    local coinRiseNum =  coins / (time * 60)  

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum) 

    local curCoins = self.m_curCoins
    --  数字上涨音效
    -- self.m_soundId = gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_jackpotView_jumpCoin.mp3",true)
    

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < coins and curCoins or coins

        self:updateJackpotInfo(curCoins, false)
        if curCoins >= coins then
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            self:stopUpDateCoins()
        end
    end,0.008)
end
function CookieCrunchJackPotBar:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil

        -- gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_jackpotView_jumpCoinStop.mp3")
    end
end


function CookieCrunchJackPotBar:playWinAnim(_fun)
    self:runCsbAction("win")

    local animTime = 1.5
    self.m_machine:levelPerformWithDelay(animTime, function()
        _fun()
    end)
end

return CookieCrunchJackPotBar