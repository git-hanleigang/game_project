---
--island
--2018年4月12日
--CandyPusherBonusOverView.lua
local CandyPusherBonusOverView = class("CandyPusherBonusOverView", util_require("Levels.BaseLevelDialog"))


CandyPusherBonusOverView.m_isOverAct = false
CandyPusherBonusOverView.m_isJumpOver = false

function CandyPusherBonusOverView:initUI(data)
    self.m_click = true

    local resourceFilename = "CandyPusher/BonusOver.csb"
    
    self:createCsbNode(resourceFilename)
    if display.height >= display.width then
        if display.height <= 1228 then
            self:findChild("root"):setScale(self:getUIScalePro())
        end
    else
        if display.width <= 1228 then
            self:findChild("root"):setScale(self:getUIScalePro())
        end
    end
    
end

function CandyPusherBonusOverView:initViewData(coins,callBackFun)

    self.m_coins = coins

    self.m_bgSoundId =  gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_PusherOverView.mp3",false,function(  )
        self.m_bgSoundId = nil
    end)

    local node=self:findChild("m_lb_coins")
    node:setString(util_formatCoins(self.m_coins,50))
    self:updateLabelSize({label=node,sx=1,sy=1},685)


    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

  
    self.m_callFun = callBackFun

end

function CandyPusherBonusOverView:onEnter()
    CandyPusherBonusOverView.super.onEnter(self)
end

function CandyPusherBonusOverView:onExit()

    CandyPusherBonusOverView.super.onExit(self)



    if self.m_bgSoundId then
       gLobalSoundManager:stopAudio(self.m_bgSoundId)
        self.m_bgSoundId = nil
    end
    
    gLobalNoticManager:removeAllObservers(self)
end

function CandyPusherBonusOverView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end
        self.m_click = true
        gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_Click.mp3")  
        
        if self.m_callFun then
            self.m_callFun()
        end

    end
end



return CandyPusherBonusOverView