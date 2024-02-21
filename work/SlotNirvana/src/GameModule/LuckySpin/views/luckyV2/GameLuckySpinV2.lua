--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-09-25 20:41:52
]]
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseSlots = require "Levels.BaseSlots"
local SpinResultData = require "data.slotsdata.SpinResultData"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local LuckySpinSlotNode = require "GameModule.LuckySpin.views.LuckySpinSlotNode"

local GameLuckySpinV2 = class("GameLuckySpinV2", BaseSlotoManiaMachine)
GameLuckySpinV2.SYMBOL_SPECAIL_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7

GameLuckySpinV2.m_closeCall = nil
GameLuckySpinV2.m_levelConfigData = nil
GameLuckySpinV2.m_levelGetAnimNodeCallFun = nil
GameLuckySpinV2.m_levelPushAnimNodeCallFun = nil
GameLuckySpinV2.m_gameSpinStage = nil
GameLuckySpinV2.m_currSpinMode = nil

function GameLuckySpinV2:ctor()
    -- BaseMachineProduceSlot
    BaseSlots.ctor(self)
    self.m_iFreeSpinTimes = 0
    self.m_validLineSymNum = VALID_LINE_SYM_NUM
    self.m_vecGetLineInfo = {}

    -- BaseMachineGameEffect
    self.m_gameEffects = {}
    self.m_isRunningEffect = false

    self.m_isShowSpecialNodeTip = true
    self.m_framePool = {}

    self.ACTION_TAG_LINE_FRAME = 20101
    self.m_LineEffectType = GameEffect.EFFECT_SHOW_ALL_LINE

    self.m_changeLineFrameTime = 2 -- 默认2秒， low symbol 两个周期
    self.m_levelUpSaleFunc = nil

    -- BaseMachine
    self.m_bProduceSlots_InFreeSpin = false
    self.m_vecSymbolEffectType = {}
    self.m_reelSlotsList = {}
    self.m_reelSlotDataPool = {}
    self.m_reelLineInfoPool = {}

    self.m_defaultEffectName = "Common/ReelEffect"

    self.m_reelNodePool = {}
    self.m_reelAnimNodePool = {}

    self.m_iOnceSpinLastWin = 0
    self.m_bIsBigWin = false
    self.m_serverWinCoins = 0
    self.m_freeSpinStartCoins = 0
    self.m_freeSpinOffSetCoins = 0

    self.m_reelResultLines = {}

    self.m_currentMusicBgName = nil
    self.m_winFrameCCB = nil
    self.m_preLoadSoundName = {}
    self.m_isChangeBGMusic = false
    self.m_reelDelayTime = 0 -- 默认为0 秒

    self.m_bCreateResNode = true

    self.m_reelRunSoundTag = -1
    self.m_expMultiNum = 1

    self.m_lineSlotNodes = {}
    self.m_longRunAddZorder = {}
    self.m_reelDownAddTime = 0

    self.m_isWaitingNetworkData = false
    self.m_LineEffectType = GameEffect.EFFECT_LINE_FRAME

    self:setGameSpinStage(IDLE)

    -- 本次spin 中产生的scatter bonus 数量 用于播放音效
    self.m_nScatterNumInOneSpin = 0
    self.m_nBonusNumInOneSpin = 0
    self.m_resetFreespinTimes = 0
    --设置scatter 出现时播放的音效
    self.m_bonusBulingSoundArry = {}
    self.m_scatterBulingSoundArry = {}

    self.m_ScatterShowCol = nil --- scatter限制列

    self.m_machineRootScale = 1

    self.m_isAllLineType = false

    self.m_reelScheduleDelegate = cc.Node:create()
    self:addChild(self.m_reelScheduleDelegate)

    -- 初始化触发buling音效
    self:setScatterDownScound()

    self.m_isSpecialReel = false

    self.m_soundHandlerId = nil
    self.m_soundGlobalId = nil

    -- BaseSlotoManiaMachine
    self.m_bQuestComplete = false
    self.m_lineDataPool = {}
    self.m_lineCount = 1

    self.m_runSpinResultData = SpinResultData.new()
    self.m_featureData = SpinFeatureData.new()
    self.m_spinRestMusicBG = false
end

