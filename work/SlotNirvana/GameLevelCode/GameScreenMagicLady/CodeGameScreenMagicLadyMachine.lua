
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenMagicLadyMachine = class("CodeGameScreenMagicLadyMachine", BaseFastMachine)

CodeGameScreenMagicLadyMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenMagicLadyMachine.SYMBOL_SCORE_10 = 9

CodeGameScreenMagicLadyMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 --TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE = 93
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10

CodeGameScreenMagicLadyMachine.SYMBOL_BIG_SCORE_10 = 1009
CodeGameScreenMagicLadyMachine.SYMBOL_BIG_SCORE_1 = 1008
CodeGameScreenMagicLadyMachine.SYMBOL_BIG_SCORE_2 = 1007
CodeGameScreenMagicLadyMachine.SYMBOL_BIG_SCORE_3 = 1006
CodeGameScreenMagicLadyMachine.SYMBOL_BIG_SCORE_4 = 1005
CodeGameScreenMagicLadyMachine.SYMBOL_BIG_SCORE_5 = 1004
CodeGameScreenMagicLadyMachine.SYMBOL_BIG_SCORE_6 = 1003
CodeGameScreenMagicLadyMachine.SYMBOL_BIG_SCORE_7 = 1002
CodeGameScreenMagicLadyMachine.SYMBOL_BIG_SCORE_8 = 1001
CodeGameScreenMagicLadyMachine.SYMBOL_BIG_SCORE_9 = 1000
CodeGameScreenMagicLadyMachine.SYMBOL_BIG_SCORE_SCATTER = 1090
CodeGameScreenMagicLadyMachine.SYMBOL_BIG_SCORE_WILD = 1092

CodeGameScreenMagicLadyMachine.SYMBOL_FIX_GREEN_SYMBOL = 30094
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_GREEN_GRAND = 30106
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_GREEN_MAJOR = 30105
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_GREEN_MINOR = 30104
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_GREEN_MINI = 30103

CodeGameScreenMagicLadyMachine.SYMBOL_FIX_BLUE_SYMBOL = 20094
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_BLUE_GRAND = 20106
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_BLUE_MAJOR = 20105
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_BLUE_MINOR = 20104
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_BLUE_MINI = 20103

CodeGameScreenMagicLadyMachine.SYMBOL_FIX_RED_SYMBOL = 10094
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_RED_GRAND = 10106
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_RED_MAJOR = 10105
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_RED_MINOR = 10104
CodeGameScreenMagicLadyMachine.SYMBOL_FIX_RED_MINI = 10103

local FIT_HEIGHT_MAX = 1660
local FIT_HEIGHT_MIN = 1054
-- 构造函数
function CodeGameScreenMagicLadyMachine:ctor()
    CodeGameScreenMagicLadyMachine.super.ctor(self)
    self.m_isReconnection = false--是否重连
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0

    self.m_jackpot_status = "Normal"
    self.m_isJackpotEnd = false

    self.m_isVisibleTriggerEffect = false--本轮是否显示触发玩法特效
    self.m_ChangedParentSymbolTab = {}--本关更改层级的图标数组
    self.m_changeParentSymbolNode = {} --本关自己更改父节点的图标对象
    self.m_respinWheelNodeTab = {} --存储respin的3个轮盘背景盘对象
    self.m_respinPrizeNodeTab = {} --存储respin下轮盘上奖励框的对象
    self.m_respinKpNodeTab = {} --存储respin下3个卡片对象
    self.m_respinViewTab = {} --存储respin的3个轮盘对象{
    self.m_respinOneReelDownNumTab = {}--respin时一列停止次数的记录
    self.m_respinFrameNode = {}--存储respin下信号框特效对象
    self.m_isFeatureOverBigWinInFree = true
    
	--init
    self:initGame()
end

function CodeGameScreenMagicLadyMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("MagicLadyConfig.csv", "LevelMagicLadyConfig.lua")
	self:initMachine(self.m_moduleName)
end

function CodeGameScreenMagicLadyMachine:initUI()
    self.m_reelRunSound = "MagicLadySounds/music_MagicLady_quick_run.mp3"--快滚音效

    --背景居中
    self.m_gameBg:setPosition(display.center)
    self.m_gameBg:setScale(self.m_machineRootScale)
    --初始化底部条上的freespin信息显示条
    self:initFreeSpinBar()
    --添加jackpot条
    self.m_jackpotBar = util_createView("CodeMagicLadySrc.MagicLadyJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self)
    --添加魔女
    self.m_magicLadyNode = util_spineCreate("MagicLady_BGRW",true,true)
    self:findChild("spine_monv"):addChild(self.m_magicLadyNode)
    util_spinePlay(self.m_magicLadyNode,"idleframe",true)
    --添加魔女球
    self.m_magicLadyQiuNode = util_spineCreate("MagicLady_QIU",true,true)
    self:findChild("spine_QIU"):addChild(self.m_magicLadyQiuNode)
    util_spinePlay(self.m_magicLadyQiuNode,"idleframe",true)
    --添加魔女✋
    self.m_magicLadyHandNode = util_spineCreate("MagicLady_SHOUZHI",true,true)
    self:findChild("spine_SHOUZHI"):addChild(self.m_magicLadyHandNode)
    util_spinePlay(self.m_magicLadyHandNode,"idleframe",true)

    self:findChild("hesezhezhao"):setLocalZOrder(1)
    self:findChild("spine_QIU"):setLocalZOrder(2)
    self:findChild("spine_SHOUZHI"):setLocalZOrder(3)
    --添加freespin计数条
    self.m_freespinBar = util_createView("CodeMagicLadySrc.MagicLadyFreespinBarView")
    self:findChild("freespin"):addChild(self.m_freespinBar)
    self.m_freespinBar:setVisible(false)
    self:findChild("freespin"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10000)
    --添加快滚特效背景
    -- self.m_quickRunBg = util_createAnimation("WinFrameMagicLady_run_bg.csb")
    -- self:findChild("reel"):addChild(self.m_quickRunBg,1)
    -- self.m_quickRunBg:setPosition(cc.p(self:findChild("sp_reel_4"):getPosition()))
    -- self.m_quickRunBg:setVisible(false)
    --添加玩法触发特效
    self.m_triggerEffect = util_createAnimation("MagicLady_dk.csb")
    self:findChild("triggerEffectNode"):addChild(self.m_triggerEffect)
    self:findChild("triggerEffectNode"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    self:findChild("triggerEffectNode"):setVisible(false)
    --添加respin界面
    self.m_respinLayer = util_createAnimation("MagicLady/MagicLadyRespin.csb")
    self:findChild("respinReel"):addChild(self.m_respinLayer)
    self.m_respinLayer:findChild("root"):setContentSize(cc.size(display.width, display.height))
    self:addClick(self.m_respinLayer:findChild("root"))
    --添加respin下的jackpot条
    self.m_respinJackpotBar = util_createView("CodeMagicLadySrc.MagicLadyJackPotBarView")
    self.m_respinLayer:findChild("jackpot"):addChild(self.m_respinJackpotBar)
    self.m_respinJackpotBar:initMachine(self)
    --添加respin描述框
    self.m_respinBar = util_createAnimation("MagicLady_respin_ditai.csb")
    self.m_respinLayer:findChild("respin_ditai"):addChild(self.m_respinBar)
    --添加赢钱框
    self.m_winBar = util_createAnimation("MagicLady_respin_win.csb")
    self.m_respinLayer:findChild("win"):addChild(self.m_winBar)
    self.m_winBar:findChild("MagicLady_jackpot_zi6_1"):setVisible(false)
    --从下到上添加三个轮盘
    local kpNameTab = {"MagicLady_respin_kp_mao.csb","MagicLady_respin_kp_wuya.csb","MagicLady_respin_kp_wa.csb"}
    for i = 1,3 do
        local wheelNode = util_createAnimation("MagicLady_respin_reel.csb")
        self.m_respinLayer:findChild("respin_reel_"..i):addChild(wheelNode)
        local kp = util_createAnimation(kpNameTab[i])
        wheelNode:findChild("respin_kp"):addChild(kp)

        local prizeNode = util_createAnimation("MagicLady_bonus_prize.csb")
        wheelNode:findChild("prizeNode"):addChild(prizeNode)
        wheelNode:findChild("prizeNode"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
        prizeNode:setVisible(false)
        
        table.insert(self.m_respinWheelNodeTab,wheelNode)
        table.insert(self.m_respinKpNodeTab,kp)
        table.insert(self.m_respinPrizeNodeTab,prizeNode)
    end

    self:findChild("respinReel"):setVisible(false)
end

function CodeGameScreenMagicLadyMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    --看资源实际的高度
    uiH = 120
    uiBH = 180

    local mainHeight = display.height - uiH - uiBH

    local winSize = display.size
    local mainScale = 1

    if display.height/display.width == DESIGN_SIZE.height/DESIGN_SIZE.width then
        --设计尺寸屏

    elseif display.height/display.width > DESIGN_SIZE.height/DESIGN_SIZE.width then
        --高屏
        local hScale = mainHeight / (DESIGN_SIZE.height - uiH - uiBH)
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale < wScale then
            mainScale = hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end
    else
        --宽屏
        local topAoH = 40--顶部条凹下去距离 在宽屏中会被用的尺寸
        local bottomMoveH = 15--底部空间尺寸，最后要下移距离
        local hScale1 = (mainHeight + topAoH )/(mainHeight + topAoH - bottomMoveH)--有效区域尺寸改变适配
        local hScale = (mainHeight + topAoH ) / (DESIGN_SIZE.height - uiH - uiBH + topAoH )--有效区域屏幕适配
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale1 * hScale < wScale then
            mainScale = hScale1 * hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end

        local designDis = (DESIGN_SIZE.height/2 - uiBH) * mainScale--设计离下条距离
        local dis = (display.height/2 - uiBH)--实际离下条距离
        local move = designDis - dis
        --宽屏下轮盘跟底部条更接近，实际整体下移了
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + move - bottomMoveH)
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
]]
function CodeGameScreenMagicLadyMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        soundPath = "MagicLadySounds/music_MagicLady_buling.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end
function CodeGameScreenMagicLadyMachine:getValidSymbolMatrixArray()
    return  table_createTwoArr(9,self.m_iReelColumnNum,TAG_SYMBOL_TYPE.SYMBOL_WILD)
end
-- 断线重连 
function CodeGameScreenMagicLadyMachine:MachineRule_initGame()
    self.m_isReconnection = true
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --轮盘动画
        self:runCsbAction("idle2")
        --背景动画
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idle3")
        self.m_magicLadyQiuNode:setVisible(false)
        self.m_magicLadyNode:setVisible(false)
        self.m_magicLadyHandNode:setVisible(false)
        self.m_jackpotBar:setVisible(false)
        self.m_freespinBar:setVisible(true)
        self.m_freespinBar:updateNoAddFreespinCount(self.m_runSpinResultData.p_freeSpinsLeftCount - self.m_runSpinResultData.p_freeSpinNewCount,self.m_runSpinResultData.p_freeSpinsTotalCount - self.m_runSpinResultData.p_freeSpinNewCount )

        self:changeFreeSpinReelData()
        --修改总行数为freespin行数
        self:changeToFreespinRowNum()
        --更改裁切区域
        self:changeClipRegion()
        --修改滚轴属性为freespin盘面的
        self:changeReelAttributeToFreespin()

        self.m_fsLastWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMagicLadyMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "MagicLady"  
end

-- 继承底层respinView
function CodeGameScreenMagicLadyMachine:getRespinView()
    return "CodeMagicLadySrc.MagicLadyRespinView"
end
-- 继承底层respinNode
function CodeGameScreenMagicLadyMachine:getRespinNode()
    return "CodeMagicLadySrc.MagicLadyRespinNode"
end

---
-- 返回自定义信号类型对应文件名
-- @param symbolType int 信号类型
function CodeGameScreenMagicLadyMachine:MachineRule_GetSelfCCBName(symbolType)
    -- 自行配置jackPot信号 csb文件名，不带后缀

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_MagicLady_10"
    end

    if symbolType == self.SYMBOL_FIX_SYMBOL  then
        return "Socre_MagicLady_linghting"
    end

    if symbolType == self.SYMBOL_FIX_GRAND then
        return "Socre_MagicLady_linghtingGrand"
    end

    if symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_MagicLady_linghtingMajor"
    end

    if symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_MagicLady_linghtingMinor"
    end

    if symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_MagicLady_linghtingMini"
    end

    if symbolType == self.SYMBOL_BIG_SCORE_10 then
        return "Socre_MagicLady_big_10"
    end
    if symbolType == self.SYMBOL_BIG_SCORE_1 then
        return "Socre_MagicLady_big_1"
    end
    if symbolType == self.SYMBOL_BIG_SCORE_2 then
        return "Socre_MagicLady_big_2"
    end
    if symbolType == self.SYMBOL_BIG_SCORE_3 then
        return "Socre_MagicLady_big_3"
    end
    if symbolType == self.SYMBOL_BIG_SCORE_4 then
        return "Socre_MagicLady_big_4"
    end
    if symbolType == self.SYMBOL_BIG_SCORE_5 then
        return "Socre_MagicLady_big_5"
    end
    if symbolType == self.SYMBOL_BIG_SCORE_6 then
        return "Socre_MagicLady_big_6"
    end
    if symbolType == self.SYMBOL_BIG_SCORE_7 then
        return "Socre_MagicLady_big_7"
    end
    if symbolType == self.SYMBOL_BIG_SCORE_8 then
        return "Socre_MagicLady_big_8"
    end
    if symbolType == self.SYMBOL_BIG_SCORE_9 then
        return "Socre_MagicLady_big_9"
    end
    if symbolType == self.SYMBOL_BIG_SCORE_SCATTER then
        return "Socre_MagicLady_big_Scatter"
    end
    if symbolType == self.SYMBOL_BIG_SCORE_WILD then
        return "Socre_MagicLady_big_Wild"
    end

    if symbolType == self.SYMBOL_FIX_GREEN_SYMBOL then
        return "Socre_MagicLady_linghting_lv"
    end
    if symbolType == self.SYMBOL_FIX_GREEN_GRAND then
        return "Socre_MagicLady_linghting_lvGrand"
    end
    if symbolType == self.SYMBOL_FIX_GREEN_MAJOR then
        return "Socre_MagicLady_linghting_lvMajor"
    end
    if symbolType == self.SYMBOL_FIX_GREEN_MINOR then
        return "Socre_MagicLady_linghting_lvMinor"
    end
    if symbolType == self.SYMBOL_FIX_GREEN_MINI then
        return "Socre_MagicLady_linghting_lvMini"
    end

    if symbolType == self.SYMBOL_FIX_BLUE_SYMBOL then
        return "Socre_MagicLady_linghting_lan"
    end
    if symbolType == self.SYMBOL_FIX_BLUE_GRAND then
        return "Socre_MagicLady_linghting_lanGrand"
    end
    if symbolType == self.SYMBOL_FIX_BLUE_MAJOR then
        return "Socre_MagicLady_linghting_lanMajor"
    end
    if symbolType == self.SYMBOL_FIX_BLUE_MINOR then
        return "Socre_MagicLady_linghting_lanMinor"
    end
    if symbolType == self.SYMBOL_FIX_BLUE_MINI then
        return "Socre_MagicLady_linghting_lanMini"
    end

    if symbolType == self.SYMBOL_FIX_RED_SYMBOL then
        return "Socre_MagicLady_linghting_hong"
    end
    if symbolType == self.SYMBOL_FIX_RED_GRAND then
        return "Socre_MagicLady_linghting_hongGrand"
    end
    if symbolType == self.SYMBOL_FIX_RED_MAJOR then
        return "Socre_MagicLady_linghting_hongMagor"
    end
    if symbolType == self.SYMBOL_FIX_RED_MINOR then
        return "Socre_MagicLady_linghting_hongMinor"
    end
    if symbolType == self.SYMBOL_FIX_RED_MINI then
        return "Socre_MagicLady_linghting_hongMini"
    end

    return nil
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenMagicLadyMachine:getReSpinSymbolScore(id,wheelIndex)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = nil
    if wheelIndex == 1 then
        storedIcons = self.m_runSpinResultData.p_storedIcons
    elseif wheelIndex == 2 then
        storedIcons = self.m_runSpinResultData.p_rsExtraData.middleStoreIcons
    elseif wheelIndex == 3 then
        storedIcons = self.m_runSpinResultData.p_rsExtraData.upStoredIcons
    end
    local score = nil
    local idNode = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return 0
    end

    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY,wheelIndex)

    if symbolType == self.SYMBOL_FIX_MINI
        or symbolType == self.SYMBOL_FIX_GREEN_MINI
        or symbolType == self.SYMBOL_FIX_BLUE_MINI
        or symbolType == self.SYMBOL_FIX_RED_MINI then
        score = "MINI"
    elseif symbolType == self.SYMBOL_FIX_MINOR 
        or symbolType == self.SYMBOL_FIX_GREEN_MINOR 
        or symbolType == self.SYMBOL_FIX_BLUE_MINOR 
        or symbolType == self.SYMBOL_FIX_RED_MINOR then
        score = "MINOR"
    elseif symbolType == self.SYMBOL_FIX_MAJOR 
        or symbolType == self.SYMBOL_FIX_GREEN_MAJOR 
        or symbolType == self.SYMBOL_FIX_BLUE_MAJOR 
        or symbolType == self.SYMBOL_FIX_RED_MAJOR then
        score = "MAJOR"
    elseif symbolType == self.SYMBOL_FIX_GRAND 
        or symbolType == self.SYMBOL_FIX_GREEN_GRAND 
        or symbolType == self.SYMBOL_FIX_BLUE_GRAND 
        or symbolType == self.SYMBOL_FIX_RED_GRAND then
        score = "GRAND"
    end

    return score
