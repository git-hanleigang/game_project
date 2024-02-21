---
-- island li
-- 2019年1月26日
-- CodeGameScreenFortuneGodMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenFortuneGodMachine = class("CodeGameScreenFortuneGodMachine", BaseNewReelMachine)

CodeGameScreenFortuneGodMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenFortuneGodMachine.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12         --105
CodeGameScreenFortuneGodMachine.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11         --104
CodeGameScreenFortuneGodMachine.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10         --103
CodeGameScreenFortuneGodMachine.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9           --102
CodeGameScreenFortuneGodMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1         --94
CodeGameScreenFortuneGodMachine.SYMBOL_RS_SCORE_BLANK = 100
CodeGameScreenFortuneGodMachine.RUN_RAMDOM_SYMBOL = 98
CodeGameScreenFortuneGodMachine.WILD2 = 111
CodeGameScreenFortuneGodMachine.WILD3 = 112
CodeGameScreenFortuneGodMachine.WILD5 = 113
CodeGameScreenFortuneGodMachine.WILD8 = 114
CodeGameScreenFortuneGodMachine.WILD10 = 115
CodeGameScreenFortuneGodMachine.WILD25 = 116
CodeGameScreenFortuneGodMachine.WILD100 = 117

CodeGameScreenFortuneGodMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 51
CodeGameScreenFortuneGodMachine.BONUS_GAME_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 50 -- 集满bonus

CodeGameScreenFortuneGodMachine.m_chipList = nil
CodeGameScreenFortuneGodMachine.m_playAnimIndex = 0
CodeGameScreenFortuneGodMachine.m_lightScore = 0

CodeGameScreenFortuneGodMachine.BASE_FS_RUN_STATES = 0
CodeGameScreenFortuneGodMachine.COllECT_FS_RUN_STATES1 = 1
CodeGameScreenFortuneGodMachine.COllECT_FS_RUN_STATES2 = 2
CodeGameScreenFortuneGodMachine.COllECT_FS_RUN_STATES3 = 3
CodeGameScreenFortuneGodMachine.COllECT_FS_RUN_STATES4 = 4

CodeGameScreenFortuneGodMachine.BONUS_RUN_NUM = 4
CodeGameScreenFortuneGodMachine.LONGRUN_COL_ADD_BONUS = 5
CodeGameScreenFortuneGodMachine.m_spReelRunAnima = nil

local selectRespinId = 0
local selectFreeSpinId = 1

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

local POSLIST = {15,16,17,18,19}    --底部绝对位置

local UPINDEX = {0,1,2,3,4}         --顶部绝对位置

local BIG_LEVEL = {
    ONE_LEVEL = 2,
    TWO_LEVEL = 7,
    THREE_LEVEL = 13,
    FOUR_LEVEL = 20
}

-- 构造函数
function CodeGameScreenFortuneGodMachine:ctor()
    CodeGameScreenFortuneGodMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_bSlotRunning = nil
    self.m_collectList = {}     
    self.m_bonusData = {}
    self.m_chooseRepin = false
    self.m_respinChipList = nil     --储存respin最后收集列表
    self.m_respinChipList2 = nil    --储存respin结算的红条底板
    self.m_respinChipList3 = nil    --储存临时隐藏的respin小块
    self.m_respinChipList4 = nil     --储存respin最后收集布上的圆框
    self.m_isTrigerRespinRun = false
    self.m_isScLongRun = false
    self.isInBonus = false
    self.respinRunEffectList = {}
    -- self.respinRunEffectList2 = {}
    self.m_respinFireList = {}      --储存respin结算火花
    self.m_isChooseRespin = false
    self.isRespinOver = false
    self.m_linkNearEnd = {}

    self.isClickMap = true

    self.m_isBonusTrigger = false
    -- 
	--init
	self:initGame()
end

function CodeGameScreenFortuneGodMachine:initGame()
    
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FortuneGodConfig.csv", "LevelFortuneGodConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  



function CodeGameScreenFortuneGodMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    -- self:initFreeSpinBar() -- FreeSpinbar
    self.freeSpinBar = util_createView("CodeFortuneGodSrc.FortuneGodFreespinBarView","free")
    self:findChild("Node_freeandrespinwenzi"):addChild(self.freeSpinBar)
    self.freeSpinBar:setVisible(false)

    self.reSpinBar = util_createView("CodeFortuneGodSrc.FortuneGodFreespinBarView","link")
    -- local respinPos = util_convertToNodeSpace(self:findChild("Node_freeandrespinwenzi"),self)
    --,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 4
    self:findChild("Node_freeandrespinwenzi"):addChild(self.reSpinBar)
    -- self.reSpinBar:setPosition(respinPos)
    -- self.reSpinBar:setScale(self.m_machineRootScale)
    self.reSpinBar:setVisible(false)

    --进度条
    self.m_progress = util_createView("CodeFortuneGodSrc.FortuneGodBonusProgressView")
    self:findChild("Node_jindutiao"):addChild(self.m_progress )

    --respin挂
    self.respinGuaDian = util_createAnimation("FortuneGod_respinbonusguadian.csb")
    --
    self.m_clipParent:addChild(self.respinGuaDian,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 10)
    local gua_bar = self:findChild("Node_respinbonusguadian")
    local guaPos = util_convertToNodeSpace(gua_bar,self.m_clipParent)
    self.respinGuaDian:setPosition(guaPos)
    -- self.respinGuaDian:setScale(self.m_machineRootScale)
    self.respinGuaDian:setVisible(false)

    self.m_jackpotView = util_createView("CodeFortuneGodSrc.FortuneGodJackPotBarView")
    self:findChild("Node_jackpot"):addChild(self.m_jackpotView)
    self.m_jackpotView:initMachine(self)

    --进度条左右部分
    self.rightNode = cc.Node:create()
    self:addChild(self.rightNode)

    self.leftNode = cc.Node:create()
    self:addChild(self.leftNode)

    self.shoujiNode = cc.Node:create()
    self:addChild(self.shoujiNode)

    self.left = util_spineCreate("FortuneGod_Jindutiaobianpao",true,true)
    self.right = util_spineCreate("FortuneGod_Jindutiao",true,true)
    local left_bar = self.m_progress:findChild("FortuneGod__bace_bianpao_4")
    local leftPos = util_convertToNodeSpace(left_bar,self.m_clipParent)
    self.m_clipParent:addChild(self.left,REEL_SYMBOL_ORDER.REEL_ORDER_2 + 1)
    self.left:setPosition(leftPos)
    -- self.left:setScale(self.m_machineRootScale)
    self:progressLeftIdle()

    self.baoDian = util_spineCreate("Socre_FortuneGod_Tongyongbaodian",true,true)
    local leftPos_bao = util_convertToNodeSpace(left_bar,self)
    self:addChild(self.baoDian,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    self.baoDian:setPosition(leftPos_bao)
    self.baoDian:setScale(self.m_machineRootScale)

    
    local right_bar = self.m_progress:findChild("FortuneGod__bace_hongbao_3")
    local rightPos = util_convertToNodeSpace(right_bar,self.m_clipParent)
    self.m_clipParent:addChild(self.right,REEL_SYMBOL_ORDER.REEL_ORDER_2 + 1)
    self.right:setPosition(rightPos)
    -- self.right:setScale(self.m_machineRootScale)
    -- self:findChild("FortuneGod__bace_hongbao_3"):addChild(self.right)
    self:progressRightIdle()

    --tips
    self.collectTipView = util_createAnimation("FortuneGod_tips.csb")     
    self:findChild("Node_tips"):addChild(self.collectTipView,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.collectTipView.m_states = nil
    self.collectTipView:setVisible(false)

    self.tipsWaitNode = cc.Node:create()
    self:addChild(self.tipsWaitNode)

    --特效层(用来放respin快滚框)
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 20)

    self.m_spineTanbanParent = cc.Node:create()
    self.m_spineTanbanParent:setOpacity(0)
    self:addChild(self.m_spineTanbanParent, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_spineTanbanParent:setPosition(display.center)


    self.bg = util_spineCreate("FortuneGod_bg_1",true,true)
    self:findChild("bg_2"):addChild(self.bg,2)
    util_spinePlay(self.bg,"idle",true)


    self.dark = util_createView("CodeFortuneGodSrc.FortuneGodDarkView")
    self.m_spineTanbanParent:addChild(self.dark,100)
    self.dark:setVisible(false)

    self.respinDark = util_createAnimation("FortuneGod_qipanyaan.csb")
    local respinDarkPos = util_convertToNodeSpace(self:findChild("Node_qipanyaan"),self.m_clipParent)
    self.m_clipParent:addChild(self.respinDark,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE)
    self.respinDark:setPosition(respinDarkPos)
    self.respinDark:setVisible(false)

    local BottomNode_bar = self.m_bottomUI:findChild("font_last_win_value")
    self.m_jiesuanAct = util_spineCreate("Socre_FortuneGod_Tongyongbaodian",true,true)
    local bottomNodePos = util_convertToNodeSpace(BottomNode_bar,self)
    self:addChild(self.m_jiesuanAct,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
    self.m_jiesuanAct:setPosition(bottomNodePos)
    self.m_jiesuanAct:setVisible(false)

    --隐藏respin底
    self:findChild("respin_bottom"):setVisible(false)

    self:createLinkRunShow()
    self:createRespinBao()

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 4
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end
        local soundName = nil
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "FortuneGodSounds/music_FortuneGod_free_win_".. soundIndex .. ".mp3"
        else
            soundName = "FortuneGodSounds/music_FortuneGod_last_win_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            self.m_winSoundsId = nil
        end)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenFortuneGodMachine:progressLeftIdle( )
    self.leftNode:stopAllActions()
    util_spinePlay(self.left,"idleframe",false)
    util_spineEndCallFunc(self.left,"idleframe",function (  )
        util_spinePlay(self.left,"idleframe2",true)
    end)
    performWithDelay(self.leftNode,function (  )
        self:progressLeftIdle()
    end,3)

end

function CodeGameScreenFortuneGodMachine:changeProgressParent(isChange)
    if isChange then
        local left_bar = self.m_progress:findChild("FortuneGod__bace_bianpao_4")
        local leftPos = util_convertToNodeSpace(left_bar,self)
        util_changeNodeParent(self,self.left,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
        self.left:setPosition(leftPos)
        self.left:setScale(self.m_machineRootScale)
        self:progressLeftIdle()

        local right_bar = self.m_progress:findChild("FortuneGod__bace_hongbao_3")
        local rightPos = util_convertToNodeSpace(right_bar,self)
        util_changeNodeParent(self,self.right,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
        self.right:setPosition(rightPos)
        self.right:setScale(self.m_machineRootScale)
        self:progressRightIdle()
    else
        local left_bar = self.m_progress:findChild("FortuneGod__bace_bianpao_4")
        local leftPos = util_convertToNodeSpace(left_bar,self.m_clipParent)
        util_changeNodeParent(self.m_clipParent,self.left,REEL_SYMBOL_ORDER.REEL_ORDER_2 + 1)
        self.left:setPosition(leftPos)
        self.left:setScale(1)
        self:progressLeftIdle()

        local right_bar = self.m_progress:findChild("FortuneGod__bace_hongbao_3")
        local rightPos = util_convertToNodeSpace(right_bar,self.m_clipParent)
        util_changeNodeParent(self.m_clipParent,self.right,REEL_SYMBOL_ORDER.REEL_ORDER_2 + 1)
        self.right:setPosition(rightPos)
        self.right:setScale(1)
        self:progressRightIdle()
    end
end

function CodeGameScreenFortuneGodMachine:changeRespinBarZorder(isChange)
    if isChange then
        local respinPos = util_convertToNodeSpace(self:findChild("Node_freeandrespinwenzi"),self)
        util_changeNodeParent(self,self.reSpinBar,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 4)
        self.reSpinBar:setPosition(respinPos)
        self.reSpinBar:setScale(self.m_machineRootScale)
    else
        util_changeNodeParent(self:findChild("Node_freeandrespinwenzi"),self.reSpinBar)
        self.reSpinBar:setPosition(cc.p(0,0))
        self.reSpinBar:setVisible(false)
    end
    
end

function CodeGameScreenFortuneGodMachine:showCollectEffect( )
    self.shoujiNode:stopAllActions()
    self.leftNode:stopAllActions()
    util_spinePlay(self.left,"shouji",false)
    util_spinePlay(self.baoDian,"actionframe",false)
    performWithDelay(self.shoujiNode,function (  )
        self:progressLeftIdle()
    end,42/30)
end

function CodeGameScreenFortuneGodMachine:progressRightIdle( )
    self.rightNode:stopAllActions()
    util_spinePlay(self.right,"idleframe",false)
    util_spineEndCallFunc(self.right,"idleframe",function (  )
        util_spinePlay(self.right,"idleframe2",true)
    end)
    performWithDelay(self.rightNode,function (  )
        self:progressRightIdle()
    end,3)
end

function CodeGameScreenFortuneGodMachine:showJiMan()
    self.rightNode:stopAllActions()
    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_collect_Man.mp3")
    util_spinePlay(self.right,"actionframe2",false)
    performWithDelay(self,function (  )
        self:progressRightIdle()
    end,2)
end

-- 断线重连 
function CodeGameScreenFortuneGodMachine:MachineRule_initGame(  )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeType = selfData.freeType
    local collectPos = selfData.collectPos
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.isInBonus = true
        self:freeSpinShow()
        if freeType and freeType == "COLLECT" then
            --
            self.m_fsReelDataIndex = self:getcollectFsStates(collectPos)
            self.m_bottomUI:showAverageBet()
        end
    end
    if self:getCurrSpinMode() == RESPIN_MODE then
        self.isInBonus = true
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFortuneGodMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "FortuneGod"  
end

-- 继承底层respinView
function CodeGameScreenFortuneGodMachine:getRespinView()
    return "CodeFortuneGodSrc.FortuneGodRespinView"
end
-- 继承底层respinNode
function CodeGameScreenFortuneGodMachine:getRespinNode()
    return "CodeFortuneGodSrc.FortuneGodRespinNode"
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFortuneGodMachine:MachineRule_GetSelfCCBName(symbolType)
    
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_FIX_SYMBOL  then
        return "Socre_FortuneGod_Bonus"
    elseif symbolType == self.SYMBOL_FIX_GRAND then
        return "Socre_FortuneGod_Bonus"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_FortuneGod_Bonus"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_FortuneGod_Bonus"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_FortuneGod_Bonus"
    elseif symbolType == self.RUN_RAMDOM_SYMBOL then
        return "Socre_FortuneGod_Bonus"
    elseif symbolType == self.SYMBOL_RS_SCORE_BLANK then
        return "Socre_FortuneGod_Blanck"
    elseif symbolType == self.WILD2 then        --小块文件相同，皮肤不同
        return "Socre_FortuneGod_Wild"
    elseif symbolType == self.WILD3 then
        return "Socre_FortuneGod_Wild"
    elseif symbolType == self.WILD5 then
        return "Socre_FortuneGod_Wild"
    elseif symbolType == self.WILD8 then
        return "Socre_FortuneGod_Wild"
    elseif symbolType == self.WILD10 then
        return "Socre_FortuneGod_Wild"
    elseif symbolType == self.WILD25 then
        return "Socre_FortuneGod_Wild"
    elseif symbolType == self.WILD100 then
        return "Socre_FortuneGod_Wild"
    end
    
    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenFortuneGodMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
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

    return score
end

function CodeGameScreenFortuneGodMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

-- 给respin小块进行赋值
function CodeGameScreenFortuneGodMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
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


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode then
                local symbol_node = symbolNode:checkLoadCCbNode()
                local spineNode = symbol_node:getCsbAct()
                if spineNode.m_csbNode then
                    local lbs = spineNode.m_csbNode:findChild("m_lb_coins")
                    if lbs and lbs.setString  then
                        lbs:setString(score)
                    end
                end
            end
        end

        symbolNode:runAnim("idleframe")

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
                if symbolNode  then
                    local symbol_node = symbolNode:checkLoadCCbNode()
                    local spineNode = symbol_node:getCsbAct()
                    if spineNode.m_csbNode then
                        local lbs = spineNode.m_csbNode:findChild("m_lb_coins")
                        if lbs and lbs.setString  then
                            lbs:setString(score)
                        end
                    end
                end
                
                symbolNode:runAnim("idleframe")
            end
        end
        
        
    end

end

function CodeGameScreenFortuneGodMachine:randomChangeTempNode(node,nodeType)
    if nodeType == self.SYMBOL_FIX_GRAND then
        node:changeCCBByName(self:getSymbolCCBNameByType(self,self.SYMBOL_FIX_GRAND ), self.SYMBOL_FIX_GRAND)
    elseif nodeType == self.SYMBOL_FIX_MAJOR then
        node:changeCCBByName(self:getSymbolCCBNameByType(self,self.SYMBOL_FIX_MAJOR ), self.SYMBOL_FIX_MAJOR)
    elseif nodeType == self.SYMBOL_FIX_MINOR then
        node:changeCCBByName(self:getSymbolCCBNameByType(self,self.SYMBOL_FIX_MINOR ), self.SYMBOL_FIX_MINOR)
    elseif nodeType == self.SYMBOL_FIX_MINI then
        node:changeCCBByName(self:getSymbolCCBNameByType(self,self.SYMBOL_FIX_MINI ), self.SYMBOL_FIX_MINI)
    end
    self:addLevelBonusSpine(node)
end



function CodeGameScreenFortuneGodMachine:addLevelBonusSpine(_symbol)
    
    local cocosName = "Socre_FortuneGod_Bonus_1.csb"
    -- if _symbol.p_symbolType == self.SYMBOL_FIX_SYMBOL then
    --     cocosName = "Socre_FortuneGod_Bonus_0.csb"
    -- end
    local symbol_node = _symbol:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local coinsView
    if not spineNode.m_csbNode then
        coinsView = util_createAnimation(cocosName)
        util_spinePushBindNode(spineNode,"kong",coinsView)
        spineNode.m_csbNode = coinsView
    else
        coinsView = spineNode.m_csbNode
    end

    if _symbol.p_symbolType == self.SYMBOL_FIX_SYMBOL then
        coinsView:findChild("m_lb_coins"):setString("")
        coinsView:findChild("m_lb_coins"):setVisible(true)
        coinsView:findChild("Node_jackpot"):setVisible(false)
    else
        coinsView:findChild("m_lb_coins"):setVisible(false)
        coinsView:findChild("Node_jackpot"):setVisible(true)
        if _symbol.p_symbolType == self.SYMBOL_FIX_GRAND then
            coinsView:findChild("FortuneGod_tubiao_grand_5"):setVisible(true)
            coinsView:findChild("FortuneGod_tubiao_major_6"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_minor_8"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_mini_7"):setVisible(false)
        elseif _symbol.p_symbolType == self.SYMBOL_FIX_MAJOR then
            coinsView:findChild("FortuneGod_tubiao_grand_5"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_major_6"):setVisible(true)
            coinsView:findChild("FortuneGod_tubiao_minor_8"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_mini_7"):setVisible(false)
        elseif _symbol.p_symbolType == self.SYMBOL_FIX_MINOR then
            coinsView:findChild("FortuneGod_tubiao_grand_5"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_major_6"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_minor_8"):setVisible(true)
            coinsView:findChild("FortuneGod_tubiao_mini_7"):setVisible(false)
        elseif _symbol.p_symbolType == self.SYMBOL_FIX_MINI then
            coinsView:findChild("FortuneGod_tubiao_grand_5"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_major_6"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_minor_8"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_mini_7"):setVisible(true)
        end
    end
end

function CodeGameScreenFortuneGodMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    --显示钱的小块挂钱
    --显示jackpot的小块挂jackpot
    if self:isFixSymbol(symbolType) then
        self:addLevelBonusSpine(node)
        if symbolType == self.SYMBOL_FIX_SYMBOL then
            self:setSpecialNodeScore(self,{node})
        end
    end

    if symbolType == self.RUN_RAMDOM_SYMBOL then
        local tempType = self.m_configData:getFixSymbolPro2()
        self:randomChangeTempNode(node,tempType)
    end

    --收集大关
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE and node.p_cloumnIndex == 3 then
        if self:isShowWild(symbolType) then
            self:wildChangeTempNode(node,symbolType)
        else
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local wildmultiply = selfData.wildmultiply
            if wildmultiply then
                --根据倍数显示不同wild
                local skinName = self:getWildSkin(wildmultiply)
                self:wildChangeShow(node,skinName)
            end
        end
        
    end
end

function CodeGameScreenFortuneGodMachine:wildChangeTempNode(node,nodeType)
    local skinName = nil
    
    if nodeType == self.WILD2 then
        skinName = self:getWildSkin(2)
    elseif nodeType == self.WILD3 then
        skinName = self:getWildSkin(3)
    elseif nodeType == self.WILD5 then
        skinName = self:getWildSkin(5)
    elseif nodeType == self.WILD8 then
        skinName = self:getWildSkin(8)
    elseif nodeType == self.WILD10 then
        skinName = self:getWildSkin(10)
    elseif nodeType == self.WILD25 then
        skinName = self:getWildSkin(25)
    elseif nodeType == self.WILD100 then
        skinName = self:getWildSkin(100)
    end

    if skinName then
        self:wildChangeShow(node,skinName)
    end
end

function CodeGameScreenFortuneGodMachine:isShowWild(symbolType)
    if symbolType == self.WILD2 or
        symbolType == self.WILD3 or
            symbolType == self.WILD5 or
                symbolType == self.WILD8 or
                    symbolType == self.WILD10 or
                        symbolType == self.WILD25 or
                            symbolType == self.WILD100 then
        return true
    end
    return false
end

function CodeGameScreenFortuneGodMachine:wildChangeShow(node,skinName)
    if node.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD and self:isShowWild(node.p_symbolType) == false then
        return
    end
    local ccbNode = node:getCCBNode()
    if not ccbNode then
        node:checkLoadCCbNode()
    end
    ccbNode = node:getCCBNode()
    if ccbNode then
        ccbNode.m_spineNode:setSkin(skinName)
    end
    node:runAnim("idleframe2")
end


function CodeGameScreenFortuneGodMachine:getWildSkin(times)
    if times == 2 then
        return "2x"
    elseif times == 3 then
        return "3x"
    elseif times == 5 then
        return "5x"
    elseif times == 8 then
        return "8x"
    elseif times == 10 then
        return "10x"
    elseif times == 25 then
        return "25x"
    elseif times == 100 then
        return "100x"
    end
    return "x1"
end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFortuneGodMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenFortuneGodMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_GRAND,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MAJOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINI,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------


--
--单列滚动停止回调
--
function CodeGameScreenFortuneGodMachine:slotOneReelDown(reelCol)    
    CodeGameScreenFortuneGodMachine.super.slotOneReelDown(self,reelCol) 

    if reelCol == 5 then
        self.m_isTrigerRespinRun = false
        self.m_isScLongRun = false
    end
end



---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenFortuneGodMachine:levelFreeSpinEffectChange()

    util_spinePlay(self.bg,"change",false)
    self.m_gameBg:runCsbAction("change")
    self:delayCallBack(1,function (  )
        util_spinePlay(self.bg,"idle2",true)
    end)
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenFortuneGodMachine:levelFreeSpinOverChangeEffect()

    util_spinePlay(self.bg,"change2",false)
    self.m_gameBg:runCsbAction("change2")
    self:delayCallBack(1,function (  )
        util_spinePlay(self.bg,"idle",true)
    end)
end
---------------------------------------------------------------------------

function CodeGameScreenFortuneGodMachine:showFreeSpinUpView(func)
    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_free_replaced.mp3")
    local freeView = util_spineCreate("FortuneGod_freezi",true,true)
    self:findChild("Node_qipanyaan"):addChild(freeView,10)
    util_spinePlay(freeView,"idle",false)
    self:delayCallBack(3,function (  )
        freeView:removeFromParent()
        if func then
            func()
        end
    end)
end
-- 触发freespin时调用
function CodeGameScreenFortuneGodMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_custom_enter_fs.mp3")
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local collectOccur = selfData.collectOccur or false
            local freeType = selfData.freeType
            self.isInBonus = true
            
            if freeType and freeType == "COLLECT" then
                self.m_bottomUI:showAverageBet()
                self:showSuperFreeStart(self.m_mapNodePos,self.m_runSpinResultData.p_freeSpinsTotalCount,function (  )
                    self:freeSpinShow()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            else
                self:freeSpinShow()
                self:showFreeSpinUpView(function (  )
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect() 
                end)
                
            end
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

end

function CodeGameScreenFortuneGodMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    local dialogName = "freespinover"
    local ownerlist = {
        m_lb_coins = coins,
        m_lb_num = num
    }
    local skinName   = nil
    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_freeSpinOver.mp3")
    self:addSpineTanbanView(dialogName, ownerlist, func, skinName)
end

-- 触发freespin结束时调用
function CodeGameScreenFortuneGodMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_over_fs.mp3")
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = selfData.collectPos or 0
    local freeType = selfData.freeType
        
    local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins
    local strCoins=util_formatCoins(freeSpinWinCoin,50)
    if freeType and freeType == "COLLECT" then
        self:showSuperFreeOver(strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:clearSpineTanbanView(function (  )
                if self.m_mapNodePos == 20 then
                    self.m_mapNodePos = 0 -- 更新最新位置
                    self.m_map.curPos = 0
                -- else
                --     self.m_mapNodePos = currentPos -- 更新最新位置
                --     self.m_map.curPos = currentPos
                end
                self.m_fsReelDataIndex = self.BASE_FS_RUN_STATES
                self:freeSpinOverShow()
                self.isInBonus = false
                self.m_bottomUI:hideAverageBet()
                -- 调用此函数才是把当前游戏置为freespin结束状态
                self:triggerFreeSpinOverCallFun()
            end) 
        end)
    else
        self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:clearSpineTanbanView(function (  )
                self.m_fsReelDataIndex = self.BASE_FS_RUN_STATES
                self:freeSpinOverShow()
                self.isInBonus = false
                -- 调用此函数才是把当前游戏置为freespin结束状态
                self:triggerFreeSpinOverCallFun()
            end)  
        end)
    end
    
    
    -- local node=view:findChild("m_lb_coins")
    -- view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)

end

--************************respin相关
--接收到数据开始停止滚动
function CodeGameScreenFortuneGodMachine:stopRespinRun()
    CodeGameScreenFortuneGodMachine.super.stopRespinRun(self)
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        self.m_respinView.isHideKuang = true
    end
    
end

function CodeGameScreenFortuneGodMachine:isCurNodeForEndCol(col)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local endLie = rsExtraData.endLie or {}
    for i,v in ipairs(endLie) do
        if v + 1 == col then
            return true
        end
    end
    return false
end


-- 是不是 respinBonus小块
function CodeGameScreenFortuneGodMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or 
        symbolType == self.SYMBOL_FIX_MINI or 
        symbolType == self.SYMBOL_FIX_MINOR or 
        symbolType == self.SYMBOL_FIX_MAJOR or 
        symbolType == self.SYMBOL_FIX_GRAND then
        return true
    end
    return false
end

function CodeGameScreenFortuneGodMachine:showRespinJackpot(index,coins,func)
    self:delayCallBack(0.5,function (  )
        --播放音效
        if index == 1 then
            gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_jackpotView1.mp3")
        elseif index == 2 then
            gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_jackpotView2.mp3")
        elseif index == 3 then
            gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_jackpotView3.mp3")
        elseif index == 4 then
            gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_jackpotView4.mp3")
        end
        local jackPotWinView = util_createView("CodeFortuneGodSrc.FortuneGodJackPotWinView", self)
        gLobalViewManager:showUI(jackPotWinView)
        jackPotWinView:initViewData(index,coins,func)
    end)
    
end

-- 结束respin收集
function CodeGameScreenFortuneGodMachine:playLightEffectEnd()
    
    self:delayCallBack(0.8,function (  )
        -- 通知respin结束
        self.m_respinView:clearRespinKuang()
        local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
        local endLie = rsExtraData.endLie or {}
        for i,endCol in ipairs(endLie) do
            self:clearTempListDi(endCol)
        end
        self:respinOver()
    end)
    
end

function CodeGameScreenFortuneGodMachine:showWinJieSunaAct( )
    self.m_jiesuanAct:setVisible(true)
    util_spinePlay(self.m_jiesuanAct,"actionframe2",false)
end

function CodeGameScreenFortuneGodMachine:collectCoinsToDownUi(endCol,collectList,func)
    if self.collectIndex > #self.m_colCoins then
        if func then
            func()
        end
        return
    end
    local node = collectList[self.collectIndex]
    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local endPos = util_convertToNodeSpace(endNode,self)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if self.collectIndex == #self.m_colCoins then
            
            self.m_respinView:cleaRespinKuangForIndex(endCol + 1)
        end
        gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_link_collectFly.mp3")
    end)
    actList[#actList + 1]  = cc.MoveTo:create(15/30,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_link_collectFankui.mp3")
        self:showWinJieSunaAct()
    end)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        local coins = self.m_colCoins[self.collectIndex]
        if coins[2] == 0 then
            self:updateBottomUICoins(self.collectCoins,coins[1],true,true,true)
            self.collectCoins = self.collectCoins + coins[1]
            self.collectIndex = self.collectIndex + 1
            self:collectCoinsToDownUi(endCol,collectList,func)
        else
            self:updateBottomUICoins(self.collectCoins,coins[1],true,true,true)
            self.collectCoins = self.collectCoins + coins[1]
            self.collectIndex = self.collectIndex + 1
            self:showRespinJackpot(coins[2], coins[1], function()
                self:collectCoinsToDownUi(endCol,collectList,func)
            end)
        end
    end)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actList))
end

function CodeGameScreenFortuneGodMachine:playChipCollectAnim2(endCol,func)
    if self.m_playAnimIndex > #self.m_respinChipList[endCol] then
        self:delayCallBack(0.8,function (  )
            --收集到下ui self.m_colCoins
            self.collectIndex = 1
            
            self:collectCoinsToDownUi(endCol,self.m_respinChipList[endCol],func)
        end)
    else
        local chipNode = self.m_respinChipList[endCol][self.m_playAnimIndex]
        local nodeKuang = self.m_respinChipList4[endCol][self.m_playAnimIndex]

        local iCol = chipNode.p_cloumnIndex
        local iRow = chipNode.p_rowIndex            
        -- local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol 

        -- 根据网络数据获得当前固定小块的分数
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) 
        
        local addScore = 0
        local jackpotScore = 0
        local nJackpotType = 0

        local lineBet = globalData.slotRunData:getCurTotalBet()
        
        if chipNode.p_symbolType == self.SYMBOL_FIX_GRAND then
            addScore = self:BaseMania_getJackpotScore(1)
            jackpotScore = self:BaseMania_getJackpotScore(1)
            nJackpotType = 4
        elseif chipNode.p_symbolType == self.SYMBOL_FIX_MAJOR then
            addScore = self:BaseMania_getJackpotScore(2)
            jackpotScore = self:BaseMania_getJackpotScore(2)
            nJackpotType = 3
        elseif chipNode.p_symbolType == self.SYMBOL_FIX_MINOR then
            addScore = self:BaseMania_getJackpotScore(3)
            jackpotScore = self:BaseMania_getJackpotScore(3)
            nJackpotType = 2
        elseif chipNode.p_symbolType == self.SYMBOL_FIX_MINI then
            addScore = self:BaseMania_getJackpotScore(4)
            jackpotScore = self:BaseMania_getJackpotScore(4)
            nJackpotType = 1
        else
            addScore = score * lineBet
        end

        --将钱数存到表中
        self.m_colCoins[#self.m_colCoins + 1] = {addScore,nJackpotType}

        self.m_lightScore = self.m_lightScore + addScore

        local function runCollect()

                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim2(endCol,func) 

        end
        if self.m_playAnimIndex == 1 then
            gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_link_colBao.mp3")
        end
        util_spinePlay(chipNode,"actionframe2",false)
        nodeKuang:setVisible(true)
        nodeKuang:runCsbAction("start",false,function (  )
            nodeKuang:runCsbAction("idle")
        end)
        self:delayCallBack(33/30,function (  )
            --修改层级
            local leftPos = util_convertToNodeSpace(chipNode,self)
            util_changeNodeParent(self,chipNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
            chipNode:setPosition(leftPos)
            chipNode:setScale(self.m_machineRootScale)
            util_spinePlay(chipNode,"actionframe2_zi",false)
        end)
        self:delayCallBack(0.3,function (  )
            runCollect() 
        end)
        
    end
end

function CodeGameScreenFortuneGodMachine:playChipCollectAnim()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local endLie = rsExtraData.endLie or {}
    if self.m_playEndColIndex > #endLie then
        --隐藏长条底
        
        self:playLightEffectEnd()
        return
    end

    local endCol = endLie[self.m_playEndColIndex]
    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_link_collectTrigger.mp3")
    for i,v in ipairs(self.m_respinChipList[endCol]) do
        util_spinePlay(v,"actionframe3",false)
    end
    self.m_playAnimIndex = 1
    self.m_colCoins = {}
    self:delayCallBack(2,function (  )
        util_spinePlay(self.m_respinFireList[endCol + 1],"huohuaxiaoshi",false)
        self:delayCallBack(1/3,function (  )
            self.m_respinFireList[endCol + 1]:setVisible(false)
        end)
        self:playChipCollectAnim2(endCol,function (  )
            self.m_playEndColIndex = self.m_playEndColIndex + 1
            self:playChipCollectAnim()
        end)
    end)
    
end


function CodeGameScreenFortuneGodMachine:initRespinView(endTypes, randomTypes)
    self.moveSymbolIndex = 1
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
            -- self:showReSpinStart(
                -- function()
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    -- 更改respin 状态下的背景音乐
                    self:changeReSpinBgMusic()
                    self:delayCallBack(0.2,function (  )
                        self:moveRespinNode(function (  )
                            self:runNextReSpinReel()
                        end)
                    end)
                -- end
            -- )
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

---判断结算
function CodeGameScreenFortuneGodMachine:reSpinReelDown(addNode)
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
        self:delayCallBack(0.5,function (  )
            self:noMoveRespinNode()
            self.moveSymbolIndex = 1
            self:moveRespinNode(function (  )
                self:delayCallBack(1,function (  )
                    self:reSpinEndAction()
                end)
            end)
        end)
        
        

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
    self:noMoveRespinNode()
    self.moveSymbolIndex = 1
    self:moveRespinNode(function (  )
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        self:runNextReSpinReel()
    end)
    --    --下轮数据
    --    self:operaSpinResult()
    --    self:getRandomList()
    --继续

    
end

function CodeGameScreenFortuneGodMachine:noMoveRespinNode( )
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local noMoveReels = rsExtraData.noMoveReels or {}
    for i,v in ipairs(noMoveReels) do
        if not self:isTopSymbol(v) then
            local fixPos = self:getRowAndColByPos(v)
            self:setRespinKuang(fixPos)
            self.m_respinView:noMoveSymbolShow(fixPos.iX,fixPos.iY)
        end
    end
end

function CodeGameScreenFortuneGodMachine:isShowOneSynthesis(row,col)
    local isShow = false
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local noMoveReels = rsExtraData.noMoveReels or {}
    for i,v in ipairs(noMoveReels) do
        local fixPos = self:getRowAndColByPos(v)
        if fixPos.iX == row and fixPos.iY == col then
            isShow = true
        end
    end
    return isShow
end

--添加respin玩法待结束列的框发光特效
function CodeGameScreenFortuneGodMachine:createLinkRunShow( )

    for i=1,self.m_iReelColumnNum do
        local runEffect = util_createAnimation("WinFrameFortuneGod_run3.csb")  
        -- local runEffect2 = util_createAnimation("WinFrameFortuneGod_run4.csb")
        local pos = util_getOneGameReelsTarSpPos(self,POSLIST[i])
        local newPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
        self.m_clipParent:addChild(runEffect,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 100)
        -- self.m_clipParent:addChild(runEffect2,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 110)
        runEffect:setPosition(pos)
        -- runEffect2:setPosition(pos)
        runEffect:setVisible(false)
        -- runEffect2:setVisible(false)
        table.insert( self.respinRunEffectList, runEffect )
        -- table.insert( self.respinRunEffectList2, runEffect2)
    end
end

function CodeGameScreenFortuneGodMachine:hideLinkRun( )
    for i=1,5 do
        local runEffect = self.respinRunEffectList[i]
        runEffect:setVisible(false)
        -- local runEffect2 = self.respinRunEffectList2[i]
        -- runEffect2:setVisible(false)
    end
end

function CodeGameScreenFortuneGodMachine:hideLinkRunForCol(col)
    for i=1,5 do
        if i == col then
            local runEffect = self.respinRunEffectList[i]
            runEffect:setVisible(false)
        end
        
        -- local runEffect2 = self.respinRunEffectList2[i]
        -- runEffect2:setVisible(false)
    end
end

--显示
function CodeGameScreenFortuneGodMachine:showLinkRun(iCol)
    for i = 1,5 do
        if i == iCol then
            local runEffect = self.respinRunEffectList[iCol]
            if not runEffect:isVisible() then 
                runEffect:setVisible(true)
                runEffect:runCsbAction("run",true)
            end
        end
    end
end

function CodeGameScreenFortuneGodMachine:isShowLinkRunSound( )
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local ifNearEnd = rsExtraData.ifNearEnd or {}
    if #ifNearEnd > 0 and #ifNearEnd > #self.m_linkNearEnd then
        self.m_linkNearEnd = ifNearEnd
        return true
    else
        return false
    end
end

function CodeGameScreenFortuneGodMachine:showLinkRun2(iCol)
    for i=1,5 do
        if i == iCol then
            local runEffect = self.respinRunEffectList[iCol]
            runEffect:setVisible(false)
            -- local runEffect2 = self.respinRunEffectList2[iCol]
            -- runEffect2:setVisible(true)
            -- runEffect2:runCsbAction("fangda",false,function (  )
                -- runEffect2:runCsbAction("run")
            -- end)
        end
    end
end

function CodeGameScreenFortuneGodMachine:changeLinkRun(iCol)
    for i=1,5 do
        if i == iCol then
            -- local runEffect = self.respinRunEffectList2[iCol]
            -- local runEffect2 = self.respinRunEffectList[iCol]
            -- runEffect:setVisible(false)
            -- runEffect2:setVisible(true)
            -- runEffect2:runCsbAction("run",true)
        end
    end
end

--respin小块移动
function CodeGameScreenFortuneGodMachine:moveRespinNode(func2)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local ifNearEnd = rsExtraData.ifNearEnd or {}
    local moveReels = rsExtraData.moveReels or {}
    local time = 0
    local lineBet = globalData.slotRunData:getCurTotalBet()
    if self.moveSymbolIndex > #moveReels then
        if func2 then
            func2()
        end
        return
    end
    local v = moveReels[self.moveSymbolIndex]

    local info1 = {
        pos = v[1],
        store = lineBet * self:getReSpinSymbolScore(v[1]),
        bonusType = v[3],
    } 
    local info2 = {
        pos = v[1]
    }
    local info4 = {
        pos = v[2],
        bonusType = v[3],
        store = lineBet * self:getReSpinSymbolScore(v[1])
    }
    local func1 = function (  )
        --将移动后的小块changeCCb为bonus小块
        
        self:changeCurNodeLightZorder(info4)
    end
    local info3 = {
        pos = v[2],
        func = func1
    }
    
    local node = cc.Node:create()
    self:addChild(node)

    local actList = {}

    actList[#actList + 1] = cc.CallFunc:create(function (  )
        self:changeCurNodeZorder(info2)
    end)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        self:symbolMoveAction(info3,self:createMoveSymbol(info1),func2)
    end)

    actList[#actList + 1] = cc.CallFunc:create(function (  )
        node:removeFromParent()
        
    end)
    node:runAction(cc.Sequence:create(actList))

end

function CodeGameScreenFortuneGodMachine:addCoinsBonusSpine(_symbol,info)
    local score = info.store
    local symbolType = info.bonusType
    local cocosName = "Socre_FortuneGod_Bonus_1.csb"
    -- if symbolType == self.SYMBOL_FIX_SYMBOL then
    --     cocosName = "Socre_FortuneGod_Bonus_0.csb"
    -- end
    local coinsView = util_createAnimation(cocosName)
    
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        coinsView:findChild("m_lb_coins"):setString(util_formatCoins(score, 3))
        coinsView:findChild("m_lb_coins"):setVisible(true)
        coinsView:findChild("Node_jackpot"):setVisible(false)
    else
        coinsView:findChild("m_lb_coins"):setVisible(false)
        coinsView:findChild("Node_jackpot"):setVisible(true)
        if symbolType == self.SYMBOL_FIX_GRAND then
            coinsView:findChild("FortuneGod_tubiao_grand_5"):setVisible(true)
            coinsView:findChild("FortuneGod_tubiao_major_6"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_minor_8"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_mini_7"):setVisible(false)
        elseif symbolType == self.SYMBOL_FIX_MAJOR then
            coinsView:findChild("FortuneGod_tubiao_grand_5"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_major_6"):setVisible(true)
            coinsView:findChild("FortuneGod_tubiao_minor_8"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_mini_7"):setVisible(false)
        elseif symbolType == self.SYMBOL_FIX_MINOR then
            coinsView:findChild("FortuneGod_tubiao_grand_5"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_major_6"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_minor_8"):setVisible(true)
            coinsView:findChild("FortuneGod_tubiao_mini_7"):setVisible(false)
        elseif symbolType == self.SYMBOL_FIX_MINI then
            coinsView:findChild("FortuneGod_tubiao_grand_5"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_major_6"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_minor_8"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_mini_7"):setVisible(true)
        end
    end
    
    util_spinePushBindNode(_symbol,"kong",coinsView)
end

function CodeGameScreenFortuneGodMachine:createMoveSymbol(info)
    local pos = info.pos
    local score = info.store
    local symbolType = info.bonusType
    local tempNode = util_spineCreate("Socre_FortuneGod_Bonus",true,true)
    self:addCoinsBonusSpine(tempNode,info)

    local pos = util_getOneGameReelsTarSpPos(self,pos)
    local newPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
    self.m_clipParent:addChild(tempNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE +5)
    tempNode:setPosition(pos)
    return tempNode
end

function CodeGameScreenFortuneGodMachine:isTopSymbol(pos)
    for i,v in ipairs(UPINDEX) do
        if v == pos then
            return true
        end
    end
    return false
end

function CodeGameScreenFortuneGodMachine:symbolMoveAction(info,node,func2)
    local pos = info.pos
    local func = info.func
    local pos = util_getOneGameReelsTarSpPos(self,pos)
    local endPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if self:isTopSymbol(info.pos) then
            util_spinePlay(node,"switch",false)
        else
            util_spinePlay(node,"switch2",false)

            local fixPos = self:getRowAndColByPos(info.pos)
            self:setRespinKuang(fixPos)
        end
        gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_link_move.mp3")
    end)
    actList[#actList + 1]  = cc.EaseIn:create(cc.MoveTo:create(10/30,pos),2)
    
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if self:isTopSymbol(info.pos) then
            local fixPos = self:getRowAndColByPos(info.pos)
            self:setRespinKuang(fixPos)
        end
    end)
    
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        self.moveSymbolIndex =self.moveSymbolIndex + 1
        self:moveRespinNode(func2)
    end)
    
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if func then
            func()
        end
    end)
    -- actList[#actList + 1] = cc.DelayTime:create(2/3)
    actList[#actList + 1] = cc.RemoveSelf:create()
    node:runAction(cc.Sequence:create( actList))

end

function CodeGameScreenFortuneGodMachine:setRespinKuang(fixPos)
    --fixPos.iX,fixPos.iY
    if fixPos.iX == 4 then
        self.m_respinView:showSynthesis(fixPos.iY,1,false)
    elseif fixPos.iX == 3 then
        self.m_respinView:showSynthesis(fixPos.iY,2,true)
    elseif fixPos.iX == 2 then
        self.m_respinView:showSynthesis(fixPos.iY,3,true)
    elseif fixPos.iX == 1 then
        self.m_respinView:showSynthesis(fixPos.iY,4,true)
    end
end

function CodeGameScreenFortuneGodMachine:changeCurNodeZorder(info)
    local pos = info.pos
    local fixPos = self:getRowAndColByPos(pos)
    -- local node = self.m_respinView:getRespinNode(fixPos.iX,fixPos.iY)
    self.m_respinView:changeLockSymbol(fixPos)
end

function CodeGameScreenFortuneGodMachine:changeCurNodeLightZorder(info)
    local pos = info.pos
    local type = info.bonusType
    local store = info.store
    -- local fixPos = self:getRowAndColByPos(pos)
    -- local node = self.m_respinView:getRespinNode(fixPos.iX,fixPos.iY)
    self.m_respinView:changeBlankSymbol(type,pos,store)
end


--结束移除小块调用结算特效
function CodeGameScreenFortuneGodMachine:reSpinEndAction()    
    --停掉单个快滚框
    self:hideLinkRun()
    self.m_respinView.isHideKuang = false
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_respinChipList = {}      --最终收集的小块列表
    self.m_respinChipList2 = {}
    self.m_respinChipList3 = {}
    self.m_respinChipList4 = {}
    self.m_playAnimIndex = 1
    self.m_playEndColIndex = 1

    self:clearCurMusicBg()
    
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()   

    --根据服务器给的应该收集的列数，将收集小块提取出来
    self:checkEndCollectNode()
    self.respinDark:setVisible(true)
    self.collectCoins = 0
    self.respinDark:runCsbAction("darkstart",false,function (  )
        self:showFireIdle()
        self.respinDark:runCsbAction("dark")
        self:delayCallBack(1,function (  )
            self:playChipCollectAnim()
        end)
    end)
    
end

function CodeGameScreenFortuneGodMachine:createRespinBao( )
    self.m_respinFireList = {}
    for i=1,5 do
        local tempRespinBoom = util_spineCreate("Socre_FortuneGod_Bonus",true,true)
        util_spinePlay(tempRespinBoom,"huohuaidle",false)
        
        local firePos = util_convertToNodeSpace(self:findChild("Node_respin_" .. i),self)
        self:addChild(tempRespinBoom,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 10)
        tempRespinBoom:setPosition(firePos)
        tempRespinBoom:setScale(self.m_machineRootScale)
        tempRespinBoom:setVisible(false)
        self.m_respinFireList[#self.m_respinFireList + 1] = tempRespinBoom
    end
end

function CodeGameScreenFortuneGodMachine:getTempSymbolZorder(col)
    if col == 1 then
        return SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 8
    elseif col == 2 then
        return SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 7
    elseif col == 3 then
        return SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 6
    elseif col == 4 then
        return SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 5
    elseif col == 5 then
        return SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 4
    else
        return SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 9
    end
end

function CodeGameScreenFortuneGodMachine:checkEndCollectNode( )
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local endLie = rsExtraData.endLie or {}
    local lineBet = globalData.slotRunData:getCurTotalBet()
    for i,v in ipairs(endLie) do
        self.m_respinChipList[v] = {}
        self.m_respinChipList3[v] = {}
        self.m_respinChipList4[v] = {}
        for j,node in ipairs(self.m_chipList) do
            local iCol = node.p_cloumnIndex
            if iCol == v + 1 then
                --若压黑，可创建一个最终收集的小块用来最终收集
                local tempRespinNode = util_spineCreate("Socre_FortuneGod_Bonus",true,true)
                local iCol = node.p_cloumnIndex
                local iRow = node.p_rowIndex
                
                tempRespinNode.p_cloumnIndex = node.p_cloumnIndex
                tempRespinNode.p_rowIndex = node.p_rowIndex
                tempRespinNode.p_symbolType = node.p_symbolType
                -- 根据网络数据获得当前固定小块的分数
                local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) 
                local info = {
                    store = score * lineBet,
                    bonusType = node.p_symbolType
                }
                self:addCoinsBonusSpine(tempRespinNode,info)
                --添加在self.m_clipParent,并设置位置

                local nodePos = util_convertToNodeSpace(node,self.m_clipParent)
                --列数越小，层级越高  GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2
                self.m_clipParent:addChild(tempRespinNode,self:getTempSymbolZorder(node.p_cloumnIndex))
                util_spinePlay(tempRespinNode,"idleframe2",false)
                -- tempRespinNode:setScale(self.m_machineRootScale)
                tempRespinNode:setPosition(nodePos)
                --创建圆框
                local tempKuang = util_createAnimation("FortuneGod_bukuang.csb")
                self.m_clipParent:addChild(tempKuang,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 3)
                -- tempKuang:setScale(self.m_machineRootScale)
                tempKuang.p_cloumnIndex = node.p_cloumnIndex
                tempKuang.p_rowIndex = node.p_rowIndex
                tempKuang:setPosition(nodePos)
                
                if iRow == 4 then
                    --底板
                    local tempRespinDi = util_spineCreate("Socre_FortuneGod_Bonus",true,true)
                    util_spinePlay(tempRespinDi,"hecheng3idle",false)
                    self.m_clipParent:addChild(tempRespinDi,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 2)
                    -- tempRespinDi:setScale(self.m_machineRootScale)
                    tempRespinDi.endLie = v
                    table.insert( self.m_respinChipList2,tempRespinDi)
                    tempRespinDi:setPosition(nodePos)
                end
                self.m_respinChipList[v][#self.m_respinChipList[v] + 1] = tempRespinNode
                self.m_respinChipList3[v][#self.m_respinChipList3[v] + 1] = node
                self.m_respinChipList4[v][#self.m_respinChipList4[v] + 1] = tempKuang
                tempKuang:setVisible(false)
                node:setVisible(false)
            end
        end
        --排序
        self:sortRespinTempNode(self.m_respinChipList[v])
        self:sortRespinTempNode(self.m_respinChipList4[v])
    end
    
end

function CodeGameScreenFortuneGodMachine:showFireIdle( )
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local endLie = rsExtraData.endLie or {}
    for i,v in ipairs(endLie) do
        self.m_respinFireList[v + 1]:setVisible(true)
        util_spinePlay(self.m_respinFireList[v + 1],"huohuaidle",true)
    end
end

function CodeGameScreenFortuneGodMachine:sortRespinTempNode(list)
    table.sort( list,
            function(a, b)
                if a.p_cloumnIndex ~= b.p_cloumnIndex then
                    return a.p_cloumnIndex < b.p_cloumnIndex
                else
                    return b.p_rowIndex  >  a.p_rowIndex
                end
        end )
end

function CodeGameScreenFortuneGodMachine:setCollectRespinNodeVisible( )
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local endLie = rsExtraData.endLie or {}
    for i,v in ipairs(endLie) do
        local tempList = self.m_respinChipList3[v]
        for j,node in ipairs(tempList) do
            node:setVisible(true)
        end
    end
    
end

function CodeGameScreenFortuneGodMachine:clearTempListDi(endCol)
    for i,v in pairs(self.m_respinChipList2) do
        if v.endLie == endCol then
            util_spinePlay(v,"hecheng3idlexiaoshi",false)
            self:delayCallBack(0.5,function (  )
                v:removeFromParent()
                self.m_respinChipList2[i] = nil
            end)
            
        end
    end
    local tempKuang = self.m_respinChipList4[endCol]
    for k,v in pairs(tempKuang) do
        v:runCsbAction("over",false,function (  )
            v:removeFromParent()
        end)
    end
    self.m_respinChipList4[endCol] = nil
end


-- 根据本关卡实际小块数量填写
function CodeGameScreenFortuneGodMachine:getRespinRandomTypes( )
    local symbolList = { 
        self.SYMBOL_FIX_GRAND,
        self.SYMBOL_FIX_MAJOR,
        self.SYMBOL_FIX_MINOR,
        self.SYMBOL_FIX_MINI,
        self.SYMBOL_FIX_SYMBOL,
        self.SYMBOL_RS_SCORE_BLANK,
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenFortuneGodMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "buling2", bRandom = false},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_GRAND, runEndAnimaName = "buling2", bRandom = false},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling2", bRandom = true}
    }

    return symbolList
end

function CodeGameScreenFortuneGodMachine:showReSpinStart(func)
    self.isInBonus = true
    local dialogName = "respinstart"
    local ownerlist = {
        
    }
    local skinName   = nil
    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_respinStart.mp3")
    self:addSpineTanbanView(dialogName, ownerlist, func, skinName)
end

function CodeGameScreenFortuneGodMachine:showRespinView()
    self.m_bottomUI:resetWinLabel()
    self.m_bottomUI:notifyTopWinCoin()
    self.m_bottomUI:checkClearWinLabel()
    self:clearCurMusicBg()
    --先播放动画 再进入respin
    -- 播放提示时播放音效
    self:playBonusTipMusicEffect()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if node then
                if self:isFixSymbol(node.p_symbolType) then
                    node:runAnim("actionframe",false,function (  )
                        node:runAnim("idleframe",true)
                    end)
                end
            end
        end
    end
    self:delayCallBack(2,function (  )
        if self.m_isChooseRespin then
                self:checkChangeBaseParent()
                
                --可随机的普通信息
                local randomTypes = self:getRespinRandomTypes( )
    
                --可随机的特殊信号 
                local endTypes = self:getRespinLockTypes()
                --构造盘面数据
                self:triggerReSpinCallFun(endTypes, randomTypes)
        else
            self:showReSpinStart(function (  )
                self:clearSpineTanbanView(function (  )
                    self:checkChangeBaseParent()
                    
                    --可随机的普通信息
                    local randomTypes = self:getRespinRandomTypes( )
        
                    --可随机的特殊信号 
                    local endTypes = self:getRespinLockTypes()
                    --构造盘面数据
                    self:triggerReSpinCallFun(endTypes, randomTypes)
                end)
            end)
        end
        
    end)
end

--ReSpin开始改变UI状态
function CodeGameScreenFortuneGodMachine:changeReSpinStartUI(respinCount)
    self.m_progress:setVisible(false)
    self.left:setVisible(false)
    self.right:setVisible(false)
    self.respinGuaDian:setVisible(true)
    self.reSpinBar:setVisible(true)
    self:runCsbAction("change")
    self:changeRespinBarZorder(true)
    --展示respin底
    self:findChild("respin_bottom"):setVisible(true)
end

--ReSpin刷新数量
function CodeGameScreenFortuneGodMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
   
end

--ReSpin结算改变UI状态
function CodeGameScreenFortuneGodMachine:changeReSpinOverUI()
    self.m_progress:setVisible(true)
    self.left:setVisible(true)
    self.right:setVisible(true)
    self.respinGuaDian:setVisible(false)
    self.reSpinBar:setVisible(false)
    self:runCsbAction("change2")
    self:changeRespinBarZorder(false)
    
end

function CodeGameScreenFortuneGodMachine:changeRespinOverCCbName( )
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow,SYMBOL_NODE_TAG)

            if symbol.p_symbolType == self.SYMBOL_RS_SCORE_BLANK then
                local type = math.random(2,8)
                symbol:changeCCBByName(self:getSymbolCCBNameByType(self, type), type)
            else
                local index = self:getPosReelIdx(iRow,iCol)
                if self:isFixNodeForStoredIcons(index) then
                    local info = self:isFixNodeForStoredIcons(index)
                    symbol:changeCCBByName(self:getSymbolCCBNameByType(self, info[3]), info[3])
                    self:addLevelBonusSpineForRespinOver(symbol,info[2],info[3])
                else
                    local type = math.random(2,8)
                    symbol:changeCCBByName(self:getSymbolCCBNameByType(self, type), type)
                end
            end
        end
    end
end

function CodeGameScreenFortuneGodMachine:addLevelBonusSpineForRespinOver(_symbol,coins,type)
    --p_rsExtraData
    local lineBet = globalData.slotRunData:getCurTotalBet()
    coins = coins * lineBet
    local score = util_formatCoins(coins, 3)
    local cocosName = "Socre_FortuneGod_Bonus_1.csb"
    -- if type == self.SYMBOL_FIX_SYMBOL then
    --     cocosName = "Socre_FortuneGod_Bonus_0.csb"
    -- end
    local symbol_node = _symbol:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local coinsView
    if not spineNode.m_csbNode then
        coinsView = util_createAnimation(cocosName)
        util_spinePushBindNode(spineNode,"kong",coinsView)
        spineNode.m_csbNode = coinsView
    else
        coinsView = spineNode.m_csbNode
    end
    
    if type == self.SYMBOL_FIX_SYMBOL then
        coinsView:findChild("m_lb_coins"):setString(score)
        coinsView:findChild("m_lb_coins"):setVisible(true)
        coinsView:findChild("Node_jackpot"):setVisible(false)
    else
        coinsView:findChild("m_lb_coins"):setVisible(false)
        coinsView:findChild("Node_jackpot"):setVisible(true)
        if type == self.SYMBOL_FIX_GRAND then
            coinsView:findChild("FortuneGod_tubiao_grand_5"):setVisible(true)
            coinsView:findChild("FortuneGod_tubiao_major_6"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_minor_8"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_mini_7"):setVisible(false)
        elseif type == self.SYMBOL_FIX_MAJOR then
            coinsView:findChild("FortuneGod_tubiao_grand_5"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_major_6"):setVisible(true)
            coinsView:findChild("FortuneGod_tubiao_minor_8"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_mini_7"):setVisible(false)
        elseif type == self.SYMBOL_FIX_MINOR then
            coinsView:findChild("FortuneGod_tubiao_grand_5"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_major_6"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_minor_8"):setVisible(true)
            coinsView:findChild("FortuneGod_tubiao_mini_7"):setVisible(false)
        elseif type == self.SYMBOL_FIX_MINI then
            coinsView:findChild("FortuneGod_tubiao_grand_5"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_major_6"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_minor_8"):setVisible(false)
            coinsView:findChild("FortuneGod_tubiao_mini_7"):setVisible(true)
        end
    end
    
    
    _symbol:runAnim("idleframe")
end

function CodeGameScreenFortuneGodMachine:isFixNodeForStoredIcons(index)
    local lastStoreIcons = self.m_runSpinResultData.p_rsExtraData.lastStoreIcons
    for k,v in pairs(lastStoreIcons) do
        if v[1] == index then
            return v
        end
    end
    return nil
end

function CodeGameScreenFortuneGodMachine:showReSpinOver(coins,func)
    self:clearCurMusicBg()
    local dialogName = "respinover"
    local ownerlist = {
        m_lb_coins = coins,
    }
    local skinName   = nil
    self:setCollectRespinNodeVisible()
    self:changeRespinOverCCbName()
    --隐藏respin底
    self:findChild("respin_bottom"):setVisible(false)
    self.m_linkNearEnd = {}
    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_respinOver.mp3")
    self:addSpineTanbanView(dialogName, ownerlist, func, skinName)
end

function CodeGameScreenFortuneGodMachine:showRespinOverView(effectData)
    self.respinDark:setVisible(false)
    self.m_isChooseRespin = false
    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()
        self:clearSpineTanbanView(function (  )
            self.m_jiesuanAct:setVisible(false)
            self.isInBonus = false
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            -- self:resetMusicBg() 
        end)
    end)

end


-- --重写组织respinData信息
function CodeGameScreenFortuneGodMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}   

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)
        
        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

-- --------respin相关结束

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFortuneGodMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume()
    if self.m_winSoundsId then
        
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil

    end
    self:hideMapScroll()
    self.m_bSlotRunning = true
    self:hideMapTipView()

    return false -- 用作延时点击spin调用
end

---
-- 进入关卡
--
function CodeGameScreenFortuneGodMachine:enterLevel()
    
    CodeGameScreenFortuneGodMachine.super.enterLevel(self)

    --显示提示
    self:delayCallBack(0.3,function (  )
        self:showMapTipView()
    end)
end


function CodeGameScreenFortuneGodMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
       self:playEnterGameSound( "FortuneGodSounds/music_FortuneGod_enter.mp3" )

    end,0.4,self:getModuleName())
end

function CodeGameScreenFortuneGodMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenFortuneGodMachine.super.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
    local pecent =  self:getProgressPecent(true)
    self.m_progress:updateLoadingbar(pecent,false)
    self:createMapScroll( )
end

function CodeGameScreenFortuneGodMachine:addObservers()
	CodeGameScreenFortuneGodMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        if self:isNormalStates( )  then
            -- 取消掉赢钱线的显示
            self:showMapScroll(nil)
        end
    end,"SHOW_BONUS_MAP")
    gLobalNoticManager:addObserver(self,function(self,params)
        
        if self.getCurrSpinMode() == NORMAL_SPIN_MODE then
          
            self:clickMapTipView()

        end
        
    end,"SHOW_BONUS_Tip")
end

function CodeGameScreenFortuneGodMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenFortuneGodMachine.super.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end



-- ------------玩法处理 -- 

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFortuneGodMachine:addSelfEffect()
    self.m_collectList ={}

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if node then
                if  self:isFixSymbol(node.p_symbolType) then
                    if not self.m_collectList then
                        self.m_collectList = {}
                    end
                    self.m_collectList[#self.m_collectList + 1] = node
                end
            end
        end
    end
    --收集
    if self.m_collectList and #self.m_collectList > 0 and self.isInBonus == false then

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_TYPE_COLLECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT
    
    end 
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collectOccur = selfData.collectOccur or false
    local collectWinCoins = selfData.collectWinCoins
    if collectWinCoins or collectOccur then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        if collectWinCoins then
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 3
        else
            selfEffect.p_effectOrder = GameEffect.EFFECT_FIVE_OF_KIND + 1
        end
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BONUS_GAME_EFFECT
    end

end


---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFortuneGodMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT then
        self:delayCallBack(0.15,function (  )
            self:showEffect_collectCoin(effectData)
        end)
        
    elseif effectData.p_selfEffectType == self.BONUS_GAME_EFFECT then
        local waitTime = 0
        if self.m_runSpinResultData.p_winLines == 0 then
            waitTime = 0
        else
            waitTime = 1
        end
        self:delayCallBack(waitTime,function (  )
            self:clearCurMusicBg()
            self:showJiMan()
            self.m_progress:showJiMan(function (  )
                self:showEffect_CollectBonus(effectData)
            end)
        end)
    end

    
	return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
--增加特殊快滚
function CodeGameScreenFortuneGodMachine:MachineRule_ResetReelRunData()
    if self.m_isChooseRespin  then
        return
    end
    --self.m_reelRunInfo 中存放轮盘滚动信息
    if self:checkTriggerAddBonusLongRun() then
        self.m_isTrigerRespinRun = true
        for iCol = self.LONGRUN_COL_ADD_BONUS, self.m_iReelColumnNum do
            local reelRunInfo = self.m_reelRunInfo
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]

            reelRunData:setReelLongRun(true)
            reelRunData:setNextReelLongRun(true)

            local reelLongRunTime = 2.5
            if iCol > self.m_iReelColumnNum then
                reelLongRunTime = 2.5
                reelRunData:setReelLongRun(false)
                reelRunData:setNextReelLongRun(false)
            end

            local iRow = columnData.p_showGridCount
            local lastColLens = reelRunInfo[1]:getReelRunLen()
            if iCol ~= 1 then
                lastColLens = reelRunInfo[iCol - 1]:getReelRunLen()
                reelRunInfo[iCol - 1 ]:setNextReelLongRun(true)
            end

            local colHeight = columnData.p_slotColumnHeight
            local reelCount = (reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
            local runLen = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高

            local preRunLen = reelRunData:getReelRunLen()
            reelRunData:setReelRunLen(runLen)

        end
    end

end


function CodeGameScreenFortuneGodMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenFortuneGodMachine.super.playEffectNotifyNextSpinCall( self )
    self.m_bSlotRunning = false
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    if self.m_chooseRepin then
        self.m_chooseRepin = false
        self:normalSpinBtnCall()
    end
end

function CodeGameScreenFortuneGodMachine:dealSmallReelsSpinStates( )

    if self.m_chooseRepinGame then
        self.m_chooseRepinGame = false
    end

    CodeGameScreenFortuneGodMachine.super.dealSmallReelsSpinStates(self )

end

function CodeGameScreenFortuneGodMachine:requestSpinReusltData()

    CodeGameScreenFortuneGodMachine.super.requestSpinReusltData(self)

    -- 设置stop 按钮处于不可点击状态
    if not self.m_chooseRepinGame  then
        if self:getCurrSpinMode() == RESPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Spin,false,true})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Stop,false,true})
        end
    end
    
