---
--island
--2018年4月12日
--PelicanJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local PelicanJackPotWinView = class("PelicanJackPotWinView", util_require("base.BaseView"))


local GrandId = 1
local MajorId = 2
local MinorId = 3
local MiniId  = 1

function PelicanJackPotWinView:initUI(_machine)

    local resourceFilename = "Pelican/Jackpotover.csb"
    self:createCsbNode(resourceFilename)

    self.m_click = true
    self:createGrandShare(_machine)
end

function PelicanJackPotWinView:initShow(index)
    --人物
    self.jueSe = util_spineCreate("Pelican_juese2",true,true)
    self:findChild("Node_renwu"):addChild(self.jueSe)

    local imgName = {{"grand_bg","Pelican_grand"},{"major_bg","Pelican_major"},{"minor_bg","Pelican_minor"},{"mini_bg","Pelican_mini"}}
    for i,v in ipairs(imgName) do
        if i == index then
            self:findChild(v[1]):setVisible(true)
            self:findChild(v[2]):setVisible(true)
        else
            self:findChild(v[1]):setVisible(false)
            self:findChild(v[2]):setVisible(false)
        end
    end
end


function PelicanJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_jackpotIndex = index

    self.m_winCoins = coins
    self.m_callFun = callBackFun
    if index == 1 or index == 2 then
        self.m_JPSound = gLobalSoundManager:playSound("PelicanSounds/music_Pelican_respin_jackpot1.mp3",false)
    else
        self.m_JPSound = gLobalSoundManager:playSound("PelicanSounds/music_Pelican_respin_jackpot2.mp3",false)
    end
    self.m_JumpSound =  gLobalSoundManager:playSound("PelicanSounds/Pelican_jackpot_jump.mp3",true)
    self:jumpCoins(coins )

    self:initShow(index)
    util_spinePlay(self.jueSe,"actionframe2",false)
    util_spineEndCallFunc(self.jueSe,"actionframe2",function (  )
        util_spinePlay(self.m_spineTanban,"idleframe",true)
    end)
    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1050)
            self:jumpCoinsFinish()
        end

        if self.m_JumpSound then
            gLobalSoundManager:stopAudio(self.m_JumpSound)
            gLobalSoundManager:playSound("PelicanSounds/Pelican_jackpotCoinsOver.mp3")
            self.m_JumpSound = nil
        end
    end,4)
    
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function PelicanJackPotWinView:onEnter()
    PelicanJackPotWinView.super.onEnter(self)
    --解决进入横版活动时再切换回关卡 弹板位置不对问题
    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
                local csbNodeName = self.m_csbNode:getName()
                if csbNodeName == "Layer" then
                    self:changeVisibleSize(display.size)
                else
                    if not self.m_isUserDefPos then
                        -- 使用的屏幕大小换算的坐标
                        local posX, posY = self:getPosition()
                        self:setPosition(cc.p(posY, posX))
                    end
                end
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    end
end

function PelicanJackPotWinView:onExit()

    if self.m_JPSound then
        gLobalSoundManager:stopAudio(self.m_JPSound)
        self.m_JPSound = nil
    end

    if self.m_JumpSound then
        gLobalSoundManager:stopAudio(self.m_JumpSound)
        self.m_JumpSound = nil
    end

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

end


function PelicanJackPotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end

        if self.m_JPSound then
            gLobalSoundManager:stopAudio(self.m_JPSound)
            self.m_JPSound = nil
        end
        
        
        if self.m_JumpSound then
            gLobalSoundManager:stopAudio(self.m_JumpSound)
            gLobalSoundManager:playSound("PelicanSounds/Pelican_jackpotCoinsOver.mp3")
            self.m_JumpSound = nil
        end

        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil

            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1050)
            self:jumpCoinsFinish()
        else
            self.m_click = true
            self:jackpotViewOver(function()
                self:runCsbAction("over")
                performWithDelay(self,function()
                    if self.m_callFun then
                        self.m_callFun()
                    end

                end,23/60)
                performWithDelay(self,function (  )
                    self:removeFromParent()
                end,5/3)
            end)
        end
    end
end

function PelicanJackPotWinView:jumpCoins(coins )

    local node =self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (3 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()
        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then
            curCoins = coins

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1050)
            self:jumpCoinsFinish()

            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                gLobalSoundManager:playSound("PelicanSounds/Pelican_jackpotCoinsOver.mp3")
                self.m_JumpSound = nil
            end

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1050)
        end
    end)
end

--[[
    自动分享 | 手动分享
]]
function PelicanJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function PelicanJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function PelicanJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function PelicanJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return PelicanJackPotWinView