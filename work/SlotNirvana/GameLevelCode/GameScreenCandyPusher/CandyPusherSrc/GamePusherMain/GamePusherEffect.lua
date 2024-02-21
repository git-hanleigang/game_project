--[[
    GamePusherEffect
    tm
]]

local Config    = require("CandyPusherSrc.GamePusherMain.GamePusherConfig")
local GamePusherManager   = require "CandyPusherSrc.GamePusherManager"


local GamePusherEffect  = class( "GamePusherEffect" , function ()
    local layer = cc.Layer:create()
    return layer
end)


function GamePusherEffect:ctor( mainLayer )
    self._Main = mainLayer
    self.m_pGamePusherMgr  =  GamePusherManager:getInstance()

    self._effectRoot = cc.Sprite3D:create()
    self:addChild(self._effectRoot)
end

-- Play Effect --
function GamePusherEffect:playEffect( nType, pCall , sStatus )
    if nType == Config.Effect.Hammer.ID then
        self:hammerEffect( pCall )
    elseif nType == Config.Effect.FlashLight.ID then
        self:flashLightEffect( 1 )
    elseif nType == Config.Effect.FrontEffectPanel.ID then
        self:frontEffect( sStatus )
    elseif nType == Config.Effect.TapHere.ID then
        self:taphereEffect( 1 )
    elseif nType == Config.Effect.JackpotEffectPanel.ID then
        self:jackpotEffect( sStatus )
    end
end

-- Tick Effect --
function GamePusherEffect:tickEffect( dt )
    self:flashLightTick( dt )
    self:jackpotTick( dt )
    self:frontEffTick( dt )
end

---------------------------------------两侧闪灯特效 S---------------------------------------
function GamePusherEffect:flashLightEffect( nType )
    if self._flashLight == nil then
        local itemAtt   = Config.Effect.FlashLight
        self._flashLight    = cc.Sprite3D:create( itemAtt.Model )
        self._flashLight:setCameraMask(cc.CameraFlag.USER1)
        self:addChild(self._flashLight)
        self._flashLight:setScale( itemAtt.Scale )
        self._flashLight:setRotation3D( cc.vec3( -90 , 180.0,  0.0) )
        self._flashLight:setTexture( itemAtt.Texture )
        
        -- 获取模型中 单个小片儿的指针 --
        self._lightList = {}
        for i = 1 , 16 do
            local node = self._flashLight:getChildByName("p"..i)
            node:setVisible(false)
            self._lightList[i] = node
            node:setTexture( itemAtt.Texture2 )

            node = self._flashLight:getChildByName( "p"..(100+i) )
            node:setTexture( itemAtt.Texture2 )
            node:setVisible(false)
            self._lightList[i+100] = node
        end
    end
end
function GamePusherEffect:flashLightTick( dt )

    if self._flashLight == nil then
        return
    end

    if self._flashLightDurTime == nil then
        self._flashLightDurTime = 0
        self._flashLightCurIndex= 0
    end

    self._flashLightDurTime = self._flashLightDurTime + dt
    if self._flashLightDurTime < 0.05 then
        return    
    end

    self._flashLightDurTime = 0

    local preNode = self._lightList[self._flashLightCurIndex]
    if preNode ~= nil then
        preNode:setVisible(false)
    end
    preNode = self._lightList[self._flashLightCurIndex+100]
    if preNode ~= nil then
        preNode:setVisible(false)
    end

    self._flashLightCurIndex = self._flashLightCurIndex + 1
    if self._flashLightCurIndex > 16 then
        self._flashLightCurIndex = 1
    end

    local nextNode = self._lightList[self._flashLightCurIndex]
    if nextNode ~= nil then
        nextNode:setVisible( true )
    end

    nextNode = self._lightList[self._flashLightCurIndex+100]
    if nextNode ~= nil then
        nextNode:setVisible( true )
    end
   
end
---------------------------------------两侧闪灯特效 E---------------------------------------

