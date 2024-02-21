--[[
    GamePusherMainLayer
    -- game推币机主界面
]]
local GamePusherManager   = require "CandyPusherSrc.GamePusherManager"
local Config              = require("CandyPusherSrc.GamePusherMain.GamePusherConfig")

local GamePusherMainLayer = class( "GamePusherMainLayer",
    function() 
        return cc.Layer:create() 
    end
)


local SYNC_DIRTY_DATA_TIME      =       2 --同步脏数据时间间隔

----------------------------------------------------------------------------------------
-- 框架(ctor, getInstance, onEnter, onExit)
----------------------------------------------------------------------------------------
function GamePusherMainLayer:ctor(  )

    local function onNodeEvent(event)
         if "enter" == event then
            self:onEnter()
        elseif "exit" == event then
            self:onExit()
        end
    end
    
    self:registerScriptHandler(onNodeEvent)

    self.m_isSyncDirty = false

    self.m_WallsLeftTimes = nil                                              -- 墙道具剩余时间 

    self.m_coinsShowType  = 1

    self.m_tEntityList    = {}                                               -- 场景中动态实体列表 
    self.m_nEntityIndex   = Config.EntityIndex                               -- 动态实体全局索引    
    self.m_ntbFloorIndex  = Config.TbFloorIndex                              -- 地板相关索引
    self.m_nPusherIndex   = Config.PusherIndex                               -- 推板相关索引
    self.m_nEntityWin     = 0                                                -- 中奖的实体个数     
    self.m_nEntityLose    = 0                                                -- 丢失的实体个数     
    self.m_tEntityDropped = {                                                -- 掉落的细节统计     
            CoinWin  = {} ,                                                 
            CoinLose = {}  }   

    self.m_tLoseData = {}                                                    -- 掉落金币Lose信息
    self.m_tWinData  = {}                                                    -- 掉落金币win信息
        
    self.m_nBuffUpdataTime = Config.ComboFreshDt   
    self.m_bBuffUpdateState = false   

    self.m_nTapUpdateTime  = Config.TapUpdateTime
    self.m_bTapUpdateState = true

    self.m_bTouchDropCoinsState = false 
    self.m_bAutoDropCoins       = false 
    self.m_nAutoDropTime = 1                                                 
    self.m_bSoundNotPlay = true                                              -- 是否播放音效标志

    self.m_bPusherOver    = false 
    self.m_bOutLinePlayStates = false                                        -- 为了处理一进推币机时某些检测不应该生效的问题

    self.m_freeSpinTimes = 0  
    self.m_pGamePusherMgr = GamePusherManager:getInstance()                  -- Mgr对象

    -- 初始化推币机时初始化各个模块的状态--
    self:stopPushing()    
end

function GamePusherMainLayer:onEnter(  )
    -- Register Even注册事件--
    self:onRegistEvent() 

    -- 初始化摄像机--
    self:InitCamera()  

    -- 创建静态模型及碰撞体--
    self:createStaticModel()                                                 

    -- 创建Slot显示及逻辑--
    self:InitReelTable()

    -- 加载存储的场景数据并创建实体--
    self:loadSceneEntityData()  

    -- 初始化MainUI--
    self:InitUI()     

    -- 初始化特效管理器--
    self:InitEffect()                                                       

    -- 播放音乐bool-- 
    self.m_bSoundNotPlay  = false         
                                      
    self.m_pMainUI:setTouchState(true)


    -- 初始化buff状态--
    self:initLifterStatus()                                                 
    
    -- 开启定时器--
    self:onUpdate( function(dt)                                             
        self:Tick(dt)
    end)

          

    if Config.Debug == true then                                            -- 初始化调试面板
        self.m_pDebugLayer = require(Config.ViewPathConfig.Debug).new( self )
        self:addChild( self.m_pDebugLayer )
        self.m_pDebugLayer:InitDebugPro()
    end



end



function GamePusherMainLayer:onExit(  )
    gLobalNoticManager:removeAllObservers(self)
end

----------------------------------------------------------------------------------------
-- 注册事件
----------------------------------------------------------------------------------------
-- 注：网络数据或者延时数据来处理界面 必须用事件来驱动 -
function GamePusherMainLayer:onRegistEvent(  )
    
    gLobalNoticManager:addObserver( self,function(self, params)    
            -- 动画触发回调         
            local playType = params[1]
            local data = params[2]
            if playType == Config.CoinEffectRefer.NORMAL then
                self.m_pGamePusherMgr:setPlayEnd(data)

            elseif playType == Config.CoinEffectRefer.SLOTS then 
                --小老虎机玩法  
                self:playSlotPlayEffect( data ) --老虎机动画   
            elseif playType == Config.CoinEffectRefer.WALL then
                -- 两侧城墙
                self:updateWallUpTimes( data )
            elseif playType == Config.CoinEffectRefer.SHAKE then
                -- 大锤子凿桌面
                self:playShakeProp( data )
            elseif playType == Config.CoinEffectRefer.BIGCOINS then
                -- 掉落大金币
                self:playBigCoinsProp( data )
            elseif playType == Config.CoinEffectRefer.COINSTOWER then
                -- 掉落金币塔玩法
                local animationStates = data:getAnimateStates()
                if animationStates == Config.CoinTowerAnimStates.TowerDrop then
                    self:playCoinsTowerDropEffect(data )
                elseif animationStates == Config.CoinTowerAnimStates.TablePush then
                    self:playCoinsTowerPushTableCoins(data)
                else
                    self.m_pGamePusherMgr:setPlayEnd(data)
                end
            elseif playType == Config.CoinEffectRefer.COINSRAIN then
                -- 掉落金币雨玩法
                self:playCoinsRainEffect(data)
            elseif playType == Config.CoinEffectRefer.COINSPILE then
                -- 随机掉落小金币堆玩法 小金币堆奖励币
                self:coinsPileDropCoins( data )    
            elseif playType == Config.CoinEffectRefer.JACKPOT then
                -- Jackopt玩法 mini minor major grand
                self:playJpCollectEffect(data)
            end
        
    end, Config.Event.GamePusherTriggerEffect)
 
    gLobalNoticManager:addObserver( self,function(self, params)                -- 实体存档
        self:saveEntityData()
        end, Config.Event.GamePusherSaveEntity)
   
    gLobalNoticManager:addObserver( self,function(self, params)                -- 更新UI  放入MainUI中？
        self:updateMainUI()
    end, Config.Event.GamePusherUpdateMainUI)

    gLobalNoticManager:addObserver(                                            -- buff打开
        self,
        function(self, params)
            self.m_pGamePusherMgr:pubSaveCoinPusherDeskstopData(self:getSceneEntityData())
        end,
    Config.Event.GamePusherTestSaveData)


    gLobalNoticManager:addObserver( self,function(self, params)                -- 重置升降台位置
        self:restLifter( )
    end, Config.Event.GamePusherMainUI_Rest_WallPos)
   

    gLobalNoticManager:addObserver( self,function(self, params)                -- 通知有新的游戏事件添加到playList
        local  data = params[1]
        local actionType = data:getActionType()
        local playState  = data:getActionState()
        if playState ~= Config.PlayState.DONE and actionType == Config.CoinEffectRefer.SLOTS then
            self.m_freeSpinTimes = self.m_freeSpinTimes + 1
            
            gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_BonusSpinTimes.mp3")
            self._freeSpinText:stopAllActions()
            self._freeSpinText:runCsbAction("actionframe")
            performWithDelay(self._freeSpinText,function()
                self:updataFreeSpinCount( self.m_freeSpinTimes)
            end,10/60)
            
        end
    end, Config.Event.GamePusherAddPlayList)
    


end

----------------------------------------------------------------------------------------
-- 摄像机
----------------------------------------------------------------------------------------

-- Init Camera --
function GamePusherMainLayer:InitCamera(  )
    local scene = self:getScene()
    if scene == nil then
        assert( false , "Get Physics scene failed ")
    end

    -- set physics world --
    self.m_pPhysicsScene = scene
    self.m_pPhysicsWorld = scene:getPhysics3DWorld()
    
    self.m_pPhysicsWorld:setDebugDrawEnable(false)
    self.m_pPhysicsWorld:setGravity( cc.vec3(0,Config.Gravity,0) )

    -- init camera --
    self.m_nAngle     = 0.0
    self.m_nDistance  = 33.0                                                                        -- 摄像机距离参数

    local nSaleAdapt = 1

    local nScaleDesign  = DESIGN_SIZE.height /  DESIGN_SIZE.width
    local nScaleDisplay = display.height /  display.width

    if nScaleDisplay > nScaleDesign then
        nSaleAdapt = nScaleDisplay / nScaleDesign
        self.m_nDistance  = self.m_nDistance * nSaleAdapt
    end

    self.m_v3LookAtOri     = cc.vec3( 0 , -4 , 11 *  nSaleAdapt )                                       -- 观察原点 --
    self.m_v3LookAtReel    = cc.vec3( 0 , 14  , 8 *  nSaleAdapt + 7 )                                 -- 观察滚轴 --
    -- self.m_v3LookAtReel.z  = self.m_v3LookAtReel.z
    self.m_v3CameraPosOri  = cc.vec3(0.0, self.m_nDistance - 0.618 + 1 - 5.5, self.m_nDistance + 9.5)         -- 摄像机原位置 --
    self.m_v3CameraPosReel = cc.vec3(0.0, self.m_nDistance - 0.618 + 1  , self.m_nDistance  + 6)    -- 摄像机移动位置--

    self.m_nCameraType = 0    
                                                                             -- IDLE状态--
    local size   = cc.Director:getInstance():getWinSize()
    self.m_pCamera = cc.Camera:createPerspective(60.0, size.width / size.height, 1.0, 1000.0)
    self.m_pCamera:setPosition3D(self.m_v3CameraPosOri)
    self.m_pCamera:lookAt( self.m_v3LookAtOri , cc.vec3(0.0, 1.0, 0.0))
    self.m_pCamera:setCameraFlag(cc.CameraFlag.USER1)
    self:addChild(self.m_pCamera)
    self.m_pPhysicsScene:setPhysics3DDebugCamera(self.m_pCamera)


end

function GamePusherMainLayer:setCameraPosData( _lookAtReel)
    if _lookAtReel then
        -- 看向推币机
        self.m_pCamera:setPosition3D(self.m_v3CameraPosReel)
        self.m_pCamera:lookAt( self.m_v3LookAtReel , cc.vec3(0.0, 1.0, 0.0))
    else
        -- 看向基础轮盘的老虎机
        self.m_pCamera:setPosition3D(self.m_v3CameraPosOri)
        self.m_pCamera:lookAt( self.m_v3LookAtOri , cc.vec3(0.0, 1.0, 0.0))
    end
    
end

-- Move Camera --
function GamePusherMainLayer:MoveCamera(  nType , fTime  )
    self.m_nCameraType     = nType
    self.m_nCameraMoveTime = fTime

    self.m_nRunTime = 0

    if nType == 2 then
        self.m_v3CurLookAt    = cc.vec3( self.m_v3LookAtReel.x   , self.m_v3LookAtReel.y    , self.m_v3LookAtReel.z    )
        self.m_v3CurCameraPos = cc.vec3( self.m_v3CameraPosReel.x, self.m_v3CameraPosReel.y , self.m_v3CameraPosReel.z )
    elseif nType == 3 then 
        self.m_v3CurLookAt    = cc.vec3( self.m_v3LookAtOri.x    , self.m_v3LookAtOri.y     , self.m_v3LookAtOri.z    )
        self.m_v3CurCameraPos = cc.vec3( self.m_v3CameraPosOri.x , self.m_v3CameraPosOri.y  , self.m_v3CameraPosOri.z  )
    end
end


-- Camrea actions --
function GamePusherMainLayer:CameraTick( dt )

    if self.m_nCameraType == 0 then
        -- do nothing --
    elseif self.m_nCameraType == 2 then
        -- 看向基础老虎机轮盘 --
        self.m_v3CurLookAt.y = self.m_v3CurLookAt.y - ( self.m_v3LookAtReel.y - self.m_v3LookAtOri.y ) / self.m_nCameraMoveTime * dt
        self.m_v3CurLookAt.z = self.m_v3CurLookAt.z - ( self.m_v3LookAtReel.z - self.m_v3LookAtOri.z ) / self.m_nCameraMoveTime * dt
        local moveStep = 0
        if self.m_v3CurLookAt.y <= self.m_v3LookAtOri.y then
            self.m_v3CurLookAt.y = self.m_v3LookAtOri.y
            moveStep = moveStep + 1
        end
        if self.m_v3CurLookAt.z <= self.m_v3LookAtOri.z then
            self.m_v3CurLookAt.z = self.m_v3LookAtOri.z
            moveStep = moveStep + 1
        end
        self.m_pCamera:lookAt( self.m_v3CurLookAt, cc.vec3(0.0, 1.0, 0.0))

        -- move camera postion --
        self.m_v3CurCameraPos.y = self.m_v3CurCameraPos.y - ( self.m_v3CameraPosReel.y - self.m_v3CameraPosOri.y ) / self.m_nCameraMoveTime * dt
        self.m_v3CurCameraPos.z = self.m_v3CurCameraPos.z - ( self.m_v3CameraPosReel.z - self.m_v3CameraPosOri.z ) / self.m_nCameraMoveTime * dt
        if self.m_v3CurCameraPos.y <= self.m_v3CameraPosOri.y then
            self.m_v3CurCameraPos.y = self.m_v3CameraPosOri.y
            moveStep = moveStep + 1
        end
        if self.m_v3CurCameraPos.z >= self.m_v3CameraPosOri.z then
            self.m_v3CurCameraPos.z = self.m_v3CameraPosOri.z 
            moveStep = moveStep + 1
        end
        self.m_pCamera:setPosition3D( self.m_v3CurCameraPos )

        if moveStep == 4 then
            self.m_nCameraType = 0
            self:setCameraPosData( )
        end 
    elseif self.m_nCameraType == 3 then
        -- 看向推币机的方向 --
        self.m_v3CurLookAt.y = self.m_v3CurLookAt.y + ( self.m_v3LookAtReel.y - self.m_v3LookAtOri.y ) / self.m_nCameraMoveTime * dt
        self.m_v3CurLookAt.z = self.m_v3CurLookAt.z + ( self.m_v3LookAtReel.z - self.m_v3LookAtOri.z ) / self.m_nCameraMoveTime * dt
        local moveStep = 0
        if self.m_v3CurLookAt.y >= self.m_v3LookAtReel.y then
            self.m_v3CurLookAt.y = self.m_v3LookAtReel.y
            moveStep = moveStep + 1
        end
        if self.m_v3CurLookAt.z >= self.m_v3LookAtReel.z then
            self.m_v3CurLookAt.z = self.m_v3LookAtReel.z
            moveStep = moveStep + 1
        end
        self.m_pCamera:lookAt( self.m_v3CurLookAt, cc.vec3(0.0, 1.0, 0.0))

        -- move camera postion --
        self.m_v3CurCameraPos.y = self.m_v3CurCameraPos.y + ( self.m_v3CameraPosReel.y - self.m_v3CameraPosOri.y ) / self.m_nCameraMoveTime * dt
        self.m_v3CurCameraPos.z = self.m_v3CurCameraPos.z + ( self.m_v3CameraPosReel.z - self.m_v3CameraPosOri.z ) / self.m_nCameraMoveTime * dt
        if self.m_v3CurCameraPos.y >= self.m_v3CameraPosReel.y then
            self.m_v3CurCameraPos.y = self.m_v3CameraPosReel.y
            moveStep = moveStep + 1
        end
        if self.m_v3CurCameraPos.z <= self.m_v3CameraPosReel.z then
            self.m_v3CurCameraPos.z = self.m_v3CameraPosReel.z
            moveStep = moveStep + 1
        end
        self.m_pCamera:setPosition3D( self.m_v3CurCameraPos )

        -- Move OK --
        if moveStep == 4 then
            self.m_nCameraType = 0
            self:setCameraPosData(true )
        end
    end
