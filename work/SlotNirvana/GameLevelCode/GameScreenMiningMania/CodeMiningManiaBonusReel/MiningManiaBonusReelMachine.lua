---
-- island li
-- 2019年1月26日
-- MiningManiaBonusReelMachine.lua
-- 
-- 玩法：
-- 
local BaseMiniMachine = require "Levels.BaseMiniMachine"
local BaseDialog = util_require("Levels.BaseDialog")
local GameEffectData = require "data.slotsdata.GameEffectData"
local MiningManiaBonusReelMachine = class("MiningManiaBonusReelMachine", BaseMiniMachine)
local PublicConfig = require "MiningManiaPublicConfig"

MiningManiaBonusReelMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

MiningManiaBonusReelMachine.m_bonusRootSccale = 1

-- MiningManiaBonusReelMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
-- MiningManiaBonusReelMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识



-- 构造函数
function MiningManiaBonusReelMachine:ctor()
    BaseMiniMachine.ctor(self)

    self.m_result = nil
    self.m_endFunc = nil
    self.m_curIndex = 0 --当前结果索引

    self.m_totalTimes = 6
    self.m_myCol = 1

    --座位
    self.m_playerItems = {}
    --自己座位列的标识
    self.m_myColAni = {}
    -- 鱼钩动画
    self.m_yuGouAniTbl = {}
    -- 上层添加小块节点
    self.m_topYuGouNode = {}
    -- 终点Y坐标
    self.m_endPosY = 560
    -- 每秒移动的速度
    self.m_speed = 400
end

function MiningManiaBonusReelMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_parent = data.parent 

    self.m_machineRootScale = self.m_parent.m_machineRootScale


    --滚动节点缓存列表
    self.cacheNodeMap = {}

    

    --init
    self:initGame()
end

function MiningManiaBonusReelMachine:initGame()


    --初始化基本数据
    self:initMachine(self.m_moduleName)

end


-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MiningManiaBonusReelMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MiningMania"
end

function MiningManiaBonusReelMachine:getMachineConfigName()

    return "MiningManiaMachineConfig.csv"
end

function MiningManiaBonusReelMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    BaseMiniMachine.initMachine(self)
end

function MiningManiaBonusReelMachine:scaleMainLayer(_scale)
    self.m_bonusRootSccale = _scale
    -- self:findChild("root"):setScale(_scale)
end

----------------------------- 玩法处理 -----------------------------------

function MiningManiaBonusReelMachine:showStartBonusView()
    performWithDelay(self.m_scWaitNode, function()
        self:showStartDialog()
    end, 0.5)
end

function MiningManiaBonusReelMachine:showMySelfColEffect()
    for index=1, 5 do
        if index == self.m_myCol then
            gLobalSoundManager:playSound(PublicConfig.Music_BonusReel_Light)
            local item = self.m_playerItems[index]
            item:runCsbAction("start", false, function()
                item:runCsbAction("idle", true)
            end)
            self.m_myColAni[index]:setVisible(true)
            self.m_myColAni[index]:runCsbAction("start", false, function()
                self.m_myColAni[index]:runCsbAction("idle", true)
            end)
        end
    end
end

-- 社交1开始弹板
function MiningManiaBonusReelMachine:showStartDialog()
    local endCallFunc = function()
        self:showMySelfColEffect()
        performWithDelay(self.m_scWaitNode, function()
            self:beginMiniReel()
        end, 0.5)
    end

    gLobalSoundManager:playSound(PublicConfig.Music_BonusReel_Describe)
    local view = self:showDialog("SheJiaoStart", nil, endCallFunc, BaseDialog.AUTO_TYPE_ONLY)
    view:findChild("root"):setScale(self.m_bonusRootSccale)
    local secondTime = self:getSecondTimeData() or {}
    -- 显示dialog布局
    for i=1, 3 do
        local times = secondTime[i] or 0
        view:findChild("m_lb_num_"..i):setString(times.."S")
    end
    util_setCascadeOpacityEnabledRescursion(view, true)
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function MiningManiaBonusReelMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)
    
    return ccbName
