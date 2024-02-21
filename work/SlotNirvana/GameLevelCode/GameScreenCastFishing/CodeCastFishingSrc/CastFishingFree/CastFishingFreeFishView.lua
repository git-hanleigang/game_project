--[[
    处理base和free的鱼池
]]
local CastFishingFreeFishView = class("CastFishingFreeFishView", util_require("Levels.BaseLevelDialog"))
local CastFishingManager = require "CodeCastFishingSrc.CastFishingFish.CastFishingManager"
local CastFishingSceneConfig = require "CodeCastFishingSrc.CastFishingFish.CastFishingSceneConfig"
local CastFishingBulletObj = require "CodeCastFishingSrc.CastFishingBattery.CastFishingBulletObj"
local CastFishingMusicConfig = require "CodeCastFishingSrc.CastFishingMusicConfig"

--鱼的层级
CastFishingFreeFishView.FishOrder = {
    Move = 1,              --正常移动
    Collision = 10,        --子弹碰撞
    Capture   = 100,       --子弹捕获
    FishNet   = 200,       --创建的鱼网
}

CastFishingFreeFishView.SceneConfig = {
    FreeFishId = {      -- 每个等级鱼的id
        1, 
        4, 
        5
    },
    BaseModelFishCount  = 8, --base模式的鱼群数量

    FishLeaveMultip = 5,    -- 鱼群退场倍速
    FishClickMultip = 3,    -- 鱼群点击倍速
}

function CastFishingFreeFishView:onEnter()
    CastFishingFreeFishView.super.onEnter(self)

    --发射炮弹
    gLobalNoticManager:addObserver(self,function(self,params)
        local sMode = params.sMode
        if sMode ~= self.m_mode then
            return
        end

        self:createBullet(params)
    end,"CastFishingMachine_launchBullet")
end
function CastFishingFreeFishView:onExit()
    self:stopUpDateTick()

    CastFishingFreeFishView.super.onExit(self)
end

function CastFishingFreeFishView:initDatas(_params)
    self.m_machine = _params[1]
    self.m_csbName = _params[2]
    self.m_mode    = _params[3]

    -- 状态
    self.m_bShowFishReward = false
    self.m_createFishState = true
    -- 游动的鱼
    self.m_fishList = {}
    self.m_fishPool = {}
    -- 飞行的子弹
    self.m_bulletList = {}
    self.m_bulletPool = {}
    -- 被撞击的鱼
    self.m_fishCollisionList = {}
    -- 鱼网
    self.m_fishNetPool = {}

    --base使用的数据
    -- 阶段状态 1:没触发玩法 2:触发了随机玩法
    self.m_baseGameStep = 1
end
function CastFishingFreeFishView:initUI(_machine)
    self:createCsbNode(self.m_csbName)
    -- 层级，不代表所有子节点都是该类对象
    self.m_layFishPool    = self:findChild("Lay_fishPool")
    self.m_layFishNetPool = self.m_layFishPool
    self.m_layBulletPool  = self:findChild("Lay_bulletPool")
end

function CastFishingFreeFishView:changeFishObjRewardState(_bShow)
    self.m_bShowFishReward = _bShow
end
-- 根据参数修改当前场上鱼的状态时间线名称
function CastFishingFreeFishView:changeFishObjStateAnimName(_data)
    --[[
        _data = {
            -- 条件 是否全体
            bALl     = true,
            -- 条件 对象id相等
            fishObjId == 0,

            -- 修改的状态
            state    = "move",
            -- 修改时间线名称
            animName = "idle2",
            -- 是否立即播放
            play     = true,
        }
    ]]
    for i,_fishObj in ipairs(self.m_fishList) do
        if _data.bALl or
            (nil ~= _data.fishObjId and _data.fishObjId == _fishObj.m_data.objId) then

            if "move" == _data.state then
                _fishObj:setStateAnimName_move(_data.animName)
                if _data.play then
                    _fishObj:playStateAnim_move()
                end
            end
        end
    end
