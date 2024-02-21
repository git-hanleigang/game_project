--[[
    ClawStallGameMain
    tm

    -- 刚体属性说明 --
    local friction      = rigidBody:getFriction()       -- 获取摩擦力 --
    local htFraction    = rigidBody:getHitFraction()    -- 碰撞摩擦力 --
    local roFraction    = rigidBody:getRollingFriction()-- 滚动摩擦力 --
    local restitution   = rigidBody:getRestitution()    -- 碰撞反弹力 --
]]
local PublicConfig = require "ClawStallPublicConfig"
local ClawStallGameManager = util_require("CodeClawStallPhysicsMachine.ClawStallGameManager"):getInstance()
local ClawStallGameMain = class( "ClawStallGameMain" , function ()
    local layer = cc.Layer:create()
    return layer
end)

--抓取模式
local CLAW_MODE = {
    NORMAL = 1,     --普通模式
    SPECIAL = 2     --特殊模式
}

local CLAW_START_POS = cc.vec3( -23 , 30  , 7 )

local rayPosAry = {
    cc.vec3( 0.0, 0, -5),
    cc.vec3( -5, 0, 4),
    cc.vec3( 5, 0, 4),
    cc.vec3( 0.0, 0, -4),
    cc.vec3( -4, 0, 4),
    cc.vec3( 4, 0, 4),
    cc.vec3( 0.0, 0, -3),
    cc.vec3( -3, 0, 4),
    cc.vec3( 3, 0, 4),
    cc.vec3( 0.0, 0, -2),
    cc.vec3( -2, 0, 4),
    cc.vec3( 2, 0, 4),
    cc.vec3( 0.0, 0, -1),
    cc.vec3( -1, 0, 4),
    cc.vec3( 1, 0, 4)
}


ClawStallGameMain.moveRotationAngel  = 45        -- 移动时旋转角度 --
ClawStallGameMain.moveRotationFactor = 0.01      -- 移动时旋转系数 --

local ITEM_MASK = 1000      --道具掩码

function ClawStallGameMain:ctor(  )
    self.m_endFunc = nil
    self.m_highPosY = 0
    self.m_outOfControlTime = 0 --超时时间
    self.m_isOutOfControl = false --是否操作超时
    self.m_isAutoRandom = false
    -- 注册事件 --
    local function onNodeEvent(event)
         if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end
    self:registerScriptHandler(onNodeEvent)

end

function ClawStallGameMain:initData_()
    local scene = display.getRunningScene()
    if scene == nil then
        assert( false , "Get Physics scene failed ")
    end
    self.m_Scene = scene

    self.m_isStartCountDown = false

    self.m_nMachineMask = 1
    self.m_nBasketMask  = 2
    self.m_ClawMask     = {101,102,103}
    self.m_nItemMask    = 1000
    self.m_ItemList     = {}
end

--[[
    设置结束回调
]]
function ClawStallGameMain:setEndFunc(func)
    self.m_endFunc = func
end

--
function ClawStallGameMain:onEnter(  )
    
    -- Register Even注册事件
    self:onRegistEvent()

    -- 初始化摄像机 --
    self:InitCamera()

    -- 创建静态模型及碰撞体 --
    self:createStaticModel()

    -- 初始化UI --
    self:InitUI()
end

-- Register Event --
function ClawStallGameMain:onRegistEvent(  )
    gLobalNoticManager:addObserver(self,function(target, params)
        if self.m_isClawing or self.m_isWaiting then
            return
        end
        if not self.m_bStartMove then
            self.m_Claw:startMoveAction()
        end
        self.m_bStartMove = true
        --当前没处在倒计时状态中
        if not self.m_isStartCountDown then
            self.m_isStartCountDown = true
            --开始倒计时
            self.m_clawInfoView:startCountDown()

            self.m_outOfControlTime = 0
            self.m_isOutOfControl = false

            if not self.m_clawInfoView.m_isCanClick then
                self.m_clawInfoView:setGrabBtnEnabled(true,true)
            end
            

        end
        self.m_vMoveSpeed = params
    end,"ClawGameMain_JoyStcikMoved")

    gLobalNoticManager:addObserver(self,function(target)
        if self.m_isClawing or self.m_isWaiting then
            return
        end
        self.m_bStartMove = false
        self.m_Claw:stopMoveAction( )
    end,"ClawGameMain_JoyStcikEnded")

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:featureResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

--
function ClawStallGameMain:onExit(  )
    self:stopSchedule()
    gLobalNoticManager:removeAllObservers(self)
end

function ClawStallGameMain:stopSchedule()
    self:unscheduleUpdate()
end

-- 3D世界坐标转屏幕2d坐标(屏幕坐标系:原点在屏幕左上角，x轴向右，y轴向下)
function ClawStallGameMain:Convert3DToScreen2D(vec3Pos)
    local uiPos = self._camera:project(vec3Pos)
    return uiPos
end
-- 3D世界坐标转OpenGL2d坐标(OpenGL坐标系:该坐标系原点在屏幕左下角，x轴向右，y轴向上)
function ClawStallGameMain:Convert3DToGL2D(vec3Pos)
    local uiPos = self._camera:projectGL(vec3Pos)
    return uiPos
end

-- Init Camera --
function ClawStallGameMain:InitCamera(  )
    
    -- set physics world --
    self._physicsScene = self.m_Scene
    self._physicsWorld = self._physicsScene:getPhysics3DWorld()
    self._physicsWorld:setDebugDrawEnable(false)
    self._physicsWorld:setGravity( cc.vec3(0,-100,0) )

    -- init camera --
    self._angle         = 0.0
    self._distanceY     = 31.0
    self._distanceZ     = 40.0
    self._lookAtOri     = cc.vec3(0.0, 10, 0 )    -- 观察原点 --
    self._cameraPosOri  = cc.vec3(0.0, self._distanceY , self._distanceZ )   -- 摄像机原位置 --

    local size      = cc.Director:getInstance():getWinSize()
    self._camera    = cc.Camera:createPerspective(60.0, size.width / size.height, 1.0, 1000.0)
    self._camera:setPosition3D( self._cameraPosOri )
    self._camera:lookAt( self._lookAtOri , cc.vec3(0.0, 1.0, 0.0))
    self._camera:setCameraFlag(cc.CameraFlag.USER1)
    self:addChild(self._camera)
    self._physicsScene:setPhysics3DDebugCamera(self._camera)

    -- self._camera:setDepth(5)
    -- local camera2D = self.m_Scene:getDefaultCamera()
    -- camera2D:setDepth(10)

    -- 初始化一个在UI上的3d摄像机 --
    self.cam3dOnUI = cc.Camera:create()
    self.cam3dOnUI:setCameraFlag( cc.CameraFlag.USER2 )
    self.cam3dOnUI:setDepth( cc.CameraFlag.USER2 )
    self:addChild(self.cam3dOnUI)
end


-- 创建静态模型 --
function ClawStallGameMain:createStaticModel(  )

    -- 创建机台 --
    self:createMachine()
    -- 爪子 --
    self:createClaw()
    -- Sky --
    self:createSky()
end