end
-- Camera quake --
function GamePusherMainLayer:CameraQuake(  )
    
    local actions   = {}
    local move_up   = cc.MoveBy:create( 0.05 , cc.vec3( 0, 1 ,0 ) )
    actions[#actions + 1] = move_up
    local move_down = cc.MoveBy:create( 0.05 , cc.vec3( 0, -1.5 , 0)  )
    actions[#actions + 1] = move_down
    local move_back = cc.MoveBy:create( 0.05 , cc.vec3( 0, 0.5 , 0)  )
    actions[#actions + 1] = move_back

    local seq = cc.Sequence:create( actions )
    self.m_pCamera:runAction(seq)

end

-- Camera quake --
function GamePusherMainLayer:CameraQuakeMax(  )
    
    local actions   = {}
    local move_up   = cc.MoveBy:create( 0.05 , cc.vec3( 0, 1 ,0 ) )
    actions[#actions + 1] = move_up
    local move_down = cc.MoveBy:create( 0.05 , cc.vec3( 0, -2.5 , 0)  )
    actions[#actions + 1] = move_down
    local move_back = cc.MoveBy:create( 0.05 , cc.vec3( 0, 1.5 , 0)  )
    actions[#actions + 1] = move_back

    local seq = cc.Sequence:create( actions )
    self.m_pCamera:runAction(seq)

end

-- 3D世界坐标转屏幕2d坐标(屏幕坐标系:原点在屏幕左上角，x轴向右，y轴向下)
function GamePusherMainLayer:Convert3DToScreen2D(vec3Pos)
    local uiPos = self.m_pCamera:project(vec3Pos)
    return uiPos
end

-- 3D世界坐标转OpenGL2d坐标(OpenGL坐标系:该坐标系原点在屏幕左下角，x轴向右，y轴向上)
function GamePusherMainLayer:Convert3DToGL2D(vec3Pos)
    local uiPos = self.m_pCamera:projectGL(vec3Pos)
    return uiPos
end

----------------------------------------------------------------------------------------
-- 推币机 道具
----------------------------------------------------------------------------------------
-- Create CoinPuhserCoins --
function GamePusherMainLayer:createCoins( _sType , _vPos , _vRot , _bCollision)
    if _sType == nil then
        local nRandomIndex = math.random(1, table.nums(Config.CoinModelRefer))
        _sType = Config.CoinModelRefer.NORMAL
    end


    local itemAtt = Config.CoinModelAtt[_sType]
    local vec3List, rbDes = self:getCoinShapeInfo(itemAtt)

    rbDes.shape     = cc.Physics3DShape:createConvexHull(vec3List, #vec3List)
    local rigidBody  = cc.Physics3DRigidBody:create(rbDes) -- 
    local component  = cc.Physics3DComponent:create(rigidBody)
    local sprite    = cc.PhysicsSprite3D:create( itemAtt.Model, rbDes )
    sprite:setCameraMask(cc.CameraFlag.USER1)
    -- rigidBody:setMassProps(150,cc.vec3(0,0,0))

    if itemAtt.Texture then
        sprite:setTexture(itemAtt.Texture)
    end

    local rigidBody = sprite:getPhysicsObj()
    rigidBody:setFriction( itemAtt.Friction )
    local htFraction = rigidBody:getHitFraction()
    rigidBody:setRestitution(Config.CoinsRestitution  )
    sprite:setScale( itemAtt.Scale )
    sprite:setRotation3D( _vRot )
    sprite:setPosition3D( _vPos )
    self.m_sp3DEntityRoot:addChild(sprite)
    -- 设置 mask --
    self.m_nEntityIndex = self.m_nEntityIndex + 1
    rigidBody:setMask( self.m_nEntityIndex )
    
    self.m_tEntityList[self.m_nEntityIndex] = {Index = self.m_nEntityIndex ,Type = Config.EntityType.COIN, ID = _sType, Node = sprite, Collision = _bCollision or false}
    -- rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true
    

    -- 添加碰撞监测函数 --
    if _sType == "BIG" then
        rigidBody:setCollisionCallback(function (collisionInfo)
            if nil ~= collisionInfo.collisionPointList and #collisionInfo.collisionPointList > 0 then
                local colAMask = collisionInfo.objA:getMask()
                local colBMask = collisionInfo.objB:getMask()
                -- 都需要矫正Mask,因为不一定A/B是金币 --
                local coinsMask = colBMask
                if colAMask >= Config.EntityIndex  then
                    coinsMask = colAMask
                end
                
                self:bigCoinCollision( coinsMask )
            end
        end)
    end
   
    return sprite
end

-- 金币刚体信息 ps: 六棱柱 
function GamePusherMainLayer:getCoinShapeInfo(_itemAtt)
    
    local rbDes = {}
    rbDes.mass        = _itemAtt.Mass                             
    local nPlaneCount = _itemAtt.palne
    local nRadiu      = _itemAtt.PhysicSize.x / math.cos(math.rad( 45 / (nPlaneCount / 4) )) /2 --斜边
    local nHeight     = _itemAtt.PhysicSize.y + 0.3
    
    local lSymbolList = { cc.p(1, -1), cc.p(-1, -1), cc.p(-1, 1), cc.p(1, 1) }
    local lVec3List = {}
    local nAnglePre = 360 / nPlaneCount

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
        local vec3Pos = cc.vec3(symbol.x * xPos,-nHeight/2, symbol.y * zPos  )
        table.insert(lVec3List,vec3Pos)
    end 
    
    --闭环坐标
    table.insert(lVec3List,cc.vec3(lVec3List[1].x,lVec3List[1].y,lVec3List[1].z))
    local shapeList = {}

    --添加镜像坐标
    for i=1, #lVec3List do
        local vec3 = lVec3List[i]
        local imageVec3 = cc.vec3(vec3.x, nHeight / 2 ,vec3.z)
        table.insert(lVec3List,imageVec3)
    end

    return lVec3List, rbDes
end

-- 创建道具 --
function GamePusherMainLayer:createItem( nIndex , vPos , vRot )

   
end

function GamePusherMainLayer:createFloorBackModel(vSize, vPos)

    local rbDes = {}
    rbDes.mass  = 0
    
    local shapeList = {}
    local bodyshape = nil
    local localTrans= nil
    
    bodyshape  = cc.Physics3DShape:createBox(vSize)
    localTrans = cc.mat4.createTranslation(0.0, -9.7 , -8.5 )
    table.insert(shapeList, {bodyshape, localTrans})

    rbDes.shape      = cc.Physics3DShape:createCompoundShape(shapeList)
    local rigidBody  = cc.Physics3DRigidBody:create(rbDes)
    local component  = cc.Physics3DComponent:create(rigidBody)
    local sprite     = cc.Sprite3D:create(  )
    rigidBody:setFriction(Config.PlatformModelAtt.Platform.BackFriction)
    sprite:setCameraMask(cc.CameraFlag.USER1)
    sprite:addComponent(component)
    self:addChild(sprite)
    sprite:setRotation3D(cc.vec3(0.0, 0.0,  0.0))
    sprite:setPosition3D(vPos)
    component:syncNodeToPhysics()
    rigidBody:setKinematic(true)

    return sprite,rigidBody
end

----------------------------------------------------------------------------------------
-- 推币机实体  台子 底座 升降台等create
----------------------------------------------------------------------------------------
function GamePusherMainLayer:createFloorForntModel(vSize, vPos)

    local rbDes = {}
    rbDes.mass  = 0
    
    local shapeList = {}
    local bodyshape = nil
    local localTrans= nil
    
    bodyshape  = cc.Physics3DShape:createBox(vSize)
    localTrans = cc.mat4.createTranslation(0.0, -9.7 , -8.5 )
    table.insert(shapeList, {bodyshape, localTrans})

    rbDes.shape      = cc.Physics3DShape:createCompoundShape(shapeList)
    local rigidBody  = cc.Physics3DRigidBody:create(rbDes)
    local component  = cc.Physics3DComponent:create(rigidBody)
    local sprite     = cc.Sprite3D:create(  )
    rigidBody:setFriction(Config.PlatformModelAtt.Platform.FrontFriction)
    sprite:setCameraMask(cc.CameraFlag.USER1)
    sprite:addComponent(component)
    self:addChild(sprite)
    sprite:setRotation3D(cc.vec3(0.0, 0.0,  0.0))
    sprite:setPosition3D(vPos)
    component:syncNodeToPhysics()
    rigidBody:setKinematic(true)

    return sprite,rigidBody
end

function GamePusherMainLayer:createFloorBorderModel(vSize, vPos)

    local rbDes = {}
    rbDes.mass  = 0
    
    local shapeList = {}
    local bodyshape = nil
    local localTrans= nil
    
    bodyshape  = cc.Physics3DShape:createBox(vSize)
    localTrans = cc.mat4.createTranslation(0.0, -9.7 , -8.5 )
    table.insert(shapeList, {bodyshape, localTrans})

    rbDes.shape      = cc.Physics3DShape:createCompoundShape(shapeList)
    local rigidBody  = cc.Physics3DRigidBody:create(rbDes)
    local component  = cc.Physics3DComponent:create(rigidBody)
    local sprite     = cc.Sprite3D:create(  )
    rigidBody:setFriction(Config.PlatformModelAtt.Platform.BorderFriction)
    sprite:setCameraMask(cc.CameraFlag.USER1)
    sprite:addComponent(component)
    self:addChild(sprite)
    sprite:setRotation3D(cc.vec3(0.0, 0.0,  0.0))
    sprite:setPosition3D(vPos)
    component:syncNodeToPhysics()
    rigidBody:setKinematic(true)


    return sprite,rigidBody
end

function GamePusherMainLayer:createFloorMiddleModel(vSize, vPos)

    local rbDes = {}
    rbDes.mass  = 0
    
    local shapeList = {}
    local bodyshape = nil
    local localTrans= nil
    
    bodyshape  = cc.Physics3DShape:createBox(vSize)
    localTrans = cc.mat4.createTranslation(0.0, -9.7 , -8.5 )
    table.insert(shapeList, {bodyshape, localTrans})

    rbDes.shape      = cc.Physics3DShape:createCompoundShape(shapeList)
    local rigidBody  = cc.Physics3DRigidBody:create(rbDes)
    local component  = cc.Physics3DComponent:create(rigidBody)
    local sprite     = cc.Sprite3D:create(  )
    rigidBody:setFriction(Config.PlatformModelAtt.Platform.MiddleFriction)
    sprite:setCameraMask(cc.CameraFlag.USER1)
    sprite:addComponent(component)
    self:addChild(sprite)
    sprite:setRotation3D(cc.vec3(0.0, 0.0,  0.0))
    sprite:setPosition3D(vPos)
    component:syncNodeToPhysics()
    rigidBody:setKinematic(true)

    return sprite, rigidBody
end

-- 创建静态模型 --
function GamePusherMainLayer:createStaticModel(  )
    -- Create machine background Model --
    if Config.PlatformModelAtt.Background then
        local itemAtt   = Config.PlatformModelAtt.Background
        local sprite    = cc.Sprite3D:create( itemAtt.Model )
        sprite:setCameraMask(cc.CameraFlag.USER1)
        self:addChild(sprite)
        sprite:setScale( itemAtt.Scale )
        sprite:setRotation3D(cc.vec3(90.0, 180.0,  0.0))
        sprite:setPosition3D(cc.vec3(0.0, -35.0, 92.0))
        sprite:setTexture(itemAtt.Texture)
    end
    
     -- Create machine Jackpot Model --
     if Config.PlatformModelAtt.Jackpot then
        self._JackpotModel = cc.Sprite3D:create()
        self._JackpotModel:setCameraMask(cc.CameraFlag.USER1)
        self._JackpotModel:setPosition3D(cc.vec3(0.0, 0.0, 0.0))
        self:addChild(self._JackpotModel)

        local itemAtt = Config.PlatformModelAtt.Jackpot
        local sprite = cc.Sprite3D:create(itemAtt.Model)
        sprite:setCameraMask(cc.CameraFlag.USER1)
        self._JackpotModel:addChild(sprite)
        sprite:setScale(itemAtt.Scale)

        sprite:setRotation3D(cc.vec3(0.0, 180.0, 0.0))
        sprite:setPosition3D(cc.vec3(0.0, 0.0, 0.0))

        -- 在3d场景中添加字体显示 目前主要是Freespin 这个控件 --
        self._freeSpinText = util_createAnimation(Config.UICsbPath.BonusSpinCsb)
        self:updataFreeSpinCount("0")
        self._freeSpinText:setCameraMask(cc.CameraFlag.USER1)
        self._freeSpinText:setPosition3D(cc.vec3(0.0, 7.45, -22.5))
        self._freeSpinText:setScale(0.06)
        self._JackpotModel:addChild(self._freeSpinText)
        self._freeSpinText:setVisible(false)

        local sprite3DLine = cc.Sprite3D:create()
        self._JackpotModel:addChild(sprite3DLine)

        local line_1 = util_createSprite("CandyPusher_C3b/xian.png")
        line_1:setPosition3D(cc.vec3(3.65, 0, 0))
        line_1:setScale(0.06)
        sprite3DLine:addChild(line_1)

        local line_2 = util_createSprite("CandyPusher_C3b/xian.png")
        line_2:setPosition3D(cc.vec3(-3.5, 0, 0))
        line_2:setScale(0.06)
        sprite3DLine:addChild(line_2)

        sprite3DLine:setCameraMask(cc.CameraFlag.USER1)
        sprite3DLine:setPosition3D(cc.vec3(0.0, 12, -23.6))
        sprite3DLine:setRotation3D(cc.vec3(0.0, 0.0, 0.0))
    end

    -- Create machine platform --           地板分成5份
    if Config.PlatformModelAtt.Platform then

        -- 底板 单独提出来 设置单独的摩擦力 --
        if true then
            local rbDes = {}
            rbDes.mass  = 0
            
            local shapeList = {}
            local bodyshape = nil
            local localTrans= nil
            
            local cutForntDis = 2 --前方切割的距离
            local cutBackDis = 35 --后方切割的距离

            local foorLeft,rigidBodyLeft = self:createFloorBorderModel(cc.vec3(1.0, 20, 60.0), cc.vec3( -9, 0.0,  0.0))
            local foorRight,rigidBodyRight = self:createFloorBorderModel(cc.vec3(1.0, 20, 60.0), cc.vec3( 9, 0.0,  0.0))
            local floorFornt ,rigidBodyFornt = self:createFloorForntModel(cc.vec3(17.0, 20, cutForntDis), cc.vec3( 0, 0.0,  30 - cutForntDis/2 ))
            local disMiddle =  60 - (cutBackDis + cutForntDis)
            local middlePosZ = 30 - cutForntDis - disMiddle / 2
            local floorMiddle,rigidBodyMiddle = self:createFloorMiddleModel(cc.vec3(17.0, 20, disMiddle), cc.vec3( 0, 0.0,  middlePosZ))
            local floorBack,rigidBodyBack = self:createFloorBackModel(cc.vec3(17.0, 20, cutBackDis), cc.vec3( 0, 0.0,  -cutBackDis/2 + (cutBackDis - 30)))
            rigidBodyBack:setRestitution(Config.BackPushRestitution)
            self._tbFloors = {}
            self._tbFloors[#self._tbFloors + 1] = {foorLeft,rigidBodyLeft}
            self._tbFloors[#self._tbFloors + 1] = {foorRight,rigidBodyRight}
            self._tbFloors[#self._tbFloors + 1] = {floorFornt,rigidBodyFornt}
            self._tbFloors[#self._tbFloors + 1] = {floorMiddle,rigidBodyMiddle}
            self._tbFloors[#self._tbFloors + 1] = {floorBack,rigidBodyBack }

            for i=1,#self._tbFloors do
                      -- 添加碰撞监测函数 --
                local floor = self._tbFloors[i]
                local rigidBody = floor[2]
                self.m_ntbFloorIndex = self.m_ntbFloorIndex + 1
                rigidBody:setMask( self.m_ntbFloorIndex )
                rigidBody:setCollisionCallback(function (collisionInfo)
                    if nil ~= collisionInfo.collisionPointList and #collisionInfo.collisionPointList > 0 then
                        local colAMask = collisionInfo.objA:getMask()
                        local colBMask = collisionInfo.objB:getMask()
                        -- 都需要矫正Mask,因为不一定A/B是金币 --
                        local coinsMask = colBMask
                        if colAMask >= Config.EntityIndex  then
                            coinsMask = colAMask
                        end

                        self:bigCoinCollision( coinsMask )
                        self:smallCoinCollision( coinsMask )
                    end
                end)
            end
        
        end

        -- 其余边栏碰撞体 --
        local itemAtt = Config.PlatformModelAtt.Platform
        local rbDes = {}
        rbDes.mass  = itemAtt.Mass
        local scale = itemAtt.Scale

        local shapeList = {}
        local bodyshape = nil
        local localTrans= nil

        -- -- 左侧栏 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 5.0, 30.0, 11))
        localTrans = cc.mat4.createTranslation( 15.2, -13 , 0 )
        table.insert(shapeList, {bodyshape, localTrans})
        -- 右边栏 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 5.0, 30.0, 11))
        localTrans = cc.mat4.createTranslation( -15.2, -13 , 0 )
        table.insert(shapeList, {bodyshape, localTrans})

        -- 左前 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 0.3, 10.0, 20))
        localTrans = cc.mat4.createRotation(cc.vec3(0.0, 0.0, 1.0), 30.0 * math.pi / 180)
        localTrans[13] = -12
        localTrans[14] = 24
        localTrans[15] = -9.8
        table.insert(shapeList, {bodyshape, localTrans})

     
        -- 右前 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 0.3, 10.0, 20))
        localTrans = cc.mat4.createRotation(cc.vec3(0.0, 0.0, 1.0), -30.0 * math.pi / 180)
        localTrans[13] = 12
        localTrans[14] = 24
        localTrans[15] = -9.8
        table.insert(shapeList, {bodyshape, localTrans})

        -- 左中 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 8.8, 8.0, 20))
        localTrans = cc.mat4.createRotation(cc.vec3(0.0, 0.0, 1.0), 24.0 * math.pi / 180)
        localTrans[13] = -12.2
        localTrans[14] = -3
        localTrans[15] = -7
        table.insert(shapeList, {bodyshape, localTrans})
        -- 右中 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 8.8, 8.0, 20))
        localTrans = cc.mat4.createRotation(cc.vec3(0.0, 0.0, 1.0), -24.0 * math.pi / 180)
        localTrans[13] = 12.2
        localTrans[14] = -3
        localTrans[15] = -7
        table.insert(shapeList, {bodyshape, localTrans})
        -- 左后正板 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 8.5, 20.0, 19.5))
        localTrans = cc.mat4.createTranslation( -10.8, -15 , -7 )
        table.insert(shapeList, {bodyshape, localTrans})
        -- 右后正板 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 8.5, 20.0, 19.5))
        localTrans = cc.mat4.createTranslation( 10.8, -15 , -7 )
        table.insert(shapeList, {bodyshape, localTrans})

        -- 左后斜板 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 10.5, 20.0, 4))
        localTrans = cc.mat4.createRotation(cc.vec3(0.0, 1.0, 0.0), 30.0 * math.pi / 180)
        localTrans[13] = -11.4
        localTrans[14] = -14
        localTrans[15] = 4
        table.insert(shapeList, {bodyshape, localTrans})
        -- 右后斜板 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 10.5, 20.0, 4))
        localTrans = cc.mat4.createRotation(cc.vec3(0.0, 1.0, 0.0), -30.0 * math.pi / 180)
        localTrans[13] = 11.4
        localTrans[14] = -14
        localTrans[15] = 4
        table.insert(shapeList, {bodyshape, localTrans})

        -- 正后正版 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 20, 8.0, 19))
        localTrans = cc.mat4.createTranslation( 0, -20 , -7 )
        table.insert(shapeList, {bodyshape, localTrans})
        -- 正后斜板 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 20, 30.0, 1))
        localTrans = cc.mat4.createRotation(cc.vec3(1.0, 0.0, 0.0), -25.0 * math.pi / 180)
        localTrans[13] = 0
        localTrans[14] = -30
        localTrans[15] = 8.9
        table.insert(shapeList, {bodyshape, localTrans})

        -- 正后最靠后一个板子 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 40, 8.0, 50))
        localTrans = cc.mat4.createTranslation( 0, -20 , -7 )
        localTrans[13] = 0
        localTrans[14] = -26.5
        localTrans[15] = 20
        table.insert(shapeList, {bodyshape, localTrans})

        -- 创建一个空模型承载这些碰撞体 --
        rbDes.shape      = cc.Physics3DShape:createCompoundShape(shapeList)
        local rigidBody  = cc.Physics3DRigidBody:create(rbDes)
        local component  = cc.Physics3DComponent:create(rigidBody)
        local sprite     = cc.Sprite3D:create(  )
        rigidBody:setFriction( 0 )
        sprite:setCameraMask(cc.CameraFlag.USER1)
        sprite:addComponent(component)
        self:addChild(sprite)
        sprite:setRotation3D( cc.vec3(-90.0, 180.0,  0.0))
        sprite:setPosition3D( cc.vec3(0.0, 0.0,  1.0) )
        component:syncNodeToPhysics()

        local spriteModel   = cc.Sprite3D:create( itemAtt.Model )
        spriteModel:setCameraMask(cc.CameraFlag.USER1)
        self:addChild(spriteModel)
        spriteModel:setScale( itemAtt.Scale )
        spriteModel:setRotation3D(cc.vec3(0.0, 180.0,  0.0))
        spriteModel:setPosition3D(cc.vec3(0.0, 0.0, 0.0))  
        spriteModel:setTexture(itemAtt.Texture)   
        self.m_ntbFloorIndex = self.m_ntbFloorIndex + 1
        rigidBody:setMask( self.m_ntbFloorIndex )
        rigidBody:setCollisionCallback(function (collisionInfo)
            if nil ~= collisionInfo.collisionPointList and #collisionInfo.collisionPointList > 0 then

                local colAMask = collisionInfo.objA:getMask()
                local colBMask = collisionInfo.objB:getMask()
                -- 都需要矫正Mask,因为不一定A/B是金币 --
                local coinsMask = colBMask
                if colAMask >= Config.EntityIndex  then
                    coinsMask = colAMask
                end
                self:smallCoinCollision( coinsMask )
            end
        end)
    end
    
    -- Create machine pusher --
    if Config.PlatformModelAtt.Pusher then

        self.m_pSp3DPusher = self:createPusher(cc.vec3(14.0, 3.5, 40.0))
        self.m_pSp3DPusherBig = self:createPusher(cc.vec3(24.0, 35, 40.0))

        self.m_pSp3DPusherBig:setPositionY(-1000)

        self.m_v3PusherPosOri  = Config.PusherPosVec3
        self.m_nPusherStatus   = Config.PusherStatus.Idle
        self.m_nPusherSpeed    = Config.PusherSpeed
        self:setPusherRunning( true )
        self:setPusherPosDestPos( Config.PusherDisVec3.ORI )

    end

    -- 创建侧边升降台 有buff的时候上升，阻挡金币侧漏 --
    if Config.PlatformModelAtt.Lifter then
        local itemAtt = Config.PlatformModelAtt.Lifter
        local rbDes = {}
        rbDes.mass  = itemAtt.Mass
        local scale = itemAtt.Scale

        local shapeList = {}
        local bodyshape = nil
        local localTrans= nil

        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 3 , 22 , 10.0))
        localTrans = cc.mat4.createTranslation( -11.0 , 10 , -24.5)
        table.insert(shapeList, {bodyshape, localTrans})
        rbDes.shape = cc.Physics3DShape:createCompoundShape(shapeList)

        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 5, 5 , 10.0))
        localTrans = cc.mat4.createRotation(cc.vec3(0.0, 0.0, 1.0), 30.0 * math.pi / 180)
        localTrans[13] = -13
        localTrans[14] = 22
        localTrans[15] = -24.5
        table.insert(shapeList, {bodyshape, localTrans})

        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 3 , 22 , 10.0))
        localTrans = cc.mat4.createTranslation( 11.0, 10 , -24.5)
        table.insert(shapeList, {bodyshape, localTrans})

        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 5, 5, 10.0))
        localTrans = cc.mat4.createRotation(cc.vec3(0.0, 0.0, 1.0), -30.0 * math.pi / 180)
        localTrans[13] = 13
        localTrans[14] = 22
        localTrans[15] = -24.5
        table.insert(shapeList, {bodyshape, localTrans})

        rbDes.shape = cc.Physics3DShape:createCompoundShape(shapeList)

        local sprite = cc.PhysicsSprite3D:create( itemAtt.Model , rbDes )
        sprite:setCameraMask(cc.CameraFlag.USER1)


        local rigidBody = sprite:getPhysicsObj()
        rigidBody:setFriction( 0 )
        
        self:addChild(sprite)
        sprite:setScale( itemAtt.Scale )


        self.m_v3LifterPosOri = cc.vec3(0.0, 0.0, 0 )
        self.m_v3LifterPosDest= cc.vec3(0.0, 22.7, 0 )
        self.m_nLifterStatus = 1
        self.m_nLifterSpeed  = 66

        sprite:setRotation3D(cc.vec3(-90.0, 180.0,  0.0))
        sprite:setPosition3D( self.m_v3LifterPosOri )

        self.m_pSp3DLifter     = sprite
        self.m_pSp3DLifter:setVisible(false)
    end

    -- 创建掉落监测实体 ( 没有中奖的平板 )--  底部特别大刚体板子
    if true then
        local rbDes = {}
        rbDes.mass  = 0

        local shapeList  = {}
        local bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 500.0, 3.5, 500.0) )
        local localTrans = cc.mat4.createTranslation(0.0, -20, 0 )
        table.insert(shapeList, {bodyshape, localTrans})
        rbDes.shape      = cc.Physics3DShape:createCompoundShape(shapeList)
        local rigidBody  = cc.Physics3DRigidBody:create(rbDes)
        local component  = cc.Physics3DComponent:create(rigidBody)
        local sprite     = cc.Sprite3D:create(  )

        sprite:setCameraMask(cc.CameraFlag.USER1)
        sprite:addComponent(component)
        self:addChild(sprite)

        sprite:setRotation3D( cc.vec3(0.0, 0.0,  0.0))
        sprite:setPosition3D( cc.vec3(0.0, 0.0,  0.0) )
        component:syncNodeToPhysics()

        self.m_ntbFloorIndex = self.m_ntbFloorIndex + 1
        rigidBody:setMask( self.m_ntbFloorIndex )
        -- 添加碰撞监测函数 --
        rigidBody:setCollisionCallback(function (collisionInfo)
            if nil ~= collisionInfo.collisionPointList and #collisionInfo.collisionPointList > 0 then

                local colAMask = collisionInfo.objA:getMask()
                local colBMask = collisionInfo.objB:getMask()
                -- 都需要矫正Mask,因为不一定A/B是金币 --
                local coinsMask = colBMask
                if colAMask >= Config.EntityIndex  then
                    coinsMask = colAMask
                end

                self:itemDropped( Config.EntityDropType.LOSE, coinsMask )
            end
        end)
    end

    -- 创建掉落监测实体 （ 中奖的平板组 ）--     台子前方底部三个掉落检测板子
    if true then
        local rbDes = {}
        rbDes.mass  = 0
        local shapeList = {}
        local bodyshape = nil
        local localTrans= nil
        -- 底盘 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3(18.0, 3.5, 40))
        localTrans = cc.mat4.createTranslation(0.0, -15 , 30 )
        table.insert(shapeList, {bodyshape, localTrans})
        -- -- 左侧栏 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 18.0, 3.5, 40))
        localTrans = cc.mat4.createRotation(cc.vec3(0.0, 1.0, 0.0), -30.0 * math.pi / 180)
        localTrans[13] = -6
        localTrans[14] = -15
        localTrans[15] = 33
        table.insert(shapeList, {bodyshape, localTrans})
        -- 右边栏 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 18.0, 3.5, 40))
        localTrans = cc.mat4.createRotation(cc.vec3(0.0, 1.0, 0.0), 30.0 * math.pi / 180)
        localTrans[13] = 6
        localTrans[14] = -15
        localTrans[15] = 33
        table.insert(shapeList, {bodyshape, localTrans})

        rbDes.shape      = cc.Physics3DShape:createCompoundShape(shapeList)
        local rigidBody  = cc.Physics3DRigidBody:create(rbDes)
        local component  = cc.Physics3DComponent:create(rigidBody)
        local sprite     = cc.Sprite3D:create(  )

        sprite:setCameraMask(cc.CameraFlag.USER1)
        sprite:addComponent(component)
        self:addChild(sprite)

        sprite:setRotation3D( cc.vec3(0.0, 0.0,  0.0))
        sprite:setPosition3D( cc.vec3(0.0, 0.0,  0.0) )
        component:syncNodeToPhysics()

        self.m_ntbFloorIndex = self.m_ntbFloorIndex + 1
        rigidBody:setMask( self.m_ntbFloorIndex )
        -- 添加碰撞监测函数 --
        rigidBody:setCollisionCallback(function (collisionInfo)
            if nil ~= collisionInfo.collisionPointList and #collisionInfo.collisionPointList > 0 then

                local colAMask = collisionInfo.objA:getMask()
                local colBMask = collisionInfo.objB:getMask()
                -- 都需要矫正Mask,因为不一定A/B是金币 --
                local coinsMask = colBMask
                if colAMask >= Config.EntityIndex  then
                    coinsMask = colAMask
                end
                
                self:itemDropped( Config.EntityDropType.WIN , coinsMask )
            end
        end)

    end 

    -- 创建一个空节点 承载所有动态实体(Coin&Item) --
    if true then
        self.m_sp3DEntityRoot = cc.Sprite3D:create( )
        self.m_sp3DEntityRoot:setCameraMask(cc.CameraFlag.USER1)
        self:addChild(self.m_sp3DEntityRoot)
        self.m_sp3DEntityRoot:setPosition( cc.vec3(0,0,0) )
    end