end

---
-- 读取配置文件数据
--
function MiningManiaBonusReelMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function MiningManiaBonusReelMachine:initMachineCSB( )

    self:createCsbNode("MiningMania/GameScreenMiningMania_SheJiao1.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")

    --收集区域
    self.m_collectBar = util_createView("CodeMiningManiaSrc.MiningManiaBaseCollectView", self)
    self:findChild("Shoujiqu"):addChild(self.m_collectBar)

    --剩余次数
    self.m_remainTimeNode = util_createAnimation("MiningMania_FreeSpinBar_SheJiao.csb")
    self:findChild("SpinBar"):addChild(self.m_remainTimeNode)
    
    for index = 1, 5 do
        local node = self:findChild("Node_Seat_"..(index - 1))
        local item = util_createView("CodeMiningManiaBonusReel.MiningManiaBonusReelPlayerItem")
        node:addChild(item)
        self.m_playerItems[index] = item

        self.m_myColAni[index] = util_createAnimation("WinFrameMiningMania_Reel_ziji.csb")
        self:findChild("Node_Me_"..index):addChild(self.m_myColAni[index])
        self.m_myColAni[index]:setVisible(false)

        self.m_yuGouAniTbl[index] = util_createAnimation("MiningManiaSheJiaoDiaogou.csb")
        self:findChild("Node_yugou_"..index):addChild(self.m_yuGouAniTbl[index])

        self.m_topYuGouNode[index] = self:findChild("Node_top_"..index)
    end

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scMyScheduleNode = cc.Node:create()
    self:addChild(self.m_scMyScheduleNode)

    self.m_scOtherScheduleNode = cc.Node:create()
    self:addChild(self.m_scOtherScheduleNode)
end

function MiningManiaBonusReelMachine:onEnter()
    MiningManiaBonusReelMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    --关闭个人信息界面
    gLobalNoticManager:addObserver(self,handler(self,function(self, _index)
        self:refreshChairs()
    end),ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER)
end

function MiningManiaBonusReelMachine:onExit()
    MiningManiaBonusReelMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_scMyScheduleNode ~= nil then
        self.m_scMyScheduleNode:unscheduleUpdate()
    end

    if self.m_scOtherScheduleNode ~= nil then
        self.m_scOtherScheduleNode:unscheduleUpdate()
    end
end

-- 根据index转换需要节点坐标系
function MiningManiaBonusReelMachine:getWorldToNodePos(_nodeTaget, _pos)
    local tarSpPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(tarSpPos))
    local endPos = _nodeTaget:convertToNodeSpace(worldPos)
    return endPos
end

--[[
    刷新座位
]]
function MiningManiaBonusReelMachine:refreshChairs()
    -- local players = self.m_parent.m_roomData:getRoomRanks()
    if not self.m_result then
        return
    end
    local playersInfo = self.m_result.data.sets or {}
    for index = 1, 5 do
        local info = nil
        for i=1, 5 do
            local curInfo = playersInfo[i]
            if curInfo and curInfo.chairId == index - 1 then
                info = playersInfo[index]
                break
            end
        end
        local item = self.m_playerItems[index]
        if info then
            item:setVisible(true)
            local udid = item:getPlayerID()
            local robot = item:getPlayerRobotInfo()
            item:refreshData(info)
            --刷新头像
            if udid ~= info.udid then
                item:refreshHead()
            end

            if info.udid and info.udid ~= "" then
                --刷新头像
                if udid ~= info.udid  then
                    item:refreshHead()
                end
            else
                -- 刷新机器人头像
                if robot and robot ~= info.robot  then
                    item:refreshHead()
                end
            end
        else
            item:refreshData(nil)
            item:setVisible(false)
        end

        -- 自己列的标识
        if item:isMySelf() then
            self.m_myCol = index
        end
    end
end