end

function CodeGameScreenMagicLadyMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

-- 给lighting图标进行赋值
function CodeGameScreenMagicLadyMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not symbolNode.p_symbolType 
        or not (symbolNode.p_symbolType == self.SYMBOL_FIX_SYMBOL 
            or symbolNode.p_symbolType == self.SYMBOL_FIX_GREEN_SYMBOL 
            or symbolNode.p_symbolType == self.SYMBOL_FIX_BLUE_SYMBOL 
            or symbolNode.p_symbolType == self.SYMBOL_FIX_RED_SYMBOL) then
        return
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        local wheelIndex = 1
        if symbolNode.p_symbolType == self.SYMBOL_FIX_GREEN_SYMBOL then
            wheelIndex = 3
        elseif symbolNode.p_symbolType == self.SYMBOL_FIX_BLUE_SYMBOL then
            wheelIndex = 2
        end
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol),wheelIndex) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            symbolNode:getCcbProperty("m_lb_score"):setString(score)
        end

        symbolNode:runIdleAnim()

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil   then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                if score == nil then
                    score = 1
                end
                score = score * lineBet
                score = util_formatCoins(score, 3)
                symbolNode:getCcbProperty("m_lb_score"):setString(score)
                
                symbolNode:runIdleAnim()
            end
        end
        
        
    end

end
--从内存池里取信号块时 设置信号块的数据
function CodeGameScreenMagicLadyMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    CodeGameScreenMagicLadyMachine.super.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    self:updateReelGridNode(node)
    
    if symbolType == self.SYMBOL_FIX_SYMBOL
        or symbolType == self.SYMBOL_FIX_MINI
        or symbolType == self.SYMBOL_FIX_MINOR
        or symbolType == self.SYMBOL_FIX_MAJOR
        or symbolType == self.SYMBOL_FIX_GRAND

        or symbolType == self.SYMBOL_FIX_GREEN_SYMBOL
        or symbolType == self.SYMBOL_FIX_GREEN_MINI
        or symbolType == self.SYMBOL_FIX_GREEN_MINOR
        or symbolType == self.SYMBOL_FIX_GREEN_MAJOR
        or symbolType == self.SYMBOL_FIX_GREEN_GRAND

        or symbolType == self.SYMBOL_FIX_BLUE_SYMBOL
        or symbolType == self.SYMBOL_FIX_BLUE_MINI
        or symbolType == self.SYMBOL_FIX_BLUE_MINOR
        or symbolType == self.SYMBOL_FIX_BLUE_MAJOR
        or symbolType == self.SYMBOL_FIX_BLUE_GRAND

        or symbolType == self.SYMBOL_FIX_RED_SYMBOL
        or symbolType == self.SYMBOL_FIX_RED_MINI
        or symbolType == self.SYMBOL_FIX_RED_MINOR
        or symbolType == self.SYMBOL_FIX_RED_MAJOR
        or symbolType == self.SYMBOL_FIX_RED_GRAND
    then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if  symbolType >= 1000 then
            local callFun = cc.CallFunc:create(handler(self,self.setBigNodeData),{node})
            self:runAction(callFun)
        end
    end

    return node
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMagicLadyMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenMagicLadyMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_GRAND,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MAJOR,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINOR,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINI,count = 1}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_GREEN_SYMBOL,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_GREEN_GRAND,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_GREEN_MAJOR,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_GREEN_MINOR,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_GREEN_MINI,count = 1}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BLUE_SYMBOL,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BLUE_GRAND,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BLUE_MAJOR,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BLUE_MINOR,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BLUE_MINI,count = 1}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_RED_SYMBOL,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_RED_GRAND,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_RED_MAJOR,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_RED_MINOR,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_RED_MINI,count = 1}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_SCORE_10,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_SCORE_1,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_SCORE_2,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_SCORE_3,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_SCORE_4,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_SCORE_5,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_SCORE_6,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_SCORE_7,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_SCORE_8,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_SCORE_9,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_SCORE_SCATTER,count = 1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_SCORE_WILD,count = 1}
    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenMagicLadyMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or 
        symbolType == self.SYMBOL_FIX_MINI or 
        symbolType == self.SYMBOL_FIX_MINOR or 
        symbolType == self.SYMBOL_FIX_MAJOR or 
        symbolType == self.SYMBOL_FIX_GRAND or
        symbolType == self.SYMBOL_FIX_GREEN_SYMBOL or 
        symbolType == self.SYMBOL_FIX_GREEN_MINI or 
        symbolType == self.SYMBOL_FIX_GREEN_MINOR or 
        symbolType == self.SYMBOL_FIX_GREEN_MAJOR or 
        symbolType == self.SYMBOL_FIX_GREEN_GRAND or
        symbolType == self.SYMBOL_FIX_BLUE_SYMBOL or 
        symbolType == self.SYMBOL_FIX_BLUE_MINI or 
        symbolType == self.SYMBOL_FIX_BLUE_MINOR or 
        symbolType == self.SYMBOL_FIX_BLUE_MAJOR or 
        symbolType == self.SYMBOL_FIX_BLUE_GRAND or
        symbolType == self.SYMBOL_FIX_RED_SYMBOL or 
        symbolType == self.SYMBOL_FIX_RED_MINI or 
        symbolType == self.SYMBOL_FIX_RED_MINOR or 
        symbolType == self.SYMBOL_FIX_RED_MAJOR or 
        symbolType == self.SYMBOL_FIX_RED_GRAND then

        return true
    end
    return false
end
--所有effect播放完之后调用
function CodeGameScreenMagicLadyMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenMagicLadyMachine.super.playEffectNotifyNextSpinCall(self)
end

--所有滚轴停止调用
function CodeGameScreenMagicLadyMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
    
    -- if self.m_isVisibleTriggerEffect then
    --     performWithDelay(self,function()
    --         CodeGameScreenMagicLadyMachine.super.slotReelDown(self)
    --     end,1)
    -- else
        CodeGameScreenMagicLadyMachine.super.slotReelDown(self)
    -- end
    -- self:hideTriggerEffect()
 end
--
--单列滚动停止回调
--
function CodeGameScreenMagicLadyMachine:slotOneReelDown(reelCol)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if reelCol == 2 or reelCol == 4 then
            return
        end
    end

    CodeGameScreenMagicLadyMachine.super.slotOneReelDown(self,reelCol)

    local playSound = {bonusSound = 0,scatterSound = 0}
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        for k = 1, self.m_iReelRowNum do
            if self:isFixSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
                local symbolNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG) --self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,i,SYMBOL_NODE_TAG))
                -- if self.m_isVisibleTriggerEffect then
                --     self:addBulingBaozhaEffect(symbolNode)
                -- else
                    playSound.bonusSound = 1
                    symbolNode:runAnim("buling",false,function()
                        --到这里可能下一轮滚走了，加个判断
                        if symbolNode.p_symbolType ~= nil then
                            symbolNode:runAnim("idleframe",true)
                        end
                    end)
                -- end
            end
            if self.m_stcValidSymbolMatrix[k][reelCol] == self.SYMBOL_BIG_SCORE_SCATTER then
                local symbolNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
                if symbolNode then
                    symbolNode:runAnim("buling",false,function()
                        if symbolNode.p_symbolType ~= nil then
                            symbolNode:runAnim("idleframe",true)
                        end
                    end)
                    playSound.scatterSound = 1
                end
            end
        end
    end
    if playSound.scatterSound == 1 then

        local soundPath = "MagicLadySounds/music_MagicLady_buling.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

    elseif playSound.bonusSound == 1 then

        local soundPath = "MagicLadySounds/music_MagicLady_lightingBuling.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

    end
end
--添加 scatter lighting图标落地 爆炸
function CodeGameScreenMagicLadyMachine:addBulingBaozhaEffect(symbolNode)
    if (self.m_runSpinResultData.p_features[2] == 3 and symbolNode.p_symbolType >= 94)
        or self.m_runSpinResultData.p_features[2] == 1 and symbolNode.p_symbolType == 90 then
        self:changeScatterAndLightingSymbolParent(symbolNode)
        symbolNode:runAnim("buling2")
        gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_buling2.mp3")
    end
end
--将 scatter lighting 图标层级提到 self.m_clipParent 层 ，本关自行管理，用底层的会冲突
function CodeGameScreenMagicLadyMachine:changeScatterAndLightingSymbolParent(slotNode)
    local nodeParent = slotNode:getParent()

    slotNode.m_preParent = nodeParent
    slotNode.m_showOrder = slotNode:getLocalZOrder()
    slotNode.m_preX = slotNode:getPositionX()
    slotNode.m_preY = self.m_SlotNodeH * slotNode.p_rowIndex - self.m_SlotNodeH * 0.5
    slotNode.m_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode:getPositionX(),slotNode:getPositionY()))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层
    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE
    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    table.insert(self.m_ChangedParentSymbolTab,slotNode)
end
--还原改变层级图标的层级
function CodeGameScreenMagicLadyMachine:recoverySymbolParent()
    local nodeLen = #self.m_ChangedParentSymbolTab
    for index = nodeLen, 1, -1 do
        local symbolNode = self.m_ChangedParentSymbolTab[index]
        if symbolNode ~= nil then
            local preParent = symbolNode.m_preParent
            if preParent ~= nil then
                if preParent ~= self.m_clipParent then
                    symbolNode.p_layerTag = symbolNode.m_preLayerTag
                end
                local nZOrder = symbolNode.m_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + symbolNode.m_showOrder
                end
                util_changeNodeParent(preParent,symbolNode,nZOrder)
                symbolNode:setPosition(symbolNode.m_preX, symbolNode.m_preY)
                symbolNode:runIdleAnim()
            end
        end
    end
    self.m_ChangedParentSymbolTab = {}
end

--显示玩法触发特效
function CodeGameScreenMagicLadyMachine:showTriggerEffect()
    self.m_ScatterShowCol = {}
    self.m_isVisibleTriggerEffect = true
    self:findChild("triggerEffectNode"):setVisible(true)
    util_spinePlay(self.m_magicLadyNode,"actionframe",false)
    util_spinePlay(self.m_magicLadyQiuNode,"actionframe",false)
    util_spinePlay(self.m_magicLadyHandNode,"actionframe",false)
    util_spineEndCallFunc(self.m_magicLadyNode,"actionframe",function ()
        util_spinePlay(self.m_magicLadyNode,"idleframe2",true)
        util_spinePlay(self.m_magicLadyQiuNode,"idleframe2",true)
        util_spinePlay(self.m_magicLadyHandNode,"idleframe2",true)
    end)
    self.m_triggerEffect:playAction("show",false,function ()
        self.m_triggerEffect:playAction("idleframe",true)
    end)
    performWithDelay(self,function ()
        self:hideTriggerEffect()
    end,2)

    local rand = math.random(0,1)
    gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_showTriggerEffect"..rand..".mp3")
