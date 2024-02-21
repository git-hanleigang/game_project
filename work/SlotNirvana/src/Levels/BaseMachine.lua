---
--island
--2017年8月25日
--BaseMachine.lua
--
-- 这里实现老虎机的所有UI表现相关联的，而各个关卡更多的关心这里的内容

GD.SLOT_LAYER_ZOEDER_FLAG = {
    SLOT_CLIP_NODE = 100,
    SLOT_NODE = 55000, -- 代表悬浮格子
    SLOT_CLIP_SPECIAL_NODE = 65001, -- 单列滚动结束时， 需要突出到外层播放动画的图层， 用于 scatter bonus 等突出播放动画显示
    SLOT_FRAME = 70000, --连线框
    SLOT_LINE = 85900, -- 绘制线工具层
    SLOT_LINE_NODE = 96000, -- 显示连线时突出显示的图层，用于放置参与连线的小块
    SLOT_EFFECT_LAYER = 100000 -- 最上层的特效层
}

GD.GAME_LAYER_ORDER = {
    LAYER_ORDER_BG = 10,
    LAYER_ORDER_GAME_MAIN_LAYER = 20,
    LAYER_ORDER_TOURNAMENT = 30,
    LAYER_ORDER_TOP = 35,
    LAYER_ORDER_BOTTOM = 45,
    LAYER_ORDER_TOUCH_LAYER = 50,
    LAYER_ORDER_SPIN_BTN = 52,
    LAYER_ORDER_SEPCIAL_LAYER = 55,
    LAYER_ORDER_EFFECT = 70,
    LAYER_ORDER_UI = 80 -- ui显示层
}

GD.SYMBOL_FIX_NODE_TAG = 1000
GD.SYMBOL_NODE_TAG = 100000
GD.SYMBOL_NODE_COVER_TAG = 100
GD.BIG_SYMBOL_NODE_DIFF_TAG = -50 -- -50表明支持的最大多少行，用这个来获取当bigSymbol 起始rowIndex 为负数时的处理

GD.NONE_BIG_SYMBOL_FLAG = -100 -- 随机组或者最终结果组中标记startRowIndex ， 用来表示此列中是否创建长条 ， -100表示不创建
GD.CLIP_NODE_TAG = 3000

local ActivitySignManager = require "Levels.ActivitySignManager"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local ReelLineInfo = require "data.levelcsv.ReelLineInfo"
local SlotsReelData = require "data.slotsdata.SlotsReelData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"
local GameEffectData = require "data.slotsdata.GameEffectData"
local ReSpinNode = require "Levels.RespinNode"

local SlotsReelRunData = require "data.slotsdata.SlotsReelRunData"
local SlotParentData = require "data.slotsdata.SlotParentData"

local BaseMachine = class("BaseMachine", BaseMachineGameEffect)

BaseMachine.m_machineModuleName = nil --

BaseMachine.m_bProduceSlots_InFreeSpin = nil --用于判断轮盘数据生成是否在fs下

BaseMachine.m_vecSymbolEffectType = nil --

BaseMachine.m_hasBigSymbol = nil -- 是否有大信号
BaseMachine.m_reelSlotDataPool = nil -- reel slot 数据缓存

BaseMachine.m_ScatterShowCol = nil --- scatter限制列

--BaseMachine.m_reelCloumGroupNums = nil -- 滚动时随机生成假数据 列信息， 例如{2,3,4,5,6}  , 第一列生成 2 * m_iReelRowNum 第二列生成 3 * m_iReelRowNum。。。

BaseMachine.m_reelNodePool = nil -- 滚动节点的内存池， 在退出时释放掉, 在launch 期间进行加载，具体数量根据情况决定
BaseMachine.m_reelAnimNodePool = nil -- 滚动动画节点 内存池， 退出时释放

BaseMachine.m_iOnceSpinLastWin = nil -- 一次转动最后 线赢的钱

BaseMachine.m_fLastWinBetNumRatio = nil --
BaseMachine.m_llBigOrMegaNum = nil --
BaseMachine.m_expMultiNum = nil
BaseMachine.m_bIsBigWin = nil --

BaseMachine.m_clipWidtRatio = nil

BaseMachine.m_reelResultLines = nil -- 运算结果的列表，从最终计算的m_vecGetLineInfo 复制而来

BaseMachine.m_winFrameCCB = nil -- frame框的 ccb文件

BaseMachine.m_handerIdAutoSpin = nil -- 定时auto spin 的句柄
BaseMachine.m_isChangeBGMusic = nil -- 是否切换了背景音乐

BaseMachine.m_reelDelayTime = nil -- 每列滚动间隔时间 ， 单位为秒第一列不需要等待时间。
BaseMachine.m_reelRunInfo = nil -- 长滚信息
BaseMachine.m_reelRunAnima = nil
BaseMachine.m_reelRunAnimaBG = nil
BaseMachine.m_reelRunSoundTag = nil

BaseMachine.m_bCreateResNode = nil --是否每列多创建一个信号(上方的回弹信号)
--关卡内音乐音效名字
BaseMachine.m_bgMusicName = nil --背景音效名字
BaseMachine.m_fsBgMusicName = nil --fs下背景音乐名字
BaseMachine.m_currentMusicBgName = nil -- 当前背景音乐， 在freespin normal 下处理
BaseMachine.m_currentMusicId = nil -- 当前播放的背景音乐id

BaseMachine.m_reelRunSound = nil --快滚音效名称
BaseMachine.m_reelDownSound = nil --滚动条下落音效
BaseMachine.m_quickStopReelDownSound = nil --滚动条快停下落音效
BaseMachine.m_reelDownSoundArray = {} -- 作为存储当前列播放轮盘停止状态
BaseMachine.m_reelDownSoundPlayed = 1
BaseMachine.m_reelDownSoundNoPlay = 0
BaseMachine.m_symbolBulingSoundArray = {} -- 作为存储当前列播放buling音效播放状态
BaseMachine.m_symbolQsBulingSoundArray = {} -- 作为快停时存储当前列播放buling音效播放状态
BaseMachine.m_reelEffectName = nil --滚动条ccb名称
BaseMachine.m_reelBgEffectName = nil --快点背景效果名称
BaseMachine.m_defaultEffectName = nil -- 默认effect 名字

BaseMachine.m_longRunAddZorder = nil --滚动条下落添加的层级

BaseMachine.m_reelDownAddTime = nil

BaseMachine.m_preLoadSoundName = nil

BaseMachine.m_isFeatureOverBigWinInFree = false     --free中特殊玩法结束是否检测播大赢

BaseMachine.m_isWaitingNetworkData = nil -- 是否等待网络数据
-- BaseMachine.m_spinResultCoin = nil -- 本轮spin 消耗的金币
BaseMachine.m_spinNextLevel = nil -- 本轮spin 后等级
BaseMachine.m_spinNextProVal = nil -- 本轮spin 后经验
BaseMachine.m_spinIsUpgrade = nil -- 本轮spin后是否升级
BaseMachine.m_serverWinCoins = nil -- 服务器计算得到的赢钱， 代表本次spin 结果  respin 、 bonus 放到其他地方
BaseMachine.m_freeSpinStartCoins = nil --freespin 触发或者断线重连时的钱
BaseMachine.m_freeSpinOffSetCoins = nil --freespin 断线重连差值
BaseMachine.m_isPadScale = nil --已宽适配
BaseMachine.m_preReSpinStoredIcons = nil -- 只用作respin 里面
BaseMachine.m_bingoBallBeginPos = nil

BaseMachine.m_bClickQuickStop = nil
BaseMachine.m_iBackDownColID = nil

BaseMachine.m_spinBeforeLevel = nil -- 本轮spin 前的等级
BaseMachine.m_spinBeforeProVal = nil -- 本轮spin 前的经验
BaseMachine.m_spinBeforeTotalProVal = nil -- 本轮spin 前的总经验

BaseMachine.m_isAddBigWinLightEffect = false  --是否需要添加大赢光效

local m_Symbol1CCBName = nil --   这里面的名字如果需要修改， 继承这些属性 重新赋值就ok了 2017-08-31 19:05:57
local m_Symbol2CCBName = nil --
local m_Symbol3CCBName = nil --
local m_Symbol4CCBName = nil --
local m_Symbol5CCBName = nil --
local m_Symbol6CCBName = nil --
local m_Symbol7CCBName = nil --
local m_Symbol8CCBName = nil --
local m_Symbol9CCBName = nil --
local m_SymbolScatterCCBName = nil --
local m_SymbolBonusCCBName = nil --
local m_SymbolWildCCBName = nil --
local m_SymbolSpecialCCBName = nil --

BaseMachine.m_maxHeightColumnIndex = nil -- 最高哪一列的 column Index
BaseMachine.m_runHeightColumnIndex = nil -- 每次滚动都要修改此值
BaseMachine.m_isSpecialReel = nil -- 是否为异形轮盘， 例如 4 * 5 * 6 * 5 * 4 就是不规则轮盘

BaseMachine.m_reelScheduleDelegate = nil -- 逐帧滚动id

BaseMachine.m_machineNode = nil -- 轮盘节点
-- BaseMachine.MACHINE_NODE_SACLE = nil -- 轮盘默认缩放比例

BaseMachine.m_topUI = nil
BaseMachine.m_bottomUI = nil
BaseMachine.m_gameBg = nil

BaseMachine.m_lineSlotNodes = nil -- 所有参与连线的slotsNode
BaseMachine.m_machineRootScale = nil

BaseMachine.m_writeRespinData = false

BaseMachine.m_totleFsCount = 0
BaseMachine.m_fsTotalWin = 0
BaseMachine.m_totalWin = 0

BaseMachine.m_reSpinsTotalCount = 0
BaseMachine.m_reSpinCurCount = 0
BaseMachine.m_resultJsonData = 0

BaseMachine.m_fsReelDataIndex = 0 --fs玩法选择假数据
BaseMachine.m_resetFreespinTimes = nil --重置fs次数 用于fs次数选择玩法
BaseMachine.m_isAllLineType = nil --是否是全线类型

BaseMachine.m_specialSpinStates = false -- 选择玩法在滚一次

--背景是否循环播放
BaseMachine.m_isMachineBGPlayLoop = false

BaseMachine.m_BigWinLimitRate = nil -- 大赢倍数
BaseMachine.m_MegaWinLimitRate = nil -- 大赢倍数
BaseMachine.m_HugeWinLimitRate = nil -- 大赢倍数
BaseMachine.m_LegendaryWinLimitRate = nil -- 大赢倍数

BaseMachine.m_onceClipNode = nil --绘制一个裁切区域时使用
BaseMachine.m_isOnceClipNode = true --是否只绘制一个矩形裁切 --小矮仙 袋鼠等不规则或者可变高度设置成false

BaseMachine.m_soundHandlerId = nil -- 声音音量控制延时id
BaseMachine.m_soundGlobalId = nil -- 声音音量控制定时id
BaseMachine.m_bgmReelsDownDelayTime = 10

BaseMachine.m_quickStopBackDistance = 35
BaseMachine.m_videoPokeMgr = nil -- videoPoker
-- 构造函数
function BaseMachine:ctor()
    print("BaseMachine:ctor")
    BaseMachineGameEffect.ctor(self)
    self.m_videoPokeMgr = nil

    self.m_pauseRef = 0

    self.m_specialSpinStates = false
    self.m_bgmReelsDownDelayTime = 10

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

    self.m_BigWinLimitRate = globalData.slotRunData.machineData:getBigWinRate()
    self.m_MegaWinLimitRate = globalData.slotRunData.machineData:getMegaWinRate()
    self.m_HugeWinLimitRate = globalData.slotRunData.machineData:getHugeWinRate()
    self.m_LegendaryWinLimitRate = globalData.slotRunData.machineData:getLegendaryRate()

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

    globalData.slotRunData.freeSpinCount = 0
    globalData.slotRunData.totalFreeSpinCount = 0

    globalData.slotRunData.isClickQucikStop = false
    --重置bet倍率
    globalData.slotRunData:setCurBetMultiply(1)

    self:setLastWinCoin(0)
    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    self:setGameSpinStage(IDLE)

    globalData.slotRunData.gameRunPause = nil
    globalData.slotRunData.gameResumeFunc = nil

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

    globalData.slotRunData.severGameJsonData = nil

    self.m_isSpecialReel = false

    self.m_soundHandlerId = nil
    self.m_soundGlobalId = nil

    self.m_BetChooseGear = 0 -- 高低bet line 初始化

    if DEBUG == 2 and gLobalDebugReelTimeManager.m_Machine == nil then
        gLobalDebugReelTimeManager.m_Machine = self
    end

    self.m_spinBeforeLevel = globalData.userRunData.levelNum
    self.m_spinBeforeTotalProVal = globalData.userRunData:getPassLevelNeedExperienceVal()
    self.m_spinBeforeProVal = globalData.userRunData.currLevelExper

    --限时活动收集角标开关
    self.m_isActLimitSignClose = false

    if self:checkControlerReelType() then
        self.m_signManager = ActivitySignManager.new({machine = self})
    end
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
function BaseMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        if i >= 3 then
            soundPath = "Sounds/bonus_scatter_3.mp3"
        else
            soundPath = "Sounds/bonus_scatter_" .. i .. ".mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

--[[
    @desc: 设置 game json data
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
--[[
    @desc: 设置赢钱数量
    time:2018-12-19 22:59:30
    --@winCoin:
    @return:
]]
function BaseMachine:setLastWinCoin(winCoin)
    globalData.slotRunData.lastWinCoin = winCoin
end
function BaseMachine:getLastWinCoin()
    return globalData.slotRunData.lastWinCoin
end

---
-- 返回各个level 的模块名字
function BaseMachine:getModuleName()
    return nil
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function BaseMachine:getNetWorkModuleName()
    return self:getModuleName()
end

--- 获取ccbname 根据symbol type
function BaseMachine:getSymbolCCBNameByType(MainClass, symbolType)
    local ccbName = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 then
        ccbName = m_Symbol1CCBName
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_2 then
        ccbName = m_Symbol2CCBName
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_3 then
        ccbName = m_Symbol3CCBName
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 then
        ccbName = m_Symbol4CCBName
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
        ccbName = m_Symbol5CCBName
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
        ccbName = m_Symbol6CCBName
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
        ccbName = m_Symbol7CCBName
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        ccbName = m_Symbol8CCBName
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        ccbName = m_Symbol9CCBName
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        ccbName = m_SymbolScatterCCBName
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        ccbName = m_SymbolBonusCCBName
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        ccbName = m_SymbolWildCCBName
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE then
    --无效类型
    end
    local selfCcbName = MainClass:MachineRule_GetSelfCCBName(symbolType)
    if selfCcbName ~= nil then
        ccbName = selfCcbName
    end
    -- print("getSymbolCCBNameByType="..symbolType)
    if not ccbName then
        print("getSymbolCCBNameByccbName=error")
    else
        -- print("getSymbolCCBNameByccbName="..ccbName)
    end
    return ccbName
end

--自定义ccb类型
--各自关卡中根据信号类型的多少实现
function BaseMachine:MachineRule_GetSelfCCBName(symbolType)
    return nil
end

--关卡临时使用的小块效果
function BaseMachine:createSymbolAniNode(_symbolType)
    local ccbName = self:getSymbolCCBNameByType(self, _symbolType)
    local spineSymbolData = self.m_configData:getSpineSymbol(_symbolType)
    local bSpine = nil ~= spineSymbolData
    local animSymbol = util_createView("Levels.SymbolAniNode")
	animSymbol:changeSymbolCcb(_symbolType, ccbName, bSpine)
    return animSymbol
end

---
-- 根据类型获取对应节点
--
function BaseMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- print("创建 SlotNode")
        local node = require(self:getBaseReelGridNode()):create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        reelNode = node
    else
        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end

function BaseMachine:perLoadSLotNodes()
    for i = 1, 10 do
        local node = require(self:getBaseReelGridNode()):create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载

        self.m_reelNodePool[#self.m_reelNodePool + 1] = node
    end
end

--小块
function BaseMachine:getBaseReelGridNode()
    return "Levels.SlotsNode"
end

--[[
    @desc: 根据symbolType
    time:2019-03-20 15:12:12
    --@symbolType:
	--@row:
    --@col:
    --@isLastSymbol:
    @return:
]]
function BaseMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol)
    if isLastSymbol == nil then
        isLastSymbol = false
    end
    local symblNode = self:getSlotNodeBySymbolType(symbolType)
    symblNode.p_cloumnIndex = col
    symblNode.p_rowIndex = row
    symblNode.m_isLastSymbol = isLastSymbol

    self:updateReelGridNode(symblNode)
    self:checkAddSignOnSymbol(symblNode)
    return symblNode
end
--新滚动使用
function BaseMachine:updateReelGridNode(symblNode)
end
---
-- 根据类型将节点放回到pool里面去
-- @param node 需要放回去的node ，在放回去时该清理的要清理完毕， 以免出现node 已经添加到了parent ，但是去除来后再addChild进去
--
function BaseMachine:pushSlotNodeToPoolBySymobolType(symbolType, node)
    if self.m_videoPokeMgr then
        -- videoPoker收集移除角标
        self.m_videoPokeMgr:removeVideoPokerIcon(node)
    end

    self.m_reelNodePool[#self.m_reelNodePool + 1] = node
    node:reset()
    node:stopAllActions()
end

---
-- 预创建内存池中的节点， 在LaunchLayer 里面，
--
function BaseMachine:preLoadSlotsNodeBySymbolType(symbolType, count)
    --    if (symbolType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 and symbolType <= TAG_SYMBOL_TYPE.SYMBOL_WILD) == false then
    --    	return
    --    end

    for i = 1, count, 1 do
        local ccbName = self:getSymbolCCBNameByType(self, symbolType)
        if ccbName == nil or ccbName == "" then
            return
        end
        local fullName = cc.FileUtils:getInstance():fullPathForFilename(ccbName .. ".csb")
        local hasSymbolCCB = cc.FileUtils:getInstance():isFileExist(fullName)
        if hasSymbolCCB == true then
            local node = SlotsAnimNode:create()
            node:loadCCBNode(ccbName, symbolType)
            node:retain()

            self:pushAnimNodeToPool(node, symbolType)
        else
            return
        end
    end
end

--加载关卡需要的list
function BaseMachine:perLoadLevelList()
    local levelList = {}
    --bigwin
    levelList[#levelList + 1] = {"CommonWin/BigWinUI.png", "CommonWin/BigWinUI.plist"}
    levelList[#levelList + 1] = {"CommonWin/ui/texiao/Bigwin_TX_01.png", "CommonWin/ui/texiao/Bigwin_TX_01.plist"}
    levelList[#levelList + 1] = {"CommonWin/ui/texiao/BigWin_Effect1.png", "CommonWin/ui/texiao/BigWin_Effect1.plist"}
    levelList[#levelList + 1] = {"CommonWin/ui/texiao/Bigwin_tx_lizi01.png", "CommonWin/ui/texiao/Bigwin_tx_lizi01.plist"}

    levelList[#levelList + 1] = {SOUND_ENUM.MUSIC_COMMON_BIGWIN_START1, SOUND_ENUM.MUSIC_COMMON_BIGWIN_START1}
    levelList[#levelList + 1] = {SOUND_ENUM.MUSIC_COMMON_BIGWIN_START2, SOUND_ENUM.MUSIC_COMMON_BIGWIN_START2}
    levelList[#levelList + 1] = {SOUND_ENUM.MUSIC_COMMON_BIGWIN_START3, SOUND_ENUM.MUSIC_COMMON_BIGWIN_START3}
    levelList[#levelList + 1] = {SOUND_ENUM.MUSIC_COMMON_BIGWIN_OVER1, SOUND_ENUM.MUSIC_COMMON_BIGWIN_OVER1}
    levelList[#levelList + 1] = {SOUND_ENUM.MUSIC_COMMON_BIGWIN_OVER2, SOUND_ENUM.MUSIC_COMMON_BIGWIN_OVER2}
    levelList[#levelList + 1] = {SOUND_ENUM.MUSIC_COMMON_BIGWIN_OVER3, SOUND_ENUM.MUSIC_COMMON_BIGWIN_OVER3}
    return levelList
end

--
function BaseMachine:pushAnimNodeToPool(animNode, symbolType)
    local reelPool = self.m_reelAnimNodePool[symbolType]
    if reelPool == nil then
        reelPool = {}

        self.m_reelAnimNodePool[symbolType] = reelPool
    end
    animNode:setScale(1)
    reelPool[#reelPool + 1] = animNode
end
function BaseMachine:getAnimNodeFromPool(symbolType, ccbName)
    if not symbolType then
        release_print(debug.traceback())
        release_print("sever传回的数据：  " .. (globalData.slotRunData.severGameJsonData or "isnil"))
        release_print(
            "error_userInfo_ udid=" ..
                (globalData.userRunData.userUdid or "isnil") .. " machineName=" .. (globalData.slotRunData.gameModuleName or "isLobby") .. " gameSeqID = " .. (globalData.seqId or "")
        )
        release_print("AnimNodeFromPool error not symbolType!!!    ccbName:" .. ccbName)
        return nil
    end
    if ccbName == nil then
        ccbName = self:getSymbolCCBNameByType(self, symbolType)
    end

    local reelPool = self.m_reelAnimNodePool[symbolType]
    if reelPool == nil then
        reelPool = {}
        self.m_reelAnimNodePool[symbolType] = reelPool
    end

    if #reelPool == 0 then
        -- 扩展支持 spine 的元素
        local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
        local node = nil
        if spineSymbolData ~= nil then
            node = SlotsSpineAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType, spineSymbolData[3])
            node:initSpineInfo(spineSymbolData[1], spineSymbolData[2])
            node:runDefaultAnim()
        else
            node = SlotsAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:runDefaultAnim()
        end

        return node
    else
        local node = reelPool[1] -- 存内存池取出来
        table.remove(reelPool, 1)
        node:runDefaultAnim()

        -- print("从尺子里面拿 SlotsAnimNode")

        return node
    end
end

---
-- 需要预加载SlotsNode 节点列表
function BaseMachine:getPreLoadSlotNodes()
    local loadNodes = {
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, count = 2},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, count = 2},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, count = 2},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, count = 2},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, count = 2},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, count = 2},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, count = 2},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, count = 2},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1, count = 2},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, count = 2},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS, count = 2},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD, count = 2}
    }

    return loadNodes
end
---
-- 清理掉 所有slot node 节点
function BaseMachine:clearSlotNodes()
    for nodeIndex = #self.m_reelNodePool, 1, -1 do
        local node = self.m_reelNodePool[nodeIndex]
        if not tolua.isnull(node) then
            node:clear()

            node:removeAllChildren() -- 必须加上这个，否则ccb的节点无法卸载，因为未加入到显示列表

            node:release()
        end
        self.m_reelNodePool[nodeIndex] = nil
    end
    self.m_reelNodePool = nil

    for key, v in pairs(self.m_reelAnimNodePool) do
        for nodeIndex = #v, 1, -1 do
            local node = v[nodeIndex]
            if not tolua.isnull(node) then
                node:clear()

                node:removeAllChildren() -- 必须加上这个，否则ccb的节点无法卸载，因为未加入到显示列表

                node:release()
            end
            v[nodeIndex] = nil
        end
        self.m_reelAnimNodePool[key] = nil
    end
    self.m_reelAnimNodePool = nil

    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent

        release_print("清理slotParent上的小块,列数:"..i)
        util_resetChildReferenceCount(slotParent)
        local slotParentBig = parentData.slotParentBig
        if slotParentBig then
            release_print("清理slotParentBig上的小块,列数:"..i)
            util_resetChildReferenceCount(slotParentBig)
        end
    end

    -- 清空掉所有遮罩提示的 SlotNode
    local nodeLen = #self.m_lineSlotNodes
    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        if not tolua.isnull(lineNode) then -- TODO 补丁
            if lineNode.clear ~= nil then
                lineNode:clear()
            end

            if lineNode:getReferenceCountEx() > 1 then
                lineNode:release()
            end

            if lineNode:getParent() ~= nil then
                lineNode:removeFromParent()
            end
        end
    end

    for i = #self.m_lineSlotNodes, 1, -1 do
        self.m_lineSlotNodes[i] = nil
    end
end

function BaseMachine:clearLayerChildReferenceCount()
    util_printLog("清理m_clipParent上的小块",true)
    util_resetChildReferenceCount(self.m_clipParent)
    util_printLog("清理m_slotEffectLayer上的小块",true)
    util_resetChildReferenceCount(self.m_slotEffectLayer)
    util_printLog("清理self上的小块",true)
    util_resetChildReferenceCount(self)
    util_printLog("清理结束",true)
end
---
-- 清理所有frame 节点
function BaseMachine:clearFrameNodes()
    for i = #self.m_framePool, 1, -1 do
        local node = self.m_framePool[i]

        if not tolua.isnull(node) then
            node:stopAllActions()
            node:clear()

            node:removeAllChildren()

            node:release()
        end

        self.m_framePool[i] = nil
    end
end

---
--@param groupNums table 滚动时生成假数据的列信息，
--@param bInclScatter bool 是否计算scatter
--@param bInclBonus bool 是否计算Bonus
--@param bPlayScatterAction bool 是否播放Bonus动画
--@param bPlayBonusAction bool 是否播放Bonus动画
function BaseMachine:slotsReelRunData(groupNums, bInclScatter, bInclBonus, bPlayScatterAction, bPlayBonusAction, autospinGroupNums, freespinGroupNums)
    if groupNums == nil or #groupNums ~= self.m_iReelColumnNum then
        return
    end

    if DEBUG == 2 then
        --输出打印接口，上线时应为注释状态
        self:printReelRunData(groupNums)
    end

    if globalData.GameConfig:checkNormalReel() == true then
        autospinGroupNums = groupNums
        freespinGroupNums = groupNums
    else
        if autospinGroupNums == nil then
            autospinGroupNums = self.m_configData.p_autospinReelRunDatas
            if autospinGroupNums == nil then
                autospinGroupNums = groupNums
            end
        end
        if freespinGroupNums == nil then
            freespinGroupNums = self.m_configData.p_freespinReelRunDatas
            if freespinGroupNums == nil then
                freespinGroupNums = groupNums
            end
        end
    end
    local groupCount = #groupNums

    self.m_reelRunInfo = {}

    --初始化长滚数据 每列初始化一个reelRunData数据
    for col = 1, self.m_iReelColumnNum, 1 do
        local reelRunData = SlotsReelRunData.new()
        local runLen = groupNums[col]

        reelRunData:initReelRunInfo(groupNums[col], bInclScatter, bInclBonus, bPlayScatterAction, bPlayBonusAction, autospinGroupNums[col], freespinGroupNums[col])
        self.m_reelRunInfo[#self.m_reelRunInfo + 1] = reelRunData

        self.m_longRunAddZorder[#self.m_longRunAddZorder + 1] = 0
    end

    -- 计算哪个列滚动的时间最长
    -- local preReelMax = 0
    local moveSpeed = self.m_configData.p_reelMoveSpeed
    local preReelTime = 0
    for i = 1, groupCount do
        local columnData = self.m_reelColDatas[i]

        local reelTime = columnData.p_showGridH * groupNums[i] / moveSpeed -- 滚动时间
        if i ~= 1 then
            reelTime = reelTime + i * self.m_reelDelayTime
        end

        if reelTime > preReelTime then
            self.m_maxHeightColumnIndex = i
        end
    end
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex
    -- printInfo("xcyy : %s","")
end

--输出各个关卡的滚动信息
function BaseMachine:printReelRunData(groupNums)
    --- 计算滚动速度和滚动小块个数
    --  第一列滚动时间为1s，之后每列递增0.2s
    --  速度：常规轮盘横版每秒滚动16个图标，竖版15个
    --  回弹距离为小块高度的 1/6
    local symbolNum = 0
    if globalData.slotRunData.isPortrait == true then
        symbolNum = 15
    else
        symbolNum = 16
    end

    local columnData = self.m_reelColDatas[1]
    local showGridH = columnData.p_showGridH
    local reelMoveSpeed = showGridH * symbolNum
    local fsReelMoveSpeed = math.floor(reelMoveSpeed * 1.1)
    local reelResDis = math.floor(showGridH / 6)
    local firstTime = 1
    local cutTime = 0.2

    local reelRunDatas = {}
    local fsReelRunDatas = {}
    local strData = "reelRunDatas,"
    local strFsData = "fsReelRunDatas,"
    local firstBaseColNum = math.floor(firstTime * reelMoveSpeed / showGridH)
    local firstFsColNum = math.floor(firstTime * fsReelMoveSpeed / showGridH)
    local addBaseNum = math.floor((firstTime + cutTime) * reelMoveSpeed / showGridH) - firstBaseColNum
    local addFsNum = math.floor((firstTime + cutTime) * fsReelMoveSpeed / showGridH) - firstFsColNum

    for i = 1, #groupNums, 1 do
        strData = strData .. (firstBaseColNum + (i - 1) * addBaseNum)
        if i ~= #groupNums then
            strData = strData .. ";"
        end

        strFsData = strFsData .. (firstFsColNum + (i - 1) * addFsNum)
        if i ~= #groupNums then
            strFsData = strFsData .. ";"
        end
    end

    print("[BaseMachine:printReelRunData] ")
    print("[BaseMachine:printReelRunData] " .. strData)
    print("[BaseMachine:printReelRunData] " .. strFsData)
    print("[BaseMachine:printReelRunData] reelResDis," .. reelResDis)
    print("[BaseMachine:printReelRunData] reelMoveSpeed," .. reelMoveSpeed)
    print("[BaseMachine:printReelRunData] fsReelMoveSpeed," .. fsReelMoveSpeed)
    print("----------------")
end

function BaseMachine:setClipWidthRatio(_ratio)
    self.m_clipWidtRatio = _ratio
end

function BaseMachine:getClipWidthRatio(colIndex)
    return self.m_clipWidtRatio or 1
end

function BaseMachine:changeViewNodePos()
    -- 在构造轮盘之前 适配关卡页面节点
end

--获得clipNode
function BaseMachine:getClipNodeForTage(tag)
    if self.m_onceClipNode then
        return self.m_onceClipNode:getChildByTag(tag)
    end
    return self.m_clipParent:getChildByTag(tag)
end

function BaseMachine:checkOnceClipNode()
    if self.m_isOnceClipNode == false then
        return
    end
    local iColNum = self.m_iReelColumnNum
    local reel = self:findChild("sp_reel_0")
    local startX = reel:getPositionX()
    local startY = reel:getPositionY()
    local reelEnd = self:findChild("sp_reel_" .. (iColNum - 1))
    local endX = reelEnd:getPositionX()
    local endY = reelEnd:getPositionY()
    local reelSize = reelEnd:getContentSize()
    local scaleX = reelEnd:getScaleX()
    local scaleY = reelEnd:getScaleY()
    reelSize.width = reelSize.width * scaleX
    reelSize.height = reelSize.height * scaleY
    local offX = reelSize.width * 0.5
    endX = endX + reelSize.width - startX + offX * 2
    endY = endY + reelSize.height - startY
    self.m_onceClipNode =
        cc.ClippingRectangleNode:create(
        {
            x = startX - offX,
            y = startY,
            width = endX,
            height = endY
        }
    )
    self.m_clipParent:addChild(self.m_onceClipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    self.m_onceClipNode:setPosition(0, 0)
end

--绘制多个裁切区域
function BaseMachine:drawReelArea()
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

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local clipNode
        local clipNodeBig
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNode.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)

            clipNodeBig = cc.Node:create()
            clipNodeBig:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNodeBig.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000000)
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

        local slotParentNode = cc.Layer:create() --cc.LayerColor:create(cc.c4f(r,g,b,200))
        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY)
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

        if clipNodeBig then
            local slotParentNodeBig = cc.Layer:create()
            slotParentNodeBig:setContentSize(reelSize.width * 2, reelSize.height)
            clipNodeBig:addChild(slotParentNodeBig)
            clipNodeBig:setPosition(posX - reelSize.width * 0.5, posY)
            parentData.slotParentBig = slotParentNodeBig
        end
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)

        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)

        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")

    -- 测试数据，看点击区域范围
    -- self.m_touchSpinLayer:setBackGroundColor(cc.c3b(0, 0, 0))
    -- self.m_touchSpinLayer:setBackGroundColorOpacity(0)
    -- self.m_touchSpinLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    end