end
-- 根据参数修改当前场上鱼的速度
function CastFishingFreeFishView:changeFishObjSpeed(_data)
    --[[
        _data = {
            -- 条件 是否全体
            bALl     = true,
            -- 条件 对象id相等
            fishObjId == 0,

            -- 基础速度倍数
            configMultip = 2,
            -- 线性加速至指定速度倍数
            linear = {time, times, multip}
        }
    ]]
    for i,_fishObj in ipairs(self.m_fishList) do
        if _data.bALl or
            (nil ~= _data.fishObjId and _data.fishObjId == _fishObj.m_data.objId) then
            
            _fishObj:stopSpeedChangeAction()
            local fishConfig = _fishObj.m_config
            local fishSpeed = CastFishingManager:getInstance():getSceneFishAttr(self.m_mode, _fishObj.m_config.id, CastFishingManager.StrAttrKey.Speed, fishConfig.speed)
            if nil ~= _data.configMultip then
                fishSpeed = fishSpeed * _data.configMultip
                _fishObj:setSpeed(fishSpeed)
            elseif nil ~= _data.linear then
                local addSpeed = fishSpeed * (_data.linear[3] - 1)
                _fishObj:startSpeedChangeAction(_data.linear[1], _data.linear[2], addSpeed)
            end
            
        end
        
    end
end

-- 结束bonus将列表所有鱼移入池子
function CastFishingFreeFishView:endFreeGamePushAllFishObj()
    for i,_fishObj in ipairs(self.m_fishList) do
        _fishObj:setVisible(false)
        table.insert(self.m_fishPool, _fishObj)
    end
    self.m_fishList = {}
end

--[[
    计时器刷帧
]]
function CastFishingFreeFishView:startUpDateTick()
    self:stopUpDateTick()
    self:onUpdate(function(dt)
        self:Tick(dt)
    end)
end
function CastFishingFreeFishView:stopUpDateTick()
    self:unscheduleUpdate()
end

function CastFishingFreeFishView:Tick(_dt)
    -- if self.m_machine:checkGameRunPause() then
    --     return
    -- end

    -- 碰撞检测
    self:checkCollisionTick()
    -- 补充鱼 
    self:createFishTick()
    -- 游动
    self:fishMoveTick()
    -- 飞行
    self:bulletFlyTick()
end
-- 补充鱼 
function CastFishingFreeFishView:setCreateFishState(_state)
    self.m_createFishState = _state
end
function CastFishingFreeFishView:createFishTick()
    if not self.m_createFishState then
        return
    end
    if self.m_mode == CastFishingManager.StrMode.Base then
        local maxCount = self.SceneConfig.BaseModelFishCount
        local curCount = #self.m_fishList
        if curCount >= maxCount then
            return
        end
        local createCount = maxCount - curCount
        for i=1,createCount do
            local fishCreatData = CastFishingManager:getInstance():randomFishData({sMode = self.m_mode})
            local fishId   = CastFishingManager:getInstance():getFishIdByMultip(fishCreatData[1])
            local fishObj  = self:createFishObj(fishId)
            local fishData = {}
            fishData.sMode       = self.m_mode
            fishData.multip      = fishCreatData[1]
            fishData.probability = fishCreatData[2]
            fishObj:setFishData(fishData)
            local startPos,direction = self:getFishStartPos({fishObj = fishObj})
            fishObj:setPosition(startPos)
            fishObj:setDirection(direction)
            fishObj:setSpeed(fishObj.m_config.speed)
            local fishObjId = self:getNewFishObjId()
            fishObj:changeFishData({objId = fishObjId})
            table.insert(self.m_fishList, fishObj)
            self:bindingBaseFishObjClickCallBack(fishObj)
            fishObj:setVisible(true)
        end
    elseif self.m_mode == CastFishingManager.StrMode.Free then
        local createFish = {
            CastFishingSceneConfig.FishLevelType.Coins,
            CastFishingSceneConfig.FishLevelType.Wild,
            CastFishingSceneConfig.FishLevelType.Jackpot
        }
        for i,_fishLevel in ipairs(createFish) do
            self:createFishObjByLevelData(_fishLevel)
        end
    end
