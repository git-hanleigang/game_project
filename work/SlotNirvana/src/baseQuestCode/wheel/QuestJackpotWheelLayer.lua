-- quest 轮盘

local QuestJackpotWheelLayer = class("QuestJackpotWheelLayer", BaseLayer)
local ActivityBaseWheel = require("Levels.ActivityBaseWheel")
local FJackpot_WheelItemNode_CodePath = "Activity_FlamingoJackpot/Code/Wheel/FJackpot_WheelItemNode"

function QuestJackpotWheelLayer:ctor()
    QuestJackpotWheelLayer.super.ctor(self)
    self:setLandscapeCsbName(QUEST_RES_PATH.QuestJackpotWheelLayer)
    self:setExtendData("QuestJackpotWheelLayer")

    self.m_outSideHuiTan = 3
    self.m_outSideHuiTanTime = 1

    self.m_inSideHuiTan = 3
    self.m_inSideHuiTanTime = 1

    self.m_useDebug = false
    self:setPauseSlotsEnabled(true)
end

--初始化数据
function QuestJackpotWheelLayer:initDatas(data)
    self.m_overCall = data._overCall
    self.m_isLookPreview  = data.isLookPreview
    self.m_activityData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    local hasWheel ,wheelData = self.m_activityData:getCurrentPhaseJackpotWheelData()
    self.m_wheelData = clone(wheelData) -- 这里克隆一份，防止转动的过程中活动结束，数据失效
    -- self:setBgm("Activity_FlamingoJackpot/Activity/sound/FlamingoJackpot.mp3") 
end

function QuestJackpotWheelLayer:initCsbNodes()
    self.lb_coins = self:findChild("lb_coins")
    self.node_middle = self:findChild("node_middle")

    self.node_wheel2_lock = self:findChild("node_wheel2_lock")
    self.node_grand2 = self:findChild("node_grand2")
    
    self.m_wheelItemNodeMap = {} -- 轮盘扇形节点  1 外圈 2 中心圈 3 内圈    
    self.m_node_wheelOuter = self:findChild("sp_wheel1") -- 轮盘 最外圈
    local mapOuter = {}
    for i=1,12 do
        local oneNode = self:findChild("node_wheel1_"..i)
        table.insert(mapOuter,oneNode)
    end
    table.insert(self.m_wheelItemNodeMap,mapOuter)


    self.m_node_wheelMiddle = self:findChild("sp_wheel2") -- 轮盘 中间圈
    local mapMiddle = {}
    for i=1,8 do
        local oneNode = self:findChild("node_wheel2_"..i)
        table.insert(mapMiddle,oneNode)
    end
    table.insert(self.m_wheelItemNodeMap,mapMiddle)
    

    self.m_node_wheelInner = self:findChild("sp_wheel3") -- 轮盘 内圈
    local mapInner = {}
    for i=1,4 do
        local oneNode = self:findChild("node_wheel3_"..i)
        table.insert(mapInner,oneNode)
    end
    table.insert(self.m_wheelItemNodeMap,mapInner)



    self.m_sp_grand = self:findChild("sp_grand")
    
    self.node_top = self:findChild("node_top") -- 顶部三个金币奖励总结点 
    
    self.btn_close = self:findChild("btn_close") -- 关闭按钮

    self.m_node_npc = self:findChild("node_spine") --

    self.m_rewardEffetNode = self:findChild("node_ef")

    self.m_node_jackpot = self:findChild("node_jackpot")

    self.m_panelTouch = self:findChild("Panel_touch")
    self:addClick(self.m_panelTouch)
    self.m_panelTouch:setSwallowTouches(true)

    self.m_sp_arrow = self:findChild("sp_arrow")
    
    self.m_actionNode = self:findChild("node_hand")

    self.m_btnClose = self:findChild("btn_close")

    self.m_node_bubble = self:findChild("node_bubble")
    
    -- local touch = G_GetMgr(ACTIVITY_REF.FlamingoJackpot):makeTouch(cc.size(display.width , display.height ), "wheel_touch")
    -- self.node_middle:addChild(touch, 1)
    -- self:addClick(touch)
