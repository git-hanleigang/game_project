local KangaPocketsJackPotView = class("KangaPocketsJackPotView",util_require("Levels.BaseLevelDialog"))
local KangaPocketsPublicConfig = require "KangaPocketsPublicConfig"

local JackPotNodeName = {
    [1] = "Node_grand",
    [2] = "Node_major",
    [3] = "Node_minor",
    [4] = "Node_mini",
}

function KangaPocketsJackPotView:onExit()
    KangaPocketsJackPotView.super.onExit(self)
    self:stopUpDateCoins()

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

--[[
    _initData = {
        coins        = 0,
        index = 1,
    }
]]
function KangaPocketsJackPotView:initUI(_initData)
    self.m_initData = _initData
    self.m_allowClick = false

    self:createCsbNode("KangaPockets/JackpotWinView.csb")

    local spineParent = self:findChild("Node_spineRole")
    self.m_kangaPocketsRole = util_createView("CodeKangaPocketsSrc.KangaPocketsRoleSpine", {})
    spineParent:addChild(self.m_kangaPocketsRole)

    self:upDateJackPotShow()
    self:setWinCoinsLab(0)
end
-- 根据jackpot类型刷新展示
function KangaPocketsJackPotView:upDateJackPotShow()
    for _jpIndex,_nodeName in ipairs(JackPotNodeName) do
        local isVisible = _jpIndex == self.m_initData.index
        local jpNode = self:findChild(_nodeName)
        jpNode:setVisible(isVisible)
    end
end
--点击回调
function KangaPocketsJackPotView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    local name = sender:getName()

    if name == "Button_collect" then

        self:clickCollectBtn(sender)
    end
end

function KangaPocketsJackPotView:clickCollectBtn(_sender)
    local bShare = self:checkShareState()
    if not bShare then

        gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_commonClick)

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end

        if self.m_updateAction ~= nil then
            self:stopUpDateCoins()
            self:setFinalWinCoins()
            self:jumpCoinsFinish()
        else
            self:playOverAnim()
        end
    end
end

-- 弹板入口
function KangaPocketsJackPotView:initViewData(mainMachine)
    self:createGrandShare(mainMachine)
    self:runCsbAction("start", false, function()
        self.m_allowClick = true
        self:runCsbAction("idle", true)
   end)

   self.m_kangaPocketsRole:playJackpotViewStartAnim()
    self:jumpCoins(self.m_initData.coins, 0)
end


function KangaPocketsJackPotView:jumpCoins(coins, _curCoins)
    local coinRiseNum =  coins / (4 * 60)  -- 每秒60帧
    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = _curCoins or 0

    local node = self:findChild("m_lb_coins")
    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_jackpotView_jumpCoins, true)
    

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum

        curCoins = curCoins < coins and curCoins or coins
        self:setWinCoinsLab(curCoins)

        if curCoins >= coins then
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            self:stopUpDateCoins()
            self:jumpCoinsFinish()
        end
    end,0.008)
end

function KangaPocketsJackPotView:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_jackpotView_jumpCoinsOver)
    end
end

function KangaPocketsJackPotView:setFinalWinCoins()
    if not self.m_initData then
        return
    end
    self:setWinCoinsLab(self.m_initData.coins)
end
function KangaPocketsJackPotView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=0.81,sy=0.81}, 773)
end



function KangaPocketsJackPotView:playOverAnim()
    -- gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_jackpot_over)

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
    模仿一下 BaseDialog 的点击结束流程
]]
function KangaPocketsJackPotView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function KangaPocketsJackPotView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function KangaPocketsJackPotView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function KangaPocketsJackPotView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_initData.index)
    end
end

function KangaPocketsJackPotView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function KangaPocketsJackPotView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return KangaPocketsJackPotView
