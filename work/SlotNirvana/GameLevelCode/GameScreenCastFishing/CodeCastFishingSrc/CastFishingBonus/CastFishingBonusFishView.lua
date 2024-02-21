--[[
    处理两个bonus的鱼池
]]
local CastFishingBonusFishView = class("CastFishingBonusFishView",util_require("Levels.BaseLevelDialog"))
local CastFishingManager = require "CodeCastFishingSrc.CastFishingFish.CastFishingManager"
local CastFishingSceneConfig = require "CodeCastFishingSrc.CastFishingFish.CastFishingSceneConfig"
local CastFishingBulletObj = require "CodeCastFishingSrc.CastFishingBattery.CastFishingBulletObj"
local CastFishingMusicConfig = require "CodeCastFishingSrc.CastFishingMusicConfig"

--鱼的层级
CastFishingBonusFishView.FishOrder = {
    Move = 1,              --正常移动
    Collision = 10,        --子弹碰撞
    Capture   = 100,       --子弹捕获
    FishNet   = 200,       --创建的鱼网
}

CastFishingBonusFishView.SceneConfig = {
    MaxPool = 4,            -- 最大等级的池子
    MaxLine = 2,            -- 每个池子包含的行数
    PoolFishId = {          -- 鱼池固定id
        [4] = 5,
        [3] = 3,
        [2] = 2,
        [1] = 1,
    },
    PoolFishDirection = {   -- 鱼池固定朝向
        [4] = -1,
        [3] = 1,
        [2] = -1,
        [1] = 1,
    },
    
    FishLeaveMultip = 8,    -- 鱼群退场倍速
}

function CastFishingBonusFishView:onEnter()
    CastFishingBonusFishView.super.onEnter(self)

    --发射炮弹
    gLobalNoticManager:addObserver(self,function(self,params)
        local sMode = params.sMode
        if sMode ~= self.m_mode then
            return
        end
        self:createBullet(params)
        self:launchBulletChangeTitleViewTimes()
    end,"CastFishingMachine_launchBullet")
end
function CastFishingBonusFishView:onExit()
    self:stopUpDateTick()

    CastFishingBonusFishView.super.onExit(self)
end

function CastFishingBonusFishView:initDatas(_params)
    self.m_machine = _params[1]
    self.m_csbName = _params[2]
    self.m_mode    = _params[3]

    -- 游动的鱼
    self.m_fishList = {}
    self.m_fishPool = {}
    -- 飞行的子弹,倒计时的子弹
    self.m_bulletList = {}
    self.m_bulletTimeList = {}
    self.m_bulletPool = {}
    -- 被撞击的鱼
    self.m_fishCollisionList = {}
    -- 鱼网,激光粒子
    self.m_fishNetPool = {}
    self.m_laserParticlePool = {}


    --当前进行的鱼池索引 1 ~ 4
    self.m_curPoolIndex = 1
    -- 1:入场 2:开始游戏 3:玩法结束
    self.m_gameStep     = 3
end
function CastFishingBonusFishView:initUI(_machine)
    self:createCsbNode(self.m_csbName)
    -- 层级，不代表所有子节点都是该类对象
    self.m_layFishPool    = self:findChild("Lay_fishPool")
    -- 鱼网和鱼要在同一父节点下方便层级操作
    self.m_layFishNetPool = self.m_layFishPool --self:findChild("Lay_fishNetPool")
    self.m_layBulletPool  = self:findChild("Lay_bulletPool")
    self.m_layLaserPool   = self:findChild("Lay_laserPool")

    self.m_tipAnim = util_createAnimation("CastFishing_UStishi.csb")
    self.m_machine:findChild("Node_bonusTipView"):addChild(self.m_tipAnim)
    self.m_tipAnim:setVisible(false)

    self.m_titleView = util_createView("CodeCastFishingSrc.CastFishingBonus.CastFishingBonusTitle")
    self:findChild("Node_title"):addChild(self.m_titleView)
    self.m_titleView:setVisible(false)

    self.m_batteryList = util_createView("CodeCastFishingSrc.CastFishingBonus.CastFishingBonusBatteryList", {self.m_machine})
    self:findChild("Node_paoTai"):addChild(self.m_batteryList)