end

function QuestJackpotWheelLayer:initView()
    --self.btn_close:setVisible(not self.bl_complete)
    self.m_panelTouch:setVisible(not self.m_isLookPreview)
    self:initTopNode()
    if not self.m_useDebug then
        self:initWheel()
    else
        self._DebugLayer = require("Activity_FlamingoJackpot.Code.Wheel.FJackpot_WheeDebug").new(self)
        self:addChild(self._DebugLayer)
        self._DebugLayer:InitDebugPro()
    end
    self.m_btnClose:setVisible(not not self.m_isLookPreview)
    --self:initSpine()

    local difficulty =  G_GetMgr(ACTIVITY_REF.Quest):getCurDifficulty()
    self.node_wheel2_lock:setVisible(true)
    self.node_grand2:setVisible(true)
    if difficulty == 2 then 
        self.node_wheel2_lock:setVisible(false)
        self.node_grand2:setVisible(true)
    elseif difficulty == 3 then
        self.node_wheel2_lock:setVisible(false)
        self.node_grand2:setVisible(false)
    end
end

-- 顶部金币滚动节点
function QuestJackpotWheelLayer:initTopNode()
    local jackpotCoinsNode = util_createView(QUEST_CODE_PATH.QuestJackpotWheelTitleNode,{inWheel = true})
    self.m_node_jackpot:addChild(jackpotCoinsNode)
    self.m_jackpotNode = jackpotCoinsNode
end

function QuestJackpotWheelLayer:initBubble()
    local difficulty =  G_GetMgr(ACTIVITY_REF.Quest):getCurDifficulty()
    if difficulty < 3 and not self.m_bubbleAct then
        self.m_bubbleAct = util_createAnimation(QUEST_RES_PATH.QuestJackpotWheelBubble)
        self.m_node_bubble:addChild(self.m_bubbleAct)
        self.m_bubbleAct:playAction("show", false,function()
            self.m_bubbleAct:playAction("idle", true)
            util_performWithDelay(
                self.m_node_bubble,
                function()
                    self.m_bubbleAct:playAction("over", false,function()
                    end)
                end,
                1
            )
        end)
    end
end  

-- 初始化轮盘Action
function QuestJackpotWheelLayer:initWheel()
    self.m_allWheel = {}
    self:createOuterRingWheel() 
    self:createMiddleRingWheel() 
    self:createInnerRingWheel()

    self.m_rewardEffetNode:setVisible(false)
end

-- function QuestJackpotWheelLayer:initSpine()
--     self.m_spine = util_spineCreate("QuestBaseRes/spine/y_NPC", true, true)
--     if self.m_spine then
--         self.m_node_npc:addChild(self.m_spine)
--         util_spinePlay(self.m_spine, "idle", true)
--     end
-- end

-- 外圈 转盘
function QuestJackpotWheelLayer:createOuterRingWheel() 
    local rewardNum = self:creteWheelItems(1)
    local params = {
        doneFunc = function()
            -- 滚动结束调用
            self:afterRollingOver(1)
        end,
        rotateNode = self.m_node_wheelOuter,      --需要转动的节点
        sectorCount = rewardNum,     --总的扇面数量
        direction = -1,       --转动方向
        parentView = self,  --父界面

        startSpeed = 0,     --开始速度
        minSpeed = 30,      --最小速度(每秒转动的角度)
        maxSpeed = 500,     --最大速度(每秒转动的角度)
        accSpeed = 200,      --加速阶段的加速度(每秒增加的角速度)
        reduceSpeed = 80,   --减速结算的加速度(每秒减少的角速度)
        turnNum = 3,         --开始减速前转动的圈数
        minDistance = 50,   --以最小速度行进的距离
        backDistance = 3,    --回弹距离
        backTime = 1 ,     --回弹时间
        pointerSp = self.m_sp_arrow ,
        pointerDo = true,
        pointerMusic = "QuestSounds/Quest_wheel_Arrow.mp3"
    }
    if self.m_useDebug then
        params.backDistance = self.m_outSideHuiTan
        params.backTime = self.m_outSideHuiTanTime
    end
    self.m_wheel_out = ActivityBaseWheel:create(params)
    self:addChild(self.m_wheel_out)
    self.m_allWheel[1] = self.m_wheel_out
