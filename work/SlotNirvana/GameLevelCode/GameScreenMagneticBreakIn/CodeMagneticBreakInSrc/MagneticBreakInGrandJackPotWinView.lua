---
--island
--2018年4月12日
--MagneticBreakInGrandJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local MagneticBreakInGrandJackPotWinView = class("MagneticBreakInGrandJackPotWinView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MagneticBreakInPublicConfig"

MagneticBreakInGrandJackPotWinView.BtnName = "Button_collect"

function MagneticBreakInGrandJackPotWinView:onEnter()
    MagneticBreakInGrandJackPotWinView.super.onEnter(self)

end
function MagneticBreakInGrandJackPotWinView:onExit()
    self:stopUpDateCoins()

    MagneticBreakInGrandJackPotWinView.super.onExit(self)
end

function MagneticBreakInGrandJackPotWinView:initUI(_initData)

    self:createCsbNode("MagneticBreakIn/JackpotWinView1.csb")

    
end

-- 根据jackpot类型刷新展示
function MagneticBreakInGrandJackPotWinView:upDateJackPotShow()
    local lighting = util_createAnimation("MagneticBreakIn_tanban_guang.csb")
    self:findChild("Node_guang"):addChild(lighting)
    lighting:runCsbAction("idle",true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_guang"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_guang"), true)
end

-- 弹板入口 刷新
function MagneticBreakInGrandJackPotWinView:initViewData(_data)
    --[[
        _data = {
            coins   = 0,
            index   = 1,
            machine = machine,
        }
    ]]
    self.m_data = _data
    self.multiple = tonumber(_data.multiple)

    self:createGrandShare(_data.machine)
    self:setWinCoinsLab(0)

    self.m_allowClick = false

    self:findChild("m_lb_num"):setVisible(true)
    if self.multiple == 0 then
        self:findChild("m_lb_num"):setString("")
    else
        self:findChild("m_lb_num"):setString("X"..self.multiple)
    end
    
    --人物
    self.jvese1 = util_spineCreate("Socre_MagneticBreakIn_9", true, true)
    self.jvese2 = util_spineCreate("Socre_MagneticBreakIn_8", true, true)
    self:findChild("spine"):addChild(self.jvese1)
    self:findChild("spine"):addChild(self.jvese2)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_jackpot_grand_show)
    util_spinePlay(self.jvese1, "JackpotWinView1_start")
    util_spinePlay(self.jvese2, "jackpot_start")
    self:runCsbAction("start", false, function()
        self.m_allowClick = true
        util_spinePlay(self.jvese1, "JackpotWinView1_idle",true)
        util_spinePlay(self.jvese2, "jackpot_idle",true)
        self:runCsbAction("idle", true)
    end)

    self:jumpCoins(self.m_data.coins, 0)
    
end
--跳钱
function MagneticBreakInGrandJackPotWinView:jumpCoins(_targetCoins)
    -- 每秒60帧
    local coinRiseNum =  _targetCoins / (4 * 60)  
    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0

    local node = self:findChild("m_lb_coins")
    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_jackpot_num_jump, true)

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < _targetCoins and curCoins or _targetCoins

        self:setWinCoinsLab(curCoins)
        if curCoins >= _targetCoins then
            self.m_allowClick = false
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            self:stopUpDateCoins()
            self:jumpCoinsFinish()
            self:showActionframeForMultiple()
        end
    end,0.008)
end

function MagneticBreakInGrandJackPotWinView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=1,sy=1}, 637)
end

--点击回调
function MagneticBreakInGrandJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    if self:checkShareState() then
        return
    end

    self:clickCollectBtn(sender)
end
function MagneticBreakInGrandJackPotWinView:clickCollectBtn(_sender)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_click)

    if self.m_updateAction ~= nil then
        self.m_allowClick = false
        self:stopUpDateCoins()
        self:setWinCoinsLab(self.m_data.coins)
        self:jumpCoinsFinish()
        self:showActionframeForMultiple()
    else
        self:playOverAnim()
    end
end

--钱停下之后砸成倍
function MagneticBreakInGrandJackPotWinView:showActionframeForMultiple(func)
    if self.multiple == 0 then
        self.m_allowClick = true
        if type(func) == "function" then
            func()
        end
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_chengbei_down)
        self:runCsbAction("actionframe")
        self:delayCallBack(1,function ()
            --改变钱数
            self:setWinCoinsLab(self.m_data.coins * self.multiple)
        end)
        self:delayCallBack(95/60,function ()
            self:findChild("m_lb_num"):setString("")
            self:runCsbAction("idle", true)
            self.m_allowClick = true
            if type(func) == "function" then
                func()
            end
        end)
    end
end

--[[
    延迟回调
]]
function MagneticBreakInGrandJackPotWinView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

function MagneticBreakInGrandJackPotWinView:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_jackpot_num_jumpOver)
    end
end

function MagneticBreakInGrandJackPotWinView:playOverAnim()
    self:findChild("Button"):setEnabled(false)
    self.m_allowClick = false

    self:jackpotViewOver(function()
        self:stopAllActions()

        if self.m_btnClickFunc then
            self.m_btnClickFunc()
            self.m_btnClickFunc = nil
        end
        self:findChild("m_lb_num"):setVisible(false)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_jackpot_over)
        util_spinePlay(self.jvese1, "JackpotWinView1_over")
        util_spinePlay(self.jvese2, "jackpot_over")
        self:runCsbAction("over", false)
        local overTime = 0.5
        performWithDelay(self,function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end
            --通知jackpot
            globalData.jackpotRunData:notifySelfJackpot(self.m_data.coins, self.m_data.index)
            self:removeFromParent()
        end,overTime)
    end)
end


--[[
    点击回调 和 结束回调
]]
function MagneticBreakInGrandJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function MagneticBreakInGrandJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function MagneticBreakInGrandJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function MagneticBreakInGrandJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_data.index)
    end
end

function MagneticBreakInGrandJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function MagneticBreakInGrandJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return MagneticBreakInGrandJackPotWinView