function GameLuckySpinV2:initMachineData()
    self:BaseMania_initCollectDataList()

    self.m_spinResultName = self.m_moduleName .. "_Datas"

    globalData.slotRunData.gameModuleName = self.m_moduleName

    -- 设置bet index

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    -- 配置全局信息，供外部使用
    self.m_levelGetAnimNodeCallFun = function(symbolType, ccbName)
        return self:getAnimNodeFromPool(symbolType, ccbName)
    end
    self.m_levelPushAnimNodeCallFun = function(animNode, symbolType)
        self:pushAnimNodeToPool(animNode, symbolType)
    end

    self:checkHasBigSymbol()
end

function GameLuckySpinV2:initData_(data)
    self.m_closeCall = data
    self:initGame()
end

function GameLuckySpinV2:initGame()
    --初始化基本数据
    self:initMachine()
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}

    local payTable = globalData.luckySpinV2:getScore()
    if payTable == nil then
        payTable = cjson.decode(globalData.userRunData.loginUserData.luckySpinScore)
    end

    if globalData.luckySpinSaleData:isExist() == true then
        for key, value in pairs(payTable) do
            local lab = self:findChild("paytable_" .. key)
            if lab ~= nil then
                lab:setString("X" .. value)
            end
        end

        payTable = globalData.luckySpinSaleData.p_score["HIGH"]
        for key, value in pairs(payTable) do
            local lab = self:findChild("sale_" .. key)
            if lab ~= nil then
                if key == "same" then
                    lab:setString("X" .. value)
                else
                    lab:setString("X" .. value)
                end
            end
        end
    else
        for key, value in pairs(payTable) do
            local lab = self:findChild("paytable_" .. key)
            if lab ~= nil then
                lab:setString("X" .. value)
            end
        end
    end
    self:runCsbAction("ildeframe", true)

    -- self:findChild("shade_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
    -- self:findChild("shade_2"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
    -- self:findChild("shade_3"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
end

function GameLuckySpinV2:perLoadSLotNodes()
end

--[[
    @desc: 读取轮盘配置信息
    time:2020-07-11 18:55:11
]]
function GameLuckySpinV2:readReelConfigData()
    self.m_ScatterShowCol = self.m_configData.p_scatterShowCol --标识哪一列会出现scatter
    self.m_validLineSymNum = self.m_configData.p_validLineSymNum --触发sf，bonus需要的数量
    self:setReelEffect(self.m_configData.p_reelEffectRes)
    --配置快滚效果资源名称
    self.m_changeLineFrameTime = self.m_configData.p_changeLineFrameTime --连线框播放时间
end

---
-- 读取配置文件数据
--
function GameLuckySpinV2:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function GameLuckySpinV2:getMachineConfigName()
    return "GameModule/LuckySpin/config/LuckySpinV2Config.csv"
end

function GameLuckySpinV2:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- print("创建 SlotNode")
        local node = LuckySpinSlotNode:create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载

        node.p_levelPushAnimNodeCallFun = self.m_levelPushAnimNodeCallFun
        node.p_levelGetAnimNodeCallFun = self.m_levelGetAnimNodeCallFun

        reelNode = node
    else
        -- print("从池子里面拿 SlotNode")

        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end

    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    -- print("hhhhh~ "..ccbName)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)

    return reelNode
end

function GameLuckySpinV2:initMachine()
    self.m_moduleName = self:getModuleName()
    self.m_machineModuleName = self.m_moduleName

    local fileName = "LuckySpinNew/GameLuckySpin.csb"
    if globalData.luckySpinSaleData:isExist() == true then
        -- fileName = "LuckySpinNew/GameLuckySpinSale.csb"
        fileName = "LuckySpinNew/GameFireLuckySpinUpgrade.csb"
    end
    self:createCsbNode(fileName)
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
    self:updateBaseConfig()
    self:updateMachineData()
    self:initMachineData()

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

    -- if display.height < 1370 then
    --     self:findChild("root"):setScale((display.height - self.m_uiHeight) / (1370 - self.m_uiHeight))
    -- else
    --     local posY = (display.height - 1370) * 0.5
    --     self:findChild("reel"):setPositionY(self:findChild("reel"):getPositionY() - posY)
    --     self:findChild("title"):setPositionY(self:findChild("title"):getPositionY() - posY)
    --     self:findChild("paytable"):setPositionY(self:findChild("paytable"):getPositionY() + posY * 0.5)
    -- end
    -- self:findChild("root"):setPositionY(self:findChild("root"):getPositionY() + 100)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function GameLuckySpinV2:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "LuckySpinV2"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function GameLuckySpinV2:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SPECAIL_EMPTY then
        return "LuckySpinNew/Socre_LuckySpin_empty"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        return "LuckySpinNew/Socre_LuckySpin_1"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
        return "LuckySpinNew/Socre_LuckySpin_2"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
        return "LuckySpinNew/Socre_LuckySpin_3"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
        return "LuckySpinNew/Socre_LuckySpin_4"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 then
        return "LuckySpinNew/Socre_LuckySpin_5"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_3 then
        return "LuckySpinNew/Socre_LuckySpin_6"
    end

    return nil
end

function GameLuckySpinV2:checkGameRunPause()
    return false
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function GameLuckySpinV2:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SPECAIL_EMPTY, count = 2}

    return loadNode
end

function GameLuckySpinV2:slotReelDown()
    BaseSlotoManiaMachine.slotReelDown(self)
    if self.m_spinSoundId ~= nil then
        gLobalSoundManager:stopAudio(self.m_spinSoundId)
        self.m_spinSoundId = nil
    end
end

--绘制多个裁切区域
function GameLuckySpinV2:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()
    self.m_slotParents = {}
    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    self:checkOnceClipNode()
    for i = 1, iColNum, 1 do
        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local diffW = 0
        if prePosX == -1 then
            slotW = slotW + reelSize.width
        else
            diffW = (posX - prePosX - reelSize.width)
            slotW = slotW + reelSize.width + diffW
        end
        prePosX = posX

        slotH = lMax(slotH, reelSize.height)
        local high = reelSize.height / 4
        reelSize.height = reelSize.height + high

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local clipNode
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNode.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        else
            clipNode =
                cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create() -- cc.LayerColor:create(cc.c4f(r,g,b,200))  --

        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY - high * 0.5)
        clipNode:setTag(CLIP_NODE_TAG + i)

        -- slotParentNode:setVisible(false)

        local parentData = SlotParentData:new()

        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)
    end
