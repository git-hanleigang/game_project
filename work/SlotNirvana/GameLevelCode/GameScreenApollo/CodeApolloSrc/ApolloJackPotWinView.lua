
local ApolloJackPotWinView = class("ApolloJackPotWinView", util_require("base.BaseView"))

ApolloJackPotWinView.m_isOverAct = false
ApolloJackPotWinView.m_isJumpOver = false

function ApolloJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "Apollo/Jackpot.csb"
    self:createCsbNode(resourceFilename)

    local dajuese = util_spineCreate("Socre_Apollo_Abo",true,true)
    self:findChild("Node_Apollo"):addChild(dajuese)
    util_spinePlay(dajuese,"idleframe2",true)
end

function ApolloJackPotWinView:initViewData(machine,index,coins,multiple,callBackFun)
    self:createGrandShare(machine)
    self.m_jackpotIndex = index

    self.m_index = index
    self.m_coins = coins
    if multiple == nil then
        self.m_multiple = 1
    else
        self.m_multiple = multiple
    end
    self.m_currcoins = 0

    self.m_bgSoundId = gLobalSoundManager:playSound("ApolloSounds/music_Apollo_JackPotWinShow.mp3",false)

    if self.m_multiple == 1 then
        self:findChild("m_lb_coins"):setString("")
        self:startNumJump()
    else
        self.m_currcoins = math.floor(self.m_coins/self.m_multiple)
        self:findChild("m_lb_coins"):setString(util_formatCoins(self.m_currcoins,50))
    end

    self:runCsbAction("start",false,function()
        if self.m_multiple == 1 then
            self.m_click = false
        else
            local multipleNode = util_createAnimation("Apollo/Jackpot_chengbei.csb")
            self:findChild("chengbei"):addChild(multipleNode)
            multipleNode:findChild("BitmapFontLabel_1"):setString(self.m_multiple.."X")
            multipleNode:playAction("chengbei")
            performWithDelay(self,function ()
                self:startNumJump()
                self.m_click = false
            end,30/60)
        end
        self:runCsbAction("idle",true)
    end)

    local imgName = {"Apollo_jackpot_tanban_grand","Apollo_jackpot_tanban_major","Apollo_jackpot_tanban_minor","Apollo_jackpot_tanban_mini"}
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
function ApolloJackPotWinView:startNumJump()
    self.m_soundId = gLobalSoundManager:playSound("ApolloSounds/music_Apollo_JackPotWinCoins.mp3",true)
    self:jumpCoins(self.m_currcoins, self.m_coins)

    performWithDelay(self,function()
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label = node,sx = 0.5,sy = 0.5},1252)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)
end
function ApolloJackPotWinView:onEnter()
end

function ApolloJackPotWinView:onExit()
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

function ApolloJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_collect" then

        if self.m_click == true then
            return
        end

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        if self.m_updateCoinHandlerID == nil then
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

        local waitTimes = 0
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)
            self:jumpCoinsFinish()

            waitTimes = 2
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end
end

function ApolloJackPotWinView:jumpCoins(currcoins,endcoins )
    local node = self:findChild("m_lb_coins")
    local coinRiseNum =  (endcoins - currcoins) / (4 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum )

    local curCoins = currcoins

    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()
        curCoins = curCoins + coinRiseNum

        if curCoins >= endcoins then

            curCoins = endcoins

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)
            self:jumpCoinsFinish()

            self.m_isJumpOver = true

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)
        end
    end)
end

--[[
    自动分享 | 手动分享
]]
function ApolloJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function ApolloJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function ApolloJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function ApolloJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return ApolloJackPotWinView