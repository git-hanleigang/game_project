---
-- island li
-- 2019年1月26日
-- CodeGameScreenGoldMarmotMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "levelsGoldMarmotPublicConfig"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenGoldMarmotMachine = class("CodeGameScreenGoldMarmotMachine", BaseSlotoManiaMachine)
local BaseDialog = require "Levels.BaseDialog"

CodeGameScreenGoldMarmotMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenGoldMarmotMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenGoldMarmotMachine.SYMBOL_SCORE_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenGoldMarmotMachine.SYMBOL_SCORE_WILD_BIG = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
CodeGameScreenGoldMarmotMachine.SYMBOL_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7


CodeGameScreenGoldMarmotMachine.CHANGE_TO_BIG_WILD = GameEffect.EFFECT_SELF_EFFECT - 1 --wild图标合并

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

--spine Tag 值
local TAG_BONUS_SPINE = 1001

--土拨鼠初始位置节点
local MARMOT_NODES = {"Node_jackpot_grand","Node_jackpot_major","Node_jackpot_minor","Node_jackpot_mini"}

--行进方向
local DIRECTION = {
    UP = 1,
    DOWN = 2,
    LEFT = 3,
    RIGHT = 4
}

local POS_DIR = {
    LEFT = 1,
    RIGHT = 2,
    UP = 3,
    DOWN = 4,
    LEFT_DOWN = 5,
    LEFT_UP = 6,
    RIGHT_DOWN = 7,
    RIGHT_UP = 8
}

local JACKPOT_TPYE = {
    "grand",
    "major",
    "minor",
    "mini"
}

-- 构造函数
function CodeGameScreenGoldMarmotMachine:ctor()
    CodeGameScreenGoldMarmotMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_publicConfig = PublicConfig
    self.m_curScore = 0
    self.m_spinRestMusicBG = true
    self.m_changeCols = {}

    self.m_topNodes = {}
    self.m_bulingNodes = {}
    self.m_scatter_down = {}
    self.m_bonus_down = {}

    self.m_digHoleSoundId = {}

    self.m_isLongRun = false
 
    --init
    self:initGame()
end

function CodeGameScreenGoldMarmotMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("GoldMarmotConfig.csv", "LevelGoldMarmotConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenGoldMarmotMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "GoldMarmot"  
end

function CodeGameScreenGoldMarmotMachine:initMachineBg()
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

    self.m_bg_spine = util_spineCreate("GameScreenGoldMarmotBg",true,true)
    gameBg:findChild("root"):addChild(self.m_bg_spine)

    util_spinePlay(self.m_bg_spine,"idleframe1",true)
end

function CodeGameScreenGoldMarmotMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_freebar")
    self.m_baseFreeSpinBar = util_createView("CodeGoldMarmotSrc.GoldMarmotFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenGoldMarmotMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
end

function CodeGameScreenGoldMarmotMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenGoldMarmotMachine:initReSpinBar()
    local node_bar = self:findChild("Node_respinbar")
    self.m_baseReSpinBar = util_createView("CodeGoldMarmotSrc.GoldMarmotRespinBar")
    node_bar:addChild(self.m_baseReSpinBar)
    self.m_baseReSpinBar:setVisible(false)
end

function CodeGameScreenGoldMarmotMachine:showReSpinBar()
    if not self.m_baseReSpinBar then
        return
    end
    self.m_baseReSpinBar:setVisible(true)
end

function CodeGameScreenGoldMarmotMachine:hideReSpinBar()
    if not self.m_baseReSpinBar then
        return
    end
    self.m_baseReSpinBar:setVisible(false)
end

function CodeGameScreenGoldMarmotMachine:updateRespinCount(leftCount,isInit)
    self.m_baseReSpinBar:updateRepinCount(leftCount,isInit)
end


function CodeGameScreenGoldMarmotMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    self:initReSpinBar()    --ReSpinbar

    local rootNode = self:findChild("root")
    self.m_rootNode = rootNode
    --特效层
    self.m_effectNode = cc.Node:create()
    rootNode:addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self.m_effectNode2 = cc.Node:create()
    self:addChild(self.m_effectNode2,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode2:setScale(self.m_machineRootScale)

    --jackpot
    self.m_jackpotBar = util_createView("CodeGoldMarmotSrc.GoldMarmotJackPotBarView",{machine = self})
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)

    --base轮盘背景
    self.m_base_reel_bg = self:findChild("Node_base_reel")
    --free轮盘背景
    self.m_free_reel_bg = self:findChild("Node_free_reel")
    --respin轮盘后置背景
    self.m_respin_reel_bg = self:findChild("Node_tudibg")
    self.m_respin_reel_bg:setVisible(false)
    --respin轮盘前置背景节点
    self.m_respin_reel_bg_front = self:findChild("Node_tudi")
    self.m_respin_reel_bg_front:setVisible(false)

    local respin_bg_behind = util_createAnimation("GoldMarmot_tudibg.csb")
    self.m_respin_reel_bg:addChild(respin_bg_behind)

    self.m_respin_bg_nodes = {}
    for index = 1,15 do
        local bg_node = util_createAnimation("GoldMarmot_tudi.csb")
        for iPos=1,15 do
            bg_node:findChild("Node_tudi"..iPos):setVisible(index == iPos)
        end
        self:findChild("Node_tudi"..index):addChild(bg_node)
        self.m_respin_bg_nodes[index] = bg_node
    end

    

    --四只土拨鼠
    self.m_marmots = {}
    local skins = {"hong","fen","lan","lv"}
    --jackpot框
    self.m_jackpotTips = {}
    for index = 1,4 do
        local marmot = util_spineCreate("GoldMarmot_marmot",true,true)
        marmot:setSkin(skins[index])
        self.m_respin_reel_bg_front:addChild(marmot)
        marmot:setPosition(util_convertToNodeSpace(self:findChild(MARMOT_NODES[index]),self.m_respin_reel_bg_front))
        self.m_marmots[index] = marmot

        local partical = util_createAnimation("GoldMarmot_marmot_0.csb")
        marmot:addChild(partical)
        marmot.m_partical = partical
        partical:setScale(2)
        partical:setVisible(false)

        local tip = util_createAnimation("GoldMarmot_respinjackpot.csb")
        self:findChild("Node_jackpot_"..JACKPOT_TPYE[index]):addChild(tip)
        for i = 1,4 do
            tip:findChild("Node_"..JACKPOT_TPYE[i].."jackpot"):setVisible(index == i)
        end
        tip:setVisible(false)
        local light = util_createAnimation("GoldMarmot_respinjackpot_tx.csb")
        self:findChild("Node_jackpot_"..JACKPOT_TPYE[index]):addChild(light)
        light:setVisible(false)
        self.m_jackpotTips[index] = {
            tip = tip,
            light = light
        }
    end

    util_setCascadeOpacityEnabledRescursion(self.m_respin_reel_bg_front,true)

    self:findChild("Node_respinLights"):setVisible(false)
end

--[[
    重置土拨鼠位置
]]
function CodeGameScreenGoldMarmotMachine:resetMarmotPos()
    for index = 1,4 do
        local marmot = self.m_marmots[index]

        local dirction,posIndex = self:getCurDirection(index,1)
        local startNode = self:findChild("Node_tudi"..(posIndex + 1))
        local startPos = cc.p(startNode:getPosition())
        marmot:setPosition(startPos)
        if dirction == DIRECTION.LEFT then
            marmot:setScaleX(-1)
            marmot.m_curDirction = DIRECTION.LEFT 
        else
            marmot:setScaleX(1)
            marmot.m_curDirction = DIRECTION.RIGHT 
        end
        
    end
end


function CodeGameScreenGoldMarmotMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_enter_game)

    end,0.4,self:getModuleName())
end

function CodeGameScreenGoldMarmotMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenGoldMarmotMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeBgAni("freespin") 
        self.m_base_reel_bg:setVisible(false)
        self.m_free_reel_bg:setVisible(true)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    else
        self:changeBgAni("base") 
        self.m_base_reel_bg:setVisible(true)
        self.m_free_reel_bg:setVisible(false)
    end

    self:runCsbAction("idleframe",true)
end

