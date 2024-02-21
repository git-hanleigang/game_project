---
--island
--2018年4月12日
--TreasureToadJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local TreasureToadJackPotWinView = class("TreasureToadJackPotWinView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "TreasureToadPublicConfig"

TreasureToadJackPotWinView.BtnName = "Button"

function TreasureToadJackPotWinView:onEnter()
    TreasureToadJackPotWinView.super.onEnter(self)

end
function TreasureToadJackPotWinView:onExit()
    self:stopUpDateCoins()

    TreasureToadJackPotWinView.super.onExit(self)
end

function TreasureToadJackPotWinView:initUI(_initData)
    --[[
        _initData = {
        }
    ]]
    self.m_machine = _initData.machine
    self:createCsbNode("TreasureToad/JackpotWinView.csb")
end

-- 根据jackpot类型刷新展示
function TreasureToadJackPotWinView:upDateJackPotShow()
    local JackPotNodeName = {
        [1] = "Node_mini",
        [2] = "Node_minor",
        [3] = "Node_major",
        [4] = "Node_grand",
    }
    local status = self.m_machine.m_jackpot_status
    
    if self.m_data.index == 4 and status ~= "Normal" then
        self:findChild("Node_mega"):setVisible(status == "Mega")
        self:findChild("Node_super"):setVisible(status == "Super")
        for k,v in pairs(JackPotNodeName) do
            local img =  self:findChild(v)
            if img then
                img:setVisible(false)
            end
        end
    else
        self:findChild("Node_mega"):setVisible(false)
        self:findChild("Node_super"):setVisible(false)
        for _jpIndex,_nodeName in ipairs(JackPotNodeName) do
            local isVisible = _jpIndex == self.m_data.index
            local jpNode = self:findChild(_nodeName)
            jpNode:setVisible(isVisible)
        end
    end
end

function TreasureToadJackPotWinView:showOtherUi()
    local jvese = util_spineCreate("Socre_TreasureToad_Bonus2",true,true)
    local bottonSg = util_spineCreate("TreasureToad_anniu_sg",true,true)
    local lighting = util_createAnimation("Socre_TreasureToad_bg_guang.csb") 
    util_spinePlay(jvese, "idleframe3",true)
    util_spinePlay(bottonSg, "idle2",true)
    lighting:runCsbAction("idleframe",true)
    self:findChild("Node_juese"):addChild(jvese)
    self:findChild("Node_sg"):addChild(bottonSg)
    self:findChild("Node_guang"):addChild(lighting)
end

function TreasureToadJackPotWinView:showJackpotSoundForIndex()
    if self.m_data.index == 1 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_jackpot_mini_show)
    elseif self.m_data.index == 2 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_jackpot_minor_show)
    elseif self.m_data.index == 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_jackpot_major_show)
    elseif self.m_data.index == 4 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_jackpot_grand_show)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_jackpot_mini_show)
    end
end

-- 弹板入口 刷新
function TreasureToadJackPotWinView:initViewData(_data)
    --[[
        _data = {
            coins   = 0,
            index   = 1,
            machine = machine,
        }
    ]]
    self.m_data = _data

    self:createGrandShare(_data.machine)
    self:upDateJackPotShow()
    self:showOtherUi()
    self:setOverAniRunFunc(_data.func)
    self:setWinCoinsLab(0)

    self.m_allowClick = false
    self:showJackpotSoundForIndex()
    self:runCsbAction("start", false, function()
        self.m_allowClick = true
        self:runCsbAction("idle", true)
    end)

    self:jumpCoins(self.m_data.coins, 0)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(_data.coins, _data.index)
end
--跳钱
function TreasureToadJackPotWinView:jumpCoins(_targetCoins)
    -- 每秒60帧
    local coinRiseNum =  _targetCoins / (4 * 60)  
    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0

    local node = self:findChild("m_lb_coins")
    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_jackpot_num_jump, true)

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

function TreasureToadJackPotWinView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=1,sy=1}, 595)
end

--点击回调
function TreasureToadJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    if self:checkShareState() then
        return
    end

    self:clickCollectBtn(sender)
end
function TreasureToadJackPotWinView:clickCollectBtn(_sender)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_click)

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setWinCoinsLab(self.m_data.coins)
        self:jumpCoinsFinish()
    else
        self:playOverAnim()
    end
end

function TreasureToadJackPotWinView:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_jackpot_num_jumpOver)
    end
end

function TreasureToadJackPotWinView:playOverAnim()
    self:findChild("Button"):setEnabled(false)
    self.m_allowClick = false

    self:jackpotViewOver(function()
        self:stopAllActions()

        if self.m_btnClickFunc then
            self.m_btnClickFunc()
            self.m_btnClickFunc = nil
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_jackpot_over)
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
function TreasureToadJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function TreasureToadJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function TreasureToadJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function TreasureToadJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        local index = self.m_data.index
        if self.m_data.index == 4 then
            index = 1
        elseif self.m_data.index == 1 then
            index = 4
        end
        self.m_grandShare:jumpCoinsFinish(index)
    end
end

function TreasureToadJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function TreasureToadJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return TreasureToadJackPotWinView

