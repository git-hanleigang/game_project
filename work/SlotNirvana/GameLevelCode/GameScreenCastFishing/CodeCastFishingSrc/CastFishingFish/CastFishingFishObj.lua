--[[
    所有场景鱼的基类
]]
local CastFishingFishObj = class("CastFishingFishObj", cc.Node)
local CastFishingManager = require "CodeCastFishingSrc.CastFishingFish.CastFishingManager"
local CastFishingSceneConfig = require "CodeCastFishingSrc.CastFishingFish.CastFishingSceneConfig"

function CastFishingFishObj:initData_(_config, _machine)
    self.m_config  = _config
    self.m_machine = _machine
    self.m_data = {}
    self.m_moveData = { 
        -- 方向
        dir = 1,    
        -- 速度
        speed = 0,
    }
    -- 点击回调(只触发1次)
    self.m_onceClickFn = nil
    self:initUI()
end
-- 放回池子时 或者取出使用时清理数据
function CastFishingFishObj:resetFishObjData()
    self.m_stateAnimName_move = nil
    self.m_stateAnimName_collect = nil
    self:clearOnceClickCallBack()
    self:playCoinsIdleAnim()
end
-- 设置数据和修改其中一个数据
--[[
    _data = {
        objId           = 0      --所在场景的唯一id
        sMode           = "base" --鱼池模式
        multip          = 0,     --分值倍数
        probability     = 0,     --权重  
        fishNetObjList  = {}     --鱼网对象列表,鱼放入鱼池时，隐藏列表内的鱼网后清空列表

        poolIndex       = 1,     --bonus等级
        lineIndex       = 1,     --bonus行数
    }
]]
function CastFishingFishObj:setFishData(_data)
    self.m_data = _data

    self:upDataMultipShow()
    -- self:initCollisionArea()
end
function CastFishingFishObj:changeFishData(_data)
    for k,v in pairs(_data) do
        self.m_data[k] = v
    end    
end

function CastFishingFishObj:initUI()
    local csbPath = self.m_config.csbPath
    self.m_animCsb = util_createAnimation(csbPath)
    self:addChild(self.m_animCsb)
    self:addClick(self.m_animCsb:findChild("Panel_click"))

    self.m_fishParent = self.m_animCsb:findChild("Node_fish")
    local spinePath = self.m_config.spinePath
    self.m_animSpine = util_spineCreate(spinePath,true,true)
    self.m_fishParent:addChild(self.m_animSpine)
    util_spinePlay(self.m_animSpine, self.m_config.spineIdle, false)

    local coinsParent = self.m_animCsb:findChild("Node_coins")
    if coinsParent then
        self.m_coinsCsb = util_createAnimation("CastFishing_jine.csb")
        coinsParent:addChild(self.m_coinsCsb)
        self.m_coinsLab = self.m_coinsCsb:findChild("m_lb_coins")
    end

    util_setCascadeOpacityEnabledRescursion(self, true)
end

--[[
    spine相关
]]
function CastFishingFishObj:playSpineAnim(_name,_loop,_fun)
    util_spinePlay(self.m_animSpine, _name, _loop)
    if nil ~= _fun then
        self:registerSpineAnimCallBack(_name, _fun)
    end    
end
function CastFishingFishObj:registerSpineAnimCallBack(_name, _fun)
    util_spineEndCallFunc(self.m_animSpine, _name, function()
        _fun() 
    end) 
end
--[[
    分值奖励展示
]]
function CastFishingFishObj:upDataMultipShow()
    local labCoins = self.m_coinsLab
    if nil ~= labCoins then
        local curBet = self.m_machine:getCastFishingCurBet()
        local mutlip = self.m_data.multip
        local coins  = curBet * mutlip
        local sCoins = util_formatCoins(coins, 3)
        labCoins:setString(sCoins) 
    end
end
function CastFishingFishObj:changeRewardShow(_bShow)
    local rewardNode = self.m_animCsb:findChild("reward")
    rewardNode:setVisible(_bShow)
end
function CastFishingFishObj:playCoinsIdleAnim()
    if nil ~= self.m_coinsCsb then
        self.m_coinsCsb:runCsbAction("idle", false)
    end
end
--[[
    游动数据包相关
]]
function CastFishingFishObj:setDirection(_direction)
    self.m_moveData.dir = _direction
    local scaleX = self.m_config.resDirection *  self.m_moveData.dir
    local fishNode = self.m_animCsb:findChild("Node_fish")
    fishNode:setScaleX(scaleX)
end
function CastFishingFishObj:setSpeed(_speed)
    self.m_moveData.speed = _speed
end
-- 开启/停止速度线性渐变
function CastFishingFishObj:startSpeedChangeAction(_time, _times, _addSpeed)
    local surplusAddSpeed  = _addSpeed
    local delayTime    = _time / _times
    local onceAddSpeed = _addSpeed / _times

    self.m_updateSpeedChange = schedule(self,function()
        onceAddSpeed = surplusAddSpeed >= onceAddSpeed and onceAddSpeed or surplusAddSpeed
        onceAddSpeed = math.max(0, onceAddSpeed)
        surplusAddSpeed = math.max(0, surplusAddSpeed - onceAddSpeed)
        self.m_moveData.speed = self.m_moveData.speed + onceAddSpeed
        if surplusAddSpeed <= 0 then
            self:stopSpeedChangeAction()
        end
    end, delayTime)
end
function CastFishingFishObj:stopSpeedChangeAction()
    if nil ~= self.m_updateSpeedChange then
        print("[CastFishingFishObj:stopSpeedChangeAction] 停止加速")
        self:stopAction(self.m_updateSpeedChange)
        self.m_updateSpeedChange = nil
    end