end

-- 中间圈 转盘
function QuestJackpotWheelLayer:createMiddleRingWheel() 
    local rewardNum = self:creteWheelItems(2)
    local params = {
        doneFunc = function()
            -- 滚动结束调用
            self:afterRollingOver(2)
        end,
        rotateNode = self.m_node_wheelMiddle,      --需要转动的节点
        sectorCount = rewardNum,     --总的扇面数量
        direction = 1,       --转动方向
        parentView = self,  --父界面

        startSpeed = 0,     --开始速度
        minSpeed = 30,      --最小速度(每秒转动的角度)
        maxSpeed = 500,     --最大速度(每秒转动的角度)
        accSpeed = 200,      --加速阶段的加速度(每秒增加的角速度)
        reduceSpeed = 80,   --减速结算的加速度(每秒减少的角速度)
        turnNum = 3,         --开始减速前转动的圈数
        minDistance = 50,   --以最小速度行进的距离
        backDistance = 3,    --回弹距离
        backTime = 1      --回弹时间
    }
    if self.m_useDebug then
        params.backDistance = self.m_inSideHuiTan
        params.backTime = self.m_inSideHuiTanTime
    end
    self.m_wheel_middle = ActivityBaseWheel:create(params)
    self:addChild(self.m_wheel_middle)
    self.m_allWheel[2] = self.m_wheel_middle
end

-- 内圈 转盘
function QuestJackpotWheelLayer:createInnerRingWheel()
    local rewardNum = self:creteWheelItems(3)
    local params = {
        doneFunc = function()
            -- 滚动结束调用
            self:afterRollingOver(3)
        end,
        rotateNode = self.m_node_wheelInner,      --需要转动的节点
        sectorCount = rewardNum,     --总的扇面数量
        direction = -1,       --转动方向
        parentView = self,  --父界面

        startSpeed = 0,     --开始速度
        minSpeed = 30,      --最小速度(每秒转动的角度)
        maxSpeed = 500,     --最大速度(每秒转动的角度)
        accSpeed = 200,      --加速阶段的加速度(每秒增加的角速度)
        reduceSpeed = 80,   --减速结算的加速度(每秒减少的角速度)
        turnNum = 3,         --开始减速前转动的圈数
        minDistance = 50,   --以最小速度行进的距离
        backDistance = 3,    --回弹距离
        backTime = 1      --回弹时间
    }
    if self.m_useDebug then
        params.backDistance = self.m_inSideHuiTan
        params.backTime = self.m_inSideHuiTanTime
    end
    self.m_wheel_inner = ActivityBaseWheel:create(params)
    self:addChild(self.m_wheel_inner)
    self.m_allWheel[3] = self.m_wheel_inner
end

function QuestJackpotWheelLayer:createCenterJackpoNode()
    -- if not self.m_wheelItemMap[4] then
    --     self.m_wheelItemMap[4] = {}
    -- end
    -- local oneData = {} 
    -- local itemNode = util_createView(FJackpot_WheelItemNode_CodePath,{item_data = oneData,type = 4})  --isHaveSuper
    -- self.m_node_wheelInner:addChild(itemNode)
    -- table.insert( self.m_wheelItemMap[4],itemNode)
end