end
-- base鱼池绑定单次点击回调
function CastFishingFreeFishView:bindingBaseFishObjClickCallBack(_fishObj)
    local fnClick = function(_fish)
        local fishObjId = _fish.m_data.objId
        self:changeFishObjStateAnimName({
            fishObjId = fishObjId,
            state    = "move",
            animName = "idle2",
            play     = true,
        })
        -- 0.3s 加速到3倍速
        self:changeFishObjSpeed({
            fishObjId = fishObjId,
            linear    = {0.3, 10, self.SceneConfig.FishClickMultip},
        })
        
    end
    _fishObj:registerOnceClickCallBack(fnClick)
end
function CastFishingFreeFishView:createFishObjByLevelData(_level)
    local manager      = CastFishingManager:getInstance()
    local fishId       = self.SceneConfig.FreeFishId[_level]
    local defaultCount = 3
    local needCount    = manager:getSceneFishAttr(self.m_mode, fishId, CastFishingManager.StrAttrKey.Count, defaultCount)
    -- 减去存活数量
    for i,_fishObj in ipairs(self.m_fishList) do
        local fishConfig = _fishObj.m_config
        if fishConfig.level == _level then
            needCount = needCount - 1
        end
    end
    if needCount > 0 then
        for i=1,needCount do

            local fishData = {}
            fishData.sMode       = self.m_mode
            local fishId   = self.SceneConfig.FreeFishId[_level]
            if _level == CastFishingSceneConfig.FishLevelType.Coins then
                local fishCreatData = manager:randomFishData({sMode = self.m_mode})
                fishData.multip      = fishCreatData[1]
                fishData.probability = fishCreatData[2]
            end
            local fishObj = self:createFishObj(fishId)
            fishObj:setFishData(fishData)
            local startPos,direction = self:getFishStartPos({fishObj = fishObj})
            fishObj:setPosition(startPos)
            fishObj:setDirection(direction)
            local fishSpeed = manager:getSceneFishAttr(self.m_mode, fishId, CastFishingManager.StrAttrKey.Speed, fishObj.m_config.speed)
            fishObj:setSpeed(fishSpeed)
            local fishObjId = self:getNewFishObjId()
            fishObj:changeFishData({objId = fishObjId})
            table.insert(self.m_fishList, fishObj)
            fishObj:setVisible(true)

        end
    end
end
function CastFishingFreeFishView:createFishObj(_fishId)
    local fishObj = nil
    -- 从其他列表导入不使用的鱼对象放到鱼池
    for i=#self.m_fishCollisionList,1,-1 do
        local _fishObj = self.m_fishCollisionList[i]
        if not _fishObj:isVisible() then
            table.remove(self.m_fishCollisionList, i)
            table.insert(self.m_fishPool, _fishObj)
        end
    end
    -- 从鱼池找一个合适的对象
    for i,_fishObj in ipairs(self.m_fishPool) do
        if _fishId == _fishObj.m_config.id then
            fishObj = table.remove(self.m_fishPool, i)
            fishObj:setOpacity(255)
            break
        end
    end

    if nil == fishObj then
        local config = CastFishingManager:getInstance():getFishConfig(_fishId)
        local codePath   = config.codePath
        if self.m_mode ==  CastFishingManager.StrMode.Base then
            codePath = "CodeCastFishingSrc.CastFishingFish.CastFishingBaseSceneFish"
        end
        fishObj = util_createView(codePath, config, self.m_machine)
        self.m_layFishPool:addChild(fishObj)
        fishObj:setVisible(false)
    end

    fishObj:resetFishObjData()
    local bShowReward = self:isShowReward()
    fishObj:changeRewardShow(bShowReward)
    fishObj:playStateAnim_move()
    self:changeFishObjOrder(fishObj, self.FishOrder.Move)

    return fishObj
