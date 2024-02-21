--[[
    GamePusherMain
    -- game推币机主界面
]]
local GamePusherManager   = require "CoinCircusSrc.GamePusherManager"
local Config              = require("CoinCircusSrc.GamePusherMain.GamePusherConfig")

local SYNC_DIRTY_DATA_TIME      =       2 --同步脏数据时间间隔

local GamePusherMain = class( "GamePusherMain",
    function() 
        return cc.Layer:create() 
    end
)

----------------------------------------------------------------------------------------
-- 框架(ctor, getInstance, onEnter, onExit)
----------------------------------------------------------------------------------------
function GamePusherMain:ctor(  )

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
    self.m_nEntityIndex   = 0                                                -- 动态实体全局索引    
    self.m_nEntityWin     = 0                                                -- 中奖的实体个数     
    self.m_nEntityLose    = 0                                                -- 丢失的实体个数     
    self.m_tEntityDropped = {                                                -- 掉落的细节统计     
            CoinWin  = {} ,                                                 
            CoinLose = {}  }   

    self.m_tLoseData = {}                                                    -- 掉落金币Lose信息
    self.m_tWinData  = {}                                                    -- 掉落金币win信息
        
    self.m_nBuffUpdataTime = Config.ComboFreshDt     
    self.m_nTapUpdateTime  = Config.TapUpdateTime
    self.m_bTapUpdateState = true


    self.m_nComboIndex = 0                                                   -- 普通金币掉落Combo计数
    self.m_nComboTimes = 0                                                   -- Combo重新计数间隔

    self.m_bPassStage    = false                                             -- 是否过关标志
    self.m_nAutoDropTime = 1                                                 
    self.m_bSoundNotPlay = true                                              -- 是否播放音效标志

    self.m_bPusherOver    = false 
    self.m_bOutLinePlayStates = false                                        -- 为了处理一进推币机时某些检测不应该生效的问题

    self.m_pGamePusherMgr = GamePusherManager:getInstance()                  -- Mgr对象
end

function GamePusherMain:onEnter(  )
    self:onRegistEvent()                                                     -- Register Even注册事件
    self:InitCamera()                                                        -- 初始化摄像机
    self:createStaticModel()                                                 -- 创建静态模型及碰撞体
    self:loadSceneEntityData()                                               -- 加载存储的场景数据并创建实体
    self:InitUI()                                                            -- 初始化MainUI
    self:InitEffect()                                                        -- 初始化特效管理器

    self.m_bSoundNotPlay  = false                                            -- 播放音乐bool
    self.m_pMainUI:setTouchState(true)
    self.m_pGamePusherMgr:reconnectionPlay()                                -- 断线重连
    self:initLifterStatus()                                                 -- 初始化buff状态
    
    self:onUpdate( function(dt)                                             -- 开启定时器
        self:Tick(dt)
    end)

    self:stopPusherAllAnim()                                      -- 初始化推币机时初始化各个模块的状态

    if Config.Debug == true then                                            -- 初始化调试面板
        self.m_pDebugLayer = require(Config.ViewPathConfig.Debug).new( self )
        self:addChild( self.m_pDebugLayer )
        self.m_pDebugLayer:InitDebugPro()
    end
end

function GamePusherMain:stopPusherAllAnim( )

    self:stopPushing()                  -- 设置推币机为停止状态 

end

function GamePusherMain:onExit(  )
    gLobalNoticManager:removeAllObservers(self)
end

----------------------------------------------------------------------------------------
-- 注册事件
----------------------------------------------------------------------------------------
-- 注：网络数据或者延时数据来处理界面 必须用事件来驱动 -
function GamePusherMain:onRegistEvent(  )
    

    gLobalNoticManager:addObserver( self,function(self, params)             -- 动画结束事件回调
        if params == Config.PopViewConfig.JACKPOT.Type then
            
        end

        end, Config.Event.GamePusherEffectEnd
    )


    gLobalNoticManager:addObserver( self,function(self, params)             -- 动画触发回调
        local playType = params[1]
        local data = params[2]
        if playType == Config.CoinEffectRefer.NORMAL then
            data:setActionState(Config.PlayState.DONE)
        elseif playType == Config.CoinEffectRefer.BIG then
            data:setActionState(Config.PlayState.DONE)
        elseif playType == Config.CoinEffectRefer.JACKPOT then

            data:setActionState(Config.PlayState.DONE)

        elseif playType == Config.CoinEffectRefer.RANDOM then
            self:randomDropCoins(data)                                             --随机奖励 币   
        elseif playType ==  Config.CoinEffectRefer.DROP then            
            self:playDropCoinsEffect(data)                                     --请求掉落金币
        end
        
        end, Config.Event.GamePusherTriggerEffect
    )
 
    gLobalNoticManager:addObserver( self,function(self, params)                -- 实体存档
        self:saveEntityData()
        end, Config.Event.GamePusherSaveEntity
    )
   
    gLobalNoticManager:addObserver( self,function(self, params)                -- 更新UI  放入MainUI中？
        self:updateMainUI()
        end, Config.Event.GamePusherUpdateMainUI
    )



    gLobalNoticManager:addObserver(                                            -- buff打开
        self,
        function(self, params)
            self.m_pGamePusherMgr:pubSaveCoinPusherDeskstopData(self:getSceneEntityData())
        end,
        Config.Event.GamePusherTestSaveData
    )

    gLobalNoticManager:addObserver( self,function(self, params)                -- 初始化更新新墙道具个数
        self.m_WallsLeftTimes = params.ntimes
        end, Config.Event.GamePusherMainUI_UpdateProp_Wall
    )
    
    gLobalNoticManager:addObserver( self,function(self, params)                -- 重置升降台位置
        self:restLifter( )
        end, Config.Event.GamePusherMainUI_Rest_WallPos
    )
   



end

----------------------------------------------------------------------------------------
-- 摄像机
----------------------------------------------------------------------------------------

-- Init Camera --
function GamePusherMain:InitCamera(  )
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

    self.m_v3LookAtOri     = cc.vec3( 0 , -4 , 15 *  nSaleAdapt )                                   -- 观察原点 --
    self.m_v3LookAtReel    = cc.vec3( 0 , 0  , 8 *  nSaleAdapt )                                    -- 观察滚轴 --
    -- self.m_v3LookAtReel.z  = self.m_v3LookAtReel.z
    self.m_v3CameraPosOri  = cc.vec3(0.0, self.m_nDistance - 0.618 + 1, self.m_nDistance + 16 )    -- 摄像机原位置 --
    self.m_v3CameraPosReel = cc.vec3(0.0, self.m_nDistance - 0.618  , self.m_nDistance - 1 )       -- 摄像机移动位置--

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

function GamePusherMain:setCameraPosData( _lookAtReel)
    if _lookAtReel then
        self.m_pCamera:setPosition3D(self.m_v3CameraPosReel)
        self.m_pCamera:lookAt( self.m_v3LookAtReel , cc.vec3(0.0, 1.0, 0.0))
    else
        self.m_pCamera:setPosition3D(self.m_v3CameraPosOri)
        self.m_pCamera:lookAt( self.m_v3LookAtOri , cc.vec3(0.0, 1.0, 0.0))
    end
    
end