end

function CodeGameScreenFortuneGodMachine:playEffectNotifyChangeSpinStatus( )
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                                        {SpinBtn_Type.BtnType_Auto,true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Auto,true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
                    self:normalSpinBtnCall()
                end, 0.5,self:getModuleName())
            end
        else
            if not self.m_chooseRepinGame  then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,true})
            end
            
        end
    end

end

function CodeGameScreenFortuneGodMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenFortuneGodMachine.super.slotReelDown(self)
end

function CodeGameScreenFortuneGodMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--gameConfig数据
function CodeGameScreenFortuneGodMachine:initGameStatusData( gameData )
    CodeGameScreenFortuneGodMachine.super.initGameStatusData( self, gameData )
    if gameData then
        if gameData.gameConfig then
            if gameData.gameConfig.extra then
                if gameData.gameConfig.extra.map then
                    self.m_bonusData = clone(gameData.gameConfig.extra)
                end
                
            end
        end
    end
end

--*****************************收集玩法

function CodeGameScreenFortuneGodMachine:showSuperFreeStart(index,num,func)
    --
    self.m_fsReelDataIndex = self:getcollectFsStates(self.m_mapNodePos)
    local data = {
        index = index,
        num = num,
        func = func
    }
    local view = util_createView("CodeFortuneGodSrc.FortuneGodSuperFreeStartView",data)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_superFreeStart.mp3")
    gLobalViewManager:showUI(view)

