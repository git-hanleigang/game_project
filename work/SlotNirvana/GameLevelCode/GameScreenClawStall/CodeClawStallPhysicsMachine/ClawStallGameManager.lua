--[[
    ClawStallGameManager
    tm - -

    在 JMSLogonLoading.lua中测试
    require("TmClawgame.ClawStallGameManager"):getInstance():enterScene()
]]
local SendDataManager = require "network.SendDataManager"
local ClawStallPhysicConfig = util_require("CodeClawStallPhysicsMachine.ClawStallPhysicConfig")

local ClawStallGameManager = class("ClawStallGameManager")

--抓取模式
local CLAW_MODE = {
    NORMAL = 1,     --普通模式
    SPECIAL = 2     --特殊模式
}

function ClawStallGameManager:ctor()
    self.newScene = nil
    self.m_isDebug = false -- 
    self.m_isPreClaw = false
    self.m_isCanClaw = false
    self.m_autoStatus = false
    --设置爪子平移速度
    self:setMoveSpeedFactor(ClawStallPhysicConfig.moveSpeedFactor)
    --设置爪子下移速度
    self:setMoveDownSpeed(ClawStallPhysicConfig.moveDownSpeed)
    --设置爪子上升速度
    self:setMoveUpSpeed(ClawStallPhysicConfig.moveUpSpeed)
    --设置爪子闭合角度
    self:setClawCloseAngle(ClawStallPhysicConfig.clawCloseAngle)
    --设置娃娃模型半径
    self:setItemRadius(ClawStallPhysicConfig.itemRadius)

    --设置爪子移动回漏斗速度
    self:setMoveBackSpeed(ClawStallPhysicConfig.moveBackSpeed)

    --设置机台偏移量
    self:setMachineOffset(ClawStallPhysicConfig.machineOffset)
    --设置娃娃缩放
    self:setItemScale(ClawStallPhysicConfig.itemScale)
    --设置小球缩放
    self:setBallScale(ClawStallPhysicConfig.ballScale)

    --设置抓取模式
    self:setCurClawMode(CLAW_MODE.NORMAL)
end

function ClawStallGameManager:setIsDebug(isDebug)
    self.m_isDebug = isDebug
end

function ClawStallGameManager:getIsDebug()
    return self.m_isDebug
end
-- Instance --
function ClawStallGameManager:getInstance()
    if not self._instance then
		self._instance = ClawStallGameManager.new()
	end
	return self._instance
end

function ClawStallGameManager:enterScene()
    -- 切换为竖屏 --
    -- globalData.slotRunData.isChangeScreenOrientation = true
    -- if globalData.slotRunData.isPortrait ~= true then
    --     globalData.slotRunData:changeScreenOrientation(true)
    -- end

    -- 创建场景 --
    -- if not self.newScene then
    --     self.newScene = cc.Scene:createWithPhysics()
    -- end

    -- -- 我们目前用Physics3D ，而此scene会自动创建2dPhysics系统，暂时停掉2d的步进计算,底层有个小Bug --
    -- local physics2dWorld = self.newScene:getPhysicsWorld()
    -- if physics2dWorld ~= nil then
    --     physics2dWorld:setAutoStep(false)
    -- end
    -- local speed = physics2dWorld:getSpeed()
    -- display.runScene( self.newScene )

    -- -- 
    -- self:initMain()
end

function ClawStallGameManager:createMainLayer(params)
    self.m_machine = params.machine
    self.m_clawMain = util_createView("CodeClawStallPhysicsMachine.ClawStallGameMain", params)
    return self.m_clawMain 
end

function ClawStallGameManager:getMachineView( )
    return self.m_machine
end

--[[
    设置爪子移动速度
]]
function ClawStallGameManager:setMoveSpeedFactor(moveSpeed)
    self.m_moveSpeedFactor = moveSpeed
end

--[[
    获取当前爪子移动速度
]]
function ClawStallGameManager:getMoveSpeedFactor()
    return self.m_moveSpeedFactor 
end

--[[
    设置爪子下移速度
]]
function ClawStallGameManager:setMoveDownSpeed(speed)
    self.m_moveDownSpeed = speed
end

--[[
    获取爪子下移速度
]]
function ClawStallGameManager:getMoveDownSpeed()
    return self.m_moveDownSpeed
end

--[[
    设置爪子上升速度
]]
function ClawStallGameManager:setMoveUpSpeed(speed)
    self.m_moveUpSpeed = speed
end

--[[
    获取爪子上升速度
]]
function ClawStallGameManager:getMoveUpSpeed()
    return self.m_moveUpSpeed
end

--[[
    设置爪子移回速度
]]
function ClawStallGameManager:setMoveBackSpeed(speed)
    self.m_moveBackSpeed = speed