-- 下一次spin
function MiningManiaBonusReelMachine:playEffectNotifyNextSpinCall( )
    if self.m_curIndex <= self.m_totalTimes then
        for i=1, 5 do
            self.m_topYuGouNode[i]:removeAllChildren()
        end
        self:startCollectMyBonusMul()
    else
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
            self.m_endFunc = nil
        end
    end
end

-- 收集自己所在的列
function MiningManiaBonusReelMachine:startCollectMyBonusMul()
    self.m_myCurPosY = 0
    if self.m_scMyScheduleNode ~= nil then
        local curColData = self:getCurColBonusData(self.m_myCol)
        self.m_playerItems[self.m_myCol]:playYaoGanTrigger()
        gLobalSoundManager:playSound(PublicConfig.Music_BonusReel_Collect)
        self.m_scMyScheduleNode:onUpdate(
            function(delayTime)
                self:collectMyBonusMul(delayTime, curColData)
            end
        )
    end
end

-- 收集自己所在的列
function MiningManiaBonusReelMachine:collectMyBonusMul(_delayTime, _curColData)
    local delayTime = _delayTime
    local curColData = _curColData
    -- 这一帧移动的距离
    local diffMove = self.m_speed*delayTime
    
    self.m_isPlay = true
    if self.m_myCurPosY < self.m_endPosY then
        self.m_myCurPosY = self.m_myCurPosY + diffMove
        self.m_yuGouAniTbl[self.m_myCol]:setPositionY(self.m_myCurPosY)
        -- 重新设置假小块位置
        self:setFalseSymbolPosY(self.m_myCurPosY, diffMove, curColData)
    else
        gLobalSoundManager:playSound(PublicConfig.Music_BonusReel_CarDown)
        -- 重新设置假小块位置
        self:setFalseSymbolPosY(self.m_myCurPosY, diffMove, curColData)
        self.m_yuGouAniTbl[self.m_myCol]:setPositionY(self.m_endPosY)
        local movoAct = cc.MoveTo:create(0.5, cc.p(0, 0))
        self.m_yuGouAniTbl[self.m_myCol]:runAction(movoAct)
        self.m_playerItems[self.m_myCol]:playYaoGanIdle()
        if self.m_scMyScheduleNode ~= nil then
            self.m_scMyScheduleNode:unscheduleUpdate()
        end
        self:startCollectOtherBonusMul()
    end
end

-- 收集其他列
function MiningManiaBonusReelMachine:startCollectOtherBonusMul()
    self.m_otherCurPosY = 0
    if self.m_scOtherScheduleNode ~= nil then
        local colDataTbl = {}
        for i=1, 5 do
            if i ~= self.m_myCol then
                colDataTbl[i] = self:getCurColBonusData(i)
                self.m_playerItems[i]:playYaoGanTrigger()
            end
        end
        gLobalSoundManager:playSound(PublicConfig.Music_BonusReel_Collect)
        self.m_scOtherScheduleNode:onUpdate(
            function(delayTime)
                self:collectOtherBonusMul(delayTime, colDataTbl)
            end
        )
    end
end

-- 收集其他列
function MiningManiaBonusReelMachine:collectOtherBonusMul(_delayTime, _colDataTbl)
    local delayTime = _delayTime
    local colDataTbl = _colDataTbl
    -- 这一帧移动的距离
    local diffMove = self.m_speed*delayTime
    
    self.m_isPlay = true
    if self.m_otherCurPosY < self.m_endPosY then
        self.m_otherCurPosY = self.m_otherCurPosY + diffMove
        for i=1, 5 do
            if i ~= self.m_myCol then
                local curColData = colDataTbl[i]
                self.m_yuGouAniTbl[i]:setPositionY(self.m_otherCurPosY)
                -- 重新设置假小块位置
                self:setFalseSymbolPosY(self.m_otherCurPosY, diffMove, curColData)
            end
        end
    else
        gLobalSoundManager:playSound(PublicConfig.Music_BonusReel_CarDown)
        for i=1, 5 do
            if i ~= self.m_myCol then
                self.m_yuGouAniTbl[i]:setPositionY(self.m_endPosY)
                local movoAct = cc.MoveTo:create(0.5, cc.p(0, 0))
                self.m_yuGouAniTbl[i]:runAction(movoAct)
                self.m_playerItems[i]:playYaoGanIdle()
                local curColData = colDataTbl[i]
                -- 重新设置假小块位置
                self:setFalseSymbolPosY(self.m_otherCurPosY, diffMove, curColData)
            end
        end
        if self.m_scOtherScheduleNode ~= nil then
            self.m_scOtherScheduleNode:unscheduleUpdate()
        end
        performWithDelay(self.m_scWaitNode, function()
            self:refreshRank()
        end, 0.5)
    end