end

function CodeGameScreenFortuneGodMachine:showSuperFreeOver(coins,num,func)
    self:clearCurMusicBg()
    local dialogName = "superfreeover"
    local ownerlist = {
        m_lb_coins = coins,
        m_lb_num = num
    }
    local skinName   = nil
    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_superFreeOver.mp3")
    self:addSpineTanbanView(dialogName, ownerlist, func, skinName)
end

function CodeGameScreenFortuneGodMachine:getProgressPecent(_init)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local collectProcess = nil 
    local maxCount = 0
    local currCount = 0

    -- 第一次进入取gameConfig的数据
    if  not collectProcess and _init then
        collectProcess = self.m_bonusData.collectProcess
        maxCount = collectProcess.target or 0
        currCount = collectProcess.collect or 0
    else
        if selfData.collectPos and selfData.collectNum and selfData.collectNumAll then
            collectProcess = {}
            collectProcess.pos = selfData.collectPos
            collectProcess.collectNum = selfData.collectNum
            collectProcess.collectNumAll = selfData.collectNumAll
        end
        if collectProcess ~= nil then
            maxCount = collectProcess.collectNumAll or 0
            currCount = collectProcess.collectNum or 0
        end
        
    end

    local percent = currCount / maxCount * 100

    return percent
end

