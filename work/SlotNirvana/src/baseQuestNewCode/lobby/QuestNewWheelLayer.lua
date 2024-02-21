-- quest 轮盘

local QuestNewWheelLayer = class("QuestNewWheelLayer", BaseLayer)
local QuestNewWheelNode = require("baseQuestNewCode/lobby/QuestNewWheelNode")
local QuestNewWheelItemNode = require("baseQuestNewCode/lobby/QuestNewWheelItemNode")

function QuestNewWheelLayer:ctor()
    QuestNewWheelLayer.super.ctor(self)
    self:setLandscapeCsbName(QUESTNEW_RES_PATH.QuestNewWheelLayer)
    self:setExtendData("QuestNewWheelLayer")
end

--初始化数据
function QuestNewWheelLayer:initDatas(chapterId)
    self.m_chapterId = chapterId
    self.m_activityData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    self.m_wheelData = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterWheelDataByChapterId(self.m_chapterId)
end

function QuestNewWheelLayer:initCsbNodes()
    self.lb_coins = self:findChild("lb_coins")
    self.node_middle = self:findChild("node_middle")
    
    self.m_wheelItemNodeMap = {} -- 轮盘扇形节点  1 外圈 2 中心圈 3 内圈    
    self.m_sp_wheel_4 = self:findChild("sp_wheel_4") -- 轮盘 最外圈
    local mapOuter = {}
    for i=1,16 do
        local oneNode = self:findChild("node_wheel_4_"..i)
        table.insert(mapOuter,oneNode)
    end
    table.insert(self.m_wheelItemNodeMap,mapOuter)

    self.m_sp_wheel_3 = self:findChild("sp_wheel_3") -- 轮盘 中间圈
    local mapMiddle = {}
    for i=1,12 do
        local oneNode = self:findChild("node_wheel_3_"..i)
        table.insert(mapMiddle,oneNode)
    end
    table.insert(self.m_wheelItemNodeMap,mapMiddle)

    self.m_sp_wheel_2 = self:findChild("sp_wheel_2") -- 轮盘 内圈
    local mapInner = {}
    for i=1,12 do
        local oneNode = self:findChild("node_wheel_2_"..i)
        table.insert(mapInner,oneNode)
    end
    table.insert(self.m_wheelItemNodeMap,mapInner)

    self.m_sp_wheel_1 = self:findChild("sp_wheel_1") -- 轮盘 中心圈

    self.node_top = self:findChild("node_top") -- 顶部三个金币奖励总结点 
    local node_minorbanzi  = self:findChild("node_minorbanzi") 
    local node_grandbanzi = self:findChild("node_grandbanzi") 
    local node_majorbanzi = self:findChild("node_majorbanzi") 
    self.m_topCoinsNodeArray = {node_minorbanzi,node_majorbanzi,node_grandbanzi} 
    
    local nodezjk01 = self:findChild("nodezjk01")  --中奖
    local nodezjk02 = self:findChild("nodezjk02") 
    local nodezjk03 = self:findChild("nodezjk03") 
    self.m_rewardEffetNodeArray = {nodezjk01,nodezjk02,nodezjk03} 
    
    self.btn_close = self:findChild("btn_close") -- 关闭按钮

    self.m_node_npc = self:findChild("node_npc") -- 关闭按钮

    self.m_sp_wheel_2_an = self:findChild("sp_wheel_2_an")
    self.m_sp_wheel_an = self:findChild("sp_wheel_an")
    self.m_sp_wheel_lock = self:findChild("sp_wheel_lock")
    

    -- local touch = G_GetMgr(ACTIVITY_REF.QuestNew):makeTouch(cc.size(display.width , display.height ), "wheel_touch")
    -- self.node_middle:addChild(touch, 1)
    -- self:addClick(touch)
end

function QuestNewWheelLayer:initView()
    --self.btn_close:setVisible(not self.bl_complete)
    self:initTopGoldNode()
    self:initWheel()
    self:initSpine()
end