end

-- 重新排名
function MiningManiaBonusReelMachine:refreshRank()
    local curRankList = self:getRankList()
    gLobalSoundManager:playSound(PublicConfig.Music_BonusReel_RankRefresh)
    for i=1, #curRankList do
        local rankInfo = curRankList[i]
        self.m_playerItems[rankInfo.p_index]:refreshUserRank(i)
        self.m_playerItems[i]:refreshRankAni()
    end

    performWithDelay(self, function()
        self:delayTimeBeginReel()
    end, 1.0)
end

function MiningManiaBonusReelMachine:delayTimeBeginReel()
    if self.m_curIndex >= self.m_totalTimes then
        self:showEndReward()
    else
        self:beginMiniReel()
    end
end

-- 社交1结束
function MiningManiaBonusReelMachine:showEndReward()
    local endCallFunc = function()
        self:showNewBonusStart()
    end

    gLobalSoundManager:playSound(PublicConfig.Music_BonusReel_Over_Self)
    -- 社交1弹板
    local view = self:showDialog("SheJiaoOver", nil, endCallFunc, BaseDialog.AUTO_TYPE_NOMAL, nil)
    view:findChild("root"):setScale(self.m_bonusRootSccale)
    local rootNode = view:findChild("root")
    local mainNode = view:findChild("Node_main")
    local seatNode = self:findChild("Node_Seat_"..(self.m_myCol - 1))
    if seatNode then
        local viewPos = util_convertToNodeSpace(seatNode, rootNode)
        mainNode:setPosition(viewPos)
        local moveAct = cc.MoveTo:create(0.5, cc.p(0, 0))
        mainNode:runAction(moveAct)
    end

    -- 弹板上的头像
    local item = util_createView("CodeMiningManiaBonusReel.MiningManiaBonusReelPlayerItem")
    item:setNodeVisible()
    view:findChild("Node_role"):addChild(item)

    -- 弹板上的倍数
    local curMul = self.m_playerItems[self.m_myCol]:getMulData()
    view:findChild("m_lb_num"):setString("X"..curMul)

    -- 弹板上的排名和时间
    local curRank, curTime = self:getCurRankTimes()
    view:findChild("m_lb_num_1"):setString(curTime.."S")

    for i = 1, 5 do
        view:findChild("sp_rank_"..i):setVisible(i==curRank)
    end

    local playersInfo = self.m_result.data.sets or {}
    for index = 1, 5 do
        local info = playersInfo[index]
        if info then
            local udid = item:getPlayerID()
            item:refreshData(info)
            --刷新头像
            if info.udid and info.udid ~= "" and item:isMySelf() then
                item:refreshHead()
                break
            end
        end
    end

    util_setCascadeOpacityEnabledRescursion(view, true)
end

