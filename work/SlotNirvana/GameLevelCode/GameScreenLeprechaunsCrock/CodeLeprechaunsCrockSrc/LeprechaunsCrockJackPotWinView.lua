---
--island
--2018年4月12日
--LeprechaunsCrockJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local LeprechaunsCrockJackPotWinView = class("LeprechaunsCrockJackPotWinView", util_require("Levels.BaseLevelDialog"))

function LeprechaunsCrockJackPotWinView:onEnter()
    LeprechaunsCrockJackPotWinView.super.onEnter(self)

end
function LeprechaunsCrockJackPotWinView:onExit()
    self:stopUpDateCoins()

    LeprechaunsCrockJackPotWinView.super.onExit(self)
end

function LeprechaunsCrockJackPotWinView:initUI(_initData)
    self.m_allowClick = false

    self.m_data = _initData
    self:createCsbNode("LeprechaunsCrock/JackpotWinView.csb")

    self:upDateJackPotShow()
    self:setWinCoinsLab(0)

    -- 添加角色
    self.m_roleSpine = util_spineCreate("LeprechaunsCrock_juese", true, true)
    self:findChild("Node_juese"):addChild(self.m_roleSpine)
    
    -- 添加彩带
    local caidaiNode = util_createAnimation("LeprechaunsCrock/FreeSpin_tanban_caidai.csb")
    self:findChild("Node_caidai"):addChild(caidaiNode)
    caidaiNode:runCsbAction("idle", true)
end

-- 根据jackpot类型刷新展示
function LeprechaunsCrockJackPotWinView:upDateJackPotShow()
    local JackPotNodeName = {
        [1] = "Node_grand",
        [2] = "Node_mega",
        [3] = "Node_major",
        [4] = "Node_minor",
        [5] = "Node_mini",
    }
    for _jpIndex,_nodeName in ipairs(JackPotNodeName) do
        local isVisible = _jpIndex == self.m_data.index
        local jpNode = self:findChild(_nodeName)
        jpNode:setVisible(isVisible)
    end
end

-- 弹板入口 刷新
function LeprechaunsCrockJackPotWinView:initViewData(_machine)

    self:createGrandShare(_machine)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig["sound_LeprechaunsCrock_pick_jackpotView_start"..self.m_data.index])

    self:runCsbAction("start", false, function()
        self.m_allowClick = true
        self:runCsbAction("idle", true)
    end)

    util_spinePlay(self.m_roleSpine, "tanban2_start", true)
    util_spineEndCallFunc(self.m_roleSpine, "tanban2_start", function()
        util_spinePlay(self.m_roleSpine, "idleframe_tanban2", true)
    end)

    self:jumpCoins(self.m_data.coins, 0)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_data.coins, self.m_data.index)
end
--跳钱
function LeprechaunsCrockJackPotWinView:jumpCoins(_targetCoins)
    -- 每秒60帧
    local coinRiseNum =  _targetCoins / (4 * 60)  
    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0

    local node = self:findChild("m_lb_coins")
    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_jackpotView_jumpCoins , true)

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

function LeprechaunsCrockJackPotWinView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=1,sy=1.05}, 570)
end

--点击回调
function LeprechaunsCrockJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    if self:checkShareState() then
        return
    end

    self:clickCollectBtn(sender)
end
function LeprechaunsCrockJackPotWinView:clickCollectBtn(_sender)
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_click)

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setWinCoinsLab(self.m_data.coins)
        self:jumpCoinsFinish()
    else
        self:playOverAnim()
    end
end

function LeprechaunsCrockJackPotWinView:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_jackpotView_jumpCoinsOver)
    end
end

function LeprechaunsCrockJackPotWinView:playOverAnim()
    self:findChild("Button_1"):setEnabled(false)
    self.m_allowClick = false

    self:jackpotViewOver(function()
        self:stopAllActions()

        if self.m_btnClickFunc then
            self.m_btnClickFunc()
            self.m_btnClickFunc = nil
        end

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_jackpotView_over)

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
function LeprechaunsCrockJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function LeprechaunsCrockJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function LeprechaunsCrockJackPotWinView:createGrandShare(_machine)
    self.m_machine = _machine
    local parent = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function LeprechaunsCrockJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_data.index)
    end
end

function LeprechaunsCrockJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function LeprechaunsCrockJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return LeprechaunsCrockJackPotWinView

