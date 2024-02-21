---
--xcyy
--2018年5月23日
--FruitFarmJackpotOver.lua

local FruitFarmJackpotOver = class("FruitFarmJackpotOver", util_require("base.BaseView"))

function FruitFarmJackpotOver:initUI(data)
    self:createCsbNode("FruitFarm/JackpotOver.csb")
    self:createGrandShare(data.machine)
    self.m_coins = data.coins or 0
    self.m_index = data.index
    self.m_jackpotIndex = 4 - data.index + 1
    self.m_startCoins = data.start_coins or 0
    self.m_clickType = false
    local name_str = {
        "mini",
        "minor",
        "major",
        "grand"
    }
    for index, node_name in pairs(name_str) do
        self:findChild(node_name):setVisible(self.m_index == index)
    end
    self:runCsbAction(
        "start",
        false,
        function()
            self.m_clickType = true
            self.m_soundId = gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_jackpot_jumpNum.mp3")
            self:runCsbAction("idle", true)
        end,
        60
    )
    if globalData.slotRunData.m_isNewAutoSpin and globalData.slotRunData.m_isAutoSpinAction then
        performWithDelay(
            self,
            function()
                self:showOver()
            end,
            8
        )
    end
   
    self.m_isRunNum = true
    local addValue = self.m_coins / (60 * 5)
    util_jumpNum(
        self:findChild("m_lb_coins"),
        0,
        self.m_coins,
        addValue,
        1 / 60,
        {30},
        nil,
        nil,
        function()
            self.m_isRunNum = false
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_jackpot_numStop.mp3")
        end,
        function()
            self:updateLabelSize({label = self:findChild("m_lb_coins"), sx = 0.7, sy = 0.7}, 855)
            self:jumpCoinsFinish()
        end
    )
end

function FruitFarmJackpotOver:onEnter()
    self.m_bgSoundId = gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_jackpot_enter.mp3")
end

function FruitFarmJackpotOver:showAdd()
end
function FruitFarmJackpotOver:onExit()
end

--默认按钮监听回调
function FruitFarmJackpotOver:clickFunc(sender)
    if not self.m_clickType then
        return
    end
    if self:checkShareState() then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if not self.m_isRunNum  then
        self.m_clickType = false
        self:showFlyCoins()
        return
    end

    self:stopAllActions()
    self:findChild("m_lb_coins"):unscheduleUpdate()
    self:findChild("m_lb_coins"):setString(util_formatCoins(self.m_coins, 30))
    self:updateLabelSize({label = self:findChild("m_lb_coins"), sx = 0.7, sy = 0.7}, 855)
    self:jumpCoinsFinish()

    if self.m_isRunNum then
        self.m_isRunNum = false
        gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_jackpot_numStop.mp3")
    end
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_bgSoundId then
        gLobalSoundManager:stopAudio(self.m_bgSoundId)
        self.m_bgSoundId = nil
    end

end

function FruitFarmJackpotOver:setCloseCallFunc(func)
    self.m_closeFunc = func
end

function FruitFarmJackpotOver:closeLayer()
    self:jackpotViewOver(function()
        self:runCsbAction(
        "over",
        false,
        function()
            if self.m_closeFunc then
                self.m_closeFunc()
            end
            self:removeFromParent()
        end,
        60)
    end)
end

function FruitFarmJackpotOver:showFlyCoins()
    --发送成功
    globalData.slotRunData.lastWinCoin = 0
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_coins + self.m_startCoins, false, true, self.m_startCoins})
    performWithDelay(
        self,
        function()
            -- 延时函数
            self:closeLayer()
        end,
        0.5
    )
end

function FruitFarmJackpotOver:showOver()
end

--[[
    自动分享 | 手动分享
]]
function FruitFarmJackpotOver:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function FruitFarmJackpotOver:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function FruitFarmJackpotOver:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function FruitFarmJackpotOver:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return FruitFarmJackpotOver