end
--隐藏玩法触发特效
function CodeGameScreenMagicLadyMachine:hideTriggerEffect()
    if self.m_isVisibleTriggerEffect then
        -- self.m_ScatterShowCol = self.m_configData.p_scatterShowCol --标识哪一列会出现scatter
        -- self.m_isVisibleTriggerEffect = false
        
        util_spinePlay(self.m_magicLadyNode,"actionframe1",false)
        util_spinePlay(self.m_magicLadyQiuNode,"actionframe1",false)
        util_spinePlay(self.m_magicLadyHandNode,"actionframe1",false)
        util_spineEndCallFunc(self.m_magicLadyNode,"actionframe1",function ()
            util_spinePlay(self.m_magicLadyNode,"idleframe",true)
            util_spinePlay(self.m_magicLadyQiuNode,"idleframe",true)
            util_spinePlay(self.m_magicLadyHandNode,"idleframe",true)
        end)
        
        self.m_triggerEffect:playAction("over",false,function ()
            self:findChild("triggerEffectNode"):setVisible(false)
        end)
    end
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenMagicLadyMachine:levelFreeSpinEffectChange()
    if self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then--是重连时触发的freespinmore调这里，不用调，直接return
        return
    end
    -- normal进入freespin轮盘界面
    -- 播过场音
    gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_changeToEffect.mp3")
    --轮盘动画
    self:runCsbAction("start")
    --背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"start2")
    --魔女动画
    self:findChild("spine_SHOUZHI"):setLocalZOrder(0)
    util_spinePlay(self.m_magicLadyNode,"actionframe2",false)
    util_spinePlay(self.m_magicLadyQiuNode,"actionframe2",false)
    util_spinePlay(self.m_magicLadyHandNode,"actionframe2",false)
    util_spineEndCallFunc(self.m_magicLadyQiuNode,"actionframe2",function ()
        self.m_magicLadyNode:setVisible(false)
        self.m_magicLadyQiuNode:setVisible(false)
        self.m_magicLadyHandNode:setVisible(false)
    end)
    performWithDelay(self,function()
        self:changeToFreespinLayer()
    end,70/30)
end
--切换到freespin盘面
function CodeGameScreenMagicLadyMachine:changeToFreespinLayer()
    self:clearWinLineEffect()
    self:recoverySymbolParent()
    self.m_magicLadyNode:setVisible(false)
    self.m_jackpotBar:setVisible(false)
    self.m_freespinBar:setVisible(true)

    self:resetMaskLayerNodes()
    --隐藏盘面不要的图标
    self:changeToFreespinHideRedundantSymbol()
    --修改总行数为freespin行数
    self:changeToFreespinRowNum()
    --更改裁切区域
    self:changeClipRegion()
    --修改滚轴属性为freespin盘面的
    self:changeReelAttributeToFreespin()
    --给freespin盘上面添加必要的图标
    self:addSymbolToFreespinLayer()
end
--切换freespin盘面之前，先隐藏普通盘面上的多余不用的图标
function CodeGameScreenMagicLadyMachine:changeToFreespinHideRedundantSymbol()
    --1、5列只隐藏第四行
    self:hideSymbolByRowCol(1,4)
    self:hideSymbolByRowCol(5,4)
    --2、3、4列隐藏（1-4行）
    local colList = {2,3,4}
    for index = 1,#colList do
        local col = colList[index]
        for row = 1, 4 do
            self:hideSymbolByRowCol(col,row)
        end
    end
end
--修改总行数为freespin行数(理论上应该走配置，配置读取流程还不太熟悉，时间紧，先这么写吧)
function CodeGameScreenMagicLadyMachine:changeToFreespinRowNum()
    self.m_iReelRowNum = 9

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end

end
--修改裁切区域
function CodeGameScreenMagicLadyMachine:changeClipRegion()
    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum

        local rect = self.m_onceClipNode:getClippingRegion()
        self.m_onceClipNode:setClippingRegion(
            {
                x = rect.x,
                y = rect.y,
                width = rect.width,
                height = columnData.p_slotColumnHeight
            }
        )
    end
end
--滚轴属性修改为freespin盘面的
function CodeGameScreenMagicLadyMachine:changeReelAttributeToFreespin()
    local columnData = self.m_reelColDatas[1]
    columnData:updateShowColCount(self.m_iReelRowNum)

    columnData = self.m_reelColDatas[2]
    columnData:updateShowColCount(0)

    columnData = self.m_reelColDatas[3]
    columnData:updateShowColCount(self.m_iReelRowNum/3)

    columnData = self.m_reelColDatas[4]
    columnData:updateShowColCount(0)

    columnData = self.m_reelColDatas[5]
    columnData:updateShowColCount(self.m_iReelRowNum)

    -- 设置各滚轴假滚长度
    -- local runData = {
    --     self.m_configData.p_reelRunDatas[1] * 3,
    --     self.m_configData.p_reelRunDatas[2] * 3,
    --     self.m_configData.p_reelRunDatas[3],
    --     self.m_configData.p_reelRunDatas[4] * 3,
    --     self.m_configData.p_reelRunDatas[5] * 3
    -- }
    local runData = {
        15,
        18,
        21/3,
        24,
        27
    }
    self:slotsReelRunData(runData,self.m_configData.p_bInclScatter
            ,self.m_configData.p_bInclBonus,self.m_configData.p_bPlayScatterAction
                ,self.m_configData.p_bPlayBonusAction)
end
--给freespin盘上面添加必要的图标
function CodeGameScreenMagicLadyMachine:addSymbolToFreespinLayer()
    for col = 1,self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[col]
        for row = 1,reelColData.p_showGridCount do
            --1、5列在没有图标的地方创建普通小图标
            if col == 1 or col == 5 then
                local slotNode = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
                if slotNode == nil then
                    local symbolType = self:getOneNorSymbol()
                    local parentData = self.m_slotParents[col]
                    local halfNodeH = reelColData.p_showGridH * 0.5
                    local showOrder = self:getBounsScatterDataZorder(symbolType)
                    local node = self:getSlotNodeWithPosAndType(symbolType, row, col, false)
                    parentData.slotParent:addChild(node, showOrder - row, col * SYMBOL_NODE_TAG + row)
                    node.p_slotNodeH = reelColData.p_showGridH
                    node.p_symbolType = symbolType
                    node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)
                    node.p_reelDownRunAnima = parentData.reelDownAnima
                    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                    node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                    node:setPositionY((row - 1) * reelColData.p_showGridH + halfNodeH)
                end
            else--第3列全部放普通大图标
                local symbolType = self:getOneBigSymbol()
                local parentData = self.m_slotParents[col]
                local halfNodeH = reelColData.p_showGridH * 0.5
                local showOrder = self:getBounsScatterDataZorder(symbolType)
                local node = self:getSlotNodeWithPosAndType(symbolType, row, col, false)
                parentData.slotParent:addChild(node, showOrder - row, col * SYMBOL_NODE_TAG + row)
                node.p_slotNodeH = reelColData.p_showGridH
                node.p_symbolTy5pe = symbolType
                node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)
                node.p_reelDownRunAnima = parentData.reelDownAnima
                node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                node:setPositionY((row - 1) * reelColData.p_showGridH + halfNodeH)
            end
        end
    end
end

function CodeGameScreenMagicLadyMachine:beginReel()
    self.m_isReconnection = false
    self.m_isVisibleTriggerEffect = false
    self.m_ScatterShowCol = self.m_configData.p_scatterShowCol
    self:recoverySymbolParent()
    CodeGameScreenMagicLadyMachine.super.beginReel(self)
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        --2、4列不滚动
        self.m_slotParents[2].isReeling = false
        self.m_slotParents[4].isReeling = false

        self.m_slotParents[2].isResActionDone = true
        self.m_slotParents[4].isResActionDone = true
    end
end

--
--隐藏盘面图标
function CodeGameScreenMagicLadyMachine:hideSymbolByRowCol(col, row)
    local slotParentData = self.m_slotParents[col]
    if slotParentData ~= nil then
        local slotParent = slotParentData.slotParent
        local slotParentBig = slotParentData.slotParentBig
        local childs = slotParent:getChildren()
        if slotParentBig then
            local newChilds = slotParentBig:getChildren()
            for j=1,#newChilds do
                childs[#childs+1] = newChilds[j]
            end
        end
        local clipChild = self.m_clipParent:getChildren()
        for i,v in ipairs(clipChild) do
            childs[#childs+1] = clipChild[i]
        end
        local index = 1
        while true do
            if index > #childs then
                break
            end
            local child = childs[index]
            if child.p_cloumnIndex == col and child.p_rowIndex == row then
                child:setVisible(false)
            end
            index = index + 1
        end
    end
end

--切换到normal盘面(freespin切到normal)
function CodeGameScreenMagicLadyMachine:changeToNormalLayer()
    --轮盘动画
    self:runCsbAction("over")
    --背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"over1")
    
    gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_changeToNormalEffect.mp3")
    
    self.m_magicLadyQiuNode:setVisible(true)
    self.m_magicLadyHandNode:setVisible(true)
    --魔女动画
    self:findChild("spine_SHOUZHI"):setLocalZOrder(3)
    util_spinePlay(self.m_magicLadyNode,"actionframe3",false)
    util_spinePlay(self.m_magicLadyQiuNode,"actionframe3",false)
    util_spinePlay(self.m_magicLadyHandNode,"actionframe3",false)
    util_spineEndCallFunc(self.m_magicLadyQiuNode,"actionframe3",function ()
        util_spinePlay(self.m_magicLadyNode,"idleframe",true)
        util_spinePlay(self.m_magicLadyQiuNode,"idleframe",true)
        util_spinePlay(self.m_magicLadyHandNode,"idleframe",true)

        self:triggerFreeSpinOverCallFun()
    end)
    performWithDelay(self,function()
        self:clearWinLineEffect()
        self.m_magicLadyNode:setVisible(true)
        self.m_jackpotBar:setVisible(true)
        self.m_freespinBar:setVisible(false)

        --隐藏盘面不要的图标
        self:changeToNormalHideRedundantSymbol()
        --修改总行数为normal行数
        self:changeToNormalRowNum()
        --更改裁切区域
        self:changeClipRegion()
        --滚轴属性修改为normal盘面的
        self:changeReelAttributeToNormal()
        --给normal盘上面添加必要的图标
        self:addSymbolToNormalLayer()

        -- self:triggerFreeSpinOverCallFun()
    end,10/30)
end
--切换freespin盘面之前，先删除普通盘面上的多余不用的图标
function CodeGameScreenMagicLadyMachine:changeToNormalHideRedundantSymbol()
    --第3列全隐藏（1-4行）
    for i = 1,4 do
        self:hideSymbolByRowCol(3,i)
    end
end
--修改总行数为normal行数(理论上应该走配置，配置读取流程还不太熟悉，时间紧，先这么写吧)
function CodeGameScreenMagicLadyMachine:changeToNormalRowNum()
    self.m_iReelRowNum = 3
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
end
--滚轴属性修改为normal盘面的
function CodeGameScreenMagicLadyMachine:changeReelAttributeToNormal()
    for i = 1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        columnData:updateShowColCount(self.m_iReelRowNum)
    end
    self:slotsReelRunData(self.m_configData.p_reelRunDatas,self.m_configData.p_bInclScatter
            ,self.m_configData.p_bInclBonus,self.m_configData.p_bPlayScatterAction
                ,self.m_configData.p_bPlayBonusAction)
end
--给normal盘上面添加必要的图标
function CodeGameScreenMagicLadyMachine:addSymbolToNormalLayer()
    --给2、4列添加普通小图标
    local colList = {2,4}
    for index = 1,#colList do
        local colIndex = colList[index]
        for rowIndex = 1, self.m_iReelRowNum do
            local symbolType = self:getOneNorSymbol()
            local parentData = self.m_slotParents[colIndex]
            local reelColData = self.m_reelColDatas[colIndex]
            local halfNodeH = reelColData.p_showGridH * 0.5
            local showOrder = self:getBounsScatterDataZorder(symbolType)
            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            node.p_slotNodeH = reelColData.p_showGridH
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)
            node.p_reelDownRunAnima = parentData.reelDownAnima
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
        end
    end
    --第三列隐藏图标的位置全部填充普通小图标
    local colIndex = 3
    for rowIndex = 1, 12 do
        local symbolType = self:getOneNorSymbol()
        local parentData = self.m_slotParents[colIndex]
        local reelColData = self.m_reelColDatas[colIndex]
        local halfNodeH = reelColData.p_showGridH * 0.5
        local showOrder = self:getBounsScatterDataZorder(symbolType)
        local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
        parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
        node.p_slotNodeH = reelColData.p_showGridH
        node.p_symbolType = symbolType
        node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)
        node.p_reelDownRunAnima = parentData.reelDownAnima
        node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
        node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
    end
end



---------------------------------------------------------------------------

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenMagicLadyMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum
    local animTime = 0

    for i=1,frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        
        local slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
        
        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and
            self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then

            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do

                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex=1,#bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then

                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        if slotNode==nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        end
                        break
                    end
                end

            end
        end

        if slotNode ~= nil then
            slotNode = self:setSlotNodeEffectParent(slotNode)
            slotNode:runAnim("actionframe",false)
            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenMagicLadyMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()
        -- self:resetMaskLayerNodes()
        callFun()
    end,util_max(2,animTime),self:getModuleName())
end
-- 触发freespin时调用（scatter触发动画结束后调用）
function CodeGameScreenMagicLadyMachine:showFreeSpinView(effectData)
    local showFSView = function ()
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_scatter_TriggerFreespin.mp3")
            for row = 1,3 do
                local slotNode = self:getFixSymbol(3,row,SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == self.SYMBOL_BIG_SCORE_SCATTER then
                    self:setSlotNodeEffectParent(slotNode)
                    slotNode:runAnim("actionframe",false,function ()
                        -- slotNode:runAnim("idleframe")
                    end)
                end
            end
            
            performWithDelay(self,function()
                -- gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_showFreespinMoreView.mp3")
                -- self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                --     effectData.p_isPlay = true
                --     self:playGameEffect()
                -- end,true)

                -- performWithDelay(self,function()
                --     for row = 1,3 do
                --         local slotNode = self:getFixSymbol(3,row,SYMBOL_NODE_TAG)
                --         if slotNode and slotNode.p_symbolType == self.SYMBOL_BIG_SCORE_SCATTER then
                --             slotNode:runAnim("idleframe")
                --         end
                --     end
                -- end,0.5)
                self:resetMusicBg(true)
                gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
                effectData.p_isPlay = true
                self:playGameEffect()
            end,3.0)
        else
            self:triggerFreeSpinCallFun()
            performWithDelay(self,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,4.0)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function()
        showFSView()
    end,0.5)
end

function CodeGameScreenMagicLadyMachine:triggerFreeSpinCallFun()

    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    --做下判断 freespinMore 与 普通触发fs 防止fsmore 断线重连后不显示fs赢钱
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    -- 通知任务变化
    -- gLobalTaskManger:triggerTask(TASK_TRIGGER_FREE_SPIN)

    -- 处理free spin 后的回调
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        -- gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)  -- 向spin按钮发送消息

    local time = 0
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:showFreeSpinBar()
        time = 3
    end

    self:setCurrSpinMode( FREE_SPIN_MODE )
    self.m_bProduceSlots_InFreeSpin = true
    performWithDelay(self,function ()
        self:resetMusicBg()
    end,time)
end