end

function GamePusherMainLayer:createPusher( _boxInfo )
    

    local itemAtt = Config.PlatformModelAtt.Pusher
    local rbDes = {}
    rbDes.mass  = itemAtt.Mass
    local scale = itemAtt.Scale

    local shapeList = {}

    local bodyshape  = cc.Physics3DShape:createBox(_boxInfo)
    local localTrans = cc.mat4.createTranslation(0.0, 0.0, 24 )
    table.insert(shapeList, {bodyshape, localTrans})
    rbDes.shape = cc.Physics3DShape:createCompoundShape(shapeList)

    local sp3DPusher = cc.PhysicsSprite3D:create( itemAtt.Model , rbDes )
    sp3DPusher:setCameraMask(cc.CameraFlag.USER1)
    sp3DPusher:setTexture(itemAtt.Texture)
    local rigidBody = sp3DPusher:getPhysicsObj()
    rigidBody:setKinematic(true)
    rigidBody:setFriction( 0.8 )
    rigidBody:setRestitution(Config.BackPushRestitution)
    

    self:addChild(sp3DPusher)
    sp3DPusher:setScale( itemAtt.Scale )
    sp3DPusher:setRotation3D(cc.vec3(0.0, 180.0,  0.0))
    sp3DPusher:setPosition3D(Config.PusherPosVec3)

    self.m_nPusherIndex = self.m_nPusherIndex + 1
    rigidBody:setMask( self.m_nPusherIndex )

    rigidBody:setCollisionCallback(function (collisionInfo)
        if nil ~= collisionInfo.collisionPointList and #collisionInfo.collisionPointList > 0 then
            local colAMask = collisionInfo.objA:getMask()
            local colBMask = collisionInfo.objB:getMask()
            -- 都需要矫正Mask,因为不一定A/B是金币 --
            local coinsMask = colBMask
            if colAMask >= Config.EntityIndex  then
                coinsMask = colAMask
            end
            self:smallCoinCollision( coinsMask )
        end
    end)

    return sp3DPusher

end

----------------------------------------------------------------------------------------
-- 推币机碰撞触发事件
----------------------------------------------------------------------------------------
--桌面碰撞
function GamePusherMainLayer:bigCoinCollision( nItemIndex )
    local colNode = self.m_tEntityList[nItemIndex]
    if colNode and  not colNode.Collision then
        if colNode.ID == Config.CoinModelAtt.BIG.Name then
            colNode.Collision = true
            --大金币掉落下来 震动一下
            self:itemsQuake( 10 )
            self:CameraQuake()  
        end
    end
end

function GamePusherMainLayer:smallCoinCollision( nItemIndex )
    local colNode = self.m_tEntityList[nItemIndex]
    if colNode and  not colNode.Collision then
        if colNode.ID == Config.CoinModelAtt.NORMAL.Name then
            colNode.Collision = true
            --音效
            self:playSound(Config.SoundConfig.COIN_PUSH_DOWN)
            --小金币掉落下来碰撞
        end
    end
end


-- 道具掉落处理 --
function GamePusherMainLayer:itemDropped( sWinType , nItemIndex )

    if not self.m_bOutLinePlayStates then
        return
    end

    if self.m_bPusherOver then
        --推币机是结束状态掉掉币也不生效
        return
    end

    local colNode = self.m_tEntityList[nItemIndex]
    if colNode ~= nil then
        local sType = colNode.Type
        local nID   = colNode.ID
        local vPos  = colNode.Node:getPosition3D()
        local vPos2d = self:Convert3DToGL2D(vPos)

        -- Remove Render Node --
        colNode.Node:setVisible(false)
        -- self.m_pPhysicsWorld:removePhysics3DObject(colNode.Node:getPhysicsObj())          
        self.m_tEntityList[nItemIndex] = nil
        
        --存档一次
        self:saveEntityData()

        self:delayCallFunc(function()
            if not tolua.isnull(colNode.Node) then
                colNode.Node:removeFromParent()
            end
        end,0.1)


        if sWinType == Config.EntityDropType.WIN then

            self.m_pGamePusherMgr:dropFromTable(nID)

            if not  self.m_tWinData[nID] then
                self.m_tWinData[nID] = 1
            else
                self.m_tWinData[nID] = self.m_tWinData[nID] + 1
            end


            if nID == Config.CoinModelRefer.SLOTS then
                self:playNormalCoinDropEffect( Config.CollectCoinsProgress.SLOTS,vPos2d,nID)
            else
                
                if nID == Config.CoinModelRefer.BIG  then
                    self:playNormalCoinDropEffect( Config.CollectCoinsProgress.BIG,vPos2d,nID)
                else
                    self:playNormalCoinDropEffect( Config.CollectCoinsProgress.NORMAL,vPos2d,nID)
                end
                
            end
            
            self.m_pMainUI:playCoinWinDropEffect(cc.p(vPos2d.x, 0), nID)


            if sType == Config.EntityType.COIN then
                self.m_tEntityDropped.CoinWin[nID] = self.m_tEntityDropped.CoinWin[nID] or 0
                self.m_tEntityDropped.CoinWin[nID] = self.m_tEntityDropped.CoinWin[nID] + 1
            end
            self.m_nEntityWin = self.m_nEntityWin + 1
 
        elseif sWinType == Config.EntityDropType.LOSE then
            if not  self.m_tLoseData[nID] then
                self.m_tLoseData[nID] = 1
            else
                self.m_tLoseData[nID] = self.m_tLoseData[nID] + 1
            end
            if sType == Config.EntityType.COIN then
                self.m_tEntityDropped.CoinLose[nID] = self.m_tEntityDropped.CoinLose[nID] or 0
                self.m_tEntityDropped.CoinLose[nID] = self.m_tEntityDropped.CoinLose[nID] + 1
            end
            self.m_nEntityLose = self.m_nEntityLose + 1


            local dropCoinNumData = 0
            local pushersData = self.m_pGamePusherMgr:getPusherUseData() or {} 
            if pushersData and table_length(pushersData) ~= 0 then
                if pushersData.dropCoinNum  then
                    dropCoinNumData = pushersData.dropCoinNum
                end
            end
        
            if dropCoinNumData then
                dropCoinNumData = dropCoinNumData + Config.CollectCoinsProgress[nID]
            end

            
            local data = {}
            data.dropCoinNum = dropCoinNumData
            self.m_pGamePusherMgr:updatePlayingData( data )

            
        end
    end
end