end

--[[
    一些界面控件
]]
-- 锁定界面
function CastFishingBonusFishView:upDateTitleViewTimes()
    for _poolIndex,_times in ipairs(self.m_bonusGameData.leftTimes) do
        local lab = self.m_titleView:findChild(string.format("m_lb_times_%d", _poolIndex))
        lab:setString(_times)
        for _spIndex=1,2 do
            local sprite = self.m_titleView:findChild(string.format("sp_lab_%d_%d", _poolIndex, _spIndex))
            if sprite then
                local visible = (1 == _spIndex and _times == 1) or (2 == _spIndex and _times ~= 1)
                sprite:setVisible(visible)
            end
        end
    end
end
function CastFishingBonusFishView:launchBulletChangeTitleViewTimes()
    for _poolIndex,_times in ipairs(self.m_bonusGameData.leftTimes) do
        if _poolIndex == self.m_curPoolIndex then
            local nextTimes = _times-1
            local lab = self.m_titleView:findChild(string.format("m_lb_times_%d", _poolIndex))
            local strTimes = string.format("%d", nextTimes)
            lab:setString(strTimes)
            for _spIndex=1,2 do
                local sprite = self.m_titleView:findChild(string.format("sp_lab_%d_%d", _poolIndex, _spIndex))
                if sprite then
                    local visible = (1 == _spIndex and nextTimes == 1) or (2 == _spIndex and nextTimes ~= 1)
                    sprite:setVisible(visible)
                end
            end
        end
    end
end
function CastFishingBonusFishView:playTitleViewOverAnim()
    self.m_titleView:runAction(cc.Sequence:create(
        cc.FadeOut:create(0.5),
        cc.CallFunc:create(function()
            self.m_titleView:pauseForIndex(0)
            self.m_titleView:setVisible(false)
            self.m_titleView:setOpacity(255)
        end)
    ))
end

--[[
    玩法开始和结束
]]
function CastFishingBonusFishView:setBonusGameData(_data)
    self.m_bonusGameData = _data
    --[[
        m_bonusGameData = {
            bSpecial   = true,      --特殊bonus玩法
            bReconnect = false,     --断线重连

            bonusWinCoins = 0       --累计赢钱
            fishingResult = "MISS"  --下一发炮弹结果
            leftTimes  = {          --每个池子的剩余次数 clone()一下 内部使用时会有修改
                [1] = 7,
            },
        }
    ]]

    self.m_batteryList:setBatteryData({
        bSpecial   = self.m_bonusGameData.bSpecial,
    })
end
function CastFishingBonusFishView:startBonusGame(_fun)
    self.m_curPoolIndex = 1
    self.m_endFun = _fun
    self:upDateTitleViewTimes()
    self.m_titleView:setVisible(true)
    
    self.m_gameStep     = 1
    self:startUpDateTick()
    -- 
    self.m_machine:levelPerformWithDelay(self, 1 , function()
        self.m_batteryList:playGrayIdleAnim()
        self:playTitleViewStart(function()
            self:playTipStart(function()
                if self.m_bonusGameData.bSpecial then
                    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_superBonus_chooseBattery)
                else
                    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_commonBonus_chooseBattery)
                end
                
                self.m_batteryList:playIdleAnim()
                self:playNextBatteryStart()
            end)
        end)
    end)
   
end
function CastFishingBonusFishView:endBonusGame(_fun)
    -- 最后一炮如果未捕获 暂停0.5s
    local delayTime = "MISS"==self.m_bonusGameData.fishingResult and 0.5 or 0
    self.m_machine:levelPerformWithDelay(self, delayTime,function()
        self.m_gameStep = 3
        self:playTitleViewOverAnim()

        if "function" == type(self.m_endFun)  then
            self.m_endFun(self.m_bonusGameData.bonusWinCoins)
            self.m_endFun = nil
        end
    end)