end

function BaseMachine:changeTouchSpinLayerSize()
    if self.m_SlotNodeH and self.m_iReelRowNum then
        local size = self.m_touchSpinLayer:getContentSize()
        self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH * self.m_iReelRowNum))
    end
end

---
--获取轮盘父节点坐标未超框小格子图标  注：获取小块用getFixSymbol不要用这个 获取不到超框信号
function BaseMachine:getReelParent(col)
    return self.m_slotParents[col].slotParent
end
--获取轮盘父节点坐标超框图标
function BaseMachine:getReelBigParent(col)
    return self.m_slotParents[col].slotParentBig
end
---
-- 获取界面上的小块
--
function BaseMachine:getReelParentChildNode(iCol, iRow, symbolTag)
    if not symbolTag then
        symbolTag = SYMBOL_NODE_TAG
    end
    local colParent = self:getReelParent(iCol)
    local slotParentBig = self:getReelBigParent(iCol)
    local childTag = self:getNodeTag(iCol, iRow, symbolTag)

    if colParent ~= nil then
        local childNode = colParent:getChildByTag(childTag)
        if childNode == nil and slotParentBig then
            childNode = slotParentBig:getChildByTag(childTag)
        end
        return childNode
    end

    return nil
end

----
--
-- 初始化Machine的csb
--
function BaseMachine:initMachineCSB()
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName
    local resourceFilename = self.m_moduleName .. "/GameScreen" .. self.m_moduleName .. ".csb"
    self:createCsbNode(resourceFilename)
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

function BaseMachine:initMachineUI()
    -- 关卡设置  系统左边条右边条 缩放值， 最好根据配置来 @lmx
    -- gLobalActivityManager:setSlotFloatLayerLeft(nil, 1)
    -- gLobalActivityManager:setSlotFloatLayerRight(nil, 1)

    self:initBottomUI()
    self.m_bottomUI:addTaskNode(self)

    self:initTopUI()
    self:initMachineBg()
    self:scaleMainLayer()
    if self:checkControlerReelType() then
        local viewLayer = gLobalViewManager:getViewLayer()
        if not tolua.isnull(viewLayer) then
            viewLayer:removeAllChildren()
            if viewLayer:getParent() ~= nil then
                viewLayer:removeFromParent(false)
            end
            self:addChild(viewLayer, GAME_LAYER_ORDER.LAYER_ORDER_UI, GAME_LAYER_ORDER.LAYER_ORDER_UI)
        end
    end
   
    self:initNewbieTaskNode()
end

function BaseMachine:initMachine()
    self.m_machineModuleName = self.m_moduleName

    self:initMachineCSB() -- 创建关卡csb信息

    self:updateBaseConfig() -- 更新关卡config.csv的配置信息
    self:updateMachineData() -- 更新滚动轮子指向、 以及更新每列的ReelColumnData
    self:initSymbolCCbNames() -- 更新最基础的信号名字
    self:initMachineData() -- 在BaseSlotoManiaMachine类里面实现

    self:changeViewNodePos() -- 不同关卡适配
    self:drawReelArea() -- 绘制裁剪区域

    self:initMachineUI() -- 初始化老虎机所有UI

    self:updateReelInfoWithMaxColumn() -- 计算最高的一列
    self:initReelEffect()

    self:slotsReelRunData(
        self.m_configData.p_reelRunDatas,
        self.m_configData.p_bInclScatter,
        self.m_configData.p_bInclBonus,
        self.m_configData.p_bPlayScatterAction,
        self.m_configData.p_bPlayBonusAction
    )

    self:initSystemInfo() -- 初始化系统化信息：log、 活动栏 等等
end

function BaseMachine:updateMachineData()
    BaseMachine.super.updateMachineData(self)
    self:resetreelDownSoundArray() --重置滚动条下落音效Id
    self:resetsymbolBulingSoundArray()
end
---
-- 初始化系统部分的逻辑
--
function BaseMachine:initSystemInfo()
    gL_logData:createGameSessionId(self.m_moduleName)
    gLobalSendDataManager:getLogSlots():setUIBet()

    -- 计算出上下ui的间距
    self:initRealViewsSize()

    -- bingo 收集的起点
    globalData.bingoCollectPos = self:getActivityBingoPosInfo()
    --左边栏，是否有活动显示
    gLobalActivityManager:InitMachineLeftNode(gLobalViewManager:getViewLayer():getParent())

    self:checkUpdateActivityEntryNode()
end

function BaseMachine:getActivityBingoPosInfo()
    -- bingo 收集的起点
    local pos = nil
    local levelName = self:getModuleName()
    if levelName == "RioPinball" then
        pos = cc.p(display.center)
    else
        local midColIndex = math.ceil(self.m_iReelColumnNum / 2)
        local worldPos, reelHeight, reelWidth = self:getReelPos(midColIndex)
        pos = cc.p(worldPos.x + reelWidth * 0.5, worldPos.y + reelHeight * 0.5)
    end
    return pos
end

---
-- 初始化快滚框的信息
--
function BaseMachine:initReelEffect()
    if self.m_reelEffectName == nil then
        self.m_reelEffectName = self.m_defaultEffectName --"ReelEffect"
    -- display.loadPlistFile("Common1.plist")
    end
    -- 初始化滚动金边  TODO
    self.m_reelRunAnima = {}
    for i = 3, self.m_iReelColumnNum do
        self:createReelEffect(i)
    end
    self.m_reelRunAnimaBG = {}
    for i = 3, self.m_iReelColumnNum do
        self:createReelEffectBG(i)
    end
end

--[[
    @desc: 初始化ccb 名字
    time:2018-12-19 17:40:52
    @return:
]]
function BaseMachine:initSymbolCCbNames()
    m_Symbol1CCBName = "Socre_" .. self.m_machineModuleName .. "_1" --
    m_Symbol2CCBName = "Socre_" .. self.m_machineModuleName .. "_2" --
    m_Symbol3CCBName = "Socre_" .. self.m_machineModuleName .. "_3" --
    m_Symbol4CCBName = "Socre_" .. self.m_machineModuleName .. "_4" --
    m_Symbol5CCBName = "Socre_" .. self.m_machineModuleName .. "_5" --
    m_Symbol6CCBName = "Socre_" .. self.m_machineModuleName .. "_6" --
    m_Symbol7CCBName = "Socre_" .. self.m_machineModuleName .. "_7" --
    m_Symbol8CCBName = "Socre_" .. self.m_machineModuleName .. "_8" --
    m_Symbol9CCBName = "Socre_" .. self.m_machineModuleName .. "_9" --
    m_SymbolScatterCCBName = "Socre_" .. self.m_moduleName .. "_Scatter" --
    m_SymbolBonusCCBName = "Socre_" .. self.m_moduleName .. "_Bonus" --
    m_SymbolWildCCBName = "Socre_" .. self.m_moduleName .. "_Wild" --
end

function BaseMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    if globalData.slotRunData.isPortrait == true then
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

function BaseMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg
end

--新手任务节点
function BaseMachine:initNewbieTaskNode()
    local sysNoviceTaskMgr = G_GetMgr(G_REF.SysNoviceTask)
    local node
    if sysNoviceTaskMgr and sysNoviceTaskMgr:checkEnabled() then
        node = sysNoviceTaskMgr:createNoviceView() 
    elseif globalNewbieTaskManager:getCurrentTaskData() then
        node = util_createView("views.newbieTask.NewbieTaskNode")
    end

    if not node then
        return
    end

    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_TOP + 1)
    globalNewbieTaskManager:changeNodePos(node, self.m_moduleName)
end

function BaseMachine:getGameTopNodeLuaPath()
    return "views.gameviews.GameTopNode"
end

function BaseMachine:initTopUI()
    local topNode = util_createView(self:getGameTopNodeLuaPath(), self)
    self:addChild(topNode, GAME_LAYER_ORDER.LAYER_ORDER_TOP)
    if globalData.slotRunData.isPortrait == false then
        topNode:setScaleForResolution(true)
    end
    topNode:setPositionX(display.cx)
    topNode:setPositionY(display.height)
    globalData.topUIScale = topNode:getCsbNodeScale()

    self.m_topUI = topNode

    local coin_dollar_10 = self.m_topUI:findChild("coin_dollar_10")
    local endPos = coin_dollar_10:getParent():convertToWorldSpace(cc.p(coin_dollar_10:getPosition()))
    globalData.flyCoinsEndPos = clone(endPos)

    local _mgr = G_GetMgr(G_REF.Currency)
    if _mgr then
        local isPortrait = globalData.slotRunData.isPortrait
        local coinNode = self.m_topUI:findChild("coin_dollar_10")
        if coinNode then
            _mgr:addCollectNodeInfo(FlyType.Coin, coinNode, "MenuTop", isPortrait)
        end
        local gemNode = self.m_topUI:findChild("gem_dollar")
        if gemNode then
            _mgr:addCollectNodeInfo(FlyType.Gem, gemNode, "MenuTop", isPortrait)
        -- elseif coinNode then
        --     _mgr:addCollectNodeInfo(FlyType.Gem, coinNode, "MenuTop", isPortrait)
        end
    end

    if globalData.slotRunData.isPortrait == false then
        globalData.recordHorizontalEndPos = clone(endPos)

    -- if device.platform == "mac" and globalData.recordHorizontalEndPos.y > globalData.recordHorizontalEndPos.x then
    --     globalData.recordHorizontalEndPos.y = display.width -(display.height - endPos.y)
    --     globalData.recordHorizontalEndPos.x = endPos.x
    -- end
    end

    local lobbyHomeBtn = self.m_topUI:findChild("btn_layout_home")
    local endPos = lobbyHomeBtn:getParent():convertToWorldSpace(cc.p(lobbyHomeBtn:getPosition()))
    globalData.gameLobbyHomeNodePos = endPos

    -- topNode:setVisible(false)
end

function BaseMachine:initBottomUI()
    local bottomNode = util_createView(self:getBottomUINode(), self)
    self:addChild(bottomNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)
    if globalData.slotRunData.isPortrait == false then
        bottomNode:setScaleForResolution(true)
    end
    bottomNode:setPositionX(display.cx)
    bottomNode:setPositionY(0)
    self.m_bottomUI = bottomNode

    -- bottomNode:setVisible(false)
end

function BaseMachine:getBottomUINode()
    return "views.gameviews.GameBottomNode"
end

function BaseMachine:initFreeSpinBar()
    if globalData.slotRunData.isPortrait == false then
        local node_bar = self.m_bottomUI:findChild("node_bar")
        self.m_baseFreeSpinBar = util_createView("Levels.FreeSpinBar")
        node_bar:addChild(self.m_baseFreeSpinBar)
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
        self.m_baseFreeSpinBar:setPositionY(-3)
    end
end

function BaseMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
end

function BaseMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

---
-- 获取关卡下对应的free spin bg
--BigMegaView
function BaseMachine:getFreeSpinMusicBG()
    return self.m_fsBgMusicName
end

function BaseMachine:getNormalMusicBg()
    return self.m_bgMusicName
end

function BaseMachine:getCurrentMusicBg()
    return self.m_currentMusicBgName
end

function BaseMachine:getReSpinMusicBg()
    return self.m_rsBgMusicName
end

