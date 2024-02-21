--[[
    GamePusherDebug
    tm
]]
local Config    = require("CandyPusherSrc.GamePusherMain.GamePusherConfig")
local GamePusherManager   = require "CandyPusherSrc.GamePusherManager"

local GamePusherDebug = class( "GamePusherDebug" , function ()
    local layer = cc.Layer:create()
    return layer
end)


function GamePusherDebug:ctor( mainLayer )
    self._Main = mainLayer
    self.m_pGamePusherMgr = GamePusherManager:getInstance()                  -- Mgr对象
end


-------------------------------------------------- Debug Function S------------------------------------------------
-- Init Debug Pro --
function GamePusherDebug:InitDebugPro(  )
    -- 设置触摸操作 来操作摄像机 --
    local listener = cc.EventListenerTouchAllAtOnce:create()
    -- touch begin --
    listener:registerScriptHandler(function(touches, event)
    end,cc.Handler.EVENT_TOUCHES_BEGAN)

    -- touch move --
    listener:registerScriptHandler(function(touches, event)
        
        if #touches > 0 and self._Main.m_pCamera ~= nil then
            local touch = touches[1]
            local delta = touch:getDelta()

            if self._posY == nil then
                self._posY = self._Main.m_nDistance
            end
            self._posY = self._posY - delta.y

            self._Main.m_nAngle = self._Main.m_nAngle - delta.x * math.pi / 180.0
            self._Main.m_pCamera:setPosition3D(cc.vec3(  self._Main.m_nDistance * math.sin(self._Main.m_nAngle), self._posY , self._Main.m_nDistance * math.cos(self._Main.m_nAngle)))
            self._Main.m_pCamera:lookAt( self._Main.m_v3LookAtOri , cc.vec3(0.0, 1.0, 0.0))
            print("x "..self._Main.m_nDistance * math.sin(self._Main.m_nAngle))
            print("y "..self._posY)
            print("z "..self._Main.m_nDistance * math.cos(self._Main.m_nAngle))
        end
    end, cc.Handler.EVENT_TOUCHES_MOVED)
  
    listener:registerScriptHandler(function(touches, event)
    end, cc.Handler.EVENT_TOUCHES_ENDED)

    -- touch ended --
    if not Config.FixCarmer then
        local eventDispatcher = self:getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)    
    end

    self._debugUIRoot = cc.Node:create()
    self:addChild( self._debugUIRoot )

    -- A button , Show debug UI --
    local debugUIBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    self._debugUIRootShow = true
    debugUIBtn:setTitleText("On")
    debugUIBtn:setPosition(  80 ,  display.height - 580 )
    debugUIBtn:addClickEventListener(function(sender)
        self._debugUIRootShow = not self._debugUIRootShow
        if self._debugUIRootShow then
            self._debugUIRoot:setVisible( true )
            debugUIBtn:setTitleText("ON")
        else
            self._debugUIRoot:setVisible( false)
            debugUIBtn:setTitleText("OFF")
        end
    end)
    debugUIBtn:setScale(1.5)
    self:addChild(debugUIBtn)

    -- A button , initDesktop--
    local initCoinPuser = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    initCoinPuser:setTitleText("盘面")
    self._debugInitDesktop = false
    initCoinPuser:setPosition(  80 ,  display.height - 620 )
    initCoinPuser:addClickEventListener(function(sender)
        self._debugInitDesktop = not self._debugInitDesktop
        if  self._debugInitDesktop  then
            initCoinPuser:setTitleText("盘面 ON")
            self._Main:initDesktopDebugLayer()

            self._debugUIRoot:setVisible( false )
            debugUIBtn:setTitleText("OFF")
            self._debugUIRootShow = false
  
        else
            initCoinPuser:setTitleText("盘面 OFF")
            self._Main:removeDesktopDebugLayer()

            self._debugUIRoot:setVisible( true )
            debugUIBtn:setTitleText("ON")
            self._debugUIRootShow = true
        end
    end)
    initCoinPuser:setScale(1.5)
    self:addChild(initCoinPuser)


    -- A text ， for process log --
    self._logLabel = cc.Label:createWithSystemFont( "Log", "", 24)
    self._logLabel:setAnchorPoint( cc.p( 0.5 , 0.5 ) )
    self._logLabel:setPosition( cc.p( display.cx, 20 ) )
    self._debugUIRoot:addChild( self._logLabel )
    self.ShowLog = function( pThis , sLog )
        self._logLabel:setString( sLog )
    end



    -- A button ，change debugshow --
    local debugDrawBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    debugDrawBtn:setTitleText("DebugDraw OFF")
    debugDrawBtn:setPosition(  80 ,  display.height - 660 )
    debugDrawBtn:addClickEventListener(function(sender)
        if self._Main.m_pPhysicsWorld:isDebugDrawEnabled() then
            self._Main.m_pPhysicsWorld:setDebugDrawEnable(false)
            debugDrawBtn:setTitleText("DebugDraw OFF")
            self:ShowLog("DebugDraw OFF")
        else
            self._Main.m_pPhysicsWorld:setDebugDrawEnable(true)
            debugDrawBtn:setTitleText("DebugDraw ON")
            self:ShowLog("DebugDraw ON")
        end
    end)
    debugDrawBtn:setScale(1.5)
    self._debugUIRoot:addChild(debugDrawBtn)

    -- A button , Look at pusher --
    local lookAtPusherBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    lookAtPusherBtn:setTitleText( "LookAt Pusher" )
    lookAtPusherBtn:setPosition(  display.width - 80 ,  display.height - 400 )
    lookAtPusherBtn:addClickEventListener(function(sender)
        self._Main:MoveCamera( 3 , 0.5 )
        self:ShowLog( "Look at pusher" )
    end)
    lookAtPusherBtn:setScale(1.5)
    self._debugUIRoot:addChild(lookAtPusherBtn)

    -- A button , Look at reeltable --
    local lookAtReelBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    lookAtReelBtn:setTitleText( "LookAt base Slot" )
    lookAtReelBtn:setPosition(  display.width - 80 ,  display.height - 440 )
    lookAtReelBtn:addClickEventListener(function(sender)
        self._Main:MoveCamera( 2 , 0.5 )
        self:ShowLog( "Look at slot" )
    end)
    lookAtReelBtn:setScale(1.5)
    self._debugUIRoot:addChild(lookAtReelBtn)


    -- A button , autoDrop --
    local autoDropBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    if self.m_pGamePusherMgr:pubCheckAutoDrop() then
        autoDropBtn:setTitleText( "Auto Drop : Open" )
    else
        autoDropBtn:setTitleText( "Auto Drop : Close" )
    end

    autoDropBtn:setPosition(  display.width - 80 ,  self:getPosY() )
    autoDropBtn:addClickEventListener(function(sender)

        if self.m_pGamePusherMgr:pubCheckAutoDrop() then
            self.m_pGamePusherMgr:pubSetAutoDrop(false)
            autoDropBtn:setTitleText( "Auto Drop : Close" )
        else
            self.m_pGamePusherMgr:pubSetAutoDrop(true)
            autoDropBtn:setTitleText( "Auto Drop : Open" )
        end
    end)
    autoDropBtn:setScale(1.5)
    self._debugUIRoot:addChild(autoDropBtn)

    -- A button , auto Drop add speed --
    local autoSpeedUpBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    -- A button , pusher Speed down pusher --
    local autoSpeedDownBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)

    autoSpeedUpBtn:setTitleText( "Speed+ "..self._Main.m_nAutoDropTime )
    autoSpeedUpBtn:setPosition(  display.width - 80 , self:getPosY() )
    autoSpeedUpBtn:addClickEventListener(function(sender)
        self._Main.m_nAutoDropTime = self._Main.m_nAutoDropTime + 0.1
        autoSpeedUpBtn:setTitleText( "Speed+ "..self._Main.m_nAutoDropTime )
        autoSpeedDownBtn:setTitleText( "Speed- "..self._Main.m_nAutoDropTime )
    end)
    autoSpeedUpBtn:setScale(1.5)
    self._debugUIRoot:addChild(autoSpeedUpBtn)

    -- A button , auto Drop add speed --
    autoSpeedDownBtn:setTitleText( "Speed- "..self._Main.m_nAutoDropTime )
    autoSpeedDownBtn:setPosition(  display.width - 80 , self:getPosY())
    autoSpeedDownBtn:addClickEventListener(function(sender)
        self._Main.m_nAutoDropTime = self._Main.m_nAutoDropTime - 0.1
        if  self._Main.m_nAutoDropTime < 0.1 then
            self._Main.m_nAutoDropTime = 0.1
        end
        autoSpeedDownBtn:setTitleText( "Speed+ "..self._Main.m_nAutoDropTime )
        autoSpeedDownBtn:setTitleText( "Speed- "..self._Main.m_nAutoDropTime )
    end)
    autoSpeedDownBtn:setScale(1.5)
    self._debugUIRoot:addChild(autoSpeedDownBtn)


    -- A button , start stop pusher --
    local pusherStartBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    pusherStartBtn:setTitleText( "Pusher Running" )
    pusherStartBtn:setPosition(  display.width - 80 ,self:getPosY())
    pusherStartBtn:addClickEventListener(function(sender)
        self._Main.m_bPusherPushing  = not self._Main.m_bPusherPushing 
        self:ShowLog( "Stop Pusher action : "..tostring( self._Main.m_bPusherPushing  ) )
    end)
    pusherStartBtn:setScale(1.5)
    self._debugUIRoot:addChild(pusherStartBtn)

    -- A button , pusher Speed up pusher --
    local pusherSpeedUpBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    -- A button , pusher Speed down pusher --
    local pusherSpeedDownBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)

    pusherSpeedUpBtn:setTitleText( "Speed+ "..self._Main.m_nPusherSpeed )
    pusherSpeedUpBtn:setPosition(  display.width - 80 , self:getPosY())
    pusherSpeedUpBtn:addClickEventListener(function(sender)
        self._Main.m_nPusherSpeed = self._Main.m_nPusherSpeed + 1
        pusherSpeedUpBtn:setTitleText( "Speed+ "..self._Main.m_nPusherSpeed )
        pusherSpeedDownBtn:setTitleText( "Speed- "..self._Main.m_nPusherSpeed )
    end)
    pusherSpeedUpBtn:setScale(1.5)
    self._debugUIRoot:addChild(pusherSpeedUpBtn)

    
    pusherSpeedDownBtn:setTitleText( "Speed- "..self._Main.m_nPusherSpeed )
    pusherSpeedDownBtn:setPosition(  display.width - 80 ,self:getPosY() )
    pusherSpeedDownBtn:addClickEventListener(function(sender)
        self._Main.m_nPusherSpeed = self._Main.m_nPusherSpeed - 1
        pusherSpeedUpBtn:setTitleText( "Speed+ "..self._Main.m_nPusherSpeed )
        pusherSpeedDownBtn:setTitleText( "Speed- "..self._Main.m_nPusherSpeed )
    end)
    pusherSpeedDownBtn:setScale(1.5)
    self._debugUIRoot:addChild(pusherSpeedDownBtn)

    -- A button , moveup pusherup test --
    local pusherUpBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    pusherUpBtn:setTitleText( "Pusher Up" )
    pusherUpBtn:setPosition(  display.width - 80 , self:getPosY())
    pusherUpBtn:addClickEventListener(function(sender)
        -- self._Main:setLifterStatus( 2 )
        local data = self.m_pGamePusherMgr:pubGetGamePusherData()
        data:setBuffPusherLT(100)
    end)
    pusherUpBtn:setScale(1.5)
    self._debugUIRoot:addChild(pusherUpBtn)

    -- A button , movedown pusherdown test --
    local pusherDownBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    pusherDownBtn:setTitleText( "Pusher Down" )
    pusherDownBtn:setPosition(  display.width - 80 , self:getPosY())
    pusherDownBtn:addClickEventListener(function(sender)
        -- self._Main:setLifterStatus( 3 )
        local data = self.m_pGamePusherMgr:pubGetGamePusherData()
        data:setBuffPusherLT(0)
    end)
    pusherDownBtn:setScale(1.5)
    self._debugUIRoot:addChild(pusherDownBtn)

    -- A button , floor quake --
    local floorQuakeBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    floorQuakeBtn:setTitleText( "Floor Quake" )
    floorQuakeBtn:setPosition(  display.width - 80 ,self:getPosY() )
    floorQuakeBtn:addClickEventListener(function(sender)
        self._Main:itemsQuake( 20 )
    end)
    floorQuakeBtn:setScale(1.5)
    self._debugUIRoot:addChild(floorQuakeBtn)

    -- A button , camera quake --
    local cameraQuakeBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    cameraQuakeBtn:setTitleText( "Camera Quake" )
    cameraQuakeBtn:setPosition(  display.width - 80 ,self:getPosY())
    cameraQuakeBtn:addClickEventListener(function(sender)

        local hammerFunction = function (  )
            self._Main:itemsQuake( 50 )
            self._Main:CameraQuake()
        end
        self._Main:PlayEffect( Config.Effect.Hammer.ID , hammerFunction )
        
    end)
    cameraQuakeBtn:setScale(1.5)
    self._debugUIRoot:addChild(cameraQuakeBtn)

    -- A button , moveup lifter test --
    local moveUpBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    moveUpBtn:setTitleText( "MoveUp Liter" )
    moveUpBtn:setPosition(  display.width - 80 , self:getPosY())
    moveUpBtn:addClickEventListener(function(sender)
        -- self._Main:setLifterStatus( 2 )
        local data = self.m_pGamePusherMgr:pubGetGamePusherData()
        data:setBuffUpWallsLT(100)
    end)
    moveUpBtn:setScale(1.5)
    self._debugUIRoot:addChild(moveUpBtn)

    -- A button , movedown lifter test --
    local moveDownBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    moveDownBtn:setTitleText( "MoveDwon Liter" )
    moveDownBtn:setPosition(  display.width - 80 , self:getPosY())
    moveDownBtn:addClickEventListener(function(sender)
        -- self._Main:setLifterStatus( 3 )
        local data = self.m_pGamePusherMgr:pubGetGamePusherData()
        data:setBuffUpWallsLT(0)
    end)
    moveDownBtn:setScale(1.5)
    self._debugUIRoot:addChild(moveDownBtn)

    -- A button , tap here test --
    local taphereBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    taphereBtn:setTitleText( "TapHere" )
    taphereBtn:setPosition(  display.width - 80 , self:getPosY())
    taphereBtn:addClickEventListener(function(sender)
        self._Main:PlayEffect( Config.Effect.TapHere.ID )
    end)
    taphereBtn:setScale(1.5)
    self._debugUIRoot:addChild(taphereBtn)

    -- A button , front effect test --
    local frontEffBtn = ccui.Button:create(Config.debugBtnRes, Config.debugBtnRes)
    frontEffBtn:setTitleText( "FrontEffect" )
    frontEffBtn:setPosition(  display.width - 80 ,self:getPosY())
    frontEffBtn:addClickEventListener(function(sender)
        
        if self._frontEffectType ~= "Flash" then
            self._frontEffectType = "Flash"
        else
            self._frontEffectType = "Idle"
        end
       
        self._Main:PlayEffect( Config.Effect.FrontEffectPanel.ID , nil , self._frontEffectType )

    end)
    frontEffBtn:setScale(1.5)
    self._debugUIRoot:addChild(frontEffBtn)

    -- Key board --
    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(handler(self,self.onKeyboard), cc.Handler.EVENT_KEYBOARD_RELEASED)
    local eventDispatcher =self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener,self)