-- Move Camera --
function GamePusherMain:MoveCamera(  nType , fTime  )
    self.m_nCameraType     = nType
    self.m_nCameraMoveTime = fTime

    self.m_nCameraYMoveTime = 2                  --向下移动的时间
    self.m_nRunTime = 0
    self.m_nCameraZMoveTime = 3                  --向前移动的时间
    self.m_nCameraCurMoveToSlotsWaitTime = 0     --向下移动完等待时间
    self.m_nCameraMoveToSlotsStep = 0            --动画步骤

    if nType == 1 then
        self.m_v3CurLookAt    = cc.vec3( self.m_v3LookAtOri.x    , self.m_v3LookAtOri.y     , self.m_v3LookAtOri.z    )
        self.m_v3CurCameraPos = cc.vec3( self.m_v3CameraPosOri.x , self.m_v3CameraPosOri.y  , self.m_v3CameraPosOri.z  )
        self:measureNode(true)
    elseif nType == 2 then
        self.m_v3CurLookAt    = cc.vec3( self.m_v3LookAtReel.x   , self.m_v3LookAtReel.y    , self.m_v3LookAtReel.z    )
        self.m_v3CurCameraPos = cc.vec3( self.m_v3CameraPosReel.x, self.m_v3CameraPosReel.y , self.m_v3CameraPosReel.z )
    elseif nType == 3 then 
        self.m_v3CurLookAt    = cc.vec3( self.m_v3LookAtOri.x    , self.m_v3LookAtOri.y     , self.m_v3LookAtOri.z    )
        self.m_v3CurCameraPos = cc.vec3( self.m_v3CameraPosOri.x , self.m_v3CameraPosOri.y  , self.m_v3CameraPosOri.z  )
    end
end

--变速动作用的测量节点
function GamePusherMain:measureNode(isPosY)
    if not self.m_pCurLookAtNode and not self.m_pCurCameraNode then 
        self.m_pCurLookAtNode = cc.Node:create()
        self.m_pCurCameraNode = cc.Node:create()
        self.m_pCurLookAtNode:setPosition(cc.vec3(self.m_v3LookAtOri.x, self.m_v3LookAtOri.y, self.m_v3LookAtOri.z))
        self.m_pCurCameraNode:setPosition(cc.vec3(self.m_v3CameraPosOri.x , self.m_v3CameraPosOri.y, self.m_v3CameraPosOri.z))
        self:addChild(self.m_pCurLookAtNode)
        self:addChild(self.m_pCurCameraNode)
    end

    local actMoveLookAt = nil 
    local actMoveCamera = nil

    local actMoveLookAtCallFunc = nil
    local actMoveCameraCallFunc = nil

    local actMoveLookAtDelayTime = nil
    local actMoveCameraDelayTime = nil
    if isPosY then 
        actMoveLookAt = cc.MoveBy:create(2,cc.vec3(0, self.m_v3LookAtReel.y - self.m_v3LookAtOri.y, 0))
        actMoveCamera = cc.MoveBy:create(2,cc.vec3(0, self.m_v3CameraPosReel.y - self.m_v3CameraPosOri.y, 0))

        actMoveLookAtCallFunc = cc.CallFunc:create(function(  )
            self.m_pCamera:lookAt( self.m_v3LookAtReel , cc.vec3(0.0, 1.0, 0.0))
        end)
        actMoveCameraCallFunc = cc.CallFunc:create(function(  )
            self.m_pCamera:setPosition3D(self.m_v3CameraPosReel)
        end)
    else
        self.m_nLookAtLastPosZ = self.m_pCurLookAtNode:getPositionZ()
        self._cameraLastPosZ = self.m_pCurCameraNode:getPositionZ()
        actMoveLookAt = cc.MoveBy:create(3,cc.vec3(0, 0, self.m_v3LookAtReel.z - self.m_v3LookAtOri.z))
        actMoveCamera = cc.MoveBy:create(3,cc.vec3(0, 0, self.m_v3CameraPosReel.z - self.m_v3CameraPosOri.z))

        actMoveLookAtDelayTime = cc.DelayTime:create(2)
        actMoveCameraDelayTime = cc.DelayTime:create(3)

        actMoveLookAtCallFunc = cc.CallFunc:create(function(  )
            self.m_pCamera:lookAt( self.m_v3LookAtOri , cc.vec3(0.0, 1.0, 0.0))
        end)
        actMoveCameraCallFunc = cc.CallFunc:create(function(  )
            self.m_pCamera:setPosition3D(self.m_v3CameraPosOri)
        end)

    end

    local actEQLookAt  = cc.EaseQuinticActionOut:create(cc.Sequence:create(actMoveLookAt,actMoveLookAtDelayTime,actMoveLookAtCallFunc) )
    local actEQOCamera = cc.EaseQuinticActionOut:create( cc.Sequence:create(actMoveCamera,actMoveCameraDelayTime,actMoveCameraCallFunc) )
   
    self.m_pCurLookAtNode:stopAllActions()
    self.m_pCurCameraNode:stopAllActions()
    self.m_pCurLookAtNode:runAction(actEQLookAt)
    self.m_pCurCameraNode:runAction(actEQOCamera)
end

--测量节点移除
function GamePusherMain:removeMeasureNode()
    self.m_pCurLookAtNode:stopAllActions()
    self.m_pCurCameraNode:stopAllActions()
    self.m_pCurLookAtNode:removeFromParent()
    self.m_pCurCameraNode:removeFromParent()
    self.m_pCurLookAtNode = nil 
    self.m_pCurCameraNode = nil
end

--移动相机到老虎机下降阶段
function GamePusherMain:moveCameraToSlotsDown(dt)
    if self.m_nCameraMoveToSlotsStep == 0 then
        self.m_nRunTime = self.m_nRunTime + dt
        local moveStep = 0
        local lookAtCurPosY = self.m_pCurLookAtNode:getPositionY()
        self.m_v3CurLookAt.y = lookAtCurPosY
        if self.m_v3CurLookAt.y >= self.m_v3LookAtReel.y or self.m_nCameraYMoveTime <= self.m_nRunTime then
            self.m_v3CurLookAt.y = self.m_v3LookAtReel.y
            moveStep = moveStep + 1
        end
        
        local cameraCurPosY = self.m_pCurCameraNode:getPositionY()
        self.m_v3CurCameraPos.y = cameraCurPosY
        if self.m_v3CurCameraPos.y <= self.m_v3CameraPosReel.y or self.m_nCameraYMoveTime <= self.m_nRunTime then
            self.m_v3CurCameraPos.y = self.m_v3CameraPosReel.y
            moveStep = moveStep + 1
        end

        --切换到前进阶段
        if moveStep == 2 then
            self.m_nCameraMoveToSlotsStep = 1
        end
    end
end

--移动相机到老虎机等待阶段
function GamePusherMain:moveCameraToSlotsWait(dt)
    if self.m_nCameraMoveToSlotsStep == 1 then
        self.m_nCameraCurMoveToSlotsWaitTime = self.m_nCameraCurMoveToSlotsWaitTime or 0
        self.m_nCameraCurMoveToSlotsWaitTime = self.m_nCameraCurMoveToSlotsWaitTime + dt
        if self.m_nCameraCurMoveToSlotsWaitTime >= 0.1 then
            self.m_nCameraCurMoveToSlotsWaitTime = 0
            self.m_nCameraMoveToSlotsStep = 2
            self.m_nRunTime = 0
            self:measureNode(false)
        end
    end
end

--移动相机到老虎机前进阶段
function GamePusherMain:moveCameraToSlotsFront(dt)
    if self.m_nCameraMoveToSlotsStep == 2 then
        self.m_nRunTime = self.m_nRunTime + dt
        local moveStep = 0

        local lookAtCurPosZ = self.m_pCurLookAtNode:getPositionZ()
        self.m_v3CurLookAt.z = self.m_v3CurLookAt.z + (lookAtCurPosZ - self.m_nLookAtLastPosZ)
        self.m_nLookAtLastPosZ = lookAtCurPosZ
        if self.m_v3CurLookAt.z <= self.m_v3LookAtReel.z or self.m_nCameraZMoveTime <= self.m_nRunTime then
            self.m_v3CurLookAt.z = self.m_v3LookAtReel.z
            moveStep = moveStep + 1
        end

        local cameraCurPosZ = self.m_pCurCameraNode:getPositionZ()
        self.m_v3CurCameraPos.z = self.m_v3CurCameraPos.z + (cameraCurPosZ - self._cameraLastPosZ)
        self._cameraLastPosZ = cameraCurPosZ
        if self.m_v3CurCameraPos.z <= self.m_v3CameraPosReel.z or self.m_nCameraZMoveTime <= self.m_nRunTime then
            self.m_v3CurCameraPos.z = self.m_v3CameraPosReel.z
            moveStep = moveStep + 1
        end

        --结束
        if moveStep == 2 then
            self.m_nCameraType = 0
            self.m_nCameraMoveToSlotsStep = 0
            self:removeMeasureNode()
        end
    end
