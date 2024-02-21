---
--island
--2018年4月12日
--CashRushJackpotsJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local CashRushJackpotsJackPotWinView = class("CashRushJackpotsJackPotWinView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CashRushJackpotsPublicConfig"

CashRushJackpotsJackPotWinView.BtnName = "Button_collect"

function CashRushJackpotsJackPotWinView:onEnter()
    CashRushJackpotsJackPotWinView.super.onEnter(self)

end
function CashRushJackpotsJackPotWinView:onExit()
    self:stopUpDateCoins()

    CashRushJackpotsJackPotWinView.super.onExit(self)
end

function CashRushJackpotsJackPotWinView:initUI(_initData)
    --[[
        _initData = {
        }
    ]]

    self:createCsbNode("CashRushJackpots/JackpotWinView.csb")
    self.m_bonusCount = self:findChild("m_lb_num")
end

-- 根据jackpot类型刷新展示
function CashRushJackpotsJackPotWinView:upDateJackPotShow()
    -- local JackPotNodeName = {
    --     [1] = "Node_grand",
    --     [2] = "Node_major",
    --     [3] = "Node_minor",
    --     [4] = "Node_mini",
    -- }
    -- for _jpIndex,_nodeName in ipairs(JackPotNodeName) do
    --     local isVisible = _jpIndex == self.m_data.index
    --     local jpNode = self:findChild(_nodeName)
    --     jpNode:setVisible(isVisible)
    -- end
end

-- 弹板入口 刷新
function CashRushJackpotsJackPotWinView:initViewData(_data, _endCallFunc)
    --[[
        _data = {
            coins   = 0,
            index   = 1,
            machine = machine,
        }
    ]]
    self.m_data = _data
    self:setOverAniRunFunc(_endCallFunc)

    self.m_bonusCount:setString(_data.bonusCount)

    self:createGrandShare(_data.machine)
    self:upDateJackPotShow()
    self:setWinCoinsLab(0)

    self.m_allowClick = false
    gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_DialogStart)
    self:runCsbAction("start", false, function()
        self.m_allowClick = true
        self:runCsbAction("idle", true)
    end)

    self:jumpCoins(self.m_data.coins, 0)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(_data.coins, _data.index)
end
--跳钱
function CashRushJackpotsJackPotWinView:jumpCoins(_targetCoins)
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
            self:stopUpDateCoins()
            self:jumpCoinsFinish()
        end
    end,0.008)
end

function CashRushJackpotsJackPotWinView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=0.7,sy=0.7}, 922)
end

--点击回调
function CashRushJackpotsJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    if self:checkShareState() then
        return
    end

    self:clickCollectBtn(sender)
end
function CashRushJackpotsJackPotWinView:clickCollectBtn(_sender)
    -- gLobalSoundManager:playSound(CashRushJackpotsPublicConfig.sound_CashRushJackpots_commonClick)

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setWinCoinsLab(self.m_data.coins)
        self:jumpCoinsFinish()
    else
        self:playOverAnim()
    end
end

function CashRushJackpotsJackPotWinView:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_updateAction then
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Stop)
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        -- gLobalSoundManager:playSound(CashRushJackpotsPublicConfig.sound_CashRushJackpots_jackpotView_jumpCoinsOver)
    end
end

function CashRushJackpotsJackPotWinView:playOverAnim()
    self:findChild("Button_collect"):setEnabled(false)
    self.m_allowClick = false
    gLobalSoundManager:playSound(PublicConfig.Music_Normal_Click)

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
    
            self:removeFromParent()
        end,overTime)
    end)
end


--[[
    点击回调 和 结束回调
]]
function CashRushJackpotsJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function CashRushJackpotsJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function CashRushJackpotsJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function CashRushJackpotsJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_data.index)
    end
end

function CashRushJackpotsJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function CashRushJackpotsJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return CashRushJackpotsJackPotWinView