end

---
-- 获取最高的那一列
--
function GameLuckySpinV2:updateReelInfoWithMaxColumn()
    local fReelMaxHeight = 0

    local iColNum = self.m_iReelColumnNum
    --    local maxHeightColumnIndex = iColNum
    for iCol = 1, iColNum, 1 do
        -- local colNodeName = "reel_unit"..(iCol - 1)
        local reelNode = self:findChild("sp_reel_" .. (iCol - 1))

        local reelSize = reelNode:getContentSize()
        local unitPos = cc.p(reelNode:getPositionX(), reelNode:getPositionY())
        unitPos = reelNode:getParent():convertToWorldSpace(unitPos)

        local pos = self.m_slotEffectLayer:convertToNodeSpace(unitPos)

        self.m_reelColDatas[iCol].p_slotColumnPosX = pos.x
        self.m_reelColDatas[iCol].p_slotColumnPosY = pos.y
        self.m_reelColDatas[iCol].p_slotColumnWidth = reelSize.width
        self.m_reelColDatas[iCol].p_slotColumnHeight = reelSize.height

        if reelSize.height > fReelMaxHeight then
            fReelMaxHeight = reelSize.height
            self.m_fReelWidth = reelSize.width
        end
    end

    self.m_fReelHeigth = fReelMaxHeight
    self.m_SlotNodeW = self.m_fReelWidth
    self.m_SlotNodeH = self.m_fReelHeigth / 4

    for iCol = 1, iColNum, 1 do
        -- self.m_reelColDatas[iCol].p_slotColumnPosY = self.m_reelColDatas[iCol].p_slotColumnPosY - 0.5 * self.m_SlotNodeH
        self.m_reelColDatas[iCol].p_slotColumnHeight = self.m_reelColDatas[iCol].p_slotColumnHeight + self.m_SlotNodeH
    end

    -- 计算每列的行数
    local isSpecialReel = false
    for i = 1, #self.m_reelColDatas do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridH = self.m_SlotNodeH
        columnData.p_showGridCount = self.m_iReelRowNum -- 对对应列进行四舍五入
        if columnData.p_showGridCount ~= self.m_iReelRowNum then
            isSpecialReel = true
        end
    end
    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end
end