-- 重置当前背景音乐名称
function BaseMachine:resetCurBgMusicName(musicName)
    if musicName then
        self.m_currentMusicBgName = musicName
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end
end
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
--@musicName 需要修改的音乐路径
function BaseMachine:resetMusicBg(isMustPlayMusic, musicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    self:resetCurBgMusicName(musicName)

    if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
        if preBgMusic ~= self.m_currentMusicBgName or isMustPlayMusic == true then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
        if self.m_currentMusicId == nil then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
    else
        -- gLobalSoundManager:stopAudio(self.m_currentMusicId)
        -- self.m_currentMusicId = nil
        self:clearCurMusicBg()
    end
end
--[[
    @desc: 再有额外背景音乐需要播放时， 可以先调用这个函数，再调用resetMusicBg
    time:2018-07-26 17:32:47
    @return:
]]
function BaseMachine:clearCurMusicBg()
    -- if self.m_currentMusicId == nil then
    self.m_currentMusicId = gLobalSoundManager:getBGMusicId()
    -- end
    if self.m_currentMusicId ~= nil then
        gLobalSoundManager:stopAudio(self.m_currentMusicId)
        self.m_currentMusicId = nil
    end
end

--设置bg音乐
function BaseMachine:setBackGroundMusic(strMusicName)
    if strMusicName ~= "" and strMusicName ~= nil then
        self.m_bgMusicName = strMusicName
    else
        self.m_bgMusicName = self.m_machineModuleName .. "_Bg_Music.mp3" --背景音效名字 以前项目名字起错了应该修改
    end
end

--设置fs背景音乐
function BaseMachine:setFsBackGroundMusic(strMusicName)
    if strMusicName ~= "" and strMusicName ~= nil then
        self.m_fsBgMusicName = strMusicName
    else
        self.m_fsBgMusicName = self.m_bgMusicName
    end
end

--设置fs背景音乐
function BaseMachine:setRsBackGroundMusic(strMusicName)
    if strMusicName ~= "" and strMusicName ~= nil then
        self.m_rsBgMusicName = strMusicName
    end
end

--设置长滚音效
function BaseMachine:setReelRunSound(strSoundName)
    if strSoundName ~= "" and strSoundName ~= nil then
        self.m_reelRunSound = strSoundName
    else
        self.m_reelRunSound = SOUND_ENUM.MUSIC_BONUS_TWO_VOICE --快滚音效名称  给一个默认音效 关卡独有的话需要单独设置
    end
end

--设置下落音效
function BaseMachine:setReelDownSound(strSoundName)
    if strSoundName ~= "" and strSoundName ~= nil and CCFileUtils:sharedFileUtils():isFileExist(strSoundName) then
        self.m_reelDownSound = strSoundName
    else
        self.m_reelDownSound = SOUND_ENUM.MUSIC_REEL_STOP_ONE --滚动条下落音效  给一个默认音效 关卡独有的话需要单独设置
    end
end

--设置快停下落音效
function BaseMachine:setQuickStopReelDownSound(strSoundName)
    if strSoundName ~= "" and strSoundName ~= nil and CCFileUtils:sharedFileUtils():isFileExist(strSoundName) then
        self.m_quickStopReelDownSound = strSoundName
    end
end

--设置创滚动画名字
function BaseMachine:setReelEffect(strEffectName)
    if strEffectName ~= "" and strEffectName ~= nil then
        self.m_reelEffectName = strEffectName
    end
end

--设置快滚背景动画名字
function BaseMachine:setReelBgEffect(strEffectName)
    if strEffectName ~= "" and strEffectName ~= nil then
        self.m_reelBgEffectName = strEffectName
    end
end

-- --播放背景音乐
-- function BaseMachine:playBackGroundMusic()
--     gLobalSoundManager:playBackgroudMusic(self.m_bgMusicName, true)
-- end

-- --播放Fs背景音乐
-- function BaseMachine:playFsBackGroundMusic()
--     gLobalSoundManager:playBackgroudMusic(self.m_fsBgMusicName, true)
-- end

---
-- 初始化机器数据, 例如betIdx 等
--
function BaseMachine:initMachineData()
end

---
-- 获取最高的那一列
--
function BaseMachine:updateReelInfoWithMaxColumn()
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
    self.m_SlotNodeH = self.m_fReelHeigth / self.m_iReelRowNum

    -- 计算每列的行数
    local isSpecialReel = false
    for i = 1, #self.m_reelColDatas do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridH = self.m_SlotNodeH
        columnData.p_showGridCount = math.floor(columnData.p_slotColumnHeight / self.m_SlotNodeH + 0.5) -- 对对应列进行四舍五入
        if columnData.p_showGridCount ~= self.m_iReelRowNum then
            isSpecialReel = true
        end
    end
    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end
end

---
-- 获取游戏区域reel height 这些都是在ccb中配置的 custom properties 属性， 但是目前无法从ccb读取，
-- cocos2dx 未开放接口
--
function BaseMachine:getReelHeight()
    return self.m_reelHeight
end

function BaseMachine:getReelWidth()
    return self.m_reelWidth
end

---
-- 获取游戏背景的reel height
--
function BaseMachine:getBGReelHeight()
    return 603
end

-- function BaseMachine:onEnter()

-- end

function BaseMachine:onExit()
    release_print("---onExit:" .. self.__cname)
    BaseMachineGameEffect.onExit(self) -- 必须调用不予许删除
    globalMachineController:onExit()
    --停止背景音乐
    gLobalSoundManager:stopBgMusic()
    gLobalSoundManager:stopAllSounds()

    gLobalDebugReelTimeManager.m_Machine = nil

    self:removeObservers()

    if self.m_signManager then
        self.m_signManager:clearAllSignData()
    end
    self:clearFrameNodes()
    self:clearSlotNodes()
    -- gLobalSoundManager:stopBackgroudMusic()
    -- 卸载金边
    for i, v in pairs(self.m_reelRunAnima) do
        local reelNode = v[1]
        local reelAct = v[2]

        if not tolua.isnull(reelNode) then
            if reelNode:getParent() ~= nil then
                reelNode:removeFromParent()
            end
            reelNode:release()
        end

        if not tolua.isnull(reelAct) then
            reelAct:release()
        end
        self.m_reelRunAnima[i] = nil
    end
    if self.m_reelRunAnimaBG ~= nil then
        for i, v in pairs(self.m_reelRunAnimaBG) do
            local reelNode = v[1]
            local reelAct = v[2]

            if not tolua.isnull(reelNode) then
                if reelNode:getParent() ~= nil then
                    reelNode:removeFromParent()
                end
                reelNode:release()
            end

            if not tolua.isnull(reelAct) then
                reelAct:release()
            end
            self.m_reelRunAnimaBG[i] = nil
        end
    end

    if self.m_reelScheduleDelegate ~= nil then
        self.m_reelScheduleDelegate:unscheduleUpdate()
    end

    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    if self.m_beginStartRunHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
        self.m_beginStartRunHandlerID = nil
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
    -- clear view childs
    if self:checkControlerReelType() then
        local viewLayer = gLobalViewManager:getViewLayer()
        if not tolua.isnull(viewLayer) then
            viewLayer:removeAllChildren()
        end
    end
    

    self:removeSoundHandler()

    self:clearLayerChildReferenceCount()

    self:clearLevelsCodeCache()
    --重置bet倍率
    globalData.slotRunData:setCurBetMultiply(1)
    --离开，清空
    gLobalActivityManager:clear()
end

--[[
    清空关卡代码缓存
]]
function BaseMachine:clearLevelsCodeCache()
    if device.platform == "mac" and DEBUG == 2 then
        for path,v in pairs(package.loaded) do
            local modelName = self:getModuleName()
            local startIndex, endIndex = string.find(path, modelName)
            if startIndex and endIndex then
                package.loaded[path] = nil
            end
        end

        -- 清除csv缓存
        local csvDatas = gLobalResManager.m_CSVDatas or {}
        for path,v in pairs(csvDatas) do
            local modelName = self:getModuleName()
            local startIndex, endIndex = string.find(path, modelName)
            if startIndex and endIndex then
                gLobalResManager.m_CSVDatas[path] = nil
            end
        end
    end
end

---
--
function BaseMachine:addObservers()
    printInfo("BaseMachine:addObservers()")
    gLobalNoticManager:addObserver(self, self.quicklyStopReel, ViewEventType.QUICKLY_SPIN_EFFECT)

    gLobalNoticManager:addObserver(self, self.normalSpinBtnCall, ViewEventType.STR_TOUCH_SPIN_BTN)

    gLobalNoticManager:addObserver(self, self.spinItemCall, ViewEventType.NOTIFY_ACTIVITY_SPIN_ITEM_REWARD_END)

    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            target:notifyGameEffectPlayComplete(param)
        end,
        ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE
    )

    gLobalNoticManager:addObserver(
        self,
        function()
            self:removeLevelSoundHandlerAndSetMaxVolume()
        end,
        ViewEventType.NOTIFY_REMOVE_LEVEL_SOUND_HANDLER_AND_SET_MAX_VOLUME
    )

    gLobalNoticManager:addObserver(
        self,
        function()
            self:resumeLevelSoundHandler()
        end,
        ViewEventType.NOTIFY_RESUME_LEVEL_SOUND_HANDLER
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target)
            --release_print("BaseMachine:ViewEventType.NOTIFY_ENTER_BONUS_GAME target setVisible")

            Target:setVisible(false)
        end,
        ViewEventType.NOTIFY_ENTER_BONUS_GAME
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, hasBonusBgMusic)
            --release_print("BaseMachine:ViewEventType.NOTIFY_EXIT_BONUS_GAME target setVisible")

            Target:setVisible(true)
            if hasBonusBgMusic ~= nil and hasBonusBgMusic == true then
                Target:resetMusicBg(true)
            end
        end,
        ViewEventType.NOTIFY_EXIT_BONUS_GAME
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, mulitiNum)
            Target.m_expMultiNum = mulitiNum
        end,
        ViewEventType.EXP_MUTLI
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            gLobalNoticManager:postNotification(ViewEventType.SHOW_PAY_TABLE_VIEW)
        end,
        ViewEventType.NOTIFY_SHOW_PAY_TABLE
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:resetMusicBg(true)
        end,
        ViewEventType.NOTIFY_RESET_BG_MUSIC
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:MachineRule_respinTouchSpinBntCallBack()
        end,
        ViewEventType.RESPIN_TOUCH_SPIN_BTN
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:reSpinReelDown()
        end,
        ViewEventType.NOTIFY_RESPIN_RUN_STOP
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:checkFeatureOverTriggerBigWin(params[1], params[2])

            Target:updateQuestBonusRespinEffectData()

            if params[2] and params[2] == GameEffect.EFFECT_BONUS then
                Target:addRewaedFreeSpinStartEffect()
            end
        end,
        ViewEventType.NOTIFY_BONUS_CLOSED
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            self.m_pauseRef = self.m_pauseRef + 1
            Target:pauseMachine()
        end,
        ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            self.m_pauseRef = math.max(self.m_pauseRef - 1, 0)
            if self.m_pauseRef <= 0 then
                Target:resumeMachine()
            end
        end,
        ViewEventType.NOTIFY_RESUME_SLOTSMACHINE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            gLobalViewManager:removeLoadingAnima()
            if params[1] == true then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            else
                gLobalViewManager:showReConnect(true)
            end
        end,
        ViewEventType.NOTIFY_COLLECT_WATCH_VIDEO_REWARD
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.reelDownSoundFlag and self.m_soundHandlerId == nil and self.m_soundGlobalId == nil then
                if gLobalSoundManager:getBackgroundMusicVolume() > 0 then
                    self:reelsDownDelaySetMusicBGVolume()
                end
            end
        end,
        ViewEventType.NOTIFY_ADS_END
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:reelsDownDelaySetMusicBGVolume()
        end,
        ViewEventType.NOTIFY_SET_DELAY_MUSICBG_VOLUME
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:removeSoundHandler()
        end,
        ViewEventType.NOTIFY_REMOVE_DELAY_MUSICBG_VOLUME
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- self:randomAddActLimitSignPos()
        end,
        ViewEventType.NOTIFY_ACTIVITY_BALLOON_RUSH_SPIN
    )
    -- gLobalNoticManager:addObserver(self,function(self,params)
    --     self.m_bQuestComplete = true

    --     --滚动停止
    --     -- if self:getGameSpinStage() == IDLE then
    --     --     if self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then

    --     --         --动画结束
    --     --         if self.m_isRunningEffect == false then
    --     --             self:showQuestCompleteTip()
    --     --         else
    --     --             self:addQuestCompleteTipEffect()
    --     --         end

    --     --     end
    --     -- else
    --         --滚动中
    --         -- self:addQuestCompleteTipEffect()
    --     -- end
    -- end,ViewEventType.NOTIFY_QUEST_LEVEL_COMPLETE)
end

function BaseMachine:checkQuestAddDelayBigWin()
end

function BaseMachine:checkQuestAddBigWin()
end

function BaseMachine:updateQuestUI()
end

function BaseMachine:addQuestCompleteTipEffect()
    if globalData.slotRunData.currLevelEnter ~= FROM_QUEST then
        return
    end
    self:updateQuestUI()
    if not self.m_bQuestComplete then
        return
    end

    if (self:getCurrSpinMode() == RESPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE) then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) or self:checkHasEffectType(GameEffect.EFFECT_RESPIN_OVER) then
            self:addAnimationOrEffectType(GameEffect.QUEST_COMPLETE_TIP)
        end
    elseif self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) or self:checkHasEffectType(GameEffect.EFFECT_RESPIN) then
        --do nothing
    else
        self:addAnimationOrEffectType(GameEffect.QUEST_COMPLETE_TIP)
    end
end

function BaseMachine:showQuestCompleteTip()
end

function BaseMachine:questCompleteTipCallBack()
end

---
--
function BaseMachine:removeObservers()
    gLobalNoticManager:removeAllObservers(self)
end

function BaseMachine:updateQuestBonusRespinEffectData()
    --加弹窗
    if self:checkHasGameEffectType(GameEffect.QUEST_COMPLETE_TIP) == false then
        if not self.m_bQuestComplete then
            return
        end

        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.QUEST_COMPLETE_TIP
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

function BaseMachine:featureOverTriggerBigWinSpecCheck(feature)
    if not self.m_isFeatureOverBigWinInFree then
        if self.m_bProduceSlots_InFreeSpin == true and (feature == GameEffect.EFFECT_RESPIN_OVER or feature == GameEffect.EFFECT_BONUS) then
            return true
        end
    elseif feature ~= GameEffect.EFFECT_FREE_SPIN_OVER then
        local freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
        local totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
        -- Free最后一次不弹自定义大赢
        if self.m_bProduceSlots_InFreeSpin == true and 
            totalFreeSpinCount ~= 0 and freeSpinCount == 0 then
            return true
        end
    end
    

    return false
end

function BaseMachine:getNewBingWinTotalBet(_over)
    local avgbet = self.m_runSpinResultData.p_avgBet or 0
    if _over then
        if avgbet ~= 0 then
            return avgbet
        end
    else
        if avgbet ~= 0 and globalData.slotRunData.m_averageStates then
            return avgbet
        end
    end
    
    return globalData.slotRunData:getCurTotalBet()
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function BaseMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
    if winAmonut == nil then
        return
    end

    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = self:getNewBingWinTotalBet(true)
    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_LegendaryWinLimitRate then
        winEffect = GameEffect.EFFECT_LEGENDARY
    elseif winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        self.m_bIsBigWin = true
        local isAddEffect = false
        for i = 1, #self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if effectData.p_effectType == feature then
                isAddEffect = true
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                delayEffect.p_effectOrder = feature + 1
                table.insert(self.m_gameEffects, i + 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, i + 2, effectData)
                break
            end
        end
        if isAddEffect == false then
            for i = 1, #self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_isPlay == false then
                    self.m_llBigOrMegaNum = winAmonut

                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert(self.m_gameEffects, i + 1, delayEffect)

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert(self.m_gameEffects, i + 2, effectData)
                    break
                end
            end
            if #self.m_gameEffects == 0 then
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                table.insert(self.m_gameEffects, 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, 2, effectData)
            end
        end
    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()

    if feature == GameEffect.EFFECT_BONUS then
        self:addRewaedFreeSpinStartEffect()
        self:addRewaedFreeSpinOverEffect()
    end
end

--TODO 游戏显示逻辑相关

---转换tag
---
function BaseMachine:getNodeTag(iColIndex, iRow, iDataTag)
    return iColIndex * iDataTag + iRow -- 用列作为大索引， 行作为小索引
end

-----
---创建一行小块 用于一列落下时 上边条漏出空隙过大
function BaseMachine:createResNode(parentData, lastNode)
    if self.m_bCreateResNode == false then
        return
    end

    local rowIndex = parentData.rowIndex
    local addRandomNode = function()
        local symbolType = self:getResNodeSymbolType(parentData)

        local slotParent = parentData.slotParent
        local columnData = self.m_reelColDatas[parentData.cloumnIndex]

        local node = self:getSlotNodeWithPosAndType(symbolType, columnData.p_showGridCount + 1, parentData.cloumnIndex, true)
        node.p_slotNodeH = columnData.p_showGridH
        node:setTag(-1)
        parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        local targetPosY = lastNode:getPositionY()

        local slotNodeH = columnData.p_showGridH

        if self.m_bigSymbolInfos[lastNode.p_symbolType] ~= nil then
            targetPosY = targetPosY + (self.m_bigSymbolInfos[lastNode.p_symbolType]) * slotNodeH
        else
            targetPosY = targetPosY + slotNodeH
        end
        -- node.

        node:setPosition(lastNode:getPositionX(), targetPosY)
        local order = 0

        if self.m_bigSymbolInfos[symbolType] ~= nil then
            order = self:getBounsScatterDataZorder(symbolType) - node.p_rowIndex
        else
            order = self:getBounsScatterDataZorder(symbolType) - node.p_rowIndex
        end

        slotParent:addChild(node, order)

        node:runIdleAnim()
    end
    if self.m_bigSymbolInfos[parentData.symbolType] ~= nil then
        local bigSymbolCount = self.m_bigSymbolInfos[parentData.symbolType]
        if rowIndex > 1 and (rowIndex - 1) + bigSymbolCount > self.m_iReelRowNum then -- 表明跨过了 当前一组
            --表明跨组了 不创建小块
        else
            --创建一个小块
            addRandomNode()
        end
    else
        --创建一个小块
        addRandomNode()
    end
end

function BaseMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_resTopTypes
end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData:
    @return:
]]
function BaseMachine:getResNodeSymbolType(parentData)
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self:getNextReelSymbolType()
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end

        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    return symbolType
end

function BaseMachine:moveDownCallFun(node)
    -- 回收对象
    --release_print("BaseMachine: moveDownCallFun node setVisible")

    node:setVisible(true)
    node:removeFromParent(false)
    local symbolType = node.p_symbolType
    self:pushSlotNodeToPoolBySymobolType(symbolType, node)
end

---
-- 重置列的 local zorder
--
function BaseMachine:resetCloumnZorder(col)
    if col < 1 or col > self.m_iReelColumnNum then
        return
    end
    local parentData = self.m_slotParents[col]
    local slotParent = parentData.slotParent
    local slotNodes = slotParent:getChildren()
    local nodeLen = #slotNodes
    local totalOrder = 0
    for index = 1, nodeLen do
        local slotNode = slotNodes[index]
        totalOrder = totalOrder + slotNode:getLocalZOrder()
    end

    slotParent:getParent():setLocalZOrder(totalOrder)
end

local slotReelTime = 0
local reelDelayTime = 0.3
local slotReelTime = 0
local L_ABS = math.abs

