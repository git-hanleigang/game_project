---
--island
--2018年4月12日
--DragonParadeJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local DragonParadeJackPotWinView = class("DragonParadeJackPotWinView", util_require("Levels.BaseLevelDialog"))

DragonParadeJackPotWinView.BtnName = "Button_1"

function DragonParadeJackPotWinView:onEnter()
    DragonParadeJackPotWinView.super.onEnter(self)

end
function DragonParadeJackPotWinView:onExit()
    self:stopUpDateCoins()

    DragonParadeJackPotWinView.super.onExit(self)
end

function DragonParadeJackPotWinView:initUI(_initData)

    self:createCsbNode("DragonParade/JackpotWinView.csb")

    local light = util_createAnimation("DragonParade_tanban_guang.csb")
    self:findChild("guang"):addChild(light)
    light:runCsbAction("idleframe", true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("guang"), true)
end

-- 弹板入口 刷新
function DragonParadeJackPotWinView:initViewData(_data)
    --[[
        _data = {
            coins   = 0,
            index   = 1,
            machine = machine,
        }
    ]]
    self.m_data = _data

    self:createGrandShare(_data.machine)
    self:setWinCoinsLab(0)

    -- self.m_popupSpine = util_spineCreate("Socre_PalaceWish_tanban", true, true)
    -- self:findChild("spine_ren"):addChild(self.m_popupSpine)
    -- if _data.index == 1 then
    --     self.m_popupSpine:setSkin("jackpot_grand")
    -- elseif _data.index == 2 then
    --     self.m_popupSpine:setSkin("jackpot_major")
    -- elseif _data.index == 3 then
    --     self.m_popupSpine:setSkin("jackpot_minor")
    -- end
    -- util_setCascadeOpacityEnabledRescursion(self:findChild("spine_ren"), true)

    local num = 1
    if _data.index >= 1 and _data.index <= 4 then
        num = _data.index
    end 

    local str = {"grand", "major", "minor", "mini"}
    for i=1,4 do
        self:findChild("di_" .. i):setVisible(i == num)
        self:findChild(str[i]):setVisible(i == num)
    end
    self.m_bgSoundId =  gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_jackpot_popup_" .. num .. ".mp3",false)


    self.m_allowClick = false
    self:runCsbAction("start", false, function()
        self.m_allowClick = true
        self:runCsbAction("idle", true)
    end)
    --spine start
    -- util_spinePlay(self.m_popupSpine, "JackpotOver_start", false)
    -- local spineEndCallFunc = function()
    --     util_spinePlay(self.m_popupSpine, "JackpotOver_idle", true)
    -- end
    -- util_spineEndCallFunc(self.m_popupSpine, "JackpotOver_start", spineEndCallFunc)

    self:jumpCoins(self.m_data.coins, 0)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(_data.coins, _data.index)
end
--跳钱
function DragonParadeJackPotWinView:jumpCoins(_targetCoins)
    -- 每秒60帧
    local coinRiseNum =  _targetCoins / (4 * 60)  
    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0

    local node = self:findChild("m_lb_coins")
    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_jackpotView_jumpCoins.mp3", true)

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
            self:jumpCoinsFinish()
        end
    end,0.008)
end

function DragonParadeJackPotWinView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=1.02,sy=1}, 631)
end

--点击回调
function DragonParadeJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    if self:checkShareState() then
        return
    end

    self:clickCollectBtn(sender)
end
function DragonParadeJackPotWinView:clickCollectBtn(_sender)
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_click.mp3")

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setWinCoinsLab(self.m_data.coins)
        self:jumpCoinsFinish()
    else
        self:playOverAnim()
    end
end

function DragonParadeJackPotWinView:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_jackpotView_jumpCoins_Over.mp3")
    end
end

function DragonParadeJackPotWinView:playOverAnim()
    self:findChild("Button_1"):setEnabled(false)
    self.m_allowClick = false

    self:jackpotViewOver(function()
        self:stopAllActions()

        if self.m_btnClickFunc then
            self.m_btnClickFunc()
            self.m_btnClickFunc = nil
        end

        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_jackpotView_Over.mp3")

        self:runCsbAction("over", false)
        local overTime = util_csbGetAnimTimes(self.m_csbAct, "over")
        performWithDelay(self,function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end
    
            self:removeFromParent()
        end,overTime)
    end)
end


--[[
    点击回调 和 结束回调
]]
function DragonParadeJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function DragonParadeJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function DragonParadeJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function DragonParadeJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_data.index)
    end

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_data.coins,self.m_data.index)
end

function DragonParadeJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function DragonParadeJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return DragonParadeJackPotWinView