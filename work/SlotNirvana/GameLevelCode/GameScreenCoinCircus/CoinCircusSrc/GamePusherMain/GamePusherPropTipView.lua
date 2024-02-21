local GamePusherPropView = class("GamePusherPropView", util_require("base.BaseView"))
local Config              = require("CoinCircusSrc.GamePusherMain.GamePusherConfig")
local GamePusherManager   = require "CoinCircusSrc.GamePusherManager"

GamePusherPropView.m_states = "idle"
GamePusherPropView.m_ShowStates = "close"

local VEC_PROP_TIP =
{
    shakeMaxUseNum = "CoinCircus_daoju_shouji_Tip_shake.csb",
    wallMaxUseNum = "CoinCircus_daoju_shouji_Tip_wall.csb",
    bigCoinMaxUseNum = "CoinCircus_daoju_shouji_Tip_huge.csb"
}

function GamePusherPropView:ctor( )

   

    self.m_pGamePusherMgr  =  GamePusherManager:getInstance()

    GamePusherPropView.super.ctor(self )
    
end

function GamePusherPropView:initUI(_propView)

    self.m_propView = _propView
    
    self:createCsbNode("CoinCircus_daoju_shouji_Tip.csb", false)
    self:runCsbAction("idle")

    self.m_waitNode = cc.Node:create()
    self:addChild(self.m_waitNode)

    self.m_animWaitNode = cc.Node:create()
    self:addChild(self.m_animWaitNode)

    self:addClick(self:findChild("click"))

    util_setCascadeOpacityEnabledRescursion(self,true)

end

function GamePusherPropView:quickCloseTip( )
   
    self.m_waitNode:stopAllActions()
    self.m_animWaitNode:stopAllActions()

    self:runCsbAction("idle")

    self.m_states = "idle"
    self.m_ShowStates = "close"
    
end

function GamePusherPropView:clickFunc(sender)


    local btnName = sender:getName()
    
    gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_Click.mp3")  

    if btnName == "Button_i" or "click" then
        if self.m_states == "idle" then
            if self.m_ShowStates == "close" then
                self:showTip( )
            else
                self:hideTip( )
            end
        end
        
    end

end

function GamePusherPropView:showTip( )

    self.m_animWaitNode:stopAllActions()
    self.m_waitNode:stopAllActions()

    self.m_states = "start"
    self:runCsbAction("start")

    performWithDelay(self.m_animWaitNode,function(  )
        self.m_states = "idle"
        self.m_ShowStates = "open"
    end,39/60)

    performWithDelay(self.m_waitNode,function(  )
        self:hideTip( )
    end,5)
end

function GamePusherPropView:hideTip( )
    self.m_animWaitNode:stopAllActions()
    self.m_waitNode:stopAllActions()

    self.m_states = "over"
    self:runCsbAction("over")

    performWithDelay(self.m_animWaitNode,function(  )
        
        self.m_states = "idle"
        self.m_ShowStates = "close"
    end,39/60)

end

function GamePusherPropView:updateUI(num)
    if num > 0 then
        local index = 1
        while true do
            local node = self:findChild("Image_"..index)
            if node ~= nil then
                if index == num then
                    node:setVisible(true)
                else
                    node:setVisible(false)
                end
            else
                break
            end
            index = index + 1
        end
    end
end

function GamePusherPropView:addTipWords(index, propName)
    local parent = self:findChild("word_"..index)
    local csbName = VEC_PROP_TIP[propName]
    if parent ~= nil and csbName ~= nil then
        local words = util_createAnimation(csbName)
        parent:addChild(words)
    end
end

function GamePusherPropView:removeAllTipWords()
    local index = 1
    while true do
        local parent = self:findChild("word_"..index)
        if parent ~= nil then
            parent:removeAllChildren()
        else
            break
        end
        index = index + 1
    end
end

function GamePusherPropView:onEnter()

end


function GamePusherPropView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end


return GamePusherPropView