function GamePusherMainLayer:updataSendDropMsg(dt)

   if globalData.slotRunData.gameRunPause then

        if self.m_nSendDt then
            self.m_nSendDt = nil
        end

       return
   end

    if self.m_bPusherOver then
        
        return 
    end
    

    -- self.m_tLoseData 本次掉落在无效区域的金币信息
    --self.m_tWinData 本次掉落在有效区域的金币信息 
    if table.nums(self.m_tLoseData) == 0 and table.nums(self.m_tWinData) == 0 then

        if self.m_nSendDt == nil then

            if self.m_pGamePusherMgr:checkPusherPropUseUp( ) and 
                self.m_pGamePusherMgr:checkPlayEffectOver( ) then 

                self.m_nSendDt = 0
            end

            
        end
        
    else
        
        gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateOverTimes,{nSendDt = 0}) 

        self.m_nSendDt = nil
        
        self.m_tLoseData = {}
        self.m_tWinData = {}
        
    end
    
    if self.m_nSendDt then

        gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateOverTimes,{nSendDt = math.floor(self.m_nSendDt) }) 

        if self.m_nSendDt > Config.OverTimes then
            
            self:sendDropMsg()
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateOverTimes,{nSendDt = 0}) 
            self.m_nSendDt = nil

        else
            self.m_nSendDt = self.m_nSendDt + dt
        end
    end

    
end

-- 向服务器发送结束信息
function GamePusherMainLayer:sendDropMsg()

    -- 发送结束消息
    self.m_pGamePusherMgr:requestBonusPusherOverNetData()

end

----------------------------------------------------------------------------------------
-- 推币机Action 升降台  底板震动  道具震动
----------------------------------------------------------------------------------------
-- 推币机 动作逻辑 --
function GamePusherMainLayer:pusherTick( _nDt )
    if self.m_nPusherStatus == Config.PusherStatus.Idle then
        -- IDLE --
        if self.m_bPusherPushing == true then
            self.m_nPusherStatus =  Config.PusherStatus.Push
        end
    elseif self.m_nPusherStatus == Config.PusherStatus.Push then
        -- Push --
        local curPos = self.m_pSp3DPusher:getPosition3D()
        local curPosBig = self.m_pSp3DPusherBig:getPosition3D()
        curPos.z = curPos.z + self.m_nPusherSpeed * _nDt
        if curPos.z > self.m_v3PusherPosDest.z then
            curPos.z = self.m_v3PusherPosDest.z
            self.m_nPusherStatus = Config.PusherStatus.Pull
        end
        
        self.m_pSp3DPusher:setPosition3D( curPos )
        self.m_pSp3DPusherBig:setPosition3D( cc.vec3(curPosBig.x, curPosBig.y, curPos.z)  )
    elseif self.m_nPusherStatus == Config.PusherStatus.Pull then
        -- Pull --
        local curPos = self.m_pSp3DPusher:getPosition3D()
        local curPosBig = self.m_pSp3DPusherBig:getPosition3D()
        curPos.z = curPos.z - self.m_nPusherSpeed * _nDt
        if curPos.z < self.m_v3PusherPosOri.z then
            curPos.z = self.m_v3PusherPosOri.z
            self.m_nPusherStatus = Config.PusherStatus.Idle
        end
        self.m_pSp3DPusher:setPosition3D( curPos )
        self.m_pSp3DPusherBig:setPosition3D( cc.vec3(curPosBig.x, curPosBig.y, curPos.z) )
    end
end

-- 设置推币机是否动作 --
function GamePusherMainLayer:setPusherRunning( bRunning )
    self.m_bPusherPushing = bRunning
end

-- 升降台重置位置
function GamePusherMainLayer:restLifter( )
    self.m_bLifterUp = false 
    self.m_nLifterStatus = 1
    self.m_pSp3DLifter:setPosition3D( self.m_v3LifterPosOri )
    self.m_pSp3DLifter:setVisible(false)
end

-- 升降台 动作逻辑 --
function GamePusherMainLayer:lifterTick( dt )
    if self.m_nLifterStatus == 1 then
        -- IDLE --
    elseif self.m_nLifterStatus == 2 then

        self.m_pSp3DLifter:setVisible(true)

        -- Move Up --
        local curPos = self.m_pSp3DLifter:getPosition3D()
        curPos.y     = curPos.y + self.m_nLifterSpeed * dt
        if curPos.y > self.m_v3LifterPosDest.y  then
            curPos.y= self.m_v3LifterPosDest.y
            self.m_nLifterStatus = 1
        end
        self.m_pSp3DLifter:setPosition3D( curPos )
    elseif self.m_nLifterStatus == 3 then
        -- Move Down --
        local curPos = self.m_pSp3DLifter:getPosition3D()
        curPos.y = curPos.y - self.m_nLifterSpeed * dt
        if curPos.y < self.m_v3LifterPosOri.y then
            curPos.y = self.m_v3LifterPosOri.y
            self.m_nLifterStatus = 1
            self.m_pSp3DLifter:setVisible(false)
        end
        self.m_pSp3DLifter:setPosition3D( curPos )
    end
end

-- 设置升降台状态 --
function GamePusherMainLayer:setLifterStatus( nStatus )
    self.m_nLifterStatus = nStatus
end

function GamePusherMainLayer:getLifterStatus()
    return self.m_nLifterStatus
end

function GamePusherMainLayer:setPusherPosDestPos( vec3 )
    self.m_v3PusherPosDest = vec3
end

function GamePusherMainLayer:getPusherPosDestPos()
    return self.m_v3PusherPosDest
end

-- 设置推币台状态状态 --
function GamePusherMainLayer:setm_nPusherStatus( nStatus )
    self.m_nPusherStatus = nStatus
end

-- 初始化Pusher数据 --
function GamePusherMainLayer:resetPusherAtt( vPos  )
    local curPosBig = self.m_pSp3DPusherBig:getPosition3D()
    self.m_pSp3DPusher:setPosition3D( vPos )
    self.m_pSp3DPusherBig:setPosition3D( cc.vec3(curPosBig.x, curPosBig.y, vPos.z) )
    self.m_nPusherStatus = Config.PusherStatus.Idle
    self:setPusherRunning( true )
end