---
-- 检测是否移除掉 每列中的元素
--
function BaseMachine:reelSchedulerCheckRemoveNodes(childs, halfH, parentY, colIndex)
    local zOrder = 0
    local preY = 0

    local columnData = self.m_reelColDatas[colIndex]

    for i = 1, #childs do
        local childNode = childs[i]

        if childNode.p_IsMask == nil then
            local childY = childNode:getPositionY()

            local nodeH = childNode.p_slotNodeH or 144

            -- 判断当前位置信息是否处于当前列的外面，是则移除掉
            local topY = 0
            if self.m_bigSymbolInfos[childNode.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[childNode.p_symbolType]
                topY = childY + (symbolCount - 0.5) * (halfH * 2) --nodeH * 0.5 -- --
            else
                topY = childY + nodeH * 0.5 --halfH
            end
            preY = util_max(preY, topY)

            if topY + parentY <= 0 then
                -- 移除
                self:moveDownCallFun(childNode)
            else
                zOrder = zOrder + childNode:getLocalZOrder()
            end
        end
    end -- end for i=1,#childs do

    return zOrder, preY
end
---
--移除节点后检测是否需要在创建节点
--
local markIndex = 0
function BaseMachine:reelSchedulerCheckAddNode(parentData, zOrder, preY, halfH, parentY, slotParent)
    if parentData.isReeling == true then
        -- 判断哪些元素需要移除出显示列表

        local columnData = self.m_reelColDatas[parentData.cloumnIndex]
        local moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth

        if moveDiff <= 0 then
            local createNextSlotNode = function()
                local node = self:getSlotNodeWithPosAndType(parentData.symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
                local posY = preY + columnData.p_showGridH * 0.5

                node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

                zOrder = zOrder + parentData.order

                node.p_slotNodeH = columnData.p_showGridH
                node.p_symbolType = parentData.symbolType
                node.p_preSymbolType = parentData.preSymbolType
                node.p_showOrder = parentData.order

                node.p_reelDownRunAnima = parentData.reelDownAnima

                node.p_reelDownRunAnimaSound = parentData.reelDownAnimaSound
                node.p_layerTag = parentData.layerTag

                local slotParentBig = parentData.slotParentBig
                -- 添加到显示列表
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, parentData.order, parentData.tag)
                else
                    slotParent:addChild(node, parentData.order, parentData.tag)
                end

                node:runIdleAnim()

                if parentData.isHide then
                    node:setVisible(false)
                end

                if self.m_bigSymbolInfos[node.p_symbolType] ~= nil then
                    local symbolCount = self.m_bigSymbolInfos[node.p_symbolType]

                    preY = posY + (symbolCount - 0.5) * columnData.p_showGridH
                else
                    preY = posY + 0.5 * columnData.p_showGridH -- 计算创建偏移位置到顶部区域y坐标
                end

                moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth
                -- lastNode = node

                -- 创建下一个节点
                if parentData.isLastNode == true then -- 本列最后一个节点移动结束
                    -- 执行回弹, 如果不执行回弹判断是否执行
                    parentData.isReeling = false
                    -- printInfo("xcyy 停下来的parent 位置为 : %d  %f  ", parentData.cloumnIndex,slotParent:getPositionY())
                    -- 创建一个假的小块 在回滚停止后移除
                    self:createResNode(parentData, node)
                else
                    -- 计算moveDiff 距离是否大于一个 格子， 如果是那么循环补齐多个格子， 以免中间缺失创建
                    self:createSlotNextNode(parentData)
                end
            end

            createNextSlotNode() -- 创建一次

            while (moveDiff < 0 and parentData.isReeling == true) do
                createNextSlotNode()
            end
        else
        end -- end if moveDiff <= 0 then

        self:changeSlotsParentZOrder(zOrder, parentData, slotParent) -- 重新设置zorder
    end -- end if parentData.isReeling == true
end

---
--@param bBlowScreen bool true 移除屏幕下边的小块 false 移除屏幕上方的小块
function BaseMachine:removeNodeOutNode(slotParent, bBlowScreen, halfH, colIndex)
    local columnData = self.m_reelColDatas[colIndex]

    local childs = slotParent:getChildren()
    for i = 1, #childs do
        local childNode = childs[i]

        if childNode.p_IsMask == nil then
            local childY = childNode:getPositionY()

            -- 判断当前位置信息是否处于当前列的外面，是则移除掉
            local topY = 0

            if self.m_bigSymbolInfos[childNode.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[childNode.p_symbolType]
                topY = childY + (symbolCount - 0.5) * columnData.p_showGridH --self.m_SlotNodeH
            else
                topY = childY + columnData.p_showGridH * 0.5
            end

            --移除屏幕下方
            if bBlowScreen then
                if topY + slotParent:getPositionY() < 1 then
                    -- 移除

                    self:moveDownCallFun(childNode)
                else
                    if childNode.m_isLastSymbol == false then
                        release_print(
                            "removeNodeOutNode " .. slotParent:getPositionY() .. "  " .. childNode.p_cloumnIndex .. " " .. childNode.p_rowIndex .. " " .. childNode:getPositionY() .. "  " .. topY
                        )
                    end
                end
            else
                --移除屏幕上方
                local bottomY = topY

                if self.m_bigSymbolInfos[childNode.p_symbolType] ~= nil then
                    local symbolCount = self.m_bigSymbolInfos[childNode.p_symbolType]
                    bottomY = bottomY - symbolCount * columnData.p_showGridH --self.m_SlotNodeH
                else
                    --self.m_SlotNodeH
                    bottomY = bottomY - columnData.p_showGridH
                end
                if bottomY + 1 >= math.abs(slotParent:getPositionY() - columnData.p_slotColumnHeight) then --self.m_fReelHeigth) then
                    -- 移除
                    self:moveDownCallFun(childNode)
                end
            end
        end -- end if IsMask
    end
end

function BaseMachine:playCustomSpecialSymbolDownAct(slotNode)
    if slotNode.p_reelDownRunAnima ~= nil then
        slotNode:playReelDownAnima()

        if slotNode.p_reelDownRunAnimaSound ~= nil then
            local iCol = slotNode.p_cloumnIndex
            self:playBulingSymbolSounds(iCol, slotNode.p_reelDownRunAnimaSound)
        end
        if slotNode.p_reelDownRunAnimaTimes then
            self.m_reelDownAddTime = slotNode.p_reelDownRunAnimaTimes
        end
    end
end

function BaseMachine:reelSchedulerCheckColumnReelDown(parentData, parentY, slotParent, halfH)
    local timeDown = 0
    --
    --停止reel
    if L_ABS(parentY - parentData.moveDistance) < 0.1 then -- 浮点数精度问题
        if parentData.isDone ~= true then
            timeDown = 0
            if self.m_bClickQuickStop ~= true or self.m_iBackDownColID == parentData.cloumnIndex then
                parentData.isDone = true
            elseif self.m_bClickQuickStop == true and self:getGameSpinStage() ~= QUICK_RUN then
                return
            end

            local quickStopDistance = 0
            if self:getGameSpinStage() == QUICK_RUN or self.m_bClickQuickStop == true then
                quickStopDistance = self.m_quickStopBackDistance
            end
            slotParent:stopAllActions()
            self:slotOneReelDown(parentData.cloumnIndex)
            slotParent:setPosition(cc.p(slotParent:getPositionX(), parentData.moveDistance - quickStopDistance))

            local slotParentBig = parentData.slotParentBig
            if slotParentBig then
                slotParentBig:stopAllActions()
                slotParentBig:setPosition(cc.p(slotParentBig:getPositionX(), parentData.moveDistance - quickStopDistance))
                self:removeNodeOutNode(slotParentBig, true, halfH, parentData.cloumnIndex)
            end

            local childs = slotParent:getChildren()
            if slotParentBig then
                local newChilds = slotParentBig:getChildren()
                for i = 1, #newChilds do
                    childs[#childs + 1] = newChilds[i]
                end
            end

            -- release_print("滚动结束 .." .. 1)
            --移除屏幕下方的小块
            self:removeNodeOutNode(slotParent, true, halfH, parentData.cloumnIndex)
            local speedActionTable, addTime = self:MachineRule_reelDown(slotParent, parentData)
            if slotParentBig then
                local seq = cc.Sequence:create(speedActionTable)
                slotParentBig:runAction(seq:clone())
            end

            timeDown = timeDown + (addTime + 0.1) -- 这里补充0.1 主要是因为以免计算出来的结果不够一帧的时间， 造成 action 执行和stop reel 有误差

            local tipSlotNoes = nil
            local nodeParent = parentData.slotParent
            local nodes = nodeParent:getChildren()
            if slotParentBig then
                local nodesBig = slotParentBig:getChildren()
                for i = 1, #nodesBig do
                    nodes[#nodes + 1] = nodesBig[i]
                end
            end

            --播放配置信号的落地音效
            self:playSymbolBulingSound(nodes)
            -- 播放配置信号的落地动效
            self:playSymbolBulingAnim(nodes, speedActionTable)

            tipSlotNoes = {}
            for i = 1, #nodes do
                local slotNode = nodes[i]
                local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

                if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
                    --播放关卡中设置的小块效果
                    self:playCustomSpecialSymbolDownAct(slotNode)

                    if self:checkSymbolTypePlayTipAnima(slotNode.p_symbolType) then
                        if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
                            tipSlotNoes[#tipSlotNoes + 1] = slotNode
                        end

                    --                            break
                    end
                --                        end
                end
            end -- end for i=1,#nodes

            if tipSlotNoes ~= nil then
                local nodeParent = parentData.slotParent
                for i = 1, #tipSlotNoes do
                    local slotNode = tipSlotNoes[i]

                    self:playScatterBonusSound(slotNode)
                    slotNode:runAnim("buling")
                    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
                    self:specialSymbolActionTreatment(slotNode)
                end -- end for
            end

            self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)

            local actionFinishCallFunc =
                cc.CallFunc:create(
                function()
                    parentData.isResActionDone = true
                    if self.m_bClickQuickStop == true then
                        self:quicklyStopReel(parentData.cloumnIndex)
                    end
                    print("滚动彻底停止了")
                    self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
                end
            )

            speedActionTable[#speedActionTable + 1] = actionFinishCallFunc

            slotParent:runAction(cc.Sequence:create(speedActionTable))
            timeDown = timeDown + self.m_reelDownAddTime
        end
    end -- end if L_ABS(parentY - parentData.moveDistance) < 0.1

    return timeDown
end

function BaseMachine:slotOneReelDownFinishCallFunc(reelCol)
end

function BaseMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return true
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        return true
    end
end

function BaseMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    globalData.slotRunData.gameRunPause = true
    -- end
end

function BaseMachine:resumeMachine()
    globalData.slotRunData.gameRunPause = nil
    if gLobalViewManager:isLobbyView() or gLobalViewManager:isLoadingView() then
        --大厅或者loading不处理回调
    else
        if globalData.slotRunData.gameResumeFunc then
            globalData.slotRunData.gameResumeFunc()
        end
    end
    globalData.slotRunData.gameResumeFunc = nil
end

function BaseMachine:checkGameRunPause()
    if globalData.slotRunData.gameRunPause == true then
        return true
    else
        return false
    end
end

function BaseMachine:reelSchedulerHanlder(delayTime)
    if (self:getGameSpinStage() ~= GAME_MODE_ONE_RUN and self:getGameSpinStage() ~= QUICK_RUN) or self:checkGameRunPause() then
        return
    end

    -- slotReelTime = slotReelTime  + delayTime
    -- if slotReelTime < reelDelayTime then
    --     return
    -- end
    -- reelDelayTime = util_random(8,30) / 100
    -- slotReelTime = 0

    if self.m_reelDownAddTime > 0 then
        self.m_reelDownAddTime = self.m_reelDownAddTime - delayTime
    else
        self.m_reelDownAddTime = 0
    end
    local timeDown = 0
    local slotParentDatas = self.m_slotParents

    for index = 1, #slotParentDatas do
        local parentData = slotParentDatas[index]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        -- if parentData.cloumnIndex == 1 then
        -- 	printInfo(" %d ", parentData.tag)
        -- end
        local columnData = self.m_reelColDatas[index]
        local halfH = columnData.p_showGridH * 0.5

        local parentY = slotParent:getPositionY()
        if parentData.isDone == false then
            local cloumnMoveStep = self:getColumnMoveDis(parentData, delayTime)
            local newParentY = slotParent:getPositionY() - cloumnMoveStep
            if self.m_isWaitingNetworkData == false then
                if newParentY < parentData.moveDistance then
                    newParentY = parentData.moveDistance
                end
            end
            -- if index == 3 thenx
            --     print("")
            -- end
            slotParent:setPositionY(newParentY)
            parentY = newParentY
            local childs = slotParent:getChildren()
            local zOrder, preY = self:reelSchedulerCheckRemoveNodes(childs, halfH, parentY, index)

            if slotParentBig then
                slotParentBig:setPositionY(newParentY)
                local childs = slotParentBig:getChildren()
                local zOrder, newPreY = self:reelSchedulerCheckRemoveNodes(childs, halfH, parentY, index)
                if newPreY > preY then
                    preY = newPreY
                end
            end
            self:reelSchedulerCheckAddNode(parentData, zOrder, preY, halfH, parentY, slotParent)
        end

        if self.m_isWaitingNetworkData == false then
            timeDown = self:reelSchedulerCheckColumnReelDown(parentData, parentY, slotParent, halfH)
        end
    end -- end for

    local isAllReelDone = function()
        for index = 1, #slotParentDatas do
            if slotParentDatas[index].isResActionDone == false then
                -- if slotParentDatas[index].isDone == false then

                return false
            end
        end

        return true
    end

    if isAllReelDone() == true then
        if self.m_reelScheduleDelegate ~= nil then
            self.m_reelScheduleDelegate:unscheduleUpdate()
        end
        self:slotReelDown()

        -- 先写在这里 之后写到 回弹结束里面去
        --加入回弹

        -- scheduler.performWithDelayGlobal(
        --     function()
        --         self:slotReelDown()
        --     end,
        --     timeDown,
        --     self:getModuleName()
        -- )

        --        end,timeDown)
        self.m_reelDownAddTime = 0
    end
end
---
-- 这里默认是匀速运动, 后去
--
function BaseMachine:getColumnMoveDis(parentData, delayTime)
    if not parentData.moveSpeed then
        parentData.moveSpeed = self.m_configData.p_reelMoveSpeed
    end
    --减速配置
    self:checkChangeStopColumnMoveDis(parentData)
    return parentData.moveSpeed * delayTime
end

--检测是否到了减速阶段
function BaseMachine:checkChangeStopColumnMoveDis(parentData)
    if parentData.isDone == true then
        return
    end
    if self.m_isWaitingNetworkData == false and self.m_configData.p_reelStopDis and self.m_configData.p_reelStopDis > 0 then
        local slotParent = parentData.slotParent
        local parentY = slotParent:getPositionY()
        if parentY - parentData.moveDistance < self.m_configData.p_reelStopDis then
            local currentDis = parentY - parentData.moveDistance
            currentDis = self.m_configData.p_reelStopDis - currentDis
            local targetDis = self.m_configData.p_reelResDis + self.m_configData.p_reelStopDis
            local moveSpeed = self:getMoveSpeedBySpinMode(self:getCurrSpinMode())
            local acceleration = moveSpeed * moveSpeed / targetDis * 0.5
            parentData.moveSpeed = math.sqrt(moveSpeed * moveSpeed - 2 * acceleration * currentDis)
        end
    end
end

---
-- 滚动停止和回弹效果
-- BaseMachine:playSymbolBulingAnim 和这个方法做了绑定 如果返回的动作 由 xxBy -> xxTo 时，对应方法需要修改
function BaseMachine:MachineRule_reelDown(slotParent, parentData)
    -- if self.m_configData.p_reelResType and self.m_configData.p_reelResType == 1 then
    --     --匀减速
    --     return self:MachineRule_DownAction1(slotParent, parentData)
    -- else
    --     --常规曲线
    --     return self:MachineRule_DownAction2(slotParent, parentData,self.m_configData.p_reelResType)
    -- end
    --常规
    return self:MachineRule_DownAction3(slotParent, parentData)
end

--回弹类型1 匀减速回弹
function BaseMachine:MachineRule_DownAction1(slotParent, parentData)
    local back, backTime = self:MachineRule_BackAction(slotParent, parentData)
    local speedActionTable = {}
    local timeDown = backTime
    local currentDis = 0
    local targetDis = self.m_configData.p_reelResDis
    local currentMoveSpeed = parentData.moveSpeed
    local acceleration = currentMoveSpeed * currentMoveSpeed / targetDis * 0.5
    local actionCount = 10
    local stepTime = currentMoveSpeed / acceleration / actionCount
    local targetMoveSpeed = currentMoveSpeed - acceleration * stepTime
    local moveDis = (currentMoveSpeed + targetMoveSpeed) * 0.5 * stepTime
    for i = 1, actionCount do
        local moveBy = cc.MoveBy:create(stepTime, cc.p(0, -moveDis))
        speedActionTable[#speedActionTable + 1] = moveBy
        timeDown = timeDown + stepTime
        currentMoveSpeed = targetMoveSpeed
        targetMoveSpeed = currentMoveSpeed - acceleration * stepTime
        moveDis = (currentMoveSpeed + targetMoveSpeed) * 0.5 * stepTime
    end
    speedActionTable[#speedActionTable + 1] = back
    return speedActionTable, timeDown
end

--回弹类型2 常规回弹
function BaseMachine:MachineRule_DownAction2(slotParent, parentData, rate)
    --回弹比例
    if not rate then
        rate = 1
    end
    local back, backTime = self:MachineRule_BackAction(slotParent, parentData)
    local speedActionTable = {}
    local dis = self.m_configData.p_reelResDis
    local speedStart = parentData.moveSpeed
    local preSpeed = speedStart / (rate * 55 + rate * 4 + 1)
    local timeDown = backTime
    for i = 1, 10 do
        speedStart = speedStart - preSpeed * (11 - i) * rate
        local moveDis = dis / 10
        local time = moveDis / speedStart
        timeDown = timeDown + time
        local moveBy = cc.MoveBy:create(time, cc.p(slotParent:getPositionX(), -moveDis))
        speedActionTable[#speedActionTable + 1] = moveBy
    end
    speedActionTable[#speedActionTable + 1] = back
    return speedActionTable, timeDown
end

function BaseMachine:MachineRule_DownAction3(slotParent, parentData)
    local back, backTime = self:MachineRule_BackAction(slotParent, parentData)
    local speedActionTable = {}
    local dis = self.m_configData.p_reelResDis
    local speedStart = parentData.moveSpeed
    local preSpeed = speedStart / 118
    local timeDown = backTime
    if self:getGameSpinStage() ~= QUICK_RUN then
        for i = 1, 10 do
            speedStart = speedStart - preSpeed * (11 - i) * 2
            local moveDis = dis / 10
            local time = moveDis / speedStart
            timeDown = timeDown + time
            local moveBy = cc.MoveBy:create(time, cc.p(slotParent:getPositionX(), -moveDis))
            speedActionTable[#speedActionTable + 1] = moveBy
        end
    end

    speedActionTable[#speedActionTable + 1] = back
    return speedActionTable, timeDown
end

function BaseMachine:MachineRule_BackAction(slotParent, parentData)
    local moveTime = self.m_configData.p_reelResTime
    -- 落地提层图标的回弹时间走关卡配置 这个位置就不写死快停回弹了 之后有需求可以加关卡配置字段区分
    -- if self:getGameSpinStage() == QUICK_RUN then
    --     moveTime = 0.3
    -- end

    local back = cc.MoveTo:create(moveTime, cc.p(slotParent:getPositionX(), parentData.moveDistance))
    return back, self.m_configData.p_reelResTime
end

function BaseMachine:isPlayTipAnima(matrixPosY, matrixPosX, node)
    local nodeData = self.m_reelRunInfo[matrixPosY]:getSlotsNodeInfo()

    if nodeData ~= nil and #nodeData ~= 0 then
        for i = 1, #nodeData do
            if self.m_bigSymbolInfos[node.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[node.p_symbolType]
                local startRowIndex = node.p_rowIndex
                local endRowIndex = node.p_rowIndex + symbolCount
                if nodeData[i].x >= matrixPosX and nodeData[i].x <= endRowIndex and nodeData[i].y == matrixPosY then
                    if nodeData[i].bIsPlay == true then
                        return true
                    end
                end
            else
                if nodeData[i].x == matrixPosX and nodeData[i].y == matrixPosY then
                    if nodeData[i].bIsPlay == true then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function BaseMachine:registerReelSchedule()
    if self.m_reelScheduleDelegate ~= nil then
        self.m_reelScheduleDelegate:onUpdate(
            function(delayTime)
                self:reelSchedulerHanlder(delayTime)
            end
        )
    end
end

function BaseMachine:createSlotNextNode(parentData)
    if self.m_isWaitingNetworkData == true then
        -- 等待网络数据返回时， 还没开始滚动真信号，所以肯定为false 2018-12-15 18:15:51
        parentData.m_isLastSymbol = false
        self:getReelDataWithWaitingNetWork(parentData)
        return
    end

    parentData.lastReelIndex = parentData.lastReelIndex + 1

    local cloumnIndex = parentData.cloumnIndex
    local columnDatas = self.m_reelSlotsList[cloumnIndex]
    local data = columnDatas[parentData.lastReelIndex]
    if data == nil then -- 在最后滚动过程中由于未滚动停止 ， 所以会继续触发创建
        return
    end
    local columnData = self.m_reelColDatas[cloumnIndex]
    local columnRowNum = columnData.p_showGridCount

    local symbolType = nil
    if tolua.type(data) == "number" then
        symbolType = data

        local rowIndex = parentData.lastReelIndex % columnRowNum --self.m_iReelRowNum
        if rowIndex == 0 then
            rowIndex = columnRowNum
        --self.m_iReelRowNum
        end

        if self.m_bigSymbolInfos[symbolType] ~= nil then
            parentData.order = self:getBounsScatterDataZorder(symbolType) - rowIndex
        else
            parentData.order = self:getBounsScatterDataZorder(symbolType)
        end
        parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

        parentData.tag = cloumnIndex * SYMBOL_NODE_TAG + rowIndex
        parentData.reelDownAnima = nil
        parentData.reelDownAnimaSound = nil
        parentData.m_isLastSymbol = false

        parentData.rowIndex = rowIndex
    else
        parentData.isLastNode = false
        symbolType = data.p_symbolType

        parentData.order = data.m_showOrder - data.m_rowIndex
        parentData.tag = data.m_columnIndex * data.m_symbolTag + data.m_rowIndex

        parentData.reelDownAnima = data.m_reelDownAnima
        parentData.reelDownAnimaSound = data.m_reelDownAnimaSound
        parentData.layerTag = data.p_layerTag

        parentData.rowIndex = data.m_rowIndex
        if data.m_rowIndex == columnRowNum then --self.m_iReelRowNum then
            parentData.isLastNode = true
        elseif self.m_bigSymbolInfos[symbolType] ~= nil then
            local addCount = self.m_bigSymbolInfos[symbolType]
            parentData.order = self:getBounsScatterDataZorder(symbolType)
            if parentData.rowIndex + (addCount - 1) >= columnRowNum then --self.m_iReelRowNum then
                parentData.isLastNode = true
            end
        end
        parentData.m_isLastSymbol = data.m_isLastSymbol
    end

    parentData.symbolType = symbolType

    if self.m_bigSymbolInfos[symbolType] ~= nil then
        local addCount = self.m_bigSymbolInfos[symbolType]
        parentData.lastReelIndex = parentData.lastReelIndex + addCount - 1
    end
end
---
-- 在这里不影响groupIndex 和 rowIndex 等到结果数据来时使用
--
function BaseMachine:getReelDataWithWaitingNetWork(parentData)
    local symbolType = self:getReelSymbolType(parentData)

    parentData.symbolType = symbolType
end

function BaseMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                util_changeNodeParent(preParent, lineNode, nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                lineNode:runIdleAnim()
            end
        end
    end
end

function BaseMachine:clearWinLineEffect()
    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)

        self.m_showLineHandlerID = nil
    end

    self:clearLineAndFrame()

    -- 改变lineSlotNodes 的层级
    self:resetMaskLayerNodes()

    -- 隐藏长条模式下 大长条的遮罩问题
    self:operaBigSymbolMask(false)
end
--[[
    @desc: 在开始滚动前重置数据
    time:2020-07-21 18:25:31
    @return:
]]
function BaseMachine:resetReelDataAfterReel()
    self.m_waitChangeReelTime = 0

    --添加线上打印
    local logName = self:getModuleName()
    if logName then
        release_print("beginReel ... GameLevelName = " .. logName)
    else
        release_print("beginReel ... GameLevelName = nil")
    end

    self:stopAllActions()
    self:requestSpinReusltData() -- 临时注释掉
    self:beforeCheckSystemData()
    -- 记录 本次spin 中共产生的 scatter和bonus 数量，播放音效使用
    self.m_nScatterNumInOneSpin = 0
    self.m_nBonusNumInOneSpin = 0

    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SET_SPIN_BTN_ORDER,{false,gLobalViewManager:getViewLayer() })
    local effectLen = #self.m_gameEffects
    for i = 1, effectLen, 1 do
        self.m_gameEffects[i] = nil
    end

    self:clearWinLineEffect()

    self.m_showLineFrameTime = nil

    self:resetreelDownSoundArray()
    self:resetsymbolBulingSoundArray()
    if self.m_videoPokeMgr then
        self.m_videoPokeMgr:setInitIconStates(true)
    end
end
--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function BaseMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

function BaseMachine:beginReel()
    self:resetReelDataAfterReel()
    local slotsParents = self.m_slotParents
    for i = 1, #slotsParents do
        local parentData = slotsParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local reelDatas = self:checkUpdateReelDatas(parentData)

        self:checkReelIndexReason(parentData)
        self:resetParentDataReel(parentData)

        self:createSlotNextNode(parentData)
        if self.m_configData.p_reelBeginJumpTime > 0 then
            self:addJumoActionAfterReel(slotParent, slotParentBig)
        else
            self:registerReelSchedule()
        end
        self:checkChangeClipParent(parentData)
    end
    self:checkChangeBaseParent()
end
--[[
    @desc: 滚动开始前 重置每列的滚动参数信息
    time:2020-07-21 19:25:40
    @return:
]]
function BaseMachine:resetParentDataReel(parentData)
    parentData.isDone = false
    parentData.isResActionDone = false
    parentData.isReeling = false
    parentData.moveSpeed = self:getMoveSpeedBySpinMode(self:getCurrSpinMode())
    parentData.isReeling = true
end
--[[
    @desc: 通过滚动模式获取滚动速度
    time:2021-09-23
]]
function BaseMachine:getMoveSpeedBySpinMode(_spinMode)
    local moveSpeed = self.m_configData.p_reelMoveSpeed

    if _spinMode == FREE_SPIN_MODE then
        if self.m_configData.p_fsReelMoveSpeed then
            moveSpeed = self.m_configData.p_fsReelMoveSpeed
            if self.m_configData.p_freeReelMoveSpeedMul then
                moveSpeed = moveSpeed * self.m_configData.p_freeReelMoveSpeedMul
            end
        end
    else
        if self:getCurrSpinMode() == AUTO_SPIN_MODE and self.m_configData.p_baseAutoReelMoveSpeedMul then
            moveSpeed = moveSpeed * self.m_configData.p_baseAutoReelMoveSpeedMul
        end
    end

    return moveSpeed
end
--[[
    @desc: 开始滚动之前添加向上跳动作
    time:2020-07-21 19:23:58
    @return:
]]
function BaseMachine:addJumoActionAfterReel(slotParent, slotParentBig)
    --添加一个回弹效果
    local action0 = cc.JumpTo:create(self.m_configData.p_reelBeginJumpTime, cc.p(slotParent:getPositionX(), slotParent:getPositionY()), self.m_configData.p_reelBeginJumpHight, 1)

    local sequece =
        cc.Sequence:create(
        {
            action0,
            cc.CallFunc:create(
                function()
                    self:registerReelSchedule()
                end
            )
        }
    )

    slotParent:runAction(sequece)
    if slotParentBig then
        slotParentBig:runAction(action0:clone())
    end
end

--beginReel时尝试修改层级
function BaseMachine:checkChangeClipParent(parentData)
    local slotParent = parentData.slotParent
    local slotParentBig = parentData.slotParentBig
    --判断tag值 如果父节点有节点tag < xxx 切节点不为轮盘 则将节点放入对应轮盘 轮盘有节点tag 》xx 则将节点放入父节点
    local childs = slotParent:getChildren()
    if slotParentBig then
        local newChilds = slotParentBig:getChildren()
        for i = 1, #newChilds do
            childs[#childs + 1] = newChilds[i]
        end
    end
    for i = 1, #childs do
        if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE then
            if childs[i].resetReelStatus ~= nil then
                childs[i]:resetReelStatus()
            end
            --将该节点放在 .m_clipParent
            local posWorld = slotParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(), childs[i]:getPositionY()))
            local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            childs[i]:setPosition(cc.p(pos.x, pos.y))
            util_changeNodeParent(self.m_clipParent, childs[i], SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + childs[i].m_showOrder)
        end
    end
end

--beginReel时尝试修改层级
function BaseMachine:checkChangeBaseParent()
    -- 处理特殊信号
    local childs = self.m_clipParent:getChildren()
    for i = 1, #childs do
        local child = childs[i]
        if childs[i].resetReelStatus ~= nil then
            childs[i]:resetReelStatus()
        end
        if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
            --将该节点放在 .m_clipParent
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(), childs[i]:getPositionY()))
            local pos = self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            if not childs[i].p_showOrder then
                childs[i].p_showOrder = self:getBounsScatterDataZorder(childs[i].p_symbolType)
            end
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            self:changeBaseParent(childs[i])
            childs[i]:resetReelStatus()
            childs[i]:setPosition(pos)
        end
    end
end

---
-- 检测滚动的随机索引是否正确 , 主要用来检测大信号
--
function BaseMachine:checkReelIndexReason(parentData)
    -- 判断随机的索引是否跨越长条
    local preSymbolType = parentData.reelDatas[parentData.beginReelIndex]

    if self.m_bigSymbolInfos[preSymbolType] ~= nil then
        local symbolCount = self.m_bigSymbolInfos[preSymbolType]
        local frontIndex = parentData.beginReelIndex
        local backIndex = parentData.beginReelIndex
        local frontSameCount = 0
        local backSameCount = 0
        local checkFrontEnd = false
        local checkBackEnd = false

        while true do
            if frontIndex < 1 then
                checkFrontEnd = true
            else
                frontIndex = frontIndex - 1
            end
            if backIndex > #parentData.reelDatas then
                checkBackEnd = true
            else
                backIndex = backIndex + 1
            end

            if checkFrontEnd == true and checkBackEnd == true then
                break
            end

            local frontCheckType = parentData.reelDatas[frontIndex]

            if preSymbolType == frontCheckType then
                frontSameCount = frontSameCount + 1
            else
                checkFrontEnd = true
            end

            local backCheckType = parentData.reelDatas[backIndex]
            if preSymbolType == backCheckType then
                backSameCount = backSameCount + 1
            else
                checkBackEnd = true
            end
        end

        -- 检测reel index 是否合理

        if frontSameCount % symbolCount == 0 or backSameCount % symbolCount == 0 then
            return
        else
            parentData.beginReelIndex = parentData.beginReelIndex - frontSameCount % symbolCount
        end
    end
end

--[[
    根据索引获取小块
]]
function BaseMachine:getSymbolByPosIndex(posIndex)
    local posData = self:getRowAndColByPos(posIndex)
    local iCol,iRow = posData.iY,posData.iX

    local symbolNode = self:getFixSymbol(iCol,iRow,SYMBOL_NODE_TAG)
    return symbolNode
end

function BaseMachine:getFixSymbol(iCol, iRow, iTag)
    if not iTag then
        iTag = SYMBOL_NODE_TAG
    end
    local fixSp = nil
    fixSp = self.m_clipParent:getChildByTag(self:getNodeTag(iCol, iRow, iTag))
    if fixSp == nil and (iCol >= 1 and iCol <= self.m_iReelColumnNum) then
        fixSp = self.m_slotParents[iCol].slotParent:getChildByTag(self:getNodeTag(iCol, iRow, iTag))
        if fixSp == nil then
            local slotParentBig = self.m_slotParents[iCol].slotParentBig
            if slotParentBig then
                fixSp = slotParentBig:getChildByTag(self:getNodeTag(iCol, iRow, iTag))
            end
        end
    end
    return fixSp
end

function BaseMachine:checkHasBigSymbol()
    local bigSymbolLen = table_length(self.m_bigSymbolInfos)
    if bigSymbolLen > 0 then
        self.m_hasBigSymbol = true
    else
        self.m_hasBigSymbol = false
    end
end

function BaseMachine:operaBigSymbolMask(showMask)
    if self.m_hasBigSymbol == false then
        return
    end
    for colIndex = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[colIndex]

        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local childs = slotParent:getChildren()

        if slotParentBig then
            local newChilds = slotParentBig:getChildren()
            for j=1,#newChilds do
                childs[#childs+1]=newChilds[j]
            end
        end

        for i = 1, #childs do
            local childNode = childs[i]

            if self.m_bigSymbolInfos[childNode.p_symbolType] ~= nil then
                if showMask == true then
                    self:operaBigSymbolShowMask(childNode)
                else
                    childNode:hideBigSymbolClip()
                end
            end
        end
    end
end

function BaseMachine:getBigSymbolMaskRowCount(_iCol)
    return self.m_iReelRowNum
end

function BaseMachine:operaBigSymbolShowMask(childNode)
    -- 这行是获取每列的显示行数， 为了适应多不规则轮盘
    local colIndex = childNode.p_cloumnIndex
    local columnData = self.m_reelColDatas[colIndex]
    local rowCount = self:getBigSymbolMaskRowCount(colIndex)

    local symbolCount = self.m_bigSymbolInfos[childNode.p_symbolType]
    local startRowIndex = childNode.p_rowIndex

    local chipH = 0
    if startRowIndex < 1 then -- 起始格子在屏幕的下方
        chipH = (symbolCount + startRowIndex - 1) * columnData.p_showGridH
    elseif startRowIndex > 1 then -- 起始格子在屏幕上方
        local diffCount = startRowIndex + symbolCount - 1 - rowCount
        if diffCount > 0 then
            chipH = (symbolCount - diffCount) * columnData.p_showGridH
        else
            chipH = symbolCount * columnData.p_showGridH
        end
    else -- 起始格子处于屏幕范围内
        chipH = symbolCount * columnData.p_showGridH
    end

    local clipY = 0
    if startRowIndex < 1 then
        clipY = math.abs((startRowIndex - 1) * columnData.p_showGridH)
    end

    clipY = clipY - columnData.p_showGridH * 0.5

    -- local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + colIndex)
    local clipNode = self:getClipNodeForTage(CLIP_NODE_TAG + colIndex)
    local reelW = clipNode:getClippingRegion().width

    childNode:showBigSymbolClip(clipY, reelW, chipH)
end

---
-- 老虎机滚动结束调用
function BaseMachine:slotReelDown()
    self:setGameSpinStage(STOP_RUN)
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex

    -- if DEBUG == 2 then
    --     for i = 1, #self.m_slotParents do
    --         local parentData = self.m_slotParents[i]
    --         local slotParent = parentData.slotParent
    --         local childs = slotParent:getChildren()
    --         for j=1,#childs do
    --             local child = childs[j]
    --             release_print(" ---- 剩余格子  row = %d , col = %d , type = %d , pos = %f , %d" ,
    --             child.p_rowIndex,child.p_cloumnIndex,child.p_symbolType,child:getPositionY(),child.m_isLastSymbol )
    --         end

    --     end
    -- end

    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]

            if reelData == nil or tolua.type(reelData) == "number" then
                -- do nothing
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end -- end for i = 1,listLen

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            value:clean()
            self.m_reelResultLines[i] = nil

            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end

    self:checkRestSlotNodePos()

    -- 判断是否是长条模式，处理长条只显示一部分的遮罩问题
    -- self:operaBigSymbolMask(true)
    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()

    -- if DEBUG == 2 then
    --     for i = 1, #self.m_slotParents do
    --         local parentData = self.m_slotParents[i]
    --         local slotParent = parentData.slotParent
    --         local childs = slotParent:getChildren()
    --         for j=1,#childs do
    --             local child = childs[j]
    --             release_print(" ---- 剩余格子  row = %d , col = %d , type = %d , pos = %f , %d" ,
    --             child.p_rowIndex,child.p_cloumnIndex,child.p_symbolType,child:getPositionY(),child.m_isLastSymbol )
    --         end

    --     end
    -- end

    self:delaySlotReelDown()
    self:stopAllActions()
    self:reelDownNotifyPlayGameEffect()

    if self.m_videoPokeMgr then
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local iconPos = selfdata.iconLocs
        local isFullCollect = selfdata.isFullCollect
        self.m_videoPokeMgr:playVideoPokerIconFly(iconPos, isFullCollect, self)
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_SLOTS_STOP)
end

function BaseMachine:checkRestSlotNodePos()
    -- 还原reel parent 信息
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local posx, posy = slotParent:getPosition()
        slotParent:setPosition(0, 0) -- 还原位置信息
        local childs = slotParent:getChildren()
        --        printInfo("xcyy  剩余 child count %d", #childs)
        if slotParentBig then
            slotParentBig:setPosition(0, 0) -- 还原位置信息
            local newChilds = slotParentBig:getChildren()
            for j = 1, #newChilds do
                childs[#childs + 1] = newChilds[j]
            end
        end
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

                if self.m_bigSymbolInfos[childNode.p_symbolType] ~= nil then
                    -- childNode:setPositionY(nodeH * (childNode.p_rowIndex - 1) + nodeH * 0.5)
                    childNode:setPositionY(self.m_SlotNodeH * (childNode.p_rowIndex - 1) + self.m_SlotNodeH * 0.5)
                else
                    childNode:setPositionY(nodeH * childNode.p_rowIndex - nodeH * 0.5)
                end

                if moveDis == nil then
                    moveDis = childPosY - childNode:getPositionY()
                end
            else
                --do nothing
            end

            childNode.m_isLastSymbol = false
        end

        --判断tag值 如果父节点有节点tag < xxx 切节点不为轮盘 则将节点放入对应轮盘 轮盘有节点tag 》xx 则将节点放入父节点
        local childs = slotParent:getChildren()
        if slotParentBig then
            local newChilds = slotParentBig:getChildren()
            for i = 1, #newChilds do
                childs[#childs + 1] = newChilds[i]
            end
        end
        for i = 1, #childs do
            local childNode = childs[i]
            if childNode.m_isLastSymbol == true then
                if childNode:getTag() < SYMBOL_NODE_TAG + BIG_SYMBOL_NODE_DIFF_TAG then
                    --将该节点放在 .m_clipParent
                    childNode:removeFromParent(false)
                    local posWorld = slotParent:convertToWorldSpace(cc.p(childNode:getPositionX(), childNode:getPositionY()))
                    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                    childNode:setPosition(cc.p(pos.x, pos.y))
                    self.m_clipParent:addChild(childNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
                end
            end
        end

        -- printInfo(" xcyy %d  %d  ", parentData.cloumnIndex,parentData.symbolType)
        parentData:reset()
    end
end

-- 重写此函数 一点要调用 BaseMachine.reelDownNotifyPlayGameEffect(self) 而不是 self:playGameEffect()
function BaseMachine:reelDownNotifyPlayGameEffect()
    self:playGameEffect()
end

function BaseMachine:reelDownNotifyChangeSpinStatus()
    -- 通知滚动结束
    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, false})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end
end

function BaseMachine:isLongRun(col)
    if col > self.m_iReelColumnNum then
        return true
    end
    if self.m_reelRunInfo[col]:getReelLongRun() and col <= self.m_iReelColumnNum then
        return true
    end
    return false
end

function BaseMachine:checkQuickStopStage()
    return self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true
end

function BaseMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = false

    --长滚效果
    local reelRunData = self.m_reelRunInfo[reelCol]

    local nodeData = reelRunData:getSlotsNodeInfo()

    -- 处理长滚动
    if reelRunData:getNextReelLongRun() == true and self:checkQuickStopStage() then
        isTriggerLongRun = true -- 触发了长滚动

        for i = reelCol + 1, self.m_iReelColumnNum do
            --添加金边
            if i == reelCol + 1 then
                if self.m_reelRunInfo[i]:getReelLongRun() then
                    self:creatReelRunAnimation(i)
                end
            end
            --后面列停止加速移动
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent

            parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
        end
    end
    return isTriggerLongRun
end

--本列停止 判断下列是否有长滚
function BaseMachine:getNextReelIsLongRun(reelCol)
    if reelCol <= self.m_iReelColumnNum then
        local bHaveLongRun = false
        for i = 1, reelCol do
            local reelRunData = self.m_reelRunInfo[i]
            if reelRunData:getNextReelLongRun() == true then
                bHaveLongRun = true
                break
            end
        end
        if self:isLongRun(reelCol) and bHaveLongRun and self.m_reelRunInfo[reelCol]:getNextReelLongRun() == false then
            return true
        end
    end
    return false
end

function BaseMachine:resetsymbolBulingSoundArray()
    self.m_symbolBulingSoundArray = {}
    for iCol = 1, self.m_iReelColumnNum do
        self.m_symbolBulingSoundArray[iCol] = {}
    end

    self.m_symbolQsBulingSoundArray = {}
end

function BaseMachine:setNormalBulingSymbolSoundId(_iCol, _soundName)
    local bulingInfo = self.m_symbolBulingSoundArray[_iCol]
    bulingInfo[tostring(_soundName)] = "soundName" .. _iCol
end

function BaseMachine:setQuickStopBulingSymbolSoundId(_soundName, _soundType)
    local qsBulingInfo = self.m_symbolQsBulingSoundArray
    if not qsBulingInfo[tostring(_soundType)] then
        qsBulingInfo[tostring(_soundType)] = {}
    end

    table.insert(qsBulingInfo[tostring(_soundType)], _soundName)
end

function BaseMachine:checkQuickStopBulingState()
    return self:getGameSpinStage() == QUICK_RUN
end

function BaseMachine:playQuickStopBulingSymbolSound(_iCol)
    if self:checkQuickStopBulingState() then
        if _iCol == self.m_iReelColumnNum then
            local soundIds = {}
            local bulingDatas = self.m_symbolQsBulingSoundArray
            for soundType, soundPaths in pairs(bulingDatas) do
                local soundPath = soundPaths[#soundPaths]
                local soundId = gLobalSoundManager:playSound(soundPath)
                table.insert(soundIds, soundId)
            end

            return soundIds
        end
    end
end

--[[
    音效落地音效播放接口
    _soundType 不同档位的音效需要传入对应的信号值
    _maxSound 不同档位的音效需要传入等级最高的音效路径
    tip:有_soundType必然有_maxSound,无_soundType无_maxSound
]]
function BaseMachine:playBulingSymbolSounds(_iCol, _soundName, _soundType)
    local soundId = nil
    local soundValue = _soundType or _soundName
    if _iCol and _soundName then
        if self:checkQuickStopBulingState()  then
            self:setQuickStopBulingSymbolSoundId(_soundName, soundValue)
        else
            local bulingInfos = self.m_symbolBulingSoundArray[_iCol]
            local Info = bulingInfos[tostring(soundValue)]
            if not Info then
                soundId = gLobalSoundManager:playSound(_soundName)
                self:setNormalBulingSymbolSoundId(_iCol, soundValue)
            end
        end
    end

    return soundId
end

function BaseMachine:resetreelDownSoundArray()
    self.m_reelDownSoundArray = {}
    for iCol = 1, self.m_iReelColumnNum do
        self.m_reelDownSoundArray[iCol] = self.m_reelDownSoundNoPlay
    end
end

function BaseMachine:setReelDownSoundId(_iCol, _typeId)
    if self:getGameSpinStage() ~= QUICK_RUN then
        self.m_reelDownSoundArray[_iCol] = _typeId
    end
end

function BaseMachine:getQuickStopBeginCol()
    for iCol = 1, self.m_iReelColumnNum do
        if self.m_reelDownSoundArray[iCol] == self.m_reelDownSoundNoPlay then
            return iCol
        end
    end
end

function BaseMachine:playReelDownSound(_iCol, _path)
    if self:checkIsPlayReelDownSound(_iCol) then
        if self:getGameSpinStage() == QUICK_RUN and self.m_quickStopReelDownSound then
            gLobalSoundManager:playSound(self.m_quickStopReelDownSound)
        else
            gLobalSoundManager:playSound(_path)
        end
    end
    self:setReelDownSoundId(_iCol, self.m_reelDownSoundPlayed)
end

function BaseMachine:checkIsPlayReelDownSound(_iCol)
    if self:getGameSpinStage() == QUICK_RUN then
        local Col = self:getQuickStopBeginCol()
        if Col then
            if _iCol == Col then
                return true
            end
        end

        return false
    else
        return true
    end
end

---
-- 每个reel条滚动到底
function BaseMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and self:checkQuickStopStage() then
        self:creatReelRunAnimation(reelCol + 1)
    end

    self:playReelDownSound(reelCol, self.m_reelDownSound)

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            --新增快滚渐隐
            if self.m_configData.m_reelEffectResFadeTime then
                util_nodeFadeIn(reelEffectNode[1],self.m_configData.m_reelEffectResFadeTime,255,0,nil,function()
                    reelEffectNode[1]:runAction(cc.Hide:create())
                end)
            else
                reelEffectNode[1]:runAction(cc.Hide:create())
            end
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]
        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            --新增快滚底渐隐
            if self.m_configData.m_reelBgEffectResFadeTime then
                util_nodeFadeIn(reelEffectNode[1],self.m_configData.m_reelBgEffectResFadeTime,255,0,nil,function()
                    reelEffectNode[1]:runAction(cc.Hide:create())
                end)
            else
                reelEffectNode[1]:runAction(cc.Hide:create())
            end
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        self:triggerLongRunChangeBtnStates()
    end

    return isTriggerLongRun
end

function BaseMachine:triggerLongRunChangeBtnStates()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
end

function BaseMachine:createReelEffect(col)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. ".csb")
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()

    self.m_slotEffectLayer:addChild(reelEffectNode)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

function BaseMachine:createReelEffectBG(col)
    if self.m_reelBgEffectName ~= nil then
        local csbName = self.m_reelBgEffectName .. ".csb"
        local reelEffectNode, effectAct = util_csbCreate(csbName)

        reelEffectNode:retain()
        effectAct:retain()

        self.m_clipParent:addChild(reelEffectNode, -1,SYMBOL_NODE_TAG * 100)
        local reel = self:findChild("sp_reel_" .. (col - 1))
        local reelType = tolua.type(reel)
        if reelType == "ccui.Layout" then
            reelEffectNode:setLocalZOrder(0)
        end
        reelEffectNode:setPosition(cc.p(reel:getPosition()))
        self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

        reelEffectNode:setVisible(false)

        return reelEffectNode, effectAct
    end
end

function BaseMachine:setLongAnimaInfo(reelEffectNode, col)
    local worldPos, reelHeight, reelWidth = self:getReelPos(col)

    local pos = self.m_slotEffectLayer:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    reelEffectNode:setPosition(cc.p(pos.x, pos.y))
end

---
--添加金边
function BaseMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")

    --新增快滚渐显
    if self.m_configData.m_reelEffectResFadeTime then
        reelEffectNode:setOpacity(0)
        util_nodeFadeIn(reelEffectNode,self.m_configData.m_reelEffectResFadeTime,0,255)
    end
    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)

    if self.m_reelBgEffectName ~= nil then -- 快滚背景特效
        local reelEffectNodeBG = nil
        local reelActBG = nil
        if self.m_reelRunAnimaBG == nil then
            self.m_reelRunAnimaBG = {}
        end
        if self.m_reelRunAnimaBG[col] == nil then
            reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
        else
            local reelBGObj = self.m_reelRunAnimaBG[col]

            reelEffectNodeBG = reelBGObj[1]
            reelActBG = reelBGObj[2]
        end

        reelEffectNodeBG:setScaleX(1)
        reelEffectNodeBG:setScaleY(1)

        -- if self.m_bProduceSlots_InFreeSpin == true then
        -- else
        -- end
        
        --新增快滚底渐显
        if self.m_configData.m_reelBgEffectResFadeTime then
            reelEffectNodeBG:setOpacity(0)
            util_nodeFadeIn(reelEffectNodeBG,self.m_configData.m_reelBgEffectResFadeTime,0,255)
        end
        reelEffectNodeBG:setVisible(true)
        util_csbPlayForKey(reelActBG, "run", true)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

---
--
function BaseMachine:getReelPos(col)
    -- local colNodeName =  "reel_unit"..(col - 1) --string.format("reel_unit%d",i - 1)
    -- local posX = self.m_ccbOwner[colNodeName]:getPositionX()
    -- local posY = self.m_ccbOwner[colNodeName]:getPositionY()
    -- local worldPos = self.m_ccbOwner[colNodeName]:getParent():convertToWorldSpace(cc.p(posX,posY))
    -- local reelHeight = self.m_ccbOwner[colNodeName]:getContentSize().height
    -- local reelWidth = self.m_ccbOwner[colNodeName]:getContentSize().width

    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

---
-- 最后一个reel条滚动到底
-- 用于快停
function BaseMachine:slotLastReelDown()
    if
        self:getGameSpinStage() == QUICK_RUN and -- self.m_enumBigSymbolType == TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE and
            self.m_hasBigSymbol == false and
            self.m_configData.p_quickStopDelayTime == 0
     then
    end
end

---
-- 等待滚动全部结束后 执行reel down 的具体后续逻辑
local curWinType = 0

function BaseMachine:delaySlotReelDown()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:resetSlotsRunChangeData()

    -- 开始执行后续的逻辑 ， 暂时不考虑准备下一阶段的滚动内容
    self:heldOnAllScore()

    self:MachineRule_stopReelChangeData()

    --改变freespin状态
    self:changeFreeSpinModeStatus()

    -- 改变respin状态
    self:changeReSpinModeStatus()

    -- 添加自定义的effects
    self:addSelfEffect()

    self:calculateLastWinCoin()

    self:addLastWinSomeEffect()

    -- 保留本轮结果
    self:keepCurrentSpinData()

    self:checkRemoveBigMegaEffect()

    --添加连线动画
    self:addLineEffect()

    --刷新quest 并且尝试添加quest完成
    self:addQuestCompleteTipEffect()

    -- 添加活动赠送免费spin次数游戏事件
    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()

    --添加收集角标Effct
    self:addCollectSignEffect()

    --动画层级赋值
    self:setGameEffectOrder()

    --检测添加大赢光效
    if self.m_isAddBigWinLightEffect then
        self:checkAddBigWinLight()
    end
    

    self:sortGameEffects()

    if #self.m_gameEffects > 0 then
        -- 通知动画开始运行。
        self.m_isRunningEffect = true
    end

    for i = #self.m_vecSymbolEffectType, 1, -1 do
        table.remove(self.m_vecSymbolEffectType, i)
    end
end

--[[
    检测添加大赢光效
]]
function BaseMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end

--[[
    检测是否存在大赢
]]
function BaseMachine:checkHasBigWin()
    if self:checkHasGameEffectType(GameEffect.EFFECT_DELAY_SHOW_BIGWIN) or
    self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) or 
    self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
    self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or 
    self:checkHasGameEffectType(GameEffect.EFFECT_LEGENDARY) then
        return true
    end
    return false
end

--[[
    检测是否为大赢类型
]]
function BaseMachine:isBigWinEffectType(effectType)
    if effectType == GameEffect.EFFECT_BIGWIN or 
    effectType == GameEffect.EFFECT_MEGAWIN or 
    effectType == GameEffect.EFFECT_EPICWIN or
    effectType == GameEffect.EFFECT_LEGENDARY then
       return true
    end

    return false
end
---
-- 排序m_gameEffects 列表，根据 effectOrder
--
function BaseMachine:sortGameEffects()
    -- 排序effect 队列
    table.sort(
        self.m_gameEffects,
        function(a, b)
            return a.p_effectOrder < b.p_effectOrder
        end
    )
end

function BaseMachine:staticsQuestSpinData()
    globalAdjustManager:checkTriggerNPAdjustLog(AdjustNPEventType.spin)
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    if piggyBankData then
        piggyBankData:updateSpinCount()
    end
end

---
--重置轮盘滚动改变的变量
function BaseMachine:resetSlotsRunChangeData()
    self:setGameSpinStage(IDLE)
    --重置 轮盘滚动数据 长度 长滚效果等
    self:resetReelRunInfo()

    self.m_longRunAddZorder = {}
    for i = 1, self.m_iReelColumnNum do
        self.m_longRunAddZorder[#self.m_longRunAddZorder + 1] = 0
    end
end

function BaseMachine:addFsTimes(addTimes)
    globalData.slotRunData.freeSpinCount = (globalData.slotRunData.freeSpinCount or 0) + addTimes
    print("addFsTimes")
end

---
--将滚动数据重置回来
function BaseMachine:resetReelRunInfo()
    --始化长滚信息
    if self.m_reelRunSoundTag ~= -1 then
        --停止长滚音效
        -- printInfo("xcyy : m_reelRunSoundTag2 %d",self.m_reelRunSoundTag)
        gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
        self.m_reelRunSoundTag = -1
    end

    for i = 1, #self.m_reelRunInfo do
        self.m_reelRunInfo[i]:clear()
    end
end

---
--判断改变freespin的状态
function BaseMachine:changeFreeSpinModeStatus()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER
            end
        end
    end

    --判断是否进入fs
    local bHasFsEffect = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)

    --如果有fs
    if bHasFsEffect then
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_bProduceSlots_InFreeSpin = true
        end
    end
end

--判断改变 reSpin 的 状态
function BaseMachine:changeReSpinModeStatus()
    if self:getCurrSpinMode() == RESPIN_MODE then
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then -- reSpin spin 模式结束
            local effectData = GameEffectData.new()
            effectData.p_effectType = GameEffect.EFFECT_RESPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = effectData
        end
    end
end

local function cloneLineInfo(originValue, targetValue)
    targetValue.enumSymbolType = originValue.enumSymbolType
    targetValue.enumSymbolEffectType = originValue.enumSymbolEffectType
    targetValue.iLineIdx = originValue.iLineIdx
    targetValue.iLineSymbolNum = originValue.iLineSymbolNum
    targetValue.iLineMulti = originValue.iLineMulti
    targetValue.lineSymbolRate = originValue.lineSymbolRate

    local matrixPosLen = #originValue.vecValidMatrixSymPos
    for i = 1, matrixPosLen do
        local value = originValue.vecValidMatrixSymPos[i]

        table.insert(targetValue.vecValidMatrixSymPos, {iX = value.iX, iY = value.iY})
    end
end

-- 组织播放连线动画信息
function BaseMachine:insterReelResultLines()
    if #self.m_vecGetLineInfo ~= 0 then
        local lines = self.m_vecGetLineInfo
        local lineLen = #lines
        local hasBonus = false
        local hasScatter = false
        for i = 1, lineLen do
            local value = lines[i]

            local function copyLineValue()
                local cloneValue = self:getReelLineInfo()
                cloneLineInfo(value, cloneValue)
                table.insert(self.m_reelResultLines, cloneValue)

                if #cloneValue.vecValidMatrixSymPos > 5 then
                -- printInfo("")
                end
            end

            if value.enumSymbolEffectType == GameEffect.EFFECT_BONUS or value.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                if value.enumSymbolEffectType == GameEffect.EFFECT_BONUS and hasBonus == false then
                    copyLineValue()
                    hasBonus = true
                elseif value.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN and hasScatter == false then
                    copyLineValue()
                    hasScatter = true
                end
            else
                copyLineValue()
            end
        end
    end
end

---
--保留本轮数据
function BaseMachine:keepCurrentSpinData()
    self:insterReelResultLines()

    --TODO   wuxi update on
    globalData.slotRunData.totalFreeSpinCount = (globalData.slotRunData.totalFreeSpinCount or 0) + self.m_iFreeSpinTimes

    local effectLen = #self.m_vecSymbolEffectType
    for i = 1, effectLen do
        local value = self.m_vecSymbolEffectType[i]
        local effectData = GameEffectData.new()
        effectData.p_effectType = value
        --                                effectData.p_effectData = data
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

---
--添加连线动画
function BaseMachine:addLineEffect()
    if #self.m_vecGetLineInfo ~= 0 then
        for i = 1, #self.m_reelResultLines do
            local lineValue = self.m_reelResultLines[i]
            if
                (lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS or lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN) and #self.m_reelResultLines == 1 and
                    lineValue.lineSymbolRate == 0
             then
                -- 如果只有bonus 和 freespin 连线 那么， 不做连线播放，
                return
            end
        end

        local effectData = GameEffectData.new()
        effectData.p_effectType = self.m_LineEffectType
        --GameEffect.EFFECT_SHOW_ALL_LINE
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData

        table.sort(
            self.m_reelResultLines,
            function(a, b)
                return a.enumSymbolType < b.enumSymbolType
            end
        )
    end
end

-----by he 将除自定义动画之外的动画层级赋值
--
function BaseMachine:setGameEffectOrder()
    if self.m_gameEffects == nil then
        return
    end

    local lenEffect = #self.m_gameEffects
    for i = 1, lenEffect, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType ~= GameEffect.EFFECT_SELF_EFFECT then
            effectData.p_effectOrder = effectData.p_effectType
        end
    end
end

--localGame轮盘停下后 改变数据
function BaseMachine:MachineRule_localGame_stopReelChangeData()
end

---
-- 轮盘停下后 改变数据
--
function BaseMachine:MachineRule_stopReelChangeData()
end

function BaseMachine:getSymbolWinRate(enumLineInfo, symbolType, lineSymbolNum)
    return 0
end

function BaseMachine:getClientWinCoins()
    local winGetLines = self.m_vecGetLineInfo
    local lineLen = #winGetLines

    local clientWinCoins = 0 -- 客户端计算出来的钱， 暂时保留用来与服务器端进行对比
    for i = 1, lineLen, 1 do
        local enumLineInfo = winGetLines[i]

        local llTheSymbolWin = self:getSymbolWinRate(enumLineInfo, enumLineInfo.enumSymbolType, enumLineInfo.iLineSymbolNum)
        if llTheSymbolWin == nil then
            local llTheSymbolWin1 = self:getSymbolWinRate(enumLineInfo, enumLineInfo.enumSymbolType, enumLineInfo.iLineSymbolNum)
        end
        llTheSymbolWin = llTheSymbolWin * enumLineInfo.iLineMulti --*= 当前得分线的倍数！

        clientWinCoins = clientWinCoins + llTheSymbolWin * globalData.slotRunData:getCurTotalBet()
        --            end
    end -- end for
    return clientWinCoins
end

---
-- 计算最后赢的钱
--
function BaseMachine:calculateLastWinCoin()
    self.m_iOnceSpinLastWin = 0 -- 每次spin 赢得数据清0

    local clientWinCoins = self:getClientWinCoins()

    print("客户端赢钱为 = " .. clientWinCoins .. "   server端赢钱为=" .. self.m_serverWinCoins)
    if self.m_serverWinCoins ~= clientWinCoins then
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== server=" .. self.m_serverWinCoins .. "    client=" .. clientWinCoins .. " ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
    end

    self.m_iOnceSpinLastWin = self.m_serverWinCoins
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iOnceSpinLastWin )
end

function BaseMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 then
        notAdd = true
    end

    return notAdd
end
---
-- 增加赢钱后的 效果
function BaseMachine:addLastWinSomeEffect() -- add big win or mega win
    local notAddEffect = self:checkIsAddLastWinSomeEffect()

    if notAddEffect then
        return
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = self:getNewBingWinTotalBet()
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or self.m_fLastWinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
end

---
-- 点击快速停止reel
--
function BaseMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")

    local isDelayCall = false
    if self.m_bClickQuickStop ~= true then
        self.m_iBackDownColID = 1
        for iCol = self.m_iBackDownColID, #self.m_slotParents, 1 do
            local slotParentDatas = self.m_slotParents
            local index = iCol
            local parentData = slotParentDatas[index]
            local col = parentData.cloumnIndex
            local lastIndex = self.m_reelRunInfo[col]:getReelRunLen()
            if parentData.isDone == true and parentData.isResActionDone ~= true then
                isDelayCall = true
                self.m_iBackDownColID = math.max(col, self.m_iBackDownColID)
            end
        end
        -- if isDelayCall == true then
        --     self.m_iBackDownColID = self.m_iBackDownColID
        -- end

        if self.m_iBackDownColID >= self.m_iReelColumnNum and self.m_iBackDownColID ~= 1 then
            self.m_iBackDownColID = 1
            return
        end
    end

    if isDelayCall == true and self.m_bClickQuickStop ~= true then
        self.m_bClickQuickStop = true
    else
        if colIndex ~= nil then
            if colIndex == self.m_iBackDownColID then
                self:setGameSpinStage(QUICK_RUN) -- 已经处于快速停止状态了。。
                self.m_iBackDownColID = 1
                self.m_bClickQuickStop = false
                self:operaQuicklyStopReel()
            end
        else
            self:setGameSpinStage(QUICK_RUN) -- 已经处于快速停止状态了。。
            self.m_iBackDownColID = 1
            self.m_bClickQuickStop = false
            self:operaQuicklyStopReel()
        end
    end
end

--[[
    @desc: 计算快停时 当前滚动出来的轮盘各列分别需要向上补充的信号个数， 最大那一列不需要补充
    time:2019-03-28 15:57:22
    @return:  返回一个各列需要补充个数的数组，
]]
function BaseMachine:getFillTopNodeCountWithQuickStop()
    local maxTopY = 0

    local reelsFillCounts = {}
    local reelsTopYs = {}

    for i = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        local halfH = columnData.p_showGridH * 0.5

        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local childs = slotParent:getChildren()
        if slotParentBig then
            local newChilds = slotParentBig:getChildren()
            for j = 1, #newChilds do
                childs[#childs + 1] = newChilds[j]
            end
        end
        local preY = 0
        -- release_print("向上补充信息开始计算..")
        preY = self:getSlotNodeChildsTopY(childs)

        reelsTopYs[i] = preY

        maxTopY = util_max(maxTopY, preY)

        -- release_print("向上补充信息为 " .. i .. " preY = " .. preY )
    end

    for index = 1, self.m_iReelColumnNum do
        local reelTopY = reelsTopYs[index]
        local nodeCount = 0
        local parentData = self.m_slotParents[index]
        if maxTopY == reelTopY or self:checkColEnterLastReel(index) == true then
            reelsFillCounts[index] = nodeCount
        else
            local diffDis = maxTopY - reelTopY
            columnData = self.m_reelColDatas[index]
            nodeCount = math.floor(diffDis / columnData.p_showGridH)
            reelsFillCounts[index] = nodeCount
        end

        -- release_print("向上补充信息为 " .. index .. " 个数为 = " .. nodeCount )
    end

    return reelsFillCounts
end

function BaseMachine:getSlotNodeChildsTopY(childs)
    local maxTopY = 0
    for childIndex = 1, #childs do
        local child = childs[childIndex]
        local isVisible = child:isVisible()
        local childY = child:getPositionY()
        local topY = nil

        if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
            local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
            topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
        else
            topY = childY + child.p_slotNodeH * 0.5
        end
        -- if topY >= maxTopY then
        --     release_print("最大信号类型为" .. child.p_symbolType .. "")
        -- end
        maxTopY = util_max(maxTopY, topY)
    end
    return maxTopY
end

--[[
    @desc: 计算最终轮盘盘面各列需要向下补充的
    time:2019-03-28 15:59:34
    @return:
]]
function BaseMachine:getFillBottomNodeCountWithQuickStop()
    local filleCounts = {}
    local maxCount = 0
    for i = 1, self.m_iReelColumnNum do
        local columnDatas = self.m_reelSlotsList[i]
        local data = columnDatas[#columnDatas - self.m_iReelRowNum + 1]

        local fillCount = 0
        local symbolType = -1
        -- 这种情况是表明有些列根本没有滚动的最终信号
        if data == nil or tolua.type(data) == "number" then
            fillCount = 0
        else
            symbolType = data.p_symbolType

            if self.m_bigSymbolInfos[symbolType] ~= nil and self:checkColEnterLastReel(i) == false then
                local bigSymbolColData = self.m_bigSymbolColumnInfo[i]

                if bigSymbolColData ~= nil and #bigSymbolColData > 0 and bigSymbolColData[1].startRowIndex < 1 then
                    fillCount = 1 - bigSymbolColData[1].startRowIndex
                else
                    fillCount = 0
                end
            else
                fillCount = 0
            end
        end

        filleCounts[i] = fillCount
        -- release_print("向下补偿的数量信息为 " .. i .. " count= "..fillCount .. " 信号类型" .. symbolType)
        maxCount = util_max(fillCount, maxCount)
    end

    for i = 1, self.m_iReelColumnNum do
        if self:checkColEnterLastReel(i) == false then
            filleCounts[i] = maxCount -- - filleCounts[i]
        end
        -- release_print("向下补偿的数量信息为 列=" .. i .. " fillCount = " .. filleCounts[i])
    end

    return filleCounts
end
--[[
    @desc: 获取各列需要补充的node 数量 , 结算上下补偿数量的总和
    author:{author}
    time:2019-03-28 16:30:55
    @return:
]]
function BaseMachine:getColumnFillCounts()
    local topFillCounts = self:getFillTopNodeCountWithQuickStop()
    local bottomFileCounts = self:getFillBottomNodeCountWithQuickStop()
    local columnFillCounts = {}
    for i = 1, self.m_iReelColumnNum do
        columnFillCounts[i] = topFillCounts[i] + bottomFileCounts[i]
    end
    return columnFillCounts
end
--[[
    @desc: 检测对应列是否已经进入到了最后的真是轮盘
    time:2019-03-29 12:32:48
    --@col:
    @return:
]]
function BaseMachine:checkColEnterLastReel(col)
    -- local lastIndex = self.m_reelRunInfo[col]:getReelRunLen()
    local parentData = self.m_slotParents[col]
    -- if slotParentData.lastReelIndex <= lastIndex then
    --     return false
    -- end
    if parentData == nil or parentData.m_isLastSymbol == false then
        return false
    end
    return true
end
--[[
    @desc: 处理轮盘滚动中的快停，
    在快停前先检测各列需要补偿的nodecount 数量，一次来补齐各个高度同时需要考虑向下补偿的数量，这种处理
    主要是为了兼容长条模式
    time:2019-03-14 14:54:47
    @return:
]]
function BaseMachine:operaQuicklyStopReel()
    local slotParentDatas = self.m_slotParents
    local quickStopCol_CallFun = function(iCol)
        local index = iCol
        local reelRunData = self.m_reelRunInfo[index]

        local parentData = slotParentDatas[index]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local col = parentData.cloumnIndex
        local lastIndex = self.m_reelRunInfo[col]:getReelRunLen()
        -- - self.m_iReelRowNum
        --如果下个小块信号在最后一组 则不快停
        --不在最后一组则触发快停
        local parentPosY = slotParent:getPositionY()
        if parentData.isDone ~= true and parentData.isResActionDone ~= true then
            --改变下个创建信号

            -- if lastIndex  ~= parentData.lastReelIndex then
            -- print(iCol .."列 调整前的开始位置" .. parentData.lastReelIndex)
            -- fillCount

            local columnDatas = self.m_reelSlotsList[col]
            for i = lastIndex, 1, -1 do
                local data = columnDatas[i]
                if tolua.type(data) == "number" then
                    lastIndex = i
                    break
                end
            end
            parentData.lastReelIndex = lastIndex
            local columnData = self.m_reelColDatas[col]
            -- print(iCol .."列 调整前的坐标距离" ..  parentData.moveDistance .. "  " .. lastNodeTopY)
            local count = math.abs(parentPosY) / columnData.p_showGridH
            count = math.floor(count + 0.5)
            parentPosY = -count * columnData.p_showGridH

            self:createFinalResult(slotParent, slotParentBig, parentPosY, columnData, parentData)
            parentData.moveDistance = parentPosY
        -- -lastNodeTopY - fillCount * columnData.p_showGridH
        -- slotParent:stopAllActions()
        -- end
        end
    end

    for i = 1, #slotParentDatas do
        -- if slotParentDatas[i].isReeling == true then
        quickStopCol_CallFun(i)
        -- end
    end
end

-- 某些异形轮子快停处理
-- 根据列获得行
function BaseMachine:getFinalResultCurrReelRowNum(_iCol)
    return self.m_iReelRowNum
end

function BaseMachine:createFinalResultRemoveAllSlotNode(_slotParent, _slotParentBig)
    local childs = _slotParent:getChildren()
    if _slotParentBig then
        local newChilds = _slotParentBig:getChildren()
        for i = 1, #newChilds do
            childs[#childs + 1] = newChilds[i]
        end
    end

    for childIndex = 1, #childs do
        local child = childs[childIndex]
        child:setVisible(true)
        child:removeFromParent(false)
        local symbolType = child.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, child)
    end
end

function BaseMachine:createFinalResult(slotParent, slotParentBig, parentPosY, columnData, parentData)
    self:createFinalResultRemoveAllSlotNode(slotParent, slotParentBig)

    local index = 1
    while index <= self:getFinalResultCurrReelRowNum(parentData.cloumnIndex) do
        self:createSlotNextNode(parentData)

        local node = self:getSlotNodeWithPosAndType(parentData.symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
        local posY = columnData.p_showGridH * (parentData.rowIndex - 0.5) - parentPosY

        node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

        -- print("col == "..cloumnIndex.."  posY = "..posY.." index = "..index)

        node.p_cloumnIndex = parentData.cloumnIndex
        node.p_rowIndex = parentData.rowIndex
        node.m_isLastSymbol = parentData.m_isLastSymbol

        node.p_slotNodeH = columnData.p_showGridH
        node.p_symbolType = parentData.symbolType
        node.p_preSymbolType = parentData.preSymbolType
        node.p_showOrder = parentData.order

        node.p_reelDownRunAnima = parentData.reelDownAnima

        node.p_reelDownRunAnimaSound = parentData.reelDownAnimaSound
        node.p_layerTag = parentData.layerTag
        node:setTag(parentData.tag)
        node:setLocalZOrder(parentData.order)

        if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
            slotParentBig:addChild(node, parentData.order, parentData.tag)
        else
            slotParent:addChild(node, parentData.order, parentData.tag)
        end

        node:runIdleAnim()

        if parentData.isLastNode == true then -- 本列最后一个节点移动结束
            -- 执行回弹, 如果不执行回弹判断是否执行
            parentData.isReeling = false
            -- printInfo("xcyy 停下来的parent 位置为 : %d  %f  ", parentData.cloumnIndex,slotParent:getPositionY())
            -- 创建一个假的小块 在回滚停止后移除

            self:createResNode(parentData, node)
        end

        if self.m_bigSymbolInfos[parentData.symbolType] ~= nil then
            local addCount = self.m_bigSymbolInfos[parentData.symbolType]
            index = addCount + node.p_rowIndex
        else
            index = index + 1
        end
    end
    -- print("index = "..index)
    -- for i = 1, self.m_iReelRowNum, 1 do
    --     self:createSlotNextNode(parentData)

    --     local node = self:getSlotNodeWithPosAndType(parentData.symbolType,
    --                                     parentData.rowIndex,parentData.cloumnIndex,parentData.m_isLastSymbol)
    --     local posY = columnData.p_showGridH * (parentData.rowIndex - 0.5) - parentPosY

    --     node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

    --     node.p_cloumnIndex = parentData.cloumnIndex
    --     node.p_rowIndex = parentData.rowIndex
    --     node.m_isLastSymbol = parentData.m_isLastSymbol

    --     node.p_slotNodeH = columnData.p_showGridH
    --     node.p_symbolType = parentData.symbolType
    --     node.p_preSymbolType = parentData.preSymbolType
    --     node.p_showOrder = parentData.order

    --     node.p_reelDownRunAnima = parentData.reelDownAnima

    --     node.p_reelDownRunAnimaSound = parentData.reelDownAnimaSound
    --     node.p_layerTag = parentData.layerTag
    --     node:setTag(parentData.tag)
    --     node:setLocalZOrder(parentData.order)

    --     if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
    --         slotParentBig:addChild(node, parentData.order, parentData.tag)
    --     else
    --         slotParent:addChild(node, parentData.order, parentData.tag)
    --     end

    --     node:runIdleAnim()

    --     if parentData.isLastNode == true then -- 本列最后一个节点移动结束
    --         -- 执行回弹, 如果不执行回弹判断是否执行
    --         parentData.isReeling = false
    --         -- printInfo("xcyy 停下来的parent 位置为 : %d  %f  ", parentData.cloumnIndex,slotParent:getPositionY())
    --         -- 创建一个假的小块 在回滚停止后移除

    --         self:createResNode(parentData, node)
    --     end
    -- end
end

--[[
    @desc: 检测接下来需要补充的假信号是否是争取的， 主要是为了有大信号(占多个格子) 创建时出现问题
    time:2019-03-28 16:43:33
    @param fillCount 需要补充的信号数量
    @param col 对应列号
    @return:
]]
function BaseMachine:checkFillCountType(parentData, col, fillCount)
    local beginIndex = parentData.lastReelIndex + 1
    local columnDatas = self.m_reelSlotsList[col]
    local lastIndex = self.m_reelRunInfo[col]:getReelRunLen()

    for checkIndex = beginIndex, beginIndex + fillCount - 1 do
        local symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
        while true do
            symbolType = self:getReelSymbolType(parentData)
            if self.m_bigSymbolInfos[symbolType] == nil then
                break
            end
        end

        if checkIndex > lastIndex then -- 这里用来保证不会影响到最终轮盘的结果， lastIndex 表明的是最后的假滚数据
            -- 如果不够补偿了 那么在多滚动几个保持补偿后的数量一致可以一起滚动停止
            table.insert(columnDatas, checkIndex, symbolType)
        else
            local data = columnDatas[checkIndex]
            if data then
                if tolua.type(data) == "number" or self.m_bigSymbolInfos[data.p_symbolType] == nil then
                    columnDatas[checkIndex] = symbolType
                end
            end
        end
    end

    -- release_print("checkFillCountType  ....." .. col)
    -- dump(columnDatas)
    -- release_print("checkFillCountType  ..... END" .. col)
end

--[[
    @desc: 检测是否需要停掉各列滚动开始的等待
    author:{author}
    time:2019-03-28 16:29:16
    @return:
]]
function BaseMachine:checkStopDelayTime()
    local slotParentDatas = self.m_slotParents

    -- 先处理下各列轮盘滚动需要等待时间的情况
    if self.m_configData.p_quickStopDelayTime > 0 then
        for i = 1, #slotParentDatas do
            local parentData = slotParentDatas[i]
            local slotParent = parentData.slotParent

            if self.m_reelDelayTime > 0 and i > 1 then -- 先让他们滚动起来 ，这样计算就统一了
                local clipNode = slotParent:getParent()
                clipNode:stopAllActions()

                if parentData.isReeling == false then
                    parentData.isReeling = true
                    self:createSlotNextNode(parentData)
                end
            end
        end
    end
end

---
-- 点击spin 按钮开始执行老虎机逻辑
--
function BaseMachine:normalSpinBtnCall()
    --暂停中点击了spin不自动开始下一次
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.normalSpinBtnCall then
                self:normalSpinBtnCall()
            end
        end
        return
    end

    print("触发了 normalspin")

    local time1 = xcyy.SlotsUtil:getMilliSeconds()

    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end

    local isContinue = true
    if globalData.slotRunData.currSpinMode == NORMAL_SPIN_MODE then
        if self.m_showLineFrameTime ~= nil then
            local waitTime = time1 - self.m_showLineFrameTime
            if waitTime < (self.m_lineWaitTime * 1000) then
                isContinue = false --时间不到，spin无效
            end
        end
    end

    if not isContinue then
        return
    end
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    -- 引导打点：进入关卡-4.点击spin
    if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.noobTaskStart1) then
        gLobalSendDataManager:getLogGuide():sendGuideLog(1, 4)
    end
    --新手引导相关
    local isComplete = globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskStart1, true)
    if isComplete then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWBIE_TASK_TIPS, {1, false})
    end
    if self.m_isWaitingNetworkData == true then -- 真实数据未返回，所以不处理点击
        return
    end

    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)

        self.m_showLineHandlerID = nil
    end

    local time2 = xcyy.SlotsUtil:getMilliSeconds()
    release_print("normalSpinBtnCall 消耗时间1 .. " .. (time2 - time1))

    if self:getGameSpinStage() == WAIT_RUN then
        return
    end

    self:firstSpinRestMusicBG()

    local isWaitCall = self:MachineRule_SpinBtnCall()
    if isWaitCall == false then
        self:callSpinBtn()
    else
        self:setGameSpinStage(WAIT_RUN)
    end

    local timeend = xcyy.SlotsUtil:getMilliSeconds()

    release_print("normalSpinBtnCall 消耗时间4 .. " .. (timeend - time1) .. " =========== ")
end

function BaseMachine:callSpinTakeOffBetCoin(betCoin)
    local curCoinNum = globalData.userRunData.coinNum
    globalData.coinsSoundType = 1
    -- 立即更改金币数量
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, curCoinNum - betCoin)
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {varCoins = -betCoin})
    -- 增加task 统计
    -- gLobalTaskManger:triggerTask(TASK_SPIN_TIMES)

    -- 这两个方法需要转移到spin结果回来之后再进行处理 csc 2020年11月18日18:04:28
    -- self:calculateSpinData()
    -- --增加新手任务进度
    -- self:checkIncreaseNewbieTask()

    if globalData.slotRunData.m_isNewAutoSpin then
        --autospin次数统计
        if globalData.slotRunData.m_autoNum and globalData.slotRunData.m_autoNum > 0 then
            globalData.slotRunData.m_autoNum = globalData.slotRunData.m_autoNum - 1
        else
            globalData.slotRunData.m_autoNum = 0
            globalData.slotRunData.m_isAutoSpinAction = false
            if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
                globalData.slotRunData.currSpinMode = NORMAL_SPIN_MODE
            end
        end
    end