function GameLuckySpinV2:checkRestSlotNodePos()
    -- 还原reel parent 信息
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local posx, posy = slotParent:getPosition()
        slotParent:setPosition(0, 0) -- 还原位置信息

        local childs = slotParent:getChildren()
        --        printInfo("xcyy  剩余 child count %d", #childs)

        local lastType = nil
        local preRow = 0
        local maxLastNodePosY = nil
        local minLastNodePosY = nil

        local moveDis = nil
        for nodeIndex = 1, #childs do
            local childNode = childs[nodeIndex]
            if childNode.m_isLastSymbol == true then
                local childPosY = childNode:getPositionY()
                if maxLastNodePosY == nil then
                    maxLastNodePosY = childPosY
                elseif maxLastNodePosY < childPosY then
                    maxLastNodePosY = childPosY
                end

                if minLastNodePosY == nil then
                    minLastNodePosY = childPosY
                elseif minLastNodePosY > childPosY then
                    minLastNodePosY = childPosY
                end
                local columnData = self.m_reelColDatas[childNode.p_cloumnIndex]
                local nodeH = columnData.p_showGridH

                childNode:setPositionY((nodeH * childNode.p_rowIndex - nodeH * 0.5))

                if moveDis == nil then
                    moveDis = childPosY - childNode:getPositionY()
                end
            else
                --do nothing
            end

            childNode.m_isLastSymbol = false
        end

        -- printInfo(" xcyy %d  %d  ", parentData.cloumnIndex,parentData.symbolType)
        parentData:reset()
    end
end

function GameLuckySpinV2:getSpinCostCoins()
    return toLongNumber(1)
end

function GameLuckySpinV2:spinResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        local spdata = globalData.luckySpinV2:getCurrentRecod()

        self.m_runSpinResultData:parseReelData(spdata)
        self.m_result = {}
        self.m_result.signal = spdata.p_signal
        self.m_result.coins = spdata.p_coins
        self.m_result.multiple = spdata.p_multiple
        self.m_result.offset = spinData.offset
        self.m_result.vipPoint = spinData.vipPoint
        self.m_result.clubPoint = spinData.clubPoint

        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        self.m_runSpinResultData.p_freeSpinsTotalCount = 0
        self.m_runSpinResultData.p_freeSpinsLeftCount = 0

        self:updateNetWorkData()
    else
        local errorCode = param[2]
        gLobalViewManager:showReConnect(true)
    end
end

function GameLuckySpinV2:callSpinBtn()
    print("callSpinBtn  点击了spin")
    local time = xcyy.SlotsUtil:getMilliSeconds()

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    release_print(" callSpinBtn1 消耗时间 " .. (time1 - time))

    print("callSpinBtn  点击了spin15")
    local time2 = xcyy.SlotsUtil:getMilliSeconds()
    release_print(" callSpinBtn2 消耗时间 " .. (time2 - time1))

    local time3 = xcyy.SlotsUtil:getMilliSeconds()
    release_print(" callSpinBtn3 消耗时间 " .. (time3 - time2))

    local time4 = xcyy.SlotsUtil:getMilliSeconds()
    release_print(" 产生本地 json 消耗时间 " .. (time4 - time3))
    self:spinBtnEnProc()

    self:setGameSpinStage(GAME_MODE_ONE_RUN)

    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

    local time5 = xcyy.SlotsUtil:getMilliSeconds()
    release_print(" 产生本地 json 消耗时间 " .. (time5 - time4))
end

function GameLuckySpinV2:requestSpinReusltData()
    local time = xcyy.SlotsUtil:getMilliSeconds()
    self:requestSpinResult()

    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

function GameLuckySpinV2:requestSpinResult()
    local totalCoin = globalData.userRunData.coinNum
    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg = MessageDataType.MSG_LUCKY_SPINV2}
    if self.m_bEnjoySlot then
        messageData.msg = MessageDataType.MSG_LUCKY_SPIN_ENJOY
    end
    -- local operaId =
    httpSendMgr:sendActionData_LuckySpin(0, totalCoin, 0, false, moduleName, false, 0, 0, messageData, false)
end

function GameLuckySpinV2:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    self:produceSlots()

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end