--[[
    创建机台
]]
function ClawStallGameMain:createMachine()
    local MACHINE_OFFSET = ClawStallGameManager:getMachineOffset() --机台偏移位置
    local pMachine  = cc.Sprite3D:create( "physicsRes/Wwj_Changjing.c3b" )
    pMachine:setTexture("physicsRes/wawaji_changjing_d.png");
    pMachine:setCameraMask( cc.CameraFlag.USER1)
    pMachine:setPosition3D( cc.vec3(0.0, 0.0, -10 + MACHINE_OFFSET) )
    pMachine:setRotation3D( cc.vec3(-90.0, 0.0, 0.0) )
    pMachine:setScale( 20 )
    self:addChild( pMachine )

    -- 创建刚体 --
    local shapeList = {}
    local bodyshape = nil
    local localTrans= nil

    local width     = 50.0
    local height    = 10.0
    local thickness = 6.0

    -- 前侧栏 --
    bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 70, height * 5,  thickness))
    localTrans = cc.mat4.createTranslation( 0, height/2 , -33  + MACHINE_OFFSET)
    table.insert(shapeList, {bodyshape, localTrans})
    -- 后边栏 --
    bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 70, height * 5, thickness))
    localTrans = cc.mat4.createTranslation( 0, height/2 , 16  + MACHINE_OFFSET)
    table.insert(shapeList, {bodyshape, localTrans})

    bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 70, height, 10))
    localTrans = cc.mat4.createTranslation( 18, height/2 ,7 + MACHINE_OFFSET)
    table.insert(shapeList, {bodyshape, localTrans})

    -- 左侧栏 --
    bodyshape  = cc.Physics3DShape:createBox( cc.vec3( thickness, height * 5, 60 ))
    localTrans = cc.mat4.createTranslation( -29, height/2 , 0  + MACHINE_OFFSET)
    table.insert(shapeList, {bodyshape, localTrans})

    -- 右侧栏 --
    bodyshape  = cc.Physics3DShape:createBox( cc.vec3( thickness, height * 5, 60 ))
    localTrans = cc.mat4.createTranslation( 29, height/2 , 0  + MACHINE_OFFSET)
    table.insert(shapeList, {bodyshape, localTrans})

    -- 洞口前挡板 --
    bodyshape  = cc.Physics3DShape:createBox( cc.vec3( 20, height, 2 ))
    localTrans = cc.mat4.createTranslation( -25 , height/2 , -0.5  + MACHINE_OFFSET)
    table.insert(shapeList, {bodyshape, localTrans})

    -- 洞口右挡板 --
    bodyshape  = cc.Physics3DShape:createBox( cc.vec3( 2, height, 20 ))
    localTrans = cc.mat4.createTranslation( -16 , height/2 , 10  + MACHINE_OFFSET)
    table.insert(shapeList, {bodyshape, localTrans})

    -- 底板 --
    bodyshape  = cc.Physics3DShape:createBox( cc.vec3( 80, 8, 80 ))
    localTrans = cc.mat4.createTranslation( 0 , -4.0 , -10  + MACHINE_OFFSET)
    table.insert(shapeList, {bodyshape, localTrans})

    -- 创建一个空模型承载这些碰撞体 --
    local rbDes = {}
    rbDes.mass  = 0.0
    rbDes.shape      = cc.Physics3DShape:createCompoundShape(shapeList)
    local rigidBody  = cc.Physics3DRigidBody:create(rbDes)
    local component  = cc.Physics3DComponent:create(rigidBody)
    local sprite     = cc.Sprite3D:create(  )
    sprite:setCameraMask(cc.CameraFlag.USER1)
    sprite:addComponent(component)
    rigidBody:setFriction( 0.8 )
    rigidBody:setMask(self.m_nMachineMask)
    self:addChild(sprite)
    component:syncNodeToPhysics()


    -- 创建小漏斗碰撞监控 --
    local rbDes     = {}
    rbDes.mass      = 0.0
    rbDes.shape     = cc.Physics3DShape:createBox(cc.vec3( 5.0, 3.0, 7.0 ))
    local rigidBody = cc.Physics3DRigidBody:create(rbDes)
    local component = cc.Physics3DComponent:create(rigidBody)

    local sprite    = cc.Sprite3D:create( )
    sprite:setCameraMask(cc.CameraFlag.USER1)
    sprite:addComponent(component)
    self:addChild(sprite)
    sprite:setPosition3D( cc.vec3(  -23 , 3 , 7  + MACHINE_OFFSET) )
    component:syncNodeToPhysics( )
    rigidBody:setMask( self.m_nBasketMask )

    -- 设置碰撞监听 --
    rigidBody:setCollisionCallback(function (collisionInfo)
        if nil ~= collisionInfo.collisionPointList and #collisionInfo.collisionPointList > 0 then
            local colAMask = collisionInfo.objA:getMask()
            local colBMask = collisionInfo.objB:getMask()

            -- 都需要矫正Mask,因为不一定A/B是小球 --
            if colAMask >= ITEM_MASK or colBMask >= ITEM_MASK then
                util_printLog("抓娃娃 检测到了碰撞")
                -- collisionInfo.objB.m_itemID
                local modelMask = colAMask
                local itemID = collisionInfo.objA.m_itemID
                if colBMask >= ITEM_MASK then
                    modelMask = colBMask
                    itemID = collisionInfo.objB.m_itemID
                end

                if not self.m_ItemList[modelMask] then
                    return
                end

                self:removeItemFromList(modelMask)
                self:sendData({itemID})
                self.m_clawInfoView:showRewardLight(itemID)

                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_item_drop)
                --抓到高价值物品
                if itemID < 6 then
                    local randIndex = math.random(1,2)
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_ClawStall_rand_sound"..randIndex])
                end
    
            end
        end
    end)
end

function ClawStallGameMain:removeItemFromList(maskID)
    local curModel = self.m_ItemList[maskID]
    if curModel ~= nil then
        
        curModel:setVisible(false)
        util_printLog("解除娃娃3D属性")
        local rigidBody = curModel.m_rigidBody
        rigidBody:setKinematic(true)
        self._physicsWorld:removePhysics3DObject(rigidBody)   
        util_nextFrameFunc(function(  )
            util_printLog("移除娃娃")
            curModel:removeFromParent()
            util_printLog("移除娃娃 end")
        end)
        
        self.m_ItemList[maskID] = nil
    end
end



function ClawStallGameMain:createSky()

    local skyFront  = cc.Sprite3D:create( "physicsRes/plane.c3b" )
    local texTure   = cc.Director:getInstance():getTextureCache():addImage( "ClawStallCommon/ClawStall_BJ_1.png" ) 
    
    -- texTure:setTexParameters(gl.LINEAR, gl.LINEAR, gl.REPEAT, gl.REPEAT);
    skyFront:setTexture(texTure);

    skyFront:setCameraMask( cc.CameraFlag.USER1)
    skyFront:setPosition3D( cc.vec3(0.0, -18.0, -50.0))
    skyFront:setRotation3D( cc.vec3( -30.0, 0.0, 0.0))
    skyFront:setScaleX( 50 )
    skyFront:setScaleY( 25 )
    self:addChild( skyFront )

end