end

-- Camrea actions --
function GamePusherMain:CameraTick( dt )

    if self.m_nCameraType == 0 then
        -- do nothing --
    elseif self.m_nCameraType == 1 then
        self:moveCameraToSlotsDown(dt)
        self:moveCameraToSlotsWait(dt)
        self:moveCameraToSlotsFront(dt)
        self.m_pCamera:lookAt(self.m_v3CurLookAt, cc.vec3(0.0, 1.0, 0.0))
        self.m_pCamera:setPosition3D(self.m_v3CurCameraPos)
    elseif self.m_nCameraType == 2 then
        -- move look at to reel --
        self.m_v3CurLookAt.y = self.m_v3CurLookAt.y - ( self.m_v3LookAtReel.y - self.m_v3LookAtOri.y ) / self.m_nCameraMoveTime * dt
        self.m_v3CurLookAt.z = self.m_v3CurLookAt.z - ( self.m_v3LookAtReel.z - self.m_v3LookAtOri.z ) / self.m_nCameraMoveTime * dt
        local moveStep = 0
        if self.m_v3CurLookAt.y < self.m_v3LookAtOri.y then
            self.m_v3CurLookAt.y = self.m_v3LookAtOri.y
            moveStep = moveStep + 1
        end
        if self.m_v3CurLookAt.z > self.m_v3LookAtOri.z then
            self.m_v3CurLookAt.z = self.m_v3LookAtOri.z
            moveStep = moveStep + 1
        end
        self.m_pCamera:lookAt( self.m_v3CurLookAt, cc.vec3(0.0, 1.0, 0.0))

        -- move camera postion --
        self.m_v3CurCameraPos.y = self.m_v3CurCameraPos.y - ( self.m_v3CameraPosReel.y - self.m_v3CameraPosOri.y ) / self.m_nCameraMoveTime * dt
        self.m_v3CurCameraPos.z = self.m_v3CurCameraPos.z - ( self.m_v3CameraPosReel.z - self.m_v3CameraPosOri.z ) / self.m_nCameraMoveTime * dt
        if self.m_v3CurCameraPos.y > self.m_v3CameraPosOri.y then
            self.m_v3CurCameraPos.y = self.m_v3CameraPosOri.y
            moveStep = moveStep + 1
        end
        if self.m_v3CurCameraPos.z > self.m_v3CameraPosOri.z then
            self.m_v3CurCameraPos.z = self.m_v3CameraPosOri.z 
            moveStep = moveStep + 1
        end
        self.m_pCamera:setPosition3D( self.m_v3CurCameraPos )

        if moveStep == 4 then
            self.m_pMainUI:setEffectStop(false)
            self.m_nCameraType = 0
            self:setCameraPosData( )
        end 
    elseif self.m_nCameraType == 3 then
        -- move look at to reel --
        self.m_v3CurLookAt.y = self.m_v3CurLookAt.y + ( self.m_v3LookAtReel.y - self.m_v3LookAtOri.y ) / self.m_nCameraMoveTime * dt
        self.m_v3CurLookAt.z = self.m_v3CurLookAt.z + ( self.m_v3LookAtReel.z - self.m_v3LookAtOri.z ) / self.m_nCameraMoveTime * dt
        local moveStep = 0
        if self.m_v3CurLookAt.y > self.m_v3LookAtReel.y then
            self.m_v3CurLookAt.y = self.m_v3LookAtReel.y
            moveStep = moveStep + 1
        end
        if self.m_v3CurLookAt.z < self.m_v3LookAtReel.z then
            self.m_v3CurLookAt.z = self.m_v3LookAtReel.z
            moveStep = moveStep + 1
        end
        self.m_pCamera:lookAt( self.m_v3CurLookAt, cc.vec3(0.0, 1.0, 0.0))

        -- move camera postion --
        self.m_v3CurCameraPos.y = self.m_v3CurCameraPos.y + ( self.m_v3CameraPosReel.y - self.m_v3CameraPosOri.y ) / self.m_nCameraMoveTime * dt
        self.m_v3CurCameraPos.z = self.m_v3CurCameraPos.z + ( self.m_v3CameraPosReel.z - self.m_v3CameraPosOri.z ) / self.m_nCameraMoveTime * dt
        if self.m_v3CurCameraPos.y < self.m_v3CameraPosReel.y then
            self.m_v3CurCameraPos.y = self.m_v3CameraPosReel.y
            moveStep = moveStep + 1
        end
        if self.m_v3CurCameraPos.z < self.m_v3CameraPosReel.z then
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
function GamePusherMain:CameraQuake(  )
    
    local actions   = {}
    local move_up   = cc.MoveBy:create( 0.05 , cc.p( 0, 1 ,0 ) )
    actions[#actions + 1] = move_up
    local move_down = cc.MoveBy:create( 0.05 , cc.p( 0, -1.5 , 0)  )
    actions[#actions + 1] = move_down
    local move_back = cc.MoveBy:create( 0.05 , cc.p( 0, 0.5 , 0)  )
    actions[#actions + 1] = move_back

    local seq = cc.Sequence:create( actions )
    self.m_pCamera:runAction(seq)

end

-- 3D世界坐标转屏幕2d坐标(屏幕坐标系:原点在屏幕左上角，x轴向右，y轴向下)
function GamePusherMain:Convert3DToScreen2D(vec3Pos)
    local uiPos = self.m_pCamera:project(vec3Pos)
    return uiPos
end

-- 3D世界坐标转OpenGL2d坐标(OpenGL坐标系:该坐标系原点在屏幕左下角，x轴向右，y轴向上)
function GamePusherMain:Convert3DToGL2D(vec3Pos)
    local uiPos = self.m_pCamera:projectGL(vec3Pos)
    return uiPos
end

----------------------------------------------------------------------------------------
-- 推币机 道具
----------------------------------------------------------------------------------------
-- Create CoinPuhserCoins --
function GamePusherMain:createCoins( _sType , _vPos , _vRot , _bCollision)
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
                self:bigCoinCollision( colBMask )
            end
        end)
    end
   
    return sprite
end

-- 金币刚体信息 ps: 六棱柱 
function GamePusherMain:getCoinShapeInfo(_itemAtt)
    
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
function GamePusherMain:createItem( nIndex , vPos , vRot )

   
end

function GamePusherMain:createFloorBackModel(vSize, vPos)

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
function GamePusherMain:createFloorForntModel(vSize, vPos)

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

function GamePusherMain:createFloorBorderModel(vSize, vPos)

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

function GamePusherMain:createFloorMiddleModel(vSize, vPos)

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
function GamePusherMain:createStaticModel(  )
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
                rigidBody:setCollisionCallback(function (collisionInfo)
                    if nil ~= collisionInfo.collisionPointList and #collisionInfo.collisionPointList > 0 then
                        local colAMask = collisionInfo.objA:getMask()
                        local colBMask = collisionInfo.objB:getMask()
                        self:bigCoinCollision( colBMask )
                        self:smallCoinCollision( colBMask )
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
        -- 左后斜板 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 10.5, 20.0, 1))
        localTrans = cc.mat4.createRotation(cc.vec3(0.0, 1.0, 0.0), 30.0 * math.pi / 180)
        localTrans[13] = -11.4
        localTrans[14] = -15
        localTrans[15] = 5
        table.insert(shapeList, {bodyshape, localTrans})
        -- 右后正板 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 8.5, 20.0, 19.5))
        localTrans = cc.mat4.createTranslation( 10.8, -15 , -7 )
        table.insert(shapeList, {bodyshape, localTrans})
        -- 右后斜板 --
        bodyshape  = cc.Physics3DShape:createBox(cc.vec3( 10.5, 20.0, 1))
        localTrans = cc.mat4.createRotation(cc.vec3(0.0, 1.0, 0.0), -30.0 * math.pi / 180)
        localTrans[13] = 11.4
        localTrans[14] = -15
        localTrans[15] = 5
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
        
        rigidBody:setCollisionCallback(function (collisionInfo)
            if nil ~= collisionInfo.collisionPointList and #collisionInfo.collisionPointList > 0 then
                local colAMask = collisionInfo.objA:getMask()
                local colBMask = collisionInfo.objB:getMask()
                self:smallCoinCollision( colBMask )
            end
        end)
    end
    
    -- Create machine pusher --
    if Config.PlatformModelAtt.Pusher then
        local itemAtt = Config.PlatformModelAtt.Pusher
        local rbDes = {}
        rbDes.mass  = itemAtt.Mass
        local scale = itemAtt.Scale

        local shapeList = {}

        local bodyshape  = cc.Physics3DShape:createBox(cc.vec3(14.0, 40.0, 3.5))
        local localTrans = cc.mat4.createTranslation(0.0, -23.8, 0 )
        table.insert(shapeList, {bodyshape, localTrans})
        rbDes.shape = cc.Physics3DShape:createCompoundShape(shapeList)

        self.m_pSp3DPusher = cc.PhysicsSprite3D:create( itemAtt.Model , rbDes )
        self.m_pSp3DPusher:setCameraMask(cc.CameraFlag.USER1)
        local rigidBody = self.m_pSp3DPusher:getPhysicsObj()
        rigidBody:setKinematic(true)
        rigidBody:setFriction( 0.8 )
        rigidBody:setRestitution(Config.BackPushRestitution)

        self:addChild(self.m_pSp3DPusher)
        self.m_pSp3DPusher:setScale( itemAtt.Scale )
        self.m_pSp3DPusher:setRotation3D(cc.vec3(-90.0, 180.0,  0.0))
        self.m_pSp3DPusher:setPosition3D(cc.vec3(0.0, 0.0, -12.5 ))

        self.m_v3PusherPosOri  = cc.vec3(0.0, 0.0, -12.5 )
        self.m_v3PusherPosDest = Config.PusherDisVec3.ORI
        self.m_bPusherPushing  = true 
        self.m_nPusherStatus   = 1
        self.m_nPusherSpeed    = Config.PusherSpeed


        rigidBody:setCollisionCallback(function (collisionInfo)
            if nil ~= collisionInfo.collisionPointList and #collisionInfo.collisionPointList > 0 then
                local colAMask = collisionInfo.objA:getMask()
                local colBMask = collisionInfo.objB:getMask()
                self:smallCoinCollision( colBMask )
            end
        end)

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

        -- 添加碰撞监测函数 --
        rigidBody:setCollisionCallback(function (collisionInfo)
            if nil ~= collisionInfo.collisionPointList and #collisionInfo.collisionPointList > 0 then

                local colAMask = collisionInfo.objA:getMask()
                local colBMask = collisionInfo.objB:getMask()

                self:itemDropped( Config.EntityDropType.LOSE, colBMask )
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

        -- 添加碰撞监测函数 --
        rigidBody:setCollisionCallback(function (collisionInfo)
            if nil ~= collisionInfo.collisionPointList and #collisionInfo.collisionPointList > 0 then

                local colAMask = collisionInfo.objA:getMask()
                local colBMask = collisionInfo.objB:getMask()

                self:itemDropped( Config.EntityDropType.WIN , colBMask )
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

----------------------------------------------------------------------------------------
-- 推币机碰撞触发事件
----------------------------------------------------------------------------------------
--桌面碰撞
function GamePusherMain:bigCoinCollision( nItemIndex )
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

function GamePusherMain:smallCoinCollision( nItemIndex )
    local colNode = self.m_tEntityList[nItemIndex]
    if colNode and  not colNode.Collision then
        if colNode.ID == Config.CoinModelAtt.NORMAL.Name then
            colNode.Collision = true
            --音效
            self:playSound(Config.SoundConfig.NORMALCOINDOWN)
            --小金币掉落下来碰撞
        end
    end
end


-- 道具掉落处理 --
function GamePusherMain:itemDropped( sWinType , nItemIndex )
    if not self.m_bOutLinePlayStates then
        return
    end

    if self.m_bPusherOver then
        --推币机是结束状态掉掉币也不生效
        return
    end
    local colNode = self.m_tEntityList[nItemIndex]
    print("sWinType " .. sWinType ..  " nItemIndex ".. nItemIndex)
    if colNode ~= nil then
     

        local sType = colNode.Type
        local nID   = colNode.ID

        local vPos  = colNode.Node:getPosition3D()
        local vPos2d = self:Convert3DToGL2D(vPos)

        -- Remove Render Node --
        colNode.Node:setVisible(false)
        self.m_pPhysicsWorld:removePhysics3DObject(colNode.Node:getPhysicsObj())          
        self.m_tEntityList[nItemIndex] = nil
        --存档一次
        self:saveEntityData()

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode, function(  )
            -- self:pushCoinSpriteToPool( colNode.Node)
            if not tolua.isnull(colNode.Node) then
                colNode.Node:removeFromParent()
            end
            waitNode:removeFromParent()
        end,0.1)
     
        if sWinType == Config.EntityDropType.WIN then

            self.m_pGamePusherMgr:dropFromTable(nID)

            if not  self.m_tWinData[nID] then
                self.m_tWinData[nID] = 1
            else
                self.m_tWinData[nID] = self.m_tWinData[nID] + 1
            end
            --Combo
            self.m_nComboIndex = self.m_nComboIndex + 1        
            if  self.m_nComboIndex  > 6 then
                self.m_nComboIndex = 6
            end
            self.m_nComboTimes = 0
            
            if not self.m_bPassStage then
                if nID == Config.CoinModelRefer.JACKPOT 
                or nID == Config.CoinModelRefer.RANDOM 
                or nID == Config.CoinModelRefer.BIG then
                    self:playSound(Config.SoundConfig.SPECIAL_PUSH_DOWN)
                    self:playSpecialCoinDropEffect(nil, vPos2d, nID)
                else
                    self:playSound(Config.SoundConfig.COIN_PUSH_DOWN)
                    self:playNormalCoinDropEffect(self.m_nComboIndex, vPos2d)
                end
                
                self.m_pMainUI:playCoinWinDropEffect(cc.p(vPos2d.x, 0), nID)
            end

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
        end
    end
end

function GamePusherMain:updataSendDropMsg(dt)

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

            if self.m_pGamePusherMgr:checkPusherPropUseUp( ) then -- 判断道具是否为0
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
function GamePusherMain:sendDropMsg()

    -- 判断是否发送结束消息

    
        self.m_bPusherOver  = true -- 设置当前为结束状态
        -- 发送结束消息
        self.m_pGamePusherMgr:requestBonusPusherOverNetData()

   


end

----------------------------------------------------------------------------------------
-- 推币机Action 升降台  底板震动  道具震动
----------------------------------------------------------------------------------------
-- 推币机 动作逻辑 --
function GamePusherMain:pusherTick( _nDt )
    if self.m_nPusherStatus == 1 then
        -- IDLE --
        if self.m_bPusherPushing == true then
            self.m_nPusherStatus =  2
        end
    elseif self.m_nPusherStatus == 2 then
        -- Push --
        local curPos = self.m_pSp3DPusher:getPosition3D()
        curPos.z = curPos.z + self.m_nPusherSpeed * _nDt
        if curPos.z > self.m_v3PusherPosDest.z then
            curPos.z = self.m_v3PusherPosDest.z
            self.m_nPusherStatus = 3
        end
        
        self.m_pSp3DPusher:setPosition3D( curPos )
    elseif self.m_nPusherStatus == 3 then
        -- Pull --
        local curPos = self.m_pSp3DPusher:getPosition3D()
        curPos.z = curPos.z - self.m_nPusherSpeed * _nDt
        if curPos.z < self.m_v3PusherPosOri.z then
            curPos.z = self.m_v3PusherPosOri.z
            self.m_nPusherStatus = 1
        end
        self.m_pSp3DPusher:setPosition3D( curPos )
    end
end

-- 设置推币机是否动作 --
function GamePusherMain:setPusherRunning( bRunning )
    self.m_bPusherPushing = true --bRunning
end

-- 升降台重置位置
function GamePusherMain:restLifter( )
    self.m_bLifterUp = false 
    self.m_nLifterStatus = 1
    self.m_pSp3DLifter:setPosition3D( self.m_v3LifterPosOri )
    self.m_pSp3DLifter:setVisible(false)
end

-- 升降台 动作逻辑 --
function GamePusherMain:lifterTick( dt )
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
function GamePusherMain:setLifterStatus( nStatus )
    self.m_nLifterStatus = nStatus
end

function GamePusherMain:getLifterStatus()
    return self.m_nLifterStatus
end

function GamePusherMain:setPusherPosDestPos( vec3 )
    self.m_v3PusherPosDest = vec3
end

function GamePusherMain:getPusherPosDestPos()
    return self.m_v3PusherPosDest
end

-- 设置推币台状态状态 --
function GamePusherMain:setm_nPusherStatus( nStatus )
    self.m_nPusherStatus = nStatus
end

-- 初始化Pusher数据 --
function GamePusherMain:resetPusherAtt( vPos  )
    self.m_pSp3DPusher:setPosition3D( vPos )
    self.m_nPusherStatus = 1
    self.m_bPusherPushing= true
end

-- 底板震动效果 --
function GamePusherMain:floorQuake(  )
    for i=1,#self._tbFloors do
        local sprite3D = self._tbFloors[i][1]
        local actions   = {}
        local move_up   = cc.MoveBy:create( 0.05 , cc.p( 0, 2 ,0 ) )
        actions[#actions + 1] = move_up
        local move_back = cc.MoveBy:create( 0.05 , cc.p( 0, -2 , 0)  )
        actions[#actions + 1] = move_back
    
        local seq = cc.Sequence:create( actions )
        sprite3D:runAction(seq)
    end

end

-- 道具振起效果 --
function GamePusherMain:itemsQuake( fForce )
    for k,entity in pairs( self.m_tEntityList ) do
        
        if not tolua.isnull( entity.Node ) then
            local rigidBody = entity.Node:getPhysicsObj()
            rigidBody:setActive( true )
            rigidBody:setLinearVelocity(  cc.vec3( math.random(-2,2),math.random(5,fForce),math.random(0,2) ) )
            rigidBody:setAngularVelocity( cc.vec3( math.random(0,5), math.random(0,5), math.random(0,5) ))
        end
    end
end

-- buff检测
function GamePusherMain:updateBuffState(_nDt)

    self.m_nBuffUpdataTime = self.m_nBuffUpdataTime + _nDt

    if self.m_nBuffUpdataTime < Config.BuffUpdateTime then
        return 
    end

    local upWallsLT = self.m_pGamePusherMgr:getBuffUpWallsLT()
    local pusherLT  = self.m_pGamePusherMgr:getBuffPusherLT()
    local prizeLT   = self.m_pGamePusherMgr:getBuffPrizeLT()

    if upWallsLT and upWallsLT > 0 then

        
        if not self.m_bLifterUp then

            
            if self:getLifterStatus() == 1 then

                local playPropData = {}
                playPropData.nAnimName = "start"
                playPropData.nIsLoop = false
                gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayProp_WallLoadingAni,playPropData) 

                self.m_WallsLeftTimes = upWallsLT

                self:setLifterStatus(2)
                gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_WallUp.mp3")


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
            self.m_pGamePusherMgr:upDataPropWallTimes(self.m_WallsLeftTimes )
        end
     
    else

        self.m_WallsLeftTimes = nil

        if self.m_bLifterUp then
            if self:getLifterStatus() == 1 then

                local playPropData = {}
                playPropData.nAnimName = "over"
                playPropData.nIsLoop = false
                gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayProp_WallLoadingAni,playPropData) 
    
                self:setLifterStatus(3)
            end  
            self.m_bLifterUp = false 
        end
    end

    if pusherLT and pusherLT > 0 then
        if self:getPusherPosDestPos() ~= Config.PusherDisVec3.PUSHER then
            self:setPusherPosDestPos(Config.PusherDisVec3.PUSHER)
        end
    elseif self:getPusherPosDestPos() ~= Config.PusherDisVec3.ORI then
        self:setPusherPosDestPos(Config.PusherDisVec3.ORI)
    end

    self.m_nBuffUpdataTime = 0
    self.m_pMainUI:setBuffState(upWallsLT > 0 or pusherLT > 0 or prizeLT > 0)

end

-- 初始化两边台子 
function GamePusherMain:initLifterStatus()
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
function GamePusherMain:updateTapState(_nDt)
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


----------------------------------------------------------------------------------------
-- update Tick 
----------------------------------------------------------------------------------------
-- Tick --
function GamePusherMain:Tick( dt )
    
    -- 摄像机逻辑 --
    self:CameraTick( dt )
    
    -- Pusher推币逻辑 --
    self:pusherTick( dt )

    -- Lifter升降台逻辑
    self:lifterTick( dt )

    -- 特效逻辑 --
    self:effectTick( dt )

    --  玩法逻辑  -- 
    self.m_pGamePusherMgr:playTick(dt)

    if self.m_bTapUpdateState then -- 开始游戏时才走检查buff剩余时间的逻辑
        -- 更新buff 逻辑
        self:updateBuffState(dt)
    end
    
 
    -- combo 重置时间
    self:updateComboTime(dt)

    -- taphere 提示时间
    self:updateTapState(dt)

   
    if self.m_bTapUpdateState then -- 开始游戏时才走判断结束的逻辑
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

function GamePusherMain:restSendDt( )
    if self.m_nSendDt then
        self.m_nSendDt = nil 
    end
end

----------------------------------------------------------------------------------------
--init item
----------------------------------------------------------------------------------------
-- 场景实体数据获取 --
function GamePusherMain:getSceneEntityData(  )
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
function GamePusherMain:randomInitDisk()
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
function GamePusherMain:loadSceneEntityData(  )
    
    local entityData = self.m_pGamePusherMgr:pubGetEntityData()

    -- 初始化推台 --
    if entityData and entityData.Pusher then
        -- self:resetPusherAtt( entityData.Pusher.Pos )

        self.m_nPusherStatus  = entityData.Pusher.Status
        self.m_bPusherPushing = true

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
function GamePusherMain:InitUI(  )

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
        if eventType == ccui.TouchEventType.ended then
            local endPos = sender:getTouchEndPosition()

            --这里加一个限定 当推币机推动时候允许点击 
            if  self.m_bTapUpdateState  then
                self:touchNodeRequestCoinsDrop(sender, endPos)
            end
        end
    end )
    
    self:initMainUI()

