---
--island
--2018年4月12日
--ClassicCashJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local ClassicCashJackPotWinView = class("ClassicCashJackPotWinView", util_require("base.BaseView"))
local PublicConfig = require "ClassicCashPublicConfig"

function ClassicCashJackPotWinView:initUI()

    self:createCsbNode("ClassicCash/ClassicCash_jackpotView.csb")
    self.m_isCanTouch = false

    self.textReward = self:findChild("m_lb_coins")
    
    self:findChild("Button"):setTouchEnabled(false)

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
        -- self:jumpCoinsFinish()
        self:findChild("Button"):setTouchEnabled(true)
        self.m_isCanTouch = true 
    end)
end

function ClassicCashJackPotWinView:onExit()
    ClassicCashJackPotWinView.super.onExit(self)
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

function ClassicCashJackPotWinView:updateCoins(coins)
    -- local lab = self:findChild("m_lb_coins") 
    -- if lab and coins then
    --     lab:setString(util_formatCoins(coins,50))

    --     self:updateLabelSize({label=lab,sx=1,sy=1},630)
    -- end

    self.textReward:setString("")
    local coinRiseNum =  coins / (5 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins
            
            self.textReward:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},630)

            self:jumpCoinsFinish()

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Stop)
        else
            self.textReward:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},630)
        end
    end)
end

function ClassicCashJackPotWinView:updateJackPotTitle(jackType)
    local nameList = {
        "Node_mini", 
        "Node_minor",
        "Node_major", 
        "Node_grand", 
    }
    local bgList = {
        "ClassicCash_tb_kuang4_mini", 
        "ClassicCash_tb_kuang3_minor",
        "ClassicCash_tb_kuang2_major", 
        "ClassicCash_tb_kuang1_grand", 
    }
    for i,v in ipairs(nameList) do
        local node = self:findChild(v)      
        if(node)then
            node:setVisible(i==jackType)
        end
    end

    for i,v in ipairs(bgList) do
        local node = self:findChild(v)      
        if(node)then
            node:setVisible(i==jackType)
        end
    end
end

function ClassicCashJackPotWinView:initCallFunc(machine, strCoins, jackPotType,func)
    self.m_func = func
    self:createGrandShare(machine)
    self.m_jackpotIndex = 4 - jackPotType + 1

    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Coins)
    self:updateJackPotTitle(jackPotType)
    self.m_rewardCoins = strCoins
    self:updateCoins(strCoins)
end

--默认按钮监听回调
function ClassicCashJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    
    if self.m_isCanTouch then
        if name == "Button" then
            local bShare = self:checkShareState()
            if not bShare then
                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
    
                    if self.m_soundId then
                        gLobalSoundManager:stopAudio(self.m_soundId)
                        self.m_soundId = nil
                    end
                    gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Stop)
    
                    self.textReward:setString(util_formatCoins(self.m_rewardCoins,50))
                    self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},630)
    
                    self:jumpCoinsFinish()
                    performWithDelay(self,function(  )
                        self:hideSelf(true)
                    end,1.5)
                else
                    gLobalSoundManager:playSound(PublicConfig.Music_Normal_Click)
                    self:hideSelf(true)
                end
            end
        end
    end
end

function ClassicCashJackPotWinView:hideSelf(hideState)
    if self.isHide then
        return
    end
    self:jackpotViewOver(function()
        self.m_isCanTouch = false
        self.isHide = hideState
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Dialog_Over)
        self:runCsbAction("over", false, function()
            if type(self.m_func) == "function" then
                self.m_func()
            end
            self:removeFromParent()
        end)
    end)
end


--[[
    自动分享 | 手动分享
]]
function ClassicCashJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function ClassicCashJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function ClassicCashJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function ClassicCashJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return ClassicCashJackPotWinView