end

--增加新手任务进度
function BaseMachine:checkIncreaseNewbieTask()
    local sysNoviceTaskMgr = G_GetMgr(G_REF.SysNoviceTask)
    if sysNoviceTaskMgr and sysNoviceTaskMgr:checkEnabled() then
        -- 新版 服务器会同步增加， 不需要客户端自己记录计算
        return
    end

    globalNewbieTaskManager:increasePool(NewbieTaskType.spin_count, 1, self.m_moduleName)
    if self.m_spinIsUpgrade then
        globalNewbieTaskManager:increasePool(NewbieTaskType.reach_level, self.m_spinNextLevel - self.m_upgradePreLevel, self.m_moduleName)
    end
    local taskData = globalNewbieTaskManager:getCurrentTaskData()
    if taskData and taskData:checkUnclaimed() then
        if self.m_spinIsUpgrade then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPLEVEL_STATUS, {level = self.m_spinNextLevel, type = 1})
        end
        self:addAnimationOrEffectType(GameEffect.EFFECT_NEWBIETASK_COMPLETE)
    end
end

function BaseMachine:getSpinCostCoins()
    local betValue = globalData.slotRunData:getCurTotalBet()
    -- local minzMgr = G_GetMgr(ACTIVITY_REF.Minz)
    -- if minzMgr then
    --     local percent = minzMgr:getMinzBetPercent()
    --     betValue = betValue + betValue * percent
    -- end
    local extraPercent = G_GetMgr(G_REF.BetExtraCosts):getExtraPercent()
    if extraPercent and extraPercent > 0 then
        betValue = betValue + betValue * extraPercent
    end    
    return toLongNumber(betValue)