-- 顶部金币滚动节点
function QuestNewWheelLayer:initTopGoldNode()
    self.m_topCoinsShowNodeArray = {}
    for i=1,3 do
        local coinsShowNode = util_createView(QUESTNEW_CODE_PATH.QuestNewTopCoinsShowNode,{type = i})
        self.m_topCoinsShowNodeArray[i] = coinsShowNode
        local node = self.m_topCoinsNodeArray[i]
        if node then
            node:addChild(coinsShowNode)
        end
    end
    self:initGoldTimer()
end

function QuestNewWheelLayer:initGoldTimer()
    local updateFun = function(isInit)
        if self.m_activityData:isCanShowRunGold() then
            G_GetMgr(ACTIVITY_REF.QuestNew):updateQuestGoldIncrease(false)
            for index, coinsShowNode in ipairs(self.m_topCoinsShowNodeArray) do
                coinsShowNode:updateCoins()
            end
        end
    end
    updateFun(true)
    schedule(
        self,
        function()
            updateFun()
        end,
        0.1
    )
end

-- 初始化轮盘Action
function QuestNewWheelLayer:initWheel()
    self.m_allWheel = {}
    self:createOuterRingWheel() 
    self:createMiddleRingWheel() 
    self:createInnerRingWheel()

    local wheelType = self.m_wheelData:getType()
    if wheelType == 2  or self.m_wheelData:isWillchangeToLevelThree(false) then
        
    elseif wheelType == 3 or self.m_wheelData:isWillchangeToLevelFour(false) then
        self.m_sp_wheel_2_an:setVisible(false)
    elseif wheelType == 4 then
        self.m_sp_wheel_2_an:setVisible(false)
        self.m_sp_wheel_an:setVisible(false)
        self.m_sp_wheel_lock:setVisible(false)
    end

    for i,node in ipairs(self.m_rewardEffetNodeArray) do
        node:setVisible(false)
    end
end

--初始Spine
function QuestNewWheelLayer:initSpine()
    self.m_spine = util_spineCreate(QUESTNEW_RES_PATH.QuestNewNPCSpinePath, true, true, 1)
    if self.m_spine then
        self.m_node_npc:addChild(self.m_spine)
        self.m_spine:setScale(2.5)
        util_spinePlay(self.m_spine, "idle", true)
    end
end

-- 外圈 转盘
function QuestNewWheelLayer:createOuterRingWheel() 
    local rewardNum = self:creteWheelItems(1,4)
    self.m_wheel_out =
        QuestNewWheelNode:create(
        self.m_sp_wheel_4,
        rewardNum,
        function()
            -- 滚动结束调用
            self:afterRollingOver(1)
        end,
        function(distance, targetStep, isBack)
            -- 滚动实时调用
            
        end,
        nil,
        nil
    )
    self:addChild(self.m_wheel_out)
    self.m_allWheel[1] = self.m_wheel_out
end

-- 中间圈 转盘
function QuestNewWheelLayer:createMiddleRingWheel() 
    local rewardNum = self:creteWheelItems(2,3)
    self.m_wheel_middle =
        QuestNewWheelNode:create(
        self.m_sp_wheel_3,
        rewardNum,
        function()
            -- 滚动结束调用
            self:afterRollingOver(2)
        end,
        function(distance, targetStep, isBack)
            -- 滚动实时调用
        end,
        nil,
        nil
    )
    self:addChild(self.m_wheel_middle)
    self.m_allWheel[2] = self.m_wheel_middle
end

-- 内圈 转盘
function QuestNewWheelLayer:createInnerRingWheel()
    local rewardNum = self:creteWheelItems(3,2)
    self.m_wheel_in =
        QuestNewWheelNode:create(
        self.m_sp_wheel_2,
        rewardNum,
        function()
            -- 滚动结束调用
            self:afterRollingOver(3)
        end,
        function(distance, targetStep, isBack)
            -- 滚动实时调用
            
        end,
        nil,
        nil
    )
    self:addChild(self.m_wheel_in)
    self.m_allWheel[3] = self.m_wheel_in
end