--- tierId 1 外圈 2 中间圈 3 内圈
function QuestJackpotWheelLayer:creteWheelItems(tierId)
    if not self.m_wheelItemMap then
        self.m_wheelItemMap = {}
    end 
    if not self.m_wheelItemMap[tierId] then
        self.m_wheelItemMap[tierId] = {}
    end 
    local ItemNodeMap = self.m_wheelItemNodeMap[tierId] or {}
    local tierVec = self.m_wheelData:getWheelTierVecByTierId(tierId)
    for index, node in ipairs(ItemNodeMap) do
        local oneData = tierVec[index]
        local itemNode = util_createView(QUEST_CODE_PATH.QuestJackpotWheelItemNode,{item_data = oneData,type = tierId}) 
        node:addChild(itemNode)
        table.insert( self.m_wheelItemMap[tierId],itemNode)
    end
    return #self.m_wheelItemMap[tierId]
end


function QuestJackpotWheelLayer:playShowAction()
    local userDefAction = function(callFunc)
        --gLobalSoundManager:playSound("Activity_FlamingoJackpot/Activity/sound/lock.mp3")
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    QuestJackpotWheelLayer.super.playShowAction(self, userDefAction)
end

function QuestJackpotWheelLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
    self:initBubble()
    self.bl_touchEnable = true
    if not self.m_isLookPreview then
        self:showHand()
        local hitResult =  self.m_wheelData:getHitResultData()
        performWithDelay(
            self,
            function()
                if self.m_doWheelAct then
                    return
                end
                if self.m_useDebug then
                    return
                end
                self.m_overPosIds = hitResult.hitPosIds
                self.m_overCoins = hitResult.hitCoin
                self.m_hitTier =  hitResult.tier_id
                self.m_hitJackpotType =  hitResult.jackpotType
                self:doWheelAct()
            end,
            3
        ) 
    end
end

function QuestJackpotWheelLayer:afterRollingOver(index)
    local hitIndex = self.m_overPosIds[index]
    -- if self:isHitPointer(index,hitIndex) then
    --     gLobalSoundManager:playSound(FJackpot__RES_PATH.FJackpot__Sound_WheelCheckOut)
    -- end


    local useWheelCount = #self.m_overPosIds >3 and 3 or #self.m_overPosIds

    if self.m_useWheel[index] then
        self.m_useWheel[index] = false
        if self.m_hitTier >= index then

            local act_path = QUEST_RES_PATH.QuestJackpotWheelEffectPath .. index .. ".csb"
            local gianAct = util_createAnimation(act_path)
            if gianAct and self.m_rewardEffetNode then
                self.m_rewardEffetNode:setVisible(true)
                self.m_rewardEffetNode:addChild(gianAct,200,200)
                gianAct:runCsbAction("idle", true, nil, 60)
            end
        end
    end

    local doReward = true
    for i,v in ipairs(self.m_useWheel) do
        if v then
            doReward = false
        end
    end

    if doReward then
        if self.m_hitTier == 4 then
            -- local centerNode = self.m_wheelItemMap[4][1]
            -- centerNode:doGainReward(function()
            --     self:showReward()
            -- end)
            self:runCsbAction("win", false,function()
                self:showReward()
            end)
        else
            self:showReward()
        end
    end
end

function  QuestJackpotWheelLayer:showReward()
    local hitJackpotType = self.m_hitJackpotType
    self.m_jackpotNode:playHitAct(hitJackpotType)
    gLobalSoundManager:playSound("Activity_FlamingoJackpot/Activity/sound/Select.mp3")
    performWithDelay(
        self,
        function()
            G_GetMgr(ACTIVITY_REF.Quest):showRewardLayer(hitJackpotType,self.m_overCoins, 0, nil,function ()
                self:closeUI(function ()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_WHEEL_ROLL_OVER)
                    if self.m_overCall then
                     self.m_overCall()
                    end
                end)
             end)
        end,
        1
    )
end

function QuestJackpotWheelLayer:onEnter()
   QuestJackpotWheelLayer.super.onEnter(self)
   gLobalNoticManager:addObserver(
       self,
       function(self,params)
        self:afterPlayWheel(params)
       end,
       ViewEventType.NOTIFY_REQUEST_AFTER_PLAYWHEEL
   )