-- 创建爪子 --
function ClawStallGameMain:createClaw()

    local MACHINE_OFFSET = ClawStallGameManager:getMachineOffset() --机台偏移位置

    self.m_Claw = cc.Sprite3D:create()
    self.m_Claw:setCameraMask( cc.CameraFlag.USER1)

    self:addChild(  self.m_Claw )

    -- 装饰线 --
    local drawNode3D = require("CodeClawStallPhysicsMachine.ClawStallDrawNode3D"):create()
    self.m_Claw:addChild( drawNode3D )
    drawNode3D:setCameraMask(cc.CameraFlag.USER1)
    drawNode3D:setPosition( cc.vec3( 0.0, 0.0, 0) )
    local ori = cc.vec3( 0.0, 0.0, 0)
    local dest= cc.vec3( 0.0, -30.0, 0)
    drawNode3D:drawLine( ori , dest , 0.5 ,cc.vec4( 1 , 1.0, 0.0, 1 ) )
    self.m_Claw.rayLine = drawNode3D
    self.m_Claw.rayLine:setVisible( false )

    

    -- 杆子 --
    local armGan   = cc.Sprite3D:create( "physicsRes/wawaji_gan.c3b")
    armGan:setTexture( "physicsRes/wawaji_zhuazi_d.png" )
    armGan:setScale(20)
    armGan:setPosition3D(cc.vec3(0.0, 0.0, 0.0))
    armGan:setRotation3D(cc.vec3(-90.0, 0.0, 0.0))
    armGan:setCameraMask(cc.CameraFlag.USER1)
    self.m_Claw:addChild( armGan )

    -- Claw Main --
    local armMainRoot = cc.Sprite3D:create()
    armMainRoot:setCameraMask( cc.CameraFlag.USER1)
    armMainRoot:setPosition3D( cc.vec3( 0.0, 0.0, 0.0) )
    self.m_Claw:addChild( armMainRoot )
    self.m_Claw.armRoot = armMainRoot

    --光柱
    local light   = cc.Sprite3D:create( "physicsRes/wawaji_guangzhu.c3b")
    light:setTexture( "physicsRes/wawaji_guangzhu_d.png" )
    light:setScale(3000)
    light:setPosition3D(cc.vec3(0.0, 5, 0))
    light:setRotation3D(cc.vec3(-90, 0.0, 0.0))
    light:setCameraMask(cc.CameraFlag.USER1)
    armMainRoot:addChild( light )
    self.m_Claw.m_light = light
    light:setVisible(false)


    local armMain   = cc.Sprite3D:create( "physicsRes/wawaji_tou.c3b")
    armMain:setTexture( "physicsRes/wawaji_zhuazi_d.png" )
    armMain:setScale(20)
    armMain:setPosition3D(cc.vec3(0.0, 0.0, 0.0))
    armMain:setRotation3D(cc.vec3(-90.0, 0.0, 0.0))
    armMain:setCameraMask(cc.CameraFlag.USER1)
    armMainRoot:addChild( armMain )

    -- 玻璃罩 --
    local bolizhao   = cc.Sprite3D:create( "physicsRes/wawaji_bolizhao.c3b")
    local mat = cc.Material:createWithFilename( "CodeClawStallPhysicsMachine/Materials/glass.material" )
    bolizhao:setMaterial( mat )
    mat:setTechnique("normal")

    bolizhao:setTexture( "physicsRes/wawaji_zhuazi_d.png" )
    bolizhao:setScale( 20 )
    bolizhao:setPosition3D(cc.vec3(0.0, 0.0, 0.0))
    bolizhao:setRotation3D(cc.vec3(-90.0, 0.0, 0.0))
    bolizhao:setCameraMask(cc.CameraFlag.USER1)
    armMainRoot:addChild( bolizhao )

    -- 创建眼睛表情 --
    self.m_emoji = util_createAnimation("ClawStall_wwbq.csb")
    armMain:addChild( self.m_emoji)
    self.m_emoji:setCameraMask(cc.CameraFlag.USER1)
    self.m_emoji:setScale( 0.0025 )
    self.m_emoji:setPosition3D( cc.vec3( 0, -0.24, -0.23 ) )
    self.m_emoji:setRotation3D( cc.vec3( 90,0, 0 ) )
    self:changeEmoji("auto")

    local posfactor = 1.5
    local posZ = 2 * posfactor
    local posX = 1.732 * posfactor
    local posY = -8.5

    local claw1 = self:createSingleClaw( 1 )
    armMainRoot:addChild( claw1 )
    claw1:setPosition3D( cc.vec3( 0, posY, -posZ ) )
    claw1:setRotation3D( cc.vec3( 0.0, 0.0, 0.0) )
    claw1:resetRotation( )
    self.m_Claw.claw1 = claw1

    local claw2 = self:createSingleClaw( 2 )
    armMainRoot:addChild( claw2 )
    claw2:setPosition3D( cc.vec3( -posX , posY, posZ/2 ) )
    claw2:setRotation3D( cc.vec3( 0.0, 120.0, 0.0) )
    claw2:resetRotation( )
    self.m_Claw.claw2 = claw2

    local claw3 = self:createSingleClaw( 3 )
    armMainRoot:addChild( claw3 )
    claw3:setPosition3D( cc.vec3( posX , posY, posZ/2 ) )
    claw3:setRotation3D( cc.vec3( 0.0, 240.0, 0.0) )
    claw3:resetRotation( )
    self.m_Claw.claw3 = claw3

    

    -- 装饰线 --
    -- local rayLine1 = require("CodeClawStallPhysicsMachine.ClawStallDrawNode3D"):create()
    -- self.m_Claw:addChild( rayLine1 )
    -- rayLine1:setCameraMask(cc.CameraFlag.USER1)
    -- rayLine1:setPosition( cc.vec3( 0.0, 0, 0) )
    -- local ori = rayPosAry[1]
    -- local dest= cc.vec3(rayPosAry[1].x, -30.0, rayPosAry[1].z)
    -- rayLine1:drawLine( ori , dest , 0.5 ,cc.vec4( 1 , 1.0, 0.0, 1 ) )

    -- -- 装饰线 --
    -- local rayLine2 = require("CodeClawStallPhysicsMachine.ClawStallDrawNode3D"):create()
    -- self.m_Claw:addChild( rayLine2 )
    -- rayLine2:setCameraMask(cc.CameraFlag.USER1)
    -- rayLine2:setPosition( cc.vec3( 0.0, 0, 0) )
    -- local ori = rayPosAry[2]
    -- local dest= cc.vec3( rayPosAry[2].x, -30.0, rayPosAry[2].z)
    -- rayLine2:drawLine( ori , dest , 0.5 ,cc.vec4( 1 , 1.0, 0.0, 1 ) )

    -- -- 装饰线 --
    -- local rayLine3 = require("CodeClawStallPhysicsMachine.ClawStallDrawNode3D"):create()
    -- self.m_Claw:addChild( rayLine3 )
    -- rayLine3:setCameraMask(cc.CameraFlag.USER1)
    -- rayLine3:setPosition( cc.vec3( 0.0, 0, 0) )
    -- local ori = rayPosAry[3]
    -- local dest= cc.vec3( rayPosAry[3].x, -30.0, rayPosAry[3].z)
    -- rayLine3:drawLine( ori , dest , 0.5 ,cc.vec4( 1 , 1.0, 0.0, 1 ) )

    --
    self.m_Claw.setAngle = function ( sender ,  vRot  )
        sender.armRoot:setRotation3D( vRot )
    end
    --
    self.m_Claw.resetAction = function ( sender )
        sender.armRoot:stopAllActions()
        local rotateTo  = cc.RotateTo:create( 0.2 , cc.vec3( 0 , 0 , 0 )  )
        sender.armRoot:runAction( rotateTo )
    end
    --
    self.m_Claw.setIdleAction = function ( sender  )
        local xRandom   = math.random( 0 , 5 )
        local zRandom   = math.random( 0 , 5 )
        local rotateTo  = cc.RotateTo:create( 2 , cc.vec3( xRandom , 0 , zRandom )  )
        local rotateTo2 = cc.RotateTo:create( 2 , cc.vec3( -xRandom , 0 , -zRandom ))
        local seq       = cc.Sequence:create( rotateTo , rotateTo2 )
        local action    = cc.RepeatForever:create( seq )
        sender.armRoot:runAction( action )
    end
    --
    self.m_Claw.startMoveAction = function ( sender )
        sender.armRoot:stopAllActions()
    end
    --
    self.m_Claw.stopMoveAction = function ( sender  )
        local actionList={}
        actionList[#actionList+1]   =   cc.RotateTo:create( 0.5 , cc.vec3( 0 , 0 , 0 )  )
        actionList[#actionList+1]   =   cc.DelayTime:create( 0.1 )
        actionList[#actionList+1]   =   cc.CallFunc:create(function(  )
            -- self.m_Claw:setIdleAction()
        end)
        local seq = cc.Sequence:create( actionList )
        sender.armRoot:runAction( seq )
    end
    --
    -- self.m_Claw:setIdleAction( )
end

-- 显示辅助线 --
function ClawStallGameMain:showHelpLine( bShow )
    self.m_Claw.rayLine:setVisible( bShow )
end

--[[
    切换表情
]]
function ClawStallGameMain:changeEmoji(emojiType)
    local allEmoji = {"Sprite_1","start","lose","laugh"}
    self.m_emoji:stopAllActions()
    if emojiType ~= "auto" then
        for k,emojiName in pairs(allEmoji) do
            self.m_emoji:findChild(emojiName):setVisible(emojiType == emojiName)
        end
    else
        util_schedule(self.m_emoji, function(  )
            local randEmoji = {"Sprite_1","laugh"}
            --随机显示一个表情
            local randomIndex = math.random(1,#randEmoji)
            local randomName = randEmoji[randomIndex]
            for k,emojiName in pairs(allEmoji) do
                self.m_emoji:findChild(emojiName):setVisible(randomName == emojiName)
            end
        end,3)

    end
end

-- 抓取动作 --
function ClawStallGameMain:clawAction( nType )

    if self.m_isClawing == true then
        print("HolyShit. Clawing......")
        return
    end

    self.m_clawInfoView:hideCounter()

    self.m_waittingNode:stopAllActions()

    self.m_isClawing = true

    self:changeEmoji("start")

    self.m_isStartCountDown = false

    self.m_vMoveSpeed = cc.p(0,0)

    -- 恢复角度 --
    self.m_Claw:resetAction()

    -- 抓取 --
    local beginClaw = function ()
        self.m_Claw.claw1:actionGrap( 1 )
        self.m_Claw.claw2:actionGrap( 1 )
        self.m_Claw.claw3:actionGrap( 1 )
    end

    -- 放下 --
    local endClaw  = function ()
        self.m_Claw.claw1:actionRelease( 0.5 )
        self.m_Claw.claw2:actionRelease( 0.5 )
        self.m_Claw.claw3:actionRelease( 0.5 )
    end

    local actionList={}
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_move_down)
    end)

    -- 移动到底部 --
    local curPos = self.m_Claw:getPosition3D()
    local moveDownSpeed = ClawStallGameManager:getMoveDownSpeed()
    local downPos = self:getClawDownPos(curPos)
    local moveDownTime = (curPos.y - downPos) / moveDownSpeed
    actionList[#actionList+1]=cc.MoveTo:create( moveDownTime , cc.vec3( curPos.x , downPos  , curPos.z ))

    -- 抓取 --
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
        if ClawStallGameManager:getAutoStatus() then
            self.m_clawInfoView:resetAutoBtnStatus()
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_close_claw)
        beginClaw()
    end)

    -- 等待1.5秒 --
    actionList[#actionList+1]=cc.DelayTime:create( 1.5 )

    actionList[#actionList+1]=cc.CallFunc:create(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_move_up)
    end)

    -- 移动到顶部 --
    local moveUpSpeed = ClawStallGameManager:getMoveUpSpeed()
    local moveUpTime = (curPos.y - downPos) / moveUpSpeed
    actionList[#actionList+1]=cc.MoveTo:create( moveUpTime , cc.vec3( curPos.x , 30  , curPos.z ))

    -- 检测是否抓到道具 --
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
        local bGrapItem = self:checkGrapItem()
        if bGrapItem == true then
            self:changeEmoji("laugh")
            self.m_clawMoveSoundID = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_move_claw)
        else
            self:changeEmoji("lose")

            -- 停止后续动作 直至恢复 --
            self.m_Claw:stopAllActions()
            actionList={}
            -- 松开 --
            actionList[#actionList+1]=cc.CallFunc:create(function(  )
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_open_claw)
                endClaw()

                self:sendData({0})
                self:changeEmoji("auto")
            end)
            -- 等待1秒 --
            actionList[#actionList+1]=cc.DelayTime:create( 1 )

            -- 恢复 --
            actionList[#actionList+1]=cc.CallFunc:create(function(  )
                self.m_isClawing = false
                
            end)
            local seq = cc.Sequence:create( actionList )
            self.m_Claw:runAction( seq )
        end
    end)

    -- 等待两秒 --
    actionList[#actionList+1]=cc.DelayTime:create( 0.1 )


    local MACHINE_OFFSET = ClawStallGameManager:getMachineOffset() --机台偏移位置
    local targetPos = cc.vec3(CLAW_START_POS.x,CLAW_START_POS.y,CLAW_START_POS.z + MACHINE_OFFSET)
    -- 移动到漏斗 --
    local distance = ClawStallGameManager:getDistance(curPos, targetPos)
    local moveBackSpeed = ClawStallGameManager:getMoveBackSpeed()
    local moveBackTime = distance / moveBackSpeed
    actionList[#actionList+1]=cc.MoveTo:create( moveBackTime , targetPos)

    -- 松开 --
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
        if self.m_clawMoveSoundID then
            gLobalSoundManager:stopAudio(self.m_clawMoveSoundID)
            self.m_clawMoveSoundID = nil
        end
        local bGrapItem = self:checkGrapItem()
        if bGrapItem == true then
            util_printLog( "抓到娃娃了")

            --等待1.5秒如果没有消息返回说明娃娃掉在洞口外了
            performWithDelay(self.m_waittingNode,function(  )
                if not ClawStallGameManager.m_isPreClaw then
                    return
                end
                util_printLog("娃娃掉在洞口外了",true)
                self:sendData({0})
            end,1.5)

        else
            util_printLog("什么都没抓到")
            self:sendData({0})
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_open_claw)
        endClaw()

        self:changeEmoji("auto")
    end)
    -- 等待两秒 --
    actionList[#actionList+1]=cc.DelayTime:create( 1 )

    -- 恢复 --
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
        self.m_isClawing = false
    end)
    local seq = cc.Sequence:create( actionList )
    self.m_Claw:stopAllActions()
    self.m_Claw:runAction( seq )