end



function CastFishingBonusFishView:playTitleViewStart(_fun)
    self.m_titleView:runCsbAction("suoding", false, _fun)
end
function CastFishingBonusFishView:playTipStart(_fun)
    if self.m_bonusGameData.bSpecial then
        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_commonBonusTipView)
    else
        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_superBonusTipView)
    end

    self.m_tipAnim:setVisible(true)
    self.m_tipAnim:runCsbAction("actionframe", false, function()
        self.m_tipAnim:setVisible(false)
        _fun()
    end)
end

-- 递归开炮
function CastFishingBonusFishView:playNextBatteryStart()
    local curPoolIndex = 0
    for _poolIndex,_times in ipairs(self.m_bonusGameData.leftTimes) do
        if _times > 0 then
            curPoolIndex = _poolIndex
            break
        end
    end

    if 0 == curPoolIndex then
        self:endBonusGame()
        return
    end
    self.m_gameStep     = 2
    self:playTitleViewUnLockAnim(curPoolIndex, function()
        self.m_batteryList:playIdleAnim()
        self.m_batteryList:startGame(self.m_bonusGameData.fishingResult, function()
            self:playNextBatteryStart()
        end)
    end)
end
function CastFishingBonusFishView:playTitleViewUnLockAnim(curPoolIndex, _fun)
    local bUnLock = self.m_curPoolIndex ~= curPoolIndex
    self:changeBulletPoolSize(curPoolIndex)

    if bUnLock then
        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_bonusUnLock)
        local animIndex = curPoolIndex - 1
        local animName  = string.format("jiesuo%d", animIndex)
        self.m_titleView:runCsbAction(animName, false, function()
            self.m_curPoolIndex = curPoolIndex
            self:changeFishObjStateAnimName({
                lessIndex = self.m_curPoolIndex,
                state     = "move",
                animName  = "idle2",
                play      = true,
            })
            self:changeFishObjSpeed({
                lessIndex    = self.m_curPoolIndex,   
                configMultip = self.SceneConfig.FishLeaveMultip
            })
            _fun()
        end)
    else
        _fun()
    end
end
-- 修改子弹图层的区域 (激光需要裁切内容)
function CastFishingBonusFishView:changeBulletPoolSize(_poolIndex)
    local size = cc.size(768, 1370)
    if _poolIndex ~= self.SceneConfig.MaxPool then
        local curSize   = self.m_layBulletPool:getContentSize()
        local lineIndex =  _poolIndex * self.SceneConfig.MaxLine
        local layPoolName = string.format("Lay_fishPool_%d", lineIndex)
        local layPool     = self:findChild(layPoolName) 
        local layPoolSize = layPool:getContentSize()
        local layPoolPos = util_convertToNodeSpace(layPool, self.m_layBulletPool)
        size = cc.size(curSize.width, layPoolPos.y + layPoolSize.height/2)
    end
    
    self.m_layBulletPool:setContentSize(size)
    self.m_layLaserPool:setContentSize(size)