--- tierId 1 外圈 2 中间圈 3 内圈
function QuestNewWheelLayer:creteWheelItems(tierId,nodeId)
    if not self.m_wheelItemMap then
        self.m_wheelItemMap = {}
    end 
    if not self.m_wheelItemMap[tierId] then
        self.m_wheelItemMap[tierId] = {}
    end 
    local unlock = self.m_wheelData:getType() >= tierId
    local ItemNodeMap = self.m_wheelItemNodeMap[tierId] or {}
    local wheelData = self.m_wheelData:getWheelDataByTierId(tierId)
    for index, node in ipairs(ItemNodeMap) do
        local oneData = wheelData.p_grids[index]
        local itemNode = util_createView(QUESTNEW_CODE_PATH.QuestNewWheelItemNode,{item_data = oneData,type = nodeId,unlock = unlock})
        node:addChild(itemNode)
        table.insert( self.m_wheelItemMap[tierId],itemNode)
    end
    return #self.m_wheelItemMap[tierId]
end


function QuestNewWheelLayer:playShowAction()
    local userDefAction = function(callFunc)
        gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_WheelStart)
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
    QuestNewWheelLayer.super.playShowAction(self, userDefAction)
end

function QuestNewWheelLayer:onShowedCallFunc()
    local wheelType = self.m_wheelData:getType()
    if wheelType == 2  or self.m_wheelData:isWillchangeToLevelThree(false) then
        self:runCsbAction("idle_1", false)
    elseif wheelType == 3 or self.m_wheelData:isWillchangeToLevelFour(false) then
        self:runCsbAction("idle_2", false)
    elseif wheelType == 4 then
        self:runCsbAction("idle_3", false)
    end
    self.bl_touchEnable = true
    self:doUnloclLevelThreeAct()
end

function QuestNewWheelLayer:clickFunc(_sander)
    if not self.bl_touchEnable then
        return
    end
    if self.m_checkChang then
        return
    end
    local name = _sander:getName()
    if name == "btn_close" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_WHEEL_ROLL_OVER)
            end
        )
    elseif name == "Button_1" then
        self.bl_touchEnable = false
        local hasPlayed, posId,wheelCoins,hitTier = self.m_wheelData:isWheelHasPalyed()
        if hasPlayed then
            self.m_overPosIds = posId
            self.m_overCoins = wheelCoins
            self.m_hitTier = hitTier
            self.m_jackpotType = self.m_wheelData:getWheelGainBigJackpotType()
       
            self:doWheelAct()
        else
            self:requestPlayWheel()
        end
    end
end

function QuestNewWheelLayer:afterRollingOver(index)
    local hitIndex = self.m_overPosIds[index]
    if self:isHitPointer(index,hitIndex) then
        gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_WheelCheckOut)
    end
    if self.m_hitTier and self.m_hitTier == index then
        local gianAct = util_createAnimation(QUESTNEW_RES_PATH.QuestNewWheelLayer_GainEffect .. index .. ".csb")
        local node = self.m_rewardEffetNodeArray[index]
        if node then
            node:setVisible(true)
            node:addChild(gianAct,200,200)
        end
        gianAct:runCsbAction("idle", true)
        gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_WheelCheckOut)
    end
    
    local unlockTierNum = self.m_wheelData:getType()
    if unlockTierNum == 4 then
        unlockTierNum = 3
    end
    self.m_useWheel[index] = false
    local doReward = true
    for i,v in ipairs(self.m_useWheel) do
        if v then
            doReward = false
        end
    end
    if doReward  then
        self:showReward()
    end
end

function QuestNewWheelLayer:requestPlayWheel()
    G_GetMgr(ACTIVITY_REF.QuestNew):requestPlayWheel()
end

function QuestNewWheelLayer:onEnter()
   QuestNewWheelLayer.super.onEnter(self)
   gLobalNoticManager:addObserver(
       self,
       function(self,params)
        self:afterPlayWheel(params)
       end,
       ViewEventType.NOTIFY_REQUEST_AFTER_PLAYWHEEL
   )
end

function QuestNewWheelLayer:afterPlayWheel(params)
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