end
function CastFishingFreeFishView:getNewFishObjId()
    local fishObjId = 0
    local fnCheckId = function(_fishObjId)
        for i,_fishObj in pairs(self.m_fishList) do 
            if _fishObjId == _fishObj.m_data.objId then
                return true
            end
        end
        return false
    end

    while fnCheckId(fishObjId) do
        fishObjId = fishObjId + 1
    end

    return fishObjId
end
function CastFishingFreeFishView:changeFishObjOrder(_fishObj, _type)
    local order = _type
    _fishObj:setLocalZOrder(order)
end
function CastFishingFreeFishView:isShowReward()
    if self.m_mode ==  CastFishingManager.StrMode.Base then
        return self.m_bShowFishReward
    elseif self.m_mode ==  CastFishingManager.StrMode.Free then
        return true
    end

    return false
end
function CastFishingFreeFishView:getFishStartPos(_params)
    --[[
        _params = [
            fishObj = {}
        ]
    ]]
    local manager = CastFishingManager:getInstance()
    local direction = 1
    local pos = cc.p(0, 0)
    local poolSize     = self.m_layFishPool:getContentSize()
    local fishConfig   = _params.fishObj.m_config
    local fishShape    = manager:getSceneFishAttr(self.m_mode , fishConfig.id, CastFishingManager.StrAttrKey.Shape, fishConfig.shape)
    local fishObjWidth = fishShape[2]
    
    -- 每个等级的鱼Y一致X的间隔一致
    if self.m_mode == CastFishingManager.StrMode.Free then
        local level     = fishConfig.level
        -- 每个等级固定方向
        local directionList = {
            [CastFishingSceneConfig.FishLevelType.Coins]   = 1,
            [CastFishingSceneConfig.FishLevelType.Wild]    = -1,
            [CastFishingSceneConfig.FishLevelType.Jackpot] = 1,
        }
        direction = directionList[level]
        -- 每个等级固定高度
        local posYList = {
            [CastFishingSceneConfig.FishLevelType.Coins]   = 50,
            [CastFishingSceneConfig.FishLevelType.Wild]    = 200,
            [CastFishingSceneConfig.FishLevelType.Jackpot] = 360,
        }
        pos.y = posYList[level]
        -- 拿尾部鱼的X坐标
        local intervalX = manager:getSceneFishAttr(self.m_mode, fishConfig.id, CastFishingManager.StrAttrKey.IntervalX, fishObjWidth * 3)
        -- 数值要求要有偏移随机值 0 ~ 10 %
        local intervalXOffset = intervalX * (math.random(0, 30)/100)
        intervalX = (intervalX - intervalXOffset) + math.random(0, intervalXOffset * 2)
        local initPosX  = 1 == direction and 0 or poolSize.width
        local lastPosX  = 1 == direction and poolSize.width or 0
        for i,_fishObj in ipairs(self.m_fishList) do
            if level == _fishObj.m_config.level then
                if 1 == direction then
                    lastPosX = math.min(lastPosX, _fishObj:getPositionX())
                else
                    lastPosX = math.max(lastPosX, _fishObj:getPositionX())
                end
            end
        end
        --无法和尾部鱼链接时,使用初始化X
        if 1 == direction then
            pos.x = lastPosX > intervalX and initPosX or lastPosX - intervalX
        else
            pos.x = lastPosX < poolSize.width - intervalX and initPosX or lastPosX + intervalX
        end
    else
        local baseIntervalX = fishObjWidth * 4
        -- 没触发玩法时:左右 均匀分布 不空场不重叠
        if 1 == self.m_baseGameStep then
            -- 拿所有鱼的位置 左上 左下 右上 右下
            local posList = {[1]={},[2]={},[3]={},[4]={}}
            for i,_fishObj in ipairs(self.m_fishList) do
                local fishPos = cc.p(_fishObj:getPosition())
                local upList = {}
                local downList = {}
                if 1 == _fishObj.m_moveData.dir then
                    upList   = posList[1]
                    downList = posList[2]
                else
                    upList   = posList[3]
                    downList = posList[4]
                end
                if fishPos.y >= poolSize.height/2 then
                    table.insert(upList, fishPos)
                else
                    table.insert(downList, fishPos)
                end
            end
            local bLeft = #posList[1] + #posList[2] <= #posList[3] + #posList[4]
            local bUp   = bLeft and #posList[1] <= #posList[2] or #posList[3] <= #posList[4]
            pos.x     = bLeft and 0 or poolSize.width
            direction = bLeft and 1 or -1
            -- 先确定高度 
            pos.y = bUp and math.random(poolSize.height/2, poolSize.height) or math.random(0, poolSize.height/2)
            -- 不能重叠 再确定X坐标
            local fnCheckPos = function(_checkPos)
                for i,_posTab in pairs(posList) do
                    for ii,_fishPos in ipairs(_posTab) do
                        local fishInterval = math.sqrt( math.pow(_checkPos.x - _fishPos.x, 2) + math.pow(_checkPos.y - _fishPos.y, 2))
                        if fishInterval < baseIntervalX then
                            return true
                        end
                    end
                end
                return false
            end

            local offsetX = bLeft and -(fishObjWidth/4) or fishObjWidth/4
            while fnCheckPos(pos) do
                pos.x = pos.x + offsetX
            end
        -- 触发玩法时:鱼要分两行游进来 
        -- 第一行:25%高度 向右, 第二行:75%高度 向左
        elseif 2 == self.m_baseGameStep then
            local posY1 = math.floor(poolSize.height * 0.25)
            local posY2 = math.floor(poolSize.height * 0.75)
            -- 拿当前场上每行鱼的位置
            local posList = {[1]={},[2]={}}
            for i,_fishObj in ipairs(self.m_fishList) do
                local fishPos = cc.p(_fishObj:getPosition())
                local rowList = (fishPos.y == posY1 and 1 == _fishObj.m_moveData.dir) and posList[1] or posList[2]
                table.insert(rowList, fishPos)
            end
            -- 先确定高度和方向
            local bRow1 = #posList[1] <= #posList[2]
            pos.y     = bRow1 and posY1 or posY2
            direction = bRow1 and 1 or -1
            -- 拿该行尾部鱼的X坐标
            local initPosX     = 1 == direction and fishObjWidth/2 or poolSize.width - fishObjWidth/2
            local lastPosX     = 1 == direction and poolSize.width - fishObjWidth/2 or fishObjWidth/2 
            local rowList = bRow1 and posList[1] or posList[2] 
            for i,_fishPos in ipairs(rowList) do
                lastPosX = 1 == direction and math.min(lastPosX, _fishPos.x) or math.max(lastPosX, _fishPos.x)
            end
            --无法和尾部鱼链接时,使用初始化X
            if 1 == direction then
                pos.x = lastPosX > baseIntervalX and initPosX or lastPosX - baseIntervalX
            else
                pos.x = lastPosX < poolSize.width - baseIntervalX and initPosX or lastPosX + baseIntervalX
            end
        end
        
    end

    return pos,direction
