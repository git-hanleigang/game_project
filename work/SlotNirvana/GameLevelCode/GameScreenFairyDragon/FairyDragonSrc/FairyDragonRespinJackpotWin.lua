---
--xcyy
--2018年5月23日
--FairyDragonRespinJackpotWin.lua

local FairyDragonRespinJackpotWin = class("FairyDragonRespinJackpotWin",util_require("base.BaseView"))


function FairyDragonRespinJackpotWin:initUI()
    self:createCsbNode("FairyDragon/Jackpotwin1.csb")
    self:addClick(self:findChild("touchPanel"))

    self.m_waitActNode = cc.Node:create()
    self:addChild(self.m_waitActNode)
end

function FairyDragonRespinJackpotWin:showWinNum(_coins,_func)
    local node=self:findChild("m_lb_coins")
    node:setString(util_formatCoins(_coins,50))
    self:updateLabelSize({label=node,sx=1,sy=1},656)
    self.m_click = true

    self:runCsbAction("start",false,function(  )
        self.m_click = false
    end)
    
    self.m_callFun = _func
    local node1=self:findChild("m_lb_coins")
    self.m_winCoins = _coins
    self:updateLabelSize({label=node1,sx=1,sy=1},656)
    self:jumpCoins(_coins )

    self.m_JumpSound = gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_jump.mp3",true)
    
    globalData.jackpotRunData:notifySelfJackpot(_coins, 4)
end

function FairyDragonRespinJackpotWin:onEnter()

end

function FairyDragonRespinJackpotWin:onExit()
    if self.m_JumpOver then
        gLobalSoundManager:stopAudio(self.m_JumpOver)
        self.m_JumpOver = nil
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


function FairyDragonRespinJackpotWin:jumpCoins(coins )
    local node=self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (5 * 60)  -- 每秒30帧

    local str = string.gsub(tostring(coinRiseNum),"0", math.random(1,5) )
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},656)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
                gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_stop.mp3")
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},634)
        end
    end)
    performWithDelay(
        self.m_waitActNode,
        function()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_stop.mp3")
                end
            end

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},656)
            
            self.m_click = true

            self:closeUI()
        
        end,
        5
    )
end

function FairyDragonRespinJackpotWin:clickFunc(sender)
    local name = sender:getName()
    if name == "touchPanel" then
        if self.m_click == true then
            return 
        end

        self.m_click = true
        self.m_waitActNode:stopAllActions()

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)


        self:closeUI()
        
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil

            gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_stop.mp3")
            if self.m_JumpSound  then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
        end

        local node=self:findChild("m_lb_coins")
        node:setString(util_formatCoins(self.m_winCoins,50))
        self:updateLabelSize({label=node,sx=1,sy=1},656)

        
    end
end

function FairyDragonRespinJackpotWin:closeUI( )
   
    performWithDelay(self.m_waitActNode,function()
         
        self:runCsbAction("over",false,function(  )

            if self.m_callFun then
                self.m_callFun()
            end
            
        end)

    end,1)

    
end
return FairyDragonRespinJackpotWin