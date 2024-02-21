---
--island
--2018年4月12日
--LuxuryDiamondJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local LuxuryDiamondJackPotWinView = class("LuxuryDiamondJackPotWinView", util_require("Levels.BaseLevelDialog"))
LuxuryDiamondJackPotWinView.JACKPOT_NAME_LIST = {"super","grand" , "major" , "minor" ,"mini" }
LuxuryDiamondJackPotWinView.JACKPOT_BG_LIST = {{"jin_zuo", "jin_you"}, {"hong_zuo", "hong_you"}, {"zi_zuo", "zi_you"}, {"lan_zuo", "lan_you"}, {"lv_zuo", "lv_you"}}

LuxuryDiamondJackPotWinView.m_isOverAct = false
LuxuryDiamondJackPotWinView.m_isJumpOver = false

function LuxuryDiamondJackPotWinView:initUI(data)
    self.m_machine = data
    self.m_click = true

    local resourceFilename = "LuxuryDiamond/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

    self.m_boxSpine = util_spineCreate("LuxuryDiamond_SuperFreeSpin", true, true)
    self:findChild("Node_spine"):addChild(self.m_boxSpine)

    self.m_effectLight = util_createAnimation("LuxuryDiamond_tb_guang.csb")
    self:findChild("Node_guang"):addChild(self.m_effectLight)

    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_guang"), true)
end

function LuxuryDiamondJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_machine:stopLineMusic()
    self:createGrandShare(self.m_machine)
    self.m_jackpotIndex = index

    local soundStr = string.format("LuxuryDiamondSounds/LuxuryDiamond_JackPotWinShow%d.mp3", index)

    self.m_bgSoundId =  gLobalSoundManager:playSound(soundStr,false)

    self.m_soundId = gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JackPotWinCoins.mp3",true)

    self.m_index = index
    self.m_coins = coins

    for i,v in ipairs(self.JACKPOT_NAME_LIST) do
        self:findChild(v):setVisible(i == index )
        for j = 1, 2 do
            self:findChild(self.JACKPOT_BG_LIST[i][j]):setVisible(i == index )
        end
    end

    self:jumpCoins(coins )

    
    performWithDelay(self,function(  )
        if not self.m_isJumpOver then
            local node=self:findChild("m_lb_coin")
            node:unscheduleUpdate()
            self.m_isJumpOver = true
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label = node, sx = 1, sy = 1}, 753)
            self:jumpCoinsFinish()
        end
        if self.m_soundId then

            gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)

    util_spinePlay(self.m_boxSpine, "start_jackpot", false)
    util_spineEndCallFunc(self.m_boxSpine, "start_jackpot", function()
        util_spinePlay(self.m_boxSpine, "idle_jackpot", true)
    end)
    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    self.m_effectLight:runCsbAction("idle", true)

    self.m_machine:flyMoney(self:findChild("Particle_1"))

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
    self.m_callFun = callBackFun
end

function LuxuryDiamondJackPotWinView:onEnter()
    LuxuryDiamondJackPotWinView.super.onEnter(self)
end

function LuxuryDiamondJackPotWinView:onExit()
    
    if not self.m_isJumpOver then
        self:findChild("m_lb_coin"):unscheduleUpdate()
        self.m_isJumpOver = true
    end

    if self.m_bgSoundId then
        gLobalSoundManager:stopAudio(self.m_bgSoundId)
        self.m_bgSoundId = nil
    end

    LuxuryDiamondJackPotWinView.super.onExit(self)
end

function LuxuryDiamondJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then

        if self.m_click == true then
            return 
        end
        gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JP_click.mp3")
        if self.m_isJumpOver then
            sender:setTouchEnabled(false)
            self.m_click = true

            local bShare = self:checkShareState()
            if not bShare then
                self:jackpotViewOver(function()
                    self:runCsbAction("over")
            
                    performWithDelay(self,function()
                        if self.m_callFun then
                            self.m_callFun()
                        end
                        self:removeFromParent()
                    end,1)
                end)
            end
        end 

        if not self.m_isJumpOver then
            local node=self:findChild("m_lb_coin")
            node:unscheduleUpdate()
            self.m_isJumpOver = true
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label = node, sx = 1, sy = 1}, 753)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JPCoinsJump_Over.mp3")
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil 
        end
    end
end

function LuxuryDiamondJackPotWinView:jumpCoins(coins )

    local node=self:findChild("m_lb_coin")
    node:setString("")
    local addValue = self.m_coins / (60 * 5)
    util_jumpNum(node,0,self.m_coins,addValue,1/60,{30}, nil, nil,function(  )
        self.m_isJumpOver = true
        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
        self:jumpCoinsFinish()
        gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JPCoinsJump_Over.mp3")
    end,function()
        self:updateLabelSize({label = node, sx = 1, sy = 1}, 753)
    end)
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

--[[
    自动分享 | 手动分享
]]
function LuxuryDiamondJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function LuxuryDiamondJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function LuxuryDiamondJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function LuxuryDiamondJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return LuxuryDiamondJackPotWinView