function GameLuckySpinV2:operaNetWorkData()
    local lastNodeIsBigSymbol = false
    local maxDiff = 0
    for i = 1, #self.m_slotParents do
        local columnData = self.m_reelColDatas[i]
        local halfH = columnData.p_showGridH * 0.5

        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent

        local moveL = self.m_reelRunInfo[i]:getReelRunLen() * columnData.p_showGridH
        -- print(i .. "列，不考虑补偿计算的移动距离 " ..  moveL)
        local childs = slotParent:getChildren()
        local preY = 0
        local isLastBigSymbol = false

        -- printInfo(" updateNetWork %d ,, col=%d " , #childs , i)

        for childIndex = 1, #childs do
            local child = childs[childIndex]
            local isVisible = child:isVisible()
            local childY = child:getPositionY()
            local topY = nil
            local nodeH = child.p_slotNodeH or 144
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
                isLastBigSymbol = true
            else
                topY = childY + nodeH * 0.5
                isLastBigSymbol = false
            end

            if topY < preY and isLastBigSymbol == false then
                isLastBigSymbol = false
            end

            preY = util_max(preY, topY)
        end
        if isLastBigSymbol == true then
            lastNodeIsBigSymbol = true
        end
        local parentY = slotParent:getPositionY()
        -- 按照逻辑处理来说， 各列的moveDiff非长条模式是相同的，长条模式需要将剩余的补齐
        local moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth
        if #childs == 0 then -- 表明这一列并未参与滚动， 先这么写吧后续考虑修改
            moveDiff = 0
        end
        moveL = moveL + moveDiff

        parentData.moveDistance = parentY - moveL
        parentData.moveL = moveL
        parentData.moveDiff = moveDiff
        parentData.preY = preY

        maxDiff = util_max(maxDiff, math.abs(moveDiff))

        -- self:createSlotNextNode(parentData)
    end

    -- 检测假数据滚动时最后一个格子是否为 bigSymbol，
    -- 如果是那么其他列补齐到与最大bigsymbol同样的高度
    if lastNodeIsBigSymbol == true then
        for i = 1, #self.m_slotParents do
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent

            local columnData = self.m_reelColDatas[i]
            local halfH = columnData.p_showGridH * 0.5

            if #slotParent:getChildren() == 0 then -- 表明这一列并未参与滚动， 先这么写吧后续考虑修改
                parentData.moveDiff = maxDiff
            end

            local parentY = slotParent:getPositionY()
            local moveL = self.m_reelRunInfo[i]:getReelRunLen() * columnData.p_showGridH

            moveL = moveL + maxDiff

            -- 补齐到长条高度
            local diffDis = maxDiff - math.abs(parentData.moveDiff)

            if diffDis > 0 then
                local nodeCount = math.floor(diffDis / columnData.p_showGridH)

                for addIndex = 1, nodeCount do
                    if self:getNormalSymbol(parentData.cloumnIndex) == nil then
                        local a = 1
                    end
                    local symbolType = self:getNormalSymbol(parentData.cloumnIndex)
                    local node = self:getSlotNodeWithPosAndType(symbolType, 1, 1, false)
                    node.p_slotNodeH = columnData.p_showGridH
                    local posY = parentData.preY + (addIndex - 1) * columnData.p_showGridH + columnData.p_showGridH * 0.5
                    node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                    node:setPositionY(posY)

                    slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                end
            end

            parentData.moveDistance = parentY - moveL

            parentData.moveL = moveL
            parentData.moveDiff = nil
            self:createSlotNextNode(parentData)
        end
    else
        for i = 1, #self.m_slotParents do
            local parentData = self.m_slotParents[i]
            self:createSlotNextNode(parentData)
        end
    end

    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

function GameLuckySpinV2:getCurrSpinMode()
    return NORMAL_SPIN_MODE
end

function GameLuckySpinV2:setCurrSpinMode(spinMode)
end

function GameLuckySpinV2:setGameSpinStage(spinStage)
    self.m_gameSpinStage = spinStage
end
function GameLuckySpinV2:getGameSpinStage()
    return self.m_gameSpinStage
end

function GameLuckySpinV2:MachineRule_checkTriggerFeatures()
end

function GameLuckySpinV2:callSpinTakeOffBetCoin(betCoin)
end

function GameLuckySpinV2:addLastWinSomeEffect()
end

function GameLuckySpinV2:randomSlotNodesByReel()
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)
        while reelData.p_reelResultSymbols[1] == self.SYMBOL_SPECAIL_EMPTY do
            reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)
        end

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex = 1, resultLen do
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = reelColData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

            parentData.slotParent:addChild(node, node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
        end
    end
end

function GameLuckySpinV2:enterLevel()
    self:randomSlotNodesByReel()
end

function GameLuckySpinV2:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function GameLuckySpinV2:clickSpin()
    -- self:runCsbAction(
    --     "actionframe",
    --     false,
    --     function()
    --         self:runCsbAction("ildeframe", true)
    --     end
    -- )
    self:runCsbAction("ildeframe", true)
    for i=1,6 do
        local a = self:findChild("ZJ_"..i)
        a:removeAllChildren()
    end
    local other = self:findChild("ZJ_other")
    other:removeAllChildren()
    self:normalSpinBtnCall()
    gLobalSoundManager:playSound("LuckySpin2Sound/sound_LuckySpin_click_spin.mp3", false)
    performWithDelay(
        self,
        function()
            self.m_spinSoundId = gLobalSoundManager:playSound("LuckySpin2Sound/sound_LuckySpin_slot_run.mp3", true)
        end,
        1
    )
end

function GameLuckySpinV2:addObservers()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:spinResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_LUCKY_SPINRESULT
    )