function CodeGameScreenFortuneGodMachine:showEffect_collectCoin(effectData)

    local endNode = self.m_progress:findChild("FortuneGod__bace_bianpao_4")
    local progressPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
    local newProgressPos = self:convertToNodeSpace(progressPos)
    local endPos = cc.p(newProgressPos)
    local function flyShow ( startPos,endPos)
        local actionList = {}
        local collectNode = util_spineCreate("Socre_FortuneGod_Bonus",true,true)
        collectNode:setScale(self.m_machineRootScale)
        self:addChild(collectNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)

        collectNode:setPosition(startPos)
        actionList[#actionList + 1] = cc.CallFunc:create(function(  )
            -- util_spinePlay(collectNode,"shouji",false)
        end)
        actionList[#actionList + 1] = cc.DelayTime:create(7/30)

        actionList[#actionList + 1] = cc.BezierTo:create(13/30,{cc.p(startPos.x , startPos.y), cc.p(endPos.x, startPos.y), endPos})

        actionList[#actionList + 1] = cc.CallFunc:create(function()
            collectNode:setVisible(false)
            collectNode:removeFromParent()
        end)
        collectNode:runAction(cc.Sequence:create(actionList))
    end
    -- if #self.m_collectList > 0 then
    --     gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_collect_fly.mp3")
    -- end
    for i = #self.m_collectList, 1, -1 do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)
        flyShow(newStartPos,endPos)
        table.remove(self.m_collectList, i)
    end
    self:delayCallBack(2/3,function (  )
        gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_collect_fanKui.mp3")
        self:showCollectEffect()
    end)
    local pecent = self:getProgressPecent()
    self:delayCallBack(0.7,function (  )
        --收集反馈，进度条增长
        self.m_progress:updateLoadingbar(pecent,true)
    end)

    local time = 0

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collectWin = selfData.collectWinCoins 

    local features = self.m_runSpinResultData.p_features or {}

    --触发收集小游戏 播放完收集
    if collectWin or #features >= 2 then 
        time = (18 + 30 + 15 )/30
    end

    performWithDelay(self,function(  )

        effectData.p_isPlay = true
        self:playGameEffect()
        
    end,time)
end

function CodeGameScreenFortuneGodMachine:getcollectFsStates(pos)
    if pos == BIG_LEVEL.ONE_LEVEL then
        return self.COllECT_FS_RUN_STATES1
    elseif pos == BIG_LEVEL.TWO_LEVEL then
        return self.COllECT_FS_RUN_STATES2
    elseif pos == BIG_LEVEL.THREE_LEVEL then
        return self.COllECT_FS_RUN_STATES3
    elseif pos == BIG_LEVEL.FOUR_LEVEL then
        return self.COllECT_FS_RUN_STATES4
    else
        return self.COllECT_FS_RUN_STATES1
    end
end

function CodeGameScreenFortuneGodMachine:showEffect_CollectBonus(effectData)
    self:clearCurMusicBg()

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self.m_bottomUI:showAverageBet()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = 1
    currentPos = selfData.collectPos
    self.m_mapNodePos = currentPos -- 更新最新位置
    local collectWinCoins = selfData.collectWinCoins or 0
    local collectOccur = selfData.collectOccur or false

    self:showMapScroll(function(  )
        self:delayCallBack(0.5,function (  )
            self.m_progress:updateLoadingbar(0,false)
            self.m_map:pandaMove(function(  )

                if collectOccur then
                    --
                    self.m_fsReelDataIndex = self:getcollectFsStates(self.m_mapNodePos)
                    
                    self:delayCallBack(0.5,function (  )
                        self:changeProgressParent(false)
                        -- self:findChild("Node_reel"):setVisible(true)
                        self.m_map:mapDisappear(function (  )
                            self:resetMusicBg(true)
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end)
                    end)
                    
                else
                    local currNode = self.m_map.m_vecNodeLevel[self.m_mapNodePos]
                    self:createParticleFly(0.3,currNode,collectWinCoins,function(  )
                        local beginCoins =  self.m_serverWinCoins - collectWinCoins
                        gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_map_small_fanKui.mp3")
                        self:updateBottomUICoins(beginCoins,collectWinCoins,true,nil,false)
                        end,function (  )
                            if #self.m_runSpinResultData.p_winLines == 0 then
                                self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount,self.BONUS_GAME_EFFECT)
                                -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_winAmount,true})
                            end
                            
                            self:delayCallBack(0.5,function (  )
                                self:changeProgressParent(false)
                                -- self:findChild("Node_reel"):setVisible(true)
                                self.m_map:mapDisappear(function(  )
                                    self.m_bottomUI:hideAverageBet()
                                    self:resetMusicBg(true)
                                    effectData.p_isPlay = true
                                    self:playGameEffect()
                        
                                end)
                            end)
                            
                        end)
                end


            end, self.m_bonusData.map, self.m_mapNodePos,collectWinCoins)
        end)
        
    end)
