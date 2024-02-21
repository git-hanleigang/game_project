---
--xcyy
--2018年5月23日
--OwlsomeWizardWheelView.lua
local PublicConfig = require "OwlsomeWizardPublicConfig"
local OwlsomeWizardWheelView = class("OwlsomeWizardWheelView",util_require("base.BaseView"))

local MAX_WHEEL_COUNT   =   16  -- 转盘区域数

--转盘转动方向
local DIRECTION = {
    CLOCK_WISE = 1,             --顺时针
    ANTI_CLOCK_WISH = -1,       --逆时针
}

local DIRECTION_START   =       0
local DIRECTION_UP      =       1
local DIRECTION_RIGHT   =       2
local DIRECTION_DOWN    =       3
local DIRECTION_LEFT    =       4
local DIRECTION_END     =       5

--小球速度
local SPEED_BALL    =       940
local RADIUS_WHEEL  =       260

function OwlsomeWizardWheelView:initUI(params)
    self.m_wheelDownCount = 2
    self.m_machine = params.machine
    self:createCsbNode("OwlsomeWizard_wheel.csb")
    --创建外圈轮盘
    self:createOuterWheel()
    --创建内圈轮盘
    self:createInnerWheel()

    --创建指针
    self.m_pointer = util_createAnimation("OwlsomeWizard_wheel_zhizheng.csb")
    self:findChild("Node_zhizheng"):addChild(self.m_pointer)
    self:runPointerIdle()

    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    --猫头鹰角色
    self.m_role_node = util_createView("CodeOwlsomeWizardSrc.OwlsomeWizardSpineRole",{machine = self.m_machine})
    self:findChild("Node_juese"):addChild(self.m_role_node)

    --转动特效
    self.m_turnParticle = util_createAnimation("OwlsomeWizard_wheel_zhuan_tx.csb")
    self:findChild("Node_zhuanpan"):addChild(self.m_turnParticle)
    self.m_turnParticle:setVisible(false)

    self.m_turnLight = util_createAnimation("OwlsomeWizard_wheel_zhuan_tx1.csb")
    self:findChild("Node_zhuan_tx1"):addChild(self.m_turnLight)
    self.m_turnLight:setVisible(false)

    --切换特效
    self.m_switchLight = util_createAnimation("OwlsomeWizard_wheel_bet_qiehuan.csb")
    self:findChild("ef_betqiehuan"):addChild(self.m_switchLight)
    self.m_switchLight:setVisible(false)
end

--[[
    创建外圈轮盘
]]
function OwlsomeWizardWheelView:createOuterWheel()
    local params = {
        doneFunc = handler(self,self.outerWheelDown),        --停止回调
        rotateNode = self:findChild("Node_waiquan"),      --需要转动的节点
        sectorCount = MAX_WHEEL_COUNT,     --总的扇面数量
        direction = DIRECTION.CLOCK_WISE,       --转动方向
        parentView = self,  --父界面

        startSpeed = 0,     --开始速度
        minSpeed = 30,      --最小速度(每秒转动的角度)
        maxSpeed = 600,     --最大速度(每秒转动的角度)
        accSpeed = 400,      --加速阶段的加速度(每秒增加的角速度)
        reduceSpeed = 120,   --减速结算的加速度(每秒减少的角速度)
        turnNum = 0,         --开始减速前转动的圈数
        minDistance = 30,   --以最小速度行进的距离
        backDistance = 1,    --回弹距离
        backTime = 0.5      --回弹时间
    }
    self.m_wheel_outer = util_require("CodeOwlsomeWizardSrc.OwlsomeWizardWheelNode"):create(params)
    self:addChild(self.m_wheel_outer)

    self.m_outerItems = {}
    for index = 1,MAX_WHEEL_COUNT do
        local item = util_createAnimation("OwlsomeWizard_waiquan_pianduan.csb")
        self.m_outerItems[index] = item
        self:findChild("Node_w_"..index):addChild(item)
        item.m_index = index

        local lbl_coins_csb = util_createAnimation("OwlsomeWizard_waiquan_shuzhi.csb")
        item:findChild("Node_shuzhi"):addChild(lbl_coins_csb)
        item.m_csb_coins = lbl_coins_csb
    end
end

--[[
    外圈转盘停止回调
]]
function OwlsomeWizardWheelView:outerWheelDown()
    self:wheelDown()
    
end

