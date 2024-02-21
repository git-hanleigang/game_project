----
-- island
-- 2018年6月4日
-- PirateBonusGameMachine.lua
--
-- 玩法：
--

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local CollectData = require "data.slotsdata.CollectData"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local PirateSlotsNode = require "CodePirateSrc.PirateSlotsNode"

local PirateBonusGameMachine = class("PirateBonusGameMachine", BaseSlotoManiaMachine)

-- 构造函数
function PirateBonusGameMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    --init
    self:initGame()
end

function PirateBonusGameMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function PirateBonusGameMachine:initUI()
end

function PirateBonusGameMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    self.m_machineModuleName = self.m_moduleName

    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("Pirate/GameScreenMachine1.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
    self:updateBaseConfig()

    self:updateMachineData()
    self:initMachineData()
    self:initSymbolCCbNames()

    self:drawReelArea()

    self:updateReelInfoWithMaxColumn()
    self:initReelEffect()

    self:slotsReelRunData(
        self.m_configData.p_reelRunDatas,
        self.m_configData.p_bInclScatter,
        self.m_configData.p_bInclBonus,
        self.m_configData.p_bPlayScatterAction,
        self.m_configData.p_bPlayBonusAction
    )
end

function PirateBonusGameMachine:initMachineData()
    self:BaseMania_initCollectDataList()

    self.m_spinResultName = self.m_moduleName .. "_Datas"

    -- 设置bet index

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    self:checkHasBigSymbol()
end

---
-- 读取配置文件数据
--
function PirateBonusGameMachine:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
end

---
-- 根据类型获取对应节点
--
function PirateBonusGameMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- release_print("创建了node")
        -- print("创建 SlotNode")
        local node = PirateSlotsNode:create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        reelNode = node
    else
        -- print("从池子里面拿 SlotNode")
        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end

    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)

    return reelNode
end
---
-- 清空掉产生的数据
--
function PirateBonusGameMachine:clearSlotoData()
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
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function PirateBonusGameMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Pirate"
end

function PirateBonusGameMachine:getNetWorkModuleName()
    return "PirateV2"
end

----------------------------- 玩法处理 -----------------------------------

function PirateBonusGameMachine:slotOneReelDown(reelCol)
    BaseSlotoManiaMachine.slotOneReelDown(self, reelCol)
end

function PirateBonusGameMachine:slotReelDown()
    BaseSlotoManiaMachine.slotReelDown(self)
end

---------------------------------------------------------------------------

function PirateBonusGameMachine:beginReel()
    BaseSlotoManiaMachine.beginReel(self)

    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

function PirateBonusGameMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)

    self:updateNetWorkData()
end

function PirateBonusGameMachine:requestSpinReusltData()
    -- do nothing
    self.m_isWaitingNetworkData = true
end
---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function PirateBonusGameMachine:initCloumnSlotNodesByNetData()
    BaseSlotoManiaMachine.initCloumnSlotNodesByNetData(self)
end

function PirateBonusGameMachine:enterLevel()
end

function PirateBonusGameMachine:initSlotNode(reels)
    self.m_runSpinResultData.p_reels = reels
    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false

        while rowIndex >= 1 do
            local rowDatas = reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType, changeRowIndex, colIndex, true)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = self:getBounsScatterDataZorder(symbolType)

            parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)

            node.p_symbolType = symbolType
            --            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((changeRowIndex - 1) * columnData.p_showGridH + halfNodeH)
            node:runIdleAnim()
            rowIndex = rowIndex - stepCount
        end -- end while
    end
end

function PirateBonusGameMachine:initFixWild(lockWild)
    local vecFixWild = lockWild
    if vecFixWild == nil then
        return
    end
    for i = 1, #vecFixWild, 1 do
        local fixPos = self:getRowAndColByPos(vecFixWild[i])
        local targSp = self:getReelParentChildNode(fixPos.iY, fixPos.iX)
        if targSp then
            if targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                self:changeSymbolType(targSp,TAG_SYMBOL_TYPE.SYMBOL_WILD)
            end
            targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000)

            if self.m_vecFixWild == nil then
                self.m_vecFixWild = {}
            end
            self.m_vecFixWild[#self.m_vecFixWild + 1] = targSp

            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            targSp.m_bInLine = true
            targSp:setLinePos(linePos)
        end
    end
end

function PirateBonusGameMachine:setFSReelDataIndex(index)
    self.m_fsReelDataIndex = index
end

function PirateBonusGameMachine:setStoredIcons(storedIcons)
    self.m_runSpinResultData.p_storedIcons = storedIcons
end

function PirateBonusGameMachine:enterGamePlayMusic()
end

function PirateBonusGameMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function PirateBonusGameMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
end

function PirateBonusGameMachine:onExit()
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function PirateBonusGameMachine:checkNotifyUpdateWinCoin()
    -- do nothing mini 轮子不在通知赢钱线的变化了
end

function PirateBonusGameMachine:calculateLastWinCoin()
end

function PirateBonusGameMachine:addLastWinSomeEffect() -- add big win or mega win
end

function PirateBonusGameMachine:reelDownNotifyChangeSpinStatus()
    -- do nothing 滚动停止不通知
end

function PirateBonusGameMachine:playEffectNotifyChangeSpinStatus()
end

function PirateBonusGameMachine:playEffectNotifyNextSpinCall()
end

function PirateBonusGameMachine:staticsTasksSpinData()
end
function PirateBonusGameMachine:staticsTasksNetWinAmount()
end
function PirateBonusGameMachine:staticsTasksEffect()
end

function PirateBonusGameMachine:setCurrSpinMode(spinMode)
    self.m_currSpinMode = spinMode
end
function PirateBonusGameMachine:getCurrSpinMode()
    return self.m_currSpinMode
end

function PirateBonusGameMachine:setGameSpinStage(spinStage)
    self.m_currSpinStage = spinStage
end
function PirateBonusGameMachine:getGameSpinStage()
    return self.m_currSpinStage
end

function PirateBonusGameMachine:setLastWinCoin(winCoin)
    self.m_lastWinCoin = winCoin
end
function PirateBonusGameMachine:getLastWinCoin()
    return self.m_lastWinCoin
end

return PirateBonusGameMachine
