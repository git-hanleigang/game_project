---
--island
--2018年4月12日
--MiningManiaJackpotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local MiningManiaJackpotWinView = class("MiningManiaJackpotWinView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MiningManiaPublicConfig"

MiningManiaJackpotWinView.BtnName = "Button_collect"

function MiningManiaJackpotWinView:onEnter()
    MiningManiaJackpotWinView.super.onEnter(self)

end
function MiningManiaJackpotWinView:onExit()
    self:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    MiningManiaJackpotWinView.super.onExit(self)
end

function MiningManiaJackpotWinView:initUI(_initData)
    --[[
        _initData = {
        }
    ]]

    self:createCsbNode("MiningMania/JackpotWinView.csb")
    self.m_roleSpine = util_spineCreate("MiningMania_guochang",true,true)
    self:findChild("Node_juese"):addChild(self.m_roleSpine)
    util_spinePlay(self.m_roleSpine,"actionframe_tanban_start",false)
    util_spineEndCallFunc(self.m_roleSpine, "actionframe_tanban_start", function()
        util_spinePlay(self.m_roleSpine,"actionframe_tanban_idle",true)
    end)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

-- 根据jackpot类型刷新展示
function MiningManiaJackpotWinView:upDateJackPotShow()
    local JackPotBgName = {
        [1] = "sp_bg_grand",
        [2] = "sp_bg_major",
        [3] = "sp_bg_minor",
        [4] = "sp_bg_mini",
    }
    local JackPotSpName = {
        [1] = "sp_grand",
        [2] = "sp_major",
        [3] = "sp_minor",
        [4] = "sp_mini",
    }
    for _jpIndex,_nodeName in ipairs(JackPotBgName) do
        local isVisible = _jpIndex == self.m_data.index
        local jpNode = self:findChild(_nodeName)
        jpNode:setVisible(isVisible)
    end
    for _jpIndex,_nodeName in ipairs(JackPotSpName) do
        local isVisible = _jpIndex == self.m_data.index
        local jpNode = self:findChild(_nodeName)
        jpNode:setVisible(isVisible)
    end
end

-- 弹板入口 刷新
function MiningManiaJackpotWinView:initViewData(_data)
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
    self:setWinCoinsLab(0)

    local jackporSound = PublicConfig.Music_Jackpot_Reward[_data.index]
    gLobalSoundManager:playSound(jackporSound)

    self.m_allowClick = false
    self:runCsbAction("start", false, function()
        self.m_allowClick = true
        self:runCsbAction("idle", true)
    end)

    self:jumpCoins(self.m_data.coins, 0)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(_data.coins, _data.index)
end
--跳钱
function MiningManiaJackpotWinView:jumpCoins(_targetCoins)
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
            self:stopUpDateCoins()
            self:jumpCoinsFinish()
        end
    end,0.008)
end

function MiningManiaJackpotWinView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=1.0,sy=1.0}, 591)
end

--点击回调
function MiningManiaJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    if self:checkShareState() then
        return
    end

    self:clickCollectBtn(sender)
end
function MiningManiaJackpotWinView:clickCollectBtn(_sender)
    -- gLobalSoundManager:playSound(levelsTemplePublicConfig.sound_levelsTemple_commonClick)

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setWinCoinsLab(self.m_data.coins)
        self:jumpCoinsFinish()
    else
        self:playOverAnim()
    end
end

function MiningManiaJackpotWinView:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Stop)
    end
end

function MiningManiaJackpotWinView:playOverAnim()
    self:findChild("Button_collect"):setEnabled(false)
    self.m_allowClick = false
    gLobalSoundManager:playSound(PublicConfig.Music_Normal_Click)
    self:jackpotViewOver(function()
        self:stopAllActions()

        if self.m_btnClickFunc then
            self.m_btnClickFunc()
            self.m_btnClickFunc = nil
        end

        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Over)
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
function MiningManiaJackpotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function MiningManiaJackpotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function MiningManiaJackpotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function MiningManiaJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_data.index)
    end
end

function MiningManiaJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function MiningManiaJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return MiningManiaJackpotWinView