end

-- 向服务器请求需要掉落什么金币
function GamePusherMain:touchNodeRequestCoinsDrop(sender, vEndPos)
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
function GamePusherMain:initMainUI()
    self.m_pMainUI = util_createView(Config.ViewPathConfig.MainUI, { machine = self.m_machine})
    self:addChild(self.m_pMainUI)
end

-- 更新UI界面
function GamePusherMain:updateMainUI()

end

----------------------------------------------------------------------------------------
-- 特效逻辑
----------------------------------------------------------------------------------------
-- 初始化特效管理模块 --
function GamePusherMain:InitEffect(  )

    self.m_pEffectRoot = require(Config.ViewPathConfig.Effect).new( self )
    self:addChild( self.m_pEffectRoot )
    self.m_pEffectRoot:setPosition3D( cc.vec3(0,0,0) )

    self:PlayEffect( Config.Effect.FlashLight.ID )
    self:PlayEffect( Config.Effect.FrontEffectPanel.ID , nil , "Idle" )


    self.m_pEffectRoot:initDropEffect()

end

-- 播放特效接口 --
function GamePusherMain:PlayEffect( nType , pCall , sStatus )
    if self.m_pEffectRoot == nil then
        return
    end
    self.m_pEffectRoot:playEffect( nType , pCall , sStatus )