function CodeGameScreenGoldMarmotMachine:addObservers()
    CodeGameScreenGoldMarmotMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            --freespin最后一次spin不会播大赢,需单独处理
            local fsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
            if fsLeftCount <= 0 then
                self.m_bIsBigWin = false
            end
        end
        
        
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local winRatio = winCoin / lTatolBetNum
        local soundIndex = 1
        local soundTime = 2
        if winRatio > 0 then
            if winRatio <= 1 then
                soundIndex = 1
            elseif winRatio > 1 and winRatio <= 3 then
                soundIndex = 2
            else
                soundIndex = 3
            end
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = ""
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = self.m_publicConfig.SoundConfig["sound_GoldMarmot_fs_winline_"..soundIndex] 
        else
            soundName = self.m_publicConfig.SoundConfig["sound_GoldMarmot_winline_"..soundIndex] 
            
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenGoldMarmotMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenGoldMarmotMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenGoldMarmotMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_GoldMarmot_10"
    end

    if symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_GoldMarmot_Bonus_1"
    end

    if symbolType == self.SYMBOL_SCORE_WILD_BIG then
        return "Socre_GoldMarmot_Wild"
    end

    if symbolType == self.SYMBOL_EMPTY then
        return "Socre_GoldMarmot_Empty"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenGoldMarmotMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenGoldMarmotMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenGoldMarmotMachine:MachineRule_initGame(  )

end

--
--单列滚动停止回调
--
function CodeGameScreenGoldMarmotMachine:slotOneReelDown(reelCol)    
    CodeGameScreenGoldMarmotMachine.super.slotOneReelDown(self,reelCol) 
    local parentData = self.m_slotParents[reelCol]
    local nodeParent = parentData.slotParent
    local nodes = nodeParent:getChildren()
    local slotParentBig = parentData.slotParentBig
    if slotParentBig then
        local nodesBig = slotParentBig:getChildren()
        for i = 1, #nodesBig do
            nodes[#nodes + 1] = nodesBig[i]
        end
    end

    --播放配置信号的落地音效
    -- self:playSymbolBulingSound(nodes)
    -- 播放配置信号的落地动效
    self:playSymbolBulingAnim(nodes)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenGoldMarmotMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenGoldMarmotMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

function CodeGameScreenGoldMarmotMachine:changeBgAni(bgType)
    if bgType == "base" then
        util_spinePlay(self.m_bg_spine,"idleframe1",true)
    else
        util_spinePlay(self.m_bg_spine,"idleframe2",true)
    end
end

--[[
    freespin过场动画
]]
function CodeGameScreenGoldMarmotMachine:changeScene_free(func)
    local spine = util_spineCreate("GoldMarmot_GC1",true,true)
    util_spinePlay(spine,"guochang")
    util_spineEndCallFunc(spine,"guochang",function()
        spine:setVisible(false)
        self:delayCallBack(0.5,function()
            spine:removeFromParent()
        end)


        if type(func) == "function" then
            func()
        end
    end)

    self:findChild("root"):addChild(spine)
end

------------Respin相关

-- 继承底层respinView
function CodeGameScreenGoldMarmotMachine:getRespinView()
    return "CodeGoldMarmotSrc.GoldMarmotRespinView"
end
-- 继承底层respinNode
function CodeGameScreenGoldMarmotMachine:getRespinNode()
    return "CodeGoldMarmotSrc.GoldMarmotRespinNode"
end

--触发respin
function CodeGameScreenGoldMarmotMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:changeTouchSpinLayerSize()

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self:reSpinEffectChange()
    self:playRespinViewShowSound()
    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
    
    self:runNextReSpinReel()
end
--[[
    显示ReSpinView
]]
function CodeGameScreenGoldMarmotMachine:showRespinView(effectData)
    --可随机的普通信息
    local randomTypes = {}


    --可随机的特殊信号
    local endTypes = {
        {type = self.SYMBOL_SCORE_BONUS, runEndAnimaName = "buling", bRandom = false},
    }

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    self.m_curScore = 0
    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    


    local function startAction(  )
        self:showReSpinBar()

        self:updateRespinCount(self.m_runSpinResultData.p_reSpinCurCount,true)

        --开始触发respin
        self:triggerReSpinCallFun(endTypes, randomTypes)
    end

    --播放触发动画
    local curBonusList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if node.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    curBonusList[#curBonusList + 1] = node
                elseif node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    local parentData = self.m_slotParents[iCol]
                    local slotParent = parentData.slotParent
                    node:changeParentToOtherNode(slotParent)
                end
            end
        end
    end
    self:clearCurMusicBg()
    local randIndex = math.random(1,2)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_GoldMarmot_bonus_trigger_short_music_fs_"..randIndex])
    

    --触发动画
    local aniTime = 0
    for i,symbolNode in ipairs(curBonusList) do
        symbolNode.preParent = symbolNode:getParent()
        symbolNode:changeParentToOtherNode(self.m_effectNode)
        local node = symbolNode:getCcbProperty("node_spine")
        if node then
            local spine = node:getChildByTag(TAG_BONUS_SPINE)
            if spine then
                util_spinePlay(spine,"actionframe",false)
                util_spineEndCallFunc(spine,"actionframe",function()
                    symbolNode:changeParentToOtherNode(self.m_clipParent)
                    util_spinePlay(spine,"idleframe",true)
                end)
                aniTime = spine:getAnimationDurationTime("actionframe")
            end
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:hideFreeSpinBar()
    end


    self:delayCallBack(aniTime + 0.1,function()
        self:checkChangeBaseParent()
        --先创建respinview防止卡顿
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
        
        --隐藏 盘面信息
        self:setReelSlotsNodeVisible(false)

        self:delayCallBack(0.1,function()
            --过场动画
            self:changeSceneToRespin(function()
                
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_show_respin_start)
                local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START,nil,function()
                    -- 更改respin 状态下的背景音乐
                    self:changeReSpinBgMusic()
                    --挖洞动画
                    self:startDigHole(function()
                        startAction()
                    end)
                end)
                view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_GoldMarmot_clickBtn
                view:setBtnClickFunc(function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_show_respin_start_over)
                end)
            end)

            self:delayCallBack(1.85,function()
                self:changeRespinShowUI()
            end)
        end)

        
    end)
end

function CodeGameScreenGoldMarmotMachine:initRespinView(endTypes, randomTypes)
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
            
        end
    )

    
end

--[[
    变更respin轮盘显示
]]
function CodeGameScreenGoldMarmotMachine:changeRespinShowUI(endTypes, randomTypes)
    self.m_base_reel_bg:setVisible(false)
    self.m_free_reel_bg:setVisible(false)
    self.m_respin_reel_bg:setVisible(true)
    self.m_respin_reel_bg_front:setVisible(true)
    self:findChild("Node_respinLights"):setVisible(true)
    self:hideJackpotTips()

    self:changeBgAni("respin")

    for k,node in pairs(self.m_respin_bg_nodes) do
        node:setOpacity(255)
        node:setVisible(true)
    end

    for index = 1,4 do
        self.m_marmots[index]:setVisible(false)
    end

    if self.m_respinView then
        for i,respinNode in ipairs(self.m_respinView.m_respinNodes) do
            local symbolNode = respinNode.m_baseFirstNode
            --非bonus小块转化为空图标
            if symbolNode and symbolNode.p_symbolType ~= self.SYMBOL_SCORE_BONUS then
                symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,self.SYMBOL_EMPTY), self.SYMBOL_EMPTY)

                if symbolNode.p_symbolImage then
                    symbolNode.p_symbolImage:removeFromParent()
                    symbolNode.p_symbolImage = nil
                end
            end
            if symbolNode then
                symbolNode:setVisible(false)
            end
        end
    end
end

