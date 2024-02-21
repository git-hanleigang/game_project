local NutCarnivalJackPotWinView = class("NutCarnivalJackPotWinView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "NutCarnivalPublicConfig"

NutCarnivalJackPotWinView.BtnName = "Button_collect"

function NutCarnivalJackPotWinView:onEnter()
    NutCarnivalJackPotWinView.super.onEnter(self)

end
function NutCarnivalJackPotWinView:onExit()
    self:stopUpDateCoins()

    NutCarnivalJackPotWinView.super.onExit(self)
end

function NutCarnivalJackPotWinView:initUI(_initData)
    --[[
        _initData = {
        }
    ]]

    self:createCsbNode("NutCarnival/JackpotWinView.csb")

    self.m_roleSpine = util_createView("CodeNutCarnivalSrc.NutCarnivalRoleSpine",{})
    self:findChild("Node_juese"):addChild(self.m_roleSpine)
end

-- 根据jackpot类型刷新展示
function NutCarnivalJackPotWinView:upDateJackPotShow()
    local JackPotNodeName = {
        [1] = "Node_grand",
        [2] = "Node_major",
        [3] = "Node_maxi",
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
function NutCarnivalJackPotWinView:initViewData(_data)
    --[[
        _data = {
            coins   = 0,
            index   = 1,
            multip  = 0,     --乘倍数值
            machine = machine,
        }
    ]]
    self.m_data   = _data
    local bMultip = self.m_data.multip > 1
    local startCoins = 0

    self:createGrandShare(_data.machine)
    self:upDateJackPotShow()
    --跳钱
    if bMultip then
        _data.machine:levelPerformWithDelay(self, 51/60, function()
            gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_jackpotView_multip)
        end)
        local multipNode = self:findChild(string.format("chengbei_%d", self.m_data.multip))
        if multipNode then
            multipNode:setVisible(true)
        end
        startCoins = math.floor(self.m_data.coins / self.m_data.multip)
        self:setWinCoinsLab(startCoins)
    else
        self:setWinCoinsLab(startCoins)
        self:jumpCoins(startCoins, self.m_data.coins, 4)
    end
    --动画
    self.m_allowClick = false
    self:runCsbAction("start", false, function()
        if bMultip then
            local fankuiCsb = util_createAnimation("NutCarnival_fankui.csb")
            self:findChild("Node_fankui"):addChild(fankuiCsb)
            fankuiCsb:runCsbAction("fankui4")
            self:jumpCoins(startCoins, self.m_data.coins, 2)
        end
        self:runCsbAction("idle", true)
        self.m_allowClick = true
    end)
    self.m_roleSpine:playJackpotViewAnim()

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(_data.coins, _data.index)
end
--跳钱
function NutCarnivalJackPotWinView:jumpCoins(_curCoins, _targetCoins, _jumpTime)
    -- 每秒60帧
    local coinRiseNum =  _targetCoins / (_jumpTime * 60)  
    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = _curCoins
    local node = self:findChild("m_lb_coins")
    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_jackpotView_jumpCoins, true)

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

function NutCarnivalJackPotWinView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=1,sy=1}, 588)
end

--点击回调
function NutCarnivalJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    if self:checkShareState() then
        return
    end

    self:clickCollectBtn(sender)
end
function NutCarnivalJackPotWinView:clickCollectBtn(_sender)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_commonClick)
    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setWinCoinsLab(self.m_data.coins)
        self:jumpCoinsFinish()
    else
        self:playOverAnim()
    end
end

function NutCarnivalJackPotWinView:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_jackpotView_jumpCoinsOver)
    end
end

function NutCarnivalJackPotWinView:playOverAnim()
    self:findChild("Button_collect"):setEnabled(false)
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
function NutCarnivalJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function NutCarnivalJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function NutCarnivalJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function NutCarnivalJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_data.index)
    end
end

function NutCarnivalJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function NutCarnivalJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return NutCarnivalJackPotWinView