end

-- 特效步进逻辑 --
function GamePusherMain:effectTick( dt )
    if self.m_pEffectRoot == nil then
        return
    end
    self.m_pEffectRoot:tickEffect( dt )
end

----------------------------------------------------------------------------------------
--推币机掉落Combo
----------------------------------------------------------------------------------------

function  GamePusherMain:playNormalCoinDropEffect(comboIndex,pos)
    self:playSound(Config.SoundConfig.COMBO)
    self.m_pMainUI:playComboEffect(comboIndex, pos)
end

--特殊金币掉落动画
function  GamePusherMain:playSpecialCoinDropEffect(comboIndex,pos,id)
    self:playSound(Config.SoundConfig.COMBO)
    self.m_pMainUI:playSpecialCoinRewardEffect(comboIndex, pos,id)
end


function  GamePusherMain:updateComboTime(dt)
    self.m_nComboTimes = self.m_nComboTimes + dt
    if self.m_nComboTimes >= Config.ComboFreshDt then
        self.m_nComboTimes = Config.ComboFreshDt
        self.m_nComboIndex = 0
    end
end

----------------------------------------------------------------------------------------
--推币机触发玩法
----------------------------------------------------------------------------------------
function GamePusherMain:dropBigCoins(_count,_func)

    local count = _count
    for i=1,count do
        self:playSound(Config.SoundConfig.BIG_COIN_DOWN)
        self:createCoins( "BIG" , cc.vec3(math.random(-5,5), 10.0, -10.0), Config.BigCoinRotate)
    end

    self:saveEntityData()
        
    if _func then
        _func()
    end