-- 社交2弹板开始
function MiningManiaBonusReelMachine:showNewBonusStart()
    local endCallFunc = function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
            self.m_endFunc = nil
        end
    end

    globalMachineController:playBgmAndResume(PublicConfig.Music_BonusReel_Over_Dialog, 3, 0, 1)
    local view = self:showDialog("SheJiaoStart2", nil, endCallFunc, BaseDialog.AUTO_TYPE_NOMAL, nil)
    view:findChild("root"):setScale(self.m_bonusRootSccale)

    local dialogData = self:getDialogData()
    local secondTime = self:getSecondTimeData() or {}

    -- 显示dialog布局
    for i=1, 5 do
        local item = dialogData[i].p_item
        local mul = dialogData[i].p_mul
        view:findChild("Node_role_"..i):addChild(item)
        view:findChild("text_mul_"..i):setString("X"..mul)

        view:findChild("Node_guang_"..i):setVisible(false)
        if item:isMySelf() then
            view:findChild("Node_guang_"..i):setVisible(true)
        end

        if i <= 3 then
            local times = secondTime[i] or 0
            view:findChild("text_time_"..i):setString(times.."S")

            view:findChild("Node_User_tx_"..i):setVisible(false)
        end
        if item:isMySelf() then
            if i == 1 then
                view:findChild("Node_User_tx_1"):setVisible(true)
            elseif i == 2 or i == 3 then
                view:findChild("Node_User_tx_2"):setVisible(true)
            elseif i == 4 or i == 5 then
                view:findChild("Node_User_tx_3"):setVisible(true)
            end
        end
    end

    util_setCascadeOpacityEnabledRescursion(view, true)
end

-- 获取社交2实际的初始时间
function MiningManiaBonusReelMachine:getSecondTimeData()
    local initRoadTimeTbl = {}
    local secondRndLine = self.m_result.data.secondRndLine
    local intervalDis = self.m_parent.m_machine_carView.m_intervalDis
    local moveDis = self.m_parent.m_machine_carView.m_moveDis
    local timeType = self.m_parent.m_machine_carView.SYMBOL_SCORE_BONUS_9
    for i=1, 3 do
        local oneLine = secondRndLine[i]
        local lineLen = #oneLine
        -- 算总时间
        initRoadTimeTbl[i] = lineLen * intervalDis / moveDis

        for k, v in pairs(oneLine) do
            local rewardType = v[1]
            local rewardMul = v[2]
            if rewardType == timeType then
                -- 算出时间类型占用的时间
                local rewardTime = rewardMul/lineLen*initRoadTimeTbl[i]
                initRoadTimeTbl[i] = initRoadTimeTbl[i] - rewardTime
            end
        end
        initRoadTimeTbl[i] = math.ceil(initRoadTimeTbl[i]) + self.m_parent.m_machine_carView.m_reduceSpeedTime
    end
    return initRoadTimeTbl
end

-- 获取社交2开始弹板数据
function MiningManiaBonusReelMachine:getDialogData()
    -- 头像；排名；倍数；时间
    local playDataTbl = {}

    local playersInfo = self.m_result.data.sets or {}
    local firstRndChairRank = self.m_result.data.firstRndChairRank or {}
    local firMulData = self.m_result.data.firstRndUserMultiple or {}
    for index = 1, 5 do
        local tempTbl = {}
        local info = playersInfo[index]
        local item = util_createView("CodeMiningManiaBonusReel.MiningManiaBonusReelPlayerItem")
        tempTbl.p_item = item

        -- 排名
        for j = 1, #firstRndChairRank do
            local chairId = firstRndChairRank[j]
            if info.chairId == chairId then
                tempTbl.p_rank = j
                break
            end
        end
        -- 倍数
        tempTbl.p_mul = firMulData[index] or 0

        if info then
            item:setNodeVisible()
            local udid = item:getPlayerID()
            local robot = item:getPlayerRobotInfo()
            item:refreshData(info)
            --刷新头像
            if info.udid and info.udid ~= "" then
                item:refreshHead()
            else
                -- 刷新机器人头像
                if robot and robot ~= info.robot  then
                    item:refreshHead()
                end
            end
        else
            item:refreshData(nil)
            item:setVisible(false)
        end
        table.insert(playDataTbl, tempTbl)
    end

    -- 按排名进去排序
    table.sort(playDataTbl, function(a, b)
        if a.p_rank ~= b.p_rank then
            return a.p_rank < b.p_rank
        end
        return false
    end)

    return playDataTbl