end

function CastFishingFreeFishView:checkCollisionTick()
    for bulletIndex=#self.m_bulletList,1,-1 do
        -- 捕获列表和碰撞列表
        local bCapture   = false
        local captureFishList = {}
        local bCollision = false
        local collisionFishList = {}
        local bulletObj  = self.m_bulletList[bulletIndex]
        for fishIndex=#self.m_fishList,1,-1 do
            local fishObj = self.m_fishList[fishIndex]
            local bCurCollision  = bulletObj:checkCollision(fishObj)
            local bCurCapture    = bCurCollision and self:checkCapture(bulletObj, fishObj)
            bCapture    = bCapture or bCurCapture
            bCollision  = bCollision or bCurCollision
            
            -- base 和 free 只能捕获一条
            if bCurCapture then
                table.remove(self.m_fishList, fishIndex)
                table.insert(self.m_fishCollisionList, fishObj)
                table.insert(captureFishList, fishObj)
                break
            -- 炮弹和鱼发生碰撞后直接消失
            elseif bCurCollision then
                table.insert(bulletObj.m_data.missFishId, fishObj.m_data.objId)
                table.insert(collisionFishList, fishObj)
                -- break
            end
        end
        
        if bCapture then
            table.remove(self.m_bulletList, bulletIndex)
            local data = {}
            data.type = CastFishingBulletObj.DisappearType.Capture
            data.fishObjList = captureFishList
            bulletObj:setVisible(false)

            self:playBulletCollisionAnim(bulletObj, captureFishList, bCapture, function()    
                bulletObj:bulletDisappear(data)
                table.insert(self.m_bulletPool, bulletObj)
            end)
        -- 碰撞改为穿鱼
        elseif bCollision then
            -- table.remove(self.m_bulletList, bulletIndex)
            -- bulletObj:runAction(cc.FadeOut:create(0.5))
            -- local data = {}
            -- data.type = CastFishingBulletObj.DisappearType.Collision
            -- data.fishObjList = collisionFishList

            self:playBulletCollisionAnim(bulletObj, collisionFishList, bCapture, function()
                -- bulletObj:bulletDisappear(data)
                -- bulletObj:setVisible(false)
                -- table.insert(self.m_bulletPool, bulletObj)
            end)
        end 
    end