end

function CodeGameScreenFortuneGodMachine:updateBottomUICoins( beiginCoins,currCoins,isNotifyUpdateTop,isPlayAnim,isRespin)
    -- free下不需要考虑更新左上角赢钱
    local endCoins = beiginCoins + currCoins
    if isRespin then
        globalData.slotRunData.lastWinCoin = beiginCoins + currCoins
    else
        globalData.slotRunData.lastWinCoin = self.m_serverWinCoins
    end

    local params = {endCoins,isNotifyUpdateTop,isPlayAnim,beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

-- 创建飞行粒子
function CodeGameScreenFortuneGodMachine:createParticleFly(time,currNode,coins,func1,func2)
    --
    local fly = util_createAnimation("Socre_FortuneGod_font_5.csb")
    local info1={label=fly,sx=0.5,sy=0.5}
    self:updateLabelSize(info1,167)
    self:addChild(fly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)

    local flyPos = util_getConvertNodePos(currNode,self)
    fly:setPosition(cc.p(flyPos.x,flyPos.y))
    fly:findChild("m_lb_coins"):setString(util_formatCoins(coins, 3))
    local coinLab = self.m_bottomUI:getNormalWinLabel()
    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local endPos = util_convertToNodeSpace(endNode,self)

    local animation = {}
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        currNode:findChild("m_lb_coins"):setString("")
    end)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        fly:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
        fly:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        fly:findChild("Particle_1"):resetSystem()
    end)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_map_small_fly.mp3")
    end)
    animation[#animation + 1] = cc.MoveTo:create(time, cc.p(endPos.x,endPos.y) )
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        fly:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
        --fankui
        self:showWinJieSunaAct()
        fly:setVisible(false)
        if func1 then
            func1()
        end
    end)
    
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        currNode:changeSmall()
    end)
    animation[#animation + 1] = cc.DelayTime:create(0.7)
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        if func2 then
            func2()
        end
    end)
    
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        
        fly:removeFromParent()

    end)

    fly:runAction(cc.Sequence:create(animation))