end

-- 获取当前所在名次的时间
function MiningManiaBonusReelMachine:getCurRankTimes()
    local curRankList = self:getRankList()
    local curRank = 5
    local rankTime = 3
    for i=1, 5 do
        if i == self.m_myCol then
            local item = self.m_playerItems[i]
            curRank = item:getCurRank()
            break
        end
    end

    if curRank == 1 then
        rankTime = 1
    elseif curRank == 2 or curRank == 3 then
        rankTime = 2
    elseif curRank == 4 or curRank == 5 then
        rankTime = 3
    end

    local secondTime = self:getSecondTimeData() or {}
    local curTime = secondTime[rankTime] or 0
    return curRank, curTime
end

-- 获取当前的排名
function MiningManiaBonusReelMachine:getRankList()
    local rankList = {}
    for i=1, 5 do
        local tempTbl = {}
        tempTbl.p_index = i
        tempTbl.p_mul = self.m_playerItems[i]:getMulData()
        table.insert(rankList, tempTbl)
    end
    table.sort(rankList, function(a, b)
        if a.p_mul ~= b.p_mul then
            return a.p_mul > b.p_mul
        end
        return false
    end)
    return rankList
end

-- 重新设置假小块位置
function MiningManiaBonusReelMachine:setFalseSymbolPosY(_curPosY, _diffMove, _curColData)
    local curPosY = _curPosY
    local diffMove = _diffMove
    local curColData = _curColData
    if #curColData > 0 then
        for k, v in pairs(curColData) do
            local moveNode = v.p_moveNode
            local bonusNodeScore = v.p_bonusNodeScore
            local targetPosY = v.p_targetPosY
            local curCol = v.p_cloumnIndex
            local symbolState = v.p_state
            if symbolState and curPosY+self.m_symbolTargetPosY[k] >= targetPosY then
                local curNodePosY = moveNode:getPositionY()
                if curNodePosY >= self.m_endPosY then
                    if self.m_isPlay then
                        self.m_isPlay = false
                        gLobalSoundManager:playSound(PublicConfig.Music_BonusReel_CollectFeedBack)
                    end
                    moveNode:runAnim("shouji", false, function()
                        moveNode:setVisible(false)
                    end)
                    bonusNodeScore:runCsbAction("shouji", false)
                    moveNode:setPositionY(self.m_endPosY)
                    local curMul = v.p_mul
                    self.m_playerItems[curCol]:refreshUserMul(curMul)
                    self.m_playerItems[curCol]:playCollectEffect()
                    v.p_state = false
                else
                    moveNode:setPositionY(curPosY+self.m_symbolTargetPosY[k])
                end
            end
        end
    end
end

