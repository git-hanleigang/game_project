--[[
    彩金弹板
]]
local PublicConfig = require "CherryBountyPublicConfig"
local CherryBountyJackPotView = class("CherryBountyJackPotView", util_require("Levels.BaseLevelDialog"))

CherryBountyJackPotView.BtnName = "Button_1"
CherryBountyJackPotView.LabName = "m_lb_coins"
--每个类型需要打开可见性的节点名称
CherryBountyJackPotView.JackpotTypeSkin = {
    [1] = "grand",
    [2] = "major",
    [3] = "minor",
    [4] = "mini",
}

function CherryBountyJackPotView:initUI(_data)
     --[[
        _data = {
            index   = 1,
            coins   = 0,
            multi   = 5,
            machine = machine,
        }
    ]]
    self.m_data    = _data
    self.m_machine = _data.machine
    self:createCsbNode("CherryBounty/JackpotWinView.csb")

    self.m_bigWinSpine = util_spineCreate("CherryBounty_grand_tanban", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigWinSpine)

    self.m_spine = util_spineCreate("JackpotWinView_spine", true, true)
    self:findChild("Node_spine"):addChild(self.m_spine)
    local skinName = self.JackpotTypeSkin[self.m_data.index]
    self.m_spine:setSkin(skinName)
end
function CherryBountyJackPotView:onEnter()
    CherryBountyJackPotView.super.onEnter(self)
    self:createGrandShare(self.m_machine)
    self:initViewData()
end
function CherryBountyJackPotView:onExit()
    self:stopJumpSound(false)
    CherryBountyJackPotView.super.onExit(self)
end
-- 弹板入口 刷新
function CherryBountyJackPotView:initViewData()
    local bMulti = self.m_data.multi > 1
    --刷新奖池类型
    self:upDateJackPotShow()
    --跳钱
    local startCoins = 0
    if bMulti then
        startCoins = math.floor(self.m_data.coins / self.m_data.multi)
        self:setWinCoinsLab(startCoins)
    else
        self:setWinCoinsLab(startCoins)
        self:jumpCoins(startCoins, self.m_data.coins, 4)
    end
    --动画
    self.m_allowClick = false
    local startName =  "start"
    local idleName  =  "idle"
    self:runCsbAction(startName, false, function()
        -- self:runCsbAction(idleName, false)
    end)
    util_spinePlay(self.m_spine, startName, false)
    util_spineEndCallFunc(self.m_spine,  startName, function()
        local fnIdle = function()
            util_spinePlay(self.m_spine, idleName, true)
            --进入idle状态时 如果在autoSpin则自动关闭弹板
            if globalData.slotRunData.m_isAutoSpinAction then
                performWithDelay(self,function()
                    self:playOverAnim()
                end,8)
            end
        end
        if bMulti then
            gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_JackpotView_multiple)
            util_spinePlay(self.m_spine, "switch", false)
            util_spineEndCallFunc(self.m_spine,  "switch", function()
                fnIdle()
            end)
            self.m_machine:levelPerformWithDelay(self, 18/30, function()
                self:jumpCoins(startCoins, self.m_data.coins, 62/30)
                self.m_allowClick = true
            end)
        else
            fnIdle()
            self.m_allowClick = true
        end
    end)
    util_spinePlay(self.m_bigWinSpine, startName, false)
    util_spineEndCallFunc(self.m_bigWinSpine,  startName, function()
        util_spinePlay(self.m_bigWinSpine, idleName, true)
    end)
    util_spinePushBindNode(self.m_spine, "Node_shuzi1", self:findChild("Node_multi"))
    util_spinePushBindNode(self.m_spine, "Node_shuzi2", self:findChild("Node_coins"))
    util_spinePushBindNode(self.m_spine, "Node_anniu",  self:findChild("Node_anniu"))

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_data.coins, self.m_data.index)
end

-- 根据jackpot类型刷新展示
function CherryBountyJackPotView:upDateJackPotShow()
    local bMulti = self.m_data.multi > 1
    self:findChild("Node_multi"):setVisible(bMulti)
    if bMulti then
        local labMulti = self:findChild("m_lb_multi")
        labMulti:setString( string.format("X%d", self.m_data.multi) )
    end
end


--跳钱
function CherryBountyJackPotView:jumpCoins(_curCoins, _targetCoins, _jumpTime)
    -- 每秒60帧
    local offsetValue = _targetCoins - _curCoins
    local coinRiseNum =  math.floor(offsetValue / (_jumpTime * 60))
    local sCoins = self.m_machine:getCherryBountyLongNumString(coinRiseNum)
    sCoins = string.gsub(sCoins,"0",math.random(1, 5))
    coinRiseNum  = tonumber(sCoins)
    coinRiseNum  = math.ceil(coinRiseNum)
    local curCoins = _curCoins

    self:playJumpSound()
    self.m_updateAction = schedule(self, function()
        curCoins = math.min(_targetCoins, curCoins + coinRiseNum)
        self:setWinCoinsLab(curCoins)
        if curCoins >= _targetCoins then
            self:stopUpDateCoins()
            self:jumpCoinsFinish()
        end
    end,0.016)
end
function CherryBountyJackPotView:setWinCoinsLab(_coins)
    local labCoins = self:findChild(self.LabName)
    labCoins:setString(util_formatCoins(_coins, 30))
    self:updateLabelSize({label = labCoins, sx=1, sy=1}, 727)
end
-- 数字上涨音效-播放
function CherryBountyJackPotView:playJumpSound()
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_JackpotView_jumpCoins, true)
end
-- 数字上涨音效-停止
function CherryBountyJackPotView:stopJumpSound(_bStopSound)
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
        if _bStopSound then
            gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_JackpotView_jumpCoinsOver)
        end
    end
end

--点击回调
function CherryBountyJackPotView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    self:clickCollectBtn(sender)
end
function CherryBountyJackPotView:clickCollectBtn(_sender)
    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_CommonClick)
    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setWinCoinsLab(self.m_data.coins)
        self:jumpCoinsFinish()
    else
        self:playOverAnim()
    end
end

function CherryBountyJackPotView:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        -- gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_JackpotView_jumpCoinsOver)
    end
    self:stopJumpSound(true)
end

function CherryBountyJackPotView:playOverAnim()
    self:findChild(self.BtnName):setEnabled(false)
    self.m_allowClick = false
    self:stopAllActions()
    self:jackpotViewOver(function()
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_JackpotView_over)
        if self.m_btnClickFunc then
            self.m_btnClickFunc()
            self.m_btnClickFunc = nil
        end
        local overName =  "over"
        self:runCsbAction(overName, false)
        util_spinePlay(self.m_spine, overName, false)
        util_spinePlay(self.m_bigWinSpine, overName, false)
        local overTime = 15/30
        performWithDelay(self,function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end
            self:removeFromParent()
        end,overTime)
    end)
end

--点击回调
function CherryBountyJackPotView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end
--结束回调
function CherryBountyJackPotView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function CherryBountyJackPotView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function CherryBountyJackPotView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_data.index)
    end
end
function CherryBountyJackPotView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function CherryBountyJackPotView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return CherryBountyJackPotView