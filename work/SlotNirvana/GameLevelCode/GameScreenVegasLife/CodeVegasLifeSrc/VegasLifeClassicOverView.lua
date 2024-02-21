---
--island
--2018年4月12日
--VegasLifeClassicOverView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local VegasLifeClassicOverView = class("VegasLifeClassicOverView", util_require("base.BaseView"))

VegasLifeClassicOverView.jPnum = {9,8,7,6,5}

function VegasLifeClassicOverView:initUI(data)
    self.m_click = false
    local resourceFilename = "VegasLife/Classical_Over.csb"
    self:createCsbNode(resourceFilename)
    self.bgSoundId = gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_classicOver.mp3")
end

function VegasLifeClassicOverView:initViewData(coins,callBackFun)
    self.m_callFun = callBackFun
    self:showResult(coins)
end

function VegasLifeClassicOverView:showResult(winNum)
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

    self.soundUpId = gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_gold_up.mp3")

    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(
        function()
            self:updateCoins()
        end
    )

    self.m_click = true

    self:runCsbAction("start",false,function()
        self.m_click = false
        self:runCsbAction("idle",true)
        globalData.slotRunData:checkViewAutoClick(self,"Button_1",4)
    end)
end
function VegasLifeClassicOverView:updateCoins()
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
        gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_gold_down.mp3")
    end
    self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_llGrowCoinNum))
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 900)
end

function VegasLifeClassicOverView:onEnter()
    -- gLobalSoundManager:pauseBgMusic()
end

function VegasLifeClassicOverView:onExit()
    -- gLobalSoundManager:resumeBgMusic()
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function VegasLifeClassicOverView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
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
            gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_gold_down.mp3")

            self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_winNum))
            util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 900)

            if not globalData.slotRunData.m_isAutoSpinAction then
                return
            end
        end

        if self.m_click == true then
            return
        end
        self.m_click = true
        gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_click.mp3")

        self:runCsbAction("over",false,function()
            -- gLobalSoundManager:resumeBgMusic()
            
            if self.m_callFun then
                self.m_callFun()
            end

            self:removeFromParent()

        end)
        -- performWithDelay(self,function()

        -- end,1)

    end
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return VegasLifeClassicOverView