-- 获取当前列的bonus数据
function MiningManiaBonusReelMachine:getCurColBonusData(_col)
    local curCol = _col
    local curMulData = self.m_result.data.firstRndMultiples[self.m_curIndex]
    local colTempTbl = {}
    local columnData = self.m_reelColDatas[curCol]
    local halfH = columnData.p_showGridH * 0.5
    if next(curMulData) then
        for k, v in pairs(curMulData) do
            local tempTbl = {}
            tempTbl.p_pos = tonumber(k)
            local fixPos = self:getRowAndColByPos(tonumber(k))
            tempTbl.p_rowIndex = fixPos.iX
            tempTbl.p_cloumnIndex = fixPos.iY
            tempTbl.p_mul = v
            if curCol == fixPos.iY then
                local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                if symbolNode then
                    symbolNode:setVisible(false)
                    local moveNode = self.m_parent:createMiningManiaSymbol(symbolNode.p_symbolType)
                    moveNode:runAnim("idleframe", true)
                    local startPos = self:getWorldToNodePos(self.m_topYuGouNode[curCol], tempTbl.p_pos)
                    moveNode:setPosition(startPos)
                    self.m_topYuGouNode[curCol]:addChild(moveNode)
                    tempTbl.p_moveNode = moveNode

                    local bonusNodeScore = util_createAnimation("Socre_MiningMania_Bonus_Mul.csb")
                    bonusNodeScore:runCsbAction("idle1", true)
                    bonusNodeScore:findChild("m_lb_num"):setString("X"..tempTbl.p_mul)
                    local m_spine = moveNode:getNodeSpine()
                    util_spinePushBindNode(m_spine,"zi2",bonusNodeScore)
                    tempTbl.p_bonusNodeScore = bonusNodeScore
                end
                colTempTbl[#colTempTbl+1] = tempTbl
            end
        end
    end

    if #colTempTbl > 0 then
        table.sort(colTempTbl, function(a, b)
            if a.p_rowIndex ~= b.p_rowIndex then
                return a.p_rowIndex < b.p_rowIndex
            end
            return false
        end)
        -- 重新设置Y坐标，这个坐标为：移动距离+这个点距离=开始移动
        for k, v in pairs(colTempTbl) do
            v.p_targetPosY = self.m_symbolTargetPosY[v.p_rowIndex]
            v.p_state = true
        end
    end
    
    return colTempTbl
end

--[[
    重置界面
]]
function MiningManiaBonusReelMachine:resetUI(result,func)
    self.m_result = result
    self.m_endFunc = func
    self.m_curIndex = 0
    self.m_myCurPosY = 0
    self.m_otherCurPosY = 0
    self.m_totalTimes = self.m_result.data.firstRndTimes
    self.m_myCol = 1
    for i=1, 5 do
        self.m_myColAni[i]:setVisible(false)
        self.m_topYuGouNode[i]:removeAllChildren()

        local item = self.m_playerItems[i]
        item:refreshMulData(0)
        item:refreshUserMul(0)
    end
    self:refreshChairs()

    -- 鱼钩移动到这个位置，播动画
    self.m_symbolTargetPosY = {}
    for i=1, 4 do
        local pos = (4-i)*5
        local endPos = self:getWorldToNodePos(self:findChild("Node_yugou_"..1), pos)
        self.m_symbolTargetPosY[i] = endPos.y
    end

    self:refreshLeftTimes(true)
    self:refreshCollectScore()
end

function MiningManiaBonusReelMachine:beginMiniReel()
    self.m_curIndex = self.m_curIndex + 1
    BaseMiniMachine.beginReel(self)
    self:refreshLeftTimes()
    self:netWorkCallFun()
end

function MiningManiaBonusReelMachine:requestSpinReusltData()

    self.m_isWaitingNetworkData = true
end

-- 消息返回更新数据
function MiningManiaBonusReelMachine:netWorkCallFun()
    self.m_isWaitingNetworkData = false
    local spinResultData = {}
    local reelData = self.m_result.data.firstRndReels[self.m_curIndex]
    spinResultData.reels = reelData

    -- self:resetDataWithLineLogic()
    self.m_runSpinResultData:parseResultData(spinResultData, self.m_lineDataPool)

    self:updateNetWorkData()
end

function MiningManiaBonusReelMachine:slotReelDown()
    MiningManiaBonusReelMachine.super.slotReelDown(self)
end

-- 更新base收集分数
function MiningManiaBonusReelMachine:refreshCollectScore()
    local userScoreData = self.m_result.data.userScore
    local uuid = globalData.userRunData.userUdid
    local userScore = userScoreData[uuid]
    
    local strCoins = util_formatCoins(userScore,50)
    self.m_collectBar:setCollectCoins(strCoins, true)
end

--[[
    刷新剩余次数
]]
function MiningManiaBonusReelMachine:refreshLeftTimes(_isOnEnter)
    if _isOnEnter then
        self.m_remainTimeNode:findChild("m_lb_num"):setString(0)
    else
        self.m_remainTimeNode:findChild("m_lb_num"):setString(self.m_curIndex)
    end
    self.m_remainTimeNode:findChild("m_lb_num_0"):setString(self.m_totalTimes)
end

function MiningManiaBonusReelMachine:updateReelGridNode(_symbolNode)
    if self:getCurSymbolIsBonus(_symbolNode.p_symbolType) then
        self:setSpecialNodeMulBonus(_symbolNode)
    end
end

--设置bonus上的倍数
function MiningManiaBonusReelMachine:setSpecialNodeMulBonus(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType  then
        return
    end

    local curBet = globalData.slotRunData:getCurTotalBet()
    local sScore = ""
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local nodeMul, mul
    if not tolua.isnull(spineNode.m_nodeMul) then
        nodeMul = spineNode.m_nodeMul
    else
        nodeMul = util_createAnimation("Socre_MiningMania_Bonus_Mul.csb")
        util_spinePushBindNode(spineNode,"zi2",nodeMul)
        spineNode.m_nodeMul = nodeMul
    end

    if symbolNode.m_isLastSymbol == true then
        sScore = self:getBonusMul(self:getPosReelIdx(iRow, iCol), symbolNode.p_symbolType)
    else
        -- 获取随机分数（本地配置）
        sScore = self:randomDownSymbolMul(symbolNode.p_symbolType)
    end
    if nodeMul then
        sScore = "X" .. sScore
        nodeMul:findChild("m_lb_num"):setString(sScore)
    end
end

--[[
    获取bonus真实倍数
]]
function MiningManiaBonusReelMachine:getBonusMul(id)
    local mulData = self.m_result.data.firstRndMultiples[self.m_curIndex]
    if next(mulData) then
        for k, v in pairs(mulData) do
            local curPos = tonumber(k)
            if curPos == id then
                return v
            end
        end
    end
    return 0
end

--随时获得分数
function MiningManiaBonusReelMachine:randomDownSymbolMul(_symbolType)
    --区间
    --local randomData1 = {10, 20, 30, 50}
    --local randomData2 = [10,20),[20,30),[30,50),[50,80)
    local randomData = {{10, 15}, {20, 25}, {30, 35, 40, 45}, {50, 55, 60, 65, 70, 75}}
    if self.m_curIndex < self.m_totalTimes then
        if _symbolType == self.m_parent.SYMBOL_SCORE_BONUS_5 then
            return 10
        elseif _symbolType == self.m_parent.SYMBOL_SCORE_BONUS_6 then
            return 20
        elseif _symbolType == self.m_parent.SYMBOL_SCORE_BONUS_7 then
            return 30
        elseif _symbolType == self.m_parent.SYMBOL_SCORE_BONUS_8 then
            return 50
        end
    else
        local curRandomeData = randomData[1]
        if _symbolType == self.m_parent.SYMBOL_SCORE_BONUS_5 then
            curRandomeData = randomData[1]
        elseif _symbolType == self.m_parent.SYMBOL_SCORE_BONUS_6 then
            curRandomeData = randomData[2]
        elseif _symbolType == self.m_parent.SYMBOL_SCORE_BONUS_7 then
            curRandomeData = randomData[3]
        elseif _symbolType == self.m_parent.SYMBOL_SCORE_BONUS_8 then
            curRandomeData = randomData[4]
        end
        local random = math.random(1, #curRandomeData)
        return curRandomeData[random]
    end
end

function MiningManiaBonusReelMachine:getCurSymbolIsBonus(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.m_parent.SYMBOL_SCORE_BONUS_5 or
        symbolType == self.m_parent.SYMBOL_SCORE_BONUS_6 or
        symbolType == self.m_parent.SYMBOL_SCORE_BONUS_7 or
        symbolType == self.m_parent.SYMBOL_SCORE_BONUS_8 then
        return true
    end
    return false
end

-- 有特殊需求判断的 重写一下
function MiningManiaBonusReelMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                if self.m_myCol == _slotNode.p_cloumnIndex then
                    return true
                end
                return false
            end
        end
    end

    return false
end

-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function MiningManiaBonusReelMachine:symbolBulingEndCallBack(_slotNode)
    _slotNode:runAnim("idleframe", true)
end

return MiningManiaBonusReelMachine