end

function GamePusherDebug:getPosY()
    if self.m_nPosY == nil then
        self.m_nCount = 1
        self.m_nPosY  =  display.height - 440
    end
    self.m_nPosY  =  self.m_nPosY - 40
    self.m_nCount = self.m_nCount + 1
    return self.m_nPosY 
end


-- 创建实体 --
function GamePusherDebug:createEntity( sType  , nIndex , vPos , vRot )
    
    if vPos == nil then
        vPos = cc.vec3(math.random(-5,5), 5.0, -10.0)
    end

    if vRot == nil then
        vRot = cc.vec3(0.0, 0.0,  0.0)
    end

    if sType == Config.EntityType.COIN then
        self._Main:createCoins( nil , vPos , vRot )
    end
end



-- Test set symbol pos --
function GamePusherDebug:testSetSymbolPos( offPos )
    
    if self.testSymbol == nil then
        return
    end

    local symPos = self.testSymbol:getPosition3D()
    symPos.x     = symPos.x + offPos.x
    symPos.y     = symPos.y + offPos.y
    symPos.z     = symPos.z + offPos.z
    self.testSymbol:setPosition3D( symPos )

    print( "x:"..symPos.x.." y:"..symPos.y.." z:"..symPos.z )
end

-- Test show item nums in scene --
function GamePusherDebug:TestItemsNumShow( dt )

    if self._testItemsNumShowTime == nil then
        self._testItemsNumShowTime = 0
    end

    
    if self._testItemsNumShowTime < 1 then
        self._testItemsNumShowTime = self._testItemsNumShowTime + dt
        return
    else
        self._testItemsNumShowTime = 0
    end

    -- 总发射数量 -- 
    if self._coinWholeNums == nil then
        
        self._coinWholeNums = cc.Label:createWithSystemFont( self._Main.m_nEntityIndex.." 掉落总量 ", "", 24)
        self._coinWholeNums:setAnchorPoint( cc.p( 1 , 0.5 ) )
        self._coinWholeNums:setPosition( cc.p( display.width , 200 ) )
        self._debugUIRoot:addChild( self._coinWholeNums )
    end
    -- 当前存活数量 --
    if self._coinLiveNums == nil then
        self._coinLiveNums = cc.Label:createWithSystemFont( table.nums(self._Main.m_tEntityList).." 存活数量 "  , "", 24)
        self._coinLiveNums:setAnchorPoint( cc.p( 1 , 0.5 ) )
        self._coinLiveNums:setPosition( cc.p( display.width , 160 ) )
        self._debugUIRoot:addChild( self._coinLiveNums )
    end
    -- 中奖数量 --
    if self._coinWinNums == nil then
        self._coinWinNums = cc.Label:createWithSystemFont( self._Main.m_nEntityWin.." 中奖数量 "  , "", 24)
        self._coinWinNums:setAnchorPoint( cc.p( 1 , 0.5 ) )
        self._coinWinNums:setPosition( cc.p( display.width , 120 ) )
        self._debugUIRoot:addChild( self._coinWinNums )
    end
    -- 丢失数量 --
    if self._coinLoseNums == nil then
        self._coinLoseNums = cc.Label:createWithSystemFont( self._Main.m_nEntityLose.." 丢失数量 "  , "", 24)
        self._coinLoseNums:setAnchorPoint( cc.p( 1 , 0.5 ) )
        self._coinLoseNums:setPosition( cc.p( display.width , 80 ) )
        self._debugUIRoot:addChild( self._coinLoseNums )
    end

    -- 掉落细节统计 --
    if self._dropDetail == nil then

        local touch = ccui.Layout:create()
        touch:setTouchEnabled(true)
        touch:setSwallowTouches(false)
        touch:setAnchorPoint(0, 0)
        touch:setContentSize( cc.size( display.width / 3 , display.cy ) )
        touch:setClippingEnabled(false)
        touch:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
        touch:setBackGroundColor( cc.c4b(0, 0, 255 ) );
        touch:setBackGroundColorOpacity( 64 )
        self._debugUIRoot:addChild( touch )


        self._dropDetail = cc.Label:createWithSystemFont( "DropDetail"  , "", 24)
        self._dropDetail:setAnchorPoint( cc.p( 0 , 1 ) )
        self._dropDetail:setPosition( cc.p( 0 , display.cy ) )
        self._debugUIRoot:addChild( self._dropDetail )
    end
    
    self._coinWholeNums:setString( self._Main.m_nEntityIndex.." 掉落总量 " )
    self._coinLiveNums:setString ( table.nums(self._Main.m_tEntityList).." 存活数量 " )
    self._coinWinNums:setString  ( self._Main.m_nEntityWin.." 中奖数量 " )
    self._coinLoseNums:setString ( self._Main.m_nEntityLose.." 丢失数量 " )


    local dropDetailText = "DropDetail:\n"
    for k,v in pairs( self._Main.m_tEntityDropped.CoinWin) do
        dropDetailText = dropDetailText.."CoinWin   ID:"..k.." Num:"..v.."\n"
    end
    for k,v in pairs( self._Main.m_tEntityDropped.CoinLose) do
        dropDetailText = dropDetailText.."CoinLose  ID:"..k.." Num:"..v.."\n"
    end
    self._dropDetail:setString( dropDetailText )