end

--*****************************选择
--[[
    *************** 选择玩法
--]]
---
-- 显示bonus 触发的小游戏
function CodeGameScreenFortuneGodMachine:showEffect_Bonus(effectData)
    self.m_isBonusTrigger = true
    self.isInBonus = true

    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    local time = 1
    local changeNum = 1/(time * 60) 
    local curvolume = 1
    self.m_updateBgMusicHandlerID = scheduler.scheduleUpdateGlobal(function()
        curvolume = curvolume - changeNum
        if curvolume <= 0 then

            curvolume = 0

            if self.m_updateBgMusicHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
                self.m_updateBgMusicHandlerID = nil
            end
        end

        gLobalSoundManager:setBackgroundMusicVolume(curvolume)
    end)

    performWithDelay(self,function(  )

        -- 停止播放背景音乐
        self:clearCurMusicBg()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "bonus")
        end
        local num,scList = self:getScatterList()
        -- 播放bonus 元素不显示连线
        if num > 0 then
            -- --由于提层导致找不到sc小块没播放触发动画
            self:checkChangeBaseParent()
            self:showScatterTrigger(num,scList,function (  )
                performWithDelay(self,function(  )
                    self:showBonusGameView(effectData)
                end,0.5)
            end)
            -- 播放提示时播放音效        
            self:playScatterTipMusicEffect()

        else
            self:showBonusGameView(effectData)
        end
 
    end,time)
        
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

    return true
end

--由于sc没有连线 导致不播scatter触发动画
function CodeGameScreenFortuneGodMachine:getScatterList( )
    local scList = {}
    local num = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if node then
                if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    table.insert( scList, node)
                    num = num + 1
                end
            end
        end
    end
    return num,scList
end

---
-- 重写sc触发逻辑
--
function CodeGameScreenFortuneGodMachine:showScatterTrigger(num,scList,callFun)

    local animTime = 0

    for i = 1, num do
        local slotNode = nil
        if scList[i] then
            slotNode = scList[i]
        end
        if slotNode ~= nil then --这里有空的没有管
            slotNode = self:setSlotNodeEffectParent(slotNode)

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime, callFun)
end

function CodeGameScreenFortuneGodMachine:showBonusGameView( effectData )
   
    if self.m_updateBgMusicHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
        self.m_updateBgMusicHandlerID = nil
    end

    self.m_bottomUI:checkClearWinLabel()
    self:show_Choose_BonusGameView(effectData)
end

function CodeGameScreenFortuneGodMachine:show_Choose_BonusGameView(effectData)
    
    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_ChooseView.mp3")

    local chooseView = util_createView("CodeFortuneGodSrc.FortuneGodChooseView",self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        chooseView.getRotateBackScaleFlag = function(  ) return false end
    end

    gLobalViewManager:showUI(chooseView)
    chooseView:findChild("root"):setScale(self.m_machineRootScale)
    chooseView:setEndCall( function( selectId ) 
        if chooseView then
            chooseView:removeFromParent()
        end
        if selectId == selectRespinId then
            self.m_iFreeSpinTimes = 0 
            globalData.slotRunData.freeSpinCount = 0
            globalData.slotRunData.totalFreeSpinCount = 0      
            self.m_bProduceSlots_InFreeSpin = false

            self:setSpecialSpinStates(true )
            self.m_chooseRepin = true
            self.m_isChooseRespin = true
            self.m_chooseRepinGame = true --选择respin
            --
            self.m_progress:setVisible(false)
            self.left:setVisible(false)
            self.right:setVisible(false)
            self.reSpinBar:setVisible(true)
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        else
            -- self:freeSpinShow()
            self:bonusOverAddFreespinEffect( )
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        end
    end)
end

function CodeGameScreenFortuneGodMachine:freeSpinShow( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeType = selfData.freeType
    self:runCsbAction("change")
    self:findChild("Node_base_reel"):setVisible(false)
    self:findChild("Node_free_reel"):setVisible(true)
    self.m_progress:setVisible(false)
    self.freeSpinBar:setVisible(true)
    if freeType and freeType == "COLLECT" then
        self.freeSpinBar:changeShowFree(true)
    else
        self.freeSpinBar:changeShowFree(false)
        self.freeSpinBar:updateFreespinCount(0,self.m_runSpinResultData.p_freeSpinsTotalCount)
    end
    self.right:setVisible(false)
    self.left:setVisible(false)
end

function CodeGameScreenFortuneGodMachine:freeSpinOverShow( )
    self:runCsbAction("change2")
    self:findChild("Node_base_reel"):setVisible(true)
    self:findChild("Node_free_reel"):setVisible(false)
    self.m_progress:setVisible(true)
    self.right:setVisible(true)
    self.left:setVisible(true)
    self.freeSpinBar:setVisible(false)
end

function CodeGameScreenFortuneGodMachine:bonusOverAddFreespinEffect( )
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end
end
--*****************************tips map

function CodeGameScreenFortuneGodMachine:createMapScroll( )

    -- local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = self.m_bonusData.collectProcess.pos or 0

    self.m_mapNodePos = currentPos
    self.m_map = util_createView("CodeFortuneGodSrc.map.FortuneGodMapView", self.m_bonusData.map, self.m_mapNodePos,self)
    self:findChild("Node_map"):addChild(self.m_map,GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT - 5 )
    self.m_map:setVisible(false)
end

function CodeGameScreenFortuneGodMachine:hideMapScroll()

    -- self:findChild("Node_reel"):setVisible(true)
    if self.m_map:getMapIsShow() == true then

        self.m_bCanClickMap = false
        self:changeProgressParent(false)
        
        self.m_map:mapDisappear(function()
            self.m_map:setVisible(false)
            self:resetMusicBg(true)
            self.m_bCanClickMap = true
        end)
    end

end

function CodeGameScreenFortuneGodMachine:showMapScroll(callback)

    if (self.m_bCanClickMap == false or self.m_bSlotRunning == true or self:getCurrSpinMode() == AUTO_SPIN_MODE) and callback == nil then
        return
    end

    self.m_bCanClickMap = false
    self:clearWinLineEffect()
    if self.m_map:getMapIsShow() == true then
        self:changeProgressParent(false)
        -- self:findChild("Node_reel"):setVisible(true)
        self.m_map:mapDisappear(function()
            -- self.isClickMap = true
            self.m_map:setVisible(false)
            self:resetMusicBg(true)

            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( ) 
            end)

            self.m_bCanClickMap = true
        end)
        
    else

        self:clearCurMusicBg()

        self:hideMapTipView(true)
        self:removeSoundHandler( )
        self.m_map:setVisible(true)
        gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_showMap.mp3")
        self.m_map:mapAppear(function()
            self:changeProgressParent(true)
            -- self:findChild("Node_reel"):setVisible(false)
            self:resetMusicBg(nil,"FortuneGodSounds/music_FortuneGod_mapBg.mp3")
            
            self.m_bCanClickMap = true

            if callback then
                callback()
            end
        end)
        
 
    end

end

function CodeGameScreenFortuneGodMachine:isNormalStates( )
    
    local featureLen = self.m_runSpinResultData.p_features or {}

    if #featureLen >= 2 then
        return false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        return false
    end

    if self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        return false
    end

    -- if self.m_bSlotRunning == true then
    --     return false
    -- end

    return true
end
--提示
function CodeGameScreenFortuneGodMachine:clickMapTipView( )
    -- 
    if self.m_map:getMapIsShow() ~= true and self.m_bSlotRunning ~= true then
        if not self.collectTipView:isVisible() then
            self:showMapTipView( )
        else    
            self:hideMapTipView( )
        end
    end
end

function CodeGameScreenFortuneGodMachine:showMapTipView( )
    if self:isNormalStates( ) then  --是否可以点击
        if self.collectTipView.m_states == nil or  self.collectTipView.m_states == "idle" then
            self.collectTipView:setVisible(true)
            self.collectTipView.m_states = "show"
            self.collectTipView:stopAllActions()
            gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_ShowTips.mp3")
            self.collectTipView:runCsbAction("start",false,function(  )
                self.collectTipView.m_states = "idle"
                self.collectTipView:stopAllActions()
                self.collectTipView:runCsbAction("idle")
                self.tipsWaitNode:stopAllActions()
                performWithDelay(self.tipsWaitNode,function (  )
                    self.collectTipView:stopAllActions()
                    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_HideTips.mp3")
                    self.collectTipView:runCsbAction("over",false,function (  )
                        self.collectTipView.m_states = "idle"
                        self.collectTipView:setVisible(false)
                    end)
                end,5)
            end)  
        end
    end
end

function CodeGameScreenFortuneGodMachine:hideMapTipView( _close )
    if self.collectTipView:isVisible() == false then
        return
    end
    self.tipsWaitNode:stopAllActions()
    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_HideTips.mp3")
    if self.collectTipView.m_states == "idle" then
        self.collectTipView.m_states = "over"
        self.collectTipView:stopAllActions()
        self.collectTipView:runCsbAction("over",false,function(  )
            self.collectTipView.m_states = "idle"
            self.collectTipView:setVisible(false)
        end)   
    end
    if _close then
        self.collectTipView:setVisible(false)
        self.collectTipView.m_states = "over"
        self.collectTipView:runCsbAction("over",false,function(  )
            self.collectTipView.m_states = "idle"
            self.collectTipView:setVisible(false)
        end)
    end
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
-- function CodeGameScreenFortuneGodMachine:specialSymbolActionTreatment( node)
--     if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
--         --修改小块层级
--         -- local scatterOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex
--         -- local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,scatterOrder)
--         -- self:playScatterBonusSound(node)
--     end
-- end

-- function CodeGameScreenFortuneGodMachine:playCustomSpecialSymbolDownAct( slotNode )

