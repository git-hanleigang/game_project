--[[
    所有场景子弹的基类
]]
local CastFishingBulletObj = class("CastFishingBulletObj", cc.Node)
local CastFishingManager = require "CodeCastFishingSrc.CastFishingFish.CastFishingManager"
local CastFishingSceneConfig = require "CodeCastFishingSrc.CastFishingFish.CastFishingSceneConfig"

CastFishingBulletObj.DisappearType = {
    Position  = 1,    --越界
    Time      = 2,    --倒计时
    Collision = 3,    --和鱼碰撞未捕获
    Capture   = 4,    --和鱼碰撞并且捕获
}

function CastFishingBulletObj:initData_(_config)
    self.m_config  = _config
    self.m_data = {}
    self.m_moveData = { 
        -- 方向(-1:下 1:上 0:不动)
        dir = self.m_config.resDirection,    
        -- 速度
        speed = 0,
    }

    self:initUI()
end

function CastFishingBulletObj:initUI()
    local csbPath = self.m_config.csbPath
    self.m_animCsb = util_createAnimation(csbPath)
    self:addChild(self.m_animCsb)

    local spinePath = self.m_config.spinePath
    self.m_animSpine = util_spineCreate(spinePath,true,true)
    self.m_animCsb:findChild("Node_Spine"):addChild(self.m_animSpine)

    -- self:initCollisionArea()
    
    util_setCascadeOpacityEnabledRescursion(self, true)
end
function CastFishingBulletObj:initCollisionArea()
    -- 碰撞区域
    local manager = CastFishingManager:getInstance()
    if manager.m_bShowShape then
        local brush = cc.DrawNode:create()
        self:addChild(brush) 
        local shapeConfig = manager:getBulletAttr(self.m_config.id, CastFishingManager.StrAttrKey.Shape, self.m_config.shape) 
        if shapeConfig[1] == CastFishingSceneConfig.ShapeType.Circular then
            brush:drawSolidCircle(cc.p(0, 0), shapeConfig[2], 0, 50, cc.c4f(0, 1, 0, 1))
        else
            local width  = shapeConfig[2]
            local height = shapeConfig[3]
            brush:drawSolidRect(cc.p(-width/2, 0), cc.p(width/2, height), cc.c4f(0, 1, 0, 1))
        end
        local blendFunc = {GL_ONE, GL_ONE}
        brush:setBlendFunc(blendFunc)
        brush:visit()
    end
end
--[[
    设置子弹的一些数据
]]
function CastFishingBulletObj:setBulletData(_data)
    --[[
        _params = {
            -- 必有
            sMode         = "free",
            bulletId      = 1,
            bulletPos     = cc.p(0, 0)
            fishingResult = "BONUS"
            overFun       = function(_fishObjList)
            end
            missFishId    = {}                         
            -- 可选
            autoDisappearTime = 0,
        }
    ]]
    self.m_data = _data
end
function CastFishingBulletObj:setDirection(_direction)
    self.m_moveData.dir = _direction
end
function CastFishingBulletObj:setSpeed(_speed)
    self.m_moveData.speed = _speed
end