end

function QuestJackpotWheelLayer:afterPlayWheel(params)
    if params.type == "success" then
        self.m_overPosIds = params.data.posIds
        self.m_overCoins = tonumber(params.data.coins) 
        self.m_hitTier = params.data.hitTier
        self.m_jackpotType = 0
        
        if params.data.jackpotType then
            if params.data.jackpotType == "Grand" then
                self.m_jackpotType = 3
            elseif params.data.jackpotType == "Major" then
                self.m_jackpotType = 2
            else
                self.m_jackpotType = 1
            end
        end
        self:doWheelAct()
    end
end

function QuestJackpotWheelLayer:doWheelAct()
    if self.m_doWheelAct then
        return
    end
    self:runCsbAction("idle2", true)
    self:stopHand()
    self.m_doWheelAct = true
    local daleyTime = 0
    self.m_useWheel = {}
    local useInsideRandomIndex = false
    for i=1,3 do
        local posId = self.m_overPosIds[i]
        if not posId  then
            posId = self:getInsideRandomIndex(i)
        end
        self.m_useWheel[#self.m_useWheel + 1] = true
        performWithDelay(
            self,
            function()
                self.m_allWheel[i]:startMove(nil)
                self.m_allWheel[i]:setEndIndex(posId - 1)
            end,
            daleyTime
        )
        daleyTime = daleyTime + 1
    end
end

function QuestJackpotWheelLayer:getInsideRandomIndex(tier)
    local randomIndex_Map = {}
    local tierVec = self.m_wheelData:getWheelTierVecByTierId(tier)
    for index, node in ipairs(tierVec) do
        local oneData = tierVec[index]
        if oneData:isJackpotType() then
            table.insert(randomIndex_Map, index)
        end
    end
    local randomId = math.random(1, #randomIndex_Map)
    return randomIndex_Map[randomId]
end

function QuestJackpotWheelLayer:closeUI(callFunc)
    QuestJackpotWheelLayer.super.closeUI(self, callFunc)
end

function QuestJackpotWheelLayer:isHitPointer(tierId,hitIndex)
    local tierVec = self.m_wheelData:getWheelTierVecByTierId(tierId)
    local hitData = tierVec[hitIndex]
    if hitData and hitData:isPointer() then
        return true
    end
    return false
end

function QuestJackpotWheelLayer:clickFunc(sender)
    local name = sender:getName()
    if self.m_doWheelAct then
        return
    end
    if self.m_useDebug then
        return
    end
    if name == "Panel_touch" then
        if not self.m_isLookPreview then
            local hitResult =  self.m_wheelData:getHitResultData()
            self.m_overPosIds = hitResult.hitPosIds
            self.m_overCoins = hitResult.hitCoin
            self.m_hitTier =  hitResult.tier_id
            self.m_hitJackpotType =  hitResult.jackpotType
            self:doWheelAct()
        end
    elseif name == "btn_close" then
        self:closeUI()
    end
end

function QuestJackpotWheelLayer:showHand()
    local hand = util_spineCreate("QuestBaseRes/spine/Flamingo_shouzhi", true, true)
    util_spinePlay(hand, "start", true)
    self.m_actionNode:addChild(hand)
end

function QuestJackpotWheelLayer:stopHand()
    if self.m_actionNode then
        self.m_actionNode:removeAllChildren()
    end
end

function QuestJackpotWheelLayer:doDebugWheel()
    self:initWheel()
    local hitResult =  self.m_wheelData:getHitResultData()
    if self.m_doWheelAct then
        return
    end
    self.m_overPosIds = hitResult.hitPosIds
    self.m_overCoins = hitResult.hitCoin
    self.m_hitTier =  hitResult.tier_id
    self.m_hitJackpotType =  hitResult.jackpotType
    self:doWheelAct()
end
return QuestJackpotWheelLayer