---------------------------------------大锤特效 S -----------------------------------------
function GamePusherEffect:hammerEffect( pCall  )

    if self._hammer == nil then
        local itemAtt   = Config.Effect.Hammer
        self._hammer    = cc.Sprite3D:create( itemAtt.Model )
        self._hammer:setCameraMask(cc.CameraFlag.USER1)
        self:addChild(self._hammer)
        self._hammer:setScale( itemAtt.Scale )

        self._hammerOriPos = cc.vec3(0.0, 5.0, 27.0)
        self._hammerOriRot = cc.vec3(-90.0, 180.0,  0.0)
        self._hammerDestRot= cc.vec3( 0, 180.0,  0.0   )
        
        self._hammerRunning  = false
    end

    if self._hammerRunning == true then
        print("Hammer is Running , wait please.")
        return
    end


    self._hammer:setRotation3D( self._hammerOriRot )
    self._hammer:setPosition3D( self._hammerOriPos )
    self._hammer:setVisible( true )
    self._hammer:setOpacity( 255 )
    self._hammerRunning = true
    
    local move = cc.RotateTo:create( 0.3 , self._hammerDestRot )
    local fade = cc.FadeOut:create(1.0 )
    local moveFunc = function(  )
       
        if pCall ~= nil then
            pCall()
        end
        -- 光片 --
        local itemAtt       = Config.Effect.Hammer
        local hammerGuang   = cc.Sprite3D:create( itemAtt.ModelGuang )
        hammerGuang:setCameraMask(cc.CameraFlag.USER1)
        self:addChild(hammerGuang)
        hammerGuang:setScale( itemAtt.Scale )
        hammerGuang:setPosition3D( cc.vec3(0.0, 0.2, 10.0) )
        hammerGuang:setRotation3D( cc.vec3(-90.0, 180.0,  0.0) )

        local scale = cc.ScaleTo:create( 0.2 , 20 )
        local fade  = cc.FadeOut:create( 0.5 )
        local done  = function (  )
            hammerGuang:removeFromParent()
        end
        hammerGuang:runAction(cc.Sequence:create( scale , fade , cc.CallFunc:create(done) ) )


    end
    local fadeFunc  = function(  )
        -- reset data --
        self._hammer:setRotation3D( self._hammerOriRot )
        self._hammer:setPosition3D( self._hammerOriPos )
        self._hammer:setVisible( false )
        self._hammerRunning  = false

    end
    self._hammer:runAction(cc.Sequence:create( move , cc.CallFunc:create(moveFunc) , fade , cc.CallFunc:create(fadeFunc) ) )

end

---------------------------------------金币掉落位置播放动画 S------------------------------------------

function GamePusherEffect:createCoinWinDropEffect(vPos)

    local winDropEffect = util_createAnimation("CandyPusherMainUI/CoinPusher_XFlizi.csb")
    winDropEffect:setScale(0.03)
    self._effectRoot:addChild(winDropEffect)
    winDropEffect:setCameraMask(cc.CameraFlag.USER1)
    winDropEffect:setPosition3D(vPos)
    winDropEffect:playAction("actionframe",false,function(  )
        if not tolua.isnull(winDropEffect) then
            winDropEffect:removeFromParent()
        end
    end)
end

---------------------------------------jackpot面板 S---------------------------------------
function GamePusherEffect:jackpotEffect( sStatus )
    if self._jackpotEffect == nil then
        local itemAtt       = Config.Effect.JackpotEffectPanel
        self._jackpotEffect = cc.Sprite3D:create( itemAtt.Model )
        self._jackpotEffect:setCameraMask(cc.CameraFlag.USER1)
        self:addChild(self._jackpotEffect)
        self._jackpotEffect:setScale( itemAtt.Scale )
        self._jackpotEffect:setRotation3D( cc.vec3( 0 , 180.0,  0.0) )
        self._jackpotEffect:setPosition3D( cc.vec3( 0 , -1.5,  0.0) )
        self._jackpotEffect:setTexture( itemAtt.Texture )
    end

    if self._jackpotEffectActionType == sStatus then
        print("Same front panal effect type")
        return
    end

    self._jackpotEffectActionType = sStatus
    self._jackpotEffectIndex      = 0
    self._jackpotEffDurTime       = 0

end
function GamePusherEffect:jackpotTick( dt )

    if self._jackpotEffect == nil then
        return
    end

    self._jackpotEffDurTime = self._jackpotEffDurTime + dt

    if self._jackpotEffectActionType == "Idle" then
        if self._jackpotEffDurTime < Config.JackPotEffectPic.IdleInterval  then
            return
        end
        self._jackpotEffectIndex = self._jackpotEffectIndex + 1
        if self._jackpotEffectIndex > table.nums(Config.JackPotEffectPic.Idle) then
            self._jackpotEffectIndex = 1
        end
        self._jackpotEffect:setTexture( Config.JackPotEffectPic.Idle[self._jackpotEffectIndex] )
    elseif self._jackpotEffectActionType == "Flash" then
        if self._jackpotEffDurTime < Config.JackPotEffectPic.FlashInterval then
            return
        end
        self._jackpotEffectIndex = self._jackpotEffectIndex + 1
        if self._jackpotEffectIndex > table.nums(Config.JackPotEffectPic.Flash) then
            self._jackpotEffectIndex = 1
        end
        self._jackpotEffect:setTexture( Config.JackPotEffectPic.Flash[self._jackpotEffectIndex] )
    end

    self._jackpotEffDurTime = 0