--[[
    土拨鼠挖洞动画
]]
function CodeGameScreenGoldMarmotMachine:startDigHole(func)
    self:resetMarmotPos()
    --四只土拨鼠钻出
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_marmot_show)
    for index = 1,4 do
        local marmot = self.m_marmots[index]
        marmot:setVisible(true)
        util_spinePlay(marmot,"start")
    end

    local endCount = 0
    local endFunc = function()
        endCount = endCount + 1
        --挖洞结束判定
        if endCount >= 4 then

            for index = 1,#self.m_digHoleSoundId do
                local soundID = self.m_digHoleSoundId[index]
                gLobalSoundManager:stopAudio(soundID)
            end
            
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_marmot_enter_ground)
            for index = 1,4 do
                local marmot = self.m_marmots[index]
                util_spinePlay(marmot,"idle_over")
                util_spineEndCallFunc(marmot,"idle_over",function()
                    marmot:setVisible(false)
                end)
            end

            self:delayCallBack(30 / 30,function()
                --显示小块底色
                self.m_respinView:showJackpotColor()
                --显示bonus图标
                self:showBonusNodeAfterDigHole()
                self:showJackpotTips()
                self:showRespinTip(function()
                    --检测是否有中的jackpot
                    self:checkHitJackpot()
                    
                    if type(func) == "function" then
                        func()
                    end
                end)
                
            end)
            
            return
        end
    end

    self:delayCallBack(21 / 30,function()
        self.m_digHoleSoundId = {}
        local soundID = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_dig_hole,true)
        self.m_digHoleSoundId[#self.m_digHoleSoundId + 1] = soundID
        for jackpotType = 1,4 do
            self:digNextHole(jackpotType,1,endFunc)
        end
        
    end)
end

function CodeGameScreenGoldMarmotMachine:showBonusNodeAfterDigHole(func)
    for i,respinNode in ipairs(self.m_respinView.m_respinNodes) do
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS  then  -- 显示bonus图标
            symbolNode:runAnim("actionframe")
        end

        if symbolNode then
            symbolNode:setVisible(true)
        end
        
    end
    self:delayCallBack(20 / 60,func)
end

function CodeGameScreenGoldMarmotMachine:showRespinTip(func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_tip_view_show)
    local tip = util_createAnimation("GoldMarmot_respintanban.csb")
    self:findChild("Node_respintanban"):addChild(tip)
    tip:runCsbAction("start",false,function()
        tip:removeFromParent()
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenGoldMarmotMachine:hideJackpotTips()
    for index = 1,4 do
        local tip = self.m_jackpotTips[index].tip
        tip:setVisible(false)
        local light = self.m_jackpotTips[index].light
        light:setVisible(false)
    end
end

function CodeGameScreenGoldMarmotMachine:showJackpotTips()
    for index = 1,4 do
        local tip = self.m_jackpotTips[index].tip
        local light = self.m_jackpotTips[index].light
        tip:setVisible(true)
        tip:runCsbAction("chuxian",false,function()
            light:setVisible(true)
            light:runCsbAction("idle",true)
        end)
    end
end

--[[
    挖下个洞
]]
function CodeGameScreenGoldMarmotMachine:digNextHole(jackpotType,curIndex,func)

    local direction,nextPos = self:getCurDirection(jackpotType,curIndex)
    if not direction then
        if type(func) == "function" then
            func()
        end
        return
    end

    
    

    local marmot = self.m_marmots[jackpotType]

    if curIndex == 1 then
        local startNode = self:findChild("Node_tudi"..(nextPos + 1))
        local startPos = cc.p(startNode:getPosition())
        marmot:setPositionY(startPos.y)
        direction = marmot.m_curDirction
    end

    self:setCurHoleFrame(jackpotType,curIndex)
    --动作结束回调
    local callBack = function()
        util_spinePlay(marmot,"idle_win",true)
        
        self:digNextHole(jackpotType,curIndex + 1,func)
    end

    --土拨鼠移动动作 frameCount:移动所需帧数
    local function moveAction(frameCount)
        local endNode = self:findChild("Node_tudi"..(nextPos + 1))
        local moveTo = cc.MoveTo:create(frameCount / 30,cc.p(endNode:getPosition()))
        marmot:runAction(moveTo)
    end

    --土块消失动作
    local function fadeOutBg(frameCount)
        local bgNode = self.m_respin_bg_nodes[nextPos + 1]
        local seq = cc.Sequence:create({
            cc.FadeOut:create(frameCount / 30),
            cc.Hide:create()
        })
        bgNode:runAction(seq)
    end
    if direction == DIRECTION.UP then
        marmot.m_partical:setVisible(true)
        self:showMarmotPartical(marmot.m_partical,direction)
        local params = {{
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = marmot,   --执行动画节点  必传参数
            actionName = "shang", --动作名称  动画必传参数,单延时动作可不传
            keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
                {
                    keyFrameName = "kaishi",   --关键帧名  spine动画用
                    callBack = function()
                        marmot.m_partical:setVisible(false)
                        --移动土拨鼠位置
                        moveAction(8)
                    end,
                }       --关键帧回调
            },   
            callBack = callBack,   --回调函数 可选参数
        }}
        util_runAnimations(params)
        self:delayCallBack(10 / 30,function()
            fadeOutBg(40)
        end)

        --获取下一个点的方向
        local nextDirection = self:getCurDirection(jackpotType,curIndex + 1)
        
        if nextDirection and nextDirection ~= marmot.m_curDirction then
            self:delayCallBack(39 / 30,function()
                if nextDirection == DIRECTION.LEFT then
                    marmot:setScaleX(-1)
                    marmot.m_curDirction = DIRECTION.LEFT 
                elseif nextDirection == DIRECTION.RIGHT then
                    marmot:setScaleX(1)
                    marmot.m_curDirction = DIRECTION.RIGHT 
                end
            end)
        end
        
    elseif direction == DIRECTION.DOWN then
        marmot.m_partical:setVisible(true)
        self:showMarmotPartical(marmot.m_partical,direction)
        local params = {{
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = marmot,   --执行动画节点  必传参数
            actionName = "xia", --动作名称  动画必传参数,单延时动作可不传
            keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
                {
                    keyFrameName = "kaishi",   --关键帧名  spine动画用
                    callBack = function()
                        marmot.m_partical:setVisible(false)
                        --移动土拨鼠位置
                        moveAction(4)
                    end,
                }       --关键帧回调
            },   
            callBack = callBack,   --回调函数 可选参数
        }}
        util_runAnimations(params)
        self:delayCallBack(10 / 30,function()
            fadeOutBg(40)
        end)

        --获取下一个点的方向
        local nextDirection = self:getCurDirection(jackpotType,curIndex + 1)
        
        if nextDirection and nextDirection ~= marmot.m_curDirction then
            self:delayCallBack(37 / 30,function()
                if nextDirection == DIRECTION.LEFT then
                    marmot:setScaleX(-1)
                    marmot.m_curDirction = DIRECTION.LEFT 
                elseif nextDirection == DIRECTION.RIGHT then
                    marmot:setScaleX(1)
                    marmot.m_curDirction = DIRECTION.RIGHT 
                end
            end)
        end
    else
        marmot.m_partical:setVisible(true)
        self:showMarmotPartical(marmot.m_partical,direction)
        local params = {}
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = marmot,   --执行动画节点  必传参数
            actionName = "actionframe_win", --动作名称  动画必传参数,单延时动作可不传
        }
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = marmot,   --执行动画节点  必传参数
            actionName = "actionframe_win", --动作名称  动画必传参数,单延时动作可不传
            callBack = function()
                marmot.m_partical:setVisible(false)
            end
        }
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = marmot,   --执行动画节点  必传参数
            actionName = "actionframe_over", --动作名称  动画必传参数,单延时动作可不传
            callBack = callBack,   --回调函数 可选参数
        }
        util_runAnimations(params)
        fadeOutBg(18 * 2)
        moveAction(18 * 2)
    end

end

function CodeGameScreenGoldMarmotMachine:showMarmotPartical(partical,direction)
    if direction == DIRECTION.UP then
        partical:findChild("shang"):setVisible(true)
        partical:findChild("shang1"):setVisible(true)
        partical:findChild("qian"):setVisible(false)
        partical:findChild("qian1"):setVisible(false)
        partical:findChild("xia"):setVisible(false)
        partical:findChild("xia1"):setVisible(false)
        
    elseif direction == DIRECTION.DOWN then
        partical:findChild("shang"):setVisible(false)
        partical:findChild("shang1"):setVisible(false)
        partical:findChild("qian"):setVisible(false)
        partical:findChild("qian1"):setVisible(false)
        partical:findChild("xia"):setVisible(true)
        partical:findChild("xia1"):setVisible(true)

        
    else
        partical:findChild("shang"):setVisible(false)
        partical:findChild("shang1"):setVisible(false)
        partical:findChild("qian"):setVisible(true)
        partical:findChild("qian1"):setVisible(true)
        partical:findChild("xia"):setVisible(false)
        partical:findChild("xia1"):setVisible(false)
    end
