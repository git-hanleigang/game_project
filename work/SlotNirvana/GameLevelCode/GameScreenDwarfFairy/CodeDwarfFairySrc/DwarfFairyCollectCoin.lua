---
--island
--2018年4月12日
--DwarfFairyCollectCoin.lua
---- respin 玩法结算时中 mini mijor等提示界面
local DwarfFairyCollectCoin = class("DwarfFairyCollectCoin", util_require("base.BaseView"))

DwarfFairyCollectCoin.m_isShowTip = false
DwarfFairyCollectCoin.m_tipAnimOver = true

function DwarfFairyCollectCoin:initUI(data)
    self.m_click = false
    self.m_machine = data
    local resourceFilename = "DwarfFairy_Lock.csb"
    self:createCsbNode(resourceFilename)
    self:addClick(self:findChild("btn"))
    self.m_labUnlockBet = self:findChild("coin")
    self.m_percent = self:findChild("percent")
    self.m_progress = util_createView("CodeDwarfFairySrc.DwarfFairyCollectProgress")
    self:findChild("progress"):addChild(self.m_progress)

    self.m_tip = util_createAnimation("DwarfFairy_Lock1.csb")
    self:addChild(self.m_tip,-1)
    self.m_tip:setVisible(false)
end

function DwarfFairyCollectCoin:initByGameData(data)
    self.m_labUnlockBet:setString(util_formatCoins(data.betNum, 6))
    self:runCsbAction("idle"..data.betLevel, true, nil, 20)
    self.m_progress:setProgress(data.progress)
    local progress = math.floor( data.progress * 10 )
    progress = progress * 0.1
    self.m_percent:setString(util_keepFloatNum(progress, 1).."%")
end

function DwarfFairyCollectCoin:onEnter()
    gLobalNoticManager:addObserver(self, function()
        if  self.m_isShowTip then
            self.m_tip:playAction("back",false,function()
                self.m_tipAnimOver = true
                self.m_tip:setVisible(false)
            end)
            self.m_isShowTip = false
        end
    end, ViewEventType.STR_TOUCH_SPIN_BTN)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        self:updateBtnEnable(params)
    end,"BET_ENABLE")

end

function DwarfFairyCollectCoin:updateBtnEnable(flag)
    if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
        flag=false
    end
    -- self:findChild("btn"):setBright(flag)
    self:findChild("btn"):setTouchEnabled(flag)

end



function DwarfFairyCollectCoin:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function DwarfFairyCollectCoin:unlock(betLevel)
    self.m_iBetLevel = betLevel
    self:runCsbAction("jiesuo", false, function()
        self:runIdle()
    end, 20)
    self:showTip()

end

function DwarfFairyCollectCoin:lock(betLevel)
    self.m_iBetLevel = betLevel
    self:hideTip()
    self:runCsbAction("lock", false, function()
        self:runIdle()
    end, 20)
end

function DwarfFairyCollectCoin:runIdle()
    self:runCsbAction("idle"..self.m_iBetLevel, true, nil, 20)
end

function DwarfFairyCollectCoin:collect(progress)
    if self.m_iBetLevel == 1 then
        self:runCsbAction("actionframe", false, function()
            self:runIdle()
        end, 20)
    end

    
    performWithDelay(self, function()
        self.m_progress:setProgress(progress)
        progress = math.floor(progress * 10 )
        progress = progress * 0.1
        self.m_percent:setString(util_keepFloatNum(progress, 1).."%")
    end, 0.25)
    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_coin_collect.mp3")
end

function DwarfFairyCollectCoin:updateProgress()

end

function DwarfFairyCollectCoin:collectOver(func)
    self:runCsbAction("shouji", false, function()
        if func ~= nil then
            performWithDelay(self, function()
                func()
            end, 0.8)
        end
    end, 20)
end

function DwarfFairyCollectCoin:showTip()
    if not self.m_isShowTip then
        self.m_isShowTip = true
        self.m_tip:setVisible(true)
        self.m_tip:playAction("click",false,function()
            self.m_tipAnimOver = true
        end)
    end
end
function DwarfFairyCollectCoin:hideTip()
    if self.m_isShowTip then
        self.m_tip:playAction("back",false,function()
            self.m_tipAnimOver = true
            self.m_tip:setVisible(false)
        end)
        self.m_isShowTip = false
    end
end
function DwarfFairyCollectCoin:dealTip()
    if self.m_tipAnimOver then
        self.m_tipAnimOver = false
        if self.m_isShowTip then
            self:hideTip()
        else
           self:showTip()
        end
    end
end
function DwarfFairyCollectCoin:clickFunc(sender)

    if self.m_machine:getCurrSpinMode() == RESPIN_MODE or self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE then
        return
    end
    self:dealTip()
    if self.m_machine.m_iBetLevel == 1 then
        gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_click_goldBar.mp3")
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)

end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return DwarfFairyCollectCoin