-- 触发freespin结束时调用
function CodeGameScreenMagicLadyMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_FreespinOverView.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,50)

    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            performWithDelay(self,function()
                -- 调用此函数才是把当前游戏置为freespin结束状态
                -- self:triggerFreeSpinOverCallFun()
                self:changeToNormalLayer()
            end,1.0)
    end)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},852)
end

function CodeGameScreenMagicLadyMachine:getOneBigSymbol()
    local symbolList = {
            self.SYMBOL_BIG_SCORE_10,
            self.SYMBOL_BIG_SCORE_1,
            self.SYMBOL_BIG_SCORE_2,
            self.SYMBOL_BIG_SCORE_3,
            self.SYMBOL_BIG_SCORE_4,
            self.SYMBOL_BIG_SCORE_5,
            self.SYMBOL_BIG_SCORE_6,
            self.SYMBOL_BIG_SCORE_7,
            self.SYMBOL_BIG_SCORE_8,
            self.SYMBOL_BIG_SCORE_9,
            self.SYMBOL_BIG_SCORE_WILD
        }
    return symbolList[math.random(1,#symbolList)]
end
function CodeGameScreenMagicLadyMachine:getOneNorSymbol()
    local symbolList = {0,1,2,3,4,5,6,7,8,9}
    return symbolList[math.random(1,#symbolList)]
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMagicLadyMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)


    return false -- 用作延时点击spin调用
end

function CodeGameScreenMagicLadyMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(function()
        if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) then

        else
            gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_enter.mp3")
            scheduler.performWithDelayGlobal(function ()
                self:resetMusicBg()
                if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
                    self:setMinMusicBGVolume()
                end
            end,2.5,self:getModuleName())
        end
    end,0.4,self:getModuleName())
end

function CodeGameScreenMagicLadyMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    self:checkUpateDefaultBet()
    self:initTopCommonJackpotBar()
    self:updataJackpotStatus()

    CodeGameScreenMagicLadyMachine.super.onEnter(self)
    self:addObservers()

    if self.m_bottomUI.m_spinBtn.addTouchLayerClick and self.m_touchSpinLayerRs then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_touchSpinLayerRs)
    end

    local hasFeature = self:checkHasFeature()
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE and not hasFeature then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_ONENTER)
    end
end

function CodeGameScreenMagicLadyMachine:addObservers()
	CodeGameScreenMagicLadyMachine.super.addObservers(self)
    -- 播放赢钱动画
    gLobalNoticManager:addObserver(self,function(self,params)  
        if self.m_bIsBigWin then
            return
        end

        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 3
        else
            soundIndex = 3
            soundTime = 3
        end

        local soundName = "MagicLadySounds/music_MagicLady_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

        
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)


     -- respin一个轮盘一列停止
     gLobalNoticManager:addObserver(self,function(self,params)  
        self:reSpinOneWheelOneReelDown(params[1],params[2])
    end,"CodeGameScreenMagicLadyMachine_reSpinOneWheelOneReelDown")

    --增加respin次数的飞行特效显示
    gLobalNoticManager:addObserver(self,function(self,params)  
        self:addRespinNumFlyEffect(params[1])
    end,"CodeGameScreenMagicLadyMachine_addRespinNumFlyEffect")

    --更改respin背景音乐
    gLobalNoticManager:addObserver(self,function(self,params)  
        self:changeRespinBg()
    end,"CodeGameScreenMagicLadyMachine_changeRespinBg")

    --ReSpin刷新数量
    gLobalNoticManager:addObserver(self,function(self,params)
        self.m_respinBar:findChild("Particle_1"):setVisible(true)
        self.m_respinBar:findChild("Particle_1"):setPositionType(0)
        self.m_respinBar:findChild("Particle_1"):resetSystem()
        self.m_respinBar:playAction("actionframe",false,function ()
            self.m_respinBar:findChild("Particle_1"):setVisible(false)
        end)
        
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    end,"CodeGameScreenMagicLadyMachine_changeReSpinUpdateUI")

    gLobalNoticManager:addObserver(self,function(self, params)
        --公共jackpot
        self:updataJackpotStatus(params)
    end,ViewEventType.NOTIFY_BET_CHANGE)
    
    --公共jackpot活动结束
    gLobalNoticManager:addObserver(self,function(target, params)

        if params.name == ACTIVITY_REF.CommonJackpot then
            self.m_isJackpotEnd = true
            self:updataJackpotStatus()
        end

    end,ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)
end

function CodeGameScreenMagicLadyMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMagicLadyMachine.super.onExit(self)
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())

    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearTitleNode()
    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearEntryNode()
end



-- ------------玩法处理 -- 

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenMagicLadyMachine:MachineRule_network_InterveneSymbolMap()

end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenMagicLadyMachine:MachineRule_afterNetWorkLineLogicCalculate()
    --消息解析之后调用，
   
    -- self.m_runSpinResultData 可以从这个里边取网络数据
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMagicLadyMachine:addSelfEffect()
    

        -- 自定义动画创建方式
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型
end
--添加连线动画
function CodeGameScreenMagicLadyMachine:addLineEffect()
    if self.m_runSpinResultData.p_features[2] == 3 
        or (self.m_runSpinResultData.p_features[2] == 1 and self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount) then
        --freespin respin触发轮 直接加钱，不播连线动画

        --加钱
        self:checkNotifyUpdateWinCoin()
        return
    end
    CodeGameScreenMagicLadyMachine.super.addLineEffect(self)

    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
        self.m_bIsBigWin = false
        self:removeEffectByType(GameEffect.EFFECT_EPICWIN)
        self:removeEffectByType(GameEffect.EFFECT_MEGAWIN)
        self:removeEffectByType(GameEffect.EFFECT_BIGWIN)
        --重连没连线的时候这个值是没有的
        if self.m_fLastWinBetNumRatio and self.m_fLastWinBetNumRatio > 0 then
            self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
        end
    end
end
--连线的时候通知更新钱数，并播音效
function CodeGameScreenMagicLadyMachine:checkNotifyUpdateWinCoin()
    CodeGameScreenMagicLadyMachine.super.checkNotifyUpdateWinCoin(self)

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = self.m_iOnceSpinLastWin / totalBet
    if winRate > 3 and winRate < self.m_BigWinLimitRate then
        local index = math.random(4,5)
        gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_last_win_".. index .. ".mp3")
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMagicLadyMachine:MachineRule_playSelfEffect(effectData)

    -- if effectData.p_selfEffectType == self.QUICKHIT_JACKPOT_EFFECT then

    --     

    -- end

    
	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenMagicLadyMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

--获得信号块层级
function CodeGameScreenMagicLadyMachine:getBounsScatterDataZorder(symbolType)
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER 
        or symbolType ==  self.SYMBOL_BIG_SCORE_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif self:isFixSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD 
        or symbolType == self.SYMBOL_BIG_SCORE_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else
        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分值越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order
end

function CodeGameScreenMagicLadyMachine:showAllFrame(winLines)

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then

            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then

            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            -- end

        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index=1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s","")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i=1,frameNum do

            local symPosData = lineValue.vecValidMatrixSymPos[i]


            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then

                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local columnData = self.m_reelColDatas[symPosData.iY]

                local showLineGridH = columnData.p_slotColumnHeight / columnData:getLinePosLen( )

                local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5

                local showGridH = columnData.p_showGridH 
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    showGridH = self.m_reelColDatas[1].p_showGridH 
                end
                local posY = showGridH * symPosData.iX - showGridH * 0.5 + columnData.p_slotColumnPosY

                local node = self:getFrameWithPool(lineValue,symPosData)
                node:setPosition(cc.p(posX,posY))

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

            end

        end
    end

end