end
-- 根据参数修改当前场上鱼的状态时间线名称
function CastFishingBonusFishView:changeFishObjStateAnimName(_data)
    --[[
        _data = {
            poolIndex    = 1,     -- 条件：等于
            excludeIndex = 1,     -- 条件：不等于
            lessIndex    = 1,     -- 条件：小于
            state        = "",    -- "move"
            animName     = "",
            play         = false
        }
    ]]
    for i,_fishObj in ipairs(self.m_fishList) do
        if (nil ~= _data.poolIndex     and _data.poolIndex    == _fishObj.m_data.poolIndex) or
            (nil ~= _data.excludeIndex and _data.excludeIndex ~= _fishObj.m_data.poolIndex) or
            (nil ~= _data.lessIndex    and _data.lessIndex    >  _fishObj.m_data.poolIndex) then
                
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
function CastFishingBonusFishView:changeFishObjSpeed(_data)
    --[[
        _data = {
            poolIndex = 1,
            excludeIndex = 1,   

            -- 基础速度的倍数
            configMultip = 2,
        }
    ]]
    local manager = CastFishingManager:getInstance()
    for i,_fishObj in ipairs(self.m_fishList) do
        if (nil ~= _data.poolIndex     and _data.poolIndex    == _fishObj.m_data.poolIndex) or
            (nil ~= _data.excludeIndex and _data.excludeIndex ~= _fishObj.m_data.poolIndex) or
            (nil ~= _data.lessIndex    and _data.lessIndex    >  _fishObj.m_data.poolIndex) then

            local fishConfig = _fishObj.m_config
            local fishSpeed = manager:getSceneFishAttr(self.m_mode, fishConfig.id, CastFishingManager.StrAttrKey.Speed, fishConfig.speed)
            if "number" == type(_data.configMultip) then
                fishSpeed = fishSpeed * _data.configMultip
            end
            _fishObj:setSpeed(fishSpeed)
        end
    end
end
-- 结束bonus将列表所有鱼移入池子
function CastFishingBonusFishView:endBonusGamePushAllFishObj()
    for i,_fishObj in ipairs(self.m_fishList) do
        _fishObj:setVisible(false)
        table.insert(self.m_fishPool, _fishObj)
    end
    self.m_fishList = {}
end
--[[
    计时器刷帧
]]
function CastFishingBonusFishView:startUpDateTick()
    self:stopUpDateTick()
    self:onUpdate(function(dt)
        self:Tick(dt)
    end)
end
function CastFishingBonusFishView:stopUpDateTick()
    self:unscheduleUpdate()
end

function CastFishingBonusFishView:Tick(_dt)
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
    -- 倒计时
    self:bulletTimeTick(_dt)
end
-- 补充鱼 
function CastFishingBonusFishView:createFishTick()
    -- 入场
    if 1 == self.m_gameStep then
        for _poolIndex=1,self.SceneConfig.MaxPool do
            local maxLine = 1==_poolIndex and self.SceneConfig.MaxLine or 1
            for i=1,maxLine do
                local lineIndex = _poolIndex * self.SceneConfig.MaxLine - (i - 1)
                
                self:createFishObjByLineData(lineIndex)
            end
        end
    -- 开始捕鱼
    elseif 2 == self.m_gameStep then
        for _poolIndex=1,self.SceneConfig.MaxPool do
            if _poolIndex >= self.m_curPoolIndex then
                local maxLine = _poolIndex == self.m_curPoolIndex and self.SceneConfig.MaxLine or 1
                for i=1,maxLine do
                    local lineIndex = _poolIndex * self.SceneConfig.MaxLine - (i - 1)
                    self:createFishObjByLineData(lineIndex)
                end
            end
        end
    -- 玩法结束
    elseif 3 == self.m_gameStep then
    end
end
function CastFishingBonusFishView:createFishObjByLineData(_lineIndex)
    local manager   = CastFishingManager:getInstance()
    -- 每个等级的池子有N行
    local poolIndex = math.ceil(_lineIndex / self.SceneConfig.MaxLine)
    local fishId    = self.SceneConfig.PoolFishId[poolIndex]
    local needCount = manager:getSceneFishAttr(self.m_mode, fishId, CastFishingManager.StrAttrKey.Count, 4)
    
    for i,_fishObj in ipairs(self.m_fishList) do
        local fishData = _fishObj.m_data
        if fishData.lineIndex == _lineIndex then
            needCount = needCount - 1
        end
    end
    if needCount > 0 then
        if poolIndex > self.SceneConfig.MaxPool then
            return
        end
        
        for i=1,needCount do

            local fishData = {}
            fishData.sMode       = self.m_mode
            fishData.multip      = 0
            fishData.probability = 0
            fishData.poolIndex   = poolIndex
            fishData.lineIndex   = _lineIndex
            if poolIndex < 4 then
                local fishCreatData  = manager:randomFishData({sMode = self.m_mode, lineIndex = _lineIndex})
                fishData.multip      = fishCreatData[1]
                fishData.probability = fishCreatData[2]
            end
            local fishObj  = self:createFishObj(fishId)
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
function CastFishingBonusFishView:createFishObj(_fishId)
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
function CastFishingBonusFishView:getNewFishObjId()
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
function CastFishingBonusFishView:changeFishObjOrder(_fishObj, _type)
    local order = _type
    _fishObj:setLocalZOrder(order)