end

--[[
    判定当前行进方向
]]
function CodeGameScreenGoldMarmotMachine:getCurDirection(jackpotType,curIndex)
    local mapData = self.m_runSpinResultData.p_rsExtraData.map
    if not mapData then
        return nil
    end

    local function debugErrorInfo()
        local json = cjson.encode(mapData)
        util_printLog("土拨鼠挖洞点位数据错误!!! mapData = "..json)
    end

    if curIndex == 1 then
        local curPos = mapData[jackpotType][curIndex]
        local nextPos = mapData[jackpotType][curIndex + 1]

        local curPosData = self:getRowAndColByPos(curPos)
        local nextPosData = self:getRowAndColByPos(nextPos)
        -- local iCol,iRow = pos.iY,pos.iX
        --上下方向
        if curPosData.iY == nextPosData.iY then
            if curPosData.iX > nextPosData.iX then
                return DIRECTION.DOWN,curPos
            elseif curPosData.iX < nextPosData.iX then
                return DIRECTION.UP,curPos
            else
                --打印错误信息
                debugErrorInfo()
            end
        elseif curPosData.iX == nextPosData.iX then --左右方向
            if curPosData.iY > nextPosData.iY then
                return DIRECTION.LEFT,curPos
            elseif curPosData.iY < nextPosData.iY then
                return DIRECTION.RIGHT,curPos
            else
                --打印错误信息
                debugErrorInfo()
            end
        else
            --打印错误信息
            debugErrorInfo()
        end
    else
        if #mapData[jackpotType] >= curIndex then
            local curPos = mapData[jackpotType][curIndex - 1]
            local nextPos = mapData[jackpotType][curIndex]

            local curPosData = self:getRowAndColByPos(curPos)
            local nextPosData = self:getRowAndColByPos(nextPos)
            -- local iCol,iRow = pos.iY,pos.iX
            --上下方向
            if curPosData.iY == nextPosData.iY then
                if curPosData.iX > nextPosData.iX then
                    return DIRECTION.DOWN,nextPos
                elseif curPosData.iX < nextPosData.iX then
                    return DIRECTION.UP,nextPos
                else
                    --打印错误信息
                    debugErrorInfo()
                end
            elseif curPosData.iX == nextPosData.iX then --左右方向
                if curPosData.iY > nextPosData.iY then
                    return DIRECTION.LEFT,nextPos
                elseif curPosData.iY < nextPosData.iY then
                    return DIRECTION.RIGHT,nextPos
                else
                    --打印错误信息
                    debugErrorInfo()
                end
            else
                --打印错误信息
                debugErrorInfo()
            end
            

        else
            return nil
        end
    end

    return nil
end

--[[
    设置当前挖过洞的框
]]
function CodeGameScreenGoldMarmotMachine:setCurHoleFrame(jackpotType,curIndex)
    local mapData = self.m_runSpinResultData.p_rsExtraData.map
    if not mapData then
        return
    end

    -- local iCol,iRow = pos.iY,pos.iX
    if curIndex == 1 then
        local curPos = mapData[jackpotType][curIndex]
        local curPosData = self:getRowAndColByPos(curPos)

        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(curPosData.iY,curPosData.iX)
        respinNode:setJackpotType(jackpotType)
        self.m_respinView:showAllFrame(curPosData.iY,curPosData.iX,jackpotType)
    else
        local curPos = mapData[jackpotType][curIndex]
        local curPosData = self:getRowAndColByPos(curPos)
        local curRespinNode = self.m_respinView:getRespinNodeByRowAndCol(curPosData.iY,curPosData.iX)

        --需要添加线的方向
        local needAddFrame = {}
        for k,dic in pairs(DIRECTION) do
            needAddFrame[dic] = true
        end

        --检测上下左右是否有相邻的小块,如果有去掉边界
        if curIndex - 1 > 0 then
            for index = 1,curIndex - 1 do
                local pos = mapData[jackpotType][index]
                local posData = self:getRowAndColByPos(pos)

                local dict = self:getDircByPosData(curPosData,posData)
                if dict then
                    --现有小块去除边界
                    local respinNode = self.m_respinView:getRespinNodeByRowAndCol(posData.iY,posData.iX)
                    self.m_respinView:hideFrameByDirct(posData.iY,posData.iX,dict)
                    if dict == DIRECTION.UP then
                        needAddFrame[DIRECTION.DOWN] = false
                    elseif dict == DIRECTION.DOWN then
                        needAddFrame[DIRECTION.UP] = false
                    elseif dict == DIRECTION.LEFT then
                        needAddFrame[DIRECTION.RIGHT] = false
                    else
                        needAddFrame[DIRECTION.LEFT] = false
                    end
                end
            end
        end

        --添加当前小块边界
        for dic,isNeedAdd in pairs(needAddFrame) do
            if isNeedAdd then
                curRespinNode:setJackpotType(jackpotType)
                self.m_respinView:showFrameByDirct(curPosData.iY,curPosData.iX,dic,jackpotType)
            end
        end
    end

    --检测拐角并缩放横向线
    self:checkCornerAndScaleLine(jackpotType,curIndex)
end

function CodeGameScreenGoldMarmotMachine:checkCornerAndScaleLine(jackpotType,curIndex)
    --只有两个小块不可能存在拐角
    if curIndex <= 2 then
        return
    end

    if not self.m_runSpinResultData.p_rsExtraData.map then
        return
    end

    local mapData = self.m_runSpinResultData.p_rsExtraData.map[jackpotType]

    --检测是否超出边界
    local function checkOutLine(col,row)
        if col < 1 or col > self.m_iReelColumnNum or row < 1 or row > self.m_iReelRowNum then
            return true
        end

        return false
    end

    --检测该点是否在路径里
    local function checkInMap(posData)
        if not posData then
            return false
        end
        local serverIndex = self:getPosReelIdx(posData.iRow, posData.iCol)
        for index = 1,curIndex do
            if mapData[index] == serverIndex then 
                return true
            end
        end
        return false
    end

    -- local iCol,iRow = pos.iY,pos.iX
    local cornerCount = 0
    for index = 1,curIndex do
        local pos = mapData[index]
        local posData = self:getRowAndColByPos(pos)

        --检测该点是否为交叉点

        --左边的点 1
        local leftPos = {iRow = posData.iX, iCol = posData.iY - 1}
        --右边的点 2
        local rightPos = {iRow = posData.iX, iCol = posData.iY + 1}
        --上边的点 3
        local upPos = {iRow = posData.iX + 1, iCol = posData.iY}
        --下边的点 4
        local downPos = {iRow = posData.iX - 1, iCol = posData.iY}
        --左下 5
        local leftDownPos = {iRow = posData.iX - 1, iCol = posData.iY - 1}
        --左上 6 
        local leftUpPos = {iRow = posData.iX + 1, iCol = posData.iY - 1}
        --右下 7 
        local rightDownPos = {iRow = posData.iX - 1, iCol = posData.iY + 1}
        --右上 8
        local rightUpPos = {iRow = posData.iX + 1, iCol = posData.iY + 1}

        local posAry = {leftPos,rightPos,upPos,downPos,leftDownPos,leftUpPos,rightDownPos,rightUpPos}

        --检测是否超出边界
        for iCount = 1,#posAry do
            if checkOutLine(posAry[iCount].iCol,posAry[iCount].iRow) then
                posAry[iCount] = false
            end

            --检测是否在路径里
            if posAry[iCount] and not checkInMap(posAry[iCount]) then
                posAry[iCount] = false
            end
        end

        local offsetX = 3
        --检测左下是否为拐角
        if posAry[POS_DIR.LEFT] and posAry[POS_DIR.DOWN] and not posAry[POS_DIR.LEFT_DOWN] then
            local posData = posAry[POS_DIR.LEFT]
            --改变左边的点的下边界
            self.m_respinView:changeFramePos(posData.iCol,posData.iRow,DIRECTION.DOWN,offsetX)
            cornerCount = cornerCount + 1
        end

        --检测左上是否为拐角
        if posAry[POS_DIR.LEFT] and posAry[POS_DIR.UP] and not posAry[POS_DIR.LEFT_UP] then
            --改变左边的点的上边界
            local posData = posAry[POS_DIR.LEFT]
            self.m_respinView:changeFramePos(posData.iCol,posData.iRow,DIRECTION.UP,offsetX)
            cornerCount = cornerCount + 1
        end

        --检测右下是否为拐点
        if posAry[POS_DIR.RIGHT] and posAry[POS_DIR.DOWN] and not posAry[POS_DIR.RIGHT_DOWN] then
            --改变右边点的下边界
            local posData = posAry[POS_DIR.RIGHT]
            self.m_respinView:changeFramePos(posData.iCol,posData.iRow,DIRECTION.DOWN,-offsetX)
            cornerCount = cornerCount + 1
        end

        --检测右上是否为拐点
        if posAry[POS_DIR.RIGHT] and posAry[POS_DIR.UP] and not posAry[POS_DIR.RIGHT_UP] then
            --改变右边点的上边界
            local posData = posAry[POS_DIR.RIGHT]
            self.m_respinView:changeFramePos(posData.iCol,posData.iRow,DIRECTION.UP,-offsetX)
            cornerCount = cornerCount + 1
        end
    end
    --有两个拐角的情况只有一种,单独特殊处理即可
    if cornerCount == 2 and curIndex == 5 then
        self.m_respinView:changeFramePos(2,3,DIRECTION.DOWN,0)
    end
end

--[[
    根据坐标确定两个小块的相邻方向
]]
function CodeGameScreenGoldMarmotMachine:getDircByPosData(posData1,posData2)
    -- local iCol,iRow = pos.iY,pos.iX
    if posData1.iY == posData2.iY then -- 上下相邻
        --检测两个小块是否相邻
        if math.abs(posData1.iX - posData2.iX) ~= 1 then
            return
        end
        if posData1.iX > posData2.iX then
            return DIRECTION.UP
        else
            return DIRECTION.DOWN
        end
    elseif posData1.iX == posData2.iX then
        --检测两个小块是否相邻
        if math.abs(posData1.iY - posData2.iY) ~= 1 then
            return
        end
        if posData1.iY > posData2.iY then
            return DIRECTION.RIGHT
        else
            return DIRECTION.LEFT
        end
    else
        util_printLog("两个位置不相邻")
    end
end

--[[
    respin过场动画
]]
function CodeGameScreenGoldMarmotMachine:changeSceneToRespin(func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_change_scene_free_to_respin)
    local spine = util_spineCreate("GoldMarmot_GC2",true,true)
    util_spinePlay(spine,"guochang1")
    util_spineEndCallFunc(spine,"guochang1",function()
        spine:setVisible(false)
        self:delayCallBack(0.5,function()
            spine:removeFromParent()
        end)

        if type(func) == "function" then
            func()
        end
    end)
    spine:setScale(1.1)
    self:findChild("root"):addChild(spine)
end

--开始滚动
function CodeGameScreenGoldMarmotMachine:startReSpinRun()
    self:updateRespinCount(self.m_runSpinResultData.p_reSpinCurCount - 1)
    CodeGameScreenGoldMarmotMachine.super.startReSpinRun(self)

end

function CodeGameScreenGoldMarmotMachine:reSpinReelDown(addNode)
    self:updateRespinCount(self.m_runSpinResultData.p_reSpinCurCount)
    CodeGameScreenGoldMarmotMachine.super.reSpinReelDown(self)

    --检测是否有中的jackpot
    self:checkHitJackpot()
end

--[[
    检测是否中了jackpot
]]
function CodeGameScreenGoldMarmotMachine:checkHitJackpot()
    local mapData = self.m_runSpinResultData.p_rsExtraData.map
    if not mapData then
        return
    end

    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local hitJackpot = {}
    for jackpotIndex = 1,#mapData do
        local count = 0
        for index = 1,#mapData[jackpotIndex] do
            local pos = mapData[jackpotIndex][index]
            for k,iconData in pairs(storedIcons) do
                if iconData[1] == pos then
                    count = count + 1
                end
            end
        end
        if count == #mapData[jackpotIndex] then
            hitJackpot[#hitJackpot + 1] = jackpotIndex
            --播背景高亮动画
            self.m_respinView:showJackpotWinAni(jackpotIndex)

            local light = self.m_jackpotTips[jackpotIndex].light
            light:setVisible(true)
            light:runCsbAction("zhongjiang",true)
        end
    end

    if #hitJackpot > 0 then
        self.m_jackpotBar:showHitJackpot(hitJackpot)
    end
end

function CodeGameScreenGoldMarmotMachine:reSpinEndAction()
    local cleanNodes = self.m_respinView:getAllCleaningNode()
    self:clearCurMusicBg()

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldMarmot_bonus_trigger)
    for k,symbolNode in pairs(cleanNodes) do
        local node = symbolNode:getCcbProperty("node_spine")
        local spine = node:getChildByTag(TAG_BONUS_SPINE)
        if spine then
            util_spinePlay(spine,"actionframe")
        end
    end

    --触发动画播完后延迟0.5s结算
    self:delayCallBack(60 / 30 + 0.5,function()
        self:collectBonusScore(cleanNodes,1,function()
            local jackpot = clone(self.m_runSpinResultData.p_rsExtraData.jackpot)
            table.sort(jackpot,function(a,b)
                return a[2] < b[2]
            end)
            if jackpot then
                self:jackpotWin(jackpot,1,function()
                    self:respinOver()
                end)
            else
                self:respinOver()
            end
        end)
    end)

    
end

--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenGoldMarmotMachine:checkChangeRespinFixNode(node)
    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex
    print("p_rowIndex == "..node.p_rowIndex)
    local posX, posY = node:getPosition()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = self:getReelParent(node.p_cloumnIndex):convertToNodeSpace(worldPos)
    node.p_symbolTag = SYMBOL_NODE_TAG
    node.p_showOrder = showOrder
    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node.m_isLastSymbol = false
    node.m_bRunEndTarge = false
    local columnData = self.m_reelColDatas[node.p_cloumnIndex]
    node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    self:changeBaseParent(node)
    
    node:setPosition(nodePos)
    node:setLocalZOrder(showOrder)

    if node.p_symbolType == self.SYMBOL_SCORE_BONUS then
        node:changeParentToOtherNode(self.m_clipParent)
        self.m_topNodes[#self.m_topNodes + 1] = node
    end
end

--新滚动使用 裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
function CodeGameScreenGoldMarmotMachine:changeBaseParent(slotNode)
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

function CodeGameScreenGoldMarmotMachine:jackpotWin(jackpots,index,func)
    if index > #jackpots then
        if type(func) == "function" then
            func()
        end
        return
    end
    local typeIndex = {
        grand = 1,
        major = 2,
        minor = 3,
        mini = 4
    }
    local jackpotData = jackpots[index]
    local jackpotType = jackpotData[1]
    local jackpotWin = jackpotData[3]
    local jackpotIndex = typeIndex[jackpotType]

    --播放触发动画
    local mapData = self.m_runSpinResultData.p_rsExtraData.map
    local list = mapData[jackpotIndex]
    for k,serverIndex in pairs(list) do
        local pos = self:getRowAndColByPos(serverIndex)
        -- local iCol,iRow = pos.iY,pos.iX
        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(pos.iY,pos.iX)
        if respinNode and respinNode.m_baseFirstNode then
            local node = respinNode.m_baseFirstNode:getCcbProperty("node_spine")
            local spine = node:getChildByTag(TAG_BONUS_SPINE)
            if spine then
                util_spinePlay(spine,"actionframe")
            end
        end
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldMarmot_bonus_hit_jp)

    self:delayCallBack(60 / 30,function()
        self:showJackpotWinView(jackpotType,jackpotWin,function()
            self:jackpotWin(jackpots,index + 1,func)
        end)
    end)

    
end