end

--[[
    获取爪子抓下的底部坐标
]]
function ClawStallGameMain:getClawDownPos(curPos)
    local MACHINE_OFFSET = ClawStallGameManager:getMachineOffset() --机台偏移位置
    --爪子位于漏斗位置内
    if curPos.x < -8 and curPos.z > 5 then
        return 26
    end

    local downPos = 12 + self.m_highPosY
    if downPos < 17 then
        downPos = 17
    end

    if downPos > 22 then
        downPos = 22
    end

    return downPos
end

-- 检测是否抓到了道具 --
function ClawStallGameMain:checkGrapItem()
    local rayStart  = self.m_Claw:getPosition3D()

    for index = 1 ,#rayPosAry do
        local startPos  = rayStart
        startPos = cc.vec3(startPos.x + rayPosAry[index].x,startPos.y + rayPosAry[index].y,startPos.z + rayPosAry[index].z)
        local endPos    = cc.vec3( startPos.x , startPos.y - 15 , startPos.z )
        local hitResult = {}
        local ret       = false
        ret, hitResult  = self._physicsWorld:rayCast( startPos, endPos, hitResult )
        if true == ret and nil ~= hitResult.hitObj and 
            hitResult.hitObj:getObjType() == cc.Physics3DObject.PhysicsObjType.RIGID_BODY and 
            hitResult.hitPosition.y > self.m_highPosY and
            not self:isClawMaskID(hitResult.hitObj:getMask()) then
                return true
        end
    end

    local rayEnd    = cc.vec3( rayStart.x , rayStart.y - 15 , rayStart.z )
    local hitResult = {}
    local ret       = false
    ret, hitResult  = self._physicsWorld:rayCast( rayStart, rayEnd, hitResult )

    if true == ret and nil ~= hitResult.hitObj and hitResult.hitObj:getObjType() == cc.Physics3DObject.PhysicsObjType.RIGID_BODY then

        local hitObj    = hitResult.hitObj
        local objMask   = hitObj:getMask()
        local curModel  = self.m_ItemList[objMask]
    
        if curModel ~= nil then
            return true
        else
            return false
        end
    else
        return false
    end
end

--[[
    爪子变形
]]
function ClawStallGameMain:changeClawForSpecial( )
    self.m_Claw.m_light:setVisible(true)
    self.m_Claw.claw1:actionChange( 1 )
    self.m_Claw.claw2:actionChange( 1 )
    self.m_Claw.claw3:actionChange( 1 )
end