--[[
    子弹和鱼的碰撞检测
    目前只考虑:圆形,矩形
]]
function CastFishingBulletObj:checkCollision(_fishObj)
    local manager = CastFishingManager:getInstance()
    local bCollision = false
    --形状
    local circularType = CastFishingSceneConfig.ShapeType.Circular
    local rectangleType = CastFishingSceneConfig.ShapeType.Rectangle

    local bulletPos   = self:getParent():convertToWorldSpace(cc.p(self:getPosition())) 
    local fishPos     = _fishObj:getParent():convertToWorldSpace(cc.p(_fishObj:getPosition())) 
    local bulletShape = manager:getBulletAttr(self.m_config.id, CastFishingManager.StrAttrKey.Shape, self.m_config.shape) 
    local fishShape   = manager:getSceneFishAttr(_fishObj.m_data.sMode, _fishObj.m_config.id, CastFishingManager.StrAttrKey.Shape, _fishObj.m_config.shape) 

    --圆形和圆形
    if bulletShape[1] == circularType and fishShape[1] == circularType then
        local distance = math.sqrt( math.pow(bulletPos.x - fishPos.x, 2) + math.pow(bulletPos.y - fishPos.y, 2))
        local radius1 =  bulletShape[2]
        local radius2 =  fishShape[2]

        bCollision = distance <= (radius1 + radius2)
        return bCollision
    end

    --矩形和矩形
    if bulletShape[1] == rectangleType and fishShape[1] == rectangleType then
        local rect1 = cc.rect(bulletPos.x - bulletShape[2]/2, bulletPos.y, bulletShape[2], bulletShape[3])
        local rect2 = cc.rect(fishPos.x - fishShape[2]/2, fishPos.y - fishShape[3]/2, fishShape[2], fishShape[3])

        bCollision = cc.rectIntersectsRect(rect1, rect2)
        return bCollision
    end

    -- 圆形和矩形(矩形默认不倾斜)(子弹为矩形时锚点为[0.5, 0], 鱼类为矩形时锚点为[0.5, 0.5])   
    local fnCheckCircularAndRectangle = function(_circularPos, _radius, _rect)
        -- 矩形中点
        local rectangleCenterPos = cc.p(_rect.x + _rect.width/2, _rect.y + _rect.height/2)
        -- 矩形中点到右上角圆心矢量
        local vectorV = cc.p(math.abs(_circularPos.x - rectangleCenterPos.x),  math.abs(_circularPos.y - rectangleCenterPos.y))
        -- 矩形中点到矩形右上角矢量
        local vectorH = cc.p(_rect.width/2, _rect.height/2)
        -- 圆心和矩形的最短矢量
        local vectorU = cc.p(math.max(0, vectorV.x-vectorH.x), math.max(0, vectorV.y-vectorH.y))
        -- 圆心到矩形的最短直线长度
        local uDistance = math.sqrt(math.pow(vectorU.x, 2) + math.pow(vectorU.y, 2))
        -- 比较平方大小
        local bTempCollision = math.pow(uDistance, 2) <= math.pow(_radius, 2)

        return bTempCollision
    end
    if bulletShape[1] == circularType and fishShape[1] == rectangleType then
        local circularPos = cc.p(bulletPos.x, bulletPos.y)
        local radius      = bulletShape[2]
        local rect        = cc.rect(fishPos.x - fishShape[2]/2, fishPos.y - fishShape[3]/2, fishShape[2], fishShape[3])
        
        bCollision = fnCheckCircularAndRectangle(circularPos, radius, rect)
        return bCollision
    elseif bulletShape[1] == rectangleType and fishShape[1] == circularType then
        local circularPos = cc.p(fishPos.x, fishPos.y)
        local radius      = fishShape[2]
        local rect        = cc.rect(bulletPos.x - bulletShape[2]/2, bulletPos.y, bulletShape[2], bulletShape[3])
        
        bCollision = fnCheckCircularAndRectangle(circularPos, radius, rect)
        return bCollision
    end

    return false
end

--[[
    子弹从场上离开
    1.位置原因 
    2.创到了鱼
    3.时间到了

    _data = {
        type = 1,
        fishObjList = {},
    }
]]
function CastFishingBulletObj:bulletDisappear(_data)
    if _data.type == self.DisappearType.Position then
        if "function" == type(self.m_data.overFun) then
            self.m_data.overFun({})
        end
    elseif _data.type == self.DisappearType.Time then
        if "function" == type(self.m_data.overFun) then
            self.m_data.overFun(_data.fishObjList)
        end
    elseif _data.type == self.DisappearType.Collision then
        if "function" == type(self.m_data.overFun) then
            self.m_data.overFun({})
        end
    elseif _data.type == self.DisappearType.Capture then
        if "function" == type(self.m_data.overFun) then
            self.m_data.overFun(_data.fishObjList)
        end
    end
end

function CastFishingBulletObj:getBulletSize()
    local size = cc.size(0, 0)

    local manager = CastFishingManager:getInstance()
    local bulletShape = manager:getBulletAttr(self.m_config.id, CastFishingManager.StrAttrKey.Shape, self.m_config.shape) 
    if bulletShape[1] == CastFishingSceneConfig.ShapeType.Circular then
        size.width  = bulletShape[2] * 2
        size.height = bulletShape[2] * 2
    elseif bulletShape[1] == CastFishingSceneConfig.ShapeType.Rectangle then
        size.width  = bulletShape[2]
        size.height = bulletShape[3]
    end
    
    return size
end


--[[
    激光类型
]]
function CastFishingBulletObj:isLaser()
    local bLaser = self.m_config.autoDisappearTime >= 0
    return bLaser
end

--[[
    状态展示变化:
    飞行
]]
function CastFishingBulletObj:playStateAnim_move()
    util_spinePlay(self.m_animSpine, self.m_config.spineIdle, false)
end



return CastFishingBulletObj