end
-- 返回是否可以捕获碰到的鱼
function CastFishingFreeFishView:checkCapture(_bulletObj, _fishObj)
    -- 结果为字符串 时 "MISS" "BONUS" 
    if "MISS" == _bulletObj.m_data.fishingResult then
        return false
    end

    return true
end
function CastFishingFreeFishView:playBulletCollisionAnim(_bulletObj, _fishObjList, _bCapture, _fun)
    -- 未捕获
    if not _bCapture then
        -- 碰撞改为穿鱼
        -- 鱼的miss反馈
        for i,_fishObj in ipairs(_fishObjList) do
            -- self:changeFishObjOrder(_fishObj, self.FishOrder.Collision)
            -- local curSpeed = _fishObj.m_moveData.speed
            -- _fishObj:setSpeed(0)
            _fishObj:playStateAnim_miss(function()
                -- self:changeFishObjOrder(_fishObj, self.FishOrder.Move)
                _fishObj:playStateAnim_move()
                -- _fishObj:setSpeed(curSpeed)
            end)
        end
        self.m_machine:levelPerformWithDelay(self, 15/30 + 0.5, function()
            _fun()
        end)
    -- 捕获
    else
        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_freeBattery_fireHit)
        -- 鱼网时间线, 鱼收集+金币时间线
        local animTime = 0
        for i,_fishObj in ipairs(_fishObjList) do
            local fishObj = _fishObj
            self:changeFishObjOrder(fishObj, self.FishOrder.Capture)
            -- 鱼网
            local fishNetObj = self:createFishNetObj(_bulletObj, fishObj)
            local animName   = "paodan2"
            local loop       = false
            -- 章鱼被捕获时和鱼网一起挣扎鱼网不消失
            local isJackpot  = _fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Jackpot
            if isJackpot then
                -- 播完出现后循环挣扎
                local fishNetAnimName = "chuxian"
                util_spinePlay(fishNetObj, fishNetAnimName, false)
                util_spineEndCallFunc(fishNetObj, fishNetAnimName, function()
                    util_spinePlay(fishNetObj, "idle", true)
                end)
                -- 将鱼网存入鱼对象的数据包内带出去
                _fishObj:insertFishNetObjList(fishNetObj)
                animTime = math.max(animTime, 3/30 + 18/30)
            else
                -- 播完直接消失
                util_spinePlay(fishNetObj, "paodan2", false)
                util_spineEndCallFunc(fishNetObj, "paodan2", function()
                    fishNetObj:setVisible(false)
                end)
                -- 策划想看看不等网的效果
                -- animTime = math.max(animTime, 36/30)
            end
            fishNetObj:setVisible(true)
            table.insert(self.m_fishNetPool, fishNetObj)

            -- 鱼的反馈
            -- 金币鱼 立刻播收集时间线,只留金币文本,身体淡出
            if fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Coins then
                fishObj:playStateAnim_collect(nil)
                fishObj:playCoinsCollectFadeOut(function()
                    self:changeFishObjOrder(fishObj, self.FishOrder.FishNet + 1)
                end)
                animTime = math.max(animTime, 24/30)
            -- wild鱼 
            elseif fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Wild then
            -- jackpot鱼 
            elseif fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Jackpot then
                self.m_machine:levelPerformWithDelay(self, 3/30, function()
                    fishObj:setStateAnimName_collect("shouji_1")
                    fishObj:playStateAnim_collect(nil, true)
                end)
            end
        end
        self.m_machine:levelPerformWithDelay(self, animTime, function()
            _fun()
        end)
    end
