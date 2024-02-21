---
--island
--2018年4月12日
--JackpotOGoldJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local JackpotOGoldJackPotWinView = class("JackpotOGoldJackPotWinView", util_require("base.BaseView"))

function JackpotOGoldJackPotWinView:initUI()

    local resourceFilename = "JackpotOGold/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

    -- 添加触摸
    self:addClick(self:findChild("touch_panel"))
end

function JackpotOGoldJackPotWinView:showResult(machine, winNum, index)
    self.m_isGrowOver = false
    self.m_winNum = winNum
    local changeTimes = 164
    local updateCoinNum = math.ceil(winNum / changeTimes)
    local currCoin = (0.2 / 0.05) * updateCoinNum

    local str = string.gsub(tostring(currCoin),"0",math.random( 1, 5 ))
    currCoin = tonumber(str)

    self.m_lb_coins = self:findChild("m_lb_num")
    self.m_lb_coins:setString(util_getFromatMoneyStr(currCoin))

    local temp = updateCoinNum

    self.m_llPerAddNum = tostring(temp)
    local index = string.find( self.m_llPerAddNum,"0")
    while index do
        local num = math.random( 0, 8)
        num = tostring(num)
        self.m_llPerAddNum = string.gsub(self.m_llPerAddNum ,"0",num,1)
        index = string.find( self.m_llPerAddNum,"0")
    end

    self.m_llPerAddNum = tonumber(self.m_llPerAddNum)
    self.m_llGrowCoinNum = currCoin + self.m_llPerAddNum

    self.soundUpId = gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_jackpot_gold_up.mp3")

    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(
        function()
            self:updateCoins()
        end
    )
end

function JackpotOGoldJackPotWinView:updateCoins()
    self.m_llGrowCoinNum = self.m_llGrowCoinNum + self.m_llPerAddNum
    if self.m_llGrowCoinNum >= self.m_winNum then
        self.m_isGrowOver = true
        self.m_llGrowCoinNum = self.m_winNum
        
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
        end

        if self.soundUpId then
            gLobalSoundManager:stopAudio(self.soundUpId)
            self.soundUpId  = nil
        end
        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_jackpot_gold_down.mp3")
    end
    self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_llGrowCoinNum))
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 587)
end

function JackpotOGoldJackPotWinView:onEnter()
    -- gLobalSoundManager:pauseBgMusic()
end

function JackpotOGoldJackPotWinView:onExit()
    -- gLobalSoundManager:resumeBgMusic()
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function JackpotOGoldJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "touch_panel" then
        if not self.m_isGrowOver then
            self.m_llGrowCoinNum = self.m_winNum
            self.m_isGrowOver = true
            
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

            -- 点击collect 停止数字增长 音效
            if self.soundUpId then
                gLobalSoundManager:stopAudio(self.soundUpId)
                self.soundUpId  = nil
            end
            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_jackpot_gold_down.mp3")

            self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_winNum))
            util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 587)
        end
    end
    
end

function JackpotOGoldJackPotWinView:jackPotOver(func)
    if func then
        func()
    end
end
--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return JackpotOGoldJackPotWinView