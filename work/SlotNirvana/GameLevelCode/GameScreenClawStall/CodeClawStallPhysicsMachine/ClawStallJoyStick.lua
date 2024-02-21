--[[
    摇杆
]]
local PublicConfig = require "ClawStallPublicConfig"
local ClawStallGameManager = util_require("CodeClawStallPhysicsMachine.ClawStallGameManager"):getInstance()
local ClawStallJoyStick = class("ClawStallJoyStick", util_require("Levels.BaseLevelDialog"))

local DIRECRION = {
    [1] = "Up0",
    [2] = "Down0",
    [3] = "Left0",
    [4] = "Right0"
}

function ClawStallJoyStick:initUI()
    self:createCsbNode("ClawStall_Machine_Joystick.csb")

    self.m_controlArea = util_createAnimation("ClawStall_Machine_ControlArea.csb")
    self:findChild("Node_ControlArea"):addChild(self.m_controlArea)
    for k,dirc in pairs(DIRECRION) do
        self.m_controlArea:findChild(dirc):setVisible(false)
    end

    self.m_tip = util_createAnimation("ClawStall_Machine_ControlTips.csb")
    self:addChild(self.m_tip)
    self.m_tip:runCsbAction("idle",true)
    self.m_tip:setVisible(false)

    self.m_touchEnabled = true

    self.m_touchStartPos = nil

    self:initVirtual3DStick()
end

--[[
    设置是否可点击
]]
function ClawStallJoyStick:setTouchEnabled(isEnabled)
    self.m_touchEnabled = isEnabled
    if not isEnabled then
        self:resetVirtual3DStick()
    end
end


function ClawStallJoyStick:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    print( "HolyShit. Click "..name )
end

function ClawStallJoyStick:onEnter()
    self.m_OriPos = cc.p( self:getPosition() )
    self.m_isTip = gLobalDataManager:getNumberByField("ClawStallJoyStickTip", 0)
    if self.m_isTip == 0 then
        -- self.m_tip:setVisible(true)
    end
    
end

--[[
    显示操作提示
]]
function ClawStallJoyStick:showControlTip( )
    local autoStatus = ClawStallGameManager:getAutoStatus()
    if autoStatus then
        return
    end
    self.m_isTip = 0
    -- self.m_tip:setVisible(true)
end

-- 虚拟3D摇杆 --
function ClawStallJoyStick:initVirtual3DStick()

    -- 金属杆 --
    self.joySylinder = self:findChild("ClawStall_wawaji_yaogan_2_2")

    -- 触碰区 --
    local joyBg = ccui.Layout:create()  
    joyBg:setAnchorPoint(0.5,0.5)
    joyBg:setContentSize(CCSizeMake(display.width * 2,display.height * 2))
    joyBg:setName("JoyStickBg")
    joyBg:setTouchEnabled(true)
    joyBg:setSwallowTouches(true)
    joyBg:setPosition( cc.p(0,0) )
    self:addChild( joyBg )
    self:addClick( joyBg )
    -- joyBg:setVisible(false)
    self.m_JoyRadius = 60

    -- 球 --
    self.joyBall = self:findChild("ClawStall_wawaji_yaogan_1_1")
    self.joyBall:setPosition(cc.p(0,0))
    self:refreshDirection(cc.p(0,0))

    util_setCascadeOpacityEnabledRescursion(self,true)
end
function ClawStallJoyStick:resetVirtual3DStick()
    self.joySylinder:setRotation( 0 )
    self.joyBall:setPosition( cc.p(0,0) )
    self:refreshDirection(cc.p(0,0))
end

-- 3D摇杆 --
function ClawStallJoyStick:init3DJoyStick()
    self.m_stickModel   = cc.Sprite3D:create( "physicsRes/JoyStick/zuozuogan.c3b")
    self.m_stickModel:setTexture( "physicsRes/JoyStick/wawaji_zaozuogan_d.png" )
    self.m_stickModel:setScale(500)
    self.m_stickModel:setCameraMask( cc.CameraFlag.USER2 )
    self.m_StickOriRot = cc.vec3(-45.0, 0.0, 0.0)
    self.m_stickModel:setRotation3D( self.m_StickOriRot )
    self:addChild( self.m_stickModel  )