end
function CastFishingFreeFishView:createFishNetObj(_bulletObj, _fishObj)
    local fishNetObj = nil
    if #self.m_fishNetPool > 0 then
        fishNetObj = table.remove(self.m_fishNetPool, 1)
    else
        fishNetObj = util_spineCreate("CastFishingPD",true,true)
        self.m_layFishNetPool:addChild(fishNetObj)
        fishNetObj:setLocalZOrder(self.FishOrder.FishNet)
        fishNetObj:setVisible(false)
    end
    local bulletPos = util_convertToNodeSpace(_bulletObj, self.m_layFishNetPool)
    local fishPos = util_convertToNodeSpace(_fishObj, self.m_layFishNetPool)
    local fishNetPos = cc.p((bulletPos.x + fishPos.x)/2, (bulletPos.y + fishPos.y)/2)
    fishNetObj:setPosition(fishNetPos)

    return fishNetObj
end

function CastFishingFreeFishView:fishMoveTick()
    local poolSize = self.m_layFishPool:getContentSize()
    local poolRect = cc.rect(0, 0, poolSize.width, poolSize.height)
    local objList = self.m_fishList

    for i=#objList,1,-1 do
        local fishObj = objList[i]
        local direction = fishObj.m_moveData.dir
        local speed     = fishObj.m_moveData.speed
        local distance  = direction * speed
        local curPosX   = fishObj:getPositionX()
        local nextPosX  = curPosX + distance
        fishObj:setPositionX(nextPosX)

        --前进的方向越界了
        local bRemove = false
        if fishObj.m_moveData.dir > 0  then
            bRemove = nextPosX > cc.rectGetMaxX(poolRect)
        elseif fishObj.m_moveData.dir < 0  then
            bRemove = nextPosX < cc.rectGetMinX(poolRect)
        end
        if bRemove then
            table.remove(objList, i)
            self:playFishLeaveAnim(fishObj)
            self:removeFishClearBulletMissList(fishObj.m_data.objId)
        end 
    end
end
function CastFishingFreeFishView:playFishLeaveAnim(_fishObj)
    _fishObj:playFishLeaveFadeOut(function()
        _fishObj:setVisible(false)
        table.insert(self.m_fishPool, _fishObj)
    end)