function CodeGameScreenMagicLadyMachine:showLineFrameByIndex(winLines,frameIndex)

    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s","")
    end
    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then

            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then

            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end

        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i=1,frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5
        local showGridH = columnData.p_showGridH 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            showGridH = self.m_reelColDatas[1].p_showGridH 
        end
        local posY = showGridH * symPosData.iX - showGridH * 0.5 + columnData.p_slotColumnPosY
        
        local node = nil
        if i <=  hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue,symPosData)
        end
        node:setPosition(cc.p(posX,posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
               self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end

            -- if runTimes ~= nil then
            --     node:runDefaultFrameTime(runTimes)
            -- else
            --     node:runDefaultAnim()
            -- end
            node:runAnim("actionframe",true)
        else
            node:runAnim("actionframe",true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end

    end
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    slotsNode:runLineAnim()
                end
            end
        end
    end
end

function CodeGameScreenMagicLadyMachine:setBigNodeData(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not symbolNode.p_symbolType then
        return
    end

    if symbolNode.m_isLastSymbol and symbolNode.m_isLastSymbol == true then
        symbolNode.m_bInLine = true
        local linePos = {}
        for colIndex = 2, 4 do
            for rowIndex = (iRow - 1) * 3 + 1, iRow * 3 do
                linePos[#linePos + 1] = {iX = rowIndex, iY = colIndex}
            end
        end
        symbolNode:setLinePos(linePos)
    end       
end

----
--- 处理spin 成功消息
--
function CodeGameScreenMagicLadyMachine:checkOperaSpinSuccess( param )
    --freespin下修改轮盘数据  将第三列 1、4、7行数据写到1、2、3行
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local reelsData = param[2].result.reels
        reelsData[#reelsData - 1][3] = reelsData[#reelsData - 3][3]
        reelsData[#reelsData - 2][3] = reelsData[#reelsData - 6][3]
    end
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        -- 触发了玩法 一定概率播特效
        if param[2].result.features[2] ~= nil then
            local rand = math.random(0,2)
            if rand == 0 then
                self:showTriggerEffect()
            end
        end
    end
    
    if self.m_isVisibleTriggerEffect then
        self.m_waitChangeReelTime = 2
        CodeGameScreenMagicLadyMachine.super.checkOperaSpinSuccess(self,param)
        -- --不能快停
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    else
        CodeGameScreenMagicLadyMachine.super.checkOperaSpinSuccess(self,param)
    end
end
function CodeGameScreenMagicLadyMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()
    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()

    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end
--进关时的初始化数据  底层的数据读取一点都不统一
function CodeGameScreenMagicLadyMachine:initGameStatusData(gameData)
    if gameData.spin then
        if gameData.spin.action == "FREESPIN" then
            local reelsData =  gameData.spin.reels
            local symbolType1 = reelsData[#reelsData][3]--第一行的图标
            local symbolType2 = reelsData[#reelsData - 3][3]--第二行的图标
            local symbolType3 = reelsData[#reelsData - 6][3]--第三行的图标
            reelsData[#reelsData - 1][3] = symbolType2
            reelsData[#reelsData - 2][3] = symbolType3
            reelsData[#reelsData - 3][3] = symbolType1
            reelsData[#reelsData - 4][3] = symbolType2
            reelsData[#reelsData - 5][3] = symbolType3
            reelsData[#reelsData - 6][3] = symbolType1
            reelsData[#reelsData - 7][3] = symbolType2
            reelsData[#reelsData - 8][3] = symbolType3
        end
    end
    CodeGameScreenMagicLadyMachine.super.initGameStatusData(self,gameData)

end

--===================================respin逻辑=====================================
function CodeGameScreenMagicLadyMachine:showRespinJackpot(index,coins,func)
    local jackPotWinView = util_createView("CodeMagicLadySrc.MagicLadyJackPotWinView",{machine = self})
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,func)
    gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_jackpotLayer.mp3")
end

-- 结束respin收集
function CodeGameScreenMagicLadyMachine:playLightEffectEnd()
    self:respinOver()
end
function CodeGameScreenMagicLadyMachine:respinOver()
    performWithDelay(self,function ()
        self:showRespinOverView()
    end,0.5)
end
--根据轮盘编号，行，列获取lighting图标获得钱数
function CodeGameScreenMagicLadyMachine:getLightingCoins(col,row,wheelIndex)
    local pos = (self.m_iReelRowNum - row) * self.m_iReelColumnNum + col - 1 + (3 - wheelIndex) * 15
    for i,v in ipairs(self.m_runSpinResultData.p_winLines) do
        if self.m_runSpinResultData.p_winLines[i].p_iconPos[1] == pos then
            return self.m_runSpinResultData.p_winLines[i].p_amount
        end
    end
    return 0
end 
-- 收集粒子设置  settingType 0 创建并初始化  1收集满图标奖励 2 收集满图标奖励完 3 收集当前轮盘图标  4 收集当前轮盘一个图标结束
function CodeGameScreenMagicLadyMachine:collectParticleSetting(settingType)
    if self.m_collectParticle == nil then
        self.m_collectParticle = util_createAnimation("MagicLady_xiaoqiuTW.csb")
        self.m_collectParticle:setScale(self.m_machineRootScale)
        self:addChild(self.m_collectParticle,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
        -- self.m_collectParticle:findChild("Particle_1"):setVisible(false)
        -- self.m_collectParticle:findChild("Particle_2"):setVisible(false)
        -- self.m_collectParticle:findChild("Particle_3"):setVisible(false)
        -- self.m_collectParticle:findChild("Particle_4"):setVisible(false)
        -- self.m_collectParticle:findChild("Particle_1"):stopSystem()
        -- self.m_collectParticle:findChild("Particle_2"):stopSystem()
        -- self.m_collectParticle:findChild("Particle_3"):stopSystem()
        -- self.m_collectParticle:findChild("Particle_4"):stopSystem()
    end
    if settingType == 1 then
        -- self.m_collectParticle:findChild("Particle_1"):setVisible(false)
        -- self.m_collectParticle:findChild("Particle_2"):setVisible(false)
        -- self.m_collectParticle:findChild("Particle_3"):setVisible(false)
        -- self.m_collectParticle:findChild("Particle_4"):setVisible(true)
        -- self.m_collectParticle:findChild("Particle_4"):setPositionType(0)
        -- self.m_collectParticle:findChild("Particle_4"):resetSystem()
        if self.m_currCollectWheelIndex == 1 then
            self.m_collectParticle:playAction("actionframe7")
        else
            self.m_collectParticle:playAction("actionframe6")
        end
    end 
    if settingType == 2 then
        -- self.m_collectParticle:findChild("Particle_1"):stopSystem()
    end
    if settingType == 3 then
        if self.m_currCollectWheelIndex == 3 then
            -- self.m_collectParticle:findChild("Particle_1"):setVisible(true)
            -- self.m_collectParticle:findChild("Particle_2"):setVisible(false)
            -- self.m_collectParticle:findChild("Particle_3"):setVisible(false)
            -- self.m_collectParticle:findChild("Particle_4"):setVisible(false)
            -- self.m_collectParticle:findChild("Particle_1"):setPositionType(0)
            -- self.m_collectParticle:findChild("Particle_1"):resetSystem()
            self.m_collectParticle:playAction("actionframe1")
        elseif self.m_currCollectWheelIndex == 2 then
            -- self.m_collectParticle:findChild("Particle_1"):setVisible(false)
            -- self.m_collectParticle:findChild("Particle_2"):setVisible(true)
            -- self.m_collectParticle:findChild("Particle_3"):setVisible(false)
            -- self.m_collectParticle:findChild("Particle_4"):setVisible(false)
            -- self.m_collectParticle:findChild("Particle_2"):setPositionType(0)
            -- self.m_collectParticle:findChild("Particle_2"):resetSystem()
            self.m_collectParticle:playAction("actionframe2")
        elseif self.m_currCollectWheelIndex == 1 then
            -- self.m_collectParticle:findChild("Particle_1"):setVisible(false)
            -- self.m_collectParticle:findChild("Particle_2"):setVisible(false)
            -- self.m_collectParticle:findChild("Particle_3"):setVisible(true)
            -- self.m_collectParticle:findChild("Particle_4"):setVisible(false)
            -- self.m_collectParticle:findChild("Particle_3"):setPositionType(0)
            -- self.m_collectParticle:findChild("Particle_3"):resetSystem()
            self.m_collectParticle:playAction("actionframe3")
        end
    end
    if settingType == 4 then
        -- if self.m_currCollectWheelIndex == 3 then
        --     self.m_collectParticle:findChild("Particle_1"):stopSystem()
        -- elseif self.m_currCollectWheelIndex == 2 then
        --     self.m_collectParticle:findChild("Particle_2"):stopSystem()
        -- elseif self.m_currCollectWheelIndex == 1 then
        --     self.m_collectParticle:findChild("Particle_3"):stopSystem()
        -- end
    end
end
--根据起始结束位置初始化收集特效
function CodeGameScreenMagicLadyMachine:initCollectParticle(startPos,endPos)
    self.m_collectParticle:setPosition(cc.p((endPos.x + startPos.x)/2,(endPos.y + startPos.y)/2 ))
    local hudu = math.atan2(endPos.x - startPos.x, endPos.y - startPos.y)
    local jiaodu = math.deg(hudu)
    self.m_collectParticle:setRotation(jiaodu)
    local scaleY = cc.pGetDistance(endPos,startPos)/self.m_collectParticle:findChild("Sprite_1"):getContentSize().height
    self.m_collectParticle:setScaleY(scaleY)
end
-- respin结束时收集
function CodeGameScreenMagicLadyMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        --一个轮盘收集完，去收集下一个轮盘
        self.m_currCollectWheelIndex = self.m_currCollectWheelIndex - 1
        self:collectFullPrize()
        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    chipNode:runAnim("actionframe2")
    -- local worldPos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPosition()))
    -- local nodePos = self:convertToNodeSpace(worldPos)
    -- self.m_collectParticle:setPosition(nodePos)
    -- self:collectParticleSetting(3)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            
    -- local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol - 1

    local scoreMultiple = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol),self.m_currCollectWheelIndex) 
    
    local addScore = self:getLightingCoins(iCol,iRow,self.m_currCollectWheelIndex)
    local nJackpotType = 0
    
    if scoreMultiple == "GRAND" then
        nJackpotType = 4
    elseif scoreMultiple == "MAJOR" then
        nJackpotType = 3
    elseif scoreMultiple == "MINOR" then
        nJackpotType = 2
    elseif scoreMultiple == "MINI" then
        nJackpotType = 1
    end

    self.m_lightScore = self.m_lightScore + addScore

    local function runCollect()
        if nJackpotType <= 1 then
            self.m_playAnimIndex = self. m_playAnimIndex + 1
            self:playChipCollectAnim() 
        else
            -- self:showRespinJackpot(nJackpotType, util_formatCoins(addScore,12), function()
            self:showRespinJackpot(nJackpotType, addScore, function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim()
            end)
        end
    end
    
    -- local worldPos = cc.p(self.m_winBar:findChild("m_lb_win"):getParent():convertToWorldSpace(cc.p(self.m_winBar:findChild("m_lb_win"):getPosition())))
    -- local endPos = cc.p(self:convertToNodeSpace(worldPos))

    -- self:initCollectParticle(nodePos,endPos)

    -- local moveTo = cc.MoveTo:create(0.2,endPos)
    -- local delay1 = cc.DelayTime:create(5/30)
    -- local callFunc1 = cc.CallFunc:create(function()
    --     self:collectParticleSetting(4)
        self.m_winBar:playAction("actionframe"..self.m_currCollectWheelIndex)
        if nJackpotType >= 1 then
            gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_lightingCollectMini.mp3")
        else
            gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_lightingCollect"..self.m_currCollectWheelIndex..".mp3")
        end
        self.m_winBar:findChild("m_lb_win"):setString(util_formatCoins(self.m_lightScore,50))
        local info = {label = self.m_winBar:findChild("m_lb_win"),sx = 0.5,sy = 0.5}
        self:updateLabelSize(info,1100)
        self.m_winBar:findChild("m_lb_win"):setVisible(true)
        -- self.m_winBar:findChild("MagicLady_jackpot_zi6_1"):setVisible(false)
        self.m_respinBar:setVisible(false)
        self.m_winBar:setVisible(true)
    -- end)
    -- local time = 0.1
    -- if self.m_currCollectWheelIndex == 3 then
    --     time = 0.1
    -- elseif self.m_currCollectWheelIndex == 2 then
    --     time = 0.05
    -- elseif self.m_currCollectWheelIndex == 1 then
    --     time = 0
    -- end
    -- local delay = cc.DelayTime:create(time + 20/30 - 5/30)
    -- local callFunc2 = cc.CallFunc:create(function()
    --     runCollect()
    -- end)
    -- local seq = cc.Sequence:create(delay1,callFunc1,delay,callFunc2)
    -- self.m_collectParticle:runAction(seq)

    performWithDelay(self,function ()
        runCollect()
    end,0.5)
end
--respin结束   收集一个轮盘满图标奖励的钱
function CodeGameScreenMagicLadyMachine:collectFullPrize()
    local fullDataTab = nil
    local fullData = nil
    if self.m_runSpinResultData.p_rsExtraData then
        fullDataTab = self.m_runSpinResultData.p_rsExtraData.full
    end
    if fullDataTab then
        for i,v in ipairs(fullDataTab) do
            if self.m_currCollectWheelIndex == 3 then
                if v.position == "up" then
                    fullData = v
                end
            elseif self.m_currCollectWheelIndex == 2 then
                if v.position == "middle" then
                    fullData = v
                end
            elseif self.m_currCollectWheelIndex == 1 then
                if v.position == "bottom" then
                    fullData = v
                end
            end
        end
    end
    if fullData == nil then
        --当前轮盘没满，直接收集图标
        self:collectOneWheelChip()
    else
        local prizeNode = self.m_respinPrizeNodeTab[self.m_currCollectWheelIndex]
        gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_last_win_4.mp3")
        prizeNode:playAction("actionframe",false,function ()
            prizeNode:playAction("over")
            local worldPos1 = prizeNode:getParent():convertToWorldSpace(cc.p(prizeNode:getPosition()))
            local nodePos = self:convertToNodeSpace(worldPos1)
            self.m_collectParticle:setPosition(nodePos)
            self:collectParticleSetting(1)

            self.m_collectParticle:findChild("BitmapFontLabel_1"):setString(util_formatCoins(fullData.coins,20,nil,nil,true))
            local info = {label = self.m_collectParticle:findChild("BitmapFontLabel_1"),sx = 0.55,sy = 0.55}
            self:updateLabelSize(info,621)

            self.m_lightScore = self.m_lightScore + fullData.coins
            local worldPos2 = cc.p(self.m_winBar:findChild("m_lb_win"):getParent():convertToWorldSpace(cc.p(self.m_winBar:findChild("m_lb_win"):getPosition())))
            local endPos = cc.p(self:convertToNodeSpace(worldPos2))

            -- self:initCollectParticle(nodePos,endPos)
            local moveTime = 10/30
            if self.m_currCollectWheelIndex == 1 then
                moveTime = 22/30
            end
            local moveTo = cc.MoveTo:create(moveTime,endPos)
            -- local delay1 = cc.DelayTime:create(5/30)
            local callFunc1 = cc.CallFunc:create(function()
                self:collectParticleSetting(2)
                
                self.m_winBar:playAction("actionframe4")
                gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_lightingCollect4.mp3") 
                self.m_winBar:findChild("m_lb_win"):setString(util_formatCoins(self.m_lightScore,50))
                local info = {label = self.m_winBar:findChild("m_lb_win"),sx = 0.5,sy = 0.5}
                self:updateLabelSize(info,1100)
                self.m_winBar:findChild("m_lb_win"):setVisible(true)
                -- self.m_winBar:findChild("MagicLady_jackpot_zi6_1"):setVisible(false)
                self.m_respinBar:setVisible(false)
                self.m_winBar:setVisible(true)
            end)
            -- local time = 0.1
            -- if self.m_currCollectWheelIndex == 3 then
            --     time = 0.1
            -- elseif self.m_currCollectWheelIndex == 2 then
            --     time = 0.05
            -- elseif self.m_currCollectWheelIndex == 1 then
            --     time = 0
            -- end
            -- local delay2 = cc.DelayTime:create(time + 20/30 - 5/30)
            -- local callFunc2 = cc.CallFunc:create(function()
            --     self:collectOneWheelChip()
            -- end)
            local seq = cc.Sequence:create(moveTo,callFunc1)
            self.m_collectParticle:runAction(seq)
            performWithDelay(self,function ()
                self:collectOneWheelChip()
            end,moveTime + 0.7)
        end)
    end
end
--respin结束收集一个轮盘的lighting图标钱
function CodeGameScreenMagicLadyMachine:collectOneWheelChip()
    if self.m_currCollectWheelIndex <= 0 then
        --所有轮盘都收集完了，弹出respin结算弹框
        self:playLightEffectEnd()
        return
    end
    self.m_playAnimIndex = 1
    self.m_chipList = self.m_respinViewTab[self.m_currCollectWheelIndex]:getAllCleaningNode()
    self:playChipCollectAnim()
end
--respin结束调用
function CodeGameScreenMagicLadyMachine:reSpinEndAction()
    self:clearCurMusicBg()
    self.m_lightScore = 0
    self.m_currCollectWheelIndex = 3
    self.m_winBar:findChild("m_lb_win"):setVisible(true)
    -- self.m_winBar:findChild("MagicLady_jackpot_zi6_1"):setVisible(false)
    self.m_respinBar:setVisible(false)
    self.m_winBar:setVisible(true)

    for wheelIndex,respinView in ipairs(self.m_respinViewTab) do
        local respinList = respinView:getAllCleaningNode()
        for i=1,#respinList do
            respinList[i]:runAnim("actionframe3",false)
        end
    end
    gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_lighting_actionframe3.mp3")
    self:collectParticleSetting(0)

    performWithDelay(self,function()
        -- 开始收集
        self:collectFullPrize()
    end,2.2)
end
-- 获取respin下出现的普通小块类型数组
function CodeGameScreenMagicLadyMachine:getRespinRandomTypes()
    local symbolList = {
        self.SYMBOL_SCORE_10,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    }

    return symbolList
end

-- 获取respin下出现的lighting图标数组
function CodeGameScreenMagicLadyMachine:getRespinLockTypes()
    local symbolList = {
        {
            {type = self.SYMBOL_FIX_RED_SYMBOL, runEndAnimaName = "buling", bRandom = true},
            {type = self.SYMBOL_FIX_RED_MINI, runEndAnimaName = "buling", bRandom = true},
            {type = self.SYMBOL_FIX_RED_MINOR, runEndAnimaName = "buling", bRandom = true},
            {type = self.SYMBOL_FIX_RED_MAJOR, runEndAnimaName = "buling", bRandom = true},
            {type = self.SYMBOL_FIX_RED_GRAND, runEndAnimaName = "buling", bRandom = true}
        },
        {
            {type = self.SYMBOL_FIX_BLUE_SYMBOL, runEndAnimaName = "buling", bRandom = true},
            {type = self.SYMBOL_FIX_BLUE_MINI, runEndAnimaName = "buling", bRandom = true},
            {type = self.SYMBOL_FIX_BLUE_MINOR, runEndAnimaName = "buling", bRandom = true},
            {type = self.SYMBOL_FIX_BLUE_MAJOR, runEndAnimaName = "buling", bRandom = true},
            {type = self.SYMBOL_FIX_BLUE_GRAND, runEndAnimaName = "buling", bRandom = true}
        },
        {
            {type = self.SYMBOL_FIX_GREEN_SYMBOL, runEndAnimaName = "buling", bRandom = true},
            {type = self.SYMBOL_FIX_GREEN_MINI, runEndAnimaName = "buling", bRandom = true},
            {type = self.SYMBOL_FIX_GREEN_MINOR, runEndAnimaName = "buling", bRandom = true},
            {type = self.SYMBOL_FIX_GREEN_MAJOR, runEndAnimaName = "buling", bRandom = true},
            {type = self.SYMBOL_FIX_GREEN_GRAND, runEndAnimaName = "buling", bRandom = true}
        }
    }

    return symbolList
end
---
-- 根据类型获取对应节点
--
function CodeGameScreenMagicLadyMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = CodeGameScreenMagicLadyMachine.super.getSlotNodeBySymbolType(self,symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL
        or symbolType == self.SYMBOL_FIX_MINI
        or symbolType == self.SYMBOL_FIX_MINOR
        or symbolType == self.SYMBOL_FIX_MAJOR
        or symbolType == self.SYMBOL_FIX_GRAND then
        reelNode.p_idleIsLoop = true
    end
    return reelNode
end
function CodeGameScreenMagicLadyMachine:showRespinView(effectData)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_WIN_RESPIN)
    --先播放动画 再进入respin
    --重连感觉节奏有点问题,有些动画好像是被覆盖了,这里延迟一点再播吧
    performWithDelay(self,function()
        self:clearCurMusicBg()
        local waitTime = 1
        if self.m_isReconnection == false then
            --播放触发动画
            for row = 1, self.m_iReelRowNum do
                for col = 1, self.m_iReelColumnNum do
                    local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
                    if slotNode and self:isFixSymbol(slotNode.p_symbolType) then
                        local showOrder = self:getBounsScatterDataZorder(slotNode.p_symbolType)
                        slotNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 - row + showOrder)
                        self:setSlotNodeEffectParent(slotNode)
                        slotNode:runAnim("actionframe",false,function ()
                            slotNode:runAnim("idleframe",true)
                        end)
                    end
                end
            end
            gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_scatter_TriggerRespin.mp3")
            waitTime = 2.5
        else
            --播放idle动画
            for row = 1, self.m_iReelRowNum do
                for col = 1, self.m_iReelColumnNum do
                    local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
                    if slotNode and self:isFixSymbol(slotNode.p_symbolType) then
                        local showOrder = self:getBounsScatterDataZorder(slotNode.p_symbolType)
                        slotNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 - row + showOrder)
                        self:setSlotNodeEffectParent(slotNode)
                        slotNode:runAnim("idleframe",true)
                    end
                end
            end
        end

        performWithDelay(self,function()
            -- self:resetMaskLayerNodes()
            --可随机的普通信号块
            local randomTypes = self:getRespinRandomTypes()
            --可随机的特殊信号 
            local endTypes = self:getRespinLockTypes()
            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)
    
            gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_changeToEffect.mp3")
            --轮盘动画
            self:runCsbAction("start2")
            --背景动画
            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"start1")
            --魔女动画
            self:findChild("spine_SHOUZHI"):setLocalZOrder(0)
            util_spinePlay(self.m_magicLadyNode,"actionframe2",false)
            util_spinePlay(self.m_magicLadyQiuNode,"actionframe2",false)
            util_spinePlay(self.m_magicLadyHandNode,"actionframe2",false)
            util_spineEndCallFunc(self.m_magicLadyQiuNode,"actionframe2",function ()
                self.m_magicLadyNode:setVisible(false)
                self.m_magicLadyQiuNode:setVisible(false)
                self.m_magicLadyHandNode:setVisible(false)
            end)
            performWithDelay(self,function()
                self:setCurrSpinMode( RESPIN_MODE )
                self.m_specialReels = true
    
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                self:clearWinLineEffect()
    
                self:changeToRespinLayer()
            end,70/30)
    
            performWithDelay(self,function()
                if self:isRespinInit() then
                    self:startFlyLightingToTop()
                else
                    self:runNextReSpinReel()
                    self:resetMusicBg()
                end
            end,4)
        end,waitTime)
    end,0.1)
end
--重置当前背景音乐名称
function CodeGameScreenMagicLadyMachine:resetCurBgMusicName()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        for i,respinView in ipairs(self.m_respinViewTab) do
            local num = 0
            if i == 1 then
                num = #self.m_runSpinResultData.p_storedIcons
            elseif i == 2 then
                num = #self.m_runSpinResultData.p_rsExtraData.middleStoreIcons
            elseif i == 3 then
                num = #self.m_runSpinResultData.p_rsExtraData.upStoredIcons
            end
            if num >= 12 then
                self.m_currentMusicBgName = "MagicLadySounds/music_MagicLady_RespinBG2.mp3"
                break
            end
        end
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end
end
--触发respin
function CodeGameScreenMagicLadyMachine:triggerReSpinCallFun(endTypes, randomTypes)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize(true)
    end

    for i,respinWheelNode in ipairs(self.m_respinWheelNodeTab) do
        local respinView = util_createView(self:getRespinView(), self:getRespinNode())
        respinView.m_wheelIndex = i
        if self:isRespinInit() then
            respinView:setAnimaState(0)
        end
        respinView:setCreateAndPushSymbolFun(
            function(symbolType,iRow,iCol,isLastSymbol)
                local symbolNode = self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
                symbolNode:setScale(0.7)
                return symbolNode
            end,
            function(targSp)
                self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
            end
        )
        respinWheelNode:findChild("reel"):addChild(respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

        table.insert(self.m_respinViewTab,respinView)
        if i == 1 then
            self.m_respinView = respinView
        end
    end
    --修改数据
    self:changeReelsDataToRespin()
    self:initRespinView(endTypes, randomTypes)
end
function CodeGameScreenMagicLadyMachine:initRespinView(endTypes, randomTypes)
    for i,respinView in ipairs(self.m_respinViewTab) do
        local respinNodeInfo = self:reateRespinNodeInfo(i)
        respinView:setEndSymbolType(endTypes[i], randomTypes)
        respinView:initRespinSize(self.m_SlotNodeW * 0.7, self.m_SlotNodeH * 0.7, self.m_fReelWidth * 0.7, self.m_fReelHeigth * 0.7)

        respinView:initRespinElement(
            respinNodeInfo,
            self.m_iReelRowNum,
            self.m_iReelColumnNum,
            function()
                self:respinInitDark(i)
            end
        )
    end
end
--隐藏lighting图标
function CodeGameScreenMagicLadyMachine:respinInitDark(wheelIndex)
    if self:isRespinInit() and wheelIndex > 1 then
        local respinList = self.m_respinViewTab[wheelIndex]:getAllCleaningNode()
        for i=1,#respinList do
            respinList[i]:setVisible(false)
        end
    else
        performWithDelay(self,function ()
            local respinList = self.m_respinViewTab[wheelIndex]:getAllCleaningNode()
            for i=1,#respinList do
                respinList[i]:runAnim("idleframe",true)
            end
        end,0.1)
    end
end
--下面轮盘上的lighting图标开始往上飞
function CodeGameScreenMagicLadyMachine:startFlyLightingToTop()
    self.m_flyIndex = 1
    self.m_lightingNodeTabList = {}
    for i,respinView in ipairs(self.m_respinViewTab) do
        local lightingNodeTab = respinView:getAllCleaningNode()
        table.insert(self.m_lightingNodeTabList,lightingNodeTab)
    end
    self:flyLightingToTop()
end
--下面轮盘上的lighting图标往上飞
function CodeGameScreenMagicLadyMachine:flyLightingToTop(func)
    if self.m_flyIndex > #self.m_lightingNodeTabList[1] then
        --所有图标飞行结束
        self.m_flySymbolNode:removeFromParent()
        self.m_flySymbolNode = nil
        self:lightingFlyEnd()
        return
    end
    self.m_currFlyPosTab = {}
    self.m_flyPosIndex = 1
    for i,lightingNodeTab in ipairs(self.m_lightingNodeTabList) do
        local symbolNode = lightingNodeTab[self.m_flyIndex]
        local pos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
        table.insert(self.m_currFlyPosTab,pos)
    end

    if self.m_flySymbolNode == nil then
        self.m_flySymbolNode = util_createAnimation("Socre_MagicLady_linghting_hong.csb")
        self.m_flySymbolNode:findChild("m_lb_score"):setVisible(false)
        self.m_flySymbolNode:setScale(0.7 * self.m_machineRootScale)
        self:addChild(self.m_flySymbolNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
        self.m_flySymbolNode:setVisible(false)
    end
    self:lightingFly()
end
--一个图标开始飞
function CodeGameScreenMagicLadyMachine:lightingFly()
    if self.m_flyPosIndex >= #self.m_currFlyPosTab then
        --一个图标飞行结束
        self.m_flyIndex = self.m_flyIndex + 1
        self.m_flySymbolNode:setVisible(false)
        self:flyLightingToTop()
        return
    end

    local startPos = self.m_currFlyPosTab[self.m_flyPosIndex]
    local endPos = self.m_currFlyPosTab[self.m_flyPosIndex + 1]
    local nodeEndSymbol = self.m_lightingNodeTabList[self.m_flyPosIndex + 1][self.m_flyIndex]

    self:runFlySymbolAction(nodeEndSymbol,startPos,endPos,function()
        self.m_flyPosIndex = self.m_flyPosIndex + 1
        self:lightingFly()
    end)

end
--飞行图标飞行
function CodeGameScreenMagicLadyMachine:runFlySymbolAction(endNode,startPos,endPos,callback)
    local actionList = {}
    self.m_flySymbolNode:setPosition(startPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        self.m_flySymbolNode:setVisible(true)
        if self.m_flyPosIndex == 1 then
            self.m_flySymbolNode:playAction("actionframe4",false)
        else
            self.m_flySymbolNode:playAction("actionframe5",false)
        end
    end)
    if self.m_flyPosIndex == 1 then
        local qifei = cc.DelayTime:create(4/30)
        local moveTo = cc.MoveTo:create(5/30,endPos)
        actionList[#actionList + 1] = qifei
        actionList[#actionList + 1] = moveTo
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            endNode:setVisible(true)
            gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_lighttingShow"..(self.m_flyPosIndex + 1)..".mp3")
            --添加爆炸动画
            local baozha = util_createAnimation("Socre_MagicLady_linghting_BZ.csb")
            baozha:setScale(0.7 * self.m_machineRootScale)
            baozha:playAction("actionframe"..self.m_flyPosIndex,false,function ()
                baozha:removeFromParent()
            end)
            baozha:setPosition(endPos)
            self:addChild(baozha,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
            endNode:runAnim("buling2",false,function()
                endNode:runAnim("idleframe",true)
            end)
        end)
        local jiangluo = cc.DelayTime:create(2/30)
        actionList[#actionList + 1] = jiangluo
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            if callback then
                callback()
            end
        end)
    else
        local qifei = cc.DelayTime:create(4/30)
        local moveTo = cc.MoveTo:create(6/30,endPos)
        actionList[#actionList + 1] = qifei
        actionList[#actionList + 1] = moveTo
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            endNode:setVisible(true)
            gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_lighttingShow"..(self.m_flyPosIndex + 1)..".mp3")
            --添加爆炸动画
            local baozha = util_createAnimation("Socre_MagicLady_linghting_BZ.csb")
            baozha:setScale(0.7 * self.m_machineRootScale)
            baozha:playAction("actionframe"..self.m_flyPosIndex,false,function ()
                baozha:removeFromParent()
            end)
            baozha:setPosition(endPos)
            self:addChild(baozha,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
            endNode:runAnim("buling2",false,function()
                endNode:runAnim("idleframe",true)
            end)
        end)
        local jiangluo = cc.DelayTime:create(4/30)
        actionList[#actionList + 1] = jiangluo
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            if callback then
                callback()
            end
        end)
    end
    self.m_flySymbolNode:runAction(cc.Sequence:create(actionList))
end
--图标飞完
function CodeGameScreenMagicLadyMachine:lightingFlyEnd()
    performWithDelay(self,function()
        --显示respin开始界面
        local view = util_createView("Levels.BaseDialog")
        view:initViewData(self,BaseDialog.DIALOG_TYPE_RESPIN_START,function ()
            for i,respinView in ipairs(self.m_respinViewTab) do
                respinView:setAnimaState(1)
            end
            self:runNextReSpinReel()
            self:resetMusicBg()
        end,nil,nil)
        view:updateOwnerVar({m_lb_num = self.m_runSpinResultData.p_reSpinCurCount})
        if globalData.slotRunData.machineData.p_portraitFlag then
            view.getRotateBackScaleFlag = function() return false end
        end
        gLobalViewManager:showUI(view)

        performWithDelay(self,function ()
            view:findChild("Particle_1"):setPositionType(0)
            view:findChild("Particle_1"):resetSystem()
        end,35/30)

        gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_respinStartLayer.mp3")
    end,2.0)
end
----构造respin上轮盘所需要的数据,wheelIndex 轮盘编号，从下到上为1到3
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenMagicLadyMachine:reateRespinNodeInfo(wheelIndex)
    local respinNodeInfo = {}
    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol,wheelIndex)
            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getRespinReelPos(iCol,wheelIndex)
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = reelHeight/3
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
--获取respin盘面图标id,wheelIndex 轮盘编号，从下到上为1到3
function CodeGameScreenMagicLadyMachine:getMatrixPosSymbolType(iRow, iCol,wheelIndex)
    local reelsData = nil
    if wheelIndex == 1 then
        reelsData = self.m_runSpinResultData.p_reels
    elseif wheelIndex == 2 then
        reelsData = self.m_runSpinResultData.p_rsExtraData.middleLastReels
    elseif wheelIndex == 3 then
        reelsData = self.m_runSpinResultData.p_rsExtraData.upLastReels
    end
    if reelsData then
        local rowCount = #reelsData
        for rowIndex = 1, rowCount do
            local rowDatas = reelsData[rowIndex]
            local colCount = #rowDatas
            for colIndex = 1, colCount do
                if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                    return rowDatas[colIndex]
                end
            end
        end
    end
    return nil
end
--获取respin轮盘滚轴的位置大小参数,wheelIndex 轮盘编号，从下到上为1到3
function CodeGameScreenMagicLadyMachine:getRespinReelPos(iCol,wheelIndex)
    local reelNode = self.m_respinWheelNodeTab[wheelIndex]:findChild("sp_reel_" .. (iCol - 1))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width
    return worldPos, reelHeight, reelWidth
end

--切换到respin盘面
function CodeGameScreenMagicLadyMachine:changeToRespinLayer()
    self:clearWinLineEffect()
    self:recoverySymbolParent()
    self.m_magicLadyNode:setVisible(false)
    self:findChild("reel"):setVisible(false)
    
    self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    self:updateKpNum(false)
    self:addRespinLightingFrame()
    self.m_winBar:findChild("m_lb_win"):setString(0)
    self.m_winBar:findChild("m_lb_win"):setVisible(false)
    -- self.m_winBar:findChild("MagicLady_jackpot_zi6_1"):setVisible(true)
    self.m_winBar:setVisible(false)
    self.m_respinBar:setVisible(true)
    self.m_winBar:playAction("idleframe")
    self:findChild("respinReel"):setVisible(true)
    self:updateRespinWheelFullLayer(true)
end
--ReSpin刷新数量
function CodeGameScreenMagicLadyMachine:changeReSpinUpdateUI(curCount)
    -- print("当前展示位置信息  %d ", curCount)
    self.m_respinBar:findChild("m_lb_win"):setString(""..curCount)
end
--更新卡片上的数字
function CodeGameScreenMagicLadyMachine:updateKpNum(isPlayAni)
    if isPlayAni == nil then
        isPlayAni = true
    end
    for i,respinKpNode in ipairs(self.m_respinKpNodeTab) do
        local num = 0
        if i == 1 then
            num = #self.m_runSpinResultData.p_storedIcons
        elseif i == 2 then
            num = #self.m_runSpinResultData.p_rsExtraData.middleStoreIcons
        elseif i == 3 then
            num = #self.m_runSpinResultData.p_rsExtraData.upStoredIcons
        end
        local localNum = tonumber(respinKpNode:findChild("BitmapFontLabel_1"):getString()) 
        respinKpNode:findChild("BitmapFontLabel_1"):setString(""..num)
        if isPlayAni and localNum ~= num then
            respinKpNode:playAction("actionframe")
            gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_addrespinnum.mp3")
        end
    end
end

--ReSpin结算改变UI状态
function CodeGameScreenMagicLadyMachine:changeReSpinOverUI(callback)
    -- 更新游戏内每日任务进度条 --
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:triggerRespinComplete()
    self:resetReSpinMode()

    -- self.m_magicLadyNode:setVisible(true)
    self.m_magicLadyQiuNode:setVisible(true)
    -- self.m_magicLadyHandNode:setVisible(true)

    gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_changeToNormalEffect.mp3")
    --轮盘动画
    self:runCsbAction("over2")
    --背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"over2")
    --魔女动画
    self:findChild("spine_SHOUZHI"):setLocalZOrder(3)
    util_spinePlay(self.m_magicLadyNode,"actionframe3",false)
    util_spinePlay(self.m_magicLadyQiuNode,"actionframe3",false)
    util_spinePlay(self.m_magicLadyHandNode,"actionframe3",false)
    util_spineEndCallFunc(self.m_magicLadyQiuNode,"actionframe3",function ()
        util_spinePlay(self.m_magicLadyNode,"idleframe",true)
        util_spinePlay(self.m_magicLadyQiuNode,"idleframe",true)
        util_spinePlay(self.m_magicLadyHandNode,"idleframe",true)
    end)
    performWithDelay(self,function()
        self:findChild("reel"):setVisible(true)
        self:findChild("respinReel"):setVisible(false)
        self.m_magicLadyNode:setVisible(true)
        self.m_magicLadyHandNode:setVisible(true)
        self:removeRespinDataAndNode()
    end,10/30)
    performWithDelay(self,function()
        if callback then
            callback()
        end
    end,2)
end
--清除respin的东西
function CodeGameScreenMagicLadyMachine:removeRespinDataAndNode()
    for i,respinView in ipairs(self.m_respinViewTab) do
        local allEndNode = respinView:getAllEndSlotsNode()
        for j = 1, #allEndNode do
            local node = allEndNode[j]
            node:removeFromParent()
        end
        respinView:removeFromParent()

        if self.m_respinFrameNode[i] ~= nil then
            for k,frame in pairs(self.m_respinFrameNode[i]) do
                frame:removeFromParent()
            end
        end
    end
    self.m_respinViewTab = {}
    self.m_respinFrameNode = {}

    for i,respinPrizeNode in ipairs(self.m_respinPrizeNodeTab) do
        respinPrizeNode:setVisible(false)
    end

    if self.m_collectParticle then
        self.m_collectParticle:removeFromParent()
        self.m_collectParticle = nil
    end

end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenMagicLadyMachine:operaEffectOver()
    CodeGameScreenMagicLadyMachine.super.operaEffectOver(self)

    if self.m_isRespinOver then
        self.m_isRespinOver = false
        --公共jackpot
        local midReel = self:findChild("sp_reel_2")
        local size = midReel:getContentSize()
        local worldPos = util_convertToNodeSpace(midReel,self)
        worldPos.x = worldPos.x + size.width / 2
        worldPos.y = worldPos.y + size.height / 2
        if G_GetMgr(ACTIVITY_REF.CommonJackpot) then
            G_GetMgr(ACTIVITY_REF.CommonJackpot):playEntryFlyAction(worldPos,function()

            end)
        end
    end
    
end

function CodeGameScreenMagicLadyMachine:showRespinOverView(effectData)
    local strCoins = util_formatCoins(self.m_serverWinCoins,11)
    gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_respinOverLayer.mp3")
    local view = self:showReSpinOver(strCoins,function()
        performWithDelay(self,function()
            self.m_isRespinOver = true
            
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg()
        end,1.0)
    end)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)
end
function CodeGameScreenMagicLadyMachine:triggerReSpinOverCallFun(score)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    performWithDelay(self,function()
        if self.m_bProduceSlots_InFreeSpin then
            local addCoin = self.m_serverWinCoins
            -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self:getLastWinCoin(),false,false})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,false})
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        end

    end,2)

    self:changeReSpinOverUI(function()

        local coins = nil
        if self.m_bProduceSlots_InFreeSpin then
            coins = self:getLastWinCoin() or 0
        else
            coins = self.m_serverWinCoins or 0
        end
        if self.postReSpinOverTriggerBigWIn then
            self:postReSpinOverTriggerBigWIn( coins)
        end

        -- self:resetMusicBg(true)
        self:playGameEffect()
        self.m_iReSpinScore = 0

        if
            self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or
                self.m_bProduceSlots_InFreeSpin
         then
            --不做处理
        else
            --停掉屏幕长亮
            globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
        end
    end)

end
function CodeGameScreenMagicLadyMachine:isRespinInit()
    return self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount
end

--respin下spin回调
function CodeGameScreenMagicLadyMachine:MachineRule_respinTouchSpinBntCallBack()
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
        if self.m_beginStartRunHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
            self.m_beginStartRunHandlerID = nil
        end
        for i,respinView in ipairs(self.m_respinViewTab) do
            respinView:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)
        end
        self:startReSpinRun()
    elseif self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        --快停
        self:quicklyStop()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

--- respin 快停
function CodeGameScreenMagicLadyMachine:quicklyStop()
    BaseFastMachine.quicklyStop(self)
    for i = 2,#self.m_respinViewTab do
        self.m_respinViewTab[i]:quicklyStop()
    end
end

--respin轮盘开始滚动
function CodeGameScreenMagicLadyMachine:startReSpinRun()
    for i = 1,self.m_iReelColumnNum do
        self.m_respinOneReelDownNumTab[i] = 0
    end
    
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
    else
        for i = 2,#self.m_respinViewTab do
            self.m_respinViewTab[i]:startMove()
        end
    end
    
    CodeGameScreenMagicLadyMachine.super.startReSpinRun(self)
    
end
--接收到数据开始停止滚动
function CodeGameScreenMagicLadyMachine:stopRespinRun()
    self:changeReelsDataToRespin()
    for i,respinView in ipairs(self.m_respinViewTab) do
        local storedNodeInfo = self:getRespinSpinData(i)
        local unStoredReels = self:getRespinReelsButStored(storedNodeInfo,i)
        respinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    end
end
--将盘面图标数据改为respin数据 将普通lighting改为红、蓝、绿lighting
function CodeGameScreenMagicLadyMachine:changeReelsDataToRespin()
    for wheelIndex,v in ipairs(self.m_respinViewTab) do
        local reelsData = nil
        if wheelIndex == 1 then
            reelsData = self.m_runSpinResultData.p_reels
        elseif wheelIndex == 2 then
            reelsData = self.m_runSpinResultData.p_rsExtraData.middleLastReels
        elseif wheelIndex == 3 then
            reelsData = self.m_runSpinResultData.p_rsExtraData.upLastReels
        end

        if reelsData then
            local rowCount = #reelsData
            for i,rowDatas in ipairs(reelsData) do
                for j,symbolId in ipairs(rowDatas) do
                    if symbolId >= 94 then
                        reelsData[i][j] = symbolId + 10000 * wheelIndex
                    end
                end
            end
        end
    end
end

function CodeGameScreenMagicLadyMachine:getRespinSpinData(wheelIndex)
    local storedIcons = nil
    if wheelIndex == 1 then
        storedIcons = self.m_runSpinResultData.p_storedIcons
    elseif wheelIndex == 2 then
        storedIcons = self.m_runSpinResultData.p_rsExtraData.middleStoreIcons
    elseif wheelIndex == 3 then
        storedIcons = self.m_runSpinResultData.p_rsExtraData.upStoredIcons
    end

    local index = 0
    local storedInfo = {}
    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            for i = 1, #storedIcons do
                if storedIcons[i] == index then
                    local type = self:getMatrixPosSymbolType(iRow, iCol,wheelIndex)
                    local pos = {iX = iRow, iY = iCol, type = type}
                    storedInfo[#storedInfo + 1] = pos
                end
            end
            index = index + 1
        end
    end
    return storedInfo
end
function CodeGameScreenMagicLadyMachine:getRespinReelsButStored(storedInfo,wheelIndex)
    local reelData = {}
    local function getIsInStore(iRow, iCol)
        for i = 1, #storedInfo do
            local storeIcon = storedInfo[i]
            if storeIcon.iX == iRow and  storeIcon.iY == iCol then
                return true
            end
        end
        return false
    end

    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
           local type = self:getMatrixPosSymbolType(iRow, iCol,wheelIndex)
           if getIsInStore(iRow, iCol) == false then
                local pos = {iX = iRow, iY = iCol, type = type}
                reelData[#reelData + 1] = pos
           end
        end
    end
    return reelData
end
--respin一个轮盘的一列停止  col列数， wheelIndex轮盘编号(没有可滚的滚轴的列的话调不到这里)
function CodeGameScreenMagicLadyMachine:reSpinOneWheelOneReelDown(col,wheelIndex)
    self.m_respinOneReelDownNumTab[col] = self.m_respinOneReelDownNumTab[col] + 1
    self:updateRespinLightingFrame(col,wheelIndex)

    local lockedRespinViewNum = 0
    for i,respinView in ipairs(self.m_respinViewTab) do
        if respinView:isHaveNoLockRespinNode(col) == false then
            lockedRespinViewNum = lockedRespinViewNum + 1
        end
    end
    if self.m_respinOneReelDownNumTab[col] + lockedRespinViewNum >= #self.m_respinViewTab then
        self:reSpinOneReelDown(col)
    end
end
--respin所有轮盘的一列停止
function CodeGameScreenMagicLadyMachine:reSpinOneReelDown(col)
    local isHaveNewLighting = false
    for i,respinView in ipairs(self.m_respinViewTab ) do
        if respinView.m_isHaveNewLightingTab[col] == true then
            isHaveNewLighting = true
            break
        end
    end
    -- 这一列有新的lighting图标出现
    if isHaveNewLighting then
        gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_lightingBuling.mp3")
    else
        --这一列没出lighting图标出现
        gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_reelstop.mp3")
    end
end
--respin轮盘滚动全部停止调用
function CodeGameScreenMagicLadyMachine:reSpinReelDown(addNode)
    for i,respinView in ipairs(self.m_respinViewTab) do
        if respinView:wheelIsAllStop() == false then
            return
        end
    end

    local inner = function()
        self:updateQuestUI()
        -- self:resetMusicBg()
        -- self:changeRespinBg()
        self:updateKpNum()
        self:addRespinLightingFrame()
        self:updateRespinWheelFullLayer()
    end

    performWithDelay(self,function()
        inner()
    end,1)
end

--添加respin lighting图标数量够了的 图标框
function CodeGameScreenMagicLadyMachine:addRespinLightingFrame()
    for wheelIndex,respinView in ipairs(self.m_respinViewTab) do
        local iColNum = respinView.m_machineColmn
        local iRowNum = respinView.m_machineRow
        local num = 0
        if wheelIndex == 1 then
            num = #self.m_runSpinResultData.p_storedIcons
        elseif wheelIndex == 2 then
            num = #self.m_runSpinResultData.p_rsExtraData.middleStoreIcons
        elseif wheelIndex == 3 then
            num = #self.m_runSpinResultData.p_rsExtraData.upStoredIcons
        end
        if num >= 12 and num < iColNum * iRowNum and self.m_respinFrameNode[wheelIndex] == nil then
            self.m_respinFrameNode[wheelIndex] = {}
            for col = 1,iColNum do
                for row = 1,iRowNum do
                    if respinView:getRespinNode(row,col):getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                        local worldPos = respinView:getWorldPosByColRow(col,row)
                        local nodePos = self:convertToNodeSpace(worldPos)
                        local frame = util_createAnimation("WinFrameMagicLady_RespinRun.csb")
                        self:addChild(frame,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
                        frame:setPosition(nodePos)
                        frame:setScale(self.m_machineRootScale)
                        self.m_respinFrameNode[wheelIndex][""..col..row] = frame
                    end
                end
            end
        end
        if self.m_respinFrameNode[wheelIndex] then
            for k,frame in pairs(self.m_respinFrameNode[wheelIndex]) do
                local actionName = ""
                if num >= iColNum * iRowNum -1 then
                    actionName = "run"
                else
                    actionName = "run2"
                end
                if frame.actionName ~= actionName then
                    frame.actionName = actionName
                    frame:playAction(frame.actionName,true)
                end
            end
        end
    end
end
--一列停止时删除  图标框
function CodeGameScreenMagicLadyMachine:updateRespinLightingFrame(col,wheelIndex)
    local iRowNum = self.m_respinViewTab[wheelIndex].m_machineRow
    for row = 1,iRowNum do
        if self.m_respinFrameNode[wheelIndex] and self.m_respinFrameNode[wheelIndex][""..col..row] then
            local wheelReelData = nil
            if wheelIndex == 1 then
                wheelReelData = self.m_runSpinResultData.p_reels
            elseif wheelIndex == 2 then
                wheelReelData = self.m_runSpinResultData.p_rsExtraData.middleLastReels
            elseif wheelIndex == 3 then
                wheelReelData = self.m_runSpinResultData.p_rsExtraData.upLastReels
            end
            local symbolType = wheelReelData[iRowNum - row + 1][col]
            if self:isFixSymbol(symbolType) then
                self.m_respinFrameNode[wheelIndex][""..col..row]:removeFromParent()
                self.m_respinFrameNode[wheelIndex][""..col..row] = nil
            end
        end
    end
end

--respin全部停止后根据lighting数量切换背景音乐
function CodeGameScreenMagicLadyMachine:changeRespinBg()
    -- for i,respinView in ipairs(self.m_respinViewTab) do
    --     local num = 0
    --     if i == 1 then
    --         num = #self.m_runSpinResultData.p_storedIcons
    --     elseif i == 2 then
    --         num = #self.m_runSpinResultData.p_rsExtraData.middleStoreIcons
    --     elseif i == 3 then
    --         num = #self.m_runSpinResultData.p_rsExtraData.upStoredIcons
    --     end
    --     if num >= 12 then
            if self.m_currentMusicBgName ~= "MagicLadySounds/music_MagicLady_RespinBG2.mp3" and self.m_soundGlobalId == nil then
                --该播背景音乐2了
                -- self:BGMVolumeGradients(0,1,function ()
                    self:resetMusicBg()
                -- end)
            end
    --         break
    --     end
    -- end
end
function CodeGameScreenMagicLadyMachine:clearCurMusicBg()
    self:removeSoundHandler()
    if self.m_currentMusicId == nil then
        self.m_currentMusicId = gLobalSoundManager:getBGMusicId()
    end
    if self.m_currentMusicId ~= nil then
        gLobalSoundManager:stopAudio(self.m_currentMusicId)
        self.m_currentMusicId = nil
    end
end
--渐变背景音乐音量
function CodeGameScreenMagicLadyMachine:BGMVolumeGradients(toVolume,time,func)
    self:removeSoundHandler()
    local volume = gLobalSoundManager:getBackgroundMusicVolume()
    local perGradientsNum = (toVolume - volume)/time * 0.1
    self.m_soundGlobalId = scheduler.scheduleGlobal(function()
            --播放广告过程中暂停逻辑
            if gLobalAdsControl ~= nil and gLobalAdsControl.getPlayAdFlag ~= nil and gLobalAdsControl:getPlayAdFlag() then
                return
            end

            if perGradientsNum <= 0 and volume <= toVolume then
                volume = toVolume
            end
            if perGradientsNum >= 0 and volume >= toVolume then
                volume = toVolume
            end

            gLobalSoundManager:setBackgroundMusicVolume(volume)

            if (perGradientsNum <= 0 and volume <= toVolume) or (perGradientsNum >= 0 and volume >= toVolume) then
                if self.m_soundGlobalId ~= nil then
                    scheduler.unscheduleGlobal(self.m_soundGlobalId)
                    self.m_soundGlobalId = nil
                    if func then
                        func()
                    end
                end
            end

            volume = volume + perGradientsNum
        end,
        0.1
    )
end

--respin轮盘滚动全部停止后满轮盘效果结束后的下一步
function CodeGameScreenMagicLadyMachine:reSpinReelDownUpdateRespinWheelFullLayerNext()


    self:setGameSpinStage(STOP_RUN)

    if self.m_runSpinResultData.p_rsExtraData.select and self.m_runSpinResultData.p_rsExtraData.options then
        if self.m_runSpinResultData.p_rsExtraData.options[self.m_runSpinResultData.p_rsExtraData.select + 1] > 0 then
            gLobalSoundManager:setBackgroundMusicVolume(0.0)
            if self.m_currentMusicBgName == "MagicLadySounds/music_MagicLady_RespinBG2.mp3" then
                gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_chooseLayerReady2.mp3")
            else
                gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_chooseLayerReady.mp3")
            end

            performWithDelay(self,function()
                self:addRespinChoseLayer()
            end,4)
            return
        end
    end

    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        --quest
        self:updateQuestBonusRespinEffectData()

        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        --respin结束
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        for i,respinView in ipairs(self.m_respinViewTab) do
            respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

            if self.m_respinFrameNode[i] ~= nil then
                for k,frame in pairs(self.m_respinFrameNode[i]) do
                    frame:removeFromParent()
                end
            end
        end
        self.m_respinFrameNode = {}

        performWithDelay(self,function()
            --结束
            self:reSpinEndAction()
        end,1)

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false

        return
    end
    self:respinToNext()
end

--respin进行下一轮
function CodeGameScreenMagicLadyMachine:respinToNext()
    self.m_isReconnection = false
    gLobalSoundManager:setBackgroundMusicVolume(1)
    for i,respinView in ipairs(self.m_respinViewTab) do
        respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    end
    self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    --继续滚下一轮
    self:runNextReSpinReel()
end
--弹出respin下选择增加respin次数的弹板
function CodeGameScreenMagicLadyMachine:addRespinChoseLayer()
    local view = util_createView("CodeMagicLadySrc.MagicLadyRespinChoseLayer",self.m_runSpinResultData.p_rsExtraData,function()
        self:respinToNext()
    end,self)
    view:findChild("root"):setScale(self.m_machineRootScale)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function() return false end
    end
    gLobalViewManager:showUI(view)
end
--增加respin次数飞特效 clickWorldPos选择的卡片的世界坐标
function CodeGameScreenMagicLadyMachine:addRespinNumFlyEffect(clickWorldPos)
    local nodePos = self.m_respinBar:findChild("m_lb_win"):getParent():convertToWorldSpace(cc.p(self.m_respinBar:findChild("m_lb_win"):getPosition()))
    gLobalNoticManager:postNotification("MagicLadyRespinChoseLayer_startFly",{clickWorldPos,nodePos})
end

--更新respin轮盘满图标弹框 isInit是否是初始化调用
function CodeGameScreenMagicLadyMachine:updateRespinWheelFullLayer(isInit)
    if isInit == nil then
        isInit = false
    end
    local isshow = false
    local fullDataTab = nil
    if self.m_runSpinResultData.p_rsExtraData then
        fullDataTab = self.m_runSpinResultData.p_rsExtraData.full
    end
    if fullDataTab then
        for i,fullData in ipairs(fullDataTab) do
            local index = 0
            if fullData.position == "up" then
                index = 3
            elseif fullData.position == "middle" then
                index = 2
            elseif fullData.position == "bottom" then
                index = 1
            end
            if index > 0 and self.m_respinPrizeNodeTab[index] then
                if self.m_respinPrizeNodeTab[index]:isVisible() == false then
                    gLobalSoundManager:setBackgroundMusicVolume(0)
                    local allSymbolNode = self.m_respinViewTab[index]:getAllCleaningNode()
                    for i,symbolNode in ipairs(allSymbolNode) do
                        symbolNode:runAnim("actionframe3")
                    end
                    performWithDelay(self,function()
                        self.m_respinPrizeNodeTab[index]:setVisible(true)
                        self.m_respinPrizeNodeTab[index]:playAction("start",false,function ()
                            self.m_respinPrizeNodeTab[index]:playAction("idle",true)
                        end)

                        if isInit then
                            self.m_respinPrizeNodeTab[index]:findChild("BitmapFontLabel_1"):setString(util_formatCoins(fullData.coins,20,nil,nil,true))
                            local info = {label = self.m_respinPrizeNodeTab[index]:findChild("BitmapFontLabel_1"),sx = 0.55,sy = 0.55}
                            self:updateLabelSize(info,621)
                        else
                            self.m_respinPrizeNodeTab[index].fullDataCoins = fullData.coins
                            self.m_respinPrizeNodeTab[index].isCoinJumping = true
                            local add_meta = (fullData.coins - 0) / 50
                            util_jumpNumInSize(self.m_respinPrizeNodeTab[index]:findChild("BitmapFontLabel_1"),0,fullData.coins,add_meta,0.05,621,0.55,function ()
                                self.m_respinPrizeNodeTab[index].isCoinJumping = false
                                self:prizeLayerNumJumpEnd()
                            end)
                            if self.m_JumpSound == nil then
                                self.m_JumpSound = gLobalSoundManager:playSound("MagicLadySounds/sound_MagicLady_jackpot_jump.mp3",true)
                            end
                        end
                    end,1.5)
                    isshow = true
                end
            end
        end
    end
    if isshow then
        gLobalSoundManager:setBackgroundMusicVolume(0)
        gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_prizeLayershow.mp3")
    else
        if isInit == false then
            --没有新弹板弹出，进入下一步
            self:reSpinReelDownUpdateRespinWheelFullLayerNext()
        end
    end
end
--respin下点击
function CodeGameScreenMagicLadyMachine:clickFunc(sender)
    local respinIsAllowClicked = false
    for i,respinPrizeNode in ipairs(self.m_respinPrizeNodeTab) do
        if respinPrizeNode.isCoinJumping == true then
            respinPrizeNode:findChild("BitmapFontLabel_1"):unscheduleUpdate()
            respinPrizeNode:findChild("BitmapFontLabel_1"):setString(util_formatCoins(respinPrizeNode.fullDataCoins,20,nil,nil,true))
            local info = {label = respinPrizeNode:findChild("BitmapFontLabel_1"),sx = 0.55,sy = 0.55}
            self:updateLabelSize(info,621)
            respinPrizeNode.isCoinJumping = false
            respinIsAllowClicked = true
        end
    end

    if respinIsAllowClicked == true then
        self:prizeLayerNumJumpEnd()
    end
end
--respin下奖励界面数字滚动完毕
function CodeGameScreenMagicLadyMachine:prizeLayerNumJumpEnd()
    local isAllStopJumpCoin = true
    if self.m_JumpSound then
        gLobalSoundManager:stopAudio(self.m_JumpSound)
        self.m_JumpSound = nil
    end
    gLobalSoundManager:playSound("MagicLadySounds/sound_MagicLady_jackpot_over.mp3")
    for i,respinPrizeNode in ipairs(self.m_respinPrizeNodeTab) do
        if respinPrizeNode.isCoinJumping == true then
            isAllStopJumpCoin = false
            break
        end
    end
    if isAllStopJumpCoin == true then
        --所有弹板数字滚动结束，进行下一步
        performWithDelay(self,function ()
            gLobalSoundManager:setBackgroundMusicVolume(1)
            self:reSpinReelDownUpdateRespinWheelFullLayerNext()
        end,1)
    end
end

function CodeGameScreenMagicLadyMachine:createFinalResult(slotParent, slotParentBig, parentPosY, columnData, parentData)

    local childs = slotParent:getChildren()
    if slotParentBig then
        local newChilds = slotParentBig:getChildren()
        for i=1,#newChilds do
            childs[#childs+1]=newChilds[i]
        end
    end

    for childIndex = 1, #childs do

        local child = childs[childIndex]
        self:moveDownCallFun(child, parentData.cloumnIndex)
    end

    local index = 1

    while index <= columnData.p_showGridCount do -- 只改了这 为了适应freespin
        self:createSlotNextNode(parentData)
        local symbolType = parentData.symbolType
        local node = self:getCacheNode(parentData.cloumnIndex, symbolType)
        if node == nil then
            node = self:getSlotNodeWithPosAndType(symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
            local slotParentBig = parentData.slotParentBig
            -- 添加到显示列表
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node, parentData.order, parentData.tag)
            else
                slotParent:addChild(node, parentData.order, parentData.tag)
            end
        else
            local tmpSymbolType = self:convertSymbolType(symbolType)
            node:setVisible(true)
            node:setLocalZOrder(parentData.order)
            node:setTag(parentData.tag)
            local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
            node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
            self:setSlotCacheNodeWithPosAndType(node, symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
        end
        
        local posY = columnData.p_showGridH * (parentData.rowIndex - 0.5) - parentPosY

        node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

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

        node:runIdleAnim()
        -- node:setVisible(false)
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


end

function CodeGameScreenMagicLadyMachine:changeTouchSpinLayerSize(_trigger)
    if self.m_SlotNodeH and self.m_iReelRowNum and self.m_touchSpinLayer then
        local size = self.m_touchSpinLayer:getContentSize()
        if _trigger then
            self.m_touchSpinLayerRs:setVisible(true)
            self.m_touchSpinLayer:setVisible(false)
        else
            self.m_touchSpinLayerRs:setVisible(false)
            self.m_touchSpinLayer:setVisible(true)
        end
        
        self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH *self.m_iReelRowNum))
    end
end

--绘制多个裁切区域
function CodeGameScreenMagicLadyMachine:drawReelArea()

    CodeGameScreenMagicLadyMachine.super.drawReelArea(self)

    if self.m_clipParent  and self.m_touchSpinLayer then
       
        local size = self.m_touchSpinLayer:getContentSize()
        self.m_touchSpinLayerRs = ccui.Layout:create()
        self.m_touchSpinLayerRs:setContentSize(cc.size(size.width, size.height/3 * 7))
        self.m_touchSpinLayerRs:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayerRs:setTouchEnabled(true)
        self.m_touchSpinLayerRs:setSwallowTouches(false)
        
        self:findChild("respinReel"):addChild(self.m_touchSpinLayerRs, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayerRs:setPosition(util_getConvertNodePos(self.m_csbOwner["sp_reel_0"],self.m_touchSpinLayerRs))
        self.m_touchSpinLayerRs:setName("touchSpin")

        self.m_touchSpinLayerRs:setVisible(false)
    end


end

---
-- 处理spin 返回结果
function CodeGameScreenMagicLadyMachine:spinResultCallFun(param)
    CodeGameScreenMagicLadyMachine.super.spinResultCallFun(self,param)
    self.m_jackpotBar:resetCurRefreshTime()
    self.m_respinJackpotBar:resetCurRefreshTime()
end

function CodeGameScreenMagicLadyMachine:updateReelGridNode(symbolNode)
    if symbolNode.p_symbolType == self.SYMBOL_FIX_GRAND or symbolNode.p_symbolType == self.SYMBOL_FIX_GREEN_GRAND or
    symbolNode.p_symbolType == self.SYMBOL_FIX_BLUE_GRAND or symbolNode.p_symbolType == self.SYMBOL_FIX_RED_GRAND then
        symbolNode:getCcbProperty("node_grand"):setVisible(self.m_jackpot_status == "Normal")
        symbolNode:getCcbProperty("node_mega"):setVisible(self.m_jackpot_status == "Mega")
        symbolNode:getCcbProperty("node_super"):setVisible(self.m_jackpot_status == "Super")
    end
end

-------------------------------------------------公共jackpot-----------------------------------------------------------------------

--[[
    更新公共jackpot状态
]]
function CodeGameScreenMagicLadyMachine:updataJackpotStatus(params)
    local totalBetID = globalData.slotRunData:getCurTotalBet()

    self.m_jackpot_status = "Normal" -- "Mega" "Super"
    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        self:updateJackpotBarMegaShow()
        return
    end

    if self.m_isJackpotEnd then
        self:updateJackpotBarMegaShow()
        return
    end

    if not mgr:isDownloadRes() then
        self:updateJackpotBarMegaShow()
        return
    end
    
    local data = mgr:getRunningData()
    if not data or not next(data) then
        self:updateJackpotBarMegaShow()
        return
    end

    local levelData = data:getLevelDataByBet(totalBetID)
    local levelName = levelData.p_name
    self.m_jackpot_status = levelName
    self:updateJackpotBarMegaShow()
end

function CodeGameScreenMagicLadyMachine:updateJackpotBarMegaShow()
    self.m_jackpotBar:updateMegaShow()
    self.m_respinJackpotBar:updateMegaShow()
end

function CodeGameScreenMagicLadyMachine:getCommonJackpotValue(_status, _addTimes)
    _addTimes = math.floor(_addTimes)
    local value     = 0
    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if _status == "Mega" then
        if mgr then
            value = mgr:getJackpotValue(CommonJackpotCfg.LEVEL_NAME.Mega)
        end
    elseif _status == "Super" then
        if mgr then
            value = mgr:getJackpotValue(CommonJackpotCfg.LEVEL_NAME.Super)
        end
    end

    return value
end

--[[
    新增顶栏和按钮
]]
function CodeGameScreenMagicLadyMachine:initTopCommonJackpotBar()
    if not ACTIVITY_REF.CommonJackpot then
        return 
    end

    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        return
    end

    local commonJackpotTitle = mgr:createTitleNode()

    if not commonJackpotTitle then
        return
    end
    self.m_commonJackpotTitle = commonJackpotTitle
    self:addChild(self.m_commonJackpotTitle, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    local titlePos = util_getConvertNodePos(self.m_topUI:findChild("TopUI_down"), self)
    local topSpSize = self.m_commonJackpotTitle:findChild("sp_Jackpot1"):getContentSize()
    titlePos.y = titlePos.y - topSpSize.height*0.25
    self.m_commonJackpotTitle:setPosition(titlePos)
    self.m_commonJackpotTitle:setScale(globalData.topUIScale)
    
end

return CodeGameScreenMagicLadyMachine