end
function CastFishingBonusFishView:isShowReward()
    return true
end
function CastFishingBonusFishView:getFishStartPos(_params)
    --[[
        _params = [
            fishObj = {}
        ]
    ]]
    local manager = CastFishingManager:getInstance()
    local direction = 1
    local pos = cc.p(0, 0)
    local poolSize = self.m_layFishPool:getContentSize()
    local fishConfig   = _params.fishObj.m_config
    local fishData     = _params.fishObj.m_data
    local fishObjWidth = fishConfig.shape[2]
    local poolIndex    = fishData.poolIndex
    local lineIndex    = fishData.lineIndex
    -- 奇数向右 偶数向左 
    direction = (math.mod(lineIndex, 2) == 0) and -1 or 1
    -- 读配置
    direction = direction * self.SceneConfig.PoolFishDirection[poolIndex]
    -- 高度固定
    local layPoolName = string.format("Lay_fishPool_%d", lineIndex)
    local layPool    = self:findChild(layPoolName)
    local layPoolPos = util_convertToNodeSpace(layPool, self.m_layFishPool)
    pos.y = layPoolPos.y
    -- 尾随上一条鱼
    local intervalX    = manager:getSceneFishAttr(self.m_mode, fishConfig.id, CastFishingManager.StrAttrKey.IntervalX, fishObjWidth * 3)
    -- 数值要求要有偏移随机值 -10% ~ 10 %
    local intervalXOffset = intervalX * (math.random(0, 30)/100)
    intervalX = (intervalX - intervalXOffset) + math.random(0, intervalXOffset * 2)
    
    local initPosX     = 1 == direction and fishObjWidth/2 or poolSize.width - fishObjWidth/2
    local lastPosX     = 1 == direction and poolSize.width - fishObjWidth/2 or fishObjWidth/2 
    for i,_fishObj in ipairs(self.m_fishList) do
        if lineIndex == _fishObj.m_data.lineIndex then
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

    return pos,direction
end

function CastFishingBonusFishView:checkCollisionTick()
    local fnCheckCollisionByList = function(_bulletList)
        for bulletIndex=#_bulletList,1,-1 do
            -- 捕获列表和碰撞列表
            local bCapture   = false
            local captureFishList = {}
            local bCollision = false
            local collisionFishList = {}
            local bulletObj  = _bulletList[bulletIndex]
            local bLaser     = bulletObj:isLaser()

            for fishIndex=#self.m_fishList,1,-1 do
                local fishObj = self.m_fishList[fishIndex]
                local bCurCollision  = self:checkCollision(bulletObj, fishObj) and bulletObj:checkCollision(fishObj)
                local bCurCapture    = bCurCollision and self:checkCapture(bulletObj, fishObj)
                bCollision = bCollision or bCurCollision
                bCapture   = bCapture or bCurCapture

                if bCurCapture then
                    table.remove(self.m_fishList, fishIndex)
                    table.insert(self.m_fishCollisionList, fishObj)
                    -- 普通炮弹捕获一条 激光可以捕获不同行数各一条
                    if bLaser then   
                        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_superBonus_fireHit)
                        fishObj:setStateAnimName_collect("shouji2")
                        fishObj:playStateAnim_collect(nil, true)                    
                        table.insert(bulletObj.m_data.captureList, fishObj)
                    else
                        table.insert(captureFishList, fishObj)
                        break
                    end
                -- 碰撞改为穿鱼
                elseif bCurCollision then
                    table.insert(bulletObj.m_data.missFishId, fishObj.m_data.objId)
                    table.insert(collisionFishList, fishObj)
                    -- break
                end
            end
            if not bLaser then
                if bCapture then
                    table.remove(_bulletList, bulletIndex)
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
                    -- table.remove(_bulletList, bulletIndex)
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
    end
    
    fnCheckCollisionByList(self.m_bulletList)
    fnCheckCollisionByList(self.m_bulletTimeList)
