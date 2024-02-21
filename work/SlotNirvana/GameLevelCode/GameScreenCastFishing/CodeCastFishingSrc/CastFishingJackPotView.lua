local CastFishingJackPotView = class("CastFishingJackPotView",util_require("Levels.BaseLevelDialog"))
local CastFishingMusicConfig = require "CodeCastFishingSrc.CastFishingMusicConfig"

local JackPotNodeName = {
    [1] = "Node_grand",
    [2] = "Node_mega",
    [3] = "Node_major",
    [4] = "Node_minor",
    [5] = "Node_mini",
}

function CastFishingJackPotView:onExit()
    CastFishingJackPotView.super.onExit(self)
    self:stopUpDateCoins()

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

--[[
    _initData = {
        machine      = machine,
        coins        = 0,
        jackpotIndex = 1,
    }
]]
function CastFishingJackPotView:initUI(_initData)
    self.m_initData = _initData
    self.m_allowClick = false
    self.m_jackpotIndex = _initData.jackpotIndex

    self:createCsbNode("CastFishing/JackpotWin.csb")

    self.m_spine = util_spineCreate("Socre_CastFishing_9_tanban",true,true)
    self:findChild("Node_spine"):addChild(self.m_spine)

    self:upDateJackPotShow()
    self:setWinCoinsLab(0)

    self:createGrandShare(_initData.machine)
end
-- 根据jackpot类型刷新展示
function CastFishingJackPotView:upDateJackPotShow()
    for _jpIndex,_nodeName in ipairs(JackPotNodeName) do
        local isVisible = _jpIndex == self.m_initData.jackpotIndex
        local jpNode = self:findChild(_nodeName)
        jpNode:setVisible(isVisible)
    end
end
--点击回调
function CastFishingJackPotView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    local name = sender:getName()

    if name == "Button_collect" then

        self:clickCollectBtn(sender)
    end
end

function CastFishingJackPotView:clickCollectBtn(_sender)
    if self:checkShareState() then
        return
    end
    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_jackpot_click)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setFinalWinCoins()
        self:jumpCoinsFinish()
    else
        self:jackpotViewOver(function()
            self:playOverAnim()
        end)
    end
end

-- 弹板入口
function CastFishingJackPotView:initViewData()
    self:runCsbAction("start", false, function()
        self.m_allowClick = true
        self:runCsbAction("idle", true)
   end)

    util_spinePlay(self.m_spine, "tanban_start", false)
    util_spineEndCallFunc(self.m_spine, "tanban_start", function()
        util_spinePlay(self.m_spine, "tanban_idle", true)
    end) 

    self:jumpCoins(self.m_initData.coins, 0)
end


function CastFishingJackPotView:jumpCoins(coins, _curCoins)
    local coinRiseNum =  coins / (4 * 60)  -- 每秒60帧

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = _curCoins or 0

    local node = self:findChild("m_lb_coins")
    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_jackpot_jumpCoins, true)
    

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

function CastFishingJackPotView:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil

        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_jackpot_jumpCoinsStop)
    end
end

function CastFishingJackPotView:setFinalWinCoins()
    if not self.m_initData then
        return
    end
    self:setWinCoinsLab(self.m_initData.coins)
end
function CastFishingJackPotView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=0.81,sy=0.81}, 773)
end



function CastFishingJackPotView:playOverAnim()
    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_jackpot_over)

    self:findChild("Button_collect"):setEnabled(false)
    self.m_allowClick = false
    self:stopAllActions()

    if self.m_btnClickFunc then
        self.m_btnClickFunc()
        self.m_btnClickFunc = nil
    end

    self:runCsbAction("over", false)
    local overTime = util_csbGetAnimTimes(self.m_csbAct, "over")
    performWithDelay(
        self,
        function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end
    
            self:removeFromParent()
        end,
        overTime
    )

end

--[[
    模仿一下 BaseDialog 的点击结束流程
]]
function CastFishingJackPotView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end
function CastFishingJackPotView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function CastFishingJackPotView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function CastFishingJackPotView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function CastFishingJackPotView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function CastFishingJackPotView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return CastFishingJackPotView