---
--island
--2018年4月12日
--VegasLifeJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local VegasLifeJackPotWinView = class("VegasLifeJackPotWinView", util_require("base.BaseView"))

VegasLifeJackPotWinView.jPnum = {9,8,7,6,5}
VegasLifeJackPotWinView.index = nil --1表示cashrush触发的jackpot；2表示classic触发的jackpot

function VegasLifeJackPotWinView:initUI(data, _machine)
    self.m_click = false
    self.index = data

    local resourceFilename = "VegasLife/JackpotOver.csb"
    if data == 2 then
        resourceFilename = "VegasLife/JackpotOver2.csb"
    end
    self:createCsbNode(resourceFilename)
    
    -- self:createGrandShare(_machine)
end

function VegasLifeJackPotWinView:initViewData(coins,index,callBackFun)
    self.m_index = index
    self.m_jackpotIndex = index + 5

    local random = math.random(1,2)
    self.bgSoundId = gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_jackpotView" .. random .. ".mp3")

    -- local node1=self:findChild("m_lb_coins")
    self:findChild("m_lb_num"):setString(self.jPnum[index])

    self.m_callFun = callBackFun
    self:showResult(coins)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_jackpotIndex)
end

function VegasLifeJackPotWinView:initClassicViewData(coins,index,callBackFun)
    self.m_index = index

    local random = math.random(1,2)
    self.bgSoundId = gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_classic_jackpotView" .. random .. ".mp3")

    for i=1,5 do
        self:findChild("VegasLife_tb1x_"..i):setVisible(false)
    end
    self:findChild("VegasLife_tb1x_"..self.m_index):setVisible(true)

    self.m_callFun = callBackFun
    local mapList = {5,4,3,2,1}
    self:showResult(coins)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,mapList[index])
end

function VegasLifeJackPotWinView:showResult(winNum)
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
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
        -- 自动spin的 时候 4秒自动over
        globalData.slotRunData:checkViewAutoClick(self,"Button_1",4)
    end)

end
function VegasLifeJackPotWinView:updateCoins()
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
    if self.m_isGrowOver then
        self:jumpCoinsFinish()
    end
    
    if self.index == 1 then
        util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 700)
    else
        util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 800)
    end
end

function VegasLifeJackPotWinView:onExit()
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    VegasLifeJackPotWinView.super.onExit(self)
end

function VegasLifeJackPotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end
    local name = sender:getName()
    if name == "Button_1" then
        if self.m_click == true then
            return
        end
        gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_click.mp3")

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
            self:jumpCoinsFinish()
            if self.index == 1 then
                util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 700)
            else
                util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 800)
            end

            if not globalData.slotRunData.m_isAutoSpinAction then
                return
            end
        else
            self:jackpotViewOver(function()
                self.m_click = true
                self:runCsbAction("over",false,function()
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end)
            end)
        end
    end
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取
--[[
    自动分享 | 手动分享
]]
function VegasLifeJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function VegasLifeJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function VegasLifeJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function VegasLifeJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return VegasLifeJackPotWinView