end

function CastFishingBonusFishView:checkCollision(_bulletObj, _fishObj)
    -- 鱼的等级和当前鱼池的等级不符合
    local fishPoolIndex =  _fishObj.m_data.poolIndex
    if fishPoolIndex ~= self.m_curPoolIndex then
        return false
    end
    -- 已经碰撞过了
    for i,_fishObjId in ipairs(_bulletObj.m_data.missFishId) do
        if _fishObj.m_data.objId == _fishObjId then
            return false
        end
    end

    return true
end
-- 返回是否可以捕获碰到的鱼
function CastFishingBonusFishView:checkCapture(_bulletObj, _fishObj)
    -- 结果为字符串 时 "MISS" "BONUS" 
    if "MISS" == _bulletObj.m_data.fishingResult then
        return false
    end
    -- 激光可以捕获相同池子不同行数的鱼各一条
    local bLaser = _bulletObj:isLaser()
    if bLaser then
        local lineIndex = _fishObj.m_data.lineIndex
        for i,fishObj in ipairs(_bulletObj.m_data.captureList) do
            if lineIndex == fishObj.m_data.lineIndex then
                return false
            end
        end
    end
    
    return true
end
function CastFishingBonusFishView:playBulletCollisionAnim(_bulletObj, _fishObjList, _bCapture, _fun)
    local bLaser = _bulletObj:isLaser()
    -- 未捕获
    if not _bCapture then
        if bLaser then
            local particleCsb = _bulletObj.m_data.particle
            self:laserBulletParticleDisappear(particleCsb)
        end
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
        -- self.m_machine:levelPerformWithDelay(self, 15/30 + 0.5, function()
            _fun()
        -- end)
    -- 捕获
    else
        local animTime = 0
        if bLaser then
            local particleCsb = _bulletObj.m_data.particle
            self:laserBulletParticleDisappear(particleCsb)
        else
            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_freeBattery_fireHit)
            -- 使用子弹和鱼中间的坐标创建鱼网
            for i,_fishObj in ipairs(_fishObjList) do
                local fishNetObj = self:createFishNetObj(_bulletObj, _fishObj)
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
            end
        end
        -- 鱼的反馈
        for i,_fishObj in ipairs(_fishObjList) do
            local fishObj = _fishObj
            self:changeFishObjOrder(fishObj, self.FishOrder.Capture)

            -- 金币鱼 立刻播收集时间线,只留金币文本,身体淡出
            if fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Coins then
                -- 屏蔽激光捕鱼
                if not bLaser then
                    fishObj:playStateAnim_collect(nil)
                    fishObj:playCoinsCollectFadeOut(function()
                        self:changeFishObjOrder(fishObj, self.FishOrder.FishNet + 1)
                    end)
                    -- 收集时间
                    animTime = math.max(animTime, 24/30)
                end
            -- wild鱼 
            elseif fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Wild then
            -- jackpot鱼 
            elseif fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Jackpot then
                -- 屏蔽激光捕鱼
                if not bLaser then
                    self.m_machine:levelPerformWithDelay(self, 3/30, function()
                        fishObj:setStateAnimName_collect("shouji_1")
                        fishObj:playStateAnim_collect(nil, true)
                    end)
                end
            end
        end

        self.m_machine:levelPerformWithDelay(self, animTime, function()
            _fun()
        end)
    end