end

-- 游动离场淡出效果
function CastFishingFishObj:playFishLeaveFadeOut(_fun)
    local actTime = 0.4
    local targetX = self.m_moveData.dir * self.m_moveData.speed * 30 --fps
    self:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.MoveBy:create(actTime, cc.p(targetX, 0)),
            cc.FadeOut:create(actTime)
        ),
        cc.CallFunc:create(function()
            if _fun then
                _fun()
            end
        end)
    ))
end
--[[
    状态展示变化: 修改时间线名称时注意外部接口 registerSpineAnimCallBack 的使用
    游动
    中子弹但未捕获
    中子弹并且捕获
    收集反馈
]]
--游动
function CastFishingFishObj:playStateAnim_move()
    self:playSpineAnim(self:getStateAnimName_move(), true)
end
function CastFishingFishObj:getStateAnimName_move()
    if nil ~= self.m_stateAnimName_move then
        return self.m_stateAnimName_move
    else
        return "idle"
    end
end
function CastFishingFishObj:setStateAnimName_move(_animName)
    self.m_stateAnimName_move =_animName
end

--中子弹但未捕获
function CastFishingFishObj:playStateAnim_miss(_fun)
    self:playSpineAnim("miss", false, _fun)
end
--中子弹并且捕获
function CastFishingFishObj:playStateAnim_hit(_fun)
    self:playSpineAnim("idle", false, _fun)
end
--收集反馈
function CastFishingFishObj:playStateAnim_collect(_fun, _loop)
    self:playSpineAnim(self:getStateAnimName_collect(), _loop, _fun)
end
function CastFishingFishObj:getStateAnimName_collect()
    if nil ~= self.m_stateAnimName_collect then
        return self.m_stateAnimName_collect
    else
        return "shouji"
    end
end
function CastFishingFishObj:setStateAnimName_collect(_animName)
    self.m_stateAnimName_collect =_animName
end
function CastFishingFishObj:playCoinsCollectFadeOut(_fun)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()
        -- 淡出 -> 硬切
        self.m_fishParent:setVisible(false)
        -- self.m_fishParent:runAction(cc.FadeOut:create(9/30))
        if _fun then
            _fun()
        end

        waitNode:removeFromParent()
    end, 15/30)
end
function CastFishingFishObj:playLaserCollectFadeOut(_fun1, _fun2)
    local collectName = self:getStateAnimName_collect()
    self:registerSpineAnimCallBack(collectName, function()
        if _fun1 then
            _fun1()
        end
        self:playSpineAnim("shouji2_1", false, _fun2) 
    end)
end


--[[
    碰撞区域
]]
function CastFishingFishObj:initCollisionArea()
    if nil ~= self.m_collisionArearBrush then
        return
    end
    -- 碰撞区域
    local manager = CastFishingManager:getInstance()
    if manager.m_bShowShape then
        local brush = cc.DrawNode:create()
        self:addChild(brush) 
        local shapeConfig = manager:getSceneFishAttr(self.m_data.sMode, self.m_config.id, CastFishingManager.StrAttrKey.Shape, self.m_config.shape) 
        if shapeConfig[1] == CastFishingSceneConfig.ShapeType.Circular then
            brush:drawSolidCircle(cc.p(0, 0), shapeConfig[2], 0, 50, cc.c4f(0, 1, 0, 1))
        else
            local width  = shapeConfig[2]
            local height = shapeConfig[3]
            brush:drawSolidRect(cc.p(-width/2, -height/2), cc.p(width/2, height/2), cc.c4f(0, 1, 0, 1))
        end
        local blendFunc = {GL_ONE, GL_ONE}
        brush:setBlendFunc(blendFunc)
        brush:visit()
        self.m_collisionArearBrush = brush
        util_setCascadeOpacityEnabledRescursion(self, true)
    end
end

--[[
    存贮的其他对象列表处理
]]
-- 鱼网
function CastFishingFishObj:insertFishNetObjList(_fishNetObj)
    if not self.m_data.fishNetObjList then
        self.m_data.fishNetObjList = {}
    end
    table.insert(self.m_data.fishNetObjList, _fishNetObj)
end
function CastFishingFishObj:clearFishNetObjList()
    if nil ~= self.m_data.fishNetObjList and #self.m_data.fishNetObjList > 0 then
        for i,v in ipairs(self.m_data.fishNetObjList) do
            v:setVisible(false)
        end
        self.m_data.fishNetObjList = {}
    end
end

--[[
    点击处理
]]
function CastFishingFishObj:addClick(node)
    if not node then
        return
    end
    node:addTouchEventListener(handler(self, self.fishObjTouchEvent))
end
function CastFishingFishObj:fishObjTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
    elseif eventType == ccui.TouchEventType.moved then
    elseif eventType == ccui.TouchEventType.ended then
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()
        local offx = math.abs(endPos.x - beginPos.x)
        local offy = math.abs(endPos.y - beginPos.y)
        if offx < 50 and offy < 50 and globalData.slotRunData.changeFlag == nil then
            self:onFishClick(sender)
        end
    elseif eventType == ccui.TouchEventType.canceled then
        self:onFishClick(sender, eventType)
    end
end

function CastFishingFishObj:registerOnceClickCallBack(_fun)
    self:clearOnceClickCallBack()

    if "function" ~= type(_fun) then
        return
    end
    self.m_onceClickFn = _fun
end
function CastFishingFishObj:clearOnceClickCallBack()
    self.m_onceClickFn = nil
end
function CastFishingFishObj:onFishClick(_sender)
    if "function" == type(self.m_onceClickFn) then
        self.m_onceClickFn(self)
        self.m_onceClickFn = nil
    end
end

return CastFishingFishObj