function QuestNewWheelLayer:doWheelAct()
    if self.m_doWheelAct then
        return
    end
    gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_WheelSpin)
    self.m_doWheelAct = true
    local unlockTierNum = self.m_wheelData:getType() >3 and 3 or self.m_wheelData:getType()
    local daleyTime = 0
    self.m_useWheel = {}
    for i=1,unlockTierNum do
        local posId = self.m_overPosIds[i]
        self.m_useWheel[#self.m_useWheel + 1] = true
        performWithDelay(
            self,
            function()
                self.m_allWheel[i]:recvData(posId,0,i%2 == 0)
                self.m_allWheel[i]:beginWheel(i%2 == 0)
            end,
            daleyTime
        )
        daleyTime = daleyTime +0.5
    end
end


function QuestNewWheelLayer:doUnloclLevelThreeAct()
    if self.m_wheelData:isWillchangeToLevelThree(false) then
        self.m_wheelData:clearWillchangeToLevelThree(false)
        self.m_checkChang = true
        self:runCsbAction("satrt1", false,function ()
            self:runCsbAction("idle_2", false)
            self:doChangeGrid(1,2,true)
        end)
    else
        self:doUnloclLevelFourAct()
    end
end

-- 奖励转换成箭头
function QuestNewWheelLayer:doChangeGrid(formTierId,toTierId,changeToFour)
    if not self.m_changeCheckGridIndex then
        self.m_changeCheckGridIndex = 1
    else
        self.m_changeCheckGridIndex = self.m_changeCheckGridIndex + 1
    end
    if not self.m_changeCheckTierIndex then
        self.m_changeCheckTierIndex = formTierId
    end
    if self.m_changeCheckTierIndex <= toTierId then
        local tierItemMap = self.m_wheelItemMap[self.m_changeCheckTierIndex]
        if self.m_changeCheckGridIndex < #tierItemMap then
            local gridItem = tierItemMap[self.m_changeCheckGridIndex]
            if gridItem then
                gridItem:doChangeToArrow(function ()
                    self:doChangeGrid(formTierId,toTierId,changeToFour)
                end)
            else
                self:doChangeGrid(formTierId,toTierId,changeToFour)
            end
        else
            self.m_changeCheckTierIndex = self.m_changeCheckTierIndex + 1
            self.m_changeCheckGridIndex = 0
            self:doChangeGrid(formTierId,toTierId,changeToFour)
        end
    else
        if changeToFour then
            self:doUnloclLevelFourAct()
        else
            self.m_checkChang = false
        end
    end
end


function QuestNewWheelLayer:doUnloclLevelFourAct()
    if self.m_wheelData:isWillchangeToLevelFour(false) then
        self.m_wheelData:clearWillchangeToLevelFour(false)
        self.m_checkChang = true
        self:runCsbAction("satrt2", false,function ()
            self:runCsbAction("idle_3", false)
            self.m_changeCheckTierIndex = 3
            self.m_changeCheckGridIndex = 0
            self:doChangeGrid(3,3,false)
        end)
    else
        self.m_checkChang = false
    end
end

function QuestNewWheelLayer:showReward()
    local rewardCoin = self.m_overCoins
    util_performWithDelay(
        self,
        function()
            self:closeUI()
            local rewardView = util_createView(QUESTNEW_CODE_PATH.QuestNewWheelRewardLayer,{coins = rewardCoin,jackpotType = self.m_jackpotType})
            if rewardView then
                gLobalViewManager:showUI(rewardView, ViewZorder.ZORDER_UI)
            end
        end,
        0.8
    )
end

function QuestNewWheelLayer:closeUI(callFunc)
    QuestNewWheelLayer.super.closeUI(self, callFunc)
end

function QuestNewWheelLayer:isHitPointer(tierId,hitIndex)
    local wheelData = self.m_wheelData:getWheelDataByTierId(tierId)
    local hitData = wheelData.p_grids[hitIndex]
    if hitData and hitData:isPointer() then
        return true
    end
    return false
end

return QuestNewWheelLayer