end

function BaseMachine:notifyClearBottomWinCoin()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    else
        local isClearWin = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, isClearWin)
    end
    -- 不在区分是不是在 freespin下了 2019-05-08 20:56:44
end

---
--没钱弹广告
function BaseMachine:showLuckyVedio()
    if globalData.adsRunData:isPlayRewardForPos(PushViewPosType.NoCoinsToSpin) then
        gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.NoCoinsToSpin)
        gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
        gLobalAdsControl:playVideo(AdsRewardDialogType.Normal, PushViewPosType.NoCoinsToSpin)
        gLobalSendDataManager:getLogAds():createPaySessionId()
        gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.NoCoinsToSpin)
        gLobalSendDataManager:getLogAds():setOpenType("PushOpen")
    -- globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.NoCoinsToSpin})
    end
end

function BaseMachine:checkSpecialSpin()
    return self.m_specialSpinStates
end

function BaseMachine:setSpecialSpinStates(_bool)
    self.m_specialSpinStates = _bool
end

function BaseMachine:callSpinBtn()
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        for i = 1, #self.m_reelRunInfo do
            self.m_reelRunInfo[i]:setReelRunLenToAutospinReelRunLen()
        end
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        for i = 1, #self.m_reelRunInfo do
            self.m_reelRunInfo[i]:setReelRunLenToFreespinReelRunLen()
        end
    end

    -- 去除掉 ， auto和 freespin的倒计时监听
    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    self:notifyClearBottomWinCoin()

    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1

    -- freespin时不做钱的计算
    if
        not self:checkSpecialSpin() and self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE and betCoin > totalCoin and
            self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE
     then
        self:operaUserOutCoins()
    else
        if
            self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
                not self:checkSpecialSpin()
         then
            self:callSpinTakeOffBetCoin(betCoin)
        else
            self:takeSpinNextData()
        end

        --统计quest spin次数
        self:staticsQuestSpinData()

        self:spinBtnEnProc()

        self:setGameSpinStage(GAME_MODE_ONE_RUN)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        globalData.userRate:pushSpinCount(1)
        globalData.userRate:pushUsedCoins(betCoin)
        globalData.rateUsData:addSpinCount()
    end
    -- 修改freespin count 的信息
    self:checkChangeFsCount()

    -- 修改 respin count 的信息
    self:checkChangeReSpinCount()