--[[
    创建内圈转盘
]]
function OwlsomeWizardWheelView:createInnerWheel()
    local params = {
        doneFunc = handler(self,self.innerWheelDown),        --停止回调
        rotateNode = self:findChild("Node_neiquan"),      --需要转动的节点
        sectorCount = MAX_WHEEL_COUNT,     --总的扇面数量
        direction = DIRECTION.ANTI_CLOCK_WISH,       --转动方向
        parentView = self,  --父界面

        startSpeed = 0,     --开始速度
        minSpeed = 30,      --最小速度(每秒转动的角度)
        maxSpeed = 600,     --最大速度(每秒转动的角度)
        accSpeed = 400,      --加速阶段的加速度(每秒增加的角速度)
        reduceSpeed = 120,   --减速结算的加速度(每秒减少的角速度)
        turnNum = 4,         --开始减速前转动的圈数
        minDistance = 30,   --以最小速度行进的距离
        backDistance = 1,    --回弹距离
        backTime = 0.5      --回弹时间
    }
    self.m_wheel_inner = util_require("Levels.BaseReel.BaseWheelNew"):create(params)
    self:addChild(self.m_wheel_inner)

    self.m_innerItems = {}
    for index = 1,MAX_WHEEL_COUNT do
        local item = util_createAnimation("OwlsomeWizard_neiquan_pianduan.csb")
        self.m_innerItems[index] = item
        self:findChild("Node_n_"..index):addChild(item)
        item.m_index = index

        local lbl_coins_csb = util_createAnimation("OwlsomeWizard_neiquan_shuzhi.csb")
        item:findChild("Node_shuzhi"):addChild(lbl_coins_csb)
        item.m_csb_coins = lbl_coins_csb
    end
end

--[[
    内圈转盘停止回调
]]
function OwlsomeWizardWheelView:innerWheelDown()
    self:wheelDown()
end

--[[
    获取转盘上的格子--(0内圈 1外圈)
]]
function OwlsomeWizardWheelView:getWheelItem(wheelType,index)
    if wheelType == 0 then
        return self.m_innerItems[index + 1]
    else
        return self.m_outerItems[index + 1]
    end
end

--[[
    切bet特效
]]
function OwlsomeWizardWheelView:runSwithLightAni(func)
    self.m_switchLight:stopAllActions()
    self.m_switchLight:setVisible(true)
    self.m_switchLight:runCsbAction("reset")

    for index = 1,4 do
        local particle = self.m_switchLight:findChild("ef_lizi_"..index)
        if particle then
            particle:resetSystem()
        end
    end

    self:showRefreshLight()
    
    performWithDelay(self.m_switchLight,function()
        self.m_switchLight:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end,100 / 60)
end

--[[
    刷新转盘
]]
function OwlsomeWizardWheelView:updateWheelView(data)
    self.m_data = data
    
    for index = 1,MAX_WHEEL_COUNT do
        local outerItem = self.m_outerItems[index]
        local innerItem = self.m_innerItems[index]

        local outerData = data[1][index]
        local innerData = data[2][index]

        
        self:updateOuterItemShow(outerItem,outerData)

        if innerData then
            self:updateInnerItemShow(innerItem,innerData)
        end
    end
end

--[[
    刷新内圈单格区域显示
]]
function OwlsomeWizardWheelView:updateInnerItemShow(item,data,isShowEffect)
    if not data then
        data = 100
    end

    if data ~= 200 then
        item:findChild("Node_1"):setVisible((item.m_index % 2) == 1)
        item:findChild("Node_3"):setVisible((item.m_index % 2) == 0)
        item:findChild("Node_2"):setVisible(false)
    else
        item:findChild("Node_2"):setVisible(true)
        item:findChild("Node_1"):setVisible(false)
        item:findChild("Node_3"):setVisible(false)
    end
    

    
    if not isShowEffect then
        item:runCsbAction("idle")
        item:findChild("Node_effect"):setVisible(false)
    end
    

    local coins_csb = item.m_csb_coins
    if data == 100 then
        coins_csb:setVisible(false)
    elseif data == 200 then
        coins_csb:setVisible(true)
        coins_csb:findChild("Node_chengbei"):setVisible(false)
        coins_csb:findChild("Node_spins"):setVisible(false)
        coins_csb:findChild("Node_up"):setVisible(true)
    else
        coins_csb:setVisible(true)
        coins_csb:findChild("Node_up"):setVisible(false)
        if data > 100 and data < 200 then
            coins_csb:findChild("Node_chengbei"):setVisible(false)
            coins_csb:findChild("Node_spins"):setVisible(true)
            coins_csb:findChild("spin1"):setVisible(data == 101)
            coins_csb:findChild("spin2"):setVisible(data == 102)
            coins_csb:findChild("spin3"):setVisible(data == 103)
        else
            coins_csb:findChild("Node_chengbei"):setVisible(true)
            coins_csb:findChild("Node_spins"):setVisible(false)
            local m_lb_chengbei = coins_csb:findChild("m_lb_chengbei")
            local m_lb_chengbei_jinse = coins_csb:findChild("m_lb_chengbei_jinse")
            m_lb_chengbei:setVisible(data < 10)
            m_lb_chengbei_jinse:setVisible(data >= 10)
            m_lb_chengbei:setString("x"..data)
            m_lb_chengbei_jinse:setString("x"..data)

            self:updateLabelSize({label=m_lb_chengbei,sx=1,sy=1},71)    
            self:updateLabelSize({label=m_lb_chengbei_jinse,sx=1,sy=1},71)    
        end
    end

    item.m_data = data

