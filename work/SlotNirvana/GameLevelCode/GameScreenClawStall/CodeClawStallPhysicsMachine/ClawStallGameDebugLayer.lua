--[[
    ClawStallGameDebugLayer
    tm
]]
local ClawStallGameManager = util_require("CodeClawStallPhysicsMachine.ClawStallGameManager"):getInstance()
local ClawStallGameDebugLayer = class( "ClawStallGameDebugLayer" , function ()
    local layer = cc.Layer:create()
    return layer
end)


function ClawStallGameDebugLayer:ctor( mainLayer )
    self._Main = mainLayer
    self:InitDebugPro()
end


-------------------------------------------------- Debug Function S------------------------------------------------
function ClawStallGameDebugLayer:createBtn( name , pos , func )
    local pBtn = ccui.Button:create( "physicsRes/debug/btn.png", "physicsRes/debug/btn2.png" )
    pBtn:setTitleText( name )
    pBtn:setPosition(  pos.x ,  pos.y )
    pBtn:addClickEventListener( func )
    pBtn:setScale(1.5)
    self:addChild( pBtn , 100 )
    return pBtn
end

-- Init Debug Pro --
function ClawStallGameDebugLayer:InitDebugPro(  )
    -- 设置触摸操作 来操作摄像机 --
    local listener = cc.EventListenerTouchAllAtOnce:create()
    -- touch begin --
    listener:registerScriptHandler(function(touches, event)
    end,cc.Handler.EVENT_TOUCHES_BEGAN)

    -- touch move --
    listener:registerScriptHandler(function(touches, event)
        local isDebug = ClawStallGameManager:getIsDebug()
        if not isDebug then
            return
        end
        if #touches > 0 and self._Main._camera ~= nil then
            local touch = touches[1]
            local delta = touch:getDelta()

            if self._posY == nil then
                self._posY = self._Main._distanceY
            end
            self._posY = self._posY - delta.y

            self._Main._angle = self._Main._angle - delta.x * math.pi / 180.0
            local pos = cc.vec3(  self._Main._distanceZ * math.sin(self._Main._angle), self._posY , self._Main._distanceZ * math.cos(self._Main._angle))
            -- util_printLog("当前摄像机位置:"..cjson.encode(pos))
            self._Main._camera:setPosition3D(pos)
            self._Main._camera:lookAt( self._Main._lookAtOri , cc.vec3(0.0, 1.0, 0.0))

        end
    end, cc.Handler.EVENT_TOUCHES_MOVED)
  
    -- touch ended --
    listener:registerScriptHandler(function(touches, event)
    end, cc.Handler.EVENT_TOUCHES_ENDED)

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)    

    self.m_debugBtns = {}

    -- 显示刚体包围框 --
    self._debugUIRootShow = false
    self.m_debugBtns[#self.m_debugBtns + 1] = self:createBtn( "OFF" , cc.p( -display.cx + 80 ,  display.cy - 100 ) , function(sender)
        self._debugUIRootShow = not self._debugUIRootShow
        if self._debugUIRootShow then
            self._Main._physicsWorld:setDebugDrawEnable(true)
            sender:setTitleText("ON")
        else
            self._Main._physicsWorld:setDebugDrawEnable(false)
            sender:setTitleText("OFF")
        end
    end)

    -- 创建道具 --
    self.m_debugBtns[#self.m_debugBtns + 1] = self:createBtn( "创建道具" , cc.p( -display.cx + 80 ,  display.cy - 200 ) , function(sender)    
        local randomID = math.random(1,6)
        local randomPos= ClawStallGameManager:getRandItemPos()
        randomPos.y = 20
        local randomRot= cc.vec3( math.random( 0 , 180) , math.random( 0 , 180) , math.random( 0 , 180) )
        self._Main:createItems( randomID , randomPos , randomRot )
    end)

    -- 显示辅助线 --
    self.m_bShowRayLine = false
    self.m_debugBtns[#self.m_debugBtns + 1] = self:createBtn( "辅助线" , cc.p( -display.cx + 80 ,  display.cy - 300 ) , function(sender)
        self.m_bShowRayLine = not self.m_bShowRayLine
        self._Main:showHelpLine( self.m_bShowRayLine  )
    end)

    --修改移动速度按钮
    local speed = ClawStallGameManager:getMoveSpeedFactor()
    self.m_addSpeedBtn = self:createBtn("速度+0.01("..speed..")",cc.p(-display.cx + 80 ,  display.cy - 350),function(sender)
        speed = ClawStallGameManager:getMoveSpeedFactor()
        speed = speed + 0.01
        ClawStallGameManager:setMoveSpeedFactor(speed)
        self.m_addSpeedBtn:setTitleText( "速度+0.01("..speed..")" )
        self.m_reduceSpeedBtn:setTitleText( "速度-0.01("..speed..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_addSpeedBtn

    self.m_reduceSpeedBtn = self:createBtn("速度-0.01("..speed..")",cc.p(-display.cx + 80 ,  display.cy - 400),function(sender)
        speed = ClawStallGameManager:getMoveSpeedFactor()
        speed = speed - 0.01
        ClawStallGameManager:setMoveSpeedFactor(speed)
        self.m_addSpeedBtn:setTitleText( "速度+0.01("..speed..")" )
        self.m_reduceSpeedBtn:setTitleText( "速度-0.01("..speed..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_reduceSpeedBtn
    

    --修改爪子下落速度按钮
    local moveDownSpeed = ClawStallGameManager:getMoveDownSpeed()
    self.m_addMoveDownSpeedBtn = self:createBtn("下落速度+1("..moveDownSpeed..")",cc.p(-display.cx + 80 ,  display.cy - 450),function(sender)
        moveDownSpeed = ClawStallGameManager:getMoveDownSpeed()
        moveDownSpeed = moveDownSpeed + 1
        ClawStallGameManager:setMoveDownSpeed(moveDownSpeed)
        self.m_addMoveDownSpeedBtn:setTitleText( "下落速度+1("..moveDownSpeed..")" )
        self.m_reduceMoveDownSpeedBtn:setTitleText( "下落速度-1("..moveDownSpeed..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_addMoveDownSpeedBtn

    self.m_reduceMoveDownSpeedBtn = self:createBtn("下落速度-1("..moveDownSpeed..")",cc.p(-display.cx + 80 ,  display.cy - 500),function(sender)
        moveDownSpeed = ClawStallGameManager:getMoveDownSpeed()
        moveDownSpeed = moveDownSpeed - 1
        ClawStallGameManager:setMoveDownSpeed(moveDownSpeed)
        self.m_addMoveDownSpeedBtn:setTitleText( "下落速度+1("..moveDownSpeed..")" )
        self.m_reduceMoveDownSpeedBtn:setTitleText( "下落速度-1("..moveDownSpeed..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_reduceMoveDownSpeedBtn

    --爪子闭合角度
    local closeAngle = ClawStallGameManager:getClawCloseAngle()
    self.m_addCloseAngleBtn = self:createBtn("闭合角度+1("..closeAngle..")",cc.p(-display.cx + 80 ,  display.cy - 550),function(sender)
        closeAngle = ClawStallGameManager:getClawCloseAngle()
        closeAngle = closeAngle + 1
        ClawStallGameManager:setClawCloseAngle(closeAngle)
        self.m_addCloseAngleBtn:setTitleText( "闭合角度+1("..closeAngle..")" )
        self.m_reduceCloseAngleBtn:setTitleText( "闭合角度-1("..closeAngle..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_addCloseAngleBtn

    self.m_reduceCloseAngleBtn = self:createBtn("闭合角度-1("..closeAngle..")",cc.p(-display.cx + 80 ,  display.cy - 600),function(sender)
        closeAngle = ClawStallGameManager:getClawCloseAngle()
        closeAngle = closeAngle - 1
        ClawStallGameManager:setClawCloseAngle(closeAngle)
        self.m_addCloseAngleBtn:setTitleText( "闭合角度+1("..closeAngle..")" )
        self.m_reduceCloseAngleBtn:setTitleText( "闭合角度-1("..closeAngle..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_reduceCloseAngleBtn

    --娃娃模型大小
    local itemRadius = ClawStallGameManager:getItemRadius()
    self.m_addRadiusBtn = self:createBtn("娃娃半径+0.1("..itemRadius..")",cc.p(-display.cx + 80 ,  display.cy - 650),function(sender)
        itemRadius = ClawStallGameManager:getItemRadius()
        itemRadius = itemRadius + 0.1
        ClawStallGameManager:setItemRadius(itemRadius)
        self.m_addRadiusBtn:setTitleText( "娃娃半径+0.1("..itemRadius..")" )
        self.m_reduceRadiusBtn:setTitleText( "娃娃半径-0.1("..itemRadius..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_addRadiusBtn

    self.m_reduceRadiusBtn = self:createBtn("娃娃半径-0.1("..itemRadius..")",cc.p(-display.cx + 80 ,  display.cy - 700),function(sender)
        itemRadius = ClawStallGameManager:getItemRadius()
        itemRadius = itemRadius - 0.1
        ClawStallGameManager:setItemRadius(itemRadius)
        self.m_addRadiusBtn:setTitleText( "娃娃半径+0.1("..itemRadius..")" )
        self.m_reduceRadiusBtn:setTitleText( "娃娃半径-0.1("..itemRadius..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_reduceRadiusBtn

    --修改爪子上升速度按钮
    local moveUpSpeed = ClawStallGameManager:getMoveUpSpeed()
    self.m_addMoveUpSpeedBtn = self:createBtn("上升速度+1("..moveUpSpeed..")",cc.p(display.cx - 80 ,  display.cy - 150),function(sender)
        moveUpSpeed = ClawStallGameManager:getMoveUpSpeed()
        moveUpSpeed = moveUpSpeed + 1
        ClawStallGameManager:setMoveUpSpeed(moveUpSpeed)
        self.m_addMoveUpSpeedBtn:setTitleText( "上升速度+1("..moveUpSpeed..")" )
        self.m_reduceMoveUpSpeedBtn:setTitleText( "上升速度-1("..moveUpSpeed..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_addMoveUpSpeedBtn

    self.m_reduceMoveUpSpeedBtn = self:createBtn("上升速度-1("..moveUpSpeed..")",cc.p(display.cx - 80 ,  display.cy - 200),function(sender)
        moveUpSpeed = ClawStallGameManager:getMoveUpSpeed()
        moveUpSpeed = moveUpSpeed - 1
        ClawStallGameManager:setMoveUpSpeed(moveUpSpeed)
        self.m_addMoveUpSpeedBtn:setTitleText( "上升速度+1("..moveUpSpeed..")" )
        self.m_reduceMoveUpSpeedBtn:setTitleText( "上升速度-1("..moveUpSpeed..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_reduceMoveUpSpeedBtn

    --修改移回速度按钮
    local moveBackspeed = ClawStallGameManager:getMoveBackSpeed()
    self.m_addMoveBackSpeedBtn = self:createBtn("移回速度+0.1("..moveBackspeed..")",cc.p(display.cx - 80 ,  display.cy - 350),function(sender)
        moveBackspeed = ClawStallGameManager:getMoveBackSpeed()
        moveBackspeed = moveBackspeed + 0.1
        ClawStallGameManager:setMoveBackSpeed(moveBackspeed)
        self.m_addMoveBackSpeedBtn:setTitleText( "移回速度+0.1("..moveBackspeed..")" )
        self.m_reduceMoveBackSpeedBtn:setTitleText( "移回速度-0.1("..moveBackspeed..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_addMoveBackSpeedBtn

    self.m_reduceMoveBackSpeedBtn = self:createBtn("移回速度-0.1("..moveBackspeed..")",cc.p(display.cx - 80 ,  display.cy - 400),function(sender)
        moveBackspeed = ClawStallGameManager:getMoveBackSpeed()
        moveBackspeed = moveBackspeed - 0.1
        ClawStallGameManager:setMoveBackSpeed(moveBackspeed)
        self.m_addMoveBackSpeedBtn:setTitleText( "移回速度+0.1("..moveBackspeed..")" )
        self.m_reduceMoveBackSpeedBtn:setTitleText( "移回速度-0.1("..moveBackspeed..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_reduceMoveBackSpeedBtn


    --修改娃娃缩放按钮
    local itemScale = ClawStallGameManager:getItemScale()
    self.m_addItemScaleBtn = self:createBtn("娃娃缩放+0.1("..itemScale..")",cc.p(display.cx - 80 ,  display.cy - 450),function(sender)
        itemScale = ClawStallGameManager:getItemScale()
        itemScale = itemScale + 0.1
        ClawStallGameManager:setItemScale(itemScale)
        self.m_addItemScaleBtn:setTitleText( "娃娃缩放+0.1("..itemScale..")" )
        self.m_reduceItemScaleBtn:setTitleText( "娃娃缩放-0.1("..itemScale..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_addItemScaleBtn

    self.m_reduceItemScaleBtn = self:createBtn("娃娃缩放-0.1("..itemScale..")",cc.p(display.cx - 80 ,  display.cy - 500),function(sender)
        itemScale = ClawStallGameManager:getItemScale()
        itemScale = itemScale - 0.1
        ClawStallGameManager:setItemScale(itemScale)
        self.m_addItemScaleBtn:setTitleText( "娃娃缩放+0.1("..itemScale..")" )
        self.m_reduceItemScaleBtn:setTitleText( "娃娃缩放-0.1("..itemScale..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_reduceItemScaleBtn

    --修改小球缩放按钮
    local ballScale = ClawStallGameManager:getBallScale()
    self.m_addBallScaleBtn = self:createBtn("小球缩放+0.01("..ballScale..")",cc.p(display.cx - 80 ,  display.cy - 250),function(sender)
        ballScale = ClawStallGameManager:getBallScale()
        ballScale = ballScale + 0.01
        ClawStallGameManager:setBallScale(ballScale)
        self.m_addBallScaleBtn:setTitleText( "小球缩放+0.01("..ballScale..")" )
        self.m_reduceBallScaleBtn:setTitleText( "小球缩放-0.01("..ballScale..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_addBallScaleBtn

    self.m_reduceBallScaleBtn = self:createBtn("小球缩放-0.01("..ballScale..")",cc.p(display.cx - 80 ,  display.cy - 300),function(sender)
        ballScale = ClawStallGameManager:getBallScale()
        ballScale = ballScale - 0.01
        ClawStallGameManager:setBallScale(ballScale)
        self.m_addBallScaleBtn:setTitleText( "小球缩放+0.01("..ballScale..")" )
        self.m_reduceBallScaleBtn:setTitleText( "小球缩放-0.01("..ballScale..")" )
    end)
    self.m_debugBtns[#self.m_debugBtns + 1] = self.m_reduceBallScaleBtn

    --开关调试项
    self.m_showDebugBtn = self:createBtn("关闭调试项",cc.p(display.cx - 80 ,  display.cy - 100),function(sender)
        local isDebug = ClawStallGameManager:getIsDebug()
        isDebug = not isDebug
        ClawStallGameManager:setIsDebug(isDebug)
        if isDebug then
            self.m_showDebugBtn:setTitleText( "关闭调试项" )
        else
            self.m_showDebugBtn:setTitleText( "开启调试项" )
        end
        for i,btn in ipairs(self.m_debugBtns) do
            btn:setVisible(isDebug)
        end
    end)
end

return ClawStallGameDebugLayer