end

-- key press --
function GamePusherDebug:onKeyboard(code, event)

    if code == cc.KeyCode.KEY_A then
        self:testSetSymbolPos( cc.vec3( -0.1 , 0 , 0 ) )
    elseif code == cc.KeyCode.KEY_S then
        self:testSetSymbolPos( cc.vec3( 0.1 , 0 , 0 ) )
    elseif code == cc.KeyCode.KEY_D then
        self:testSetSymbolPos( cc.vec3( 0 , -0.1 , 0 ) )
    elseif code == cc.KeyCode.KEY_F then
        self:testSetSymbolPos( cc.vec3( 0 , 0.1 , 0 ) )
    elseif code == cc.KeyCode.KEY_G then
        self:testSetSymbolPos( cc.vec3( 0 , 0 , -0.1 ) )
    elseif code == cc.KeyCode.KEY_H then
        self:testSetSymbolPos( cc.vec3( 0 , 0 , 0.1 ) )
    end

end


-- 清除场景中实体 --
function GamePusherDebug:TestClearSceneEntity(  )
    self._Main.m_sp3DEntityRoot:removeAllChildren()
    self._Main.m_tEntityList = {}   -- 场景中动态实体列表 --
    self._Main.m_nEntityIndex= Config.EntityIndex    -- 动态实体全局索引  --
    self._Main.m_nEntityWin  = 0    -- 中奖的实体个数    --
    self._Main.m_nEntityLose = 0    -- 丢失的实体个数    --
    self.m_tEntityDropped = {       -- 掉落的细节统计    --
            CoinWin  = {} , 
            CoinLose = {} }  