end

--[[
    刷新外圈单格区域显示
]]
function OwlsomeWizardWheelView:updateOuterItemShow(item,data,isShowEffect)
    if not data then
        data = -1
    end
    local coins_csb = item.m_csb_coins
    
    if not isShowEffect then
        item:runCsbAction("idle")
        item:findChild("Node_effect"):setVisible(false)
    end
    
    if type(data) == "number" then
        item:findChild("Node_1_4"):setVisible(data > 0 and data <= 4)
        item:findChild("Node_5_15"):setVisible(data >= 5 and data <= 15)
        item:findChild("Node_25_50"):setVisible(data >= 16 and data <= 50)
        item:findChild("Node_grand"):setVisible(false)
        item:findChild("Node_major"):setVisible(false)
        item:findChild("Node_hui"):setVisible(data == -1)
        
        coins_csb:setVisible(data ~= -1)
        if data ~= -1 then
            coins_csb:findChild("Node_jackpot"):setVisible(false)
            local m_lb_coins = coins_csb:findChild("m_lb_coins")
            m_lb_coins:setVisible(true)
            local betCoins = toLongNumber(globalData.slotRunData:getCurTotalBet()) or 0
            m_lb_coins:setString(util_formatCoins(betCoins * data,3))
            self:updateLabelSize({label=m_lb_coins,sx=1,sy=1},91)    
        end
        
    else
        item:findChild("Node_1_4"):setVisible(false)
        item:findChild("Node_5_15"):setVisible(false)
        item:findChild("Node_25_50"):setVisible(false)
        item:findChild("Node_grand"):setVisible(string.lower(data) == "grand")
        item:findChild("Node_major"):setVisible(string.lower(data) == "major")
        item:findChild("Node_hui"):setVisible(false)

        coins_csb:setVisible(true)
        coins_csb:findChild("m_lb_coins"):setVisible(false)
        coins_csb:findChild("Node_jackpot"):setVisible(true)
        coins_csb:findChild("node_grand"):setVisible(string.lower(data) == "grand")
        coins_csb:findChild("node_major"):setVisible(string.lower(data) == "major")
    end

    item.m_data = data
end

--[[
    转盘开始转动
]]
function OwlsomeWizardWheelView:startWheel()
    self.m_wheel_inner:startMove()
    self.m_wheel_outer:startMove()
    self.m_wheelDownCount = 0

    self.m_turnWheelSoundID = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_wheel_turning,true)
    self.m_wheel_outer:setSlowFunc(function()
        self:hideTurnLight()
    end)

    self:showTurnLight()
end

--[[
    显示转动特效
]]
function OwlsomeWizardWheelView:showTurnLight()
    self.m_turnParticle:setVisible(true)
    self.m_turnLight:setVisible(true)
    for index = 1,2 do
        local particle = self.m_turnParticle:findChild("Particle_"..index)
        if particle then
            particle:resetSystem()
        end
    end
    self.m_turnLight:runCsbAction("start")
end

--[[
    隐藏转动特效
]]
function OwlsomeWizardWheelView:hideTurnLight()
    for index = 1,2 do
        local particle = self.m_turnParticle:findChild("Particle_"..index)
        if particle then
            particle:stopSystem()
        end
    end
    self.m_machine:delayCallBack(1,function()
        self.m_turnParticle:setVisible(false)
    end)

    self.m_turnLight:runCsbAction("over",false,function()
        self.m_turnLight:setVisible(false)
    end)
end

function OwlsomeWizardWheelView:wheelDown()
    self.m_wheelDownCount  = self.m_wheelDownCount + 1
    if self.m_wheelDownCount < 2 then
        return
    end

    if self.m_turnWheelSoundID then
        gLobalSoundManager:stopAudio(self.m_turnWheelSoundID)
        self.m_turnWheelSoundID = nil
    end

    self.m_machine:reSpinReelDown()
end

--[[
    设置停止索引
]]
function OwlsomeWizardWheelView:setWheelEndIndex(outerIndex,innerIndex)
    self.m_wheel_outer:setEndIndex(outerIndex)
    self.m_wheel_inner:setEndIndex(innerIndex)
    self.m_outerIndex = outerIndex
    self.m_innerIndex = innerIndex
end

--[[
    重置转盘
]]
function OwlsomeWizardWheelView:resetWheel()
    self.m_wheel_outer:resetViewStatus()
    self.m_wheel_inner:resetViewStatus()
end