end

--[[
    @desc: 记录spin 后的数据
    time:2020-07-21 20:32:55
    @return:
]]
function BaseMachine:takeSpinNextData()
    self.m_spinNextLevel = globalData.userRunData.levelNum
    self.m_spinNextProVal = globalData.userRunData.currLevelExper
    self.m_spinIsUpgrade = false
end

--[[
    @desc: 处理用户没钱的逻辑
    time:2020-07-21 20:30:01
    @return:
]]
function BaseMachine:operaUserOutCoins()
    --金币不足
    -- gLobalTriggerManager:triggerShow({viewType=TriggerViewType.Trigger_NotEnoughSpin})
    gLobalPushViewControl:showView(PushViewPosType.NoCoinsToSpin)
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NoCoins)
    end

    gLobalPushViewControl:setEndCallBack(
        function()
            local betCoin = self:getSpinCostCoins() or toLongNumber(0)
            local totalCoin = globalData.userRunData.coinNum or 1
            if betCoin <= totalCoin then
                globalData.rateUsData:resetBankruptcyNoPayCount()
                self:showLuckyVedio()
                return
            end

            -- cxc 2023年12月02日13:57:48 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
            globalData.rateUsData:addBankruptcyNoPayCount()
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Bankruptcy", "BankruptcyNoPay_" .. globalData.rateUsData:getBankruptcyNoPayCount())
            if view then
                view:setOverFunc(function()
                    self:showLuckyVedio()
                end)
            else
                self:showLuckyVedio()
            end
        end
    )

    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    end
end

function BaseMachine:checkChangeFsCount()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and globalData.slotRunData.freeSpinCount ~= nil and globalData.slotRunData.freeSpinCount > 0 then
        --减少free spin 次数
        globalData.slotRunData.freeSpinCount = globalData.slotRunData.freeSpinCount - 1
        print(" globalData.slotRunData.freeSpinCount = globalData.slotRunData.freeSpinCount - 1")
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        globalData.userRate:pushFreeSpinCount(1)
    end
end

function BaseMachine:checkChangeReSpinCount()
    if self:getCurrSpinMode() == RESPIN_MODE then
        --减少free spin 次数
        globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount - 1
        gLobalNoticManager:postNotification(ViewEventType.SHOW_RESPIN_SPIN_NUM)
    end
end

function BaseMachine:getSpinAddExpRate()
    local addExpRate = self:getRunCsvData().line_num * self.m_expMultiNum

    return addExpRate
end

--[[
    @desc: 计算spin 消耗钱 新的计算方式 ,放置在spin 数据返回之后调用
    time:2020-11-18 17:19:32
    @return:
]]
function BaseMachine:calculateSpinDataV2()
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        -- 这种情况下 不应该进来

        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()

    --增加获取最新的数据
    local currLevel = globalData.userRunData.levelNum
    local currProVal = globalData.userRunData.currLevelExper
    if not currProVal then
        return
    end
    local totalProVal = globalData.userRunData:getPassLevelNeedExperienceVal()

    -- 添加的经验 (没升级的情况下)
    local addBetExp = currProVal - self.m_spinBeforeProVal

    local isUpgrade = false
    if self.m_spinBeforeLevel < currLevel then
        -- 证明升级了
        isUpgrade = true
        -- 升级后添加经验 = 升级前差的 + 升级后多出来的
        addBetExp = self.m_spinBeforeTotalProVal - self.m_spinBeforeProVal + currProVal
    end

    -- 记录下spin 后金钱和等级经验的数据
    self.m_spinNextLevel = currLevel
    self.m_spinNextProVal = currProVal
    self.m_spinIsUpgrade = isUpgrade
    if self.m_totalEndUpGrade == nil then -- 每次spin流程彻底结束时  freespin  respin 多次视为一次
        self.m_totalEndUpGrade = isUpgrade
    end

    self:addAnimationOrEffectType(GameEffect.EFFECT_PushSlot)

    if isUpgrade == true then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.Levelup)

        self.m_upgradePreLevel = globalData.userRunData.levelNum - 1
        self.m_unLockPreLevel = globalData.userRunData.levelNum - 1
        -- 升级
        self:addAnimationOrEffectType(GameEffect.EFFECT_LEVELUP)
        if self.m_upgradePreLevel < globalData.constantData.OPENLEVEL_DAILYMISSION and self.m_spinNextLevel >= globalData.constantData.OPENLEVEL_DAILYMISSION then
            self:addAnimationOrEffectType(GameEffect.MISSION_LOCK_OPEN)
        end
        -- 判断提升的等级是否可以解锁下一个关卡  .  curLevel

        local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()

        if questConfig and questConfig.m_IsQuestLogin then
            -- elseif questNewUserConfig and questNewUserConfig.m_IsQuestLogin then
            -- 活动进入的关卡， 不做 关卡解锁提示
        elseif G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest() then
            -- 活动进入的关卡， 不做 关卡解锁提示
        elseif self.m_spinNextLevel == 2 or self.m_spinNextLevel == 5 then
            --2级不提示解锁关卡
        else
            local levels = globalData.slotRunData.p_machineDatas
            local curCount = 0
            local nextCount = 0
            for i = 1, #levels do
                if levels[i].p_openLevel <= self.m_upgradePreLevel then
                    curCount = curCount + 1
                end
                if levels[i].p_openLevel <= self.m_spinNextLevel then
                    nextCount = nextCount + 1
                end
            end
            if curCount ~= nextCount then
                self:addAnimationOrEffectType(GameEffect.EFFECT_Unlock)
            end
        end
    end
    -- 通知经验等级变化
    gLobalNoticManager:postNotification(
        ViewEventType.NOTIFY_UPDATE_EXP_PRO,
        {
            addBetExp,
            isUpgrade,
            currLevel,
            currProVal
        }
    )
end

function BaseMachine:getFreeSpinCount()
    return globalData.slotRunData.freeSpinCount
end

function BaseMachine:changeToRewardReSpinMode()
    self:setCurrSpinMode(REWAED_SPIN_MODE)
end
function BaseMachine:resetReSpinMode()
    if self.m_bProduceSlots_InFreeSpin == true then
        self:setCurrSpinMode(FREE_SPIN_MODE)
    else
        -- print("NORMAL_SPIN_MODE")
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
    end

    self.m_reSpinsTotalCount = 0
    self.m_reSpinCurCount = 0

    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()
end

---
--
function BaseMachine:MachineRule_SpinBtnCall()
    return false
end

---
-- 处理点击逻辑
--
function BaseMachine:spinBtnEnProc()
    --TODO 处理repeat逻辑

    if self.m_isChangeBGMusic then
        -- gLobalSoundManager:playFreeSpinBackMusic(self:getFreeSpinMusicBG())

        self.m_currentMusicId = gLobalSoundManager:playBgMusic(self:getFreeSpinMusicBG())

        self.m_isChangeBGMusic = false
    end
    self:beginReel()
end

--------------------------------------------ReSpin----------------------------------------------
local ENUM_TOUCH_STATUS = {
    UNDO = 1, ---等待状态 不允许点击
    ALLOW = 2, ---允许点击
    WATING = 3, --等待滚动
    RUN = 4, ---滚动状态
    QUICK_STOP = 5 ---快滚状态
}
local BASE_RUN_NUM = 20
BaseMachine.m_RESPIN_RUN_TIME = 1.2
BaseMachine.m_RESPIN_WAIT_TIME = 1
BaseMachine.m_reSpinEndType = nil
BaseMachine.m_respinNodeInfo = nil
BaseMachine.m_randomFixList = nil
BaseMachine.m_iReSpinScore = nil
BaseMachine.m_specialReels = nil

BaseMachine.m_respinEndSound = nil
function BaseMachine:getIsFixPos(iRow, iCol)
    local allFixPos = self.m_runSpinResultData.p_storedIcons
    if allFixPos ~= nil then
        for i = 1, #allFixPos do
            local fixPos = self:getRowAndColByPos(allFixPos[i])
            if iCol == fixPos.iY and iRow == fixPos.iX then
                return true
            end
        end
    end
    return false
end

function BaseMachine:getMatrixPosSymbolType(iRow, iCol,reels)
    local tarReel = reels or self.m_runSpinResultData.p_reels
    local rowCount = #tarReel 
    for rowIndex = 1, rowCount do
        local rowDatas = tarReel[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end

function BaseMachine:getRandomList()
    local allFixPos = self.m_preReSpinStoredIcons

    -- self.m_runSpinResultData.p_storedIcons
    if self.m_preReSpinStoredIcons ~= nil then
        for i = 1, #self.m_runSpinResultData.p_storedIcons do
            local checkStoredIndex = self.m_runSpinResultData.p_storedIcons[i]
            local isNewStored = true
            for j = 1, #self.m_preReSpinStoredIcons do
                local preStoredIndex = self.m_preReSpinStoredIcons[j]
                if checkStoredIndex == preStoredIndex then
                    isNewStored = false

                    break
                end
            end

            if isNewStored == true then
                allFixPos[#allFixPos + 1] = checkStoredIndex
            end
        end
    end

    self.m_randomFixList = {}
    if allFixPos ~= nil then
        for index = 1, #allFixPos do
            local fixPos = self:getRowAndColByPos(allFixPos[index])
            self.m_randomFixList[#self.m_randomFixList + 1] = {x = fixPos.iX, y = fixPos.iY}
        end
    end
end

--开始滚动
function BaseMachine:startReSpinRun()
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    self:requestSpinReusltData()
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end

    self.m_respinView:startMove()
end

function BaseMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local index = 0
    local storedInfo = {}
    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            for i = 1, #storedIcons do
                if storedIcons[i] == index then
                    local type = self:getMatrixPosSymbolType(iRow, iCol)

                    local pos = {iX = iRow, iY = iCol, type = type}
                    storedInfo[#storedInfo + 1] = pos
                end
            end
            index = index + 1
        end
    end
    return storedInfo
end

function BaseMachine:getRespinReelsButStored(storedInfo)
    local reelData = {}
    local function getIsInStore(iRow, iCol)
        for i = 1, #storedInfo do
            local storeIcon = storedInfo[i]
            if storeIcon.iX == iRow and storeIcon.iY == iCol then
                return true
            end
        end
        return false
    end

    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            local type = self:getMatrixPosSymbolType(iRow, iCol)
            if getIsInStore(iRow, iCol) == false then
                local pos = {iX = iRow, iY = iCol, type = type}
                reelData[#reelData + 1] = pos
            end
        end
    end
    return reelData
end

BaseMachine.m_respinView = nil
--触发respin
function BaseMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:changeTouchSpinLayerSize()

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)
end

function BaseMachine:getRespinView()
    return "Levels.RespinView"
end

function BaseMachine:getRespinNode()
    return "Levels.RespinNode"
end

function BaseMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            self:showReSpinStart(
                function()
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    -- 更改respin 状态下的背景音乐
                    self:changeReSpinBgMusic()
                    self:runNextReSpinReel()
                end
            )
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

function BaseMachine:reSpinEffectChange()
end

function BaseMachine:playRespinViewShowSound()
end

function BaseMachine:showReSpinStart(func)
end
---
function BaseMachine:triggerChangeRespinNodeInfo(respinNodeInfo)
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function BaseMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end

--隐藏盘面信息
function BaseMachine:setReelSlotsNodeVisible(status)
    for iCol = 1, self.m_iReelColumnNum do
        local childs = self:getReelParent(iCol):getChildren()
        for j = 1, #childs do
            local node = childs[j]
            node:setVisible(status)
        end
        local slotParentBig = self:getReelBigParent(iCol)
        if slotParentBig then
            local childs = slotParentBig:getChildren()
            for j = 1, #childs do
                local node = childs[j]
                node:setVisible(status)
            end
        end
    end

    --如果为空则从 clipnode获取
    local childs = self.m_clipParent:getChildren()
    local childCount = #childs

    for i = 1, childCount, 1 do
        local slotsNode = childs[i]
        if slotsNode:getTag() > SYMBOL_FIX_NODE_TAG and slotsNode:getTag() < SYMBOL_NODE_TAG then
            slotsNode:setVisible(status)
        end
    end
end

--接收到数据开始停止滚动
function BaseMachine:stopRespinRun()
    local storedNodeInfo = self:getRespinSpinData()
    local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)
    self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels)
end

--- respin 快停
function BaseMachine:quicklyStop()
    self.m_respinView:quicklyStop()
end

function BaseMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    if self.m_serverWinCoins ~= score then
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== respin  server=" .. self.m_serverWinCoins .. "    client=" .. score .. " ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
    end

    local coins = nil
    if self.m_bProduceSlots_InFreeSpin then
        coins = self:getLastWinCoin() or 0
        local addCoin = self.m_serverWinCoins
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
    else
        coins = self.m_serverWinCoins or 0

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    self:postReSpinOverTriggerBigWIn(coins)
    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

--开始下次ReSpin
function BaseMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end
    self.m_beginStartRunHandlerID =
        scheduler.performWithDelayGlobal(
        function()
            if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
                self:startReSpinRun()
            end
            self.m_beginStartRunHandlerID = nil
        end,
        self.m_RESPIN_RUN_TIME,
        self:getModuleName()
    )
end

--respin固定元素
function BaseMachine:heldOnAllScore()
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        return
    end

    self.m_heldOnScores = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local fixSymbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if fixSymbol and fixSymbol.p_symbolType == self.m_reSpinEndType then
                fixSymbol:setLocalZOrder(fixSymbol:getLocalZOrder() + 1000)
                fixSymbol.m_symbolTag = SYMBOL_FIX_NODE_TAG
                fixSymbol.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                fixSymbol.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE

                self.m_heldOnScores[#self.m_heldOnScores + 1] = fixSymbol
            end
        end
    end
end

---判断结算
function BaseMachine:reSpinReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})

    self:setGameSpinStage(STOP_RUN)

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

        --quest
        self:updateQuestBonusRespinEffectData()

        --结束
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false

        return
    end

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    end
    --    --下轮数据
    --    self:operaSpinResult()
    --    self:getRandomList()
    --继续
    self:runNextReSpinReel()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
end

--
function BaseMachine:respinOver()
    self:setReelSlotsNodeVisible(true)

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:removeRespinNode()
    self:showRespinOverView()
end
---------------------------------------------removeRespinNode start
--respin结束 移除respin小块对应位置滚轴中的小块
function BaseMachine:checkRemoveReelNode(node)
    local targSp = self:getReelParent(node.p_cloumnIndex):getChildByTag(self:getNodeTag(node.p_cloumnIndex, node.p_rowIndex, SYMBOL_NODE_TAG))
    local slotParentBig = self:getReelBigParent(node.p_cloumnIndex)
    if targSp == nil and slotParentBig then
        targSp = slotParentBig:getChildByTag(self:getNodeTag(node.p_cloumnIndex, node.p_rowIndex, SYMBOL_NODE_TAG))
    end
    if targSp then
        targSp:removeFromParent(false)
        self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
    end
end
--获得respin小块放回滚轴时的层级
function BaseMachine:getChangeRespinOrder(node)
    --有特殊需求可以根据node.p_cloumnIndex node.p_rowIndex node.p_symbolType手动修改层级
    return REEL_SYMBOL_ORDER.REEL_ORDER_2
end
--respin结束 把respin小块放回对应滚轴位置
function BaseMachine:checkChangeRespinFixNode(node)
    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local showOrder = self:getChangeRespinOrder(node)
    local posX, posY = node:getPosition()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = self:getReelParent(node.p_cloumnIndex):convertToNodeSpace(worldPos)
    node.m_symbolTag = SYMBOL_NODE_TAG
    node.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node.m_isLastSymbol = false
    node.m_bRunEndTarge = false
    local columnData = self.m_reelColDatas[node.p_cloumnIndex]
    node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    self:changeBaseParent(node)
    node:setPosition(nodePos)
end
--新滚动使用 裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
function BaseMachine:changeBaseParent(slotNode)
    if tolua.isnull(slotNode) or not slotNode.p_symbolType or not slotNode.p_cloumnIndex then
        --小块不存在 没有类型 或者没有所在列跳过
        return
    end
    local cloumnIndex = slotNode.p_cloumnIndex
    local symbolType = slotNode.p_symbolType
    local showOrder = slotNode.p_showOrder
    local slotParentBig = self.m_slotParents[cloumnIndex].slotParentBig
    if slotParentBig and self.m_configData:checkSpecialSymbol(symbolType) then
        util_changeNodeParent(slotParentBig, slotNode, showOrder)
    else
        util_changeNodeParent(self.m_slotParents[cloumnIndex].slotParent, slotNode, showOrder)
    end
    slotNode:setTag(cloumnIndex * SYMBOL_NODE_TAG + slotNode.p_rowIndex)
end
--新滚动使用 重新初始化盘面使用
function BaseMachine:removeAllGridNodes()
end
--播放respin放回滚轴后播放的提示动画
function BaseMachine:checkRespinChangeOverTip(node, endAnimaName, loop)
    if type(endAnimaName) == "string" and endAnimaName ~= "" then
        node:runAnim(endAnimaName, loop)
    end
end
--结束移除小块调用结算特效
function BaseMachine:removeRespinNode()
    if self.m_respinView == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNode = self.m_respinView:getAllEndSlotsNode()
    for i = 1, #allEndNode do
        local node = allEndNode[i]
        local endAnimaName, loop = node:getSlotsNodeAnima()
        --respin结束 移除respin小块对应位置滚轴中的小块
        self:checkRemoveReelNode(node)
        --respin结束 把respin小块放回对应滚轴位置
        self:checkChangeRespinFixNode(node)
        --播放respin放回滚轴后播放的提示动画
        self:checkRespinChangeOverTip(node)
    end
    self.m_respinView:removeFromParent()
    self.m_respinView = nil
end
---------------------------------------------removeRespinNode end
function BaseMachine:reSpinEndAction()
    self:respinOver()
end

function BaseMachine:MachineRule_respinTouchSpinBntCallBack()
    if self.m_respinView and self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
        if self.m_beginStartRunHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
            self.m_beginStartRunHandlerID = nil
        end
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)
        self:startReSpinRun()
    elseif self.m_respinView and self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        --快停
        self:quicklyStop()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    elseif not self.m_respinView then
        release_print("当前出错关卡名称:" .. self:getModuleName())
    end
end

--如果是大图隐藏中心图片
function BaseMachine:reSpinFixHideBigSymbol(node, targSp)
    -- if targSp.p_symbolType==self.SYMBOL_3X3_BIG_SYMBOL then
    --     node:setVisible(false)
    -- end
end
--ReSpin开始改变UI状态
function BaseMachine:changeReSpinStartUI(curCount)
end
--ReSpin刷新数量
function BaseMachine:changeReSpinUpdateUI(curCount)
    -- self.m_reSpinBar:toAction("3show")
    -- print("当前展示位置信息  %d ", curCount)
    -- self.m_reSpinBar:updateLeftCount(curCount)
end
--ReSpin结算改变UI状态
function BaseMachine:changeReSpinOverUI()
    -- self.m_reSpinBar:setVisible(false)
    -- if self:getCurrSpinMode() == FREE_SPIN_MODE then
    --     self.m_freeSpinBar:setVisible(true)
    -- end
    -- self.m_reSpinBar:updateWinCount(0)
end

--respin 模式下更换背景音乐
function BaseMachine:changeReSpinBgMusic()
    if self.m_rsBgMusicName ~= nil then
        self.m_currentMusicBgName = self.m_rsBgMusicName
        self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_rsBgMusicName)
    end
end

-- 特殊信号下落时播放的音效
function BaseMachine:playScatterBonusSound(slotNode)
    if slotNode ~= nil then
        local iCol = slotNode.p_cloumnIndex
        local soundPath = nil
        local soundType = slotNode.p_symbolType
        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if self.m_scatterBulingSoundArry == nil or not tolua.isnull(self.m_scatterBulingSoundArry) then
                return
            end

            self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1
            if self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin] ~= nil then
                soundPath = self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin]
            elseif self.m_scatterBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_scatterBulingSoundArry["auto"]
            else
                soundPath = SOUND_ENUM.MUSIC_SPECIAL_BONUS
            end
        elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
                return
            end
            self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
            if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
                soundPath = self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
            elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_bonusBulingSoundArry["auto"]
            else
                soundPath = SOUND_ENUM.MUSIC_SPECIAL_BONUS
            end
        end

        if soundPath then
            self:playBulingSymbolSounds(iCol, soundPath, soundType)
        end
    end
