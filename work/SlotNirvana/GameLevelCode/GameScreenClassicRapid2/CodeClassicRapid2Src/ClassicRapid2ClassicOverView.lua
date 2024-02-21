---
--island
--2018年4月12日
--ClassicRapid2ClassicOverView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local ClassicRapid2ClassicOverView = class("ClassicRapid2ClassicOverView", util_require("base.BaseView"))

ClassicRapid2ClassicOverView.jPnum = {9,8,7,6,5}

function ClassicRapid2ClassicOverView:initUI(data)
    self.m_click = false
    local resourceFilename = "ClassicRapid2/Classical_Over.csb"
    self:createCsbNode(resourceFilename)
    self.bgSoundId = gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_jackpotView1.mp3")
end

function ClassicRapid2ClassicOverView:initViewData(coins,callBackFun)
    self.m_callFun = callBackFun
    self:showResult(coins)
end

function ClassicRapid2ClassicOverView:showResult(winNum)
    self.m_winNum = winNum
    local changeTimes = 165
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
    self.m_schedule = schedule(
        self,
        function()
            self:updateCoins()
        end,
        1/30
    )

    self.m_click = true

    self:runCsbAction("start",false,function()
        self.m_click = false
        self:runCsbAction("idle",true)
        globalData.slotRunData:checkViewAutoClick(self,"Button_1")
    end)
end
function ClassicRapid2ClassicOverView:updateCoins()
    self.m_llGrowCoinNum = self.m_llGrowCoinNum + self.m_llPerAddNum
    if self.m_llGrowCoinNum >= self.m_winNum then
        self.m_isGrowOver = true
        self.m_llGrowCoinNum = self.m_winNum
        -- self:findChild("jinbi"):setVisible(false)
        self.m_schedule:stop()
        if self.bgSoundId then
            gLobalSoundManager:stopAudio(self.bgSoundId)
        end
        gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_jackpotView2.mp3")
    end
    self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_llGrowCoinNum))
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 537)
end

function ClassicRapid2ClassicOverView:onEnter()
    -- gLobalSoundManager:pauseBgMusic()
end

function ClassicRapid2ClassicOverView:onExit()
    -- gLobalSoundManager:resumeBgMusic()
end

function ClassicRapid2ClassicOverView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        if not self.m_isGrowOver then
            self.m_llGrowCoinNum = self.m_winNum
            self.m_isGrowOver = true
            return
        end
        if self.m_click == true then
            return
        end
        self.m_click = true
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

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

return ClassicRapid2ClassicOverView