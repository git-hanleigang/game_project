---
--island
--2018年4月12日
--ChicEllaJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local ChicEllaJackPotWinView = class("ChicEllaJackPotWinView", util_require("Levels.BaseLevelDialog"))
local ChicEllaMusic = util_require("CodeChicEllaSrc.ChicEllaMusic")

ChicEllaJackPotWinView.m_isOverAct = false
ChicEllaJackPotWinView.m_isJumpOver = false

function ChicEllaJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "ChicElla/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

end

function ChicEllaJackPotWinView:initViewData(index,coins,mainMachine,callBackFun)
    self:createGrandShare(mainMachine)
    self.m_index = index
    self.m_coins = coins
    
    -- self.m_bgSoundId =  gLobalSoundManager:playSound("ChicEllaSounds/levelsTemple_JackPotWinShow.mp3",false)

    self.m_soundId = gLobalSoundManager:playSound("ChicEllaSounds/sound_ChicElla_jackpot_num_rocking.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins_0")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.52,sy=0.52},1269)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)


    -- 创建光效
    local addEffect = util_createAnimation("ChicElla/JackpotWinView_g.csb")
    self:findChild("ef_g"):addChild(addEffect)
    addEffect:setPosition(0,0)
    addEffect:setVisible(true)
    addEffect:runCsbAction("actionframe", true)

    -- 图标人物
    local addSpine = util_spineCreate("Socre_ChicElla_Wild", true, true)
    self:findChild("spine"):addChild(addSpine)
    addSpine:setPosition(0,0)
    util_spinePlay(addSpine, "idle4", true)


    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)

        
    end)

    local imgName = {"Node_grand_0", "Node_major_0", "Node_minor_0"}
    for k,v in pairs(imgName) do
        local img =  self:findChild(v)
        if img then
            if k == index then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
            
        end
    end

    self.m_callFun = callBackFun


    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function ChicEllaJackPotWinView:onEnter()

    ChicEllaJackPotWinView.super.onEnter(self)
end

function ChicEllaJackPotWinView:onExit()

    ChicEllaJackPotWinView.super.onExit(self)

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
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

function ChicEllaJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end

        local bShare = self:checkShareState()
        if not bShare then
            -- gLobalSoundManager:playSound("ChicEllaSounds/music_levelsTemples_Click_Collect.mp3")
            if self.m_updateCoinHandlerID == nil then
                self:jackpotViewOver(function()
                    sender:setTouchEnabled(false)
                    self.m_click = true

                    self:runCsbAction("over")
                    performWithDelay(self,function()
                        if self.m_callFun then
                            self.m_callFun()
                        end
                        self:removeFromParent()
                    end,1)

                    performWithDelay(self,function()
                        self:findChild("ef_g"):removeAllChildren()
                    end, 20/60)

                    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                end)
            else
                local waitTimes = 0
                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                    local node=self:findChild("m_lb_coins_0")
                    node:setString(util_formatCoins(self.m_coins,50))
                    self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)
    
                    waitTimes = 2
                    self:jumpCoinsFinish()
                end
            end 

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
        end
    end
end

function ChicEllaJackPotWinView:jumpCoins(coins )

    local node=self:findChild("m_lb_coins_0")
    node:setString("")

    local coinRiseNum =  coins / (4 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self:findChild("m_lb_coins_0")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)

            self.m_isJumpOver = true

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

            self:jumpCoinsFinish()

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

            gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_jackpot_num_end)
        else
            local node=self:findChild("m_lb_coins_0")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)
        end
    end)
end

--[[
    自动分享 | 手动分享
]]
function ChicEllaJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function ChicEllaJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_index)
    end
end

function ChicEllaJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function ChicEllaJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return ChicEllaJackPotWinView