end
function CastFishingBonusFishView:createFishNetObj(_bulletObj, _fishObj)
    local fishNetObj = nil
    if #self.m_fishNetPool > 0 then
        for i,v in ipairs(self.m_fishNetPool) do
            if not v:isVisible() then
                fishNetObj = table.remove(self.m_fishNetPool, i)
                break
            end
        end
    end
    if not fishNetObj then
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

function CastFishingBonusFishView:fishMoveTick()
    local poolSize = self.m_layFishPool:getContentSize()
    local poolRect = cc.rect(0, 0, poolSize.width, poolSize.height)
    local objList = self.m_fishList
    local objPool = self.m_fishPool

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
function CastFishingBonusFishView:playFishLeaveAnim(_fishObj)
    _fishObj:playFishLeaveFadeOut(function()
        _fishObj:setVisible(false)
        table.insert(self.m_fishPool, _fishObj)
    end)
end
function CastFishingBonusFishView:removeFishClearBulletMissList(_fishObjId)
    for i,_bulletObj in ipairs(self.m_bulletList) do
        for _idIndex,fishObjId in ipairs(_bulletObj.m_data.missFishId) do
            if fishObjId == _fishObjId then
                table.remove(_bulletObj.m_data.missFishId, _idIndex)
                return
            end
        end
    end
end