end

function GamePusherMain:playHammerEffect(data)

    local hammerFunction = function (  )
        self:itemsQuake( 30 )
        self:CameraQuake()
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode, function(  )

            self.m_pSlotData:reduceEffectDataCount(Config.SlotEffectRefer.HAMMER)
            self.m_pGamePusherMgr:saveRunningData()

            performWithDelay(waitNode, function(  )
                self:playHammerEffect()    
                waitNode:removeFromParent()
            end,1.5)  
        end,0.5)  
        
    end
    self:playSound(Config.SoundConfig.HAMMER_DOWN)
    self:PlayEffect( 1 , hammerFunction )

end

function GamePusherMain:playDropCoinsEffect(data)
    local actionData = data:getActionData()
    local dropCoins = actionData[1]
    local dropInfo = actionData[2]
    local delayTime = 0
    for i,v in pairs(dropCoins) do
        local sType = tostring(i)
        for j = 1, v do
            local v3Rotate = Config.randomCoinRotate()
            if sType ~= Config.CoinModelRefer.NORMAL then
                --不为普通金币播放 动画
                self.m_pEffectRoot:playDropEffect()                
                self:playSound(Config.SoundConfig.SEPCIAL_COIN_DOWN)
                self:createCoins( tostring(i), Config.SpecialCoinV3, v3Rotate) 
            else      
                self:createCoins( tostring(i), dropInfo.entityPos, v3Rotate)          
            end
            data:reduceCoinsCount(tostring(i))
        end
    end
    self.m_pEffectRoot:stopTaphereEffect()
    self.m_nTapUpdateTime = 0
    self:saveEntityData()
    data:setActionState(Config.PlayState.DONE)
end

function GamePusherMain:showPassStageView(  )
    
end

----------------------------------------- trigger game  Play Function E-----------------------------------------


----------------------------------------- add GAME COIN  Function S   --------------------------------------------
function  GamePusherMain:showRewardLayer(data, path)
    self:stopPushing()
    self.m_tPlayData = data
    self.m_pMainUI:showRewardLayer(path)
    self:playSound(Config.SoundConfig.REWARD)
end

function GamePusherMain:palyRewardEnd()
    self:startPushing()
    self.m_tPlayData:setActionState(Config.PlayState.DONE)
end
----------------------------------------- add GAME COIN  Function E   --------------------------------------------

----------------------------------------- randomDropCion  Function S   -------------------------------------------
function GamePusherMain:randomDropCoins(_pData)
    local data = _pData:getEffectDatas()
    for k,v in pairs(data) do
        for i=1,v do
            self:createCoins( tostring(k) , Config.SpecialCoinV3, Config.randomCoinRotate())
            _pData:reduceEffectDataCount(tostring(k))
        end
    end
end

----------------------------------------- randomDropCion  Function E   -------------------------------------------

function GamePusherMain:stopPushing()
    self.m_bPusherOver    = true 
    self.m_bTapUpdateState = false  -- 停止tap
    self.m_bPusherPushing = true
    -- self.m_nPusherStatus = 3
end

function GamePusherMain:startPushing()
    self.m_bPusherOver    = false 
    self.m_bTapUpdateState = true  -- 停止tap
    self.m_bPusherPushing = true
    self.m_bOutLinePlayStates = true
    -- self.m_nPusherStatus = 1
end

----------------------------------------------------------------------------------------
-- 音 效
----------------------------------------------------------------------------------------
function GamePusherMain:playSound(_soundName)
    if not self.m_bSoundNotPlay  then
        gLobalSoundManager:playSound(_soundName)
    end
end
----------------------------------------------------------------------------------------

function GamePusherMain:stopAllEntity()

    for k,v in pairs(self.m_tEntityList) do
        local colNode = v
        if colNode ~= nil then
            self.m_pPhysicsWorld:removePhysics3DObject(colNode.Node:getPhysicsObj())  
        end
    end
end

function GamePusherMain:saveEntityData(_isFlush)
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

----------------------------------------------------------------------------------------
--推币机Debug And Log
----------------------------------------------------------------------------------------

function GamePusherMain:updataAutoDrop(dt)
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

function GamePusherMain:testLog()
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

function GamePusherMain:initDesktopDebugLayer()
    self.m_pDesktopLayer = util_createView(Config.ViewPathConfig.DesktopDebug, self)
    self.m_pDesktopLayer:setPosition(display.width/2, display.height)
    self:addChild(self.m_pDesktopLayer)
end

function GamePusherMain:removeDesktopDebugLayer()
    if self.m_pDesktopLayer then
        self.m_pDesktopLayer:removeFromParent()
        self.m_pDesktopLayer = nil
    end
end