end
function CastFishingFreeFishView:removeFishClearBulletMissList(_fishObjId)
    for i,_bulletObj in ipairs(self.m_bulletList) do
        for _idIndex,fishObjId in ipairs(_bulletObj.m_data.missFishId) do
            if fishObjId == _fishObjId then
                table.remove(_bulletObj.m_data.missFishId, _idIndex)
                return
            end
        end
    end
end

function CastFishingFreeFishView:createBullet(_params)
    local sMode = _params.sMode
    if sMode ~= self.m_mode then
        return
    end
    --[[
        _params = {
            sMode         = CastFishingManager.StrMode.Free
            bulletId      = bulletId
            bulletPos     = bulletWorldPos
            fishingResult = self.fishingResult
            overFun       = function(_fishObjList)
                self:endGame(_fishObjList)
            end
        }
    ]]
    local manager = CastFishingManager:getInstance()
    -- 拿一个子弹对象
    local bulletObj = nil
    local bulletId  = _params.bulletId
    for i,_fishObj in ipairs(self.m_bulletPool) do
        if bulletId == _fishObj.m_config.id then
            bulletObj = table.remove(self.m_bulletPool, i)
            -- 有些逻辑可能会让透明度为 0
            bulletObj:setOpacity(255)
            break
        end
    end
    if nil == bulletObj then
        local config = manager:getBulletConfig(bulletId)
        local codePath   = config.codePath
        bulletObj = util_createView(codePath, config)
        self.m_layBulletPool:addChild(bulletObj)
        bulletObj:setVisible(false)
    end
    local pos = self.m_layBulletPool:convertToNodeSpace(_params.bulletPos)
    local bulletSize = bulletObj:getBulletSize()
    pos.y = pos.y + bulletSize.height/2
    bulletObj:setPosition(pos)
    -- 存一下miss鱼的id
    _params.missFishId = {}
    bulletObj:setBulletData(_params)
    local bulletSpeed = manager:getBulletAttr(bulletObj.m_config.id, CastFishingManager.StrAttrKey.Speed, bulletObj.m_config.speed) 
    bulletObj:setSpeed(bulletSpeed)
    bulletObj:playStateAnim_move()
    bulletObj:setVisible(true)
    table.insert(self.m_bulletList, bulletObj)
end
function CastFishingFreeFishView:bulletFlyTick()
    local poolSize = self.m_layBulletPool:getContentSize()
    local poolRect = cc.rect(0, 0, poolSize.width, poolSize.height)
    local objList = self.m_bulletList
    local objPool = self.m_bulletPool

    for i=#objList,1,-1 do
        local bulletObj = objList[i]
        local direction =  bulletObj.m_moveData.dir
        local speed    = bulletObj.m_moveData.speed
        local distance = direction * speed
        local curPosY  = bulletObj:getPositionY()
        local nextPosY = curPosY + distance
        local bulletSize = bulletObj:getBulletSize()
        local minY = cc.rectGetMinY(poolRect)
        local maxY = cc.rectGetMaxY(poolRect) + bulletSize.height * 2
        local bRemove = (nextPosY < minY) or (nextPosY > maxY)
        if bRemove then
            -- bulletObj:setPositionY(cc.rectGetMaxY(poolRect) - bulletSize.height/2)
            table.remove(objList, i)
            local data = {}
            data.type = CastFishingBulletObj.DisappearType.Position
            self:playBulletLeaveAnim(bulletObj, function()
                bulletObj:bulletDisappear(data)
                bulletObj:setVisible(false)
                table.insert(objPool, bulletObj)
            end)
        else
            -- bulletObj:setPositionY(nextPosY)
        end 
        bulletObj:setPositionY(nextPosY)
    end
end
-- 子弹因为位置越界离场时的淡出
function CastFishingFreeFishView:playBulletLeaveAnim(_bulletObj, _fun)
    _bulletObj:runAction(cc.Sequence:create(
        cc.FadeOut:create(0.1),
        cc.CallFunc:create(function()
            _fun()
        end)
    ))
end

return CastFishingFreeFishView