end

function GameLuckySpinV2:symbolNodeAnimation(animation)
    for reelCol = 1, self.m_iReelColumnNum, 1 do
        local parent = self:getReelParent(reelCol)
        local children = parent:getChildren()
        for i = 1, #children, 1 do
            local child = children[i]
            child:runAnim(animation)
        end
        -- local symbolNode =  self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, 1, SYMBOL_NODE_TAG))
    end
end

function GameLuckySpinV2:onExit()
    BaseMachineGameEffect.onExit(self) -- 必须调用不予许删除
    self:clearSlotoData()
    self:removeObservers()

    self:clearFrameNodes()
    self:clearSlotNodes()

    for i, v in pairs(self.m_reelRunAnima) do
        local reelNode = v[1]
        local reelAct = v[2]
        if reelNode:getParent() ~= nil then
            reelNode:removeFromParent()
        end

        reelNode:release()
        reelAct:release()

        self.m_reelRunAnima[i] = v
    end

    if self.m_reelScheduleDelegate ~= nil then
        self.m_reelScheduleDelegate:unscheduleUpdate()
    end

    if self.m_respinNodeInfo ~= nil and #self.m_respinNodeInfo > 0 then
        for k = 1, #self.m_respinNodeInfo do
            local node = self.m_respinNodeInfo[k].node
            if not tolua.isnull(node) then
                node:removeFromParent()
            end
        end
    end
    self.m_respinNodeInfo = {}

    self:removeSoundHandler()

    --离开，清空
    gLobalActivityManager:clear()

    scheduler.unschedulesByTargetName("BaseSlotoManiaMachine")
    scheduler.unschedulesByTargetName(self:getModuleName())
end

function GameLuckySpinV2:clearSlotoData()
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

function GameLuckySpinV2:playEffectNotifyNextSpinCall()
    globalMachineController:playBgmAndResume("LuckySpin2Sound/sound_LuckySpin_win.mp3", 4, 0.4, 1)

    for i = 1, self.m_iReelColumnNum, 1 do
        local node = self:getReelParentChildNode(i, 3)
        -- node:setScale(1.2)
        node:runAnim("actionframe", true)
    end
    if self.m_result.signal == "jackpot" then
        self:runCsbAction("ildeframe2", true)
    elseif self.m_result.signal ~= "same" then
        local effect, act = util_csbCreate("LuckySpin2/Socre_LuckySpin_zhongjiangkuang.csb")
        util_csbPlayForKey(act, "animation0", true)
        local node = self:findChild("ZJ_" .. self.m_result.signal)
        node:addChild(effect)
    else
        self:runCsbAction("actionframe2", true)
    end

    performWithDelay(
        self,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_SPIN_OVER, self.m_result)
        end,
        1
    )
end

function GameLuckySpinV2:getReelSymbolType(parentData)
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]

    local addCount = 1
    parentData.beginReelIndex = parentData.beginReelIndex + addCount
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
    end

    return symbolType
end

function GameLuckySpinV2:playEffectNotifyChangeSpinStatus()
end

function GameLuckySpinV2:showLineFrameByIndex(winLines, frameIndex)
end

function GameLuckySpinV2:reelDownNotifyChangeSpinStatus()
end

function GameLuckySpinV2:enterGamePlayMusic()
end

-- 是否是 先享后付
function GameLuckySpinV2:setIsEnjoyType(_value)
    self.m_bEnjoySlot = _value
end

return GameLuckySpinV2