-- 底板震动效果 --
function GamePusherMainLayer:floorQuake(  )
    for i=1,#self._tbFloors do
        local sprite3D = self._tbFloors[i][1]
        local actions   = {}
        local move_up   = cc.MoveBy:create( 0.05 , cc.vec3( 0, 2 ,0 ) )
        actions[#actions + 1] = move_up
        local move_back = cc.MoveBy:create( 0.05 , cc.vec3( 0, -2 , 0)  )
        actions[#actions + 1] = move_back
    
        local seq = cc.Sequence:create( actions )
        sprite3D:runAction(seq)
    end

end

-- 道具振起效果 --
function GamePusherMainLayer:itemsQuake( fForce )

    gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_TableShake.mp3")

    for k,entity in pairs( self.m_tEntityList ) do
        
        if not tolua.isnull( entity.Node ) then
            local rigidBody = entity.Node:getPhysicsObj()
            rigidBody:setActive( true )
            rigidBody:setLinearVelocity(  cc.vec3( math.random(-2,2),math.random(5,fForce),math.random(0,2) ) )
            rigidBody:setAngularVelocity( cc.vec3( math.random(0,5), math.random(0,5), math.random(0,5) ))
        end
    end
end

-- 倒数第二次时新出现的金币堆流程 --
function GamePusherMainLayer:playSuperBonusCoinsDown(_func  )

    gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_superBonusInitCoinsDown.mp3") 

    local moveTime_1 = 1.5
    local moveTime_2 = 0.1
    local moveTime_3 = 0.1
    local moveTime_4 = 0.1

    for k,entity in pairs( self.m_tEntityList ) do
        
        if not tolua.isnull( entity.Node ) then
            local sprite =  entity.Node 
            local Pos = sprite:getPosition3D()
            local vPos  = cc.vec3(Pos.x , Pos.y + 25 , Pos.z ) 
            sprite:setPosition3D(vPos)
            local actList = {}
            actList[#actList + 1] = cc.EaseIn:create(cc.MoveTo:create(moveTime_1,cc.vec3(Pos.x , Pos.y , Pos.z)),3)
            actList[#actList + 1] = cc.EaseOut:create(cc.MoveTo:create(moveTime_2,cc.vec3(Pos.x , Pos.y + 0.15 , Pos.z)),3)
            actList[#actList + 1] = cc.EaseIn:create(cc.MoveTo:create(moveTime_3,cc.vec3(Pos.x , Pos.y  , Pos.z )),3)
            local sq = cc.Sequence:create(actList)
            sprite:runAction(sq)
        end
    end

    self:delayCallFunc( function(  )
        self:CameraQuakeMax()
    end,moveTime_1 )

    self:delayCallFunc( function(  )

        if _func then
            _func()
        end

    end,(moveTime_1 + moveTime_2 + moveTime_3 + moveTime_4))
end

-- buff检测
function GamePusherMainLayer:updateBuffState(_nDt)

    self.m_nBuffUpdataTime = self.m_nBuffUpdataTime + _nDt

    if self.m_nBuffUpdataTime < Config.BuffUpdateTime then
        return 
    end

    local upWallsLT = self.m_pGamePusherMgr:getBuffUpWallsLT()

    if upWallsLT and upWallsLT > 0 then

        
        if not self.m_bLifterUp then

            if self:getLifterStatus() == 1 then

                self.m_WallsLeftTimes = upWallsLT
                self:setLifterStatus(2)
                self:playSound(Config.SoundConfig.WallUp)
                self:updateWallBar( )

            end
            self.m_bLifterUp = true

        end

        if self.m_WallsLeftTimes then

            if upWallsLT ~= self.m_WallsLeftTimes then
                -- 时间不一致说明购买道具了更新为最新时间
                self.m_WallsLeftTimes = upWallsLT
            end

            self.m_WallsLeftTimes = self.m_WallsLeftTimes - _nDt
            self.m_pGamePusherMgr:setPusherUpWalls( self.m_WallsLeftTimes,true )
            if self.m_WallsLeftTimes <= 0 then
                self.m_WallsLeftTimes = 0
            end
            self:updateWallBar( )
            
        end
     
    else

        self.m_WallsLeftTimes = nil

        if self.m_bLifterUp then
            if self:getLifterStatus() == 1 then

                self.m_pMainUI.m_wallBar:setVisible(false)

                self:setLifterStatus(3)
            end  
            self.m_bLifterUp = false 
        end
    end


    self.m_nBuffUpdataTime = 0
    self.m_pMainUI:setBuffState(upWallsLT > 0 )

end

function GamePusherMainLayer:updateWallBar( )
    self.m_pMainUI.m_wallBar:setVisible(true)
    local currTime = self.m_WallsLeftTimes
    local totalTime = self.m_pGamePusherMgr:getMaxWallTime( )
    self.m_pMainUI.m_wallBar:updateBarPercent(currTime,totalTime )
end

function GamePusherMainLayer:hideLifter( )
    -- Move Down --
    local curPos = self.m_pSp3DLifter:getPosition3D()
    curPos.y = self.m_v3LifterPosOri.y
    self.m_nLifterStatus = 1
    self.m_pSp3DLifter:setVisible(false)
    self.m_pSp3DLifter:setPosition3D( curPos )
    self.m_bLifterUp = false 
    self.m_pMainUI.m_wallBar:setVisible(false)
    self.m_WallsLeftTimes = nil
end

-- 初始化两边台子 
function GamePusherMainLayer:initLifterStatus()
    local upWallsLT = self.m_pGamePusherMgr:getBuffUpWallsLT()
    if upWallsLT and upWallsLT > 0 then
        if not self.m_bLifterUp then
            if self:getLifterStatus() == 1 then
                -- self:setLifterStatus(2)
                local curPos = self.m_pSp3DLifter:getPosition3D()
                curPos.y= self.m_v3LifterPosDest.y
                self.m_pSp3DLifter:setPosition3D( curPos )
            end
            -- self.m_bLifterUp = true
        end
     
    else
        if self.m_bLifterUp then
            if self:getLifterStatus() == 1 then
                self:setLifterStatus(3)
                local curPos = self.m_pSp3DLifter:getPosition3D()
                curPos.y= self.m_v3LifterPosOri.y
                self.m_pSp3DLifter:setPosition3D( curPos )
            end  
            self.m_bLifterUp = false 
        end
    end
end

-- tap动画
function GamePusherMainLayer:updateTapState(_nDt)
    if self.m_bTapUpdateState then
        if self.m_nTapUpdateTime >= Config.TapUpdateTime then
            self:PlayEffect( Config.Effect.TapHere.ID )
            self.m_nTapUpdateTime = Config.TapUpdateTime
        else
            self.m_nTapUpdateTime =  self.m_nTapUpdateTime  + _nDt
        end
    else
        self.m_pEffectRoot:stopTaphereEffect()
    end
end


-------------------------------------------------- Slot Function S------------------------------------------------
-- Init reel table --
function GamePusherMainLayer:InitReelTable()
    -- 创建根结点 --
    self._reelTable = cc.Sprite3D:create()
    self._reelTable:setCameraMask(cc.CameraFlag.USER1)

    -- 暂 将 ReelTable 添 加 到 Jackpot 节 点 上，便 于 同 时 移 动 ，Holyshit --
    self._JackpotModel:addChild(self._reelTable)
    self._reelTable:setPosition3D(Config.ReelTableCenter)

    -- 创建3个轴根结点 --
    self._reelUnitsRoot = {}
    for i = 1, 3 do
        self._reelUnitsRoot[i] = cc.Sprite3D:create()
        self._reelUnitsRoot[i]:setCameraMask(cc.CameraFlag.USER1)
        self._reelTable:addChild(self._reelUnitsRoot[i])
        self._reelUnitsRoot[i]:setPosition3D(Config.ReelUnitCenter[i])
    end

    -- 滚轴指针 暂且随机一个值 --
    self._indexPointer = Config.ReelDataIndexPointer
    
    -- 滚轴信号块管理器 --
    self._reelUnits = {
        {Status = 0, Nodes = {}, Dest = nil},
        {Status = 0, Nodes = {}, Dest = nil},
        {Status = 0, Nodes = {}, Dest = nil}
    }
    -- 初始化滚轴模型 --
    for i, v in ipairs(Config.ReelUnitConfig) do
        for j, w in ipairs(v) do
            local symbolID = Config.ReelDataConfig[i][self._indexPointer[i]]
            local symbol = self:createSymbol(symbolID, w)
            symbol._symbolID = symbolID
            symbol._nodeTag = j
            self._reelUnitsRoot[i]:addChild(symbol)
            self._reelUnits[i].Nodes[j] = symbol

            self._indexPointer[i] = self._indexPointer[i] + 1
            if self._indexPointer[i] > Config.ReelDataNums[i] then
                self._indexPointer[i] = 1
            end
        end
    end
    -- 重制数据 --
    self:resetReelDestData()


end


-- Create symbol --
function GamePusherMainLayer:createSymbol(_nSymbolID, _pPos)
    
    local itemAtt = Config.PlatformModelAtt.ReelUnit
    local sprite = cc.Sprite3D:create()
    local spSymbol = self:createCsbSymbol(_nSymbolID)
    spSymbol:setTag(10)
    sprite:addChild(spSymbol)
    sprite:setCameraMask(cc.CameraFlag.USER1)
    sprite:setRotation3D(cc.vec3(0, 0.0, 0.0))
    sprite:setPosition3D(_pPos)
    return sprite
end

function GamePusherMainLayer:createCsbSymbol(_nSymbolID)
    local symbolAtt = Config.SymbolRes[_nSymbolID]
    local spSymbol
    if symbolAtt.isSpine then
        spSymbol = util_spineCreate(symbolAtt.Path,true,true)
    else
        spSymbol = util_createAnimation(symbolAtt.Path)  
    end
    spSymbol:setScale(0.05)
    
    return spSymbol
end

function GamePusherMainLayer:replaceCsbSymbol(_sp3D, _nSymbolID)
    local csbNode = _sp3D:getChildByTag(10)
    csbNode:removeFromParent()
    local spSymbol = self:createCsbSymbol(_nSymbolID)
    spSymbol:setCameraMask(cc.CameraFlag.USER1)
    spSymbol:setTag(10)
    _sp3D:addChild(spSymbol)
end

function GamePusherMainLayer:getSymbolAnimaNode(_sp3D)
    local csbNode = _sp3D:getChildByTag(10)
    return csbNode
end

-- reset Reel runtime Data --
function GamePusherMainLayer:resetReelDestData()
    self._destPointer = {-1, -1, -1}
    self._destData = {}
    self._reelJumpDatas = {}

    for i = 1, 3 do
        self._reelUnits[i].Status = Config.ReelStatus.Idle
        self._reelUnits[i].Dest = nil
    end
end
-- Set Reel Stop Data --
function GamePusherMainLayer:setReelData(lData)
    self._destData = lData
    for i = 1, 3 do
        self._destPointer[i] = self._indexPointer[i] + Config.ReelStopOffset[i]
        if self._destPointer[i] > Config.ReelDataNums[i] then
            self._destPointer[i] = self._destPointer[i] - Config.ReelDataNums[i]
        end
    end
end

function GamePusherMainLayer:stopRoll(lData)
    for i = 1, 3 do
        if self._reelUnits[i].Status > Config.ReelStatus.Running then
            print("The ree is not running now :" .. i)
            return
        end
    end

    self:setReelData(lData)
end

function GamePusherMainLayer:startRoll()
    for i = 1, 3 do
        if self._reelUnits[i].Status ~= Config.ReelStatus.Idle then
            print("The reel is running now :" .. i)
            return
        end
    end

    self:resetReelDestData()
    for i = 1, 3 do
        self._reelUnits[i].Status = Config.ReelStatus.JumpUp
        self._reelJumpDatas[i] = {DelayTime = 0, PosY = 0}
    end
end
function GamePusherMainLayer:reelStopped(nReelIndex)
    self._reelUnits[nReelIndex].Status = Config.ReelStatus.Idle
    gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_ClassicReelStop.mp3")
    if nReelIndex == 3 then
        --播放动画
        self:runSlotEnd()
    end
end
-- Reel Tick --
function GamePusherMainLayer:reelTick(dt)
    for i, w in ipairs(self._reelUnits) do

        if w.Status == Config.ReelStatus.JumpUp then

            for k, v in pairs(w.Nodes) do
                local action = v:getActionByTag(110)
                if action == nil then
                    local curPos = v:getPosition3D()
                    local endPos = curPos
                    if curPos.y ~= 0 then
                        v:setVisible(false)
                    end
                    endPos.y = endPos.y + Config.ReelJumpConfig[i].DestPosY

                    local speedActionTable = {}
                    local delayAct = cc.DelayTime:create(Config.ReelJumpConfig[i].DelayTime)
                    local moveTime = Config.ReelJumpUpTime
                    local moveAct = cc.EaseSineOut:create(cc.MoveTo:create(moveTime, endPos))
                    local callBackAct =
                        cc.CallFunc:create(
                        function()
                            if w.Status ~= Config.ReelStatus.Running then
                                w.Status = Config.ReelStatus.Running
                            end
                        end
                    )
                    local seqAct = cc.Sequence:create(delayAct, moveAct, callBackAct)
                    seqAct:setTag(110)
                    v:runAction(seqAct)
                end
            end
        elseif w.Status == Config.ReelStatus.Running then
            
            -- 计算步进 --
            local moveStep = Config.ReelRollSpeed * dt

            -- 如果已经存在目标点 --
            if w.Dest ~= nil then
                local curPos = w.Dest:getPosition3D()
                if curPos.y + moveStep < Config.ReelStopPos then
                    moveStep = -curPos.y + Config.ReelStopPos
                    -- 这里可以设置Reel进入JumpDown状态了 --
                    w.Status = Config.ReelStatus.JumpDown
                end
            end

            for k, v in pairs(w.Nodes) do
                -- 计算步进 --
                local curPos = v:getPosition3D()
                curPos.y = curPos.y + moveStep

                -- 计算下边界 --
                if curPos.y < Config.ReelBottomPos then
                    -- 重制位置 --
                    local moveOff = curPos.y - Config.ReelBottomPos
                    curPos.y = Config.ReelTopPos + moveOff

                    -- 重制纹理 --
                    local symbolID = Config.ReelDataConfig[i][self._indexPointer[i]]

                    -- 如果出现目标点 --
                    if self._destPointer[i] == self._indexPointer[i] then
                        symbolID = tonumber(self._destData[i])
                        w.Dest = v
                    end

                    local symbolAtt = Config.SymbolRes[symbolID]
                    self:replaceCsbSymbol(v, symbolID)
                    v._symbolID = symbolID

                    -- 索引++ --
                    self._indexPointer[i] = self._indexPointer[i] + 1
                    if self._indexPointer[i] > Config.ReelDataNums[i] then
                        self._indexPointer[i] = 1
                    end
                elseif curPos.y < Config.ReelTopPos then
                    v:setVisible(true)
                end
                -- 设置最终位置 --
                v:setPosition3D(curPos)
            end

            -- 如果从Running状态下进入JumpDown 塞点儿代码 --
            if w.Status == Config.ReelStatus.JumpDown then
                for k, v in pairs(w.Nodes) do
                    -- 此处塞点矫正代码 把除了目标信号块的另一个信号块 重制位置 主要是为了把下方镂空腾出来 --
                    if w.Dest ~= v then
                        local curPos = v:getPosition3D()
                        curPos.y = Config.ReelTopPos

                        local symbolID = Config.ReelDataConfig[i][self._indexPointer[i]]
                        local symbolAtt = Config.SymbolRes[symbolID]
                        self:replaceCsbSymbol(v, symbolID)
                        v._symbolID = symbolID

                        -- 索引++ --
                        self._indexPointer[i] = self._indexPointer[i] + 1
                        if self._indexPointer[i] > Config.ReelDataNums[i] then
                            self._indexPointer[i] = 1
                        end
                        -- 设置最终位置 --
                        v:setPosition3D(curPos)
                    end
                end

                local speedActionTable = {}
                local dis = 0.7
                local speedStart = -Config.ReelRollSpeed
                local preSpeed = speedStart / 118
                for i = 1, 10 do
                    speedStart = speedStart - preSpeed * (11 - i) * 2
                    local moveDis = dis / 10
                    local time = moveDis / speedStart
                    local moveBy = cc.MoveBy:create(time, cc.vec3(0, -moveDis, 0))
                    speedActionTable[#speedActionTable + 1] = moveBy
                end

                local moveBy = cc.MoveBy:create(0.1, cc.vec3(0, -dis, 0))
                speedActionTable[#speedActionTable + 1] = moveBy:reverse()

                local call_state =
                    cc.CallFunc:create(
                    function()
                        self:reelStopped(i)
                    end
                )
                speedActionTable[#speedActionTable + 1] = call_state
                -- 滚轴根结点执行动作列表 --
                local seq = cc.Sequence:create(speedActionTable)
                self._reelUnitsRoot[i]:runAction(seq)

                w.Status = Config.ReelStatus.Stoping
            end
        elseif w.Status == Config.ReelStatus.Idle then
        end
    end
end

-------------------------------------------------- trigger Slot Play Function S-----------------------------------------
function GamePusherMainLayer:playSlotPlayEffect(data)

    local updateData = {}
    updateData.isShoInitSlotReel = 1
    self.m_pGamePusherMgr:updatePlayingData( updateData )

    data:initSlotsRunData( ) -- 小老虎开始转动，然后才确定本轮的数据
    self._SlotData = data
    self._SoltsPlayData = {}
    --播放音效

    self:runSolt()
     
end



function GamePusherMainLayer:resetUnitTexture(_data)
    for i, w in ipairs(self._reelUnits) do
        local id = tonumber(_data[i])
        for k, v in pairs(w.Nodes) do
            self:replaceCsbSymbol(v, id)
            v._symbolID = id
        end
    end
end

function GamePusherMainLayer:runSolt()
    

    self:startRoll()

    self:delayCallFunc(function()

        self.m_freeSpinTimes = self.m_freeSpinTimes - 1
        self:updataFreeSpinCount( self.m_freeSpinTimes)

        local stopData = self._SlotData:getPlaySlotsDataReels()
        self:stopRoll( stopData )
    end,1)

end

function GamePusherMainLayer:playSlotEndLineEffect()
    --播放连线动画
    local reel = self._SlotData:getPlaySlotsDataReels()
    local symbol = nil
    local winType = self._SlotData.m_tRunningData.ActionData.EndType
    local hasLine = true
    local times = 0
    local CoinPileNum = 0
    for i = 1, #reel do
        
        if not symbol then
            symbol = reel[i]
        else
            if symbol ~= reel[i] then
                hasLine = false
            end
        end

        if reel[i] == Config.slotsSymbolType.CoinPile then
            CoinPileNum = CoinPileNum + 1
        end
    end

    if CoinPileNum > 0 and CoinPileNum < #reel then
        hasLine = true
        times = 1
        for i, w in ipairs(self._reelUnits) do
            for k, v in pairs(w.Nodes) do
                if v._symbolID == Config.slotsSymbolType.CoinPile then
                    self:changeSymbolInfo(v)
                    local action = cc.Sequence:create(cc.DelayTime:create(0.3), cc.Blink:create(0.5, 1))
                    v:runAction(cc.Repeat:create(action, 1))
                end
            end
        end

    else

        if hasLine then

            gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_slotNodeFlsh.mp3")

            times = 2
            for i, w in ipairs(self._reelUnits) do
                for k, v in pairs(w.Nodes) do
                    self:changeSymbolInfo(v)
                    local action = cc.Sequence:create(cc.DelayTime:create(0.3), cc.Blink:create(0.5, 1))
                    v:runAction(cc.Repeat:create(action, 2))
                end
            end

        end
    end

    if winType == Config.slotsSymbolType.Wall then
        gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_ComBo_WinThemAll.mp3") 
    elseif winType == Config.slotsSymbolType.Shake then
        gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_ComBo_SugarPower.mp3") 
    elseif winType == Config.slotsSymbolType.BigCoin then
        gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_ComBo_SweeterThanSweet.mp3") 
    elseif winType == Config.slotsSymbolType.CoinTower then
        gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_ComBo_Outstandinglydelicious.mp3") 
    elseif winType == Config.slotsSymbolType.CoinRain then
        gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_ComBo_Coinshower.mp3") 
    elseif winType == Config.slotsSymbolType.CoinPile then
        
    elseif winType == Config.slotsSymbolType.Jackpot then
        gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_ComBo_SweetJackpot.mp3")  
    elseif winType == Config.slotsSymbolType.Grand then
        gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_ComBo_SweetJackpot.mp3") 
    elseif winType == Config.slotsSymbolType.Major then
        gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_ComBo_SweetJackpot.mp3") 
    elseif winType == Config.slotsSymbolType.Minor then
        gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_ComBo_SweetJackpot.mp3") 
    elseif winType == Config.slotsSymbolType.Mini then
        gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_ComBo_SweetJackpot.mp3")  
    end
    
    
    return hasLine,times
end

function GamePusherMainLayer:changeSymbolInfo(_nodeAnima,_icol)
    if _nodeAnima._symbolID == Config.slotsSymbolType.CoinRain then
        local nodeAnima = self:getSymbolAnimaNode(_nodeAnima)
        local lbCount = nodeAnima:findChild("lbCount")
        if lbCount then
            lbCount:setVisible(true)
            local slotData = 10 -- 随机获取个数 后期写算法
            lbCount:setString(slotData.values)
        end
        
    end
end

function GamePusherMainLayer:runSlotEnd()
    local playLink,time = self:playSlotEndLineEffect()
    --结束
    self:delayCallFunc(function()
        self:playSlotEndEffect()
    end,time)

    
end

function GamePusherMainLayer:getSlotEndEffectInfo( )
    local _sType = nil
    local _sData = nil
    local endType =  self._SlotData.m_tRunningData.ActionData.EndType
    if endType == Config.slotsSymbolType.Wall then
        _sType = Config.CoinEffectRefer.WALL
    elseif endType == Config.slotsSymbolType.Shake then
        _sType = Config.CoinEffectRefer.SHAKE
    elseif endType == Config.slotsSymbolType.BigCoin then
        _sType = Config.CoinEffectRefer.BIGCOINS
    elseif endType == Config.slotsSymbolType.CoinTower then
        _sType = Config.CoinEffectRefer.COINSTOWER
    elseif endType == Config.slotsSymbolType.CoinRain then
        _sType = Config.CoinEffectRefer.COINSRAIN
    elseif endType == Config.slotsSymbolType.CoinPile then
        _sType = Config.CoinEffectRefer.COINSPILE
    elseif self.m_pGamePusherMgr:checkJackPotSymbolType(endType )  then
        _sType = Config.CoinEffectRefer.JACKPOT
    end
    return _sType,_sData
end

function GamePusherMainLayer:playSlotEndEffect()

        local sType,sData = self:getSlotEndEffectInfo( )
        self.m_pGamePusherMgr:addSlotsEffect(sType,sData)

        self.m_pGamePusherMgr:setPlayEnd(self._SlotData)
        self._SlotData = nil

end

----------------------------------------------------------------------------------------
-- update Tick 
----------------------------------------------------------------------------------------
-- Tick --
function GamePusherMainLayer:Tick( dt )
    
    -- 摄像机逻辑 --
    self:CameraTick( dt )
    
    -- Slot滚动逻辑 --
    self:reelTick(dt)
    
    -- Pusher推币逻辑 --
    self:pusherTick( dt )

    -- Lifter升降台逻辑
    self:lifterTick( dt )

    -- 特效逻辑 --
    self:effectTick( dt )

    --  玩法逻辑  -- 
    self.m_pGamePusherMgr:playTick(dt)

    if self.m_bBuffUpdateState then -- 开始游戏时才走检查buff剩余时间的逻辑
        -- 更新buff 逻辑
        self:updateBuffState(dt)
    end
    

    -- taphere 提示时间
    self:updateTapState(dt)

   
    if self.m_bBuffUpdateState then -- 开始游戏时才走判断结束的逻辑
        -- 判断是否向服务器发送游戏结束消息
        self:updataSendDropMsg(dt)
    else
        if self.m_nSendDt then
            self.m_nSendDt = nil 
        end
    end
    
    
    self:testLog()
    -- Test --
    if self.m_pDebugLayer then
        self.m_pDebugLayer:TestItemsNumShow( dt )
    end

    self:updataAutoDrop(dt)
end

function GamePusherMainLayer:restSendDt( )
    if self.m_nSendDt then
        self.m_nSendDt = nil 
    end
end

----------------------------------------------------------------------------------------
--init item
----------------------------------------------------------------------------------------
-- 场景实体数据获取 --
function GamePusherMainLayer:getSceneEntityData(  )
    local entityAttList = {}
    entityAttList.Pusher = { Status = self.m_nPusherStatus , Pos = self.m_pSp3DPusher:getPosition3D() }
    entityAttList.Entity = {}
    for k,v in pairs( self.m_tEntityList ) do
        
        local sType = v.Type
        local nID   = v.ID
        local pNode = v.Node
        local bCollision = v.Collision
        local vPos  = pNode:getPosition3D()
        local vRot  = pNode:getRotation3D()

        local entityAtt = { Type = sType , ID = nID , Pos = vPos , Rot = vRot , Collision = bCollision}
        table.insert( entityAttList.Entity, entityAtt )
    end 
    table.sort(entityAttList.Entity ,function( a,b )
        return a.Pos.z < a.Pos.z
    end)
    return entityAttList
end

---- 随机创建初始化存档数据
function GamePusherMainLayer:randomInitDisk()
    local tPushCoins = self.m_pGamePusherMgr:pubGetGamePusherCoins()
    --初始化盘面数据
    if tPushCoins and table.nums(tPushCoins) > 0 then
        --初始化盘面
        for i,data in pairs(tPushCoins) do
            for i = 1, data:getCount() do 
                self:createCoins( tostring(data.p_type), cc.vec3( math.random(-5,5),0, math.random(-2,20)) , cc.vec3(0.0, 0.0,  0.0), true) 
            end
        end
        self:saveEntityData()
    end
    
end

-- 场景实体加载 --  
function GamePusherMainLayer:loadSceneEntityData(  )
    
    local entityData = self.m_pGamePusherMgr:pubGetEntityData()

    -- 初始化推台 --
    if entityData and entityData.Pusher then
        -- self:resetPusherAtt( entityData.Pusher.Pos )

        self.m_nPusherStatus  = entityData.Pusher.Status
        self:setPusherRunning( true )

        -- 初始化金币和道具 --
        if entityData.Entity then
            for k,v in pairs( entityData.Entity ) do
                local sType = v.Type
                local nID   = v.ID
                local vPos  = v.Pos
                local vRot  = v.Rot
                local bCollision  = v.Collision
                
                if sType == Config.EntityType.COIN then
                    -- 创建金币或道具 必须在同一帧创建出来 --
                    self:createCoins( nID , vPos , vRot , bCollision)
                end
            end
            
        else
            -- 不会出现这种情况 金币数据应该是一直存在的
            assert( false , "loadSceneEntityData  不应该随机创建 ")
            self:randomInitDisk()
        end
        self:saveEntityData(true) --初始化推币机需要存储数据
        self.m_pGamePusherMgr:setAllEntityNodeKinematic( true  ) -- 初始化金币时不碰撞检测
        
    else
        -- 初始化金币和道具 --
        if entityData and entityData.Entity then
            for k,v in pairs( entityData.Entity ) do
                local sType = v.Type
                local nID   = v.ID
                local vPos  = v.Pos
                local vRot  = v.Rot
                local bCollision  = v.Collision or false

                if sType == Config.EntityType.COIN then
                    -- 创建金币或道具 必须在同一帧创建出来 --
                    self:createCoins( nID , vPos , vRot ,bCollision)
                end
            end

        else
            -- 不会出现这种情况 金币数据应该是一直存在的
            assert( false , "loadSceneEntityData  不应该随机创建 ")
            self:randomInitDisk()
        end
        self:saveEntityData(true) --初始化推币机需要存储数据
        self.m_pGamePusherMgr:setAllEntityNodeKinematic( true  ) -- 初始化金币时不碰撞检测
        
    end
end

----------------------------------------------------------------------------------------
--init UI
----------------------------------------------------------------------------------------
-- 初始化UI --  点击事件 (掉金币)
function GamePusherMainLayer:InitUI(  )

    if self.m_nodeUIRoot == nil then
        self.m_nodeUIRoot = cc.Node:create()
        self:addChild( self.m_nodeUIRoot )
    end

    -- 初始化触摸板 --
    local touch = ccui.Layout:create()
    touch:setName("EmitCoins")
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(false)
    touch:setAnchorPoint(0.5000, 0.5000)
    touch:setContentSize( cc.size( display.width / 2 + 150, display.height * 2))
    touch:setClippingEnabled(false)

    self.m_syncDirtyNode = cc.Node:create()
    self:addChild(self.m_syncDirtyNode)

    -- 点击区域加颜色 
    -- touch:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
    -- touch:setBackGroundColor( cc.c4b(0, 0, 255 ) );
    -- touch:setBackGroundColorOpacity( 128 )
    
    local pos3d = self.m_v3PusherPosOri     -- 目前以Pusher的初始3D位置来定位UI的2D坐标 --
    local pos2d = self:Convert3DToGL2D( pos3d)
    touch:setPosition( pos2d )
    self._TouchNode = touch
    self.m_nodeUIRoot:addChild(touch)
    
    touch:addTouchEventListener( function( sender, eventType )

        --这里加一个限定 当推币机推动时候允许点击 
        if  self.m_bTouchDropCoinsState  then

            if eventType == ccui.TouchEventType.began then
                print("d------------点击开始")
                self._TouchNode:stopAllActions()
                local beganPos = sender:getTouchBeganPosition()

                if not self.m_bAutoDropCoins then
                    if  self.m_bTouchDropCoinsState  then
                        self:touchNodeRequestCoinsDrop(sender, beganPos)
                    end
                end
                
                performWithDelay(self._TouchNode,function(  )
                    self.m_bAutoDropCoins  = true 
                    self:pusher_Schedule(self._TouchNode,function(  )
                        
                        if  self.m_bTouchDropCoinsState  then
                            self:touchNodeRequestCoinsDrop(sender, beganPos)
                        end 
                    end,Config.AutoIntervalTime)
                end,Config.AutoWaitTime)
            elseif eventType == ccui.TouchEventType.moved then
                print("d------------移动")
                self:stopAutoDrop( )
            elseif eventType == ccui.TouchEventType.canceled then
                print("dd-----------取消")
                self:stopAutoDrop( )
            elseif eventType == ccui.TouchEventType.ended then
                print("d------------点击结束")
                self:stopAutoDrop( )
            end
        else
            -- 不允许点击的状态就停止自动掉币
            self:stopAutoDrop( )
        end
        
    end )
    
    self:initMainUI()


end

function GamePusherMainLayer:pusher_Schedule(node, callback, delay)
    local delay = cc.DelayTime:create(delay)
    local sequence = cc.Sequence:create( cc.CallFunc:create(callback),delay)
    local action = cc.RepeatForever:create(sequence)
    node:runAction(action)
    return action
end

function GamePusherMainLayer:stopAutoDrop( )
    if self._TouchNode then
        self._TouchNode:stopAllActions()
    end
    self.m_bAutoDropCoins = false
end

-- 向服务器请求需要掉落什么金币
function GamePusherMainLayer:touchNodeRequestCoinsDrop(sender, vEndPos)
    local curPos = cc.p( sender:getPosition() )
    local offPos = cc.p( vEndPos.x - curPos.x , vEndPos.y - curPos.y )

    local content = sender:getContentSize()
    
    -- 发射金币 --
    local pos3dX  = offPos.x / (content.width / 2) * 12 + 1 - math.random(0, 2)
    local pos3dZ = -10.0    

    if offPos.y > 0 then
        local offPosY  = offPos.y / (content.width / 2) * 15
        pos3dZ = pos3dZ - offPosY
        if pos3dZ < -20 then
            pos3dZ = -20
        end
    end
    

    --服务器数据组装
    local vTouchPos = cc.vec3( pos3dX  , 8.0, pos3dZ)
    self.m_pGamePusherMgr:touchDropCoins(vTouchPos)
end


----------------------------------------------------------------------------------------
-- UI层逻辑
----------------------------------------------------------------------------------------
-- 初始化UI界面
function GamePusherMainLayer:initMainUI()
    self.m_pMainUI = util_createView(Config.ViewPathConfig.MainUI,self)
    self:addChild(self.m_pMainUI)
end

-- 更新UI界面
function GamePusherMainLayer:updateMainUI()

end

----------------------------------------------------------------------------------------
-- 特效逻辑
----------------------------------------------------------------------------------------
-- 初始化特效管理模块 --
function GamePusherMainLayer:InitEffect(  )

    self.m_pEffectRoot = require(Config.ViewPathConfig.Effect).new( self )
    self:addChild( self.m_pEffectRoot )
    self.m_pEffectRoot:setPosition3D( cc.vec3(0,0,0) )

    self:PlayEffect( Config.Effect.FlashLight.ID )
    self:PlayEffect( Config.Effect.FrontEffectPanel.ID , nil , "Idle" )
    self:PlayEffect(Config.Effect.JackpotEffectPanel.ID, nil, "Idle")

    self.m_pEffectRoot:initDropEffect()

end

-- 播放特效接口 --
function GamePusherMainLayer:PlayEffect( nType , pCall , sStatus )
    if self.m_pEffectRoot == nil then
        return
    end
    self.m_pEffectRoot:playEffect( nType , pCall , sStatus )
end

-- 特效步进逻辑 --
function GamePusherMainLayer:effectTick( dt )
    if self.m_pEffectRoot == nil then
        return
    end
    self.m_pEffectRoot:tickEffect( dt )
end

----------------------------------------------------------------------------------------
--推币机掉落
----------------------------------------------------------------------------------------

function  GamePusherMainLayer:playNormalCoinDropEffect(num,pos,id)

    self.m_pMainUI:playCoinsShowEffect(num, pos,id)
end

----------------------------------------------------------------------------------------
--推币机触发玩法
----------------------------------------------------------------------------------------
function GamePusherMainLayer:dropBigCoins(_count,_func)

    local count = _count
    for i=1,count do
        self:createCoins( "BIG" , cc.vec3(math.random(-5,5), 10.0, -10.0), Config.BigCoinRotate)
    end

    self:saveEntityData()
        
    if _func then
        _func()
    end

end



function GamePusherMainLayer:playDropCoinsEffect(_actionData)
    local actionData = _actionData
    local dropCoins = actionData[1]
    local dropInfo = actionData[2]
    local delayTime = 0
    for i,v in pairs(dropCoins) do
        local sType = tostring(i)
        for j = 1, v do
            local v3Rotate = Config.randomCoinRotate()
            if sType ~= Config.CoinModelRefer.NORMAL then
                --不为普通金币播放     
                self.m_pEffectRoot:playDropEffect()  
                if sType == Config.CoinModelRefer.SLOTS then
                    gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_slotCoinDrop.mp3")
                end
                self:createCoins( tostring(i), Config.CoinsPileDropCenter, v3Rotate) 
            else      
                self:createCoins( tostring(i), dropInfo.entityPos, v3Rotate)          
            end
        end
    end
    self.m_pEffectRoot:stopTaphereEffect()
    self.m_nTapUpdateTime = 0
    self:saveEntityData()
end

function GamePusherMainLayer:showPassStageView(  )
    
end

----------------------------------------- trigger game  Play Function E-----------------------------------------




----------------------------------------- add GAME COIN  Function E   --------------------------------------------

----------------------------------------- randomDropCion  Function S   -------------------------------------------
function GamePusherMainLayer:coinsPileDropCoins(_pData)

    -- 存储数据
    local totalNum = _pData:getTotalNum()
    local playingData = self.m_pGamePusherMgr:getPusherUseData( ) or {}
    local pusherMaxUseNum = playingData.pusherMaxUseNum
    local netInitData = playingData.netInitData or {}
    local coinPileMaxUseNum = netInitData.coinPileMaxUseNum or 0
    netInitData.coinPileMaxUseNum = coinPileMaxUseNum + totalNum
    playingData.netInitData = netInitData
    playingData.pusherMaxUseNum = playingData.pusherMaxUseNum + totalNum
    self.m_pGamePusherMgr:updatePlayingData( playingData )

    -- 播放效果
    self.m_bTouchDropCoinsState = false -- 不允许点击
    self.m_pGamePusherMgr:getMainUiNode():playLeftCoinsAnim( "autoStart",false,function()

        self.m_pGamePusherMgr:getMainUiNode():playLeftCoinsAnim( "autoJump",true)
        local playPropData = {}
        playPropData.ntimes = playingData.pusherMaxUseNum
        playPropData.beginNum = pusherMaxUseNum
        playPropData.jumpTime = 2
        playPropData.callfunc = function(  )

            self.m_pGamePusherMgr:getMainUiNode():playLeftCoinsAnim( "autoOver",false,function()
                self.m_bTouchDropCoinsState = true --播放完效果运行点击
            end)

        end
        gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_JumpLeftFreeCoinsTimes,playPropData)

    end)

    
    self.m_pGamePusherMgr:setPlayEnd(_pData)
end

----------------------------------------- randomDropCion  Function E   -------------------------------------------

function GamePusherMainLayer:stopPushing()
    self.m_bPusherOver    = true 
    self.m_bTapUpdateState = false  -- 停止tap
    self.m_bBuffUpdateState = false  
    self.m_bTouchDropCoinsState = false
    self:setPusherRunning( true )
    self.m_bPusherPlayStates = false
    self:stopAutoDrop( )

end

function GamePusherMainLayer:startPushing()
    self.m_bPusherOver    = false 
    self.m_bTouchDropCoinsState    = true
    self.m_bTapUpdateState = true  -- 停止tap
    self.m_bBuffUpdateState = true  
    self:setPusherRunning( true )
    self.m_bPusherPlayStates = true
    self.m_bOutLinePlayStates = true
end

----------------------------------------------------------------------------------------
-- 音 效
----------------------------------------------------------------------------------------
function GamePusherMainLayer:playSound(_soundName)
    if not self.m_bSoundNotPlay  then
        gLobalSoundManager:playSound(_soundName)
    end
end
----------------------------------------------------------------------------------------

function GamePusherMainLayer:stopAllEntity()

    for k,v in pairs(self.m_tEntityList) do
        local colNode = v
        if colNode ~= nil then
            self.m_pPhysicsWorld:removePhysics3DObject(colNode.Node:getPhysicsObj())  
        end
    end
end

function GamePusherMainLayer:saveEntityData(_isFlush)
    if _isFlush then
        --保存初始化盘面
        local entityData = self:getSceneEntityData()
        self.m_pGamePusherMgr:saveEntityData(entityData,_isFlush)
    else
        if self.m_isSyncDirty then
            return
        end
        self.m_isSyncDirty = true
    
        --开启同步后每2秒存一次数据
        performWithDelay(self.m_syncDirtyNode,function()
            self.m_isSyncDirty = false
            --保存初始化盘面
            local entityData = self:getSceneEntityData()
            self.m_pGamePusherMgr:saveEntityData(entityData,_isFlush)
        end,SYNC_DIRTY_DATA_TIME)
    end
    
end


-- 六边形坐标 
function GamePusherMainLayer:getHexagonInfo(_itemAtt,_halfAngle,_addX)
    
                       
    local nPlaneCount = 8
    local nRadiu      = _itemAtt.PhysicSize.x + _addX --斜边
    local cutAngle = (360 /(8*2)) * (_halfAngle % 2)
    
    local lSymbolList = { cc.p(1, -1), cc.p(-1, -1), cc.p(-1, 1), cc.p(1, 1) }
    local lVec3List = {}
    local nAnglePre = 360 / nPlaneCount 

    for i=1, nPlaneCount do
        local nAngle = nAnglePre * i - cutAngle
        local nIndex  = 1    
      
        --区分象限 算出计算坐标角度
        if nAngle >= (0 - cutAngle) and nAngle < (90 - cutAngle) then
            nIndex = 1  
        elseif nAngle >= (90 - cutAngle) and nAngle < (180 - cutAngle) then
            nIndex = 2  
            nAngle = 180 - nAngle
        elseif nAngle >= (180 - cutAngle) and nAngle < (270 - cutAngle) then
            nIndex = 3  
            nAngle = nAngle - 180 
        elseif nAngle >= (270 - cutAngle) and nAngle < (360- cutAngle) then
            nIndex = 4  
            nAngle = 360  - nAngle
        end

        local xPos = math.cos(math.rad(nAngle)) * nRadiu
        local zPos = math.sin(math.rad(nAngle)) * nRadiu
        local symbol = lSymbolList[nIndex]
        local vec3Pos = cc.vec3(symbol.x * xPos,0, symbol.y * zPos + 10  )
        table.insert(lVec3List,vec3Pos)
    end 
    
    return lVec3List
end

function GamePusherMainLayer:updataFreeSpinCount(str)
    if self._freeSpinText then
        self._freeSpinText:findChild("m_lb_num"):setString(str)
        self._freeSpinText:updateLabelSize({label=self._freeSpinText:findChild("m_lb_num"),sx=0.68,sy=0.68},55)
    end
end



--[[
    播放道具     
--]]
-- 道具 震动
function GamePusherMainLayer:playShakeProp( _data )


    local hammerFunction = function (  )
        self:itemsQuake( 30 )
        self:CameraQuake()
        self:saveEntityData()
        self.m_pGamePusherMgr:setPlayEnd(_data)
        
    end
    self:PlayEffect( Config.Effect.Hammer.ID , hammerFunction )

end

-- 道具 大金币
function GamePusherMainLayer:playBigCoinsProp(_data )

    local bigCoinsFunction = function (  )
        self.m_pGamePusherMgr:setPlayEnd(_data)
    end

    self:dropBigCoins(1,bigCoinsFunction)
     
end

-- 道具 墙
function GamePusherMainLayer:updateWallUpTimes(data )

       
    local pushersData = self.m_pGamePusherMgr:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    local wallInfo = {}
    wallInfo.wallMaxUseTimes = pushersData.wallMaxUseTimes  + Config.PropWallMaxCount
    self.m_pGamePusherMgr:updatePlayingData( data )
    self.m_pGamePusherMgr:setPusherUpWalls( wallInfo.wallMaxUseTimes,true )

    self.m_pGamePusherMgr:setMaxWallTime(wallInfo.wallMaxUseTimes )

    self.m_pGamePusherMgr:setPlayEnd(data)

 
end

-- 金币雨效果
function GamePusherMainLayer:playCoinsRainEffect(data )

    self:delayCallFunc( function(  )
        self.m_pGamePusherMgr:setPusherSpeed( Config.CoinsRainSpeed )
    end, 1 )  

    local posList =  {  cc.vec3( 0, 30.0, -15),
                        cc.vec3( -4, 30.0, -15),
                        cc.vec3( 4, 30.0, -15),
                        cc.vec3( -8, 30.0, -15),
                        cc.vec3( 8, 30.0, -15)}
    local posIndex = 1
    local totalNum = data:getLastCoinsNum()
    if totalNum <= 0 then
        self.m_pGamePusherMgr:setPlayEnd( data )
        return
    end

    local miniTime = Config.CoinsRainMinTimes * (totalNum / Config.CoinsRainMaxDrop)
    local maxTime = Config.CoinsRainMaxTimes * (totalNum / Config.CoinsRainMaxDrop)

    for i=1,totalNum do
        local index = i
        if posIndex > #posList then
            posIndex = 1
        end
        local Pos = posList[posIndex]
        local rotate = Config.CoinsRainRotate()
        if math.random(1,100) < 45 then
            rotate = Config.randomCoinRotate()
        end
        
        local time = math.random(miniTime* 10, maxTime* 10)/(totalNum * 10)
        self:delayCallFunc( function(  )

            local rodType = self.m_pGamePusherMgr:getRainDropCoinsType()
            if rodType == Config.CoinModelRefer.NORMAL then
                self:createCoins(  rodType , Pos, rotate)
            else

                self.m_pEffectRoot:playDropEffect()  
                if rodType == Config.CoinModelRefer.SLOTS then
                    gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_slotCoinDrop.mp3")
                end
                self:createCoins(  rodType , Config.CoinsPileDropCenter, rotate)
            end
            data:setLastCoinsNum( totalNum - index )
            self:saveEntityData()
            self.m_pGamePusherMgr:saveRunningData() 
            if i == totalNum then
                if data then

                    self.m_pGamePusherMgr:setPusherSpeed( Config.CoinsRainSpeed )
                    self:delayCallFunc( function(  )
                        self.m_pGamePusherMgr:setPlayEnd( data )
                        self.m_pGamePusherMgr:setPusherSpeed( Config.PusherSpeed )
                    end, 2 )                
                end
            end
        end, time * i )

        posIndex = posIndex + 1
    end

end

-- 播放推下台面所有金币动画
function GamePusherMainLayer:playCoinsTowerPushTableCoins(data )

    self.m_bTouchDropCoinsState    = false
    self.m_bTapUpdateState = false  -- 停止tap


    self:setPusherPosDestPos( Config.PusherDisVec3.PUSHER )
    self.m_nPusherStatus = Config.PusherStatus.Pull
    self:setPusherRunning( false ) 

    local node = cc.Node:create()
    self:addChild(node)
    util_schedule(node,function(  )
        if self.m_nPusherStatus == Config.PusherStatus.Idle then

            gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_TowerPushTable.mp3")
            
            -- 当前推币机状态是静止状态时，说明推币机已经收回去了

            self.m_pSp3DPusher:setPositionY(-1000)
            self.m_pSp3DPusherBig:setPositionY(Config.PusherPosVec3.y)
            self:setPusherRunning( true ) 
            node:stopAllActions()

            self:delayCallFunc(function(  )
                -- 等待一段时间后，停止推币机
                self:setPusherRunning( false ) 
                util_schedule(node,function(  )
                   
                    if self.m_nPusherStatus == Config.PusherStatus.Idle then
                        self.m_pGamePusherMgr:setPusherSpeed( Config.PusherSpeed )
                        self:playCoinsTowerDropEffect(data )

                        if not tolua.isnull(node) then
                            node:removeFromParent()
                        end

                        
                    elseif self.m_nPusherStatus == Config.PusherStatus.Pull then
                        if self.m_nPusherSpeed == Config.PusherSpeed then
                            self.m_pGamePusherMgr:setPusherSpeed( Config.PusherRainPullSpeed  )
                        end
                    end
                end,1/30)
            end,0.1)

        end
    end,1/30)

end

-- 播放推下台面所有金币动画
function GamePusherMainLayer:playCoinsTowerDropEffect(data )

    self.m_bTouchDropCoinsState     = false
    self.m_bTapUpdateState          = false  -- 停止tap

    self:setPusherRunning( false )
    self.m_pSp3DPusher:setPosition3D( Config.PusherPosVec3 )
    local curPosBig = self.m_pSp3DPusherBig:getPosition3D()
    self.m_pSp3DPusherBig:setPosition3D( cc.vec3(curPosBig.x, curPosBig.y, Config.PusherPosVec3.z) )
    self.m_nPusherStatus = Config.PusherStatus.Idle
    if data then
        data:setAnimateStates( Config.CoinTowerAnimStates.TowerDrop) 
    end
    
    self.m_pGamePusherMgr:saveRunningData() 

    -- 当前推币机状态是静止状态时，说明已经走完往下推的逻辑
    self:playCoinsTowerDrop(function(  )

        self.m_bTouchDropCoinsState     = true
        self.m_bTapUpdateState          = true  -- 停止tap
        if data then
            self.m_pGamePusherMgr:setPlayEnd( data )
        end
        
    end )
                
end

-- 播放金币塔下路动画
function GamePusherMainLayer:playCoinsTowerDrop(_func )
    performWithDelay(self,function(  )
        gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_TowerDrop.mp3")
    end,0.5)
    
   
    local coinsTowerSprList = {}
    local EntityData = self.m_pGamePusherMgr:getDiskEntityData("coinsTower")  -- 金币信息读取本地配置
    local moveTime_1 = 1.5
    local moveTime_2 = 0.1
    local moveTime_3 = 0.1
    local moveTime_4 = 0.1
    -- 初始化金币和道具 --
    if EntityData.Entity then
        for k,v in pairs( EntityData.Entity ) do
            local sType = v.Type
            local nID   = v.ID
            local vPos  = cc.vec3(v.Pos.x , v.Pos.y + 25 , v.Pos.z ) 
            local vRot  = v.Rot
            local bCollision  = true
            local sprite = self:createCoins( nID , vPos , vRot , bCollision)
            local rigidBody = sprite:getPhysicsObj()
            rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true

            local actList = {}
            actList[#actList + 1] = cc.EaseIn:create(cc.MoveTo:create(moveTime_1,cc.vec3(v.Pos.x , v.Pos.y , v.Pos.z)),3)
            actList[#actList + 1] = cc.EaseOut:create(cc.MoveTo:create(moveTime_2,cc.vec3(v.Pos.x , v.Pos.y + 0.3 , v.Pos.z)),3)
            actList[#actList + 1] = cc.EaseIn:create(cc.MoveTo:create(moveTime_3,cc.vec3(v.Pos.x , v.Pos.y  , v.Pos.z )),3)
            actList[#actList + 1] = cc.DelayTime:create(moveTime_4)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                rigidBody:setKinematic(false) 
            end) 
            local sq = cc.Sequence:create(actList)
            sprite:runAction(sq)
            table.insert( coinsTowerSprList, sprite )
        end
    end


    self:delayCallFunc( function(  )
        self:CameraQuakeMax()
    end,moveTime_1 )

    self:delayCallFunc( function(  )


        self.m_pSp3DPusherBig:setPositionY(-1000)
        self.m_pSp3DPusher:setPositionY(Config.PusherPosVec3.y)
    
        self:setPusherPosDestPos( Config.PusherDisVec3.ORI )
        self:setPusherRunning( true ) 

        self:saveEntityData() 

        if _func then
            _func()
        end

    end,(moveTime_1 + moveTime_2 + moveTime_3 + moveTime_4))
    


    
    return coinsTowerSprList
end

-- jackpot收集玩法
function GamePusherMainLayer:playJpCollectEffect( data)

     --load游戏数据
    local pushersData = self.m_pGamePusherMgr:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    if pushersData and table_length(pushersData) ~= 0 then

        local netInitData = pushersData.netInitData or {} 
        local jackpotSignal = tonumber(netInitData.jackpotSignal)  

        -- local endPos_max    = cc.vec3(7.5 , 13 , 36 ) -- 上
        -- local endPos_mid    = cc.vec3(7.5 , 10 , 36 )
        -- local endPos_mini   = cc.vec3(10.5 , 6 , 36 )

        local endPos_max    = cc.vec3(7 , 16 , 36 )  -- 下
        local endPos_mid    = cc.vec3(7 , 12 , 36 )
        local endPos_mini   = cc.vec3(10 , 10 , 36 )


        local endPos        = endPos_mid

        if display.height == 1024 then
            endPos              = endPos_mini
        elseif display.height == 1370 then
            endPos              = endPos_mid
        elseif display.height == 1660 then
            endPos              = endPos_max
        elseif display.height > 1370 then
            local cutPos        = cc.vec3(endPos_max.x - endPos_mid.x,endPos_max.y - endPos_mid.y,0)
            local mul_1         = 1660 - 1370
            local mul_2         = display.height - 1370
            local addPos        = cc.vec3((cutPos.x / mul_1) * mul_2 ,(cutPos.y / mul_1) * mul_2 ,0)
            endPos              = cc.vec3add(addPos,endPos_mid) 
        elseif display.height > 1024 then
            local cutPos        = cc.vec3(endPos_max.x - endPos_mini.x,endPos_max.y - endPos_mini.y,0)
            local mul_1         = 1660 - 1024
            local mul_2         = display.height - 1024
            local addPos        = cc.vec3((cutPos.x / mul_1) * mul_2 ,(cutPos.y / mul_1) * mul_2 ,0)
            endPos              = cc.vec3add(addPos,endPos_mini) 
        end

        gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_JpFly.mp3")
        
        for i = 1, 3 do
            local pos = self._reelUnitsRoot[i]:getPosition3D()
            local spSymbol = self:createSymbol(jackpotSignal, pos)
            self._reelUnitsRoot[i]:getParent():addChild(spSymbol)
            spSymbol:setVisible(false)
            local aniNode = self:getSymbolAnimaNode(spSymbol)
            aniNode:runCsbAction("shouji")

            local actList = {}
            if i == 3 then
                actList[#actList + 1] = cc.CallFunc:create(function(  )
                    for i, w in ipairs(self._reelUnits) do
                        for k, v in pairs(w.Nodes) do
                            local csbNode = self:getSymbolAnimaNode(v)
                            csbNode:runCsbAction("shouji",false,function(  )
                                csbNode:runCsbAction("idleframe")
                            end)
                        end
                    end
                end)
            end
            actList[#actList + 1] = cc.DelayTime:create(11/60)
            actList[#actList + 1] = cc.CallFunc:create(function(  )

                

                spSymbol:setVisible(true)
                local csbNode = self:getSymbolAnimaNode(spSymbol)
                csbNode:runCsbAction("fly")

                spSymbol:runAction(cc.ScaleTo:create(18/60,0.5))
            end)
            actList[#actList + 1] = cc.MoveTo:create(18/60,endPos)
            if i == 3 then
                actList[#actList + 1] = cc.CallFunc:create(function(  )

                    gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_JpSlotfankui.mp3")

                    self.m_pMainUI:initJpLogoImg(self.m_pGamePusherMgr:getJpTypeIndex( jackpotSignal ) )
                    self.m_pMainUI.m_jpLogoCsb:setVisible(true)
                    self.m_pMainUI.m_jpLogoCsb:runCsbAction("actionframe",false,function()
                        self.m_pGamePusherMgr:updateNetInitData({jpPlayed = 1} )
                        self.m_pGamePusherMgr:setPlayEnd( data )
                        self.m_pMainUI.m_jpLogoCsb:runCsbAction("idleframe",true)
                    end)
                end)
            end
            actList[#actList + 1] = cc.DelayTime:create(6/60)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                spSymbol:setVisible(false)
                spSymbol:removeFromParent()
            end)      
            spSymbol:runAction(cc.Sequence:create(actList))
        end
    else
        self.m_pGamePusherMgr:updateNetInitData({jpPlayed = 1} )
        self.m_pGamePusherMgr:setPlayEnd( data )
    end
    

    
end

function GamePusherMainLayer:delayCallFunc( _func,_time)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode, function(  )
        if _func then
            _func()
        end

        if not tolua.isnull(waitNode) then
            waitNode:removeFromParent()
        end

    end,_time)
end



----------------------------------------------------------------------------------------
--推币机Debug And Log
----------------------------------------------------------------------------------------

function GamePusherMainLayer:updataAutoDrop(dt)
    if self.m_pGamePusherMgr:pubCheckAutoDrop() then
        if  not self.m_nAutoDropTimeRecord then
            self.m_nAutoDropTimeRecord = self.m_nAutoDropTime
        end

        self.m_nAutoDropTimeRecord = self.m_nAutoDropTimeRecord - dt

        if self.m_nAutoDropTimeRecord < 0 then
            self.m_nAutoDropTimeRecord = self.m_nAutoDropTime
            if self.m_pGamePusherMgr:getPlayListCount() == 0 then
                --检查当前的动画状态
                self:touchNodeRequestCoinsDrop(self._TouchNode, cc.p(self._TouchNode:getPositionX() + display.cx / 2 - math.random(0, display.cx ) ,self._TouchNode:getPositionY())) 
            end
        end
    end
end

function GamePusherMainLayer:testLog()
    if not  Config.DebugCoinCount then
        return
    end
    local testData = {}
    for k,v in pairs( self.m_tEntityList ) do
        local nID   = v.ID
        if testData[nID] then
            testData[nID] = testData[nID] + 1
        else
            testData[nID] = 1
        end
    end 
    
    if not self._TestLb then
        self._TestLb  = {}
    end
    for i=1,#self._TestLb do
        local lb = self._TestLb[i]
        lb:setVisible(false)
    end

    local iCount = 0
    for k,v in pairs(testData) do
        local lcoinWinNums = self:getChildByName(k)
        if not lcoinWinNums then
            lcoinWinNums = cc.Label:createWithSystemFont( k .. "  :  " ..v , "", 24)
            lcoinWinNums:setTextColor(ccc4(255,   0,   0, 255) )
            lcoinWinNums:setAnchorPoint( cc.p( 1 , 0.5 ) )
            lcoinWinNums:setPosition( cc.p( 200 , 100 + iCount * 25 ) )
            lcoinWinNums:setName(k)
            self:addChild( lcoinWinNums)
            self._TestLb[#self._TestLb  + 1 ] = lcoinWinNums

        else
            lcoinWinNums:setVisible(true)
            lcoinWinNums:setString(k .. "  :  " ..v)
            lcoinWinNums:setPosition( cc.p( 200 , 100 + iCount * 25 ) )
        end
        iCount = iCount + 1
    end
end

function GamePusherMainLayer:initDesktopDebugLayer()
    self.m_pDesktopLayer = util_createView(Config.ViewPathConfig.DesktopDebug, self)
    self.m_pDesktopLayer:setPosition(display.width/2, display.height)
    self:addChild(self.m_pDesktopLayer)
end

function GamePusherMainLayer:removeDesktopDebugLayer()
    if self.m_pDesktopLayer then
        self.m_pDesktopLayer:removeFromParent()
        self.m_pDesktopLayer = nil
    end
end


function GamePusherMainLayer:randomSetDesktop(pushCoins)

    self.m_coinsShowType = self.m_coinsShowType + 1

    if self.m_coinsShowType > 6 then
        self.m_coinsShowType = 1
    end

    local coinsShowType = 5--self.m_coinsShowType

    if coinsShowType == 1 then -- 埃及金字塔测试代码
        --[[  1 1 1 
             1 /1\
              / 4 \
             /  9  \
            /   16  \ 1
            1  1   1  1
        --]]

        -- 第一层
        local skewX = 6.7
        local addX = 2.1
        local skewZ = 2

        for iX=1,4 do
            local addiX = 0.08 * iX
            for iY=1,4 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX 
                local posY = 0.7400004863739
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=1,4 do
            local addiX = 0.08 * iX
            for iY=1,4 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX 
                local posY = 0.7400004863739 + sizeY
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end


        -- 第二层
        for iX=1,3 do
            local addiX = 0.08 * iX
            for iY=1,3 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX + addX / 2
                local posY = 0.7400004863739 + sizeY * 2
                local PosZ = (iY + 1.5) * sizeX  - addiX - skewZ
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

    


        -- 第三层
        for iX=1,2 do
            local addiX = 0.08 * iX
            for iY=1,2 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX + addX 
                local posY = 0.7400004863739 + sizeY * 3
                local PosZ = (iY + 2) * sizeX  - addiX - skewZ
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end 

    



        -- 第四层
        for iX=1,1 do
            local addiX = 0.08 * iX
            for iY=1,1 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX + addX * 1.5
                local posY = 0.7400004863739 + sizeY * 4
                local PosZ = (iY + 2.5) * sizeX - addiX - skewZ
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end


        for iX=1,4 do
            local addiX = 0.08 * iX
            for iY=1,2 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 1.2
                local posY = 0.7400004863739
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ - 6
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=1,3 do
            local addiX = 0.08 * iX
            for iY=1,1 do
                local coinsType = "SLOTS"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 1.2
                local posY = 0.7400004863739 + sizeY
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ - 6
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=2,2 do
            local addiX = 0.08 * iX
            for iY=1,1 do
                local coinsType = "SLOTS"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 1.2
                local posY = 0.7400004863739 + sizeY * 2
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ - 6
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for z=1,1 do
            for iX=2,2 do
                local addiX = 0.08 * iX
                for iY=1,1 do
                    local coinsType = "SLOTS"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * sizeX  - (iY * 1) - skewX - 0.2 - 1.2
                    local posY = 0.7400004863739 + sizeY * (4 + z)
                    local PosZ = (iY + 1) * sizeX  - addiX - skewZ  + 4
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 
            end
        end
        

        for iX=1,1 do
            local addiX = 0.08 * iX
            for iY=1,1 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 4
                local posY = 0.7400004863739 + sizeY
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ + 1
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=1,5 do
            local addiX = 0.08 * iX
            for iY=4,4 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.5
                local posY = 0.7400004863739
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ - 1 + 5
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

          
        for iX=5,5 do
            local addiX = 0.08 * iX
            for iY=2,3 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.3
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.5
                local posY = 0.7400004863739
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ - 1 + 5
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

    elseif coinsShowType == 2 then --螺旋塔
        --[[
           ↙ ↖
           ↘ ↗
            .
            . x 8
            .
           ↙ ↖
           ↘ ↗
           
        --]]
        
        local itemAtt = Config.CoinModelAtt["NORMAL"]
        local sizeY = itemAtt.PhysicSize.y + 0.3

        local posX = -2
        local posY = 0.7400004863739 + sizeY * 9
        local PosZ = 12.5
        self:createCoins( tostring("SLOTS"), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
        self.m_pDesktopLayer:reducePushType(tostring("SLOTS"))

        local posX = 2
        local posY = 0.7400004863739 + sizeY * 9
        local PosZ =  12.5
        self:createCoins( tostring("SLOTS"), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
        self.m_pDesktopLayer:reducePushType(tostring("SLOTS"))


        -- 确定一点
        local centerCircle = cc.vec3(0,0,0)
        local base = 6
        local posTable = {}

        local rbDes = {}                          
        local nPlaneCount = 50
        local itemAtt = Config.CoinModelAtt["NORMAL"]
        local nRadiu      = (itemAtt.PhysicSize.x + 1.6) / math.cos(math.rad( 45 / (nPlaneCount / 4) )) /2 + 0.5
        local nHeight     = itemAtt.PhysicSize.y + 0.3
        
        local lSymbolList = { cc.p(1, -1), cc.p(-1, -1), cc.p(-1, 1), cc.p(1, 1) }
        local lVec3List = {}
        local nAnglePre = 360 / nPlaneCount

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
            local vec3Pos = cc.vec3(symbol.x * xPos,-nHeight/2, symbol.y * zPos  )
            table.insert(posTable,vec3Pos)
        end 
        
        local layerNum = 8
        local coinsNum = 5
        local tCoins = {}
        for iLayer=1,layerNum do
            if tCoins[iLayer] == nil then
                tCoins[iLayer] = {}
            end 
            for iCoins=1,coinsNum do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05
                local sizeY = itemAtt.PhysicSize.y + 0.3

                local vLastCoinsPosY = nil
                if tCoins[iLayer - 1] and  tCoins[iLayer - 1][iCoins] then
                    vLastCoinsPosY = tCoins[iLayer - 1][iCoins].sp:getPosition3D().y + tCoins[iLayer - 1][iCoins].height / 2 + sizeY / 2 + 0.1
                else
                    vLastCoinsPosY = 0.74000036716461
                end
                
                local nIndex = iCoins * 10 + iLayer
                if nIndex >  nPlaneCount then
                    nIndex = iLayer
                end
                local posX = posTable[nIndex].x  
                local posY = vLastCoinsPosY
                local PosZ = posTable[nIndex].z + 12
                local spCoins = self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
                tCoins[iLayer][iCoins] = {sp = spCoins, height = sizeY}
            end
        end

        -- 第一层
        local skewX = 6.7
        local addX = 2.1
        local skewZ = 2

        for i=1,4 do
            for iX=1,1 do
                local addiX = 0.08 * iX
                for iY=1,3 do
                    local coinsType = "NORMAL"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5 + 1
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * sizeX  - (4 * 1) - skewX - 0.5 + 2 - 2
                    local posY = 0.7400004863739 + sizeY * (i -1) 
                    local PosZ =  sizeX  - addiX - skewZ - 1 + 3 + 14 - sizeX*(iY)
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 
            end  

            for iX=4,4 do
                local addiX = 0.08 * iX
                for iY=1,3 do
                    local coinsType = "NORMAL"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5 + 1
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * sizeX  - (1 * 1) - skewX - 0.5 + 2 - 2 - 3.5
                    local posY = 0.7400004863739 + sizeY * (i -1) 
                    local PosZ =  sizeX  - addiX - skewZ - 1 + 3 + 14 - sizeX*(iY)
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 
            end 
        end
        

    
        for i=1,4 do
            for iX=1,4 do
                local addiX = 0.08 * iX
                for iY=4,4 do
                    local coinsType = "NORMAL"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5 + 1
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * sizeX  - (iY * 1) - skewX - 0.5 + 2 - 2
                    local posY = 0.7400004863739 + sizeY * (i -1) 
                    local PosZ =  sizeX  - addiX - skewZ - 1 + 3 + 14
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 
            end
        end
       

        for iX=1,3 do
            local addiX = 0.08 * iX
            for iY=4,4 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5 + 1
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.5 + 2
                local posY = 0.7400004863739 + sizeY * 5
                local PosZ =  sizeX  - addiX - skewZ - 1 + 3 + 14
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for i=1,6 do
            local coinsType = "NORMAL"
            for iX=1,3 do
                local addiX = 0.08 * iX
                for iY=4,4 do
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5 + 1
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * sizeX  - (iY * 1) - skewX - 0.5 + 2
                    local posY = 0.7400004863739 + sizeY * (i -1)
                    local PosZ =  sizeX  - addiX - skewZ - 1 + 3 - 5
                    local coinsType_1 = "NORMAL"
                    if i>=6 then
                        coinsType_1 = "SLOTS"
                    end
                    self:createCoins( tostring(coinsType_1), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 
            end
        end
        



        

    elseif coinsShowType == 3 then -- 五个柱子每个八层

        --[[
            0 0 0  
             0 0
        --]]

        -- 第一层
        local skewX = 6.8
        local addX = 1.8
        local skewZ = 1

        for iY=1,8 do
            
                for iX=1,3 do
                    local addiX = 0.08 * iX
                    local coinsType = "NORMAL"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * sizeX  - skewX
                    local posY = 0.7400004863739 + sizeY * (iY - 1)
                    local PosZ =  sizeX * 3 - addiX - skewZ
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 

     
        end

        -- 第二层
        for iY=1,8 do

                for iX=1,2 do
                    local addiX = 0.08 * iX
                    local coinsType = "NORMAL"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * sizeX - skewX + addX
                    local posY = 0.7400004863739 + sizeY * (iY - 1)
                    local PosZ =  sizeX * 4 - addiX - skewZ
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 

        end

        -- 最高层slots币
        for iX=1,2 do
            local addiX = 0.08 * iX
            local coinsType = "SLOTS"
            local itemAtt = Config.CoinModelAtt[coinsType]
            local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
            local sizeY = itemAtt.PhysicSize.y + 0.3
            local posX = iX * sizeX - skewX + addX - 1.6
            local posY = 0.7400004863739 + sizeY * (9 - 1)
            local PosZ =  sizeX * 4 - addiX - skewZ - 5
            self:createCoins( "SLOTS", cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
            self.m_pDesktopLayer:reducePushType(coinsType)
        end 


        
         -- 第一层
         local skewX = 6.7
         local addX = 2.1
         local skewZ = 2
 
         for i=1,4 do
             for iX=1,1 do
                 local addiX = 0.08 * iX
                 for iY=1,3 do
                     local coinsType = "NORMAL"
                     local itemAtt = Config.CoinModelAtt[coinsType]
                     local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5 + 1
                     local sizeY = itemAtt.PhysicSize.y + 0.3
                     local posX = iX * sizeX  - (4 * 1) - skewX - 0.5 + 2 - 2
                     local posY = 0.7400004863739 + sizeY * (i -1) 
                     local PosZ =  sizeX  - addiX - skewZ - 1 + 3 + 14 - sizeX*(iY)
                     self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                     self.m_pDesktopLayer:reducePushType(coinsType)
                 end 
             end  
 
             for iX=4,4 do
                 local addiX = 0.08 * iX
                 for iY=1,3 do
                     local coinsType = "NORMAL"
                     local itemAtt = Config.CoinModelAtt[coinsType]
                     local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5 + 1
                     local sizeY = itemAtt.PhysicSize.y + 0.3
                     local posX = iX * sizeX  - (1 * 1) - skewX - 0.5 + 2 - 2 - 3.5
                     local posY = 0.7400004863739 + sizeY * (i -1) 
                     local PosZ =  sizeX  - addiX - skewZ - 1 + 3 + 14 - sizeX*(iY)
                     self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                     self.m_pDesktopLayer:reducePushType(coinsType)
                 end 
             end 
         end
         
 
     
         for i=1,4 do
             for iX=1,4 do
                 local addiX = 0.08 * iX
                 for iY=4,4 do
                     local coinsType = "NORMAL"
                     local itemAtt = Config.CoinModelAtt[coinsType]
                     local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5 + 1
                     local sizeY = itemAtt.PhysicSize.y + 0.3
                     local posX = iX * sizeX  - (iY * 1) - skewX - 0.5 + 2 - 2
                     local posY = 0.7400004863739 + sizeY * (i -1) 
                     local PosZ =  sizeX  - addiX - skewZ - 1 + 3 + 14
                     self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                     self.m_pDesktopLayer:reducePushType(coinsType)
                 end 
             end
         end
        
 
         for iX=1,3 do
             local addiX = 0.08 * iX
             for iY=4,4 do
                 local coinsType = "NORMAL"
                 local itemAtt = Config.CoinModelAtt[coinsType]
                 local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5 + 1
                 local sizeY = itemAtt.PhysicSize.y + 0.3
                 local posX = iX * sizeX  - (iY * 1) - skewX - 0.5 + 2
                 local posY = 0.7400004863739 + sizeY * 5
                 local PosZ =  sizeX  - addiX - skewZ - 1 + 3 + 14
                 self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                 self.m_pDesktopLayer:reducePushType(coinsType)
             end 
         end
 
         for i=1,4 do
             local coinsType = "NORMAL"
             for iX=1,3 do
                 local addiX = 0.08 * iX
                 for iY=4,4 do
                     local itemAtt = Config.CoinModelAtt[coinsType]
                     local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5 + 1
                     local sizeY = itemAtt.PhysicSize.y + 0.3
                     local posX = iX * sizeX  - (iY * 1) - skewX - 0.5 + 2
                     local posY = 0.7400004863739 + sizeY * (i -1)
                     local PosZ =  sizeX  - addiX - skewZ - 1 + 3 - 5
                     local coinsType_1 = "NORMAL"
                     if i>=4 then
                         coinsType_1 = "SLOTS"
                     end
                     self:createCoins( tostring(coinsType_1), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                     self.m_pDesktopLayer:reducePushType(coinsType)
                 end 
             end
         end
         
         


    elseif coinsShowType == 4 then 

        --[[  
            3 x 4 -- 3层
        --]]

        -- 第一层
        local skewX = 11.5
        local addX = 2.1
        local skewZ = -1

        for i=1,2 do
            for iX=1,5 do
                local addiX = 0.08 * iX
                for iY=1,4 do
                    local coinsType = "NORMAL"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * (sizeX + 0.2)  - skewX 
                    local posY = 0.7400004863739 + (i -1) *sizeY
                    local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 
            end 
        end
        

        for iX=1,5 do
            local addiX = 0.08 * iX
            for iY=1,4 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * (sizeX + 0.2)  - skewX 
                local posY = 0.7400004863739 + sizeY * 2
                local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        

        for iX=1,5 do
            local addiX = 0.08 * iX
            for iY=1,3 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * (sizeX + 0.2)  - skewX 
                local posY = 0.7400004863739 + sizeY * 3
                local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end


        for iX=1,5 do
            local addiX = 0.08 * iX
            for iY=1,2 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * (sizeX + 0.2)  - skewX 
                local posY = 0.7400004863739 + sizeY * 4
                local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end 




        for index=1,5 do
            for iX=1,3 do
                local addiX = 0.08 * iX
                for iY=4,4 do
                    local coinsType = "SLOTS"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * (sizeX + 1)  - skewX + 0.5
                    local posY = 0.7400004863739 + sizeY * (index -1 )
                    local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ - 20
                    if index <= 4 then
                        coinsType = "NORMAL"
                    else
                        if iX ~= 2 then
                            coinsType = "NORMAL"
                        end
                    end
                    
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 
            end 
        end
          

        
        for index=1,6 do
            for iX=1,2 do
                local addiX = 0.08 * iX
                for iY=4,4 do
                    local coinsType = "SLOTS"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * (sizeX + 1)  - skewX + 3.2
                    local posY = 0.7400004863739 + sizeY * (index -1 )
                    local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ - 25
                    if index <= 5 then
                        coinsType = "NORMAL"
                    end
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 
            end
        end

        for iX=1,2 do
            local addiX = 0.08 * iX
            for iY=4,4 do
                local coinsType = "SLOTS"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = (iX -1) * sizeX - skewX + 3.2 + 6
                local posY = 0.7400004863739 + sizeY * 5
                local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ - 12
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

    elseif coinsShowType == 5 then
        -- 船型super牌面
 
          --[[ 
             z   y   x 
             3 x 4 x 5 
         --]]
 
         -- 平铺前9层
         local skewX = 11.5
         local addX = 2.1
         local skewZ = -1
         for i=1,9 do
             for iX=1,5 do
                 local addiX = 0.08 * iX
                 for iY=1,4 do
                     local coinsType = "NORMAL"
                     local itemAtt = Config.CoinModelAtt[coinsType]
                     local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                     local sizeY = itemAtt.PhysicSize.y + 0.3
                     local posX = iX * (sizeX + 0.2)  - skewX 
                     local posY = 0.7400004863739 + (i -1) *sizeY
                     local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ
 
                     if i == 9 then
                         if iY == 3  then
                             if iX == 3  then
                                 self:createCoins( tostring("SLOTS"), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                             end
                         elseif iY == 2 then
                             if iX == 2 or  iX == 4 then
                                 self:createCoins( tostring("SLOTS"), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                             end
                         end
                         
                     elseif i > 5 then
                         if iX > 1 and  iX < 5 then
                             if iY > 1 and  iY < 4 then
                                 self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                             end
                         end
                     else
                         self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                     end
                     self.m_pDesktopLayer:reducePushType(coinsType)
                 end 
             end 
         end 
 
         -- 正向向后两行
         for index=1,6 do
             for iX=1,3 do
                 local addiX = 0.08 * iX
                 for iY=4,4 do
                     local coinsType = "SLOTS"
                     local itemAtt = Config.CoinModelAtt[coinsType]
                     local sizeX = itemAtt.PhysicSize.x + 0.05 
                     local sizeY = itemAtt.PhysicSize.y + 0.3
                     local posX = iX * (sizeX + 0.5)  - skewX + 2.2
                     local posY = 0.7400004863739 + sizeY * (index -1 )
                     local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ - 23
 
                     if index == 6 then
                         self:createCoins( tostring("SLOTS"), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                     else
                         self:createCoins( tostring("NORMAL"), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                     end
                     self.m_pDesktopLayer:reducePushType(coinsType)
                 end 
             end
         end
 
         for index=1,6 do
             for iX=1,4 do
                 local addiX = 0.08 * iX
                 for iY=4,4 do
                     local coinsType = "SLOTS"
                     local itemAtt = Config.CoinModelAtt[coinsType]
                     local sizeX = itemAtt.PhysicSize.x + 0.05 
                     local sizeY = itemAtt.PhysicSize.y + 0.3
                     local posX = iX * (sizeX + 0.5)  - skewX 
                     local posY = 0.7400004863739 + sizeY * (index -1 )
                     local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ - 18
    
                     if index == 6  then
                         self:createCoins( tostring("SLOTS"), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                     else
                         self:createCoins( tostring("NORMAL"), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                     end
                     
                     self.m_pDesktopLayer:reducePushType(coinsType)
                 end 
             end
         end
 
    elseif coinsShowType == 6 then
        --[[
            3个金币金币塔
        --]]
        local itemAtt  = Config.CoinModelAtt["NORMAL"]
        local height   = 8
        local sizeY    = itemAtt.PhysicSize.y + 0.4
        local addX     = 1.1

        for i=1,height do
            local vec3List = self:getHexagonInfo(itemAtt,i,addX)
            for j=1,#vec3List do
                vec3List[j].x = vec3List[j].x + 5.8
                vec3List[j].z = vec3List[j].z + 6
                vec3List[j].y = sizeY * (i -1)

                local spriteCenter 
                if j == #vec3List then
                    local pos3d = cc.vec3((vec3List[1].x + vec3List[4].x) / 2  , vec3List[j].y,(vec3List[1].z + vec3List[4].z) / 2 + 1.5)
                    spriteCenter = self:createCoins( "NORMAL",  cc.vec3(5.8, vec3List[j].y ,16) , cc.vec3(0.0, 0.0,0.0), false) 
                end
                if spriteCenter then
                    local rigidBody = spriteCenter:getPhysicsObj()
                    rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true
                end


                local sprite = self:createCoins( "NORMAL", vec3List[j] , cc.vec3(0.0, 0.0,0.0), false) 
                local rigidBody = sprite:getPhysicsObj()
                rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true
            end
        end

        for i=1,height do
            local vec3List = self:getHexagonInfo(itemAtt,i,addX)
            for j=1,#vec3List do
                vec3List[j].x = vec3List[j].x - 5.8
                vec3List[j].z = vec3List[j].z + 6
                vec3List[j].y = sizeY * (i -1)

                local spriteCenter 
                if j == #vec3List then
                    local pos3d = cc.vec3((vec3List[1].x + vec3List[4].x) / 2 , vec3List[j].y,(vec3List[1].z + vec3List[4].z) / 2 + 1.5) 
                    spriteCenter = self:createCoins( "NORMAL",cc.vec3(-5.8, vec3List[j].y ,16) , cc.vec3(0.0, 0.0,0.0), false) 
                end

                if spriteCenter then
                    local rigidBody = spriteCenter:getPhysicsObj()
                    rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true
                end


                local sprite = self:createCoins( "NORMAL", vec3List[j] , cc.vec3(0.0, 0.0,0.0), false) 
                local rigidBody = sprite:getPhysicsObj()
                rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true
            end
        end
      
        for i=1,height do
            local vec3List = self:getHexagonInfo(itemAtt,i,addX)
            for j=1,#vec3List do
                -- vec3List[j].x = vec3List[j].x 
                vec3List[j].z = vec3List[j].z - 4.5
                vec3List[j].y = sizeY * (i -1)

                local spriteCenter 
                if j == #vec3List then
                    local pos3d = cc.vec3((vec3List[1].x + vec3List[4].x) / 2 , vec3List[j].y,(vec3List[1].z + vec3List[4].z) / 2 + 1.5) 
                    spriteCenter = self:createCoins( "NORMAL",cc.vec3(0.0,vec3List[j].y,5.5), cc.vec3(0.0, 0.0,0.0), false) 
                end

                if spriteCenter then
                    local rigidBody = spriteCenter:getPhysicsObj()
                    rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true
                end


                local sprite = self:createCoins( "NORMAL", vec3List[j] , cc.vec3(0.0, 0.0,0.0), false) 
                local rigidBody = sprite:getPhysicsObj()
                rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true
            end
        end

        ---------------------
        --上三
        local spriteSlot_1 = self:createCoins( "SLOTS",cc.vec3(0.0, sizeY * height,5.5 - 3), cc.vec3(0.0, 0.0,0.0), false) 
        local rigidBody = spriteSlot_1:getPhysicsObj()
        rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true

        local spriteSlot_2 = self:createCoins( "SLOTS",cc.vec3(2.5, sizeY* height,5.5 + 1.5), cc.vec3(0.0, 0.0,0.0), false) 
        local rigidBody = spriteSlot_2:getPhysicsObj()
        rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true

        local spriteSlot_3 = self:createCoins( "SLOTS",cc.vec3(-2.5, sizeY* height,5.5 + 1.5), cc.vec3(0.0, 0.0,0.0), false) 
        local rigidBody = spriteSlot_3:getPhysicsObj()
        rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true

        ---------------------
        --左下二
        local spriteSlot_4 = self:createCoins( "SLOTS",cc.vec3(-5.8, sizeY* height,16 - 3 ), cc.vec3(0.0, 0.0,0.0), false) 
        local rigidBody = spriteSlot_4:getPhysicsObj()
        rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true


        ---------------------
        --右下二
        local spriteSlot_4 = self:createCoins( "SLOTS",cc.vec3(5.8, sizeY* height,16 - 3 ), cc.vec3(0.0, 0.0,0.0), false) 
        local rigidBody = spriteSlot_4:getPhysicsObj()
        rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true



        ---------------------
        --中1
        local spriteSlot_4 = self:createCoins( "SLOTS",cc.vec3(0, sizeY* height,16 - 3.5 ), cc.vec3(0.0, 0.0,0.0), false) 
        local rigidBody = spriteSlot_4:getPhysicsObj()
        rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为true


    
    
    
    elseif coinsShowType == 7 then
        --[[
            -个金币堆
        --]]
        local itemAtt  = Config.CoinModelAtt["NORMAL"]
        
        local height   = 1
        local sizeY    = itemAtt.PhysicSize.y + 0.4

        for i=1,height do

                local vec3List = self:getHexagonInfo(itemAtt,i,1.5)
        
                for j=1,#vec3List do
                    if j == 1 then
                        vec3List[j].y = sizeY * (i -1) + itemAtt.PhysicSize.y / 2
                        vec3List[j].z = vec3List[j].z - 20
                        -- vec3List[j].x = vec3List[j].x
                        local sprite = self:createCoins( "BIG", vec3List[j] , cc.vec3(0.0, 0.0,0.0), false) 
                        local rigidBody = sprite:getPhysicsObj()
                        -- rigidBody:setKinematic(true) -- 设置刚体不碰撞 置为 true
                    end   
                end
                
        end
    

    elseif coinsShowType == 8 then
        --[[
           金币雨效果模拟
        --]]
        self:playCoinsRainEffect( )

    elseif coinsShowType == 9 then

        --[[
           金币塔效果模拟
        --]]
        -- self:playCoinsTowerDrop( )

        self:playCoinsTowerPushTableCoins( )
   

    end

    
end



return GamePusherMainLayer