end

-- 定时器 在场景中放普通金币 --
function GamePusherDebug:TestEmitCoins( dt )

    -- test auto emit coin s--
    if self._debugUIRootShow == false then
        return
    end

    if self.testEmitCoinTime == nil then
        self.testEmitCoinTime = 0
        self.testEmitCoinType = 1
    end
    -- 如果Interval==0 则停止发射 --
    if self.testEmitInterval == 0 then
        return
    end
    -- 时间步进 --
    self.testEmitCoinTime = self.testEmitCoinTime + dt
    -- 发射 --
    if self.testEmitCoinTime > self.testEmitInterval then

        -- 根据发射类型 指定发射位置和数量 --
        if self.testEmitCoinType == 1 then
            self:createEntity( Config.EntityType.COIN , 1 , cc.vec3(math.random(-5,5), 5.0, -10.0) )
        elseif self.testEmitCoinType == 2 then
            self:createEntity( Config.EntityType.COIN , 1 , cc.vec3( -5 , 5.0, -10.0) )
        elseif self.testEmitCoinType == 3 then
            self:createEntity( Config.EntityType.COIN , 1 , cc.vec3(  0 , 5.0, -10.0) )
        elseif self.testEmitCoinType == 4 then
            self:createEntity( Config.EntityType.COIN , 1 , cc.vec3(  5 , 5.0, -10.0) )
        elseif self.testEmitCoinType == 5 then
            self:createEntity( Config.EntityType.COIN , 1 , cc.vec3(  -5 , 5.0, -10.0) )
            self:createEntity( Config.EntityType.COIN , 1 , cc.vec3(  -1.7 , 5.0, -10.0) )
            self:createEntity( Config.EntityType.COIN , 1 , cc.vec3(  1.7 , 5.0, -10.0) )
            self:createEntity( Config.EntityType.COIN , 1 , cc.vec3(  5 , 5.0, -10.0) )

        end
        self.testEmitCoinTime = 0
    end
end

-- System Speed up --
function GamePusherDebug:SpeedUp(  )
    local scheduler = cc.Director:getInstance():getScheduler()
    self.m_timeSaleIndex = self.m_timeSaleIndex or 1
    self.m_timeSaleIndex = self.m_timeSaleIndex + 1
    if self.m_timeSaleIndex > 10 then
        self.m_timeSaleIndex = 1
    end
    scheduler:setTimeScale( self.m_timeSaleIndex )
end


return GamePusherDebug