--[[
    刷新外圈奖励(有动效)
]]
function OwlsomeWizardWheelView:showOuterWheelReward(startIndex,rewardList)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_wheel_collect_feed_back)
    
    for index = 1,#rewardList do
        local rewardData = rewardList[index]
        local item = self:getWheelItem(1,startIndex + index - 2)
        self:updateOuterItemShow(item,rewardData)
        item:findChild("Node_hui"):setVisible(true)
        item:findChild("Node_effect"):setVisible(true)
        item:findChild("Node_shuzhi"):setVisible(false)
        local parent = item:getParent()
        parent:setLocalZOrder(100 + startIndex + index - 2)
        performWithDelay(item,function()
            item:findChild("Node_shuzhi"):setVisible(true)
        end,30 / 60)
        item:runCsbAction("unlock",false,function()
            parent:setLocalZOrder(startIndex + index - 2)
            item:findChild("Node_effect"):setVisible(false)
            item:findChild("Node_hui"):setVisible(false)

            --扫光特效(策划要求,爆完再扫光)
            local light1 = util_createAnimation("OwlsomeWizard_waiquan_pianduan_shua.csb")
            item:findChild("Node_shua"):addChild(light1)

            light1:runCsbAction("shua",false,function()
                light1:removeFromParent()
            end)
        end)
    end
end

--[[
    随机升级
    依次: 类型(0内圈 1外圈), 位置, 升级后信号或倍数
    "wheelUps": [
        [1, 9, 5], [0, 8, 102]
    ],
]]
function OwlsomeWizardWheelView:randomLevelUpAni(wheelUps,func)
    local list = {}
    --圆形轨迹周长
    local circleLength = 2 * math.pi * RADIUS_WHEEL
    --单格弧形长度
    local singleLength = circleLength / MAX_WHEEL_COUNT

    for index = 1,#wheelUps do
        local data = wheelUps[index]
        local item = util_createAnimation("OwlsomeWizard_mofazhu.csb")
        self:addChild(item,1000)

        -- local endRotation = 0
        -- if data[1] == 1 then
        --     endRotation = self.m_wheel_outer.m_endRotation
        -- end
        local outerIndex = 0
        if data[4] then
            outerIndex = data[4]
        end
        local tarIndex = data[2]
        
        tarIndex  = tarIndex + (MAX_WHEEL_COUNT - outerIndex)
        if tarIndex >= MAX_WHEEL_COUNT then
            tarIndex = tarIndex % MAX_WHEEL_COUNT
        end

        local speedAdd = (16 - tarIndex) * 15

        local speedReduce = 650 + speedAdd
        local reduceLength = 450

        local secondDistance = 2 * math.pi * RADIUS_WHEEL
        if tarIndex <= 4 then
            secondDistance = secondDistance - (4 - tarIndex + 1.5) * singleLength
        else
            secondDistance = secondDistance + (tarIndex - 4 - 1.5) * singleLength
        end

        if tarIndex > 11 then
            reduceLength = 300
        end

        item:setVisible(false)
        list[#list + 1] = {
            item = item,
            wheelItem = self:getWheelItem(data[1],data[2]),
            speedMax = SPEED_BALL,
            speedAdd = speedAdd,
            speedMin = 100,
            reduceSpeed = speedReduce,  --  减速加速度
            reduceLength = reduceLength, --减速距离
            speed = 700,
            wheelType = data[1], --(0内圈 1外圈)
            tarPos = data[2],   --停止位置
            tarReward = data[3], --升级后的奖励
            curDistance = 0,    --当前移动的距离
            circleStep = 0,     --圆形迭代轨迹距离
            firstDistance = math.pi * RADIUS_WHEEL / 2,
            secondDistance = secondDistance,
            direction = DIRECTION_START, --移动方向
            isRunEnd = false,   --是否到达终点
        }
    end
    self.m_ballMoveList = list
    self.m_ballMoveCallFunc = func
    self.m_ballMoveEndCount = 0

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_role_buff_up)
    --猫头鹰施法动作
    self.m_role_node:runAddBuffAni(function()
        self:startSchedule(list)
    end)

    
    
end

--[[
    开始刷帧
]]
function OwlsomeWizardWheelView:startSchedule(ballList)
    for index = 1,#ballList do
        local ballData = ballList[index]
        ballData.item:setVisible(true)
    end
    self.m_sound_ball_id = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_wheel_ball_move,true)
    self.m_scheduleNode:onUpdate(function(dt)
        for index = 1,#ballList do
            local ballData = ballList[index]
            self:ballMoveAction(ballData,dt)
        end
        
    end)
