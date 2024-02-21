---
--island
--2018年4月12日
--MagneticBreakInJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local MagneticBreakInJackPotWinView = class("MagneticBreakInJackPotWinView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MagneticBreakInPublicConfig"

MagneticBreakInJackPotWinView.BtnName = "Button_collect"

function MagneticBreakInJackPotWinView:onEnter()
    MagneticBreakInJackPotWinView.super.onEnter(self)

end
function MagneticBreakInJackPotWinView:onExit()
    self:stopUpDateCoins()

    MagneticBreakInJackPotWinView.super.onExit(self)
end

function MagneticBreakInJackPotWinView:initUI(_initData)
    --[[
        _initData = {
        }
    ]]

    self:createCsbNode("MagneticBreakIn/JackpotWinView.csb")
end

-- 根据jackpot类型刷新展示
function MagneticBreakInJackPotWinView:upDateJackPotShow()
    local JackPotNodeName = {
        [1] = {},
        [2] = {"di_mega","di_mega0"},
        [3] = {"di_major","di_major_0"},
        [4] = {"di_minor","di_minor0"},
        [5] = {"di_mini","di_mini_0"},
    }
    local JackPotZiName = {
        [1] = "",
        [2] = "mega",
        [3] = "major",
        [4] = "minor",
        [5] = "mini",
    }
    for _jpIndex,_nodeName in ipairs(JackPotZiName) do
        local isVisible = _jpIndex == self.m_data.index
        local jpNode = self:findChild(_nodeName)
        if jpNode then
            jpNode:setVisible(isVisible)
        end
    end

    for _jpIndex,_nodeName in ipairs(JackPotNodeName) do
        local isVisible = _jpIndex == self.m_data.index
        local jpNode1 = self:findChild(_nodeName[1])
        local jpNode2 = self:findChild(_nodeName[2])
        if jpNode1 and jpNode2 then
            jpNode1:setVisible(isVisible)
            jpNode2:setVisible(isVisible)
        end 
    end
    local lighting = util_createAnimation("MagneticBreakIn_tanban_guang.csb")
    self:findChild("Node_guang"):addChild(lighting)
    lighting:runCsbAction("idle",true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_guang"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_guang"), true)
end

function MagneticBreakInJackPotWinView:showJackpotSoundForIndex()
    if self.m_data.index == 5 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_jackpot_mini_show)
    elseif self.m_data.index == 4 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_jackpot_minor_show)
    elseif self.m_data.index == 4 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_jackpot_major_show)
    elseif self.m_data.index == 4 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_jackpot_mega_show)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_jackpot_mini_show)
    end
end

-- 弹板入口 刷新
function MagneticBreakInJackPotWinView:initViewData(_data)
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
    self:upDateJackPotShow()
    self:setWinCoinsLab(0)

    self.m_allowClick = false
    
    self:findChild("m_lb_num"):setVisible(true)
    if self.multiple == 0 then
        self:findChild("m_lb_num"):setString("")
    else
        self:findChild("m_lb_num"):setString("X"..self.multiple)
    end
    --人物
    self.jvese = util_spineCreate("Socre_MagneticBreakIn_9", true, true)
    self:findChild("spine"):addChild(self.jvese)
    self:showJackpotSoundForIndex()
    util_spinePlay(self.jvese, "JackpotWinView_start")
    self:runCsbAction("start", false, function()
        self.m_allowClick = true
        util_spinePlay(self.jvese, "JackpotWinView_idle",true)
        self:runCsbAction("idle", true)
    end)

    self:jumpCoins(self.m_data.coins, 0)
    
end
--跳钱
function MagneticBreakInJackPotWinView:jumpCoins(_targetCoins)
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
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            self.m_allowClick = false
            self:stopUpDateCoins()
            self:jumpCoinsFinish()
            self:showActionframeForMultiple()
        end
    end,0.008)
end

function MagneticBreakInJackPotWinView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=1,sy=1}, 637)
end

--点击回调
function MagneticBreakInJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    if self:checkShareState() then
        return
    end

    self:clickCollectBtn(sender)
end
function MagneticBreakInJackPotWinView:clickCollectBtn(_sender)
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
function MagneticBreakInJackPotWinView:showActionframeForMultiple(func)
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

function MagneticBreakInJackPotWinView:stopUpDateCoins()
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

function MagneticBreakInJackPotWinView:playOverAnim()
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
        util_spinePlay(self.jvese, "JackpotWinView_over")
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
function MagneticBreakInJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function MagneticBreakInJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function MagneticBreakInJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function MagneticBreakInJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_data.index)
    end
end

function MagneticBreakInJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function MagneticBreakInJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

--[[
    延迟回调
]]
function MagneticBreakInJackPotWinView:delayCallBack(time, func)
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

return MagneticBreakInJackPotWinView