--[[
    显示jackpot赢钱
]]
function CodeGameScreenGoldMarmotMachine:showJackpotWinView(jackpotType,winCoin,func)
    self.m_curScore = self.m_curScore + winCoin
    --刷新赢钱
    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_curScore))
    self:playCoinWinEffectUI()

    local view = util_createView("CodeGoldMarmotSrc.GoldMarmotJackPotWinView",{
        machine = self,
        jackpotType = jackpotType,
        winCoin = winCoin,
        func = function()
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
end

function CodeGameScreenGoldMarmotMachine:collectBonusScore(cleanNodes,index,func)
    if index > #cleanNodes then
        self:delayCallBack(15 / 30,func)
        return
    end
    local symbolNode = cleanNodes[index]
    local respinNode = self.m_respinView:getRespinNodeByRowAndCol(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex)
    if symbolNode then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldMarmot_bonus_collect)
        local node = symbolNode:getCcbProperty("node_spine")
        -- symbolNode:runAnim("jiesuan")
        symbolNode:getCcbProperty("shuzi"):setVisible(false)
        symbolNode:getCcbProperty("Node_Par"):setVisible(false)

        local str = symbolNode:getCcbProperty("BitmapFontLabel_1"):getString()
        self:flyCollectScoreAni(str,symbolNode,self.m_bottomUI.coinWinNode,function()
            self.m_curScore = self.m_curScore + symbolNode.m_score
            self:playCoinWinEffectUI()
            --刷新赢钱
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_curScore))
        end)

        
        if node then
            local spine = node:getChildByTag(TAG_BONUS_SPINE)
            if spine then
                local params = {}
                params[1] = {
                    type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                    node = spine,   --执行动画节点  必传参数
                    actionName = "jiesuan", --动作名称  动画必传参数,单延时动作可不传
                    callBack = function()
                        
                    end
                }

                params[2] = {
                    type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                    node = spine,   --执行动画节点  必传参数
                    actionName = "bian", --动作名称  动画必传参数,单延时动作可不传
                }
                
                util_runAnimations(params)
                self:delayCallBack(0.5,function(  )
                    self:collectBonusScore(cleanNodes,index + 1,func)
                end)
                
            else
                self:collectBonusScore(cleanNodes,index + 1,func)
            end
        else
            self:collectBonusScore(cleanNodes,index + 1,func)
        end
    else
        self:collectBonusScore(cleanNodes,index + 1,func)
    end
end

--[[
    收集分数动画
]]
function CodeGameScreenGoldMarmotMachine:flyCollectScoreAni(coins,startNode,endNode,func)
    local flyNode = util_createAnimation("Socre_GoldMarmot_Bonus_1.csb")
    local Particle = flyNode:findChild("Particle_1")
    Particle:setPositionType(0)

    flyNode:findChild("BitmapFontLabel_1"):setString(util_formatCoins(coins, 3))

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode2)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode2)

    self.m_effectNode2:addChild(flyNode)
    flyNode:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.DelayTime:create(11 / 60),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldMarmot_fly_bonus_score)
        end),
        cc.MoveTo:create(29 / 60,endPos),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldMarmot_fly_bonus_score_feed_back)
            Particle:stopSystem()
            flyNode:findChild("BitmapFontLabel_1"):setVisible(false)
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
    flyNode:runCsbAction("jiesuan",false)
end

function CodeGameScreenGoldMarmotMachine:triggerReSpinOverCallFun(score)
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
        local winCoins = self.m_runSpinResultData.p_fsWinCoins or self:getLastWinCoin()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {winCoins, false, false})
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

--[[
    respin结束界面
]]
function CodeGameScreenGoldMarmotMachine:showRespinOverView()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldMarmot_respin_win_short_music)
    local coins = self.m_runSpinResultData.p_resWinCoins
    self.m_serverWinCoins = coins
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, function()
        self:changeScene_respinToBase(function()
            self:triggerReSpinOverCallFun(coins)

            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                self:showFreeSpinBar()
                self:changeBgAni("freespin")
                self.m_base_reel_bg:setVisible(false)
                self.m_free_reel_bg:setVisible(true)
            end
        end)
        self:delayCallBack(0.5,function()
            self:hideJackpotTips()
            self:hideReSpinBar()
            self.m_jackpotBar:hideAllLight()
            self:changeBgAni("base")

            self:findChild("Node_respinLights"):setVisible(false)

            self.m_base_reel_bg:setVisible(true)
            self.m_free_reel_bg:setVisible(false)
            self.m_respin_reel_bg:setVisible(false)
            self.m_respin_reel_bg_front:setVisible(false)

            --替换空图标
            for iCol = 1,self.m_iReelColumnNum do
                for iRow = 1,self.m_iReelRowNum do
                    local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if symbol and symbol.p_symbolType == self.SYMBOL_EMPTY then
                        local randSymbolType = math.random(0,self.SYMBOL_SCORE_10)
                        symbol:changeCCBByName(self:getSymbolCCBNameByType(self,randSymbolType), randSymbolType)
                    elseif symbol and symbol.p_symbolType == self.SYMBOL_SCORE_BONUS then
                        local node = symbol:getCcbProperty("node_spine")
                        symbol:getCcbProperty("shuzi"):setVisible(true)
                        if node then
                            local spine = node:getChildByTag(TAG_BONUS_SPINE)
                            if spine then
                                util_spinePlay(spine,"idleframe",true)
                            end
                        end
                    end
                end
            end
        end)
    end)

    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.6,sy=0.6},1390)
end



function CodeGameScreenGoldMarmotMachine:changeScene_respinToBase(func)
    -- local spine = util_spineCreate("GoldMarmot_GC2",true,true)
    -- util_spinePlay(spine,"guochang2")
    -- util_spineEndCallFunc(spine,"guochang2",function()
    --     spine:setVisible(false)
    --     self:delayCallBack(0.5,function()
    --         spine:removeFromParent()
    --     end)

    --     if type(func) == "function" then
    --         func()
    --     end
    -- end)

    -- self:findChild("root"):addChild(spine)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_change_scene_respin_to_free)
    
    self:changeScene_free(func)
end

----------- FreeSpin相关

---
-- 显示free spin
function CodeGameScreenGoldMarmotMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        self:setMinMusicBGVolume()
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end

    --等待落地动画播完
    self:delayCallBack(20 / 30,function()
        self:showBonusAndScatterLineTip(
            scatterLineValue,
            function()
                -- self:visibleMaskLayer(true,true)
                -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                self:showFreeSpinView(effectData)
            end
        )
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    end)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenGoldMarmotMachine:showBonusAndScatterLineTip(lineValue, callFun)

    local animTime = 0
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
           local symbol = self:getFixSymbol(iCol,iRow)
           if symbol and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbol.preParent = symbol:getParent()
                symbol:changeParentToOtherNode(self.m_effectNode)
                symbol:runAnim(symbol:getLineAnimName(),false,function()
                    symbol:changeParentToOtherNode(symbol.preParent)
                end)

                animTime = util_max(animTime, symbol:getAniamDurationByName(symbol:getLineAnimName()))
            end 
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local randIndex = math.floor(1,2)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_GoldMarmot_scatter_trigger_fs_"..randIndex])
    else
        local randIndex = math.floor(1,2)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_GoldMarmot_scatter_trigger_"..randIndex])
    end

    

    self:delayCallBack(animTime,function()
        callFun()
    end)
end

-- FreeSpinstart
function CodeGameScreenGoldMarmotMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("GoldMarmotSounds/music_GoldMarmot_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_show_fs_more)
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_show_fs_start)
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_change_scene_base_to_free)
                self:changeScene_free(function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()     
                    
                end)
                self:delayCallBack(1,function()
                    self:changeBgAni("freespin") 
                    self.m_base_reel_bg:setVisible(false)
                    self.m_free_reel_bg:setVisible(true)
                end)
            end)
            view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_GoldMarmot_clickBtn
            view:setBtnClickFunc(function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_fs_start_over)
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    self:delayCallBack(0.5,function()
        showFSView()    
    end)
end

function CodeGameScreenGoldMarmotMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end
end

function CodeGameScreenGoldMarmotMachine:showFreeSpinOverView()
    self:clearCurMusicBg()
    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldMarmot_fs_over_short_music)
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()

        self:changeBgAni("base")
        self.m_base_reel_bg:setVisible(true)
        self.m_free_reel_bg:setVisible(false)
    end)
    
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_GoldMarmot_clickBtn

end

function CodeGameScreenGoldMarmotMachine:showFreeSpinOver(coins, num, func)
    if globalData.slotRunData.lastWinCoin > 0 then
        local ownerlist = {}
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
        local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.6,sy=0.6},1390)
        return view
    else
        return self:showDialog("FreeSpinOver_NoWins",nil,func)
    end
    
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenGoldMarmotMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )

    self.m_isNotice = false
    self.m_isPlayNotice = true

    return false -- 用作延时点击spin调用
end


--[[
    检测是否需要合并为大wild的列
]]
function CodeGameScreenGoldMarmotMachine:checkNeedChangeWildCols()
    local reelData = self.m_runSpinResultData.p_reels
    local changeCols = {}
    for iCol = 1,self.m_iReelColumnNum do
        local count = 0
        for iRow = 1,self.m_iReelRowNum do
            if reelData[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                count = count + 1
            end
        end
        if count == self.m_iReelRowNum then
            --检测是否参与连线
            local winLines = self.m_runSpinResultData.p_winLines
            if #winLines > 0 then
                for index = 1,#winLines do
                    local lineData = winLines[index]
                    local iconPos = lineData.p_iconPos
                    --该列是否参与连线
                    local isInWinLines = false
                    for k,v in pairs(iconPos) do
                        local pos = self:getRowAndColByPos(v)
                        if pos.iY == iCol then
                            changeCols[iCol] = true
                            isInWinLines = true
                            break
                        end
                    end
                    --已确定参与连线,后面不用算了
                    if isInWinLines then
                        break
                    end
                end
            end
        end
    end
    return changeCols
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenGoldMarmotMachine:addSelfEffect()
    self.m_changeCols = {}
    local changeCols = self:checkNeedChangeWildCols()
    for k,isBig in pairs(changeCols) do
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.CHANGE_TO_BIG_WILD
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.CHANGE_TO_BIG_WILD -- 动画类型
        self.m_changeCols = changeCols
        break
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenGoldMarmotMachine:MachineRule_playSelfEffect(effectData)

    --整列wild图标转化动画
    if effectData.p_selfEffectType == self.CHANGE_TO_BIG_WILD then
        self:changeToBigWild(self.m_changeCols,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    
    return true
end

--[[
    整列wild图标转化动画
]]
function CodeGameScreenGoldMarmotMachine:changeToBigWild(changeCols,func)
    for col,isBig in pairs(changeCols) do
        local symbolNode = self:getFixSymbol(col,1)
        if symbolNode then
            --放到大信号层
            symbolNode:changeParentToTopNode()
            symbolNode.p_symbolType = self.SYMBOL_SCORE_WILD_BIG
            symbolNode:runAnim("switch",false,function()
                for iRow = 2,self.m_iReelRowNum do
                    local symbol = self:getFixSymbol(col,iRow)
                    symbol:setVisible(false)
                end
            end)
        end
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_change_to_big_wild)

    self:delayCallBack(30 / 30,function()
        if type(func) == "function" then
            func()
        end
    end)
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenGoldMarmotMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenGoldMarmotMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenGoldMarmotMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenGoldMarmotMachine:slotReelDown( )



    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
           local symbol = self:getFixSymbol(iCol,iRow)
           if symbol and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbol:runAnim("idleframe")
            end 
        end
    end


    CodeGameScreenGoldMarmotMachine.super.slotReelDown(self)
end

function CodeGameScreenGoldMarmotMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

---
--设置bonus scatter 层级
function CodeGameScreenGoldMarmotMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_SCORE_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_SCORE_WILD_BIG then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_EMPTY then
        return REEL_SYMBOL_ORDER.REEL_ORDER_1
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order

end

--新滚动使用
function CodeGameScreenGoldMarmotMachine:updateReelGridNode(symbolNode)
    if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
        self:setSpecialNodeScore(symbolNode)
    elseif symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_WILD_BIG then
        symbolNode:runAnim("idleframe2")
    end
end

function CodeGameScreenGoldMarmotMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end
    local score = 0

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        score = self:getBonusSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）

    else
        score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score == nil then
                score = 1
            end
        end
    end

    if symbolNode and symbolNode.p_symbolType then
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet

        symbolNode.m_score = score

        score = util_formatCoins(score, 3)
        symbolNode:getCcbProperty("BitmapFontLabel_1"):setString(score)
        

        local node = symbolNode:getCcbProperty("node_spine")
        if node then
            local spine = node:getChildByTag(TAG_BONUS_SPINE)
            if not spine then
                spine = util_spineCreate("Socre_GoldMarmot_Bonus",true,true)
                node:addChild(spine)
                spine:setTag(TAG_BONUS_SPINE)
            end

            if self:getGameSpinStage( ) > IDLE then
                util_spinePlay(spine,"tuowei",true)
            else
                util_spinePlay(spine,"idleframe",true)
            end

            
        end
    end

    symbolNode:runAnim("idleframe")
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenGoldMarmotMachine:getBonusSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = 0

    if not storedIcons then
        return self:randomDownRespinSymbolScore(self.SYMBOL_SCORE_BONUS)
    end

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            return score
        end
    end
    return score
end

function CodeGameScreenGoldMarmotMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_SCORE_BONUS then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getBnBasePro()
    end


    return score
end

function CodeGameScreenGoldMarmotMachine:reelSchedulerCheckColumnReelDown(parentData, parentY, slotParent, halfH)
    local timeDown = 0
    --
    --停止reel
    if math.abs(parentY - parentData.moveDistance) < 0.1 then -- 浮点数精度问题
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

            -- --播放配置信号的落地音效
            -- self:playSymbolBulingSound(nodes)
            -- -- 播放配置信号的落地动效
            -- self:playSymbolBulingAnim(nodes, speedActionTable)

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
                    slotNode:runAnim("buling",false,function()
                        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and self.m_isLongRun then
                            slotNode:runAnim("idleframe2",true)
                        end
                    end)
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

-- 有特殊需求判断的 重写一下
function CodeGameScreenGoldMarmotMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                return true
            elseif _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then
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
function CodeGameScreenGoldMarmotMachine:playSymbolBulingAnim(slotNodeList)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            --播了落地的才提层
            if self:checkSymbolBulingAnimPlay(_slotNode) then

                -- 是否是最终信号
                local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
                if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                    --1.提层-不论播不播落地动画先处理提层
                    if symbolCfg[1] then
                        local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                        util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                        _slotNode:setPositionY(curPos.y)

                        self.m_bulingNodes[#self.m_bulingNodes + 1] = _slotNode

                        --连线坐标
                        local linePos = {}
                        linePos[#linePos + 1] = {iX = _slotNode.p_rowIndex, iY = _slotNode.p_cloumnIndex}
                        _slotNode.m_bInLine = true
                        _slotNode:setLinePos(linePos)
                    end
                end


                if _slotNode.p_symbolType and _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    if not self.m_bonus_down[_slotNode.p_cloumnIndex] then
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_bonus_down)
                    end
                    self.m_bonus_down[_slotNode.p_cloumnIndex] = true
                    local node = _slotNode:getCcbProperty("node_spine")
                    if node then
                        local spine = node:getChildByTag(TAG_BONUS_SPINE)
                        if spine then
                            util_spinePlay(spine,"buling")
                            util_spineEndCallFunc(spine,"buling",function()
                                util_spinePlay(spine,"idleframe",true)
                            end)
                        end
                    end
                else
                    if not self.m_scatter_down[_slotNode.p_cloumnIndex] then
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_scatter_down)
                    end
                    self.m_scatter_down[_slotNode.p_cloumnIndex] = true
                    --2.播落地动画
                    _slotNode:runAnim(
                        symbolCfg[2],
                        false,
                        function()
                            self:symbolBulingEndCallBack(_slotNode)
                            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and self.m_isLongRun then
                                _slotNode:runAnim("idleframe2",true)
                            end
                        end
                    )
                end

                if self.m_bClickQuickStop then
                    for index = 1,self.m_iReelColumnNum do
                        self.m_scatter_down[index] = true
                        self.m_bonus_down[index] = true
                    end
                end
                
            end
        end
    end
end

--[[
    延迟回调
]]
function CodeGameScreenGoldMarmotMachine:delayCallBack(time, func)
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

function CodeGameScreenGoldMarmotMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
    if startIndex == nil then
        startIndex = 1
    end
    if endIndex == nil then
        endIndex = #winLines
    end

    if bChangeToMask == nil then
        bChangeToMask = true
    end

    local function checkAddLineSlotNode(slotNode)
        if slotNode ~= nil then
            local isHasNode = false
            for checkIndex = 1, #self.m_lineSlotNodes do
                local checkNode = self.m_lineSlotNodes[checkIndex]
                if checkNode == slotNode then
                    isHasNode = true
                    break
                end
            end
            if isHasNode == false then
                if bChangeToMask == false then
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode
                else
                    self:changeToMaskLayerSlotNode(slotNode)
                end
            end
        end
    end

    -- 获取所有参与连线的SlotsNode 节点
    for lineIndex = startIndex, endIndex do
        local lineValue = winLines[lineIndex]

        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN and lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_BONUS then
            if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] == nil then
                self.m_eachLineSlotNode[lineIndex] = {}
            end
            local frameNum = lineValue.iLineSymbolNum
            for i = 1, frameNum do
                -- 播放slot node 的动画
                local symPosData = lineValue.vecValidMatrixSymPos[i]

                local slotNode = nil
                local parentData = self.m_slotParents[symPosData.iY]
                local slotParent = parentData.slotParent
                local slotParentBig = parentData.slotParentBig
                if self.m_changeCols[symPosData.iY] ~= nil then
                    slotNode = self:getFixSymbol(symPosData.iY,1)
                else
                    slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    if slotNode == nil and slotParentBig then
                        slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    end
                end

                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    slotNode = sepcicalNode
                end

                checkAddLineSlotNode(slotNode)

                -- 存每一条线
                symPosData = lineValue.vecValidMatrixSymPos[i]
                if self.m_changeCols[symPosData.iY] ~= nil then
                    slotNode = self:getFixSymbol(symPosData.iY,1)
                else
                    slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                end
                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    slotNode = sepcicalNode
                end
                if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                    self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = slotNode
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end

    -- 添加特殊格子。 只适用于覆盖类的长条，例如小财神， 白虎乌鸦人等 ..
    local specialChilds = self:getAllSpecialNode()
    for specialIndex = 1, #specialChilds do
        local specialNode = specialChilds[specialIndex]
        checkAddLineSlotNode(specialNode)
    end