end
function ClawStallJoyStick:updata3DJoyStick( moveSpeed )
    local newRotation = cc.vec3( self.m_StickOriRot.x -  moveSpeed.y * 2  , self.m_StickOriRot.y  , self.m_StickOriRot.z + moveSpeed.x * 2  )
    self.m_stickModel:setRotation3D( newRotation )
end

--点击监听
function ClawStallJoyStick:clickStartFunc(sender)
    local autoStatus = ClawStallGameManager:getAutoStatus()
    if autoStatus then
        return
    end

    if self.m_isTip == 0 then
        self.m_isTip = 1
        self.m_tip:setVisible(false)
        gLobalDataManager:setNumberByField("ClawStallJoyStickTip", self.m_isTip, true)
    end

    if not self.m_touchEnabled then
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_click_joystick)

    self.m_touchStartPos = self:convertToNodeSpace(sender:getTouchBeganPosition())
    
end
--移动监听
function ClawStallJoyStick:clickMoveFunc(sender)
    local autoStatus = ClawStallGameManager:getAutoStatus()
    if autoStatus then
        return
    end

    if not self.m_touchEnabled or not self.m_touchStartPos then
        return
    end

    if not self.m_soundId then
        self.m_soundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_move_claw,true)
    end
    

    --获取当前点击位置
    local touchPos       = sender:getTouchMovePosition()
    local movePos = self:convertToNodeSpace(touchPos)

    --计算半径
    local tmpDis        = cc.pGetDistance( movePos , self.m_touchStartPos )
    if math.abs(tmpDis) > self.m_JoyRadius then
        tmpDis = self.m_JoyRadius
    end
    --计算角度
    local angleDegree   = util_getDegreesByPos( self.m_touchStartPos ,  movePos  )
    local angleRadian   = (angleDegree - 90) * math.pi / 180
    local tmpPos        = cc.p( tmpDis * math.cos( angleRadian ) , -tmpDis * math.sin( angleRadian ) )

    local tmpBallPos = cc.pMul( tmpPos , 0.5 )
    self.joyBall:setPosition( tmpBallPos )

    local angle   = util_getDegreesByPos( cc.p(self.joySylinder:getPosition()) , tmpBallPos   )
    self.joySylinder:setRotation( angle )

    -- 通知事件 --
    local speed = ClawStallGameManager:getMoveSpeedFactor()
    local moveSpeed = cc.pMul( tmpPos ,  speed)
    gLobalNoticManager:postNotification( "ClawGameMain_JoyStcikMoved" , moveSpeed )

    self:refreshDirection(moveSpeed)
end

function ClawStallJoyStick:refreshDirection(moveSpeed)
    for k,dirc in pairs(DIRECRION) do
        self.m_controlArea:findChild(dirc):setVisible(false)
    end
    if moveSpeed.x > 0 then
        self.m_controlArea:findChild(DIRECRION[4]):setVisible(true)
    end
    if moveSpeed.x < 0 then
        self.m_controlArea:findChild(DIRECRION[3]):setVisible(true)
    end
    if moveSpeed.y > 0 then
        self.m_controlArea:findChild(DIRECRION[1]):setVisible(true)
    end
    if moveSpeed.y < 0 then
        self.m_controlArea:findChild(DIRECRION[2]):setVisible(true)
    end
end

--结束监听
function ClawStallJoyStick:clickEndFunc(sender)
    -- self.m_joy:setPosition( cc.p( 0 ,0 ) )

    -- reset 3d joystick rotation --
    -- self.m_stickModel:setRotation3D( self.m_StickOriRot )

    local autoStatus = ClawStallGameManager:getAutoStatus()
    if autoStatus then
        return
    end

    self:resetVirtual3DStick()
    gLobalNoticManager:postNotification( "ClawGameMain_JoyStcikEnded" )

    self.m_touchStartPos = nil

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

return ClawStallJoyStick