end
--[[
    小球移动动作
]]
function OwlsomeWizardWheelView:ballMoveAction(ballData,dt)
    

    local step = ballData.speed * dt
    ballData.speed = ballData.speed + ballData.speedAdd * dt
    if ballData.speed > ballData.speedMax then
        ballData.speed = ballData.speedMax
    end
    
    local startPos = cc.p(0,0)
    local centerPos = cc.p(0,0)
    
    local direction = ballData.direction

    local speedMin = ballData.speedMin
    local reduceSpeed = ballData.reduceSpeed
    local reduceLength = ballData.reduceLength

    --开始先走一个半圆
    if ballData.direction == DIRECTION_START then
        ballData.curDistance = ballData.curDistance + step
        if ballData.curDistance > ballData.firstDistance then
            ballData.curDistance = ballData.firstDistance
            ballData.direction = DIRECTION_DOWN
            ballData.circleStep = 0
        end
        -- 弧长公式 L=n× π× r/180
        local angleCircle = ballData.curDistance / (math.pi * RADIUS_WHEEL / 2 /180 )
        local addX =  RADIUS_WHEEL / 2 - math.cos(angleCircle * math.pi / 180) * RADIUS_WHEEL / 2
        local addY =  math.sin(angleCircle * math.pi / 180) * RADIUS_WHEEL / 2 

        --刷新Y坐标
        local posX = addX
        ballData.item:setPositionX(posX)
        local posY = self:getCirclePosY(ballData.item,cc.p(RADIUS_WHEEL / 2,0),RADIUS_WHEEL / 2 )
        ballData.item:setPositionY(posY)
    elseif ballData.direction == DIRECTION_DOWN  then --向下走
        ballData.curDistance = ballData.curDistance + step
        ballData.circleStep = ballData.circleStep + step

        local startCirclePos = cc.p(RADIUS_WHEEL,0)
        -- 弧长公式 L=n× π× r/180
        local angleCircle = ballData.circleStep / (math.pi *RADIUS_WHEEL/180 )
        local addX =  RADIUS_WHEEL - math.cos(angleCircle * math.pi / 180) * RADIUS_WHEEL

        local addY =  math.sin(angleCircle * math.pi / 180) * RADIUS_WHEEL 

        --刷新Y坐标
        local posY = startCirclePos.y - addY
        ballData.item:setPositionY(posY)
        local posX = startCirclePos.x - addX
        ballData.item:setPositionX(posX)

        --判定是否减速
        if ballData.curDistance > ballData.firstDistance + ballData.secondDistance - reduceLength then
            ballData.speed = ballData.speed - reduceSpeed * dt
            if ballData.speed < speedMin then
                ballData.speed = speedMin
            end
        end

        if ballData.curDistance > ballData.firstDistance + ballData.secondDistance then
            ballData.direction = DIRECTION_END
        elseif ballData.circleStep >= RADIUS_WHEEL * math.pi * 2 / 4 then--判断是否需要变更方向
            --修改方向
            ballData.direction = DIRECTION_LEFT
            ballData.circleStep = 0
        end
        
    elseif ballData.direction == DIRECTION_LEFT  then --向左走
        ballData.curDistance = ballData.curDistance + step
        ballData.circleStep = ballData.circleStep + step

        local startCirclePos = cc.p(0,-RADIUS_WHEEL)
        -- 弧长公式 L=n× π× r/180
        local angleCircle = ballData.circleStep / (math.pi * RADIUS_WHEEL / 180 )
        local addX =  math.sin(angleCircle * math.pi / 180) * RADIUS_WHEEL 
        local addY =  RADIUS_WHEEL - math.cos(angleCircle * math.pi / 180) * RADIUS_WHEEL

        --刷新X坐标
        local posX = startCirclePos.x - addX
        ballData.item:setPositionX(posX)
        local posY = startCirclePos.y + addY
        ballData.item:setPositionY(posY)

        --判定是否减速
        if ballData.curDistance > ballData.firstDistance + ballData.secondDistance - reduceLength then
            ballData.speed = ballData.speed - reduceSpeed * dt
            if ballData.speed < speedMin then
                ballData.speed = speedMin
            end
        end

        if ballData.curDistance > ballData.firstDistance + ballData.secondDistance then
            ballData.direction = DIRECTION_END
        elseif ballData.circleStep >= RADIUS_WHEEL * math.pi * 2 / 4 then--判断是否需要变更方向
            --修改方向
            ballData.direction = DIRECTION_UP
            ballData.circleStep = 0
        end
    elseif ballData.direction == DIRECTION_UP  then --向上走
        ballData.curDistance = ballData.curDistance + step
        ballData.circleStep = ballData.circleStep + step

        local startCirclePos = cc.p(-RADIUS_WHEEL,0)
        -- 弧长公式 L=n× π× r/180
        local angleCircle = ballData.circleStep / (math.pi * RADIUS_WHEEL / 180 )
        local addX =  RADIUS_WHEEL - math.cos(angleCircle * math.pi / 180) * RADIUS_WHEEL
        local addY =  math.sin(angleCircle * math.pi / 180) * RADIUS_WHEEL 

        --刷新Y坐标
        local posY = startCirclePos.y + addY
        ballData.item:setPositionY(posY)
        local posX = startCirclePos.x + addX
        ballData.item:setPositionX(posX)

        --判定是否减速
        if ballData.curDistance > ballData.firstDistance + ballData.secondDistance - reduceLength then
            ballData.speed = ballData.speed - reduceSpeed * dt
            if ballData.speed < speedMin then
                ballData.speed = speedMin
            end
        end
        
        if ballData.curDistance > ballData.firstDistance + ballData.secondDistance then
            ballData.direction = DIRECTION_END
        elseif ballData.circleStep >= RADIUS_WHEEL * math.pi * 2 / 4 then--判断是否需要变更方向
            --修改方向
            ballData.direction = DIRECTION_RIGHT
            ballData.circleStep = 0
        end
    elseif ballData.direction == DIRECTION_RIGHT  then --向右走
        ballData.curDistance = ballData.curDistance + step
        ballData.circleStep = ballData.circleStep + step

        local startCirclePos = cc.p(0,RADIUS_WHEEL)
        -- 弧长公式 L=n× π× r/180
        local angleCircle = ballData.circleStep / (math.pi * RADIUS_WHEEL / 180 )
        local addX =  math.sin(angleCircle * math.pi / 180) * RADIUS_WHEEL 
        local addY =  RADIUS_WHEEL - math.cos(angleCircle * math.pi / 180) * RADIUS_WHEEL

        --刷新X坐标
        local posX = startCirclePos.x + addX
        ballData.item:setPositionX(posX)
        local posY = startCirclePos.y - addY
        ballData.item:setPositionY(posY)

        --判定是否减速
        if ballData.curDistance > ballData.firstDistance + ballData.secondDistance - reduceLength then
            ballData.speed = ballData.speed - reduceSpeed * dt
            if ballData.speed < speedMin then
                ballData.speed = speedMin
            end
        end

        if ballData.curDistance > ballData.firstDistance + ballData.secondDistance then
            ballData.direction = DIRECTION_END
        elseif ballData.circleStep >= RADIUS_WHEEL * math.pi * 2 / 4 then --判断是否需要变更方向
            --修改方向
            ballData.direction = DIRECTION_DOWN
            ballData.circleStep = 0
        end
    elseif ballData.direction == DIRECTION_END and not ballData.isRunEnd then
        -- ballData.isRunEnd = true
        -- --获取对应格子
        -- local wheelItem = ballData.wheelItem
        -- local endPos = util_convertToNodeSpace(wheelItem.m_csb_coins,self)
        -- local startPos = cc.p(ballData.item:getPosition())
        -- local distance = cc.pGetDistance(startPos, endPos)
        
        -- local time = distance / ballData.speed * 8
        -- if ballData.wheelType == 0 then
        --     time = distance / ballData.speed * 12
        -- end

        -- local seq = {
        --     -- cc.EaseExponentialOut:create(cc.BezierTo:create(time,{startPos,cc.p(startPos.x,endPos.y),endPos})),
        --     cc.EaseExponentialOut:create(cc.MoveTo:create(time,endPos)),
        --     cc.CallFunc:create(function()

        --         self:ballMoveEndFunc()
        --     end)
        -- }

        -- ballData.item:runAction(cc.Sequence:create(seq))

        local wheelItem = ballData.wheelItem
        local startPos = cc.p(ballData.item:getPosition())
        local endPos = util_convertToNodeSpace(wheelItem.m_csb_coins,self)
        
        ballData.speed = ballData.speed - reduceSpeed * dt
        if ballData.speed < speedMin then
            ballData.speed = speedMin
        end
        local pos,isEnd = self:getBallPosInLine(startPos,endPos,dt,ballData.speed)
        ballData.item:setPosition(pos)
        ballData.isRunEnd = isEnd
        if isEnd then
            self:ballMoveEndFunc()
        end

    end