--[[
    开始吸入娃娃
]]
function ClawStallGameMain:startIndrawing( )
    self.m_waittingNode:stopAllActions()
    self.m_isClawing = true
    self.m_isStartCountDown = false
    self:stopSchedule()

    self.m_clawInfoView:hideCounter()
    -- 放下 --
    local endClaw  = function ()
        self.m_isClawing = false
        self.m_Claw.m_light:setVisible(false)
        self.m_Claw.claw1:actionRelease( 0.5 )
        self.m_Claw.claw2:actionRelease( 0.5 )
        self.m_Claw.claw3:actionRelease( 0.5 )
    end

    local actionList={}
    -- actionList[#actionList+1]=cc.CallFunc:create(function()
    --     self:changeClawForSpecial()
    -- end)

    -- actionList[#actionList+1]=cc.DelayTime:create(1)

    actionList[#actionList+1]=cc.CallFunc:create(function(  )
        --获取范围内的娃娃
        local itemsAry,itemsID = self.m_itemsAry,self.m_itemsID
        if itemsAry and #itemsAry > 0 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_indrawing_item)
            for index,item in ipairs(itemsAry) do
                item:setModelTechnique("outline")
                self:flyItemToClaw(item,function()
                    --反馈光效
                    self.m_clawInfoView:inDrawingFeedBackAni()
                    if index == #itemsAry then
                        --重启定时器
                        self:onUpdate( function(dt)
                            self:Tick(dt)
                        end)

                        endClaw()
    
                        --发送消息
                        self:sendData(itemsID)
                    end
                end)
            end
        else --没有吸到娃娃
            local machine = ClawStallGameManager:getMachineView()
            machine:delayCallBack(1,function()
                --重启定时器
                self:onUpdate( function(dt)
                    self:Tick(dt)
                end)
                self:sendData({0})
                endClaw()
            end)
            
            
        end
        
    end)

    local seq = cc.Sequence:create( actionList )
    self.m_Claw:runAction( seq )
end

--[[
    获取吸取范围内的娃娃
]]
function ClawStallGameMain:getItemsInDrawAry()
    local clawPos = self.m_Claw:getPosition3D()
    local itemAry,itemsID = {},{}
    for maskID,item in pairs(self.m_ItemList) do
        local itemPos = item:getPosition3D()
        local pos = cc.vec3( clawPos.x , itemPos.y , clawPos.z )
        --获取娃娃到爪子所在纵轴的直线距离
        local distance = ClawStallGameManager:getDistance(pos,itemPos)
        if distance < 10 then
            itemAry[#itemAry + 1] = item
            itemsID[#itemsID + 1] = item.resID
        end
    end
    
    return itemAry,itemsID
end

--[[
    娃娃飞到爪子处
]]
function ClawStallGameMain:flyItemToClaw(item,func)
    local maskID = item.m_maskID
    item.m_rigidBody:setKinematic(true)
    
    local startPos = item:getPosition3D()
    local endPos = self.m_Claw:getPosition3D()
    endPos.x = endPos.x + math.random() * math.random(-2,2)
    endPos.y = endPos.y - 8.5
    endPos.z = endPos.z + math.random() * math.random(-2,2)

    local distance = ClawStallGameManager:getDistance(startPos,endPos)
    local moveTime = distance / 25

    local actionList = {
        cc.EaseExponentialIn:create(cc.MoveTo:create( moveTime , endPos)),
        cc.CallFunc:create(function()
            self:removeItemFromList(maskID)
            if type(func) == "function" then
                func()
            end
        end)
    }

    item:runAction(cc.Sequence:create(actionList))
    
end


-- 创建单个爪子 --
function ClawStallGameMain:createSingleClaw( nIndex )
    
    local clawNode = cc.Sprite3D:create(  )
    clawNode:setCameraMask(cc.CameraFlag.USER1)
    clawNode:setPosition3D(cc.vec3(0.0, 0.0, 0.0))
    
    -- Claw Arm --
    local arm   = cc.Sprite3D:create( "physicsRes/Wwj_Zhuazi.c3b")
    arm:setTexture( "physicsRes/wawaji_zhuazi_d.png" )

    arm:setScale(20)
    arm:setPosition3D(cc.vec3(0.0, 0.0, 0.0))
    arm:setRotation3D(cc.vec3(-90.0, 0.0, 0.0))
    arm:setCameraMask(cc.CameraFlag.USER1)
    clawNode:addChild( arm )
    clawNode.arm = arm

    -- init Rotation --
    clawNode.resetRotation = function (sender )
        sender.arm:setRotation3D( cc.vec3( -60 , 0 , 0 ) )
    end
    -- Function Set --
    clawNode.setArmRotation = function (sender ,  vRot )
        sender.arm:setRotation3D( vRot )
    end
    -- Function Action Test --
    clawNode.setArmRotationAction = function (sender ,  time , vRot )
        sender.arm:stopAllActions()
        local rotateTo  = cc.RotateTo:create( time , vRot  )
        local rotateTo2 = cc.RotateTo:create( time , cc.vec3( -90 , 0 , 0 ))
        local seq       = cc.Sequence:create( rotateTo , rotateTo2 )
        local action    = cc.RepeatForever:create( seq )
        sender.arm:runAction( action )
    end
    -- 抓取 --
    clawNode.actionGrap = function ( sender ,  time , vRot )
        sender.arm:stopAllActions()
        local closeAngle = ClawStallGameManager:getClawCloseAngle()
        local rotateTo  = cc.RotateTo:create( time , cc.vec3( closeAngle , 0 , 0 )  )
        sender.arm:runAction( rotateTo )
    end
    -- 释放
    clawNode.actionRelease = function( sender , time )
        util_printLog("抓娃娃 松开爪子")
        sender.arm:stopAllActions()
        local rotateTo  = cc.RotateTo:create( time , cc.vec3( -60.0, 0.0, 0.0)  )
        sender.arm:runAction( rotateTo )
    end

    --变形
    clawNode.actionChange = function( sender , time )
        sender.arm:stopAllActions()
        local rotateTo  = cc.RotateTo:create( time , cc.vec3( -30.0, 0.0, 0.0)  )
        sender.arm:runAction( rotateTo )
    end

    --------------------------------------------
    local rbDes = {}
    local scale = 20.0
    local trianglesList = cc.Bundle3D:getTrianglesList( "physicsRes/Wwj_Zhuazi.c3b" )
    for i = 1, #trianglesList do
        trianglesList[i] = {x = trianglesList[i].x * scale, y = trianglesList[i].y * scale, z = trianglesList[i].z * scale}
    end
    rbDes.mass      = 0.0
    rbDes.shape     = cc.Physics3DShape:createMesh(trianglesList, math.floor(#trianglesList / 3))
    local rigidBody = cc.Physics3DRigidBody:create(rbDes)
    local component = cc.Physics3DComponent:create(rigidBody)
    rigidBody:setKinematic(true)
    rigidBody:setHitFraction(0)
    rigidBody:setMask( self.m_ClawMask[nIndex] )
    arm:addComponent(component)
    component:syncNodeToPhysics()
    --------------------------------------------

    return clawNode
end

--
function ClawStallGameMain:createItems( nId, vPos , vRot )

    local modelInfo = ClawStallGameManager:getItemData(nId)
    if not modelInfo then
        print( "HolyShit.  Model Info is nil : "..tostring(nId) )
        return
    end

    local modelPath = modelInfo.modelPath
    local texPath   = modelInfo.texPath
    local scale     = modelInfo.scale 
    local mass      = modelInfo.mass
    if nId < 6 then
        scale = ClawStallGameManager:getItemScale()
    else
        scale = ClawStallGameManager:getBallScale()
    end

    local pModel = cc.Sprite3D:create( modelPath  )
    pModel.resID = nId

    local mat = cc.Material:createWithFilename( "CodeClawStallPhysicsMachine/Materials/outline.material" )
    pModel:setMaterial(mat)
    mat:setTechnique("normal")
    pModel.mat = mat
    pModel:setTexture( texPath )

    pModel.setModelTechnique = function ( sender ,  sPass  )
        sender.mat:setTechnique( sPass )
        sender:setTexture( texPath )
    end


    
   
    pModel:setScale( scale )
    pModel:setPosition3D( vPos or cc.vec3(0.0, 20.0, 0) )
    pModel:setRotation3D( vPos or cc.vec3(0.0, 0.0, 0) )
    pModel:setCameraMask(cc.CameraFlag.USER1)
    
    -- 模型刚体 --
    local rbDes     = {}
    rbDes.mass      = mass

    local vec3List = self:getItemShapeInfo()
    rbDes.shape     = cc.Physics3DShape:createConvexHull(vec3List, #vec3List)

    -- local shapeList = self:getSingleItemShape( nId )
    -- rbDes.shape     = cc.Physics3DShape:createCompoundShape(shapeList)
    -- rbDes.disableSleep = true 
    local rigidBody = cc.Physics3DRigidBody:create(rbDes)
    local component = cc.Physics3DComponent:create(rigidBody)

    rigidBody:setFriction( 0.5 )
    rigidBody:setHitFraction(0)
    rigidBody:setMask( self.m_nItemMask )
    rigidBody.m_itemID = nId

    pModel:addComponent(component)
    rigidBody:setKinematic(false)

    self:addChild(pModel)
    component:syncNodeToPhysics()

    pModel.m_rigidBody = rigidBody
    pModel.m_maskID = self.m_nItemMask

    self.m_ItemList[self.m_nItemMask] = pModel
    self.m_nItemMask = self.m_nItemMask + 1
end

-- Tick --
function ClawStallGameMain:Tick( dt )

    -- 移动爪子
    self:moveClawByJoystick( dt )

    -- Check pick item --
    self:checkingPickItem( dt )

    -- Tick Eye Effect --
    self:tickEyeAction( dt )
end

-- 移动爪子 --
function ClawStallGameMain:moveClawByJoystick( dt )
    local autoStatus = ClawStallGameManager:getAutoStatus()
    if autoStatus then
        return
    end
    local MACHINE_OFFSET = ClawStallGameManager:getMachineOffset() --机台偏移位置
    if self.m_bStartMove == true and  not self.m_isClawing then
        local curPos = self.m_Claw:getPosition3D()
        local moveX  = curPos.x + self.m_vMoveSpeed.x * dt
        local moveZ  = curPos.z - self.m_vMoveSpeed.y * dt

        moveX = math.max( moveX , -20 )
        moveX = math.min( moveX , 20  )
        moveZ = math.max( moveZ , -25 + MACHINE_OFFSET )
        moveZ = math.min( moveZ , 7 + MACHINE_OFFSET)

        local newPos = cc.vec3(  moveX , curPos.y , moveZ )
        self.m_Claw:setPosition3D( newPos )

        -- 尝试变换角度 --
        local angleX = -self.m_vMoveSpeed.y * ClawStallGameMain.moveRotationAngel * ClawStallGameMain.moveRotationFactor
        local angleY = self.m_vMoveSpeed.x * ClawStallGameMain.moveRotationAngel * ClawStallGameMain.moveRotationFactor
        self.m_Claw:setAngle( cc.vec3( angleX , 0 , angleY ) )
    end

    if not self.m_isStartCountDown and not self.m_isOutOfControl and not self.m_isWaiting and self:isVisible() and not self.m_isClawing then
        self.m_outOfControlTime = self.m_outOfControlTime + dt
        --检测是否超时未操作
        if self.m_outOfControlTime >= 5 then
            self.m_isOutOfControl = true
            self.m_clawInfoView:showControlTip()
        end
    end
    
    
end

-- 检测拾取到的道具 --
function ClawStallGameMain:checkingPickItem( dt )

    self.m_checkingDuration = self.m_checkingDuration or 1

    self.m_checkingDuration = self.m_checkingDuration + dt

    if self.m_checkingDuration <= 0.2 then
        return
    end

    self.m_checkingDuration = 0.0

    --获取当前抓取模式
    local clawMode = ClawStallGameManager:getCurClawMode()
    if clawMode == CLAW_MODE.SPECIAL and not self.m_isAutoRandom then
        for k,item in pairs(self.m_ItemList) do
            item:setModelTechnique("normal")
            item.m_isHighLight = false
        end
        local itemsAry,itemsID = self:getItemsInDrawAry()
        for k,item in pairs(itemsAry) do
            item:setModelTechnique("outline")
            item.m_isHighLight = true
        end

        self.m_itemsAry = itemsAry
        self.m_itemsID = itemsID
        return
    end


    local autoStatus = ClawStallGameManager:getAutoStatus()
    --自动抓取状态下不显示描边
    if autoStatus then
        return
    end

    local rayStart  = self.m_Claw:getPosition3D()
    local rayEnd    = cc.vec3( rayStart.x , rayStart.y - 40 , rayStart.z )
    local hitResult = {}
    local ret       = false
    ret, hitResult  = self._physicsWorld:rayCast( rayStart, rayEnd, hitResult )

    if true == ret and nil ~= hitResult.hitObj and hitResult.hitObj:getObjType() == cc.Physics3DObject.PhysicsObjType.RIGID_BODY and not self:isClawMaskID(hitResult.hitObj:getMask()) then
        local hitObj = hitResult.hitObj
        local objMask= hitObj:getMask()
        --获取最高的碰撞点
        self.m_highPosY = hitResult.hitPosition.y
        local curModel = self.m_ItemList[self.m_CurPickObjMask]
        self.curModelItem = curModel

        local distance = 10
        --计算碰撞点的距离
        local objModel = self.m_ItemList[objMask]
        if objModel then
            local itemPos = objModel:getPosition3D()
            local pos = cc.vec3( itemPos.x , hitResult.hitPosition.y , itemPos.z )
            distance = ClawStallGameManager:getDistance(pos,hitResult.hitPosition)
        end

        if self.m_CurPickObjMask ~= objMask then
            if curModel ~= nil then
                curModel:setModelTechnique("normal")
                curModel.m_isHighLight = false
            end

            if objMask >= 1 and not self.m_isClawing and objModel then
                if distance < 2 and not objModel.m_isHighLight then
                    objModel:setModelTechnique("outline")
                    objModel.m_isHighLight = true
                    self.m_CurPickObjMask = objMask
                elseif objModel.m_isHighLight then
                    objModel:setModelTechnique("normal")
                    objModel.m_isHighLight = false
                    self.m_CurPickObjMask = -1
                end
            end

        else
            if self.m_isClawing or distance >= 2 and curModel and curModel.m_isHighLight then
                curModel:setModelTechnique("normal")
                curModel.m_isHighLight = false
                self.m_CurPickObjMask = -1
            end
        end
    else

        for k,item in pairs(self.m_ItemList) do
            if item.m_isHighLight then
                item:setModelTechnique("normal")
                item.m_isHighLight = false
            end
        end
        self.curModelItem = nil
        self.m_highPosY = 0
        self.m_CurPickObjMask = -1
    end

    --每个爪子发一条射线,获取每个爪子接触到的最高的点
    for index = 1 ,#rayPosAry do
        local startPos  = rayStart
        startPos = cc.vec3(startPos.x + rayPosAry[index].x,startPos.y + rayPosAry[index].y,startPos.z + rayPosAry[index].z)
        local endPos    = cc.vec3( startPos.x , startPos.y - 40 , startPos.z )
        local hitResult = {}
        local ret       = false
        ret, hitResult  = self._physicsWorld:rayCast( startPos, endPos, hitResult )
        if true == ret and nil ~= hitResult.hitObj and 
            hitResult.hitObj:getObjType() == cc.Physics3DObject.PhysicsObjType.RIGID_BODY and 
            hitResult.hitPosition.y > self.m_highPosY and
            not self:isClawMaskID(hitResult.hitObj:getMask()) then
                self.m_highPosY = hitResult.hitPosition.y
        end
    end
    
end

--[[
    检测碰撞到的是不是爪子
]]
function ClawStallGameMain:isClawMaskID(maskID)
    for k,id in pairs(self.m_ClawMask) do
        if id == maskID then
            return true
        end
    end

    if self.m_nMachineMask == maskID then
        return true
    end

    return false
end

-- 眼睛动效 --
function ClawStallGameMain:tickEyeAction( dt )

end

-------------------------------------------------- UI Function S---------------------------------------------------
-- 初始化UI --
function ClawStallGameMain:InitUI(  )

    if self._UIRoot == nil then
        self._UIRoot = cc.Node:create()
        self:addChild( self._UIRoot )
    end

    --初始化下界面
    self:initBottomUI()

    if ClawStallGameManager:getIsDebug() then
        -- 初始化 Debug 模式 --
        self:initDesktopDebugLayer()
    end
    
end

--[[
    初始化下界面
    self:initBottomUI()
]]
function ClawStallGameMain:initBottomUI( )
    self.m_clawInfoView = util_createView("CodeClawStallPhysicsMachine.ClawStallInfoView",{mainView = self})
    self:addChild(self.m_clawInfoView)

    self.m_waittingNode = cc.Node:create()
    self:addChild(self.m_waittingNode)
end

--[[
    刷新界面
]]
function ClawStallGameMain:updateView( )
    self.m_isWaiting = false
    self:stopSchedule()
    -- 开启定时器 --
    self:onUpdate( function(dt)
        self:Tick(dt)
    end)
    --初始化道具
    self:initItem()

    --初始化爪子位置
    self:initClawPos()

    --刷新收集区显示
    self.m_clawInfoView:refreshCollectItems(self.m_bonusData)
end

--[[
    初始化道具
]]
function ClawStallGameMain:initItem( )
    self:clearItems()
    -- self.m_bonusData
    if self.m_bonusData.number then
        local curNum = 0
        for itemID,num in ipairs(self.m_bonusData.number) do
            local count = tonumber(num)
            for index = 1,count do
                curNum = curNum + 1
                --随机生成的位置分为4个区域
                local randomPos= ClawStallGameManager:getRandItemPos(curNum)
                local randomRot= cc.vec3( math.random(90,180),math.random(90,180),math.random(90,180))
                self:createItems( itemID , randomPos , randomRot )
            end
        end
    end
end

--[[
    清空道具
]]
function ClawStallGameMain:clearItems( )
    for maskID,item in pairs(self.m_ItemList) do
        self:removeItemFromList(maskID)
    end
    self.m_ItemList = {}
end

--[[
    初始化爪子位置
]]
function ClawStallGameMain:initClawPos()
    local MACHINE_OFFSET = ClawStallGameManager:getMachineOffset() --机台偏移位置
    local targetPos = cc.vec3(0,CLAW_START_POS.y, -MACHINE_OFFSET)
    self.m_Claw:setPosition3D(targetPos)

    self.m_clawInfoView:setGrabBtnEnabled(true,true)
end

-------------------------------------------------- UI Function E---------------------------------------------------

-----------------------------自动抓取--------------------------------------------------------------------------------------------------------
--[[
    开始自动抓取
]]
function ClawStallGameMain:startAutoClaw()
    ClawStallGameManager:setAutoStatus(true)
    self.m_clawInfoView:updateAutoShow()
    
    if self.m_isClawing == true then
        return
    end
    local machine = ClawStallGameManager:getMachineView()
    machine:delayCallBack(1,function()
        if not ClawStallGameManager:getAutoStatus() then
            return
        end
        self.m_isAutoRandom = true
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_auto_random_item)
        self:randItemAni(function(item)
            self.m_isAutoRandom = false
            if not ClawStallGameManager:getAutoStatus() then
                return
            end

            local ani = util_createAnimation("ClawStall_shoujichu.csb")
            self:addChild(ani)
            local itemPos = item:getPosition3D()
            local pos = self:Convert3DToGL2D(itemPos)
            ani:setPosition(pos)
            ani:runCsbAction("actionframe4",false,function()
                ani:removeFromParent()
            end)

            self:moveClawToTargetItem(item)
        end)
    end)
    
end

--[[
    停止自动抓取功能
]]
function ClawStallGameMain:stopAutoAction()
    for k,item in pairs(self.m_ItemList) do
        item:setModelTechnique("normal")
        item.m_isHighLight = false
    end

    self.m_isAutoRandom = false
end

--[[
    将爪子移动到目标娃娃上方并抓取
]]
function ClawStallGameMain:moveClawToTargetItem(item)
    local itemPos = item:getPosition3D()
    local clawPos = self:getClawPos()
    local targetPos =  cc.vec3( itemPos.x , clawPos.y, itemPos.z )

    local MACHINE_OFFSET = ClawStallGameManager:getMachineOffset() --机台偏移位置
    local moveX  = targetPos.x
    local moveZ  = targetPos.z

    moveX = math.max( moveX , -20 )
    moveX = math.min( moveX , 20  )
    moveZ = math.max( moveZ , -25 + MACHINE_OFFSET )
    moveZ = math.min( moveZ , 7 + MACHINE_OFFSET)
    targetPos.x = moveX
    targetPos.z = moveZ


    -- 移动到漏斗 --
    local distance = ClawStallGameManager:getDistance(clawPos, targetPos)
    local moveBackSpeed = ClawStallGameManager:getMoveBackSpeed()
    local moveBackTime = distance / moveBackSpeed
    local actionList = {
        cc.MoveTo:create( moveBackTime , targetPos),
        cc.CallFunc:create(function()
            self.m_clawInfoView:clickFunc(self.m_clawInfoView.m_grabBtn:findChild("btn_normal"))
        end)
    }

    local seq = cc.Sequence:create( actionList )
    self.m_Claw:stopAllActions()
    self.m_Claw:runAction( seq )

    self.m_clawInfoView:showGoAni()
end

--[[
    随机一个娃娃
]]
function ClawStallGameMain:randItemAni(func)
    local tempList = {}
    for k,item in pairs(self.m_ItemList) do
        tempList[#tempList + 1] = item
        item:setModelTechnique("normal")
        item.m_isHighLight = false
    end
    --随机出需要显示的娃娃列表
    local randomList = {}
    for index = 1,4 do
        if #tempList == 0 then
            break
        end

        local randIndex = math.random(1,#tempList)
        randomList[#randomList + 1] = tempList[randIndex]
        table.remove(tempList,index)
    end
    
    self:showNextRandItem(randomList,1,function()
        if type(func) == "function" then
            func(randomList[#randomList])
        end
    end)
end

--[[
    显示下一个娃娃
]]
function ClawStallGameMain:showNextRandItem(list,index,func)
    if not ClawStallGameManager:getAutoStatus() then
        return
    end
    if index > #list then
        if type(func) == "function" then
            func()
        end
        return
    end

    local delayTime = 0.3 --1 - (index - 1) * 0.1
    local item = list[index]
    for i,item in ipairs(list) do
        if i == index then --显示描边
            item:setModelTechnique("outline")
        else
            item:setModelTechnique("normal")
        end
    end

    local machine = ClawStallGameManager:getMachineView()
    machine:delayCallBack(delayTime,function()
        self:showNextRandItem(list,index + 1,func)
    end)
end

-----------------------------自动抓取 end--------------------------------------------------------------------------------------------------------

-------------------------------------------------- SingleItem  S---------------------------------------------------
function ClawStallGameMain:getSingleItemShape( nID )
    local shapeList = {}
    local bodyshape = nil
    local localTrans= nil

    if nID <= 6 then
        bodyshape  =  cc.Physics3DShape:createSphere( 3 )
        localTrans = cc.mat4.createTranslation( 0 , 0 , 0 )
        table.insert(shapeList, {bodyshape, localTrans})
    elseif nID == 6 then
        bodyshape  =  cc.Physics3DShape:createCylinder( 6 , 4.5 )
        localTrans = cc.mat4.createTranslation( 0 , 0 , 0 )
        table.insert(shapeList, {bodyshape, localTrans})
    elseif nID == 7 then
        bodyshape  =  cc.Physics3DShape:createCapsule( 3 , 1.8 )
        localTrans = cc.mat4.createRotation(cc.vec3(1.0, 0.0, 0.0), 90.0 * math.pi / 180)
        localTrans[13] = 0.0
        localTrans[14] = 0.0
        localTrans[15] = 0.0
        table.insert(shapeList, {bodyshape, localTrans})

        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 2.2, 1.5, 2.2 ))
        localTrans = cc.mat4.createTranslation( 0, -3 , 0 )
        table.insert(shapeList, {bodyshape, localTrans})
    elseif nID == 8 then
        bodyshape  = cc.Physics3DShape:createSphere( 2.2 )
        localTrans = cc.mat4.createTranslation( 0.5 , 1 , -1 )
        table.insert(shapeList, {bodyshape, localTrans})

        bodyshape  = cc.Physics3DShape:createSphere( 2.2 )
        localTrans = cc.mat4.createTranslation( 0.5 , -1 , -0.3 )
        table.insert(shapeList, {bodyshape, localTrans})

        bodyshape  = cc.Physics3DShape:createSphere( 1.5 )
        localTrans = cc.mat4.createTranslation( -1.5 , -1.5 , 1.5 )
        table.insert(shapeList, {bodyshape, localTrans})
    elseif nID == 9 then
        bodyshape  =  cc.Physics3DShape:createCapsule( 2 , 1.5 )
        localTrans = cc.mat4.createTranslation( 0 , 0 , 0 )
        table.insert(shapeList, {bodyshape, localTrans})

        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 2, 2, 2 ))
        localTrans = cc.mat4.createTranslation( 0, -2 , 0 )
        table.insert(shapeList, {bodyshape, localTrans})
    elseif nID == 10 then
        bodyshape  = cc.Physics3DShape:createSphere( 3 )
        localTrans = cc.mat4.createTranslation( 0 , 0 , 1.5 )
        table.insert(shapeList, {bodyshape, localTrans})

        bodyshape  = cc.Physics3DShape:createSphere( 3 )
        localTrans = cc.mat4.createTranslation( 0 , -1.5 , 0 )
        table.insert(shapeList, {bodyshape, localTrans})

        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 4.5, 6, 3 ))
        localTrans = cc.mat4.createTranslation( 0, -1.5 , -3.6 )
        table.insert(shapeList, {bodyshape, localTrans})
    end

    return shapeList
end

function ClawStallGameMain:getItemShapeInfo()                          
    local nPlaneCount = 5

    local itemRadius = ClawStallGameManager:getItemRadius()
    local radiusAry = {0.1}
    for index = 1,3 do
        local tempRadius = math.sqrt(math.pow(itemRadius,2) - math.pow(itemRadius / 3 * (3 - index),2) )
        radiusAry[#radiusAry + 1] = tempRadius
    end

    -- local radiusAry = {0.1,math.sqrt(5),math.sqrt(8),itemRadius}
    local lVec3List = {}

    for index = 1,#radiusAry do
        local nRadiu      = radiusAry[index]
        local nHeight     = math.sqrt(itemRadius * itemRadius - nRadiu * nRadiu)
        local nAnglePre = 360 / nPlaneCount

        -- --创建一个6边形
        -- lVec3List[#lVec3List + 1] = cc.vec3(nRadiu,-nHeight,nRadiu / 2)
        -- lVec3List[#lVec3List + 1] = cc.vec3(0,-nHeight,nRadiu)
        -- lVec3List[#lVec3List + 1] = cc.vec3(-nRadiu,-nHeight,nRadiu / 2)
        -- lVec3List[#lVec3List + 1] = cc.vec3(-nRadiu,-nHeight,-nRadiu / 2)
        -- lVec3List[#lVec3List + 1] = cc.vec3(0,-nHeight,-nRadiu)
        -- lVec3List[#lVec3List + 1] = cc.vec3(nRadiu,-nHeight,-nRadiu / 2)
        -- lVec3List[#lVec3List + 1] = cc.vec3(nRadiu,-nHeight,nRadiu / 2)

        local lSymbolList = { cc.p(1, -1), cc.p(-1, -1), cc.p(-1, 1), cc.p(1, 1) }
        for i=1, nPlaneCount do
            local nAngle = nAnglePre * i
            local nIndex  = 1    
        
            --区分象限 算出计算坐标角度
            if nAngle >= 0 and nAngle < 90 then
                nIndex = 1
            elseif nAngle >= 90 and nAngle < 180 then
                nIndex = 2  
                nAngle = 180 - nAngle
            elseif nAngle >= 180 and nAngle < 270 then
                nIndex = 3  
                nAngle = nAngle - 180
            elseif nAngle >= 270 and nAngle < 360 then
                nIndex = 4  
                nAngle = 360 - nAngle
            end

            local xPos = math.cos(math.rad(nAngle)) * nRadiu
            local zPos = math.sin(math.rad(nAngle)) * nRadiu
            local symbol = lSymbolList[nIndex]
            local vec3Pos = cc.vec3(symbol.x * xPos,-nHeight, symbol.y * zPos  )
            table.insert(lVec3List,vec3Pos)
            
        end
        -- 闭环坐标
        table.insert(lVec3List,cc.vec3(lVec3List[#lVec3List - nPlaneCount + 1].x,lVec3List[#lVec3List - nPlaneCount + 1].y,lVec3List[#lVec3List - nPlaneCount + 1].z))
    end
    local shapeList = {}
    --添加镜像坐标
    for i=1, #lVec3List do
        local vec3 = lVec3List[i]
        if vec3.y ~= 0 then
            local imageVec3 = cc.vec3(vec3.x, math.abs(vec3.y) ,vec3.z)
            table.insert(lVec3List,imageVec3)
        end
        
    end

    return lVec3List
end
-------------------------------------------------- SingleItem  E---------------------------------------------------

-----------------------------------------网络消息-------------------------------------------------------------------------------------------
--[[
    发送消息
]]
function ClawStallGameMain:sendData(choose)
    if self.m_isWaiting then
        return
    end
    -- util_printLog("抓娃娃 发送数据:"..choose)
    self.m_isWaiting = true
    ClawStallGameManager:sendBonusData(choose)
end
--[[
    消息返回
]]
function ClawStallGameMain:featureResultCallFun(param)
    if not self:isVisible() then
        return
    end
    if param[1] == true then
        local spinData = param[2]
        if spinData.action == "FEATURE" then
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        
            self:recvBaseData(spinData.result)
        end
    else
        gLobalViewManager:showReConnect(true)
    end
end


--[[
    接收数据
]]
function ClawStallGameMain:recvBaseData(featureData)
    ClawStallGameManager.m_isCanClaw = featureData.bonus.extra.CanClaw
    if ClawStallGameManager.m_isPreClaw then
        ClawStallGameManager.m_isPreClaw = false
        self.m_clawInfoView:startClaw()
        return
    end

    self.m_waittingNode:stopAllActions()
    
    util_printLog("抓娃娃 消息返回")
    self.m_featureData = featureData
    self:updateBonusData(featureData.bonus.extra)

    --刷新本次收集奖励
    local curIndex = self.m_bonusData.bonustime
    if curIndex == 0 then
        curIndex = 1
    end
    local curRewardData = self.m_bonusData.collect[curIndex]
    --显示当前抓取的奖励
    self.m_clawInfoView:showRewardAni(curIndex,curRewardData,function(  )
        self.m_isClawing = false
        --刷新收集区显示
        self.m_clawInfoView:refreshCollectItems(self.m_bonusData)

        util_printLog("抓娃娃 刷新奖励")

        if featureData.bonus.status == "CLOSED" then
            self.m_clawInfoView:playScoreCollectAnim(self.m_bonusData.collect,function(  )
                if type(self.m_endFunc) == "function" then
                    self.m_endFunc(self.m_featureData)
                end
            end)
        else
            -- if curRewardData[1] ~= "0" then
            --     self.m_clawInfoView:setGrabBtnEnabled(false,true)
            -- else
            --     self.m_clawInfoView:setGrabBtnEnabled(true,true)
            -- end
            self.m_clawInfoView:setGrabBtnEnabled(true,true)
            self.m_isWaiting = false

            --检测添加娃娃
            self:checkAddItems()
            
        end
    end)

    
end

--[[
    检测是否需要添加娃娃
]]
function ClawStallGameMain:checkAddItems( )
    local addNums = self.m_bonusData.addnumber
    if not addNums then
        return
    end

    local curNum = 0

    for itemID,num in pairs(addNums) do
        if num > 0 then
            for index = 1,num do
                curNum = curNum + 1
                --随机生成的位置分为4个区域
                local randomPos= ClawStallGameManager:getRandItemPos(curNum)
                local randomRot= cc.vec3( math.random(90,180),math.random(90,180),math.random(90,180))
                randomPos.y = 20
                self:createItems( itemID , randomPos , randomRot )
            end
        end
    end
end

--[[
    刷新bonus数据
]]
function ClawStallGameMain:updateBonusData(bonusData)
    self.m_bonusData = clone(bonusData) 
end

-----------------------------------------网络消息  end-------------------------------------------------------------------------------------------

-------------------------------------------------- Debug       S-----------------------------------------------
function ClawStallGameMain:initDesktopDebugLayer()
    self._DesktopLayer = require("CodeClawStallPhysicsMachine.ClawStallGameDebugLayer").new( self )
    self._DesktopLayer:setPosition(display.cx , display.cy )
    self:addChild(self._DesktopLayer)
end

function ClawStallGameMain:removeDesktopDebugLayer()
    if self._DesktopLayer then
        self._DesktopLayer:removeFromParent()
        self._DesktopLayer = nil
    end
end

--[[
    获取爪子坐标
]]
function ClawStallGameMain:getClawPos( )
    local clawPos = self.m_Claw:getPosition3D()
    return clawPos
end
-------------------------------------------------- Debug       E-----------------------------------------------

return ClawStallGameMain