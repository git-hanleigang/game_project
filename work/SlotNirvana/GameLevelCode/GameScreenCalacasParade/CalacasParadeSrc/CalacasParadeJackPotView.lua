--[[
    彩金弹板
]]
local CalacasParadeJackpotView = class("CalacasParadeJackpotView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CalacasParadePublicConfig"

CalacasParadeJackpotView.BtnName = "Button"
CalacasParadeJackpotView.LabName = "m_lb_coins"
--每个类型需要打开可见性的节点名称
CalacasParadeJackpotView.JackpotTypeNodeName = {
    [1] = {},
    [2] = {"Node_major"},
    [3] = {"Node_minor"},
    [4] = {"Node_mini"},
}

function CalacasParadeJackpotView:initUI(_data)
    --[[
        _data = {
            index   = 1,
            coins   = 0,
            csbName = "",
            machine = machine,
        }
    ]]
    self.m_data   = _data

    self:createCsbNode(self.m_data.csbName)
end
function CalacasParadeJackpotView:onEnter()
    CalacasParadeJackpotView.super.onEnter(self)
    self:initViewData()
end
-- 弹板入口 刷新
function CalacasParadeJackpotView:initViewData()
    self:createGrandShare(self.m_data.machine)
    --刷新奖池类型
    self:upDateJackPotShow()
    --跳钱
    local startCoins = 0
    self:setWinCoinsLab(startCoins)
    self:jumpCoins(startCoins, self.m_data.coins, 4)
    --动画
    self.m_allowClick = false
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        self.m_allowClick = true
    end)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_data.coins, self.m_data.index)
end


-- 根据jackpot类型刷新展示
function CalacasParadeJackpotView:upDateJackPotShow()
    local bGrand = 1 == self.m_data.index

    local ndoeNameList = self.JackpotTypeNodeName[self.m_data.index]
    for i,_nodeName in ipairs(ndoeNameList) do
        local jpNode = self:findChild(_nodeName)
        jpNode:setVisible(true)
    end

    self.m_gcSpine = util_spineCreate("CalacasParade_huache_guochang1", true, true)
    self:findChild("Node_spine"):addChild(self.m_gcSpine)
    util_spinePlay(self.m_gcSpine, "idle", true)

    self.m_yhSpine = util_spineCreate("CalacasParade_yanhua", true, true)
    self:findChild("Node_yanhua"):addChild(self.m_yhSpine)
    local yhAnimName = bGrand and "tanban_idle3" or "tanban_idle2" 
    util_spinePlay( self.m_yhSpine, yhAnimName, true)
end


--跳钱
function CalacasParadeJackpotView:jumpCoins(_curCoins, _targetCoins, _jumpTime)
    -- 每秒60帧
    local coinRiseNum =  _targetCoins / (_jumpTime * 60)  
    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 
    local curCoins = _curCoins

    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_JackpotView_jumpCoins, true)

    self.m_updateAction = schedule(self, function()
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

function CalacasParadeJackpotView:setWinCoinsLab(_coins)
    local labCoins = self:findChild(self.LabName)
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label = labCoins, sx=1, sy=1}, 628)
end

--点击回调
function CalacasParadeJackpotView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    if self:checkShareState() then
        return
    end

    self:clickCollectBtn(sender)
end
function CalacasParadeJackpotView:clickCollectBtn(_sender)
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CommonClick)
    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setWinCoinsLab(self.m_data.coins)
        self:jumpCoinsFinish()
    else
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_JackpotView_over)
        self:playOverAnim()
    end
end

function CalacasParadeJackpotView:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_JackpotView_jumpCoinsOver)
    end
end

function CalacasParadeJackpotView:playOverAnim()
    self:findChild(self.BtnName):setEnabled(false)
    self.m_allowClick = false

    self:jackpotViewOver(function()
        self:stopAllActions()
        if self.m_btnClickFunc then
            self.m_btnClickFunc()
            self.m_btnClickFunc = nil
        end
    
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
function CalacasParadeJackpotView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function CalacasParadeJackpotView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function CalacasParadeJackpotView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function CalacasParadeJackpotView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_data.index)
    end
end
function CalacasParadeJackpotView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function CalacasParadeJackpotView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end
return CalacasParadeJackpotView