end

--[[
    获取减速阶段小球的位置
]]
function OwlsomeWizardWheelView:getBallPosInLine(startPos,endPos,dt,speed)
    local distance = cc.pGetDistance(startPos,endPos)
    local cos = math.abs(startPos.x - endPos.x) / distance
    local sin = math.abs(startPos.y - endPos.y) / distance

    local length = speed * dt

    if length >= distance then
        return endPos,true
    end

    local diffX = length * cos
    local diffY = length * sin

    if startPos.x > endPos.x then
        diffX = -diffX
    end

    if startPos.y > endPos.y then
        diffY = -diffY
    end

    return cc.p(startPos.x + diffX,startPos.y + diffY),false

end

--[[
    小球停止移动
]]
function OwlsomeWizardWheelView:ballMoveEndFunc()
    self.m_ballMoveEndCount  = self.m_ballMoveEndCount + 1
    if self.m_ballMoveEndCount < #self.m_ballMoveList then
        return
    end

    if self.m_sound_ball_id then
        gLobalSoundManager:stopAudio(self.m_sound_ball_id)
        self.m_sound_ball_id = nil
    end

    for index = 1,#self.m_ballMoveList do
        local ballData = self.m_ballMoveList[index]

        --奖励升级动画
        local wheelItem = ballData.wheelItem
        local wheelType = ballData.wheelType --(0内圈 1外圈)
        local tarReward = ballData.tarReward
        local ballItem = ballData.item
        performWithDelay(ballItem,function()
            

            -- wheelItem:findChild("Node_effect"):setVisible(true)
            -- wheelItem:runCsbAction("actionframe",false,function()
            --     wheelItem:findChild("Node_effect"):setVisible(false)
            -- end)
            

            local lightAni = util_createAnimation("OwlsomeWizard_wheel_shengji.csb")
            self:addChild(lightAni,1500)
            lightAni:setPosition(cc.p(ballItem:getPosition()))
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_wheel_up)
            lightAni:runCsbAction("actionframe",false,function()
                lightAni:removeFromParent()

                --扫光特效(策划要求,爆完再扫光)
                local light1
                if wheelType == 0 then
                    light1 = util_createAnimation("OwlsomeWizard_neiquan_pianduan_shua.csb")
                else
                    light1 = util_createAnimation("OwlsomeWizard_waiquan_pianduan_shua.csb")
                end
                wheelItem:findChild("Node_shua"):addChild(light1)

                light1:runCsbAction("shua",false,function()
                    light1:removeFromParent()
                end)
            end)
            ballItem:removeFromParent()
            self.m_machine:delayCallBack(5 / 60,function()
                if wheelType == 0 then
                    self:updateInnerItemShow(wheelItem,tarReward,true)
                else
                    self:updateOuterItemShow(wheelItem,tarReward,true)
                end
            end)
        end,0.1 * index)
    end

    --停止计时器
    self.m_scheduleNode:unscheduleUpdate()

    self.m_machine:delayCallBack(45 / 60 + 0.1 * #self.m_ballMoveList,function()
        if type(self.m_ballMoveCallFunc) == "function" then
            self.m_ballMoveCallFunc()
        end
    
        self.m_ballMoveList = nil
        self.m_ballMoveCallFunc = nil
        self.m_ballMoveEndCount = 0
    end) 
