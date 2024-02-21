---
--island
--2018年4月12日
--BadgedCowboyJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local BadgedCowboyJackPotWinView = class("BadgedCowboyJackPotWinView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "BadgedCowboyPublicConfig"

BadgedCowboyJackPotWinView.BtnName = "Button_1"

function BadgedCowboyJackPotWinView:onEnter()
    BadgedCowboyJackPotWinView.super.onEnter(self)

end
function BadgedCowboyJackPotWinView:onExit()
    self:stopUpDateCoins()

    BadgedCowboyJackPotWinView.super.onExit(self)
end

function BadgedCowboyJackPotWinView:initUI(_initData)
    --[[
        _initData = {
        }
    ]]

    self:createCsbNode("BadgedCowboy/JackpotWinView.csb")

    self.m_midSpine = util_spineCreate("Socre_BadgedCowboy_9",true,true)
    self:findChild("Node_ren"):addChild(self.m_midSpine)
    util_spinePlay(self.m_midSpine, "actionframe_tanban", true)

    self.m_jackpotLight = util_createAnimation("FreeSpinOver_tb_shine.csb")
    self:findChild("Node_guang"):addChild(self.m_jackpotLight)
    self.m_jackpotLight:runCsbAction("idle", true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

-- 根据jackpot类型刷新展示
function BadgedCowboyJackPotWinView:upDateJackPotShow()
    local JackPotNodeSpName = {
        [1] = "grand",
        [2] = "major",
        [3] = "minor",
        [4] = "mini",
    }
    local JackPotKuangName = {
        [1] = "kuang_grand",
        [2] = "kuang_major",
        [3] = "kuang_minor",
        [4] = "kuang_mini",
    }
    for _jpIndex,_nodeName in ipairs(JackPotNodeSpName) do
        local isVisible = _jpIndex == self.m_data.index
        local jpNode = self:findChild(_nodeName)
        jpNode:setVisible(isVisible)
    end
    for _jpIndex,_nodeName in ipairs(JackPotKuangName) do
        local isVisible = _jpIndex == self.m_data.index
        local jpNode = self:findChild(_nodeName)
        jpNode:setVisible(isVisible)
    end
end

-- 弹板入口 刷新
function BadgedCowboyJackPotWinView:initViewData(_data, _endCallFunc)
    --[[
        _data = {
            coins   = 0,
            index   = 1,
            machine = machine,
        }
    ]]
    self.m_data = _data
    self.m_endCallFunc = _endCallFunc

    self:createGrandShare(_data.machine)
    self:upDateJackPotShow()
    self:setWinCoinsLab(0)

    local soundName = PublicConfig.Music_Jackpot_Reward[_data.index]
    if soundName then
        gLobalSoundManager:playSound(soundName)
    end

    self.m_allowClick = false
    util_spinePlay(self.m_midSpine, "actionframe_tanban", true)
    self.m_jackpotLight:runCsbAction("idle", true)
    self:runCsbAction("start", false, function()
        self.m_allowClick = true
        self:runCsbAction("idle", true)
    end)

    self:jumpCoins(self.m_data.coins, 0)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(_data.coins, _data.index)
end
--跳钱
function BadgedCowboyJackPotWinView:jumpCoins(_targetCoins)
    -- 每秒60帧
    local coinRiseNum =  _targetCoins / (4 * 60)  
    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0

    local node = self:findChild("m_lb_coins")
    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Coins)

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < _targetCoins and curCoins or _targetCoins

        self:setWinCoinsLab(curCoins)
        if curCoins >= _targetCoins then
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Stop)
            self:stopUpDateCoins()
            self:jumpCoinsFinish()
            performWithDelay(self.m_scWaitNode,function(  )
                self:playOverAnim()
            end,1.5)
        end
    end,0.008)
end

function BadgedCowboyJackPotWinView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=0.81,sy=0.81}, 773)
end

--点击回调
function BadgedCowboyJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    if self:checkShareState() then
        return
    end

    self:clickCollectBtn(sender)
end
function BadgedCowboyJackPotWinView:clickCollectBtn(_sender)
    -- gLobalSoundManager:playSound(BadgedCowboyPublicConfig.sound_BadgedCowboy_commonClick)

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setWinCoinsLab(self.m_data.coins)
        self:jumpCoinsFinish()
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Stop)
        performWithDelay(self.m_scWaitNode,function(  )
            self:playOverAnim()
        end,1.5)
    else
        self:playOverAnim()
        gLobalSoundManager:playSound(PublicConfig.Music_Normal_Click)
    end
end

function BadgedCowboyJackPotWinView:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        -- gLobalSoundManager:playSound(BadgedCowboyPublicConfig.sound_BadgedCowboy_jackpotView_jumpCoinsOver)
    end
end

function BadgedCowboyJackPotWinView:playOverAnim()
    self:findChild(self.BtnName):setEnabled(false)

    if not self.m_allowClick then
        return
    end
    self.m_allowClick = false

    self:jackpotViewOver(function()
        self:stopAllActions()

        if self.m_btnClickFunc then
            self.m_btnClickFunc()
            self.m_btnClickFunc = nil
        end
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_DialogOver)
        self:runCsbAction("over", false)
        local overTime = util_csbGetAnimTimes(self.m_csbAct, "over")
        performWithDelay(self,function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end
            if type(self.m_endCallFunc) == "function" then
                self.m_endCallFunc()
            else
                local test = 1
            end
            self:removeFromParent()
        end,overTime)
    end)
end


--[[
    点击回调 和 结束回调
]]
function BadgedCowboyJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function BadgedCowboyJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function BadgedCowboyJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function BadgedCowboyJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_data.index)
    end
end

function BadgedCowboyJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function BadgedCowboyJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return BadgedCowboyJackPotWinView