--     if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
--         if slotNode and  self:isFixSymbol(slotNode.p_symbolType) then
            -- local bonusOrder = self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex
            -- local symbolNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, self.SYMBOL_FIX_SYMBOL,bonusOrder)
            -- self:playScatterBonusSound(slotNode)
            -- if slotNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
            --     slotNode:runAnim("buling")
            -- else
            --     slotNode:runAnim("buling2")
            -- end
            
--         end
--     end
-- end

-- ---------------------- 特殊快滚
function CodeGameScreenFortuneGodMachine:checkTriggerAddBonusLongRun( )
    local bonusNum = 0
    for iCol = 1 ,(self.m_iReelColumnNum - 1) do
        for iRow = 1,self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
        
            if self:isFixSymbol(symbolType) then
                bonusNum = bonusNum + 1  
            end
        end
        
    end

    if bonusNum >= self.BONUS_RUN_NUM then
        self:setLongRunCol()
        return true
    end

    return false
end

function CodeGameScreenFortuneGodMachine:setLongRunCol( )
    --前两列bonus大于等于4，第三列开始
    if self:getColBonusNum(2) >= self.BONUS_RUN_NUM then
        self.LONGRUN_COL_ADD_BONUS = 3
    --前三列bonus大于等于4，第四列开始
    elseif self:getColBonusNum(3) >= self.BONUS_RUN_NUM then
        self.LONGRUN_COL_ADD_BONUS = 4
    --前四列bonus大于等于4，第五列开始
    elseif self:getColBonusNum(4) >= self.BONUS_RUN_NUM then
        self.LONGRUN_COL_ADD_BONUS = 5
    end
end

function CodeGameScreenFortuneGodMachine:getColBonusNum(colNum)
    local bonusNum = 0
    for iCol = 1 , colNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
        
            if self:isFixSymbol(symbolType) then
                bonusNum = bonusNum + 1  
            end
        end 
    end
    return bonusNum
end

---
--添加金边
function CodeGameScreenFortuneGodMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    
    if self.m_isScLongRun and self.m_isTrigerRespinRun == false then
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
    
        reelEffectNode:setVisible(true)
        util_csbPlayForKey(reelAct, "run", true)
    
    elseif self.m_isTrigerRespinRun and self.m_isScLongRun == false then
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

            reelEffectNodeBG:setVisible(true)
            util_csbPlayForKey(reelActBG, "run", true)
        end
    else
        CodeGameScreenFortuneGodMachine.super.creatReelRunAnimation(self,col)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

--设置bonus scatter 信息
function CodeGameScreenFortuneGodMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
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

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        self.m_isScLongRun = true
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

function CodeGameScreenFortuneGodMachine:isWildSymbol(symbolType)
        if symbolType == self.WILD2 or
            symbolType == self.WILD3 or
                symbolType == self.WILD5 or
                    symbolType == self.WILD8 or
                        symbolType == self.WILD10 or
                            symbolType == self.WILD25 or
                                symbolType == self.WILD100 or
                                symbolType == 92 then
            return true
        end
        return false
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenFortuneGodMachine:playInLineNodes()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildmultiply = selfData.wildmultiply

    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if wildmultiply and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                slotsNode:runAnim("actionframe2",true)
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
function CodeGameScreenFortuneGodMachine:playInLineNodesIdle()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildmultiply = selfData.wildmultiply
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if wildmultiply and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                slotsNode:runAnim("idleframe2",true)
            else
                slotsNode:runIdleAnim()
            end
            
        end
    end
end

function CodeGameScreenFortuneGodMachine:resetMaskLayerNodes()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildmultiply = selfData.wildmultiply
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
                if wildmultiply and lineNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    lineNode:runAnim("idleframe2",true)
                else
                    lineNode:runIdleAnim()
                end
                
            end
        end
    end
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenFortuneGodMachine:showLineFrameByIndex(winLines, frameIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildmultiply = selfData.wildmultiply

    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")
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

    for i = 1, frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        node:setPosition(cc.p(posX, posY))

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
            node:runAnim("actionframe", true)
        else
            node:runAnim("actionframe", true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end
    end
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    if wildmultiply and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        slotsNode:runAnim("actionframe2",true)
                    else
                        slotsNode:runLineAnim()
                    end
                    
                end
            end
        end
    end
end

function CodeGameScreenFortuneGodMachine:showEffect_LineFrame(effectData)

    
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collectWinCoins = selfData.collectWinCoins or 0
    if collectWinCoins > 0 then
        self.m_iOnceSpinLastWin = self.m_iOnceSpinLastWin - collectWinCoins
        globalData.slotRunData.lastWinCoin = self.m_iOnceSpinLastWin
    end

    return CodeGameScreenFortuneGodMachine.super.showEffect_LineFrame(self,effectData)
    
end
--[[
    参数_dialogName：spine弹板名字
    参数_ownerlist：钱数m_lb_coins、次数m_lb_num
    参数_func：点击回调
    参数_skinName：显示的皮肤
]]

function CodeGameScreenFortuneGodMachine:addSpineTanbanView(_dialogName,_ownerlist, _func, _skinName)

    local spineTanbanParent = self.m_spineTanbanParent

    --创建spine，将cocos挂到spine上
    self.m_spineTanban  = util_spineCreate(_dialogName,true,true)
    spineTanbanParent:addChild(self.m_spineTanban,10000)
    if _skinName then
        self.m_spineTanban:setSkin(_skinName)
    end
    -- self.m_spineTanban:setScale(self.m_machineRootScale)
   
    -- --按钮
    local btnView = util_createView("CodeFortuneGodSrc.FortuneGodTanBanBtnView",_dialogName)
    util_spinePushBindNode(self.m_spineTanban,"anniubaidian88",btnView)
    self.m_spineTanban.m_btnView = btnView
    
    --钱数
    if _ownerlist.m_lb_coins ~= nil then
        local coinsView = util_createAnimation("Socre_FortuneGod_font_5.csb")
        coinsView:findChild("m_lb_coins"):setString(_ownerlist.m_lb_coins)
        coinsView:findChild("Particle_1"):stopSystem()
        self:updateLabelSize({label=coinsView:findChild("m_lb_coins"),sx=1.08,sy=1.08},553)
        util_spinePushBindNode(self.m_spineTanban,"zhongbaidian11",coinsView)
    end
    --次数
    if _ownerlist.m_lb_num ~= nil then
        local numView = util_createAnimation("Socre_FortuneGod_font_5.csb")
        numView:findChild("m_lb_coins"):setString(_ownerlist.m_lb_num)
        self:updateLabelSize({label=numView:findChild("m_lb_coins"),sx=0.7,sy=0.7},553)
        numView:findChild("Particle_1"):stopSystem()
        util_spinePushBindNode(self.m_spineTanban,"zhongbaidian22",numView)
    end

    util_spinePlay(self.m_spineTanban,"start",false)
    util_spineEndCallFunc(self.m_spineTanban,"start",function(  )
        util_spinePlay(self.m_spineTanban,"idle",true)
        local pos = util_convertToNodeSpace(btnView,self.m_spineTanban)
        btnView:setVisible(false)

        local btnView2 = util_createView("CodeFortuneGodSrc.FortuneGodTanBanBtnView",_dialogName)
        btnView2:initViewData(_func)
        self.m_spineTanban.m_btnView_2 = btnView2
        self.m_spineTanban:addChild(btnView2)

        btnView2:setPosition(pos)
        btnView2:setIsClick(true)
    end)
    self.dark:setVisible(true)
    self.dark:runCsbAction("start")
end

function CodeGameScreenFortuneGodMachine:clearSpineTanbanView(func)
    local btnView = self.m_spineTanban.m_btnView
    if btnView then
        btnView:setVisible(true)
        if self.m_spineTanban.m_btnView_2 then
            self.m_spineTanban.m_btnView_2:setVisible(false)
        end
    end
    
    util_spinePlay(self.m_spineTanban,"over",false)
    self.dark:runCsbAction("over",false,function (  )
        self.dark:setVisible(false)
    end)
    self:delayCallBack(2/3,function (  )
        if func then
            func()
        end
        if self.m_spineTanban then
            self.m_spineTanban:removeFromParent()
            self.m_spineTanban = nil
        end
    end)
end


--延迟回调
function CodeGameScreenFortuneGodMachine:delayCallBack(time, func)
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


---
-- 检测处理respin  和 special reel的逻辑
--
-- function CodeGameScreenFortuneGodMachine:checkOpearReSpinAndSpecialReels(param)
--     -- self:closeCheckTimeOut()
--     if self:getCurrSpinMode() == RESPIN_MODE and self.m_specialReels then
--         if param[1] == true then
--             local spinData = param[2]
--             -- print("respin"..cjson.encode(param[2]))
--             if spinData.action == "SPIN" then
--                 self:operaWinCoinsWithSpinResult(param)

--                 self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
--                 self:getRandomList()

--                 self:stopRespinRun()

--                 self:setGameSpinStage(GAME_MODE_ONE_RUN)
--                 if self.isRespinOver then
--                     self.isRespinOver = false
--                 else
--                     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
--                 end
                
--             end
--         else
--             --TODO 佳宝 给与弹板玩家提示。。
--             gLobalViewManager:showReConnect()
--         end
--         return true
--     end
--     return false
-- end


function CodeGameScreenFortuneGodMachine:operaUserOutCoins( )
    --金币不足
    self.m_bSlotRunning = false
    CodeGameScreenFortuneGodMachine.super.operaUserOutCoins(self)
end

-- function CodeGameScreenFortuneGodMachine:setScatterDownScound( )
--     for i = 1, 5 do
--         local soundPath = "FortuneGodSounds/music_FortuneGod_scatter_down.mp3"
--         local soundPathBonus = "FortuneGodSounds/music_FortuneGod_bonus_down.mp3"
--         self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
--         self.m_bonusBulingSoundArry[#self.m_bonusBulingSoundArry + 1] = soundPathBonus
--     end
-- end

-- 特殊信号下落时播放的音效
-- function CodeGameScreenFortuneGodMachine:playScatterBonusSound(slotNode)
--     if slotNode ~= nil then

--         local iCol = slotNode.p_cloumnIndex
--         local soundPath = nil
--         local soundType = slotNode.p_symbolType
--         if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
--             if self.m_scatterBulingSoundArry == nil or not tolua.isnull(self.m_scatterBulingSoundArry) then
--                 return
--             end
            
--             self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1
--             if self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin] ~= nil then
--                 soundPath = self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin]
--             elseif self.m_scatterBulingSoundArry["auto"] ~= nil then
--                 soundPath = self.m_scatterBulingSoundArry["auto"]
--             else
--                 soundPath = self.m_scatterBulingSoundArry[1]
--             end
--         elseif  self:isFixSymbol(slotNode.p_symbolType) then
--             if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
--                 return
--             end
--             self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
--             if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
--                 soundPath = self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
--             elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
--                 soundPath = self.m_bonusBulingSoundArry["auto"]
--             else
--                 soundPath = self.m_bonusBulingSoundArry[1]
--             end
--         end

--         if soundPath then
--             self:playBulingSymbolSounds( iCol,soundPath,soundType )
--         end
--     end
-- end

function CodeGameScreenFortuneGodMachine:scaleMainLayer()
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
        
        if display.width / display.height >= 1024/768 and display.width / display.height <= 1228/768 then
            if display.width / display.height >= 1024/768 and display.width / display.height <= 960/640 then

                mainScale = 0.73 + 0.00042969 * (display.width - 1024)
            end
        else
            if display.width / display.height > 1228/768 and display.width / display.height <= 1370/768 then
                mainScale = 0.861 + 0.00084507 * (display.width - 1228)
            end
            self.m_machineNode:setPositionY(mainPosY)
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
    end
end

function CodeGameScreenFortuneGodMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if ("respin" == _sFeature and self.m_isBonusTrigger) or "free" == _sFeature then
        self.m_isBonusTrigger = false
        return
    end
    if CodeGameScreenFortuneGodMachine.super.levelDeviceVibrate then
        CodeGameScreenFortuneGodMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenFortuneGodMachine