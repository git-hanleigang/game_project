--[[
    reSpin的棋盘顶部结算栏
]]
local NutCarnivalWinnerBar = class("NutCarnivalWinnerBar",util_require("Levels.BaseLevelDialog"))

function NutCarnivalWinnerBar:initUI(_machine)
    self.m_machine = _machine
    self.m_feedbackAnimList = {}
    
    self:createCsbNode("NutCarnival_respin_winner.csb")

    self.m_winCoins    = 0
    self.m_targetCoins = 0
    self.m_labelCoins  = self:findChild("m_lb_coins")
end

function NutCarnivalWinnerBar:resetUi()
    self:setWinCoinsLab(0)
end

--跳钱
function NutCarnivalWinnerBar:jumpCoins(_targetCoins, _time)
    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setWinCoinsLab(self.m_targetCoins)
    end
    self.m_targetCoins = _targetCoins

    local coinRiseNum  =  (_targetCoins - self.m_winCoins) / (_time * 60)  
    local sCoinRiseNum = tostring(coinRiseNum)
    local sCoinRiseNum = string.gsub(sCoinRiseNum,"0",math.random( 1, #sCoinRiseNum))
    coinRiseNum = tonumber(sCoinRiseNum)
    coinRiseNum = math.ceil(coinRiseNum) 

    local curCoins = self.m_winCoins

    local node = self.m_labelCoins
    --  数字上涨音效
    -- self.m_soundId = gLobalSoundManager:playSound("NutCarnivalSounds/sound_NutCarnival_jackpotView_jumpCoins.mp3", true)

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < _targetCoins and curCoins or _targetCoins

        self:setWinCoinsLab(curCoins)
        if curCoins >= _targetCoins then
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            self:stopUpDateCoins()
        end
    end,0.008)
end

function NutCarnivalWinnerBar:setWinCoinsLab(_winCoins)
    self.m_winCoins = _winCoins
    local sCoins = _winCoins > 0 and util_formatCoins(_winCoins, 50) or ""
    self.m_labelCoins:setString(sCoins)
    self:upDateWinnerBarLabelSize(self.m_labelCoins)
end
function NutCarnivalWinnerBar:upDateWinnerBarLabelSize(_label)
    self:updateLabelSize({label=_label,sx=1,sy=1}, 305)
end
function NutCarnivalWinnerBar:getCurWinCoins()
    if self.m_updateAction ~= nil then
        return self.m_targetCoins
    else
        return self.m_winCoins
    end
end

function NutCarnivalWinnerBar:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        -- gLobalSoundManager:playSound(NutCarnivalPublicConfig.sound_NutCarnival_jackpotView_jumpCoinsOver)
    end
end
--收集反馈
function NutCarnivalWinnerBar:playCollectFeedbackAnim()
    local feedbackAnim = self:createCollectFeedbackAnim()
    feedbackAnim:runCsbAction("fankui2", false, function()
        feedbackAnim:setVisible(false)
        table.insert(self.m_feedbackAnimList, feedbackAnim)
    end)
    return 48/60
end
function NutCarnivalWinnerBar:createCollectFeedbackAnim()
    local feedbackAnim = nil
    if #self.m_feedbackAnimList > 0 then
        feedbackAnim = table.remove(self.m_feedbackAnimList, 1)
        feedbackAnim:setVisible(true)
    end
    if not feedbackAnim then
        feedbackAnim = util_createAnimation("NutCarnival_fankui.csb")
        self:addChild(feedbackAnim, 10)
    end
    return feedbackAnim
end

--[[
    时间线
]]
function NutCarnivalWinnerBar:playStartAnim(_fun)
    self:runCsbAction("chuxian", false, _fun)
end
function NutCarnivalWinnerBar:playOverAnim(_fun)
    self:runCsbAction("xiaoshi", false, _fun)
end

return NutCarnivalWinnerBar