end
--21.12.06-播放不影响老关的落地音效逻辑
function BaseMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            if symbolCfg then
                local iCol = _slotNode.p_cloumnIndex
                local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                if soundPath then
                    self:playBulingSymbolSounds(iCol, soundPath, nil)
                end
            end
        end
    end
end
-- 有特殊需求判断的 重写一下
function BaseMachine:checkSymbolBulingSoundPlay(_slotNode)
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
                return true
            end
        end
    end

    return false
end
--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function BaseMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --1.提层-不论播不播落地动画先处理提层
                if symbolCfg[1] then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                    _slotNode:setPositionY(curPos.y)

                    --连线坐标
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = _slotNode.p_rowIndex, iY = _slotNode.p_cloumnIndex}
                    _slotNode.m_bInLine = true
                    _slotNode:setLinePos(linePos)

                    --回弹
                    local newSpeedActionTable = {}
                    for i = 1, #speedActionTable do
                        if i == #speedActionTable then
                            -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
                            local resTime = self.m_configData.p_reelResTime
                            local index = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
                            local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
                            newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
                        else
                            newSpeedActionTable[i] = speedActionTable[i]
                        end
                    end

                    local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
                    _slotNode:runAction(actSequenceClone)
                end
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                --2.播落地动画
                self:playBulingAnimFunc(_slotNode,symbolCfg)
            end
        end
    end
end

function BaseMachine:playBulingAnimFunc(_slotNode,_symbolCfg)
    _slotNode:runAnim(
        _symbolCfg[2],
        false,
        function()
            self:symbolBulingEndCallBack(_slotNode)
        end
    )
end

function BaseMachine:checkSymbolBulingAnimPlay(_slotNode)
    -- 和音效保持一致
    return self:checkSymbolBulingSoundPlay(_slotNode)
end
-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function BaseMachine:symbolBulingEndCallBack(_slotNode)
end

function BaseMachine:isNormalSpinTriggerFreeSpin()
    local haveFreespin = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)

    if haveFreespin and self.m_bProduceSlots_InFreeSpin == false then
        return true
    end
    return false
end

function BaseMachine:staticsQuestEffect()
end

function BaseMachine:getFreatureIsRepin()
    local freature = self.m_runSpinResultData.p_features
    if freature[1] and freature[1] == 0 then
        if freature[2] and freature[2] == 3 then
            return true
        end
    end
    return false
end

function BaseMachine:getSpinAction()
    local spinStatus = SPIN
    if self:getCurrSpinMode() == RESPIN_MODE then
        spinStatus = RESPIN
    elseif self.m_bProduceSlots_InFreeSpin == true then
        spinStatus = FREE_SPIN
    end
    return spinStatus
end

function BaseMachine:getPosReelIdx(iRow, iCol)
    local index = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + (iCol - 1)
    return index
end

function BaseMachine:resetFreespinTimes(newFreespinTimes)
    self.m_totleFsCount = newFreespinTimes
    self.m_resetFreespinTimes = newFreespinTimes
    globalData.slotRunData.freeSpinCount = newFreespinTimes
    print("resetFreespinTimes")
    globalData.slotRunData.totalFreeSpinCount = globalData.slotRunData.totalFreeSpinCount + newFreespinTimes
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
end

--respinCount
function BaseMachine:getRepsinWins()
    return 0
end

---respin数据
function BaseMachine:getLocalGameReSpinStoredIcons(...)
    -- body
    return {}
end

---respinFeature
function BaseMachine:getRespinFeature(...)
    return {0}
end

--------
--RESPIN信息
function BaseMachine:getUnRespinNodePos()
    local lockPos = {}
    for i = 1, #self.m_allLockNodeReelPos do
        local idx = self.m_allLockNodeReelPos[i]
        lockPos[idx] = i
    end

    local unLockPos = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local reelIdx = self:getPosReelIdx(iRow, iCol)
            if lockPos[reelIdx] == nil then
                unLockPos[#unLockPos + 1] = {iX = iRow, iY = iCol}
            end
        end
    end
    return unLockPos
end

--[[
    @desc: 如果触发了 freespin 时，将本次触发的bigwin 和 mega win 去掉
    time:2019-01-22 15:31:18
    @return:
]]
function BaseMachine:checkRemoveBigMegaEffect()
    local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
    if hasFsEffect == true then
        if self.m_bProduceSlots_InFreeSpin == false then
            self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
            self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
            self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
            self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
            self.m_bIsBigWin = false
        end
    end

    -- 如果处于 freespin 中 那么大赢都不触发
    local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
    if hasFsOverEffect == true then -- or  self.m_bProduceSlots_InFreeSpin == true
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
        self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_bIsBigWin = false
    end
end

function BaseMachine:getStaticsBetRate()
    return 1
end

---统计每日任务
-- function BaseMachine:staticsTasksData() -- r

--     local wildNum = 0
--     local scatterNum = 0
--     for iCol = 1, self.m_iReelColumnNum do
--         for iRow = 1, self.m_iReelRowNum do
--             local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
--             if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
--                 scatterNum = scatterNum + 1
--             end

--             if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
--                 wildNum = wildNum + 1
--             end
--         end
--     end
--     if scatterNum > 0 then

--     end

-- end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function BaseMachine:specialSymbolActionTreatment(node)
    -- print("dada")
end

-- 处理特殊关卡 遮罩层级
function BaseMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
    slotParent:getParent():setLocalZOrder(zOrder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

function BaseMachine:stopLinesWinSound()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    if self.m_delayHandleId then
        scheduler.unscheduleGlobal(self.m_delayHandleId)
        self.m_delayHandleId = nil
    end
end

function BaseMachine:playEnterGameSound(path)
    if not self.m_beInSpecialGameTrigger then
        self.m_enterGameSoundId = gLobalSoundManager:playSound(path)
    end
end

-- 背景 音乐机制处理
function BaseMachine:setMinMusicBGVolume()
    gLobalSoundManager:setBackgroundMusicVolume(0)
end

function BaseMachine:firstSpinRestMusicBG()
    if self.m_spinRestMusicBG then
        self:resetMusicBg()
        self.m_spinRestMusicBG = false
    end
end

function BaseMachine:setMaxMusicBGVolume()
    self:removeSoundHandler()

    gLobalSoundManager:setBackgroundMusicVolume(1)

    -- 停止音乐渐变效果
    -- gLobalSoundManager:stopFadeBgMusic()
    -- self.m_currentMusicId = gLobalSoundManager:getBGMusicId()
    -- 当前没有播放背景音乐
    -- if not self.m_currentMusicId then
    --     self:resetMusicBg(true)
    -- end
end

function BaseMachine:removeSoundHandler()
    if self.m_soundHandlerId ~= nil then
        scheduler.unschedulesByTargetName("SoundHandlerId")
        self.m_soundHandlerId = nil
    end

    if self.m_soundGlobalId ~= nil then
        scheduler.unscheduleGlobal(self.m_soundGlobalId)
        self.m_soundGlobalId = nil
    end
end

function BaseMachine:reelsDownDelaySetMusicBGVolume()
    self:removeSoundHandler()

    self.m_soundHandlerId =
        scheduler.performWithDelayGlobal(
        function()
            self.m_soundHandlerId = nil
            local volume = gLobalSoundManager:getBackgroundMusicVolume() or 0

            self.m_soundGlobalId =
                scheduler.scheduleGlobal(
                function()
                    --播放广告过程中暂停逻辑
                    if gLobalAdsControl ~= nil and gLobalAdsControl.getPlayAdFlag ~= nil and gLobalAdsControl:getPlayAdFlag() then
                        return
                    end

                    if volume <= 0 then
                        volume = 0
                    end

                    print("缩小音量 = " .. tostring(volume))
                    gLobalSoundManager:setBackgroundMusicVolume(volume)

                    if volume <= 0 then
                        if self.m_soundGlobalId ~= nil then
                            scheduler.unscheduleGlobal(self.m_soundGlobalId)
                            self.m_soundGlobalId = nil
                        end
                    end

                    volume = volume - 0.04
                end,
                0.1
            )
        end,
        self.m_bgmReelsDownDelayTime,
        "SoundHandlerId"
    )

    self:setReelDownSoundFlag(true)
end

function BaseMachine:setReelDownSoundFlag(flag)
    self.reelDownSoundFlag = flag
end

function BaseMachine:checktriggerSpecialGame()
    local istrigger = false

    local features = self.m_runSpinResultData.p_features

    if features then
        if #features > 1 then
            istrigger = true
        end
    end

    return istrigger
end

function BaseMachine:checkTriggerOrInSpecialGame(func)
    if
        self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE or self:checktriggerSpecialGame() or
            self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE
     then
        self:removeSoundHandler() -- 移除监听
    else
        if func then
            func()
        end
    end
end

--关卡内活动下载完成监听
function BaseMachine:checkUpdateActivityEntryNode()
    local activityDataList = globalData.commonActivityData:getActivitys()
    if activityDataList ~= nil then
        local updateFlag = false
        for k, v in pairs(activityDataList) do
            --local reference = v:getRefName()
            local themeName = v:getThemeName()
            if v:isRunning() and (v.getPositionBar and v:getPositionBar() == 1) and themeName ~= nil then
                if globalDynamicDLControl:checkDownloading(themeName) then
                    gLobalNoticManager:addObserver(
                        self,
                        function(target, params)
                            gLobalActivityManager:showActivityEntryNode()
                        end,
                        "DL_Complete" .. tostring(themeName)
                    )
                else
                    updateFlag = true
                    -- break
                end
            end
        end
        -- if updateFlag then
            gLobalActivityManager:showActivityEntryNode()
        -- end
    end
end
--[[
    底栏收集反馈动效
]]
--修改资源
function BaseMachine:changeCoinWinEffectUI(_levelName, _csbPath)
    if self.m_bottomUI ~= nil then
        self.m_bottomUI:changeCoinWinEffectUI(_levelName, _csbPath)
    end
end
--播放
function BaseMachine:playCoinWinEffectUI(callBack)
    if self.m_bottomUI ~= nil then
        self.m_bottomUI:playCoinWinEffectUI(callBack)
    end
end
--[[
    底栏大赢文本
]]
--修改资源
function BaseMachine:changeBottomBigWinLabUi(_csbPath)
    if self.m_bottomUI ~= nil then
        self.m_bottomUI:changeBigWinLabUi(_csbPath)
    end
end
--播放
function BaseMachine:playBottomBigWinLabAnim(_params)
    if self.m_bottomUI ~= nil then
        self.m_bottomUI:playBigWinLabAnim(_params)
    end
end

-- 初始化小块时 规避某个信号接口 （包含随机创建的两个函数，根据网络消息创建的函数）
function BaseMachine:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)
    return symbolType
end

function BaseMachine:initRealViewsSize()
    local topBgSize = self.m_topUI:findChild("sp_bg"):getContentSize()
    local bottomBgSize = self.m_bottomUI:findChild("sp_bg"):getContentSize()
    local offY = 10

    -- 如果是竖屏的时候换一套算法
    local currViewDire = globalData.slotRunData.isPortrait
    if globalData.slotRunData.machineData then
        currViewDire = globalData.slotRunData.machineData.p_portraitFlag
    end

    if currViewDire == true then
        local bottomHeight = self.m_bottomUI:findChild("Node_1"):getPositionY()
        local lobbyHomeBtn = self.m_topUI:findChild("btn_layout_home")
        globalData.gameRealViewsSize = {topUIHeight = display.height - globalData.gameLobbyHomeNodePos.y + lobbyHomeBtn:getContentSize().height, bottomUIHeight = bottomHeight + offY}
    else
        globalData.gameRealViewsSize = {topUIHeight = topBgSize.height, bottomUIHeight = bottomBgSize.height + offY}
    end
end
--是否在关卡进入后显示bet选择界面
function BaseMachine:isShowChooseBetOnEnter()
    return false
end

--[[
    @desc: 系统模块数据 spin 之前检查
    author:{author}
    time:2020-11-24 17:38:59
    @return:
]]
function BaseMachine:beforeCheckSystemData()
    if self.m_spinBeforeLevel == nil then
        self.m_spinBeforeLevel = globalData.userRunData.levelNum
    end
    if self.m_spinBeforeTotalProVal == nil then
        self.m_spinBeforeTotalProVal = globalData.userRunData:getPassLevelNeedExperienceVal()
    end
    if self.m_spinBeforeProVal == nil then
        self.m_spinBeforeProVal = globalData.userRunData.currLevelExper
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE then
        self.m_spinBeforeLevel = globalData.userRunData.levelNum
        self.m_spinBeforeTotalProVal = globalData.userRunData:getPassLevelNeedExperienceVal()
        self.m_spinBeforeProVal = globalData.userRunData.currLevelExper
    end
end

--缓存日志
function BaseMachine:pushSpinLog(strLog)
    if not self.m_spinLog then
        local fieldValue = util_getUpdateVersionCode(false) or "Vnil"
        self.m_spinLog = "START " .. fieldValue .. " | \n"
    end
    strLog = tostring(strLog)
    self.m_spinLog = self.m_spinLog .. strLog .. " | \n"
end
--清空日志
function BaseMachine:clearSpinLog()
    self.m_spinLog = nil
end
--检测是否存在问题
function BaseMachine:checkSpinError()
    return false
end
--发送日志
function BaseMachine:sendSpinLog()
    local isError = self:checkSpinError()
    if not isError then
        return
    end
    if self.m_spinLog and gLobalSendDataManager and gLobalSendDataManager.getLogGameLoad and gLobalSendDataManager:getLogGameLoad().sendSpinErrorLog then
        gLobalSendDataManager:getLogGameLoad():sendSpinErrorLog(self.m_spinLog)
    end
end

--[[
    停止减小背景音并把音量恢复到最大
]]
function BaseMachine:removeLevelSoundHandlerAndSetMaxVolume()
    self:setMaxMusicBGVolume()
    self:resetMusicBg()
end

--[[
    恢复背景音并逐渐减小音量
]]
function BaseMachine:resumeLevelSoundHandler()
    self:setMaxMusicBGVolume()
    self:resetMusicBg()
    self:reelsDownDelaySetMusicBGVolume()
end

-----------------------------------------活动角标玩法相关接口----------------------------------------------------------
--[[
    检测在小块上添加角标
    非必要不重写改接口,若需重写此接口需调用super方法
]]
function BaseMachine:checkAddSignOnSymbol(symbolNode)
    if self.m_signManager then
        self.m_signManager:addSignForActivity(symbolNode)
    end
end

--[[
    随机角标位置
]]
function BaseMachine:randomAddSignPos()
    if self.m_signManager then
        self.m_signManager:randomAddSignPos()
    end
end

--[[
    获取所有可随机位置
]]
function BaseMachine:getAllSignRandomPos()
    local reels = self.m_runSpinResultData.p_reels
    --服务器数据错误,直接返回
    if #reels == 0 then
        return {}
    end
    local allPosAry = {}
    for iCol = 1, self.m_iReelColumnNum do
        local colData = self.m_reelColDatas[iCol]
        --获取可视行数
        local rowNum = colData.p_showGridCount or self.m_iReelRowNum
        local iRow = #reels
        local rowIndex = 1
        while iRow >= #reels - rowNum + 1 do
            local symbolType = reels[iRow][iCol]
            if self.m_bigSymbolInfos[symbolType] then
                local addCount = self.m_bigSymbolInfos[symbolType]
                iRow = iRow - addCount
                rowIndex = rowIndex + addCount
            else
                --转化索引值
                local posIndex = self:getPosReelIdx(rowIndex, iCol)
                allPosAry[#allPosAry + 1] = posIndex
                iRow = iRow - 1
                rowIndex = rowIndex + 1
            end
        end
    end

    return allPosAry
end

--[[
    检测轮盘是否有长条图标
]]
function BaseMachine:checkHasLongSymbol()
    local reels = self.m_runSpinResultData.p_reels
    for iRow = 1, #reels do
        for iCol = 1, #reels[iRow] do
            local symbolType = reels[iRow][iCol]
            if self.m_bigSymbolInfos[symbolType] then
                return true
            end
        end
    end

    return false
end

--[[
    添加收集角标事件
]]
function BaseMachine:addCollectSignEffect()
    if self.m_signManager then
        self.m_signManager:addCollectSignEffect()
    end
end

--[[
    收集角标
]]
function BaseMachine:showEffect_collectSign(effectData)

    if self.m_signManager then
        self.m_signManager:collectSignAni(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    return true
end

function BaseMachine:spinItemCall()
    if self.m_signManager then
        self.m_signManager:spinItemCallBack()
    end
end

---------------------------------------------------------------------------------------------------

---
-- 判断当前是否可点击
-- 商店玩法等滚动过程中不允许点击的接口
-- 返回true,允许点击
function BaseMachine:collectBarClickEnabled()
    local featureDatas = self.m_runSpinResultData.p_features or {0}
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    local bonusStates = self.m_runSpinResultData.p_bonusStatus or ""
    --

    if self.m_isWaitingNetworkData then
        return false
    elseif self:getGameSpinStage() ~= IDLE then
        return false
    elseif bonusStates == "OPEN" then
        return false
    elseif self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return false
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        return false
    elseif self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        return false
    elseif reSpinCurCount and reSpinCurCount and reSpinCurCount > 0 and reSpinsTotalCount > 0 then
        return false
    elseif self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        return false
    elseif #featureDatas > 1 then
        return false
    elseif self.m_isRunningEffect then
        return false
    end

    return true
end

--[[
    长条symbolNode获取接口
]]
function BaseMachine:getBigFixSymbol(iCol, iRow, iTag)
    if not iTag then
        iTag = SYMBOL_NODE_TAG
    end
    local fixSp = nil

    if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[iCol] ~= nil then
        local parentData = self.m_slotParents[iCol]
        local slotParent = parentData.slotParent
        local slotParentBig = self.m_slotParents[iCol].slotParentBig
        local bigSymbolInfos = self.m_bigSymbolColumnInfo[iCol]
        for k = 1, #bigSymbolInfos do
            local bigSymbolInfo = bigSymbolInfos[k]
            for changeIndex = 1, #bigSymbolInfo.changeRows do
                if bigSymbolInfo.changeRows[changeIndex] == iRow then
                    local fixSpTag = self:getNodeTag(iCol, bigSymbolInfo.startRowIndex, iTag)
                    fixSp = self.m_clipParent:getChildByTag(fixSpTag)
                    if fixSp == nil and (iCol >= 1 and iCol <= self.m_iReelColumnNum) then
                        fixSp = slotParent:getChildByTag(fixSpTag)
                        if fixSp == nil and slotParentBig then
                            fixSp = slotParentBig:getChildByTag(fixSpTag)
                        end
                    end

                    return fixSp, bigSymbolInfo.changeRows
                end
            end
        end
    end

    return fixSp
end
--获取当前关卡服务器下发的全局数据
function BaseMachine:getCurLevelMachineData()
    local machineData = globalData.slotRunData.machineData
    return machineData
end

--[[
    变更小块信号值
]]
function BaseMachine:changeSymbolType(symbolNode,symbolType,notNeedPutBack)
     
    if symbolNode then
        if symbolNode.p_symbolImage then
            symbolNode.p_symbolImage:removeFromParent()
            symbolNode.p_symbolImage = nil
        end

        local symbolName = self:getSymbolCCBNameByType(self,symbolType)
        symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType), symbolType)
        symbolNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self,symbolType))

        symbolNode.p_symbolType = symbolType
        symbolNode.p_showOrder = self:getBounsScatterDataZorder(symbolType)

        if not notNeedPutBack then
            self:putSymbolBackToPreParent(symbolNode)
        end
    end
end

--[[
    检测是否为最上层的特殊信号块
]]
function BaseMachine:isSpecialSymbol(symbolType)
    if not self.m_configData.p_specialSymbolList then
        return false
    end
    for i,v in ipairs(self.m_configData.p_specialSymbolList) do
        if v == symbolType then
            return true
        end
    end
    
    return false
end

--[[
    将小块放回原父节点
]]
function BaseMachine:putSymbolBackToPreParent(symbolNode)
    if not tolua.isnull(symbolNode) and type(symbolNode.isSlotsNode) == "function" and symbolNode:isSlotsNode() then
        local parentData = self.m_slotParents[symbolNode.p_cloumnIndex]
        if not symbolNode.m_baseNode then
            symbolNode.m_baseNode = parentData.slotParent
        end

        if not symbolNode.m_topNode then
            symbolNode.m_topNode = parentData.slotParentBig
        end

        symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

        local zOrder = self:getBounsScatterDataZorder(symbolNode.p_symbolType)
        symbolNode.p_showOrder = zOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * 10
        local isInTop = self:isSpecialSymbol(symbolNode.p_symbolType)
        symbolNode.m_isInTop = isInTop
        symbolNode:putBackToPreParent()

        symbolNode:setTag(self:getNodeTag(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex,SYMBOL_NODE_TAG))
    end
end

--[[
    小块提层到clipParent上
]]
function BaseMachine:changeSymbolToClipParent(symbolNode)
    if not tolua.isnull(symbolNode) and type(symbolNode.isSlotsNode) == "function" and symbolNode:isSlotsNode() then
        local index = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
        local pos = util_getOneGameReelsTarSpPos(self, index)
        local showOrder = self:getBounsScatterDataZorder(symbolNode.p_symbolType)
        showOrder = showOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * self.m_iReelRowNum * 2
        symbolNode.p_showOrder = showOrder
        symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        util_changeNodeParent(self.m_clipParent,symbolNode,showOrder)
        symbolNode:setTag(self:getNodeTag(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex,SYMBOL_NODE_TAG))

        symbolNode:setPosition(cc.p(pos.x, pos.y))
    end
    
end


--[[
    获取小块spine槽点上绑定的csb节点
    csbName csb文件名称
    bindNodeName 槽点名称
]]
function BaseMachine:getLblCsbOnSymbol(symbolNode,csbName,bindNodeName)
    if tolua.isnull(symbolNode) then
        return
    end
    
    local symbolType = symbolNode.p_symbolType
    if not symbolType then
        return
    end

    local aniNode = symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine and tolua.isnull(spine.m_bindCsbNode) then

        local label = util_createAnimation(csbName)
        util_spinePushBindNode(spine,bindNodeName,label)
        spine.m_bindCsbNode = label
    end

    return spine.m_bindCsbNode,spine
end

---
--根据配置的信号等级设置symbol层级；没有配置走原来逻辑
function BaseMachine:getBounsScatterDataZorder(symbolType)
    local zorder = BaseMachine.super.getBounsScatterDataZorder(self, symbolType)

    --信号类型+等级
    local symbolZorderLevelAyyay = self.m_configData.p_symbolZorderLevelAyyay
    if symbolZorderLevelAyyay and next(symbolZorderLevelAyyay) and symbolZorderLevelAyyay[symbolType] then
        local zorderLevel = symbolZorderLevelAyyay[symbolType]
        local intervalZorder = 200
        if zorderLevel == 1 then
            zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
        elseif zorderLevel == 2 then
            zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
        elseif zorderLevel == 3 then
            zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2
        elseif zorderLevel == 4 then
            zorder = REEL_SYMBOL_ORDER.REEL_ORDER_1
        elseif zorderLevel > 4 then
            zorder = REEL_SYMBOL_ORDER.REEL_ORDER_1 - ((zorderLevel - 4) * intervalZorder)
        end

        -- 防止等级过多导致Zorder为负数
        if zorder <= 0 then
            zorder = 0
        end
    end

    return zorder
end

--[[
    延迟回调
]]
function BaseMachine:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return BaseMachine