end

function CodeGameScreenGoldMarmotMachine:showEachLineSlotNodeLineAnim(_frameIndex)
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode then
                    if self.m_changeCols[slotsNode.p_cloumnIndex] and slotsNode.p_rowIndex == 1 then
                        slotsNode:runAnim("actionframe2")
                    else
                        slotsNode:runLineAnim()
                    end
                    
                end
            end
        end
    end
end

function CodeGameScreenGoldMarmotMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent(false)
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    self.m_clipParent:addChild(slotNode, self:getSlotNodeEffectZOrder(slotNode))
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        if self.m_changeCols[slotNode.p_cloumnIndex] and slotNode.p_rowIndex == 1 then
            slotNode:runAnim("actionframe2")
        else
            slotNode:runLineAnim()
        end
    end
    return slotNode
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenGoldMarmotMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if self.m_changeCols[slotsNode.p_cloumnIndex] then
                slotsNode:runAnim("actionframe2")
            else
                slotsNode:runLineAnim()
            end
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenGoldMarmotMachine:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if self.m_changeCols[slotsNode.p_cloumnIndex] and slotsNode.p_rowIndex == 1 then
                slotsNode:runAnim("idleframe2")
            else
                slotsNode:runIdleAnim()
            end
            
        end
    end
end

function CodeGameScreenGoldMarmotMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                lineNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                util_changeNodeParent(preParent, lineNode, nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                
                if self.m_changeCols[lineNode.p_cloumnIndex] and lineNode.p_rowIndex == 1 then
                    lineNode:runAnim("idleframe2")
                else
                    lineNode:runIdleAnim()
                end
                
            end
        end
    end
end

function CodeGameScreenGoldMarmotMachine:getBottomUINode()
    return "CodeGoldMarmotSrc.GoldMarmotBottomNode"
end

----
--- 处理spin 成功消息
--
function CodeGameScreenGoldMarmotMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
        local params = {}
        params.rewaedFSData = self.m_rewaedFSData
        params.states = "spinResult"
        gLobalNoticManager:postNotification(ViewEventType.REWARD_FREE_SPIN_CHANGE_TIME, params)
    end
    if spinData.action == "SPIN" then

        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)

        gLobalNoticManager:postNotification("TopNode_updateRate")

        -- 出现预告动画概率30%
        self.m_isNotice = (math.random(1, 100) <= 30) 
        local features = self.m_runSpinResultData.p_features or {}
        if #features >= 2 and features[2] > 0 then
            if self.m_isNotice then
                self:playNoticeAni()
                self:delayCallBack(1,function()
                    self:updateNetWorkData()
                end)
            else
                self:updateNetWorkData()
            end
        else
            self:updateNetWorkData()
        end

        
    end
end

--[[
    预告中奖
]]
function CodeGameScreenGoldMarmotMachine:playNoticeAni(func)
    self:runCsbAction("zhen",true)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GoldMarmot_notice_win)
    
    local spine = util_spineCreate("GoldMarmot_GC2",true,true)
    util_spinePlay(spine,"yugao")
    util_spineEndCallFunc(spine,"yugao",function()
        spine:setVisible(false)
        self:delayCallBack(0.5,function()
            spine:removeFromParent()
        end)

        self:runCsbAction("idleframe",true)

        if type(func) == "function" then
            func()
        end
    end)

    self:findChild("tuboshu"):addChild(spine)
end

--设置bonus scatter 信息
function CodeGameScreenGoldMarmotMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效
                    
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else 
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
        
    end

    if not self.m_isNotice and bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

function CodeGameScreenGoldMarmotMachine:spinBtnEnProc()
    self.m_isLongRun = false
    --scatter和bonus图标放回原层级
    local slotsParents = self.m_slotParents
    for key,symbol in pairs(self.m_topNodes) do
        if symbol then
            local parentData = slotsParents[symbol.p_cloumnIndex]
            local pos = util_convertToNodeSpace(symbol,parentData.slotParent) --util_getOneGameReelsTarSpPos(self,self:getPosReelIdx(symbol.p_rowIndex,symbol.p_cloumnIndex))
            util_changeNodeParent(parentData.slotParent,symbol,self:getBounsScatterDataZorder(symbol.p_symbolType) - symbol.p_rowIndex)
            symbol:changeParentToOtherNode(parentData.slotParent)
            symbol:setPosition(pos)
        end
    end

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_scatter_down = {}
    self.m_bonus_down = {}

    self.m_topNodes = {}
    self.m_bulingNodes = {}
    CodeGameScreenGoldMarmotMachine.super.spinBtnEnProc(self)
end

function CodeGameScreenGoldMarmotMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 13

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
    

    mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)

    local ratio = display.height / display.width
    local winSize = cc.Director:getInstance():getWinSize()
    if ratio >= 768 / 1024 then
        mainScale = 0.74
    elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
        mainScale = 0.84
        mainPosY = mainPosY - 12
    elseif ratio < 640 / 960 and ratio >= 768 / 1230 then
        mainScale = 0.88
        mainPosY = mainPosY - 5
    elseif ratio < 768 / 1230 and ratio > 768 / 1370 then
        mainScale = 0.88
    else
        mainScale = 1
        mainPosY = mainPosY - 5
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

function CodeGameScreenGoldMarmotMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = CodeGameScreenGoldMarmotMachine.super.setReelLongRun(self,reelCol)
    
    if not self.m_isLongRun and isTriggerLongRun then
        --scatter播期待动画
        for iCol = 1,reelCol do
            for iRow = 1,self.m_iReelRowNum do
               local symbol = self:getFixSymbol(iCol,iRow)
               if symbol and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    symbol:runAnim("idleframe2",true)
                end 
            end
        end
        self.m_isLongRun = isTriggerLongRun
    end

    

    return isTriggerLongRun
end

return CodeGameScreenGoldMarmotMachine






