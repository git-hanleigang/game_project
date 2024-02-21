---
-- xcyy
-- 2018-12-18
-- RocketPupMiniMachine.lua
--
--

local miniSlotReelMachine = require "RocketPupSrc.miniSlotReelMachine"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local RocketPupMiniMachine = class("RocketPupMiniMachine", miniSlotReelMachine)

RocketPupMiniMachine.m_machineIndex = nil -- csv 文件模块名字
RocketPupMiniMachine.gameResumeFunc = nil
RocketPupMiniMachine.gameRunPause = nil
RocketPupMiniMachine.COLLECT_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 10

-- 构造函数
function RocketPupMiniMachine:ctor()
    miniSlotReelMachine.ctor(self)
    self.m_isInitSlotsNode = true
end

function RocketPupMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_machine = data.parent
    self.m_reelId = data.reelId
    self.m_maxReelIndex = data.maxReelIndex
    self.m_csbPath = data.csbPath
    self.m_weelNum = data.weelNum
    self.m_lockWildList = {}
    --init
    self:initGame()
end

function RocketPupMiniMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function RocketPupMiniMachine:MachineRule_newInitGame()
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function RocketPupMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "RocketPup"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function RocketPupMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

---
-- 读取配置文件数据
--
function RocketPupMiniMachine:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
end