end

---------------------------------------台前特效面板 S---------------------------------------
function GamePusherEffect:frontEffect( sStatus )
    if self._frontEffect == nil then
        local itemAtt       = Config.Effect.FrontEffectPanel
        self._frontEffect = cc.Sprite3D:create( itemAtt.Model )
        self._frontEffect:setCameraMask(cc.CameraFlag.USER1)
        self:addChild(self._frontEffect)
        self._frontEffect:setScale( itemAtt.Scale )
        self._frontEffect:setRotation3D( cc.vec3( 0 , 180.0,  0.0) )
        self._frontEffect:setVisible(false)
        self._frontEffect:setTexture( Config.FrontEffectPic.Idle[1] )
    end

    if self._frontEffectActionType == sStatus then
        print("Same front panal effect type")
        return
    end
    self._frontEffectActionType = sStatus
    self._frontEffectIndex      = 0
    self._frontEffDurTime       = 0

end
function GamePusherEffect:frontEffTick( dt )

    if self._frontEffect == nil then
        return
    end

    self._frontEffDurTime = self._frontEffDurTime + dt

    if self._frontEffectActionType == "Idle" then
        if self._frontEffDurTime < Config.FrontEffectPic.IdleInterval  then
            return
        end
        self._frontEffectIndex = self._frontEffectIndex + 1
        if self._frontEffectIndex > table.nums(Config.FrontEffectPic.Idle) then
            self._frontEffectIndex = 1
        end
        self._frontEffect:setTexture( Config.FrontEffectPic.Idle[self._frontEffectIndex] )
    elseif self._frontEffectActionType == "Flash" then
        if self._frontEffDurTime < Config.FrontEffectPic.FlashInterval then
            return
        end
        self._frontEffectIndex = self._frontEffectIndex + 1
        if self._frontEffectIndex > table.nums(Config.FrontEffectPic.Flash) then
            self._frontEffectIndex = 1
        end
        self._frontEffect:setTexture( Config.FrontEffectPic.Flash[self._frontEffectIndex] )
    end

    self._frontEffDurTime = 0

end
---------------------------------------特殊金币掉落动画 S------------------------------------------

function GamePusherEffect:initDropEffect()
    if self._LightDrop == nil then
        local sp = cc.Sprite3D:create()
        self:addChild(sp)
        self._LightDrop = util_createAnimation( Config.UICsbPath.DropCoinsLight)
        self._LightDrop:setScale(0.03)
        sp:addChild(self._LightDrop)
        self._LightDrop:setCameraMask(cc.CameraFlag.USER1)
        self._LightDrop:setPosition3D( cc.vec3(0, 20, -10))
        self._LightDrop:setVisible(false)
    end
end

function GamePusherEffect:playDropEffect()
    self._LightDrop:setVisible(true)
    self._LightDrop:playAction("idle2",false)
end

---------------------------------------Taphere面板 S---------------------------------------
function GamePusherEffect:taphereEffect( nType )

    if self._taphereEffect == nil then
        local itemAtt       = Config.Effect.TapHere
        self._taphereEffect = cc.Sprite3D:create( itemAtt.Model )

        self._taphereEffect:setCameraMask(cc.CameraFlag.USER1)
        self._effectRoot:addChild(self._taphereEffect)
        self._taphereEffect:setTexture(itemAtt.Texture)
        -- itemAtt.Scale
        self._taphereEffect:setScale(8)
        self._taphereEffect:setRotation3D( cc.vec3(-90 , 180,  0.0) )
        self._taphereEffect:setPosition3D( cc.vec3( 0 , 3.5, -8) )
    end

    if  self._tapHereEffectAction  then

        if self.m_pGamePusherMgr:checkPusherDropTimesUseUp( ) then
            if self._taphereEffect:isVisible() then
            end
            self._taphereEffect:setVisible(false)
        else
            self._taphereEffect:setVisible(true)
        end 

        return
    end

    self._taphereEffect:setOpacity( 0 )
    local fadeIn    = cc.FadeIn:create(1)
    local fadeOut   = fadeIn:reverse()
    local seq       = cc.Sequence:create( fadeIn , fadeOut)  
    self._tapHereEffectAction =  self._taphereEffect:runAction(cc.RepeatForever:create(seq))



end


function GamePusherEffect:stopTaphereEffect( )
    if self._tapHereEffectAction then
        self._taphereEffect:stopAction(self._tapHereEffectAction)
        self._taphereEffect:setOpacity( 0 )
        self._tapHereEffectAction = nil
    end
end


return GamePusherEffect