end

--[[
    获取Y坐标
]]
function OwlsomeWizardWheelView:getCirclePosY(target,centerPos,radius)
    local pos = cc.p(target:getPosition())
    if pos.y < centerPos.y then
        return -math.sqrt(math.abs(radius * radius - (pos.x - centerPos.x) * (pos.x - centerPos.x))) + centerPos.y
    else
        return math.sqrt(math.abs(radius * radius - (pos.x - centerPos.x) * (pos.x - centerPos.x))) + centerPos.y
    end
end

--[[
    获取X坐标
]]
function OwlsomeWizardWheelView:getCirclePosX(target,centerPos,radius)
    local pos = cc.p(target:getPosition())
    if pos.x < centerPos.x then
        return -math.sqrt(math.abs(radius * radius - (pos.y - centerPos.y) * (pos.y - centerPos.y)) ) + centerPos.x
    else
        return math.sqrt(math.abs(radius * radius - (pos.y - centerPos.y) * (pos.y - centerPos.y))) + centerPos.x
    end
end

--[[
    轮盘集满动效
]]
function OwlsomeWizardWheelView:collectFullAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_wheel_collect_full)
    local lightAni = util_createAnimation("OwlsomeWizard_wheel_jiman.csb")
    self:findChild("ef_jiman"):addChild(lightAni)
    lightAni:runCsbAction("actionframe",false,function()
        lightAni:removeFromParent()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示指针
]]
function OwlsomeWizardWheelView:showPointerAni(func)
    self.m_pointer:runCsbAction("show",false,func)
end

--[[
    隐藏指针
]]
function OwlsomeWizardWheelView:hidePointerAni(func)
    self.m_pointer:runCsbAction("over",false,function()
        self:runPointerIdle()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    base下指针idle
]]
function OwlsomeWizardWheelView:runPointerIdle()
    self.m_pointer:runCsbAction("idle")
end