function RocketPupMiniMachine:initMachineCSB()
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("RocketPup_qipan.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

function RocketPupMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    miniSlotReelMachine.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function RocketPupMiniMachine:setBuffDatas(_buffDatas)
    self.m_buffs = _buffDatas
end

function RocketPupMiniMachine:playAddWild(_buffLv, _buffValue, _index, _over)
    local effect = util_createAnimation("RocketPup_wildadd.csb")
    local effectNode = self:findChild("Node_wildadd")
    effectNode:addChild(effect)
    effect:playAction("add", false, function()
        effect:setVisible(false)
    end)
    for i=1,3 do
        effect:findChild(""..i):setVisible(i <= _buffLv)
    end
    
    local bar = util_createAnimation("RocketPup_wildadd_bar.csb")
    local barNode = self:findChild("Node_wildadd_bar")
    barNode:addChild(bar)
    local poa = nil
    local scale = 1
    if self.m_weelNum > 1 then
        scale = 0.6
    end
    if _index == 1 then
        local nodep = self.m_machine:findChild("Node_30")
        local a = 300/2
        if self.m_weelNum > 1 then
            a = a*0.6
        end
        poa = cc.p(nodep:getPositionX(),nodep:getPositionY() + a)
    else
        local nodep = self.m_machine:findChild("Node_qipanshu"..self.m_weelNum)
        local nodep1 = nodep:getChildByName("Node_".._index)
        local ps = nodep1:getPositionY()
        poa = cc.p(nodep1:getPositionX(),nodep1:getPositionY()+(300/2)*0.6)
    end
    local root = self.m_machine:findChild("root")
    util_changeNodeParent(root,barNode)
    local sl = self.m_machine:getMachineScale()
    local s = cc.p(poa.x*sl,poa.y*sl)
    barNode:setPosition(s)
    barNode:setScale(scale)
    
    bar:playAction("add", true, nil, 60)
    
    local m_lb_num = bar:findChild("m_lb_num")
    local barShowNum = 0
    local finishNum = tonumber(_buffValue)
    m_lb_num:setString(barShowNum)
    
    local time = util_csbGetAnimTimes(effect.m_csbAct, "add", 60)
    local frameTime = 6/60
    local updateCount = math.ceil(time/frameTime)
    local frameAddNum = math.max(0, math.ceil((finishNum - barShowNum) / updateCount))
    local function updateNum()
        barShowNum = barShowNum + frameAddNum
        if barShowNum >= finishNum then
            m_lb_num:setString(finishNum)
            m_lb_num:stopAllActions()
            if not tolua.isnull(bar) then
                util_fadeOutNode(bar, 0.5, _over)
            else
                if _over then
                    _over()
                end
            end
        else
            m_lb_num:setString(barShowNum)
        end
    end
    util_schedule(m_lb_num, updateNum, frameTime)
end

function RocketPupMiniMachine:onEnter()
    miniSlotReelMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function RocketPupMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function RocketPupMiniMachine:insterReelResultLines()
    miniSlotReelMachine.insterReelResultLines(self)
end

function RocketPupMiniMachine:reelDownNotifyChangeSpinStatus() 
    
end

function RocketPupMiniMachine:reelDownNotifyPlayGameEffect()
    miniSlotReelMachine.reelDownNotifyPlayGameEffect(self)
end

function RocketPupMiniMachine:playEffectNotifyChangeSpinStatus()
    self.m_machine:setFsAllRunDown(1)
end

function RocketPupMiniMachine:quicklyStopReel(colIndex)
    miniSlotReelMachine.quicklyStopReel(self, colIndex)
end

function RocketPupMiniMachine:showLineFrame()
    miniSlotReelMachine.showLineFrame(self)
end

function RocketPupMiniMachine:onExit()
    miniSlotReelMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function RocketPupMiniMachine:removeObservers()
    miniSlotReelMachine.removeObservers(self)
end

function RocketPupMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

function RocketPupMiniMachine:beginMiniReel()
    self.m_isInitSlotsNode = false
    miniSlotReelMachine.beginReel(self)
end

function RocketPupMiniMachine:replaceHigh(reels,_data)
    if _data and #_data > 0 then
        for i,v in ipairs(_data) do
            local posIndex = tonumber(v[1])
            local wild = v[2]
            local hang = 1
            local lie = 1
            if posIndex <= 4 then
                hang = 1
                lie = posIndex + 1
            elseif posIndex > 4 and posIndex <= 9 then
                hang = 2
                lie = posIndex-4
            else
                hang = 3
                lie = posIndex-9
            end
            local h = reels[hang]
            h[lie] = wild
        end
    end
end

-- 消息返回更新数据
function RocketPupMiniMachine:netWorkCallFun(spinResult)
    local selfData = spinResult.selfData or {}
    if selfData["SLOT1_SYMBOL"] then
        self:replaceHigh(spinResult.reels,selfData["SLOT1_SYMBOL"])
    end
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    
    if selfData.SLOT2_STICKY and #selfData.SLOT2_STICKY > 0 then
        self:initFsLockWild(selfData.SLOT2_STICKY)
    end
    if selfData.SLOT2_COIN and tonumber(selfData.SLOT2_COIN) > 0 then
        self.m_betc = tonumber(selfData.SLOT2_COIN)
    end
    -- -- buff3：去除低分图标的位置
    -- if selfData.SLOT1_SYMBOL and #selfData.SLOT1_SYMBOL > 0 then
    --     self.m_randoms = selfData.SLOT1_SYMBOL
    -- end
    self:updateNetWorkData()  
end

function RocketPupMiniMachine:enterLevel()
end

function RocketPupMiniMachine:enterLevelMiniSelf()
    miniSlotReelMachine.enterLevel(self)
end

function RocketPupMiniMachine:dealSmallReelsSpinStates()
    self.m_machine:setFsAllSpinStates(1)
end

-- 轮盘停止回调(自己实现)
function RocketPupMiniMachine:setDownCallFunc(func)
    self.m_reelDownCallback = func
end

function RocketPupMiniMachine:playEffectNotifyNextSpinCall()
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end

-- 处理特殊关卡 遮罩层级
function RocketPupMiniMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
    local maxzorder = 0
    local zorder = 0
    for i = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder > maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

---
--设置bonus scatter 层级
function RocketPupMiniMachine:getBounsScatterDataZorder(symbolType)
    return self.m_machine:getBounsScatterDataZorder(symbolType)
end

function RocketPupMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines
end

function RocketPupMiniMachine:checkGameResumeCallFun()
    if self:checkGameRunPause() then
        self.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end
        return false
    end
    return true
end

function RocketPupMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function RocketPupMiniMachine:pauseMachine()
    self.gameRunPause = true
end

function RocketPupMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

function RocketPupMiniMachine:initRandomSlotNodes()
    self.m_initGridNode = true
    self:randomSlotNodes()
    self:initGridList()
end

function RocketPupMiniMachine:addLineEffect()
    RocketPupMiniMachine.super.addLineEffect(self)
end

---
-- 清空掉产生的数据
--
function RocketPupMiniMachine:clearSlotoData()
    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then
        for i = #self.m_lineDataPool, 1, -1 do
            self.m_lineDataPool[i] = nil
        end
    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function RocketPupMiniMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end

function RocketPupMiniMachine:clearCurMusicBg()
end

function RocketPupMiniMachine:updateReelGridNode(node)
    self:setSpecialSymbolSkin(node, "wild_1")
end

function RocketPupMiniMachine:setSpecialSymbolSkin(_symbolNode, _skinName)
    if _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        local ccbNode = _symbolNode:getCCBNode()
        if not ccbNode then
            _symbolNode:checkLoadCCbNode()
        end
        ccbNode = _symbolNode:getCCBNode()
        if ccbNode and ccbNode.m_spineNode then
            ccbNode.m_spineNode:setSkin(_skinName)
        end
    end
end

function RocketPupMiniMachine:playReelDownSound(_iCol, _path)
    if self.m_reelId == 1 then
        RocketPupMiniMachine.super.playReelDownSound(self, _iCol, "RocketPupSounds/music_RocketPup_Reel_stop.mp3")
    end
end

function RocketPupMiniMachine:slotOneReelDown(reelCol)
    RocketPupMiniMachine.super.slotOneReelDown(self, reelCol)
end


function RocketPupMiniMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    elseif self.m_bInBonus then
        reelDatas = self.m_configData:getBonusReelDatasByColumnIndex(parentData.cloumnIndex)
    else
        -- "reel_cloumn_"..lv.."_"..parentData.cloumnIndex
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    -- 替换假滚卷轴
    self:getreplData(reelDatas)
    
    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

function RocketPupMiniMachine:getreplData(_data)
    local symbolBuffLv = self:getSymbolBuffLv()
    if symbolBuffLv > 0 then
        -- JQKA 
        local replaceSymbolTypes = {} -- {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 92}
        local lowSymbolTypes = {8, 7, 6, 5}
        for i=1,symbolBuffLv do
            local symbolType = lowSymbolTypes[i]
            if symbolType then
                table.insert(replaceSymbolTypes, symbolType)
            end
        end
        local tarSymbolType = 92
        self:replaceReelCloumn(_data, replaceSymbolTypes, tarSymbolType)
    end
end

function RocketPupMiniMachine:replaceReelCloumn(_reelCloumns, _replaces, _tar)
    if _reelCloumns and #_reelCloumns > 0 and _replaces and #_replaces > 0 then
        for i=1,#_reelCloumns do
            for j=1,#_replaces do
                if _reelCloumns[i] == _replaces[j] then
                    _reelCloumns[i] = _tar
                end
            end
        end
    end
end

function RocketPupMiniMachine:getSymbolBuffLv()
    local symbolBuffLv = 0
    if self.m_buffs and #self.m_buffs > 0 then
        for i=1,#self.m_buffs do
            if self.m_buffs[i].buffType == "SLOT1_SYMBOL" then
                symbolBuffLv = tonumber(self.m_buffs[i].value)
                break
            end
        end
    end
    return symbolBuffLv
end


function RocketPupMiniMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

function RocketPupMiniMachine:getBaseReelsTarSpPos(index)
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos = self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)
    return targSpPos
end

function RocketPupMiniMachine:randomSlotNodes()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        self:getreplData(reelDatas)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)

            symbolType = self:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            util_printLog("当前随机的信号值:"..symbolType)

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            --            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

return RocketPupMiniMachine
