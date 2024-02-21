---
--island
--2018年4月12日
--KenoWinMaxView.lua
local KenoWinMaxView = class("KenoWinMaxView", util_require("base.BaseView"))

function KenoWinMaxView:initUI()
    self.m_click = false

    local resourceFilename = "Keno/KenoAllHit.csb"
    self:createCsbNode(resourceFilename)

    -- 母鸡
    self.m_mujiSpine = util_spineCreate("Socre_Keno_Scatter", true, true)
    self:findChild("Node_ji"):addChild(self.m_mujiSpine,10)
end

function KenoWinMaxView:initViewData(coins, callBackFun)
    self.m_callFun = callBackFun
    self:showResult(coins)
end

function KenoWinMaxView:showResult(winNum)
    self.m_winNum = winNum
    local changeTimes = 164
    local updateCoinNum = math.ceil(winNum / changeTimes)
    local currCoin = (0.2 / 0.05) * updateCoinNum

    local str = string.gsub(tostring(currCoin),"0",math.random( 1, 5 ))
    currCoin = tonumber(str)

    self.m_lb_coins = self:findChild("m_lb_coins")
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

    self.soundUpId = gLobalSoundManager:playSound("KenoSounds/sound_Keno_gold_up.mp3")

    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(
        function()
            self:updateCoins()
        end
    )
    util_spinePlay(self.m_mujiSpine, "tanban2", false)
    util_spineEndCallFunc(self.m_mujiSpine, "tanban2", function()

        util_spinePlay(self.m_mujiSpine, "tanban6", true)
    end)
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
        -- 自动spin的 时候 4秒自动over
        globalData.slotRunData:checkViewAutoClick(self,"Button_collect",4)
    end)

end

function KenoWinMaxView:updateCoins()
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
        gLobalSoundManager:playSound("KenoSounds/sound_Keno_gold_down.mp3")
    end
    self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_llGrowCoinNum))
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 770)
end

function KenoWinMaxView:onEnter()
    -- gLobalSoundManager:pauseBgMusic()
end

function KenoWinMaxView:onExit()
    -- gLobalSoundManager:resumeBgMusic()
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function KenoWinMaxView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_collect" then
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
            gLobalSoundManager:playSound("KenoSounds/sound_Keno_gold_down.mp3")

            self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_winNum))
            util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 770)
            if not globalData.slotRunData.m_isAutoSpinAction then
                return
            end
        end
        
        if self.m_click == true then
            return
        end
        self.m_click = true
        -- gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_click.mp3")

        self:runCsbAction("over",false,function()
            if self.m_callFun then
                self.m_callFun()
            end
            self:removeFromParent()
        end)
    end
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return KenoWinMaxView