--[[
    显示转动的结果
]]
function OwlsomeWizardWheelView:showWheelResult(outerIndex,innerIndex,innerReward,func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_wheel_hit)
    for index = 1,MAX_WHEEL_COUNT do
        local outerItem = self.m_outerItems[index]
        local innerItem = self.m_innerItems[index]
        --压暗其他未中奖扇面
        if outerIndex + 1 ~= index then
            self:runDardAni(outerItem)
        else
            local csbNode = outerItem.m_csb_coins
            local pos = util_convertToNodeSpace(csbNode,self:findChild("root"))
            util_changeNodeParent(self:findChild("root"),csbNode)
            csbNode:setPosition(pos)
        end

        if innerIndex + 1 ~= index then
            self:runDardAni(innerItem)
        else
            
            local csbNode = innerItem.m_csb_coins
            local pos = util_convertToNodeSpace(csbNode,self:findChild("root"))
            util_changeNodeParent(self:findChild("root"),csbNode)
            csbNode:setPosition(pos)

            if innerReward == 200 then
                csbNode:runCsbAction("actionframe",true)
            elseif innerReward > 100 and innerReward < 104 then
                csbNode:runCsbAction("actionframe1")
            end
        end
    end
    self:runCsbAction("dark")

    --指针播放选中动效
    self.m_pointer:runCsbAction("actionframe",true)

    self.m_machine:delayCallBack(2,function()
        
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    重置轮盘选中状态
]]
function OwlsomeWizardWheelView:resetWheelSelectStatus()
    self.m_pointer:runCsbAction("idle2")
    self:runCsbAction("dark_over")
    for index = 1,MAX_WHEEL_COUNT do
        local outerItem = self.m_outerItems[index]
        local innerItem = self.m_innerItems[index]

        local outerCsbNode = outerItem.m_csb_coins
        if outerCsbNode:getParent() == self:findChild("root") then
            util_changeNodeParent(outerItem:findChild("Node_shuzhi"),outerCsbNode)
            outerCsbNode:setPosition(cc.p(0,0))
        end

        local innerCsbNode = innerItem.m_csb_coins
        if innerCsbNode:getParent() == self:findChild("root") then
            util_changeNodeParent(innerItem:findChild("Node_shuzhi"),innerCsbNode)
            innerCsbNode:setPosition(cc.p(0,0))
            innerCsbNode:runCsbAction("idle")
        end
        

        outerItem:runCsbAction("over",false,function()
            outerItem:findChild("Node_effect"):setVisible(false)

            if outerItem:findChild("ef_unlock") then
                outerItem:findChild("ef_unlock"):setVisible(true)
            end
        
            if outerItem:findChild("ef_tishi") then
                outerItem:findChild("ef_tishi"):setVisible(true)
            end
        end)
        innerItem:runCsbAction("over",false,function()
            innerItem:findChild("Node_effect"):setVisible(false)

            if innerItem:findChild("ef_unlock") then
                innerItem:findChild("ef_unlock"):setVisible(true)
            end
        
            if innerItem:findChild("ef_tishi") then
                innerItem:findChild("ef_tishi"):setVisible(true)
            end
        end)
    end
end

--[[
    压黑动画
]]
function OwlsomeWizardWheelView:runDardAni(item)
    item:findChild("Node_effect"):setVisible(true)
    item:runCsbAction("dark")

    if item:findChild("ef_unlock") then
        item:findChild("ef_unlock"):setVisible(false)
    end

    if item:findChild("ef_tishi") then
        item:findChild("ef_tishi"):setVisible(false)
    end
end

--[[
    显示外圈收集提示动效
]]
function OwlsomeWizardWheelView:showOuterCollectNoticeAni(startIndex,count)
    for index = 1,count do
        local item = self:getWheelItem(1,startIndex + index - 2)
        item:findChild("Node_effect"):setVisible(true)
        item:runCsbAction("tishi",true)
    end
end

--[[
    刷光动画
]]
function OwlsomeWizardWheelView:showRefreshLight()
    -- for index = 1,#self.m_innerItems do
    --     local item = self.m_innerItems[index]
    --     local light = util_createAnimation("OwlsomeWizard_neiquan_pianduan_shua.csb")
    --     item:findChild("Node_shua"):addChild(light)

    --     light:runCsbAction("shua",false,function()
    --         light:removeFromParent()
    --     end)
    -- end

    for index = 1,#self.m_outerItems do
        local item = self.m_outerItems[index]

        if (type(item.m_data) == "number" and item.m_data ~= -1) or type(item.m_data) ~= "number" then
            item:findChild("Node_effect"):setVisible(true)
            item:stopAllActions()
            item:runCsbAction("bet")

            performWithDelay(item,function()
                item:findChild("Node_effect"):setVisible(false)
            end,45 / 60)
        end
    end

    performWithDelay(self.m_switchLight,function()
        for index = 1,#self.m_outerItems do
            local item = self.m_outerItems[index]
    
            if (type(item.m_data) == "number" and item.m_data ~= -1) or type(item.m_data) ~= "number" then
                local light = util_createAnimation("OwlsomeWizard_waiquan_pianduan_shua.csb")
                item:findChild("Node_shua"):addChild(light)
                light:runCsbAction("shua",false,function()
                    light:removeFromParent()
                end)
            end
        end
    end,45 / 60)
end
return OwlsomeWizardWheelView