function GamePusherMain:randomSetDesktop(pushCoins)

    self.m_coinsShowType = self.m_coinsShowType + 1

    if self.m_coinsShowType > 5 then
        self.m_coinsShowType = 1
    end

    local coinsShowType = 5 --self.m_coinsShowType

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


            -- 第二层
            for iX=1,3 do
                local addiX = 0.08 * iX
                for iY=1,3 do
                    local coinsType = "NORMAL"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * sizeX  - (iY * 1) - skewX + addX / 2
                    local posY = 0.7400004863739 + sizeY
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
                    local posY = 0.7400004863739 + sizeY * 2
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
                    local posY = 0.7400004863739 + sizeY * 3
                    local PosZ = (iY + 2.5) * sizeX - addiX - skewZ
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 
            end


        for iX=1,3 do
            local addiX = 0.08 * iX
            for iY=1,1 do
                local coinsType = "RANDOM"
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

        for iX=1,2 do
            local addiX = 0.08 * iX
            for iY=1,1 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX + 2 - 1.2
                local posY = 0.7400004863739 + sizeY
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ - 6
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=2,2 do
            local addiX = 0.08 * iX
            for iY=1,1 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.2 - 1.2
                local posY = 0.7400004863739 + sizeY * 2
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ - 6
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=1,1 do
            local addiX = 0.08 * iX
            for iY=1,1 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 5
                local posY = 0.7400004863739 + sizeY
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ - 3
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=1,4 do
            local addiX = 0.08 * iX
            for iY=4,4 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.5
                local posY = 0.7400004863739
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ - 1
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=4,4 do
            local addiX = 0.08 * iX
            for iY=4,4 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.2
                local posY = 0.7400004863739
                local PosZ = (iY + 1) * sizeX  - addiX - skewZ - 5.5
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
        
        -- 确定一点
        local centerCircle = cc.p(0,0,0)
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

        for iX=1,4 do
            local addiX = 0.08 * iX
            for iY=4,4 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.5
                local posY = 0.7400004863739
                local PosZ =  sizeX  - addiX - skewZ - 1 + 3
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end
        
        for iX=1,4 do
            local addiX = 0.08 * iX
            for iY=4,4 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.5
                local posY = 0.7400004863739
                local PosZ =  sizeX * 5  - addiX - skewZ - 1 - 1
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=1,3 do
            local addiX = 0.08 * iX
            for iY=4,4 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.5 + 2
                local posY = 0.7400004863739
                local PosZ =  sizeX * 5  - addiX - skewZ - 1 - 1
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=1,3 do
            local addiX = 0.08 * iX
            for iY=4,4 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.5 + 2
                local posY = 0.7400004863739
                local PosZ =  sizeX  - addiX - skewZ - 1 + 3 - 5
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=1,3 do
            local addiX = 0.08 * iX
            for iY=4,4 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.5 + 2
                local posY = 0.7400004863739 + sizeY
                local PosZ =  sizeX  - addiX - skewZ - 1 + 3 - 5
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end
        
        for iX=1,3 do
            local addiX = 0.08 * iX
            for iY=4,4 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.5 + 2
                local posY = 0.7400004863739 + sizeY * 2
                local PosZ =  sizeX  - addiX - skewZ - 1 + 3 - 5
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=1,1 do
            local addiX = 0.08 * iX
            for iY=2,3 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (4 * 1) - skewX - 0.5
                local posY = 0.7400004863739
                local PosZ =  sizeX * 5  - addiX - skewZ - 1 - 1 - (iY - 1)*sizeX
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end

        for iX=4,4 do
            local addiX = 0.08 * iX
            for iY=2,3 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (4 * 1) - skewX - 0.5
                local posY = 0.7400004863739
                local PosZ =  sizeX * 5  - addiX - skewZ - 1 - 1 - (iY - 1)*sizeX
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
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
            
            -- performWithDelay(self, function(  )
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
            -- end, 1 * iY)
     
        end

        -- 第二层
        for iY=1,8 do

            -- performWithDelay(self, function(  )

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
            -- end, 1 * iY)
        end

         -- 第一层
         local skewX = 6.7
         local addX = 2.1
         local skewZ = 2
 
         for iX=1,4 do
             local addiX = 0.08 * iX
             for iY=4,4 do
                 local coinsType = "RANDOM"
                 local itemAtt = Config.CoinModelAtt[coinsType]
                 local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                 local sizeY = itemAtt.PhysicSize.y + 0.3
                 local posX = iX * sizeX  - (iY * 1) - skewX - 0.5
                 local posY = 0.7400004863739
                 local PosZ =  sizeX  - addiX - skewZ - 1 + 3
                 self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                 self.m_pDesktopLayer:reducePushType(coinsType)
             end 
         end
         
         for iX=1,4 do
             local addiX = 0.08 * iX
             for iY=4,4 do
                 local coinsType = "RANDOM"
                 local itemAtt = Config.CoinModelAtt[coinsType]
                 local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                 local sizeY = itemAtt.PhysicSize.y + 0.3
                 local posX = iX * sizeX  - (iY * 1) - skewX - 0.5
                 local posY = 0.7400004863739
                 local PosZ =  sizeX * 5  - addiX - skewZ - 1 - 1
                 self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                 self.m_pDesktopLayer:reducePushType(coinsType)
             end 
         end

         for iX=1,4 do
            local addiX = 0.08 * iX
            for iY=4,4 do
                local coinsType = "RANDOM"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * sizeX  - (iY * 1) - skewX - 0.5
                local posY = 0.7400004863739
                local PosZ =  sizeX * 5  - addiX - skewZ - 1 - 1
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end
 
         for iX=1,3 do
             local addiX = 0.08 * iX
             for iY=4,4 do
                 local coinsType = "RANDOM"
                 local itemAtt = Config.CoinModelAtt[coinsType]
                 local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                 local sizeY = itemAtt.PhysicSize.y + 0.3
                 local posX = iX * sizeX  - (iY * 1) - skewX - 0.5 + 2
                 local posY = 0.7400004863739
                 local PosZ =  sizeX * 5  - addiX - skewZ - 1 - 1
                 self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                 self.m_pDesktopLayer:reducePushType(coinsType)
             end 
         end
 
         for iX=1,3 do
             local addiX = 0.08 * iX
             for iY=4,4 do
                 local coinsType = "RANDOM"
                 local itemAtt = Config.CoinModelAtt[coinsType]
                 local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                 local sizeY = itemAtt.PhysicSize.y + 0.3
                 local posX = iX * sizeX  - (iY * 1) - skewX - 0.5 + 2
                 local posY = 0.7400004863739
                 local PosZ =  sizeX  - addiX - skewZ - 1 + 3 - 5
                 self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                 self.m_pDesktopLayer:reducePushType(coinsType)
             end 
         end
 

 
         for iX=1,1 do
             local addiX = 0.08 * iX
             for iY=2,3 do
                 local coinsType = "RANDOM"
                 local itemAtt = Config.CoinModelAtt[coinsType]
                 local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                 local sizeY = itemAtt.PhysicSize.y + 0.3
                 local posX = iX * sizeX  - (4 * 1) - skewX - 0.5
                 local posY = 0.7400004863739
                 local PosZ =  sizeX * 5  - addiX - skewZ - 1 - 1 - (iY - 1)*sizeX
                 self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                 self.m_pDesktopLayer:reducePushType(coinsType)
             end 
         end
 
         for iX=4,4 do
             local addiX = 0.08 * iX
             for iY=2,3 do
                 local coinsType = "RANDOM"
                 local itemAtt = Config.CoinModelAtt[coinsType]
                 local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                 local sizeY = itemAtt.PhysicSize.y + 0.3
                 local posX = iX * sizeX  - (4 * 1) - skewX - 0.1
                 local posY = 0.7400004863739 + sizeY 
                 local PosZ =  sizeX * 5  - addiX - skewZ - 1 - 1 - (iY - 1)*sizeX - 0.5
                 self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                 self.m_pDesktopLayer:reducePushType(coinsType)
             end 
         end
         
    elseif coinsShowType == 4 then -- 6个柱子，1-12，2-15，3-10，4-6，5-8，6-3

        --[[
            1 2 3  
             4 5
              6
        --]]

        -- 第一层
        local skewX = 6.8
        local addX_2 = 1.5
        local addX_3 = 1.2
        local skewZ = 0
        local YNum_1 = {12,15,10}
        for iX=1,3 do
            local addiX = 0.08 * iX
            for iY=1,YNum_1[iX] do
                -- performWithDelay(self, function(  )

                    local coinsType = "NORMAL"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * sizeX  - skewX
                    local posY = 0.7400004863739 + sizeY * (iY - 1)
                    local PosZ =  sizeX * 3 - addiX - skewZ
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                -- end, 1 * iY)

            end 
        end
        local YNum_2 = {6,8}
        -- 第二层
        for iX=1,2 do
            local addiX = 0.08 * iX
            for iY=1,YNum_2[iX] do
                -- performWithDelay(self, function(  )

                    local coinsType = "NORMAL"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * sizeX - skewX + addX_2
                    local posY = 0.7400004863739 + sizeY * (iY - 1)
                    local PosZ =  sizeX * 4 - addiX - skewZ
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                -- end, 1 * iY)

            end 
        end

        -- 第三层
        for iX=1,1 do
            local addiX = 0.08 * iX
            for iY=1,3 do
                -- performWithDelay(self, function(  )

                    local coinsType = "NORMAL"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * sizeX - skewX + addX_2 + addX_3
                    local posY = 0.7400004863739 + sizeY * (iY - 1)
                    local PosZ =  sizeX * 5 - addiX - skewZ
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                -- end, 1 * iY)
            end 
        end


        local addRodNum = 4 --math.random(2,3)

        for i=1,addRodNum do
            local addiX = 0.08 * math.random(1,4)
            local coinsType = "RANDOM"
            local itemAtt = Config.CoinModelAtt[coinsType]
            local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
            local sizeY = itemAtt.PhysicSize.y + 0.3
            local posX = (i -1) * sizeX  - skewX 
            local posY = 0.7400004863739 + sizeY * 3
            local PosZ = sizeX * 1 - addiX - skewZ - math.random(-3,3)
   
            self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
            self.m_pDesktopLayer:reducePushType(coinsType)
        end
     
        addRodNum = 3
        for i=1,addRodNum do
            local addiX = 0.08 * math.random(1,4)
            local coinsType = "RANDOM"
            local itemAtt = Config.CoinModelAtt[coinsType]
            local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
            local sizeY = itemAtt.PhysicSize.y + 0.3
            local posX = (math.random(1,4) -1) * sizeX  - skewX 
            local posY = 0.7400004863739 + sizeY * 3
            local PosZ = sizeX * 3 - addiX - skewZ - math.random(-3,3)
   
            self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
            self.m_pDesktopLayer:reducePushType(coinsType)
        end

    elseif coinsShowType == 5 then 

        --[[  
            3 x 4 -- 3层
        --]]

        -- 第一层
        local skewX = 11.5
        local addX = 2.1
        local skewZ = -1


        for iX=1,5 do
            local addiX = 0.08 * iX
            for iY=1,4 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * (sizeX + 0.2)  - skewX 
                local posY = 0.7400004863739
                local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end


        -- 第二层
        for iX=1,5 do
            local addiX = 0.08 * iX
            for iY=1,3 do
                local coinsType = "NORMAL"
                local itemAtt = Config.CoinModelAtt[coinsType]
                local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                local sizeY = itemAtt.PhysicSize.y + 0.3
                local posX = iX * (sizeX + 0.2)  - skewX 
                local posY = 0.7400004863739 + sizeY
                local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ
                self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                self.m_pDesktopLayer:reducePushType(coinsType)
            end 
        end


        -- 第三层
        for iX=1,5 do
            local addiX = 0.08 * iX
            for iY=1,2 do
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

        -- 第四层
        for iX=1,5 do
            local addiX = 0.08 * iX
            for iY=1,1 do
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


        for index=1,5 do
            for iX=1,3 do
                local addiX = 0.08 * iX
                for iY=4,4 do
                    local coinsType = "RANDOM"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * (sizeX + 1)  - skewX + 0.5
                    local posY = 0.7400004863739 + sizeY * index
                    local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ - 20
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 
            end 
        end
          

        
        for index=1,6 do
            for iX=1,2 do
                local addiX = 0.08 * iX
                for iY=4,4 do
                    local coinsType = "RANDOM"
                    local itemAtt = Config.CoinModelAtt[coinsType]
                    local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                    local sizeY = itemAtt.PhysicSize.y + 0.3
                    local posX = iX * (sizeX + 1)  - skewX + 3.2
                    local posY = 0.7400004863739 + sizeY * index
                    local PosZ = (iY + 1) * (sizeX + 0.2)  - addiX - skewZ - 25
                    self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), true) 
                    self.m_pDesktopLayer:reducePushType(coinsType)
                end 
            end
        end

        


    --[[

        -- 五个柱子，1-10，2-15，3-12，4-8，5-5
              1  2
                    3
             4   5  
        

         -- 第一层
         local skewX = 7.5
         local addX_1 = 1
         local addX_2 = 1.5
         local skewZ = 3
         local YNum_1 = {10,15}
         for iX=1,2 do -- 1,2

            local addiX = 0.08 * iX


             for iY=1,YNum_1[iX] do
                -- performWithDelay(self, function(  )
                
                 local coinsType = "NORMAL"
                 local itemAtt = Config.CoinModelAtt[coinsType]
                 local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                 local sizeY = itemAtt.PhysicSize.y + 0.3
                 local posX = iX * sizeX  - skewX + addX_1
                 local posY = 0.7400004863739 + sizeY * (iY - 1)
                 local PosZ =  sizeX * 3 - addiX - skewZ
                 self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), false) 
                 self.m_pDesktopLayer:reducePushType(coinsType)
                -- end, 1 * iY)

             end 
         end
         local YNum_2 = {8,5}
         -- 第二层
         for iX=1,2 do -- 4,5

            local addiX = 0.08 * iX

             for iY=1,YNum_2[iX] do
                -- performWithDelay(self, function(  )

                 local coinsType = "NORMAL"
                 local itemAtt = Config.CoinModelAtt[coinsType]
                 local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                 local sizeY = itemAtt.PhysicSize.y + 0.3
                 local posX = iX * sizeX - skewX 
                 local posY = 0.7400004863739 + sizeY * (iY - 1)
                 local PosZ =  sizeX * 4 - addiX - skewZ
                 self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), false) 
                 self.m_pDesktopLayer:reducePushType(coinsType)
                -- end, 1 * iY)

             end 
         end
 
         -- 第三层
         for iX=1,1 do -- 3

            local addiX = 0.08 * iX

             for iY=1,12 do
                -- performWithDelay(self, function(  )

                 local coinsType = "NORMAL"
                 local itemAtt = Config.CoinModelAtt[coinsType]
                 local sizeX = itemAtt.PhysicSize.x + 0.05 + 0.5
                 local sizeY = itemAtt.PhysicSize.y + 0.3
                 local posX = iX * sizeX - skewX + addX_2 + (2 * sizeX)
                 local posY = 0.7400004863739 + sizeY * (iY - 1)
                 local PosZ =  sizeX * 3.5 - addiX - skewZ
                 self:createCoins( tostring(coinsType), cc.vec3( posX,posY, PosZ) , cc.vec3(0.0, 0.0,0.0), false) 
                 self.m_pDesktopLayer:reducePushType(coinsType)
                -- end, 1 * iY)

             end 
         end
    --]]


    end

    


end


return GamePusherMain