end

--[[
    获取爪子移回速度
]]
function ClawStallGameManager:getMoveBackSpeed( )
    return self.m_moveBackSpeed
end

--[[
    设置爪子闭合角度
]]
function ClawStallGameManager:setClawCloseAngle(angle)
    self.m_closeAngle = angle
end

--[[
    获取爪子闭合角度
]]
function ClawStallGameManager:getClawCloseAngle()
    return self.m_closeAngle
end

--[[
    设置娃娃半径
]]
function ClawStallGameManager:setItemRadius(radius)
    self.m_itemRadius = radius
end

--[[
    获取娃娃模型半径
]]
function ClawStallGameManager:getItemRadius( )
    return self.m_itemRadius
end

--[[
    发送预抓取消息
]]
function ClawStallGameManager:sendPreClawData()
    local httpSendMgr = SendDataManager:getInstance()
    -- -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,data = {-1}}

    self.m_isPreClaw = true

    util_printLog("发送预抓取娃娃数据")
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

--[[
    发送bonus消息
]]
function ClawStallGameManager:sendBonusData(choose)
    if not self.m_isCanClaw then
        return
    end
    local httpSendMgr = SendDataManager:getInstance()
    -- -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,data = choose}

    util_printLog("发送抓取娃娃数据")
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

--[[
    随机道具位置
]]
function ClawStallGameManager:getRandItemPos(curNum)
    if not curNum then
        curNum = 1
    end
    local MACHINE_OFFSET = self:getMachineOffset() --机台偏移位置
    local randAreaIndex = curNum % 4
    if randAreaIndex == 0 then
        randAreaIndex = 4
    end
    if randAreaIndex == 1 then
        return cc.vec3( math.random( -26 , 0) , math.random(0,10), math.random( -30 + MACHINE_OFFSET ,-18 + MACHINE_OFFSET))
    elseif randAreaIndex == 2 then
        return cc.vec3( math.random( -26 , 0) , math.random(0,10), math.random( -18 + MACHINE_OFFSET ,-7 + MACHINE_OFFSET))
    elseif randAreaIndex == 3 then
        return cc.vec3( math.random( 0 , 26) , math.random(0,10), math.random( -30 + MACHINE_OFFSET ,-18 + MACHINE_OFFSET))
    else
        return cc.vec3( math.random( 0 , 26) , math.random(0,10), math.random( -18 + MACHINE_OFFSET ,-7 + MACHINE_OFFSET))
    end
end

--[[
    获取距离
]]
function ClawStallGameManager:getDistance(startP,endP)
    local tempPos = {x = startP.x - endP.x , y = startP.y - endP.y ,z = startP.z - endP.z}
    return math.sqrt( tempPos.x * tempPos.x + tempPos.y * tempPos.y + tempPos.z * tempPos.z )
end

--[[
    根据id获取道具数据
]]
function ClawStallGameManager:getItemData(itemID)
    local itemList = ClawStallPhysicConfig.itemList
    return itemList[itemID]
end

--[[
    获取倒计时时长
]]
function ClawStallGameManager:getCountDownTime( )
    return ClawStallPhysicConfig.countDownTime
end

--[[
    设置机台偏移量
]]
function ClawStallGameManager:setMachineOffset(offset)
    self.m_machineOffset = offset
end

--[[
    获取机台偏移量
]]
function ClawStallGameManager:getMachineOffset()
    return self.m_machineOffset
end

--[[
    设置娃娃缩放
]]
function ClawStallGameManager:setItemScale(scale)
    self.m_itemScale = scale
end

--[[
    获取娃娃缩放
]]
function ClawStallGameManager:getItemScale()
    return self.m_itemScale
end

--[[
    设置小球缩放
]]
function ClawStallGameManager:setBallScale(scale)
    self.m_ballScale = scale
end

--[[
    获取小球缩放
]]
function ClawStallGameManager:getBallScale()
    return self.m_ballScale
end

--[[
    获取当前是否为debug模式
]]
function ClawStallGameManager:getIsDebug( )
    return self.m_isDebug
end

--[[
    设置当前抓取模式
]]
function ClawStallGameManager:setCurClawMode(mode)
    if not mode then
        mode = CLAW_MODE.NORMAL
    end
    self.m_clawMode = mode
end

--[[
    获取当前抓取模式
]]
function ClawStallGameManager:getCurClawMode( )
    return self.m_clawMode
end

--[[
    设置自动状态
]]
function ClawStallGameManager:setAutoStatus(isAuto)
    self.m_autoStatus = isAuto
end

--[[
    获取自动状态
]]
function ClawStallGameManager:getAutoStatus()
    return self.m_autoStatus
end

return ClawStallGameManager