function CastFishingBonusFishView:createBullet(_params)
    --[[
        _params = {
            sMode         = CastFishingManager.StrMode.Free
            -- 子弹的创建跟随所处环境的变化而变化,舍弃传入的id 22.07.04
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
    -- 
    local bonusStartBulletId = 2
    local bulletId  = bonusStartBulletId
    if self.m_bonusGameData.bSpecial then
        bulletId  = 100
    else
        bulletId = bonusStartBulletId + (self.m_curPoolIndex - 1)
    end

    local bulletConfig = manager:getBulletConfig(bulletId)
    local bLaser = false
    for i,_fishObj in ipairs(self.m_bulletPool) do
        if bulletId == _fishObj.m_config.id then
            bulletObj = table.remove(self.m_bulletPool, i)
            -- 有些逻辑可能会让透明度为 0
            bulletObj:setOpacity(255)
            bLaser = bulletObj:isLaser()
            break
        end
    end
    if nil == bulletObj then
        local codePath   = bulletConfig.codePath
        bulletObj = util_createView(codePath, bulletConfig)
        bLaser = bulletObj:isLaser()
        local bulletParent = bLaser and self.m_layLaserPool or self.m_layBulletPool
        bulletParent:addChild(bulletObj)
        bulletObj:setVisible(false)
    end
    local pos = self.m_layBulletPool:convertToNodeSpace(_params.bulletPos)
    local bulletSize = bulletObj:getBulletSize()
    bulletObj:setPosition(pos)
    -- 插入特殊数据 存一下粒子节点
    if bLaser then
        _params.autoDisappearTime = bulletConfig.autoDisappearTime
        _params.captureList = {}
        _params.particle = self:createLaserBulletParticle(bulletObj)
    end
    -- 存一下miss鱼的id
    _params.missFishId = {}
    bulletObj:setBulletData(_params)
    local bulletSpeed = manager:getBulletAttr(bulletObj.m_config.id, CastFishingManager.StrAttrKey.Speed, bulletObj.m_config.speed) 
    bulletObj:setSpeed(bulletSpeed)
    bulletObj:playStateAnim_move()
    bulletObj:setVisible(true)
    -- 区分 延时自动消失的子弹 和 飞行越界消失的子弹
    if bLaser then
        table.insert(self.m_bulletTimeList, bulletObj)
    else
        table.insert(self.m_bulletList, bulletObj)
    end
end
-- 特殊子弹 激光的粒子
function CastFishingBonusFishView:createLaserBulletParticle(_bulletObj)
    local animCsb = nil
    local parent = self.m_layLaserPool
    if #self.m_laserParticlePool > 0 then
        animCsb = table.remove(self.m_laserParticlePool, 1)
    else
        animCsb = util_createAnimation("CastFishing_jiguanglizi.csb")
        parent:addChild(animCsb)
        animCsb:setVisible(false)
    end
    local pos = util_convertToNodeSpace(_bulletObj, parent)
    animCsb:setPosition(pos)
    animCsb:setVisible(true)

    return animCsb
end
function CastFishingBonusFishView:laserBulletParticleDisappear(_particleCsb)
    local particleNode1 = _particleCsb:findChild("Particle_1")
    local particleNode2 = _particleCsb:findChild("Particle_2")
    -- 粒子淡出后 要保证下次使用时就是满状态
    local actList = {}
    table.insert(actList, cc.CallFunc:create(function()
        particleNode1:stopSystem()
        particleNode2:stopSystem()
        util_setCascadeOpacityEnabledRescursion(particleNode1, true)
        util_setCascadeOpacityEnabledRescursion(particleNode2, true)
        particleNode1:runAction(cc.FadeOut:create(0.5))
        particleNode2:runAction(cc.FadeOut:create(0.5))
    end))
    table.insert(actList, cc.DelayTime:create(1))
    table.insert(actList, cc.CallFunc:create(function()
        _particleCsb:setVisible(false)
        particleNode1:resetSystem()
        particleNode2:resetSystem()
    end))
    table.insert(actList, cc.DelayTime:create(1))
    table.insert(actList, cc.CallFunc:create(function()
        table.insert(self.m_laserParticlePool, _particleCsb)
    end))

    _particleCsb:runAction(cc.Sequence:create(actList))
end
function CastFishingBonusFishView:bulletFlyTick()
    local poolSize = self.m_layBulletPool:getContentSize()
    local poolRect = cc.rect(0, 0, poolSize.width, poolSize.height)
    local objList = self.m_bulletList
    local objPool = self.m_bulletPool

    for i=#objList,1,-1 do
        local bulletObj = objList[i]
        local direction = bulletObj.m_moveData.dir
        local speed     = bulletObj.m_moveData.speed
        local distance  = direction * speed
        local curPosY   = bulletObj:getPositionY()
        local nextPosY  = curPosY + distance
        local bulletSize = bulletObj:getBulletSize()
        local minY = cc.rectGetMinY(poolRect)
        local maxY = cc.rectGetMaxY(poolRect) - bulletSize.height/2
        if self.m_curPoolIndex == self.SceneConfig.MaxPool then
            maxY = cc.rectGetMaxY(poolRect) + bulletSize.height * 2
        end
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
function CastFishingBonusFishView:bulletTimeTick(_dt)
    local objList = self.m_bulletTimeList
    local objPool = self.m_bulletPool
    for i=#objList,1,-1 do
        local bulletObj = objList[i]
        bulletObj.m_data.autoDisappearTime = math.max(0, bulletObj.m_data.autoDisappearTime - _dt)
        local bRemove = bulletObj.m_data.autoDisappearTime <= 0
        if bRemove then
            table.remove(objList, i)
            local data = {}
            data.type = CastFishingBulletObj.DisappearType.Time
            data.fishObjList = bulletObj.m_data.captureList

            
            local bCapture = #data.fishObjList > 0
            self:playBulletCollisionAnim(bulletObj, data.fishObjList, bCapture,function()
                bulletObj:setVisible(false)
                bulletObj:bulletDisappear(data)
                table.insert(objPool, bulletObj)
            end)
        end
    end
end
-- 子弹因为位置越界离场时的淡出
function CastFishingBonusFishView:playBulletLeaveAnim(_bulletObj, _fun)
    _bulletObj:runAction(cc.Sequence:create(
        cc.FadeOut:create(0.1),
        cc.CallFunc:create(function()
            _fun()
        end)
    ))
end

return CastFishingBonusFishView