---
-- island li
-- 2019年1月26日
-- CodeGameScreenBeatlesMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BeatlesBaseData = require "CodeBeatlesSrc.BeatlesBaseData"


local CodeGameScreenBeatlesMachine = class("CodeGameScreenBeatlesMachine", BaseNewReelMachine)
CodeGameScreenBeatlesMachine.MAIN_REEL_ADD_POS_Y = 10

CodeGameScreenBeatlesMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBeatlesMachine.COLLECT_NIUCOIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 牛币收集
CodeGameScreenBeatlesMachine.BOUNS_CHANGE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenBeatlesMachine.BOUNS_MODEL_MULTI = GameEffect.EFFECT_SELF_EFFECT + 1
CodeGameScreenBeatlesMachine.BOUNS_MODEL_LINE = GameEffect.EFFECT_SELF_EFFECT + 2
CodeGameScreenBeatlesMachine.BOUNS_MODEL_REPLACE = GameEffect.EFFECT_SELF_EFFECT + 3
CodeGameScreenBeatlesMachine.BOUNS_MODEL_REELS = GameEffect.EFFECT_SELF_EFFECT + 4
CodeGameScreenBeatlesMachine.BOUNS_MODEL_ADD = GameEffect.EFFECT_SELF_EFFECT + 5
CodeGameScreenBeatlesMachine.BOUNS_MODEL_MULTI_END = GameEffect.EFFECT_SELF_EFFECT + 6 -- 自定义动画的标识

CodeGameScreenBeatlesMachine.SYMBOL_BOUNS_NORMAL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  --94
CodeGameScreenBeatlesMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1  --9
CodeGameScreenBeatlesMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2  --10
CodeGameScreenBeatlesMachine.SYMBOL_WILD_REEL = 150
--SYMBOL_SCORE_1

-- 构造函数
function CodeGameScreenBeatlesMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    --初始化基本数据
    self.m_spinRestMusicBG = true
    self.m_clipNode = {}
    self.m_modes_tab = {}
    self.m_wild_reel = {}
    self.m_models_action = {}  --存储各个model玩法的动作节点
    self.m_base_line = 30 --基础线速
    self.m_cur_line = self.m_base_line --当前的线数
    self.m_mask_num = 0  --遮罩层需要的次数
    self.m_isChangeBaseBgMusic = false
    self.m_isQuitShow = false --是否跳过一些表现
    self.m_curModel_index = 0 --当前的触发的model索引
    self.m_model4_soundType = false  --玩法4音效是2个音效交替播放 bool值记录播放音效的两种状态  
    self.m_isCanTouch = true -- 商店入口是否可以点击
    self.isBounsChange_quick = false --收集bonus点击了快停
    self.isPlayActionMulti = false -- 成倍是否播放了触发动画
    self.m_freeSpinCoin = 0
    self.isMultiEndFly = false
    self.m_isReconnection = false--是否是重连轮

	--init
	self:initGame()
end

function CodeGameScreenBeatlesMachine:initGame()

	self:initMachine(self.m_moduleName)
    self.m_configData = gLobalResManager:getCSVLevelConfigData("BeatlesConfig.csv", "LevelBeatlesConfig.lua")
	
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBeatlesMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Beatles"  
end


function CodeGameScreenBeatlesMachine:initUI()

    self.m_line_left = util_createAnimation("Beatles_Base_lines_left.csb")
    self:findChild("node_lines_left"):addChild(self.m_line_left)
    self.m_line_left:playAction("idle2")
    self.m_line_left:findChild("Node_100"):setVisible(false)
   
    self.m_line_right = util_createAnimation("Beatles_Base_lines_right.csb")
    self:findChild("node_lines_right"):addChild(self.m_line_right)
    self.m_line_right:playAction("idle2")
    self.m_line_right:findChild("Node_100"):setVisible(false)

    local multi_plier = util_createView("CodeBeatlesSrc.BeatlesModeItem", 1)
    self:findChild("Multiplier"):addChild(multi_plier)
    self.m_modes_tab[1] = multi_plier --玩法1赢钱倍数

    local add_line = util_createView("CodeBeatlesSrc.BeatlesModeItem", 2)
    self:findChild("ExtraLines"):addChild(add_line)
    self.m_modes_tab[2] = add_line --玩法2添加线数

    local replaced = util_createView("CodeBeatlesSrc.BeatlesModeItem", 3)
    self:findChild("SymbolReplaced"):addChild(replaced)
    self.m_modes_tab[3] = replaced --玩法3改变小块

    local reel_wild = util_createView("CodeBeatlesSrc.BeatlesModeItem", 4)
    self:findChild("WildReels"):addChild(reel_wild)
    self.m_modes_tab[4] = reel_wild --玩法4整列wild

    local add_wild = util_createView("CodeBeatlesSrc.BeatlesModeItem", 5)
    self:findChild("WildsAdded"):addChild(add_wild)
    self.m_modes_tab[5] = add_wild --玩法5随机wild

    self.m_spinBar = util_createView("CodeBeatlesSrc/BeatlesFreespinBarView",self)
    self:findChild("node_SpinBar"):addChild(self.m_spinBar)
    self.m_spinBar:isChangeBase(true)

    self.m_LockWildNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_LockWildNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 2)

    --遮罩
    self.m_maskLayer = util_createAnimation("Beatles_Bonus_dark.csb")
    self.m_clipParent:addChild(self.m_maskLayer,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 2)
    self.m_maskLayer:setVisible(false)

    -- 大角色相关
    self.m_freeJueSe = util_createAnimation("Beatles_FreeGame_juese.csb")
    self:findChild("Node_FreeGame_juese"):addChild(self.m_freeJueSe)
    self.m_freeJueSe:setVisible(false)

    -- 连线
    self.m_linesNode = util_createAnimation("Socre_Beatles_Paylines.csb")
    self.m_clipParent:addChild(self.m_linesNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 101)
    local endWorldPos = self:findChild("Node_paylines"):getParent():convertToWorldSpace(cc.p(self:findChild("Node_paylines"):getPosition()))
    local endPos = self.m_clipParent:convertToNodeSpace(endWorldPos)
    self.m_linesNode:setPosition(endPos)
    self.m_linesNode:setVisible(false)

    -- 商店入口
    self.m_shopNode = util_createView("CodeBeatlesSrc.BeatlesShopEnterView",self)
    self:findChild("Node_shop"):addChild(self.m_shopNode)

    self.m_guoChang = util_spineCreate("Beatles_guochang", true, true)
    self:addChild(self.m_guoChang, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_guoChang:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_guoChang:setScale(self.m_machineRootScale)
    self.m_guoChang:setVisible(false)

    self.m_guoChang2 = util_spineCreate("Beatles_guochang2", true, true)
    self:addChild(self.m_guoChang2, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 2)
    self.m_guoChang2:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_guoChang2:setScale(self.m_machineRootScale)
    self.m_guoChang2:setVisible(false)

    --添加商店
    self.m_ShopView = util_createView("CodeBeatlesSrc.BeatlesShopMainView",self)
    self:addChild(self.m_ShopView,GAME_LAYER_ORDER.LAYER_ORDER_TOP-4)
    self.m_ShopView:setVisible(false)

    --主要会挂载一些动效相关的节点
    self.m_role_node = cc.Node:create()
    self.m_role_node:setPosition(display.width * 0.5, display.height * 0.5)
    self:findChild("root_ui"):addChild(self.m_role_node, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)

    for i = 1,8 do  --6这个节点给bouns收集玩法用 7 8 后加的特殊用
        self.m_models_action[i] = cc.Node:create()
        self.m_models_action[i]:setPosition(display.width * 0.5, display.height * 0.5)
        local ZOrder = GAME_LAYER_ORDER.LAYER_ORDER_TOP

        self:findChild("root_ui"):addChild(self.m_models_action[i], ZOrder)
    end

    self:findChild("node_FeatureTip"):setZOrder(GAME_LAYER_ORDER.LAYER_ORDER_TOP + 1)
    self:findChild("node_freegameover"):setZOrder(GAME_LAYER_ORDER.LAYER_ORDER_TOP)

    self.m_maskNodeTab = {}

    for col = 1,self.m_iReelColumnNum do
        --添加半透明遮罩
        local parentData = self.m_slotParents[col]
        local mask = cc.LayerColor:create(cc.c3b(0, 0, 0), parentData.reelWidth - 1 , parentData.reelHeight)
        mask:setOpacity(200)
        mask.p_IsMask = true--不被底层移除的标记
        mask:setPositionX(parentData.reelWidth/2)
        parentData.slotParent:addChild(mask,REEL_SYMBOL_ORDER.REEL_ORDER_1 + 100)
        table.insert(self.m_maskNodeTab,mask)
        mask:setVisible(false)
    end

    self:setReelBg(true)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                local isFreeSpinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
                if not isFreeSpinOver then
                    return
                end
            else
                return
            end
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 1
        local soundTime = 1
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
            soundTime = 2
        elseif winRate > 6 then
            soundIndex = 3
            soundTime = 2
        end
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if winRate <= 1 then
                soundIndex = 11
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 22
                soundTime = 2
            elseif winRate > 3 then
                soundIndex = 33
                soundTime = 2
            end
            local levels = self.m_runSpinResultData.p_selfMakeData.level
            local newFreeRoleId = {}
            if levels and #levels > 0 then
                for i,num in ipairs(levels) do
                    if i ~= 1 and num > 0 then
                        table.insert(newFreeRoleId, i-1)
                    end
                end
            end

            if #newFreeRoleId == 1 then
                local randomId = math.random(1,4)
                local sound_voice = string.format("BeatlesSounds/Sound_Beatles_role%d_voice%d.mp3", newFreeRoleId[1], randomId)
                gLobalSoundManager:playSound(sound_voice)
            end
        end
        local soundName = "BeatlesSounds/music_Beatles_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        -- if self.m_bProduceSlots_InFreeSpin then
        --     local bigWinRate = globalData.slotRunData.machineData:getBigWinRate()
        --     if winRate >= 3 and winRate < bigWinRate then
        --         local model_index = BeatlesBaseData:getInstance():getDataByKey("choose_index")
        --         for i,v in ipairs(model_index) do
        --             if v ~= 0 then
        --                 self.m_modes_tab[i]:playRoleOnomatopoetic()
        --             end
        --         end
        --     end
        -- end

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenBeatlesMachine:enterGamePlayMusic(  )
    self:playEnterGameSound("BeatlesSounds/music_Beatles_enter.mp3")
end

function CodeGameScreenBeatlesMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenBeatlesMachine:addObservers()
    BaseNewReelMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        --local betCoin = globalData.slotRunData:getCurTotalBet() or 0
        local betCoin = globalData.slotRunData:getCurTotalBet()
        local cur_coin = BeatlesBaseData:getInstance():getDataByKey("curBetValue")
        if tonumber(betCoin) ~= tonumber(cur_coin) then
            self:updataBeatlesCurBetData()
            self:changeBaseGameMusic(false)
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:qucikStopEffect()
    end,"QUICKSTOP_BEATLES")

    gLobalNoticManager:addObserver(self,function(self,params)
        self:qucik_BounsChange()
    end,"QUICKSTOP_BEATLES1")
end

function CodeGameScreenBeatlesMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()
    BeatlesBaseData:clear()
    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBeatlesMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_BOUNS_NORMAL then
        return "Socre_Beatles_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_Beatles_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_Beatles_11"
    elseif symbolType == self.SYMBOL_WILD_REEL then
        return "Socre_Beatles_WildReel"
    end    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBeatlesMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BOUNS_NORMAL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD_REEL,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenBeatlesMachine:MachineRule_initGame(  )
    self.m_isReconnection = true

    if not self.m_bProduceSlots_InFreeSpin then
        self:setReelBg(true)
    end
    if self.m_bProduceSlots_InFreeSpin then
        if self.m_runSpinResultData.p_features[2] and self.m_runSpinResultData.p_features[2] > 0 then
            if self.m_runSpinResultData.p_selfMakeData.level and #self.m_runSpinResultData.p_selfMakeData.level > 0 then
                self.m_ShopView:setVisible(true)
                self.m_ShopView:runCsbAction("idle",true)
            end
        else
            if self.m_runSpinResultData.p_selfMakeData.level and #self.m_runSpinResultData.p_selfMakeData.level > 0 then
                if self.m_runSpinResultData.p_selfMakeData.level[3] > 0 then
                    self:setLineCount(self.m_runSpinResultData.p_selfMakeData.store.storeData.buy_num["bonusType2"][self.m_runSpinResultData.p_selfMakeData.level[3]+1] + self.m_base_line, true)
                end
            end
            self.m_freeSpinCoin = self.m_runSpinResultData.p_fsWinCoins
        end
        self.m_spine_num = BeatlesBaseData:getInstance():getDataByKey("spin_num")
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenBeatlesMachine:slotOneReelDown(reelCol) 
    BaseNewReelMachine.slotOneReelDown(self,reelCol) 
    for k = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[k][reelCol]
        if symbolType == self.SYMBOL_BOUNS_NORMAL then
            local symbolNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
            if symbolNode.trailingNode then
                symbolNode.trailingNode:runCsbAction("over",false,function()
                    symbolNode.trailingNode:removeFromParent()
                    symbolNode.trailingNode = nil
                end)
                symbolNode:runAnim("buling")
            else
                symbolNode:runAnim("buling")
            end
            gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_bouns_buling.mp3")
        end
    end

end

function CodeGameScreenBeatlesMachine:slotOneReelDownFinishCallFunc( reelCol )

end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenBeatlesMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画

    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self.m_linesNode:setVisible(false)
    self.m_models_action[8]:removeAllChildren()

    self:runCsbAction("idle", false)
    self:setReelBg(false,"start")
    self.m_spinBar:isChangeBase(false)
    
    gLobalNoticManager:postNotification("MODEITEMNUM_NUMBAR", {active = false, levels = self.m_runSpinResultData.p_selfMakeData.level})

    if self.m_chooseLayer then
        self.m_chooseLayer:removeFromParent()
        self.m_chooseLayer = nil
    end
    self.m_models_action[1]:removeAllChildren()
    self:setSymbolToReel()
    
    self:changeShowDaJueSeFreeStart()

    local model_index = self.m_runSpinResultData.p_selfMakeData.level or {}
    for i,v in ipairs(model_index) do
        if i ~= 1 then
            if v ~= 0 then
                self:attempSetRoleTip(i-1)
                self.m_modes_tab[i-1]:showRoleLightIdle()
            end
        end
    end
    -- 商店进的free
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.level and #self.m_runSpinResultData.p_selfMakeData.level > 0 then
        self.m_bottomUI:showAverageBet()
    end

    if #self.m_wild_reel then
        for key,node in ipairs(self.m_wild_reel) do
            if node then
                node:runIdleAnim() 
            end
        end
    end
    
    -- free玩法下屏蔽商店入口
    self.m_shopNode:setVisible(false)
    self.m_shopNode.shopEnter:setVisible(false)
    self.m_shopNode.m_enter_feidie:setVisible(false)
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenBeatlesMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    BeatlesBaseData:getInstance():setDataByKey("shopNum", {1,0,0,0,0,0})
    self.m_freeSpinCoin = 0
    self.isMultiEndFly = false
    self.m_isQuitShow = false
    self:setLineCount(self.m_base_line, false)
    -- 商店进的free
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.level and #self.m_runSpinResultData.p_selfMakeData.level > 0 then
        self.m_bottomUI:hideAverageBet()
    end

    for i=1,5 do
        self.m_modes_tab[i]:showFreeIdle()
    end
end
---------------------------------------------------------------------------


----------- FreeSpin相关
---
function CodeGameScreenBeatlesMachine:showFreeSpinStart(num, levels, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    for roleId = 1, 5 do
        ownerlist["m_lb_num1_"..roleId] = roleId == 1 and levels[roleId+1].."X" or levels[roleId+1]
    end
    local view = nil

    if isAuto then
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    end

    return view

end

-- FreeSpinstart
function CodeGameScreenBeatlesMachine:showFreeSpinView(effectData)

    local showFreeSpinView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            effectData.p_isPlay = true
            self:playGameEffect()
        else
            if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.level and #self.m_runSpinResultData.p_selfMakeData.level > 0 then
                --从商店购买 进入的freespin
                self.freeStartFunc1 = function()
                    gLobalSoundManager:playSound("BeatlesSounds/sound_Beatles_guoChang_baseToFree.mp3")
                    self:showGuoChange("guochang","show1", function()

                        self:triggerFreeSpinCallFun()  
                        
                        if self.m_daJueSePos then
                            for id,num in ipairs(self.m_daJueSePos) do
                                if num > 0 then
                                    self.m_modes_tab[id].m_role:setVisible(false)
                                end
                            end
                        end
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

                    end, function()

                        if self.m_daJueSePos then
                            for i,num in ipairs(self.m_daJueSePos) do
                                if num > 0 then
                                    self.m_modes_tab[i].m_role:setVisible(true)
                                    util_spinePlay(self.m_modes_tab[i].m_role, "idleframe3_2", false)
                                    util_spineEndCallFunc(self.m_modes_tab[i].m_role, "idleframe3_2", function()
                                        util_spinePlay(self.m_modes_tab[i].m_role, "idleframe3", true)    
                                                
                                    end)
                                end
                                if i == #self.m_daJueSePos then
                                    if self.m_runSpinResultData.p_selfMakeData.level[3] > 0 then
                                        self:showEffectFree_BounsLine(effectData)
                                    else
                                        effectData.p_isPlay = true
                                        self:playGameEffect() 
                                    end
                                end  
                            end
                        else
                            effectData.p_isPlay = true
                            self:playGameEffect() 
                        end
                    end)

                end

                gLobalSoundManager:playSound("BeatlesSounds/music_Beatles_start_fs.mp3")
                self.m_chooseLayer = util_createView("CodeBeatlesSrc.BeatlesFreeStartView", self)
                self:addChild(self.m_chooseLayer,GAME_LAYER_ORDER.LAYER_ORDER_TOP-2)
 
                util_csbScale(self.m_chooseLayer.m_csbNode, self.m_machineRootScale)
                
            else
                self:waitWithDelay(1/30, function()
                    self:resetRole()
                    self:triggerFreeSpinCallFun()
                    for i=1,5 do
                        self.m_modes_tab[i].m_role:setVisible(false)
                    end
                end)

                self:waitWithDelay(28/30, function()
                    for i=1,5 do
                        util_spinePlay(self.m_modes_tab[i].m_role, "idleframe3_2", false)
                        self:waitWithDelay(2/30, function()
                            self.m_modes_tab[i].m_role:setVisible(true)
                        end)
                        util_spineEndCallFunc(self.m_modes_tab[i].m_role, "idleframe3_2", function()
                            self.m_modes_tab[i]:showFreeIdle()          
                        end)
                    end

                    effectData.p_isPlay = true
                    self:playGameEffect()  
                    
                end)
            end
            
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    -- performWithDelay(self,function(  )
            showFreeSpinView()    
    -- end,0.5)

end

function CodeGameScreenBeatlesMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("BeatlesSounds/music_Beatles_over_fs.mp3")
    for key,node in ipairs(self.m_wild_reel) do
        node:runIdleAnim() 
    end
    self:clearWinLineEffect()
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()

        gLobalSoundManager:playSound("BeatlesSounds/sound_Beatles_guoChang_freeToBase.mp3")
        self:showGuoChange("guochang2","show2", function()

            self:changeShowDaJueSeFreeOver()
                -- 打开商店入口
            self.m_shopNode:setVisible(true)
            self.m_shopNode.shopEnter:setVisible(true)
            self.m_shopNode.m_enter_feidie:setVisible(true)
        end, function()
            self:triggerFreeSpinOverCallFun()
        end)
    end)
    local node=view:findChild("m_lb_coins")
    if node then
        view:updateLabelSize({label=node,sx=1,sy=1},654)
        util_changeNodeParent(self:findChild("node_freegameover"), view)
    end
end

function CodeGameScreenBeatlesMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    self.m_models_action[8]:removeAllChildren()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

    if coins == "0" then
        return self:showDialog("FreeSpinOver_NoWins",ownerlist,func)
    else
        --
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER,ownerlist,func)
    end

    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenBeatlesMachine:showDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("CodeBeatlesSrc.BeatlesBaseDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(view)
    return view
end

--隐藏盘面信息
function CodeGameScreenBeatlesMachine:setReelSlotsNodeVisible(status)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:setVisible(status)
            end
        end
    end
    if #self.m_wild_reel then
        for key,node in ipairs(self.m_wild_reel) do
            if node then
                node:setVisible(status)
            end
        end
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBeatlesMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume( )

    if self.m_ShopView:isVisible() then
        self:showOpenOrCloseShop(false)
    end

    self.m_isCanTouch = false
    self.m_linesNode:setVisible(false)
    self.m_models_action[8]:removeAllChildren()

    self:stopLinesWinSound( )
    -- self:qucik_BounsChange()
    self.isBounsChange_quick = false
    if not self.m_bProduceSlots_InFreeSpin then

        local waitNode = self.m_models_action[1]
        waitNode:stopAllActions()
        waitNode:removeAllChildren()  

    end

    return false -- 用作延时点击spin调用
    
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenBeatlesMachine:addSelfEffect()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    self.m_mask_num = 0
    if selfdata.bonusTransfer then --收集玩法次数
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BOUNS_CHANGE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BOUNS_CHANGE_EFFECT -- 动画类型
    end

    if selfdata.changeSignals then  --替换小块
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BOUNS_MODEL_REPLACE
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BOUNS_MODEL_REPLACE -- 动画类型
        self.m_mask_num  = self.m_mask_num + 1
    end

    if selfdata.fullWilds then --整列小块
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BOUNS_MODEL_REELS
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BOUNS_MODEL_REELS -- 动画类型
        self.m_mask_num  = self.m_mask_num + 1
    end

    if selfdata.randomWilds then --随机小块
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BOUNS_MODEL_ADD
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BOUNS_MODEL_ADD -- 动画类型
        self.m_mask_num  = self.m_mask_num + 1
    end

    if not self.m_bProduceSlots_InFreeSpin then
        if selfdata.winLinesNum then --添加线数
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.BOUNS_MODEL_LINE
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BOUNS_MODEL_LINE -- 动画类型
            self.m_mask_num  = self.m_mask_num + 1
        end
    end

    if selfdata.winMultiple then --赢钱乘倍
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BOUNS_MODEL_MULTI
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BOUNS_MODEL_MULTI -- 动画类型
        BeatlesBaseData:getInstance():setDataByKey("multi", selfdata.winMultiple)
        self.m_mask_num  = self.m_mask_num + 1
        if self.m_bProduceSlots_InFreeSpin then
            local newCoin = self.m_runSpinResultData.p_fsWinCoins - self.m_freeSpinCoin
            self.m_freeSpinCoin = self.m_runSpinResultData.p_fsWinCoins
            if newCoin > 0 then
                self.isMultiEndFly = true
            end
        else
            local newCoin = self.m_runSpinResultData.p_winAmount
            if newCoin > 0 then
                self.isMultiEndFly = true
            end
        end
        local selfEffect = GameEffectData.new() --赢钱乘倍结束
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BOUNS_MODEL_MULTI_END
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BOUNS_MODEL_MULTI_END -- 动画类型
        self.m_mask_num  = self.m_mask_num + 1
        
    end

    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.store 
        and self.m_runSpinResultData.p_selfMakeData.store.score and #self.m_runSpinResultData.p_selfMakeData.store.score > 0 then
        local selfEffect = GameEffectData.new() --收集牛币
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_NIUCOIN_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_NIUCOIN_EFFECT
    end

    

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBeatlesMachine:MachineRule_playSelfEffect(effectData)

    --收集猪猪币
    if effectData.p_selfEffectType == self.COLLECT_NIUCOIN_EFFECT then
        self:collectSymbolIconFly(effectData)
    elseif effectData.p_selfEffectType == self.BOUNS_CHANGE_EFFECT then
        self:showEffect_BounsChange(effectData)
    elseif effectData.p_selfEffectType == self.BOUNS_MODEL_MULTI then
        self:showModelsTip(1, function()
            self:showEffect_BounsMulti(effectData)
        end)
    elseif effectData.p_selfEffectType == self.BOUNS_MODEL_LINE then
        self:showModelsTip(2, function()
            self:showEffect_BounsLine(effectData)
        end)
    elseif effectData.p_selfEffectType == self.BOUNS_MODEL_REPLACE then
        self:showModelsTip(3, function()
            self:showEffect_BounsReplace(effectData)
        end)
    elseif effectData.p_selfEffectType == self.BOUNS_MODEL_REELS then
        self:showModelsTip(4, function()
            self:showEffect_BounsReel(effectData)
        end)
    elseif effectData.p_selfEffectType == self.BOUNS_MODEL_ADD then
        self:showModelsTip(5, function()
            self:showEffect_BounsAdd(effectData)
        end)
    elseif effectData.p_selfEffectType == self.BOUNS_MODEL_MULTI_END then
        self:showEffect_BounsMultiEnd(effectData) 
    end

	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBeatlesMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

---
-- 处理spin 返回结果
function CodeGameScreenBeatlesMachine:spinResultCallFun(param)
    --dump(param,"spinResultCallFun", 8)
    BaseNewReelMachine.spinResultCallFun(self, param)
end

function CodeGameScreenBeatlesMachine:initGameStatusData(gameData)
    BaseNewReelMachine.initGameStatusData(self, gameData)
    if gameData.special then --商店购买之后断线重连的数据
        self.m_runSpinResultData.p_features = gameData.special.features
        if gameData.special.freespin ~= nil then
            self.m_runSpinResultData.p_freeSpinsTotalCount = gameData.special.freespin.freeSpinsTotalCount -- fs 总数量
            self.m_runSpinResultData.p_freeSpinsLeftCount = gameData.special.freespin.freeSpinsLeftCount -- fs 剩余次数
            self.m_runSpinResultData.p_fsMultiplier = gameData.special.freespin.fsMultiplier -- fs 当前轮数的倍数
            self.m_runSpinResultData.p_freeSpinNewCount = gameData.special.freespin.freeSpinNewCount -- fs 增加次数
            self.m_runSpinResultData.p_fsWinCoins = gameData.special.freespin.fsWinCoins -- fs 累计赢钱数量
            self.m_runSpinResultData.p_freeSpinAddList = gameData.special.freespin.freeSpinAddList
            self.m_runSpinResultData.p_newTrigger = gameData.special.freespin.newTrigger
            self.m_runSpinResultData.p_fsExtraData = gameData.special.freespin.extra
        end

        self.m_runSpinResultData.p_selfMakeData = gameData.special.selfData

        self.m_initSpinData = self.m_runSpinResultData
    end

    if gameData.feature then --5选1断线重连之后的数据
        self.m_runSpinResultData.p_features = gameData.feature.features
        if gameData.feature.freespin ~= nil then
            self.m_runSpinResultData.p_freeSpinsTotalCount = gameData.feature.freespin.freeSpinsTotalCount -- fs 总数量
            self.m_runSpinResultData.p_freeSpinsLeftCount = gameData.feature.freespin.freeSpinsLeftCount -- fs 剩余次数
            self.m_runSpinResultData.p_fsMultiplier = gameData.feature.freespin.fsMultiplier -- fs 当前轮数的倍数
            self.m_runSpinResultData.p_freeSpinNewCount = gameData.feature.freespin.freeSpinNewCount -- fs 增加次数
            self.m_runSpinResultData.p_fsWinCoins = gameData.feature.freespin.fsWinCoins -- fs 累计赢钱数量
            self.m_runSpinResultData.p_freeSpinAddList = gameData.feature.freespin.freeSpinAddList
            self.m_runSpinResultData.p_newTrigger = gameData.feature.freespin.newTrigger
            self.m_runSpinResultData.p_fsExtraData = gameData.feature.freespin.extra
        end

        self.m_runSpinResultData.p_selfMakeData = gameData.feature.selfData

        self.m_initSpinData = self.m_runSpinResultData
    end

    --dump(gameData, "initGameStatusData", 8)
    local gameConfig = gameData.spin and gameData.spin.selfData or nil
    local storeData = gameData.gameConfig.extra or nil
    if gameConfig and gameConfig.extra then
        local bonusMode = gameConfig.extra
        if bonusMode then
            for k,v in pairs(bonusMode) do
                if v.spinTimes == 10 then
                    bonusMode[k].spinTimes = 0
                end
            end
            BeatlesBaseData:getInstance():setDataByKey("bonusMode", bonusMode)
        end
    end
    if storeData and storeData.store and storeData.store.storeData then
        BeatlesBaseData:getInstance():setDataByKey("storeData", storeData.store.storeData)
    end 

    if gameConfig and gameConfig.store then
        local store = gameConfig.store
        self.m_runSpinResultData.p_selfMakeData.store.score = {} --断线重连 重置牛牛币数据
        if store then
            self:setWaiXingNiuCoin(false,store.coins)
        else
            self:setWaiXingNiuCoin(false,0)
        end
    else
        self:setWaiXingNiuCoin(false,0)
    end
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    
    if selfdata.freetype then --base下触发的5选1free玩法 freetype表示选择的哪种玩法从0到4，需要处理成1到5
        local chooseIndexList = {0, 0, 0, 0, 0}
        chooseIndexList[tonumber(selfdata.freetype)+1] = 1
        BeatlesBaseData:getInstance():setDataByKey("choose_index", chooseIndexList)
    end
    if selfdata.level then--商店购买的玩法1表示买的free次数，2到6才是玩法，处理成1到5；base下触发5选1free玩法 没有这个字段，只在商店玩法才有
        local chooseIndexList = {}
        for i,v in ipairs(selfdata.level) do
            if i ~= 1 then
                chooseIndexList[i-1] = v
            end
        end
        BeatlesBaseData:getInstance():setDataByKey("choose_index", chooseIndexList)
    end 

end

function CodeGameScreenBeatlesMachine:enterLevel()
    BaseNewReelMachine.enterLevel(self)
    self:updataBeatlesCurBetData()
end

function CodeGameScreenBeatlesMachine:updataBeatlesCurBetData( )
    local action_node = self.m_models_action[6]
    action_node:stopAllActions()
    action_node:removeAllChildren()
    local betValue = globalData.slotRunData:getCurTotalBet()
    BeatlesBaseData:getInstance():setCurBetValue(tostring(betValue))
    
    --更新modeItem的num
    if not self.m_bProduceSlots_InFreeSpin then
        self.m_spine_num = BeatlesBaseData:getInstance():getDataByKey("spin_num")
        self.m_spinBar:updateSpinNum(self.m_spine_num)

        gLobalNoticManager:postNotification("MODEITEMNUM_BEATLES")
    end
end

function CodeGameScreenBeatlesMachine:waitWithDelay(time, endFunc, parent)
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        
        waitNode:removeFromParent()
    end, time)
end

--设置牛币的数量
function CodeGameScreenBeatlesMachine:setWaiXingNiuCoin(isPlayAni,coinNum)
    if isPlayAni == nil then
        isPlayAni = false
    end
    local num = 0
    if coinNum then
        num = coinNum
    end

    self.m_shopNode:setWaiXingNiuCoin(num)
end

-- 收集动画
function CodeGameScreenBeatlesMachine:collectSymbolIconFly(effectData)
    gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_coin_fly.mp3")
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.store 
        and self.m_runSpinResultData.p_selfMakeData.store.score and #self.m_runSpinResultData.p_selfMakeData.store.score > 0 then
        local posTable = self.m_runSpinResultData.p_selfMakeData.store.score
        local isUpdateCoins = true--是否更新牛币显示数量
        local currCoinNum = self.m_runSpinResultData.p_selfMakeData.store.coins or 0
        
        for posStr, coinNum in pairs(posTable) do
            if coinNum > 0 then
                local rowColData = self:getRowAndColByPos(tonumber(posStr)-1)
                local symbolNode = self:getFixSymbol(rowColData.iY , rowColData.iX, SYMBOL_NODE_TAG)
                if symbolNode and symbolNode.m_icon then
                    --创建上飞的猪猪币
                    local flyCoin = util_createAnimation("Socre_Beatles_SymbolCoins.csb")
                    flyCoin:findChild("num"):setString(coinNum)
                    self:addChild(flyCoin, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                    flyCoin:runCsbAction("shouji",false)
                    local startPos = cc.p(util_getConvertNodePos(symbolNode.m_icon, flyCoin))
                    flyCoin:setPosition(startPos)
                    
                    self:waitWithDelay(20/60, function()
                        --添加拖尾
                        -- local tuowei = util_createAnimation("Beatles_SymbolCoins_tuowei.csb")
                        -- flyCoin:addChild(tuowei,-1)
                        if flyCoin:findChild("Particle_1") then
                            flyCoin:findChild("Particle_1"):setDuration(500)
                            flyCoin:findChild("Particle_1"):setPositionType(0)
                            flyCoin:findChild("Particle_1"):resetSystem()
                        end

                        local endWorldPos = self.m_shopNode.m_enterCoin:findChild("m_lb_coins"):getParent():convertToWorldSpace(cc.p(self.m_shopNode.m_enterCoin:findChild("m_lb_coins"):getPosition()))
                        local endPos = self:convertToNodeSpace(endWorldPos)
                        local delay = cc.DelayTime:create(10/60)
                        local move = cc.MoveTo:create(20/60,endPos)
                        local call = cc.CallFunc:create(function ()
                            if flyCoin:findChild("Particle_1") then
                                flyCoin:findChild("Particle_1"):stopSystem()
                            end
                            flyCoin:findChild("Sprite_1"):setVisible(false)
                            self:waitWithDelay(0.5, function()
                                flyCoin:removeFromParent()
                            end)
                            if isUpdateCoins then
                                isUpdateCoins = false
                                self:setWaiXingNiuCoin(true,currCoinNum)
                                
                                util_spinePlay(self.m_shopNode.shopEnter, "shouji", false)
                                util_spineEndCallFunc(self.m_shopNode.shopEnter, "shouji", function()
                                    util_spinePlay(self.m_shopNode.shopEnter, "idleframe", true)
                                end)
                                self.m_shopNode.m_enter_feidie:playAction("shouji", false, function()
                                    self.m_shopNode.m_enter_feidie:playAction("idleframe")
                                end)
                                gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_coin_collect.mp3")
                            end
                        end)

                        local seq = cc.Sequence:create(delay,move,call)
                        flyCoin:runAction(seq)

                        if symbolNode.m_icon and symbolNode.m_icon.stopAllActions and symbolNode.m_icon.removeFromParent then
                            symbolNode.m_icon:stopAllActions()
                            symbolNode.m_icon:removeFromParent()
                            symbolNode.m_icon = nil
                        end
                    end)
                    
                else

                end
            end
        end
    end

    effectData.p_isPlay = true
    self:playGameEffect()
end

function CodeGameScreenBeatlesMachine:showEffect_BounsChange(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.bonusTransfer then
        local bonusTransfer = {}
        local total_count = 0
        local cur_index = 1 

        bonusTransfer = selfdata.bonusTransfer
        total_count = #bonusTransfer
 
        local waitNode = self.m_models_action[6]
        local isSkip = false 
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local features = self.m_runSpinResultData.p_features or {}
        if  globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE or #features >= 2 then
            isSkip = true
        end

        local collectNum = {} -- 收集的方法集合
        for key,value in ipairs(bonusTransfer) do
            if collectNum[value[2]] then
                table.insert(collectNum[value[2]], value[1])
            else
                collectNum[value[2]] = {}
                table.insert(collectNum[value[2]], value[1])
            end
        end

        local temp_index = 0
        self:waitWithDelay(0.2, function()
            gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_niu_fly.mp3")
            for k,v in pairs(collectNum) do
                self:waitWithDelay(1, function()
                    self.m_modes_tab[tonumber(k)+1]:playRoleVoice()
                end, waitNode)
            end
            for key,value in ipairs(bonusTransfer) do
                temp_index = temp_index + 1
                
                local temp_data = value --1是位置  2是对应的方法
                local pos = self:getRowAndColByPos(temp_data[1])
                local targSpNode = self:getFixSymbol(pos.iY , pos.iX , SYMBOL_NODE_TAG)

                if targSpNode and targSpNode.p_symbolType then

                    local index = temp_data[2]+1 or 0
                    local mode = self.m_modes_tab[index]
                    if index > 0 then
                        local rowIndex = pos.iX
                        if pos.iX == 1 then
                            rowIndex = 3
                        elseif pos.iX == 3 then
                            rowIndex = 1
                        end
                        local ani_str = "shouji"..rowIndex
                        targSpNode:runAnim("idleframe2")
                        local start_worldPos = targSpNode:getParent():convertToWorldSpace(cc.p(targSpNode:getPosition()))
                        local start_pos = self.m_models_action[7]:convertToNodeSpace(start_worldPos)
                        local flyNui = util_spineCreate("Socre_Beatles_Bonus2", true, true)
                        self.m_models_action[7]:addChild(flyNui, 5)
                        flyNui:setPosition(start_pos)
                        util_spinePlay(flyNui, ani_str, false)

                        self:setRoleToTip(mode)
                        util_spinePlay(mode.m_role, "shouji", false)
                        util_spineEndCallFunc(mode.m_role, "shouji", function()
                            mode:showFreeIdle()
                            flyNui:removeFromParent()
                        end)
                        self:waitWithDelay(1, function()
                            if temp_index == total_count then
                                gLobalSoundManager:playSound("BeatlesSounds/sound_Beatles_niu_collect.mp3")
                                if isSkip then
                                    local time = 0
                                    --触发收集小游戏 播放完收集
                                    if #features >= 2 then 
                                        time = 2
                                    end
                                    self:waitWithDelay(time, function()
                                        effectData.p_isPlay = true
                                        self:playGameEffect()
                                    end, waitNode)
                                end
                                if not self.isBounsChange_quick then
                                    for k,v in pairs(collectNum) do
                                        gLobalNoticManager:postNotification("MODEITEMUPDATA_BEATLES_"..(k+1))
                                    end
                                    
                                end
                            end
                        end, waitNode)
                    end
                end
            end
            if not isSkip then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end, waitNode)

    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

---
--设置bonus scatter 层级
function CodeGameScreenBeatlesMachine:getBounsScatterDataZorder(symbolType )
    local order = BaseNewReelMachine.getBounsScatterDataZorder(self,symbolType)
    if symbolType == self.SYMBOL_BOUNS_NORMAL then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == self.SYMBOL_WILD_REEL then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_3 + 1
    end
    return order
end

--将图标提层
function CodeGameScreenBeatlesMachine:setSymbolToClip(slotNode, order)
    if tolua.isnull(slotNode) or not slotNode.p_symbolType then
        return
    end
    local nodeParent = slotNode:getParent()
    slotNode.m_preParent = nodeParent
    slotNode.m_showOrder = slotNode:getLocalZOrder()
    slotNode.m_preX = slotNode:getPositionX()
    slotNode.m_preY = slotNode:getPositionY()
    slotNode.m_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.m_preX, slotNode.m_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent(false)
    -- 切换图层
    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    local z_order = order
    if not z_order then
        z_order = self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex + slotNode.p_cloumnIndex * 10
    end
    self.m_clipParent:addChild(slotNode, z_order)
    
    local isAdd = true
    for i,v in ipairs(self.m_clipNode) do
        if v.p_rowIndex == slotNode.p_rowIndex and v.p_cloumnIndex == slotNode.p_cloumnIndex then
            isAdd = false
        end
    end
    if isAdd then
        self.m_clipNode[#self.m_clipNode + 1] = slotNode
    end

    local linePos = {}
    linePos[#linePos + 1] = {iX = slotNode.p_rowIndex, iY = slotNode.p_cloumnIndex}
    slotNode:setLinePos(linePos)
end
--将图标恢复到轮盘层
function CodeGameScreenBeatlesMachine:setSymbolToReel()
    for i, slotNode in ipairs(self.m_clipNode) do
        if slotNode.p_symbolType ~= self.SYMBOL_WILD_REEL then
            util_setClipReelSymbolToBaseParent(self,slotNode)
        end
    end
    self.m_clipNode = {}

end

--节点提层 
function CodeGameScreenBeatlesMachine:setRoleToTip(item)
    local nodeParent = item:getParent()
    item.m_preParent = nodeParent
    item.m_showOrder = item:getLocalZOrder()
    item.m_preX = item:getPositionX()
    item.m_preY = item:getPositionY()
    local pos = nodeParent:convertToWorldSpace(cc.p(item.m_preX, item.m_preY))
    pos = self.m_role_node:convertToNodeSpace(pos)
    util_changeNodeParent(self.m_role_node, item, item.m_showOrder)
    item:setPosition(pos.x, pos.y)
end

--节点提层 
function CodeGameScreenBeatlesMachine:setLineToTip(item)
    local nodeParent = item:getParent()
    item.m_preParent = nodeParent
    item.m_showOrder = item:getLocalZOrder()
    item.m_preX = item:getPositionX()
    item.m_preY = item:getPositionY()
    local pos = nodeParent:convertToWorldSpace(cc.p(item.m_preX, item.m_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    util_changeNodeParent(self.m_clipParent, item, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 3)
    item:setPosition(pos.x, pos.y)
end

--角色复原
function CodeGameScreenBeatlesMachine:resetRole()
    for rolePos = 1, 5 do
        local item = self.m_modes_tab[rolePos]
        local preParent = item.m_preParent
        if preParent ~= nil then
            local nZOrder = item.m_showOrder
            item:setPosition(item.m_preX, item.m_preY)
            item:hideLight()
            item:playerRoleIdle()
            util_changeNodeParent(preParent, item, nZOrder)
            item.m_preParent = nil
        end
    end
end

--角色复原到最开始的时候
function CodeGameScreenBeatlesMachine:resetBeginRole()
    for rolePos = 1, 5 do
        local item = self.m_modes_tab[rolePos]
        item:setVisible(true)
        local preParent = item.m_preParent
        -- if preParent ~= nil then
            local nZOrder = 0
            item:setPosition(cc.p(0, 0))
            item:hideLight()
            -- item:playerRoleIdle()
            if rolePos == 1 then
                util_changeNodeParent(self:findChild("Multiplier"), item, nZOrder)
            elseif rolePos == 2 then
                util_changeNodeParent(self:findChild("ExtraLines"), item, nZOrder)
            elseif rolePos == 3 then
                util_changeNodeParent(self:findChild("SymbolReplaced"), item, nZOrder)
            elseif rolePos == 4 then
                util_changeNodeParent(self:findChild("WildReels"), item, nZOrder)
            elseif rolePos == 5 then
                util_changeNodeParent(self:findChild("WildsAdded"), item, nZOrder)
            end
            item.m_preParent = nil
        -- end
    end
end

--回归原处
function CodeGameScreenBeatlesMachine:reBackNode(node)
    local preParent = node.m_preParent
    if preParent ~= nil then
        local nZOrder = node.m_showOrder
        node:setPosition(node.m_preX, node.m_preY)
        util_changeNodeParent(preParent, node, nZOrder)
        node.m_preParent = nil
    end
end

--轮盘滚动显示遮罩
function CodeGameScreenBeatlesMachine:beginReelShowMask()
    for i,maskNode in ipairs(self.m_maskNodeTab) do
        if maskNode:isVisible() == false then
            maskNode:setVisible(true)
            maskNode:setOpacity(0)
            maskNode:runAction(cc.FadeTo:create(0.5,150))
        end
    end
end
--轮盘停止隐藏遮罩
function CodeGameScreenBeatlesMachine:reelStopHideMask(actionTime, col)
    local maskNode = self.m_maskNodeTab[col]
    local fadeAct = cc.FadeTo:create(actionTime,0)
    local func = cc.CallFunc:create(function ()
        maskNode:setVisible(false)
    end)
    maskNode:runAction(cc.Sequence:create(fadeAct,func))
end

function CodeGameScreenBeatlesMachine:beginReel()
    
    if self.m_bProduceSlots_InFreeSpin == false then
        self:setLineCount(self.m_base_line, false)

        self.m_spine_num  = self.m_spine_num + 1
        if self.m_spine_num > 10 then
            self.m_spine_num = 1
            self:resetRole()
            self:changeBaseGameMusic(false)
        elseif self.m_spine_num == 10 then
            self:changeBaseGameMusic(true)
        end
        if self.m_spine_num == 1 or self.m_spine_num > 7 then
            local spine_num = self.m_spine_num
            gLobalNoticManager:postNotification("SPINEBAR_NUM_BEATLES", spine_num)
        end
        if self.m_spine_num == 1 then
            self:changeBaseGameMusic(false)
            self:resetBeginRole()
        end
        self.m_spinBar:updateSpinNum(self.m_spine_num)
        for i=1,5 do
            local action_node = self.m_models_action[i]
            action_node:stopAllActions()
            action_node:removeAllChildren()
        end
    end
    self.m_curModel_index = 0
    self.m_isQuitShow = false 
    self.m_isReconnection = false--是否是重连轮
    self.isPlayActionMulti = false -- 成倍是否播放了触发动画
    self.isMultiEndFly = false
    
    if (not self.m_bProduceSlots_InFreeSpin) then
        if self.m_spine_num < 10 then
            self:beginReelShowMask()
        end
    end

    self:clearReelWild()
    self:clearNormalWild()
    self:setSymbolToReel()
    BaseNewReelMachine.beginReel(self)
end

----
--- 处理spin 成功消息
--
function CodeGameScreenBeatlesMachine:checkOperaSpinSuccess( param )
    -- 触发了玩法 一定概率播特效
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self.m_spine_num == 10 then
        gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_base_num10.mp3")
        self:showTip(function()
            CodeGameScreenBeatlesMachine.super.checkOperaSpinSuccess(self,param)
            if param[2] and param[2].action == "SPIN" then --更新数据  没有提前处理是因为需要配合一些动效
                local result = param[2].result
                if result and result.selfData then
                    local temp_data = result.selfData
                    local bonusMode = temp_data.bonusMode
                    if bonusMode then
                        self.m_spine_num = bonusMode.spinTimes or 0
                        local temp_spin_num = self.m_spine_num < 10 and self.m_spine_num or 0
                        BeatlesBaseData:getInstance():setSpinNum(temp_spin_num)
                        self.m_spinBar:updateSpinNum(self.m_spine_num)
                        local modes = bonusMode.modes
                        BeatlesBaseData:getInstance():initModes(modes)
                    end
                end
            end
        end)
    elseif self.m_bProduceSlots_InFreeSpin == true  then
        CodeGameScreenBeatlesMachine.super.checkOperaSpinSuccess(self,param)
    else
        if param[2] and param[2].action == "SPIN" then
            local result = param[2].result
            if result and result.selfData then
                local temp_data = result.selfData
                local bonusMode = temp_data.bonusMode
                if bonusMode then
                    self.m_spine_num = bonusMode.spinTimes or 0
                    local temp_spin_num = self.m_spine_num < 10 and self.m_spine_num or 0
                    BeatlesBaseData:getInstance():setSpinNum(temp_spin_num)
                    self.m_spinBar:updateSpinNum(self.m_spine_num)
                    local modes = bonusMode.modes
                    BeatlesBaseData:getInstance():initModes(modes)
                end
            end
        end
        CodeGameScreenBeatlesMachine.super.checkOperaSpinSuccess(self,param)
    end
end

function CodeGameScreenBeatlesMachine:showEffect_BounsMulti(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.winMultiple then
        -- if self.m_iOnceSpinLastWin > 0 or self.m_bProduceSlots_InFreeSpin == false then
        --     self:attemptShowMask()
        -- end
        self:attemptShowMask()
        self:attempSetRoleTip(1)
        if self:isQucikStop() then
            self:attemptHideMask()
            self:qucik_BounsMulti()
            local qucik_tiem = 0
            
            self:waitWithDelay(qucik_tiem, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
            return
        end
        local waitNode = self.m_models_action[1]
        local mode = self.m_modes_tab[1]
        local feature = mode:getFeatureNum()
        local multi = BeatlesBaseData:getInstance():getDataByKey("multi")
        local act_list = {}
        act_list[#act_list + 1] = cc.DelayTime:create(0.5)

        if self.isPlayActionMulti == false then
            local funCallBack = function()
                local mode_role = self.m_modes_tab[1].m_role
                gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role1_start.mp3")
                util_spinePlay(mode_role, "actionframe", false)
                util_spineEndCallFunc(mode_role, "actionframe", function()
                    util_spinePlay(mode_role, "idleframe4", true)
                    self.isPlayActionMulti = true
                end)
                local multiNode = util_createAnimation("Beatles_fonts_multiplier.csb")
                local start_worldPos = mode:findChild("BitmapFontLabel_1"):getParent():convertToWorldSpace(cc.p(mode:findChild("BitmapFontLabel_1"):getPosition()))
                local start_pos = waitNode:convertToNodeSpace(start_worldPos)

                waitNode:addChild(multiNode, 2)
                multiNode:findChild("BitmapFontLabel_1"):setString(string.format("%dX", selfdata.winMultiple))
                multiNode:setPosition(start_pos)
                multiNode:setName("multiNode")
                multiNode:playAction("start",false,function()
                    multiNode:playAction("idle",true)
                end)
            end

            if not waitNode:getChildByName("multiNode") then
                if self:getFreePlayerNum() then
                    act_list[#act_list + 1] = cc.CallFunc:create(function()
                        local random = math.random(1,2)
                        gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role1_tips"..random..".mp3")
                        self:showModelsFreeTip(1, function()
                            funCallBack()
                        end)
    
                    end)
                    act_list[#act_list + 1] = cc.DelayTime:create(2.5)
                else
                    funCallBack()
                end
            end
        end
            

        act_list[#act_list + 1] = cc.CallFunc:create(function()
            effectData.p_isPlay = true
            self:attemptHideMask()
            self:playGameEffect()
            
        end)

        if self.m_bProduceSlots_InFreeSpin and selfdata.winLinesNum then
            self:setLineCount(selfdata.winLinesNum + self.m_base_line, true)
        end
        waitNode:runAction(cc.Sequence:create(act_list))
    else
        effectData.p_isPlay = true
        self:attemptHideMask()
        self:playGameEffect()
    end

end

function CodeGameScreenBeatlesMachine:showEffect_BounsReplace(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.changeSignals then
        self:attemptShowMask()
        self:attempSetRoleTip(3)
        if self:isQucikStop() then
            self:qucik_BounsReplace()
            self:attemptHideMask()
            effectData.p_isPlay = true
            self:playGameEffect()
            return
        end
        local waitNode = self.m_models_action[3]
        local changeSignals = selfdata.changeSignals
        local count = #changeSignals
        local mode_role = self.m_modes_tab[3].m_role
        -- mode_role:stopAllActions()
        local start_worldPos = self:findChild("jiguangNode"):getParent():convertToWorldSpace(cc.p(self:findChild("jiguangNode"):getPosition()))
        local start_pos = waitNode:convertToNodeSpace(start_worldPos)

        local yuGaoNodeTable = {}--临时存储 预告框
        local newSpineRole = util_spineCreate("BeatleBeat_juese_3", true, true)
        local newSpineRoleWorldPos = self:findChild("root_ui"):getParent():convertToWorldSpace(cc.p(self:findChild("root_ui"):getPosition()))
        local newSpineRolePos = waitNode:convertToNodeSpace(newSpineRoleWorldPos)
        waitNode:addChild(newSpineRole)
        newSpineRole:setPosition(newSpineRolePos)
        newSpineRole:setVisible(false)

        local funCallBack = function()
            local newSpineRoleAction = {}
            local newSpineRoleDelay = {}
            for key,value in ipairs(changeSignals) do
                if count <= 1 then
                    newSpineRoleAction[key] = "actionframe_6"
                    newSpineRoleDelay[key] = 0
                elseif count == 2 then
                    if key == 1 then
                        newSpineRoleAction[key] = "actionframe_2"
                        newSpineRoleDelay[key] = 0
                    else
                        newSpineRoleAction[key] = "actionframe_4"
                        newSpineRoleDelay[key] = newSpineRole:getAnimationDurationTime(newSpineRoleAction[key-1])
                    end
                else
                    if key == count then
                        newSpineRoleAction[key] = "actionframe_4"
                        newSpineRoleDelay[key] = newSpineRole:getAnimationDurationTime(newSpineRoleAction[key-1])+newSpineRoleDelay[key-1]
                    elseif key == 1 then
                        newSpineRoleAction[key] = "actionframe_2"
                        newSpineRoleDelay[key] = 0
                    else
                        newSpineRoleAction[key] = "actionframe_3"
                        newSpineRoleDelay[key] = newSpineRole:getAnimationDurationTime(newSpineRoleAction[key-1])+newSpineRoleDelay[key-1]
                    end
                end
            end

            gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role3_start.mp3")
            util_spinePlay(mode_role, "actionframe", false)
            util_spineFrameCallFunc(mode_role, "actionframe", "switch", function()

                for key,value in ipairs(changeSignals) do
                    local delay_time = newSpineRoleDelay[key]
                    local temp_index = key
                    local temp_value = value

                    self:waitWithDelay(delay_time,function()
                        -- gLobalNoticManager:postNotification("MODEITEMUPDATA_BEATLES_SUB_3", temp_index == count)
                        newSpineRole:setVisible(true)
                        util_spinePlay(newSpineRole, newSpineRoleAction[key], false)
                        
                        util_spineFrameCallFunc(newSpineRole, newSpineRoleAction[key] ,"suoding", function()
                            for _, pos in ipairs(temp_value) do
                                local fixPos = self:getRowAndColByPos(pos)
                                local targSpNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)

                                if targSpNode then
                                    local wildNodeYuGao = self:createNormalYuGao(fixPos)
                                    if yuGaoNodeTable[key] then
                                        table.insert(yuGaoNodeTable[key], wildNodeYuGao)
                                    else
                                        yuGaoNodeTable[key] = {}
                                        table.insert(yuGaoNodeTable[key], wildNodeYuGao)
                                    end
                                    self:setSymbolToClip(targSpNode)
                                end
                            end
                            util_spineFrameCallFunc(newSpineRole, newSpineRoleAction[key] ,"show1", function()
                                gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role3_jiguang.mp3")
                                for id, pos in ipairs(temp_value) do
                                    local fixPos = self:getRowAndColByPos(pos)
                                    local targSpNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                                    local yugao = nil
                                    if targSpNode then
    
                                        local act_lisit = {}
    
                                        act_lisit[#act_lisit + 1] = cc.CallFunc:create(function()
                                            local world_pos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)
                                            local end_pos = waitNode:convertToNodeSpace(world_pos)
                                            local pao = util_createAnimation("Beatles_paopao.csb")
                                            waitNode:addChild(pao, 2)
                                            local angle = util_getAngleByPos(start_pos,end_pos) 
                                            pao:setRotation( - angle)
                                            pao:setPosition(start_pos)
    
                                            local moveTo = cc.MoveTo:create(24/60, end_pos)
                                            local fun =
                                                cc.CallFunc:create(
                                                function()
                                                end
                                            )
                                            pao:runAction(cc.Sequence:create(moveTo, fun))
    
                                            pao:playAction("actionframe",false,function()
                                                pao:removeFromParent()
    
                                                if targSpNode then
                                                    targSpNode:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                                    if targSpNode.p_symbolImage ~= nil and targSpNode.p_symbolImage:getParent() ~= nil then
                                                        targSpNode.p_symbolImage:removeFromParent()
                                                        targSpNode.p_symbolImage = nil
                                                    end
                                                    
                                                    if #yuGaoNodeTable[key] > 0 then
                                                        for i,node in ipairs(yuGaoNodeTable[key]) do
                                                            if not tolua.isnull(node) then
                                                                node:removeFromParent()
                                                            end
                                                        end
                                                    end
                                                    
                                                    self:createNormalWild(fixPos)
                                                    if id == #temp_value then
                                                        gLobalSoundManager:playSound("BeatlesSounds/sound_Beatles_role3_change_wild.mp3")
                                                    end
                                                end
                                            end)
                                        end)                       
                                        
                                        waitNode:runAction(cc.Sequence:create(act_lisit))
                                    end
                                end
    
                                if temp_index == count then
                                    mode_role:stopAllActions()
                                    self:waitWithDelay(1, function()
                
                                        if newSpineRole then
                                            newSpineRole:removeFromParent()
                                        end
                                        self.m_models_action[7]:removeAllChildren()
                                        if newSpineRoleAction[key] == "actionframe_4" or newSpineRoleAction[key] == "actionframe_6" then
                                            util_spinePlay(mode_role, "actionframe_5", false)
                                            util_spineEndCallFunc(mode_role, "actionframe_5", function()
                                                util_spinePlay(mode_role, "idleframe3", true)
                                            end)
                                        end
                                        self:attemptHideMask()
                                        effectData.p_isPlay = true
                                        self:playGameEffect()
                                    end, waitNode)
                                end
                            end,
                            function()
    
                            end)
                        end)
                        
                    end, waitNode)
                end
            end)
        end
        if self.m_bProduceSlots_InFreeSpin == false then
            funCallBack()
        else
            if self.m_bProduceSlots_InFreeSpin and selfdata.winLinesNum then
                self:setLineCount(selfdata.winLinesNum + self.m_base_line, true)
            end
            if self:getFreePlayerNum() then
                local random = math.random(1,2)
                gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role3_tips"..random..".mp3")
                self:showModelsFreeTip(3, function()
                    funCallBack()
                end)
            else
                funCallBack()
            end
        end
    else
        self:attemptHideMask()
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

function CodeGameScreenBeatlesMachine:showEffect_BounsReel(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.fullWilds then
        self:attemptShowMask()
        self:attempSetRoleTip(4)
        if self:isQucikStop() then
            self:qucik_BounsReel()
            self:attemptHideMask()
            local qucik_tiem = 0
            -- if self.m_bProduceSlots_InFreeSpin then --freeGame 要有0.5秒的延时
            --     qucik_tiem = 0.5
            -- end
            self:waitWithDelay(qucik_tiem, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
            return
        end
        local waitNode = self.m_models_action[4]
        local mode_role = self.m_modes_tab[4].m_role
        -- mode_role:stopAllActions()

        local funCallBack = function(  )
            local fullWilds = selfdata.fullWilds
            table.sort(fullWilds, function(a, b)
                return a > b
            end)
            local total_num = #fullWilds
            local startPosWord = self.m_modes_tab[4]:getParent():convertToWorldSpace(cc.p(self.m_modes_tab[4]:getPosition()))
            local startPos = waitNode:convertToNodeSpace(startPosWord)
            startPos.y = startPos.y + 100

            util_spinePlay(mode_role, "actionframe", false)

            util_spineFrameCallFunc(mode_role, "actionframe", "show1", function()
  
                local fullWilds = selfdata.fullWilds
                table.sort(fullWilds, function(a, b)
                    return a > b
                end)
                local total_num = #fullWilds
                for i,v in ipairs(fullWilds) do
                    local delay_time = 0.1 + (i-1) * 1.5
                    local reelCol = v+1
                    local temp_index = i
                    self:waitWithDelay(delay_time, function()
                        
                        local temp_time = self.m_bProduceSlots_InFreeSpin and 0 or 1/3
                        self:waitWithDelay(0, function()
                            local world_pos =  self:getNodePosByColAndRow(2, reelCol)
                            local pos = waitNode:convertToNodeSpace(world_pos)
                            local feature = util_createAnimation("Beatles_Bonus_Feature_1.csb")
                            local woNiu = util_spineCreate("BeatleBeat_juese_4", true, true)
                            feature:findChild("Node_spine"):addChild(woNiu)
                            util_spinePlay(woNiu, "idleframe3", true)
                            woNiu:setRotation(180)
                            waitNode:addChild(feature)
                            feature:setPosition(pos)
                            local rotation = (temp_index % 2) == 1 and 180 or 0
                            feature:setRotation(rotation)
                            gLobalSoundManager:playSound("BeatlesSounds/sound_Beatles_change_wild_reel.mp3")

                            feature:playAction("actionframe1", false,function()
                                self:waitWithDelay(18/60, function()
                                    self:createReelWild(reelCol, self.m_clipParent)
                                end, waitNode)
                                feature:playAction("actionframe2", false, function()
                                    if temp_index == total_num then

                                        util_spinePlay(mode_role, "idleframe3_2", false)
                                        util_spineEndCallFunc(mode_role, "idleframe3_2", function()
                                            util_spinePlay(mode_role, "idleframe3", true)
                                        end)

                                        self:attemptHideMask()
                                        effectData.p_isPlay = true
                                        self:playGameEffect()
                                    end
                                    if woNiu then
                                        woNiu:removeFromParent()
                                    end
                                    if feature then
                                        feature:removeFromParent()
                                    end
                                end, 60)
                            end, 60)
                        end, waitNode)
                    end, waitNode)
                end 
            end,
            function()
                -- util_spinePlay(mode_role, "idleframe3", true) 

            end)
        end
        if self.m_bProduceSlots_InFreeSpin == false then
            funCallBack()
        else
            if self.m_bProduceSlots_InFreeSpin and selfdata.winLinesNum then
                self:setLineCount(selfdata.winLinesNum + self.m_base_line, true)
            end
            if self:getFreePlayerNum() then
                local random = math.random(1,2)
                gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role4_tips"..random..".mp3")
                self:showModelsFreeTip(4, function()
                    funCallBack()
                end)
            else
                funCallBack()
            end
        end

    else
        self:attemptHideMask()
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

function CodeGameScreenBeatlesMachine:showEffect_BounsAdd(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.randomWilds then
        self:attemptShowMask()
        self:attempSetRoleTip(5)
        if self:isQucikStop() then
            self:qucik_BounsAdd()
            self:attemptHideMask()
            effectData.p_isPlay = true
            self:playGameEffect()
            return
        end
        local randomWilds = selfdata.randomWilds
        table.sort(randomWilds,function(a, b)
            return a < b
        end)

        local waitNode = self.m_models_action[5]
        local item_role = self.m_modes_tab[5].m_role
        -- item_role:stopAllActions()
        local total_num = #randomWilds

        local funCallBack = function(  )
            self:waitWithDelay(0.1, function()
                gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role5_start.mp3")
                util_spinePlay(item_role, "actionframe", false)
                util_spineEndCallFunc(item_role, "actionframe", function()
                    util_spinePlay(item_role, "idleframe3", true)
                end)

                for i,pos in ipairs(randomWilds) do
                    local temp_index = i
                    local fixPos = self:getRowAndColByPos(pos)
                    local targSpNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                    self:waitWithDelay(23/30, function()
                        local startPosWord = self.m_modes_tab[5]:getParent():convertToWorldSpace(cc.p(self.m_modes_tab[5]:getPosition()))
                        local startPos = self.m_role_node:convertToNodeSpace(startPosWord)
                        startPos.y = startPos.y + 150
                        local endPosWord =  self:getNodePosByColAndRow( fixPos.iX, fixPos.iY)
                        local endPos = self.m_role_node:convertToNodeSpace(endPosWord)
                        local aixin = util_createAnimation("Socre_Beatles_WildAdd.csb")
                        self.m_role_node:addChild(aixin, self.m_modes_tab[5]:getLocalZOrder()-1)
                        aixin:playAction("idleframe")
                        aixin:setPosition(startPos)
                        aixin:setScale(0.7)
    
                        local actionList={}
                        actionList[#actionList + 1] = cc.BezierTo:create(15/30,{cc.p(startPos.x, startPos.y+150), cc.p(endPos.x, startPos.y+150), endPos})
                        actionList[#actionList+1]=cc.CallFunc:create(function(  )
                            aixin:setVisible(false)
                            aixin:removeFromParent()
    
                            if targSpNode then
                                targSpNode:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                if targSpNode.p_symbolImage ~= nil and targSpNode.p_symbolImage:getParent() ~= nil then
                                    targSpNode.p_symbolImage:removeFromParent()
                                end
                                targSpNode.p_symbolImage = nil
                                self:createNormalAddWild(fixPos)
                            end
    
                            if temp_index == total_num then
                                gLobalSoundManager:playSound("BeatlesSounds/sound_Beatles_role5_change_wild.mp3")
                                self:waitWithDelay(1, function()

                                    self:attemptHideMask()
                                    effectData.p_isPlay = true
                                    self:playGameEffect()
    
                                end,waitNode)
                            end
    
                        end)
                        actionList[#actionList + 1] = cc.RemoveSelf:create()
                        local seq1 = cc.Sequence:create(cc.ScaleTo:create(15/30,1))
                        local seq2 = cc.Sequence:create(actionList)
                        local seq3 = cc.Sequence:create(cc.DelayTime:create(5/30), cc.CallFunc:create(function()
                            aixin:setLocalZOrder(self.m_modes_tab[5]:getLocalZOrder()+100)
                        end))
                        local spiwn = cc.Spawn:create(seq1,seq2,seq3)
                        aixin:runAction(spiwn)
    
                    end, waitNode)
                end
            end,waitNode)
        end 

        if self.m_bProduceSlots_InFreeSpin == false then
            funCallBack()
        else
            if self.m_bProduceSlots_InFreeSpin and selfdata.winLinesNum then
                self:setLineCount(selfdata.winLinesNum + self.m_base_line, true)
            end
            if self:getFreePlayerNum() then
                local random = math.random(1,2)
                gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role5_tips"..random..".mp3")
                self:showModelsFreeTip(5, function()
                    funCallBack()
                end)
            else
                funCallBack()
            end
        end
        
    else
        self:attemptHideMask()
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

function CodeGameScreenBeatlesMachine:showEffect_BounsLine(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.winLinesNum then
        self:attemptShowMask()
        self:attempSetRoleTip(2)
        if self:isQucikStop() then
            self:qucik_BounsLine()
            self:attemptHideMask()
            local qucik_tiem = 0
            if self.m_bProduceSlots_InFreeSpin then  --freeGame 需要一些表现 所有需要一定的延时时间
                qucik_tiem = 0.5
            end
            self:waitWithDelay(qucik_tiem, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
            return
        end
        local waitNode = self.m_models_action[2]
        local mode = self.m_modes_tab[2]
        local feature = self.m_modes_tab[2]:getFeatureNum()
        local modes_role = self.m_modes_tab[2].m_role
        local startPosWord = self:findChild("SymbolReplaced"):getParent():convertToWorldSpace(cc.p(self:findChild("SymbolReplaced"):getPosition()))
        local startPos = waitNode:convertToNodeSpace(startPosWord)


        self:waitWithDelay(1, function()
            gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role2_dian_fly.mp3")
            util_spinePlay(modes_role, "actionframe", false)

            util_spineFrameCallFunc(modes_role, "actionframe", "switch1", function()
                local newSpineRole = util_spineCreate("BeatleBeat_juese_2", true, true)
                waitNode:addChild(newSpineRole)
                newSpineRole:setPosition(startPos)


                util_spinePlay(newSpineRole, "actionframe_2", false)
                util_spineFrameCallFunc(newSpineRole, "actionframe_2", "show1", function()

                    self:runCsbAction("actionframe_3", false)
                    self:waitWithDelay(10/60, function()
                        self:setLineCount(selfdata.winLinesNum + self.m_base_line, true)
                    end, waitNode)

                    self:waitWithDelay(30/60, function()
                        
                        self:attemptHideMask()
                        effectData.p_isPlay = true
                        self:playGameEffect()

                        if waitNode:getChildByName("flyNode") then
                            waitNode:getChildByName("flyNode"):removeFromParent() 
                        end
    
                    end, waitNode)

                end,
                function()
                    util_spinePlay(modes_role, "idleframe3_2", false) 
                    util_spineEndCallFunc(modes_role, "idleframe3_2", function()
                        util_spinePlay(modes_role, "idleframe3", true)
                    end)
                    
                end)

            end,
            function()

            end)

        end, waitNode)
    else
        self:attemptHideMask()
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

function CodeGameScreenBeatlesMachine:showEffectFree_BounsLine(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.level[3] > 0 then
        
        self.m_maskLayer:setVisible(true)
        self.m_maskLayer:playAction("start", false, function()
            self.m_maskLayer:playAction("idle")
        end)
        self:attempSetRoleTip(2)
        if self:isQucikStop() then
            self:qucik_BounsLine()
            self:attemptHideMask()
            local qucik_tiem = 0
            -- if self.m_bProduceSlots_InFreeSpin then  --freeGame 需要一些表现 所有需要一定的延时时间
            --     qucik_tiem = 0.5
            -- end
            self:waitWithDelay(qucik_tiem, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
            return
        end
        local waitNode = self.m_models_action[2]
        local mode = self.m_modes_tab[2]
        local feature = self.m_modes_tab[2]:getFeatureNum()
        local modes_role = self.m_modes_tab[2].m_role
        local startPosWord = self:findChild("SymbolReplaced"):getParent():convertToWorldSpace(cc.p(self:findChild("SymbolReplaced"):getPosition()))
        local startPos = waitNode:convertToNodeSpace(startPosWord)

        local random = math.random(1,2)
        gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role2_tips"..random..".mp3")
        self:showModelsFreeTip(2, function()
            self:waitWithDelay(0.1, function()
                gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role2_dian_fly.mp3")
                util_spinePlay(modes_role, "actionframe", false)
    
                util_spineFrameCallFunc(modes_role, "actionframe", "switch1", function()
                    local newSpineRole = util_spineCreate("BeatleBeat_juese_2", true, true)
                    waitNode:addChild(newSpineRole)
                    newSpineRole:setPosition(startPos)
    
    
                    util_spinePlay(newSpineRole, "actionframe_2", false)
                    util_spineFrameCallFunc(newSpineRole, "actionframe_2", "show1", function()

                        self:runCsbAction("actionframe_3", false)
                        self:waitWithDelay(10/60, function()
                            self:setLineCount(self.m_runSpinResultData.p_selfMakeData.store.storeData.buy_num["bonusType2"][self.m_runSpinResultData.p_selfMakeData.level[3]+1] + self.m_base_line, true)
                        end,waitNode)
                        self:waitWithDelay(55/60, function()
                            
                            self.m_maskLayer:setVisible(false)
                            effectData.p_isPlay = true
                            self:playGameEffect()
    
                            if waitNode:getChildByName("flyNode") then
                                waitNode:getChildByName("flyNode"):removeFromParent() 
                            end
        
                        end, waitNode)
    
                    end,
                    function()
                        util_spinePlay(modes_role, "idleframe3_2", false) 
                        util_spineEndCallFunc(modes_role, "idleframe3_2", function()
                            util_spinePlay(modes_role, "idleframe3", true)
                        end)
                    end)
    
                end,
                function()
    
                end)
    
            end, waitNode)
        end)
        
    else
        self.m_maskLayer:setVisible(false)
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

-- 判断free玩法 有几个大角色玩法 
-- 除了加线 其他4中 只有一个玩法 不播放提示条
-- 加线和 其他4中 任意组合成2中玩法 除了加线 其他也不播放提示条
function CodeGameScreenBeatlesMachine:getFreePlayerNum( )
    local newNumTable = {}
    if self.m_runSpinResultData.p_selfMakeData.level and #self.m_runSpinResultData.p_selfMakeData.level > 0 then
        for id, num in ipairs(self.m_runSpinResultData.p_selfMakeData.level) do
            if id ~= 1 then -- 5中玩法 ID是从2开始的
                if num > 0 then
                    table.insert(newNumTable, id-1)
                end
            end
        end
        if #newNumTable == 2 then
            if newNumTable[1] == 2 or newNumTable[2] == 2 then
                return false
            else
                return true
            end
        else
            if #newNumTable == 1 then
                return false
            else
                return true
            end
        end
    end
end

--MultiEnd 成倍end
function CodeGameScreenBeatlesMachine:showEffect_BounsMultiEnd(effectData)
    if self:isQucikStop() then
        self:attemptHideMask()
        util_spinePlay(self.m_modes_tab[1].m_role, "over", false)
        util_spineEndCallFunc(self.m_modes_tab[1].m_role, "over", function()
            util_spinePlay(self.m_modes_tab[1].m_role, "idleframe3", true)  
        end)
        self.isPlayActionMulti = false

        if self.m_models_action[1]:getChildByName("multiNode") then
            self.m_models_action[1]:getChildByName("multiNode"):playAction("over",false,function()
                self.m_models_action[1]:removeAllChildren()
            end)
        else
            self.m_models_action[1]:removeAllChildren()
        end
        local qucik_tiem = 0
        
        self:waitWithDelay(qucik_tiem, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        return
    end
    local waitNode = self.m_models_action[1]
    if not self.isMultiEndFly then
        if self.m_bProduceSlots_InFreeSpin then
            if globalData.slotRunData.freeSpinCount == 0 then
                -- mode:showFreeIdle()
                if waitNode:getChildByName("multiNode") then
                    util_spinePlay(self.m_modes_tab[1].m_role, "over", false)
                    util_spineEndCallFunc(self.m_modes_tab[1].m_role, "over", function()
                        util_spinePlay(self.m_modes_tab[1].m_role, "idleframe3", true)  
                    end)
                end
                waitNode:removeAllChildren()
                self.isPlayActionMulti = false
            end
        else
            if waitNode:getChildByName("multiNode") then
                util_spinePlay(self.m_modes_tab[1].m_role, "over", false)
                util_spineEndCallFunc(self.m_modes_tab[1].m_role, "over", function()
                    util_spinePlay(self.m_modes_tab[1].m_role, "idleframe3", true)  
                end)
            end
            waitNode:removeAllChildren()
            self.isPlayActionMulti = false
        end
        self:attemptHideMask()
        effectData.p_isPlay = true
        self:playGameEffect()
    else
        local act_list = {}
        self:attemptShowMask()
        act_list[#act_list + 1] = cc.DelayTime:create(0.3)
        act_list[#act_list + 1] = cc.CallFunc:create(function()
            local mode_role = self.m_modes_tab[1].m_role
            
            util_spinePlay(mode_role, "over", false)
            if waitNode:getChildByName("multiNode") then
                waitNode:getChildByName("multiNode"):findChild("Particle_1"):setDuration(-1)
                waitNode:getChildByName("multiNode"):findChild("Particle_1"):setPositionType(0)

                local worldPos = self:getNodePosByColAndRow(2, 3)
                local pos = waitNode:convertToNodeSpace(worldPos)
                pos.y = pos.y - 100
                
                local act_lisit2 = {}
                act_lisit2[#act_lisit2 + 1] = cc.Spawn:create(cc.ScaleTo:create(0.3, 2), cc.MoveTo:create(0.3, pos)) 
                act_lisit2[#act_lisit2 + 1] = cc.CallFunc:create(function()
                    waitNode:getChildByName("multiNode"):findChild("Particle_1"):stopSystem()
                end)
                act_lisit2[#act_lisit2 + 1] = cc.CallFunc:create(function()
                    local feature = util_createAnimation("Beatles_Bonus_Feature_6.csb")
                    waitNode:addChild(feature)
                    feature:setPosition(waitNode:convertToNodeSpace(worldPos))
                    gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role1_multi_collect.mp3")
                    feature:playAction("actionframe", false, function()
                        
                        self:attemptHideMask()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                        feature:removeFromParent()
                        -- waitNode:getChildByName("multiNode"):removeFromParent()
                        
                    end, 60)
                    self.isPlayActionMulti = false
                end)
                act_lisit2[#act_lisit2 + 1] = cc.RemoveSelf:create()
                waitNode:getChildByName("multiNode"):runAction(cc.Sequence:create(act_lisit2))
            else
                self:attemptHideMask()
                effectData.p_isPlay = true
                self:playGameEffect()
            end

            util_spineEndCallFunc(mode_role, "over", function()
                util_spinePlay(mode_role, "idleframe3", true)  
            end)

        end)

        gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role1_multi_fly.mp3")
        waitNode:runAction(cc.Sequence:create(act_list))
    end
end

--设置棋盘的背景
function CodeGameScreenBeatlesMachine:setReelBg(isBase, actionName)
    self:findChild("Beatles_reel_base"):setVisible(isBase)
    self:findChild("Beatles_reel_free"):setVisible(isBase == false)

    if isBase then
        if actionName and actionName == "over" then
            util_spinePlay(self.m_gameBg, "start", false)
            self.m_gameBg:setVisible(true)
            self.m_gameBgFree:setVisible(false)

            util_spineEndCallFunc(self.m_gameBg, "start", function()
                
                util_spinePlay(self.m_gameBg, "idleframe", true)
            end)
        else
            if self.m_bProduceSlots_InFreeSpin then
                self.m_gameBg:setVisible(false)
                self.m_gameBgFree:setVisible(true)
                util_spinePlay(self.m_gameBgFree, "idleframe", true)
            else
                self.m_gameBg:setVisible(true)
                self.m_gameBgFree:setVisible(false)
                util_spinePlay(self.m_gameBg, "idleframe", true)
            end
            
        end
    else
        if actionName and actionName == "start" then
            util_spinePlay(self.m_gameBgFree, "start", false)
            self.m_gameBgFree:setVisible(true)
            self.m_gameBg:setVisible(false)

            util_spineEndCallFunc(self.m_gameBgFree, "start", function()
            
                util_spinePlay(self.m_gameBgFree, "idleframe", true)
            end)
  
        else
            if self.m_bProduceSlots_InFreeSpin then
                self.m_gameBg:setVisible(false)
                self.m_gameBgFree:setVisible(true)
                util_spinePlay(self.m_gameBgFree, "idleframe", true)
            else
                self.m_gameBg:setVisible(true)
                self.m_gameBgFree:setVisible(false)
                util_spinePlay(self.m_gameBg, "idleframe", true)
            end
        end
    end
end

function CodeGameScreenBeatlesMachine:initMachineBg()
    local gameBg = util_spineCreate("GameScreenBeatlesBg", true, true) 
    local gameBgFree = util_spineCreate("GameScreenBeatlesBg2", true, true) 
    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
        bgNode:addChild(gameBgFree, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
        self:addChild(gameBgFree, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    
    self.m_gameBg = gameBg
    self.m_gameBgFree = gameBgFree
end

--设置线数
function CodeGameScreenBeatlesMachine:setLineCount(count, isLight)
    if self.m_cur_line ~= count then
        
        self.m_cur_line = count
        if count >= 100 then
            self.m_line_right:findChild("Node_Double"):setVisible(false)
            self.m_line_left:findChild("Node_Double"):setVisible(false)
            self.m_line_right:findChild("Node_100"):setVisible(true)
            self.m_line_left:findChild("Node_100"):setVisible(true)
        else
            self.m_line_right:findChild("Node_Double"):setVisible(true)
            self.m_line_left:findChild("Node_Double"):setVisible(true)
            self.m_line_right:findChild("Node_100"):setVisible(false)
            self.m_line_left:findChild("Node_100"):setVisible(false)
            local lineNum = count / 10
            self.m_line_right:findChild("m_lb_num_double1"):setString(lineNum)
            self.m_line_left:findChild("m_lb_num_double1"):setString(lineNum)
        end

        if count > self.m_base_line then
            self.m_line_left:playAction("actionframe")
            self.m_line_right:playAction("actionframe")
        else
            self.m_line_left:playAction("over")
            self.m_line_right:playAction("over")
        end
    end
    if isLight then
        self:setLineToTip(self.m_line_left)
        self:setLineToTip(self.m_line_right)
        
    else
        local item = self.m_line_left
        local preParent = item.m_preParent
        if preParent ~= nil then
            local nZOrder = item.m_showOrder
            item:setPosition(item.m_preX, item.m_preY)
            util_changeNodeParent(preParent, item, nZOrder)
            item.m_preParent = nil
        end

        local item1 = self.m_line_right
        local preParent = item1.m_preParent
        if preParent ~= nil then
            local nZOrder = item1.m_showOrder
            item1:setPosition(item1.m_preX, item1.m_preY)
            util_changeNodeParent(preParent, item1, nZOrder)
            item1.m_preParent = nil
        end
    end
end

--创建一列wild
function CodeGameScreenBeatlesMachine:createReelWild(reelCol, parent_node)

    local reelWild = self:getSlotNodeBySymbolType(self.SYMBOL_WILD_REEL)
    local world_pos =  self:getNodePosByColAndRow(2, reelCol)
    local pos = parent_node:convertToNodeSpace(world_pos)
    parent_node:addChild(reelWild, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100, SYMBOL_FIX_NODE_TAG + 1)
    reelWild:setPosition(pos)
    reelWild.p_slotNodeH = self.m_SlotNodeH 

    reelWild.m_symbolTag = SYMBOL_FIX_NODE_TAG
    reelWild.m_showOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100
    reelWild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
    reelWild.m_bInLine = true

    local linePos = {}
    for iRow = 1, self.m_iReelRowNum do
        local itme = {iX = iRow,iY = reelCol}
        table.insert(linePos, itme)
    end
    reelWild:setLinePos(linePos)
    table.insert(self.m_wild_reel, reelWild)
    reelWild:runAnim("idleframe",false)

end

--创建小wild
function CodeGameScreenBeatlesMachine:createNormalWild(pos)
    local wild = util_createAnimation("Socre_Beatles_WildAdd.csb")
    local world_pos =  self:getNodePosByColAndRow(pos.iX, pos.iY)
    local pos = self.m_LockWildNode:convertToNodeSpace(world_pos)
    self.m_LockWildNode:addChild(wild)
    wild:setPosition(pos)
    wild:playAction("actionframe",false,function()
    end)
end

--创建小wild
function CodeGameScreenBeatlesMachine:createNormalAddWild(pos)
    local wild = util_createAnimation("Socre_Beatles_WildAdd2.csb")
    local world_pos =  self:getNodePosByColAndRow(pos.iX, pos.iY)
    local pos = self.m_LockWildNode:convertToNodeSpace(world_pos)
    self.m_LockWildNode:addChild(wild)
    wild:setPosition(pos)
    wild:playAction("actionframe",false,function()
    end)

    return wild
end


--创建小框
function CodeGameScreenBeatlesMachine:createNormalYuGao(pos,temp_index)
    local wild = util_spineCreate("BeatleBeat_juese_3", true, true)
    local world_pos =  self:getNodePosByColAndRow(pos.iX, pos.iY)

    local pos = self.m_models_action[7]:convertToNodeSpace(world_pos)
    self.m_models_action[7]:addChild(wild, -1)
    wild:setPosition(pos)

    util_spinePlay(wild, "actionframe2", false)
    util_spineEndCallFunc(wild, "actionframe2", function()
    end)
    return wild
end

function CodeGameScreenBeatlesMachine:getNodePosByColAndRow(row, col)
    if col >= 1 and col <= 5 then
        local reelNode = self:findChild("sp_reel_" .. (col - 1))
        local posX, posY = reelNode:getPosition()
        posX = posX + self.m_SlotNodeW * 0.5
        posY = posY + (row - 0.5) * self.m_SlotNodeH
        local world_pos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
        return world_pos
    end
end

function CodeGameScreenBeatlesMachine:clearReelWild()
    for key,node in ipairs(self.m_wild_reel) do
        if not tolua.isnull(node) then
            util_nodeFadeIn(node,0.2,255,0,nil,function ()
                node:removeFromParent()
                if util_resetChildReferenceCount then
                    util_resetChildReferenceCount(node)
                end
            end)
        end
    end
    self.m_wild_reel = {}
end

function CodeGameScreenBeatlesMachine:clearNormalWild()
    self.m_LockWildNode:removeAllChildren()
end

function CodeGameScreenBeatlesMachine:showLineFrame()
    self:clearNormalWild()
    BaseNewReelMachine.showLineFrame(self)
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenBeatlesMachine:showEffect_Bonus(effectData)
    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self.m_linesNode:setVisible(false)
    self.m_models_action[8]:removeAllChildren()

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

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then

        self:showBonusAndScatterLineTip(bonusLineValue,function()
            self:waitWithDelay(1, function()
                self:showBonusGameView(effectData)
            end)
        end)
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else

        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

    return true
end

function CodeGameScreenBeatlesMachine:showBonusGameView(effectData)

    self:showGuoChange("guochang","show1", function()
        self.m_chooseLayer = util_createView("CodeBeatlesSrc.BeatlesChooseView", self)
        self:addChild(self.m_chooseLayer, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
        util_csbScale(self.m_chooseLayer.m_csbNode, self.m_machineRootScale)
        self.m_chooseLayer:setEndCall(function()
            self:featuresOverAddFreespinEffect()
            self:notifyGameEffectPlayComplete(GameEffect.EFFECT_BONUS)
        end)
    end, function()
        
    end)
    
end

--bonus玩法结束后添加freespin动画效果
function CodeGameScreenBeatlesMachine:featuresOverAddFreespinEffect()
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i = 1, #featureDatas do
        local featureId = featureDatas[i]
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end
end

function CodeGameScreenBeatlesMachine:showGuoChange(actionName, frameName, callFunc1, callFunc2)
    self.m_guoChang:setVisible(true)
    self.m_guoChang2:setVisible(true)
    -- 过场遮罩
    self.m_guoChangLayer = util_newMaskLayer(false)
    self:addChild(self.m_guoChangLayer, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 3)

    util_spinePlay(self.m_guoChang, actionName, false)
    util_spinePlay(self.m_guoChang2, actionName, false)

    util_spineFrameCallFunc(self.m_guoChang2, actionName, frameName, function()
        if callFunc1 then
            callFunc1()
        end
    end,
    function()
        if callFunc2 then
            callFunc2()
        end
        self.m_guoChang:setVisible(false)
        self.m_guoChang2:setVisible(false)
        self.m_guoChangLayer:removeFromParent()
        self.m_guoChangLayer = nil
    end
    )
end

function CodeGameScreenBeatlesMachine:scaleMainLayer()
    BaseNewReelMachine.scaleMainLayer(self)
    local ratio = display.height/display.width
    local root_ui_scale = 1.05
    if  ratio >= 768/1024 then
        local mainScale = 0.76
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.86 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.92 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio > 768/1370 then
        local mainScale = 0.95 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio <= 768/1370 then

        self:findChild("root_ui"):setScale(root_ui_scale)
    end
end

function CodeGameScreenBeatlesMachine:showInLineSlotNodeByWinLines(winLines,startIndex,endIndex,bChangeToMask)
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
            for checkIndex=1,#self.m_lineSlotNodes do

                local checkNode = self.m_lineSlotNodes[checkIndex]
                if checkNode == slotNode then
                    isHasNode = true
                    break
                end

            end
            if isHasNode == false then
                if bChangeToMask == false or slotNode.p_symbolType == self.SYMBOL_WILD_REEL then
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode
                else
                    self:changeToMaskLayerSlotNode(slotNode)
                end

            end
        end
    end

    -- 获取所有参与连线的SlotsNode 节点
    for lineIndex=startIndex,endIndex do
        local lineValue = winLines[lineIndex]

        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN and
            lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_BONUS then

            if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] == nil then
                self.m_eachLineSlotNode[lineIndex] = {}
            end
            local frameNum = lineValue.iLineSymbolNum
            for i=1,frameNum do
                -- 播放slot node 的动画
                local symPosData = lineValue.vecValidMatrixSymPos[i]

                local slotNode = nil
                local parentData = self.m_slotParents[symPosData.iY]
                local slotParent = parentData.slotParent
                local slotParentBig = parentData.slotParentBig
                if self.m_bigSymbolColumnInfo ~= nil and
                    self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then

                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do

                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex=1,#bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then

                                slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                if slotNode==nil and slotParentBig then
                                    slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                end
                                isBigSymbol = true
                                break
                            end
                        end

                    end
                    if isBigSymbol == false then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        if slotNode==nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        end
                    end
                else
                    slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    if slotNode==nil and slotParentBig then
                        slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    end
                end

                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil  then
                    slotNode = sepcicalNode
                end

                checkAddLineSlotNode(slotNode)

                -- 存每一条线
                symPosData = lineValue.vecValidMatrixSymPos[i]
                if self.m_bigSymbolColumnInfo ~= nil and
                    self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then

                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do

                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex=1,#bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = self:getFixSymbol(symPosData.iY, bigSymbolInfo.startRowIndex, SYMBOL_NODE_TAG)
                                isBigSymbol = true
                                break
                            end
                        end

                    end
                    if isBigSymbol == false then
                        slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                    end
                else
                    slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                end
                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil  then
                    slotNode = sepcicalNode
                end
                if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                    self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = slotNode
                end

                ---
            end  -- end for i = 1 frameNum

        end -- end if freespin bonus


    end

    -- 添加特殊格子。 只适用于覆盖类的长条，例如小财神， 白虎乌鸦人等 ..
    local specialChilds = self:getAllSpecialNode()
    for specialIndex =1,#specialChilds do
        local specialNode = specialChilds[specialIndex]
        checkAddLineSlotNode(specialNode)
    end

end

function CodeGameScreenBeatlesMachine:showTip(callFunc)
    local mode_data = BeatlesBaseData:getInstance():getDataByKey("modes") or {}
    local tipTab = {} --可触发的玩法
    for k,v in ipairs(mode_data) do
        local value = v or 0 
        if value > 0 then
            table.insert(tipTab, k)
        end
    end
    local tab_num = table.nums(tipTab)
    if tab_num <= 0 then
        if callFunc then
            callFunc()
        end
        return
    end
    --角色提层
    self:resetBeginRole()
    local isHaveModel_5 = false --玩法乘倍 需要特殊处理下
    for _, index in ipairs(tipTab) do
        local node = self.m_modes_tab[index]
        self:setRoleToTip(node)
    end
    --角色light
    gLobalNoticManager:postNotification("MODEITELIGHT_BEATLES")

    --遮罩
    self.m_maskLayer:setVisible(true)
    self.m_maskLayer:playAction("start", false, function()
        self.m_maskLayer:playAction("idle")
    end)

    self:waitWithDelay(1, function()
        if callFunc then
            callFunc()
        end
    end)
end

--尝试关闭遮罩
function CodeGameScreenBeatlesMachine:attemptHideMask()
    self.m_curModel_index = 0 --重置索引
    self.m_mask_num  = self.m_mask_num - 1
    if self.m_mask_num == 0 then
        self:reelDownNotifyChangeSpinStatus()

        local callFunc = function()
            if self.m_bProduceSlots_InFreeSpin == false then
                self:resetRole()
            end
            self:reBackNode(self.m_line_left)
            self:reBackNode(self.m_line_right)
            self.m_maskLayer:setVisible(false)
            self.m_maskLayer:setZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 2)
        end

        if self.m_maskLayer:isVisible() then
            self.m_maskLayer:playAction("over", false, function()
                if callFunc then
                    callFunc()
                end
            end)
        else
            if callFunc then
                callFunc()
            end
        end
    end
end

--显示遮罩
function CodeGameScreenBeatlesMachine:attemptShowMask()
    if self.m_maskLayer:isVisible() == false and self.m_mask_num > 0 and not self:isQucikStop() then
        self.m_maskLayer:setVisible(true)
        self.m_maskLayer:playAction("start", false, function()
            self.m_maskLayer:playAction("idle")
        end)
    end
end

function CodeGameScreenBeatlesMachine:attempSetRoleTip(index)
    local item = self.m_modes_tab[index]
    local preParent = item.m_preParent
    -- if preParent == nil then
        item:showLight(true)
        self:setRoleToTip(item)
    -- end
end


function CodeGameScreenBeatlesMachine:playEffectNotifyNextSpinCall( )

    BaseNewReelMachine.playEffectNotifyNextSpinCall(self)
    if not self.m_bProduceSlots_InFreeSpin then
        if self.m_spine_num ~= 10 then
            self:checkTriggerOrInSpecialGame(function()
                self:reelsDownDelaySetMusicBGVolume()
            end)
        end
    end
end

--所有滚轴停止调用
function CodeGameScreenBeatlesMachine:slotReelDown()
    BaseNewReelMachine.slotReelDown(self)

end

-- 所有的动画执行完毕 才可以点击商店
function CodeGameScreenBeatlesMachine:changeBtnTouch( )
    if self:getGameSpinStage() == IDLE then
        self.m_isCanTouch = true
    end
    for i,v in ipairs(self.m_gameEffects) do
        if not v.p_isPlay then
            self.m_isCanTouch = false
        else
            self.m_isCanTouch = true
        end
    end
    
end

-- 得到按钮状态
function CodeGameScreenBeatlesMachine:getBtnTouch( )
    self:changeBtnTouch()

    return self.m_isCanTouch
end

--baseGame 背景音乐
function CodeGameScreenBeatlesMachine:changeBaseGameMusic(isChange)
    local music_bg = self.m_configData.p_musicBg
    if isChange then
        music_bg = "BeatlesSounds/Music_Beatles_Base_Bg2.mp3"
    end
    self:setBackGroundMusic(music_bg)
    if isChange ~= self.m_isChangeBaseBgMusic then
        local volume = gLobalSoundManager:getBackgroundMusicVolume() or 0
        self:clearCurMusicBg()
        self:resetMusicBg()
        self.m_isChangeBaseBgMusic = not self.m_isChangeBaseBgMusic
        -- gLobalSoundManager:setBackgroundMusicVolume(volume)
        -- self:removeSoundHandler( )
        -- self:checkTriggerOrInSpecialGame(function(  )
        --     self:reelsDownDelaySetMusicBGVolume( )
        -- end)
    end
end

--玩法提示
function CodeGameScreenBeatlesMachine:showModelsTip(index, callFunc)
    self.m_curModel_index = index
    if self:isQucikStop() then
        if callFunc then
            callFunc()
        end
        return
    end
    self:attempShowStopBtn()
    if self.m_bProduceSlots_InFreeSpin then -- freeGame 没有玩法提示
        if callFunc then
            callFunc()
        end
        return
    end
    --baseGame的玩法提示
    -- gLobalNoticManager:postNotification("MODEITEMTIP_BEATLES_"..index)
    -- 线数框提前提层
    self:setLineToTip(self.m_line_left)
    self:setLineToTip(self.m_line_right)

    local csb_name = string.format("Beatles_Bonus_FeatureTip_%d.csb", index)
    local tip = util_createAnimation(csb_name)
    self:findChild("node_FeatureTip"):addChild(tip)
    local storeData = self.m_runSpinResultData.p_selfMakeData.store.storeData or nil
    
    tip:playAction("start")
    local random = math.random(1,2)
    gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_role"..index.."_tips"..random..".mp3")
    
    util_spinePlay(self.m_modes_tab[index].m_role, "shouji2", false)
    util_spineEndCallFunc(self.m_modes_tab[index].m_role, "shouji2", function()
        util_spinePlay(self.m_modes_tab[index].m_role, "idleframe3", true)
    end)
    local waitNode = self.m_models_action[index]
    local feature = self.m_modes_tab[index]:getFeatureNum()
    local act_list = {}
    act_list[#act_list + 1] = cc.DelayTime:create(65/60) --start时间线的等待时间
    for i=1,feature do
        local temp_index = i
        act_list[#act_list + 1] = cc.CallFunc:create(function()
            gLobalNoticManager:postNotification("MODEITEMUPDATA_BEATLES_SUB_"..index)
        end)
        act_list[#act_list + 1] = cc.DelayTime:create(0.1)
        act_list[#act_list + 1] = cc.CallFunc:create(function()
            local module_num = tip:findChild("model_num")
            if storeData and storeData.buy_num then
                if index == 1 then
                    module_num:setString(storeData.buy_num["bonusType"..index][temp_index+1] .."X")
                else
                    module_num:setString(storeData.buy_num["bonusType"..index][temp_index+1])
                end
            else
                module_num:setString(0)
            end
            tip:playAction("actionframe")
            gLobalSoundManager:playSound("BeatlesSounds/sound_Beatles_tips_num_change.mp3")
        end)
        act_list[#act_list + 1] = cc.DelayTime:create(0.4)
    end
    act_list[#act_list + 1] = cc.DelayTime:create(0.1)
    act_list[#act_list + 1] = cc.CallFunc:create(function()
        if callFunc then
            callFunc()
        end
        tip:playAction("over", false, function()
            tip:removeFromParent()
        end)
    end)
    -- act_list[#act_list + 1] = cc.DelayTime:create(0.8)
    -- act_list[#act_list + 1] = cc.CallFunc:create(function()

    -- end)
    waitNode:runAction(cc.Sequence:create(act_list))
end

--玩法提示
function CodeGameScreenBeatlesMachine:showModelsFreeTip(index, callFunc)

    local waitNode = self.m_models_action[index]
    local storeData = self.m_runSpinResultData.p_selfMakeData.store.storeData or nil
    local csb_name = string.format("Beatles_Bonus_FeatureTip_%d.csb", index)
    local tip = util_createAnimation(csb_name)
    local start_worldPos = self:findChild("node_FeatureTip"):getParent():convertToWorldSpace(cc.p(self:findChild("node_FeatureTip"):getPosition()))
    local start_pos = waitNode:convertToNodeSpace(start_worldPos)
    waitNode:addChild(tip)
    tip:setPosition(start_pos)
    -- tip:playAction("start")
    
    local feature = self.m_modes_tab[index]:getFeatureNum()
    local act_list = {}
    -- act_list[#act_list + 1] = cc.DelayTime:create(65/60) --start时间线的等待时间
 
    act_list[#act_list + 1] = cc.CallFunc:create(function()
        local module_num = tip:findChild("model_num")
        if storeData and storeData.buy_num then
            if index == 1 then
                module_num:setString(self.m_runSpinResultData.p_selfMakeData.winMultiple .."X")
            else
                module_num:setString(storeData.buy_num["bonusType"..index][self.m_runSpinResultData.p_selfMakeData.level[index+1]+1]) 
            end
        else
            module_num:setString(0)
        end
        tip:playAction("start")
    end)
    act_list[#act_list + 1] = cc.DelayTime:create(65/60)

    act_list[#act_list + 1] = cc.CallFunc:create(function()
        if callFunc then
            callFunc()
        end
        tip:playAction("over", false, function()
            tip:removeFromParent()
        end)
    end)
    waitNode:runAction(cc.Sequence:create(act_list))
   
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenBeatlesMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i=1,frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        if slotNode==nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        end
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

        if slotNode ~= nil then--这里有空的没有管

            slotNode = self:setSlotNodeEffectParent(slotNode)
            slotNode:runAnim("actionframe",false,function()
                slotNode:runAnim("idleframe2")
            end)
            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenBeatlesMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()
        callFun()
    end,util_max(2,animTime),self:getModuleName())
end

--下面内容基本都是快停相关
function CodeGameScreenBeatlesMachine:getBottomUINode( )
    return "CodeBeatlesSrc.BeatlesBottomUI"
end

--尝试显示stopbtn
function CodeGameScreenBeatlesMachine:attempShowStopBtn()
    -- if not globalData.slotRunData.isClickQucikStop and globalData.slotRunData.currSpinMode ~= AUTO_SPIN_MODE 
    --    and not self.m_isQuitShow then
    --    --and not self.m_isQuitShow and self.m_bProduceSlots_InFreeSpin == false then  
    --     self:dealSmallReelsSpinStates()
    -- end
    if not self.m_bProduceSlots_InFreeSpin then
        if self.m_spine_num == 10 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
            return
        end
    end

    if not self.m_isQuitShow and globalData.slotRunData.currSpinMode ~= AUTO_SPIN_MODE then
        if not globalData.slotRunData.isClickQucikStop or self.m_bProduceSlots_InFreeSpin then
            if self.m_bProduceSlots_InFreeSpin then
                self:waitWithDelay(0.5, function()
                    self:dealSmallReelsSpinStates()
                    self.m_bottomUI:getSpinBtn():resetStopBtnTouch()  --重置下stop按钮的点击状态
                end)
            else
                self:dealSmallReelsSpinStates()
            end
        end
    end
end

--是否已快停
function CodeGameScreenBeatlesMachine:isQucikStop()
    if self.m_bProduceSlots_InFreeSpin then
        return self.m_isQuitShow 
    else
        if self.m_spine_num == 10 then --第10次不能快停
            return false
        else
            return globalData.slotRunData.isClickQucikStop or self.m_isQuitShow 
        end 
    end
    
end

--替换图标-快停
function CodeGameScreenBeatlesMachine:qucik_BounsReplace()
    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification("MODEITEMNUM_BEATLES_3")
    end
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.changeSignals then
        local changeSignals = selfdata.changeSignals
        for key,value in ipairs(changeSignals) do
            local temp_value = value
            for _, pos in ipairs(temp_value) do
                local fixPos = self:getRowAndColByPos(pos)
                local targSpNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                if targSpNode and targSpNode.p_symbolType  ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    targSpNode:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    if targSpNode.p_symbolImage ~= nil and targSpNode.p_symbolImage:getParent() ~= nil then
                        targSpNode.p_symbolImage:removeFromParent()
                    end
                    targSpNode.p_symbolImage = nil                
                end
            end
        end
    end
end

--整列wild快停
function CodeGameScreenBeatlesMachine:qucik_BounsReel()
    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification("MODEITEMNUM_BEATLES_4")
    end
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.fullWilds then
        self:clearReelWild()
        local fullWilds = selfdata.fullWilds
        local total_num = #fullWilds
        for i,v in ipairs(fullWilds) do
            local reelCol = v+1
            self:createReelWild(reelCol, self.m_clipParent)
        end 
    end
end

--随机wild快停
function CodeGameScreenBeatlesMachine:qucik_BounsAdd()
    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification("MODEITEMNUM_BEATLES_5")
    end
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.randomWilds then
        local randomWilds = selfdata.randomWilds
        local slot_col = {}  --按列分组
        for i,v in ipairs(randomWilds) do
            local fixPos = self:getRowAndColByPos(v)
            local targSpNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            if targSpNode and targSpNode.p_symbolType  ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                targSpNode:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                if targSpNode.p_symbolImage ~= nil and targSpNode.p_symbolImage:getParent() ~= nil then
                    targSpNode.p_symbolImage:removeFromParent()
                end
                targSpNode.p_symbolImage = nil
            end
        end
    end
end

--添加线数快停
function CodeGameScreenBeatlesMachine:qucik_BounsLine()
    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification("MODEITEMNUM_BEATLES_2")
    end
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.winLinesNum then
        self:setLineCount(selfdata.winLinesNum + self.m_base_line, true)
    end
    self:findChild("node_freegameover"):removeAllChildren()
    local qucik_tiem = 0
    if self.m_bProduceSlots_InFreeSpin then
        qucik_tiem = 0.4
    end
    self:waitWithDelay(qucik_tiem, function()
        
    end)
end

--乘倍快停
function CodeGameScreenBeatlesMachine:qucik_BounsMulti()
    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification("MODEITEMNUM_BEATLES_1")
    end
    
    local qucik_tiem = 0
    if self.m_bProduceSlots_InFreeSpin then
        qucik_tiem = 0.4
    end
    self.isPlayActionMulti = false

    self:waitWithDelay(qucik_tiem, function()
        local mode_role = self.m_modes_tab[1].m_role
        local waitNode = self.m_models_action[1]
       
        if waitNode:getChildByName("multiNode") then
            waitNode:getChildByName("multiNode"):removeFromParent() 
        end
        
        util_spinePlay(mode_role, "idleframe3", true)  
        
    end)
end

--收集bouns快停
function CodeGameScreenBeatlesMachine:qucik_BounsChange()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.bonusTransfer then
     
        for i=1,5 do
            local model = self.m_modes_tab[i]
            model:playerRoleIdle()
        end
        self.isBounsChange_quick = true
        if self.m_spine_num ~= 10 then
            gLobalNoticManager:postNotification("MODEIBOUNS_BEATLES")
        end
    end

end

function CodeGameScreenBeatlesMachine:qucikStopEffect()
    if self.m_spine_num == 10 and not self.m_bProduceSlots_InFreeSpin then
        return
    end
    if not self.m_isQuitShow then
        self.m_isQuitShow = true
        local qucik_tiem = 0
        if self.m_curModel_index > 0  and self.m_curModel_index < 6 then
            self:findChild("node_FeatureTip"):stopAllActions()
            self:findChild("node_FeatureTip"):removeAllChildren()
            local action_node = self.m_models_action[self.m_curModel_index]
            action_node:stopAllActions()
            action_node:removeAllChildren()
            if self.m_curModel_index == 3 then
                self.m_models_action[7]:stopAllActions()
                self.m_models_action[7]:removeAllChildren()
            end
            local model = self.m_modes_tab[self.m_curModel_index]
            model:unregisterSpineEvent()
            if self.m_bProduceSlots_InFreeSpin then --原先freeGame也可以进来,就保留了
                model:showRoleLightIdle()
            else
                model:playerRoleIdle()
            end
            self:clearNormalWild()
            local effectOrder = self.BOUNS_MODEL_MULTI
            
            if self.m_curModel_index == 1 then
                self:qucik_BounsMulti()
                if self.m_bProduceSlots_InFreeSpin then
                    -- qucik_tiem = 0.5
                end
            elseif self.m_curModel_index == 2 then
                self:qucik_BounsLine()
                effectOrder = self.BOUNS_MODEL_LINE
                if self.m_bProduceSlots_InFreeSpin then
                    -- qucik_tiem = 0.5
                end
            elseif self.m_curModel_index == 3 then
                self:qucik_BounsReplace()
                effectOrder = self.BOUNS_MODEL_REPLACE
            elseif self.m_curModel_index == 4 then
                self:qucik_BounsReel()
                effectOrder = self.BOUNS_MODEL_REELS
                if self.m_bProduceSlots_InFreeSpin then
                    -- qucik_tiem = 0.5
                end
            elseif self.m_curModel_index == 5 then
                self:qucik_BounsAdd()
                effectOrder = self.BOUNS_MODEL_ADD
            end
            self:reelDownNotifyChangeSpinStatus()
            local effectLen = #self.m_gameEffects
            local effectData = nil    
            for i=1,effectLen do
                effectData = self.m_gameEffects[i]
                if effectData.p_effectType ==  GameEffect.EFFECT_SELF_EFFECT and effectData.p_effectOrder == effectOrder and effectData.p_isPlay == false then
                    break
                end
            end
            self:waitWithDelay(qucik_tiem, function()
                self:attemptHideMask()
                effectData.p_isPlay = true
                self:playGameEffect() -- 继续播放动画
            end)
        end
    end
end

--初始化base轮盘
function CodeGameScreenBeatlesMachine:randomSlotNodes( )
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex=1,rowCount do
            --local symbolType = self:getRandomReelType(colIndex,reelDatas)
            local symbolType = self:getSymbolByRowAndCol(rowIndex,colIndex)
            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType ,colIndex , reelDatas   )

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex,reelDatas)
            end

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)


            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                    node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node,
                    node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder - rowIndex)
                node:setVisible(true)
            end
            node.p_reelDownRunAnima = parentData.reelDownAnima
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * columnData.p_showGridH + halfNodeH )
        end
    end
    self:initGridList()
end

function CodeGameScreenBeatlesMachine:getSymbolByRowAndCol(row, col)
    local reel = {
        {4, 4, 94, 4, 4},
        {4, 94, 94, 94, 4},
        {94, 94, 94, 94, 94}
    }
    local symbol = reel[row][col]
    return symbol
end

function CodeGameScreenBeatlesMachine:getBaseReelGridNode()
    return "CodeBeatlesSrc.BeatlesSlotNode"
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenBeatlesMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "BeatlesSounds/Sound_Beatles_scatter_down.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

-- 刷新金币
function CodeGameScreenBeatlesMachine:updateReelGridNode(node)
    if node:isLastSymbol() then
        if self.m_isReconnection then
            --重连不显示收集的图标
            return
        end
        self:addItemToSymbol(node, node.p_rowIndex, node.p_cloumnIndex)
        local symnolType = node.p_symbolType
        if symnolType == self.SYMBOL_BOUNS_NORMAL then
            node.trailingNode = util_createAnimation("Socre_Beatles_bonus_tuowei.csb")
            node:addChild(node.trailingNode,-1)
        end
    else
        if self.m_isReconnection then
            --重连不显示收集的图标
            return
        end
        local symnolType = node.p_symbolType
        if symnolType == self.SYMBOL_BOUNS_NORMAL then
            node:addTrailing(self.m_slotParents[node.p_cloumnIndex].slotParent)
        end
    end

end

--在信号块上添加收集图标
function CodeGameScreenBeatlesMachine:addItemToSymbol(node, irow, icol)
    local reelsIndex = self:getPosReelIdx(irow, icol)
    local isHave, num = self:getSymbolIcon(reelsIndex)
    if isHave then
        if node.m_icon == nil then
            node.m_icon = util_createAnimation("Socre_Beatles_SymbolCoins.csb")
            node.m_icon:findChild("num"):setString(num)
            node.m_icon:setPosition(cc.p(64, -38))
            node:addChild(node.m_icon, 2)
        end
    end
end
--获取某个位置是否有牛币数据
function CodeGameScreenBeatlesMachine:getSymbolIcon(pos)
    local isHave = false
    local num = 0
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.store and 
        self.m_runSpinResultData.p_selfMakeData.store.score and #self.m_runSpinResultData.p_selfMakeData.store.score > 0 then
        local posTable = self.m_runSpinResultData.p_selfMakeData.store.score
        for posStr, coinNum in pairs(posTable) do
            local index = tonumber(posStr)-1
            if pos == index and coinNum > 0 then
                isHave = true
                num = coinNum
                break
            end
        end
    end
    return isHave, num
end

---
-- 显示所有的连线框
--
function CodeGameScreenBeatlesMachine:showAllFrame(winLines)

    if self.m_runSpinResultData.p_features[2] and self.m_runSpinResultData.p_features[2] == 5 then
        return
    end

    self.m_linesNode:setVisible(true)
    
    -- 最多有100连线 策划定死的
    for lineId = 1, 100 do
        self.m_linesNode:findChild("Sprite_"..lineId):setVisible(false)
    end
    self.m_models_action[8]:removeAllChildren()

    local addFrames = {}
    local checkIndex = 0
    for index = 1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s", "")
        end
        local frameId = lineValue.iLineIdx + 1

        if frameId > 0 then
            self.m_linesNode:findChild("Sprite_"..frameId):setVisible(true)
        end
    end
    for i = 1, #self.m_eachLineSlotNode do
        local slotsNodeTable = self.m_eachLineSlotNode[i]
        for j = 1, #slotsNodeTable do
            local slotsNode = slotsNodeTable[j]
            if slotsNode then
                if slotsNode.p_symbolType ~= self.SYMBOL_WILD_REEL then 
                    self:setSymbolToClip(slotsNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE)
                    slotsNode:runIdleAnim()
                else
                    slotsNode:runLineAnim()
                end
            end
        end

    end
end
---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenBeatlesMachine:showLineFrameByIndex(winLines, frameIndex)

    if self.m_runSpinResultData.p_features[2] and self.m_runSpinResultData.p_features[2] == 5 then
        return
    end

    self.m_linesNode:setVisible(true)

    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")
    end
    local frameId = lineValue.iLineIdx + 1

    if frameId > 0 then
        for lineId = 1, 100 do
            self.m_linesNode:findChild("Sprite_"..lineId):setVisible(false)
        end
        self.m_models_action[8]:removeAllChildren()

        for i = 1, #self.m_eachLineSlotNode do
            local slotsNodeTable = self.m_eachLineSlotNode[i]
            for j = 1, #slotsNodeTable do
                local slotsNode = slotsNodeTable[j]
                if slotsNode.p_symbolType ~= self.SYMBOL_WILD_REEL then
                    self:setSymbolToClip(slotsNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE)
                end
            end
        end

        if self.m_eachLineSlotNode ~= nil then
            local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
            if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
                for i = 1, #vecSlotNodes, 1 do
                    local slotsNode = vecSlotNodes[i]
                    if slotsNode.p_symbolType ~= self.SYMBOL_WILD_REEL then 
                        self:setSymbolToClip(slotsNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                    end
                    if slotsNode ~= nil then
                        if not tolua.isnull(slotsNode) then
                            slotsNode:runLineAnim()
                        end
                        if slotsNode.p_rowIndex and slotsNode.p_cloumnIndex then
                            local world_pos =  self:getNodePosByColAndRow(slotsNode.p_rowIndex, slotsNode.p_cloumnIndex)
                            local pos = self.m_models_action[8]:convertToNodeSpace(world_pos)
                            local kuang = util_createAnimation("WinFrameBeatles.csb")
                            kuang:setPosition(pos)
                            self.m_models_action[8]:addChild(kuang)
                        end
                        
                    end
                end
            end
        end
        self.m_linesNode:findChild("Sprite_"..frameId):setVisible(true)

    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenBeatlesMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if slotsNode.p_symbolType == self.SYMBOL_WILD_REEL then
                slotsNode:runLineAnim()
            else
                slotsNode:runIdleAnim()
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

-- 显示打开商店
function CodeGameScreenBeatlesMachine:showOpenOrCloseShop(isOpen)
    gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_shop_openOrClose.mp3")
    if isOpen then
        if self.m_spine_num and self.m_spine_num < 10 then
            local volume = gLobalSoundManager:getBackgroundMusicVolume()
            if volume == 1 then
                gLobalSoundManager:setBackgroundMusicVolume(1)
                self:removeSoundHandler( )
                -- self:checkTriggerOrInSpecialGame(function(  )
                --     self:reelsDownDelaySetMusicBGVolume( )
                -- end)
            end
        end

        self.m_ShopView:setVisible(isOpen)
        local lizi1 = self.m_ShopView:findChild("Particle_1")
        local lizi2 = self.m_ShopView:findChild("Particle_1_0")
    
        lizi1:resetSystem()
        lizi2:resetSystem()

        util_spinePlay(self.m_ShopView.shopSpine, "start", false)
        self.m_ShopView:runCsbAction("start",false,function ()
            self.m_ShopView:runCsbAction("idle",true)
        end)
        self.m_ShopView:setEndCall(function()
            self:featuresOverAddFreespinEffect()
            self:playGameEffect()

        end)
        
    else
        util_spinePlay(self.m_ShopView.shopSpine, "over", false)
        self.m_ShopView:runCsbAction("over",false,function(  )
            self.m_ShopView:setVisible(isOpen)
        end)
        if self.m_spine_num and self.m_spine_num < 10 then
            local volume = gLobalSoundManager:getBackgroundMusicVolume()
            if volume == 1 then
                gLobalSoundManager:setBackgroundMusicVolume(1)
                self:removeSoundHandler( )
                self:checkTriggerOrInSpecialGame(function(  )
                    self:reelsDownDelaySetMusicBGVolume( )
                end)
            end
        end
    end
    if not isOpen then
        local coins = self.m_runSpinResultData.p_selfMakeData.store.coins or 0
        self:setWaiXingNiuCoin(false,coins)
        self.m_ShopView:resetLimitData()
    end
end

-- free玩法显示大角色
function CodeGameScreenBeatlesMachine:changeShowDaJueSeFreeStart()
    self.m_daJueSePos = nil
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    local daJueSePos = {0,0,0,0,0}
    local daJueSeNum = 0
    if selfMakeData.level then--商店购买进入
        for id,num in ipairs(selfMakeData.level) do
            if id ~= 1 then
                if num > 0 then
                    daJueSePos[id-1] = num
                    daJueSeNum = daJueSeNum + 1
                else
                    daJueSePos[id-1] = num
                end
            end
        end
    else--base下触发free 5选1 进入
        daJueSePos[tonumber(selfMakeData.freetype)+1] = 1
        daJueSeNum = daJueSeNum + 1
    end

    -- 商店里 没有选择玩法 只是free 则直接return
    if daJueSeNum == 0 then
        return
    end
    self.m_daJueSePos = daJueSePos
    -- 先隐藏
    for roleId = 1,5 do
        self.m_freeJueSe:findChild("Node_juese"..roleId):setVisible(false)
        self.m_modes_tab[roleId]:setVisible(false)
    end
    --按对应大角色数量显示
    self.m_freeJueSe:findChild("Node_juese"..daJueSeNum):setVisible(true)
    local m = 0
    for id,num in ipairs(daJueSePos) do
        if num > 0 then
            m = m + 1
            self.m_modes_tab[id]:setVisible(true)
            local worldPos = self.m_freeJueSe:findChild("juese" .. daJueSeNum ..  "_"..m):getParent():convertToWorldSpace(cc.p(self.m_freeJueSe:findChild("juese" .. daJueSeNum ..  "_"..m):getPosition()))
            local endPos = self.m_modes_tab[id]:getParent():convertToNodeSpace(worldPos)
            self.m_modes_tab[id]:setPosition(endPos.x, endPos.y)

            self.m_modes_tab[id].m_role:setVisible(true)
            -- util_spinePlay(self.m_modes_tab[id].m_role, "idleframe3_2", false)
            -- util_spineEndCallFunc(self.m_modes_tab[id].m_role, "idleframe3_2", function()
            --     util_spinePlay(self.m_modes_tab[id].m_role, "idleframe3", true)        
            -- end)
            
        end
    end
    self.m_freeJueSe:setVisible(true)
end

-- free玩法结束恢复大角色
function CodeGameScreenBeatlesMachine:changeShowDaJueSeFreeOver( )
    self.m_linesNode:setVisible(false)
    self.m_models_action[8]:removeAllChildren()

    self:setReelBg(true, "over")
    -- self:resetRole()
    self:setSymbolToReel()
    gLobalNoticManager:postNotification("MODEITEMNUM_NUMBAR", {active = true})
    self.m_spinBar:isChangeBase(true)
    self.m_spine_num = BeatlesBaseData:getInstance():getDataByKey("spin_num")
    self.m_spinBar:updateSpinNum(self.m_spine_num)


    self.m_freeJueSe:setVisible(false)

    
    -- for id,num in ipairs(self.m_daJueSePos) do
    --     self.m_modes_tab[id]:setVisible(true)
    --     if num > 0 then
    --         self.m_modes_tab[id]:setPosition(cc.p(0, 0))
    --     end
    -- end
    self:resetBeginRole()
end

--滚轴停止回弹
function CodeGameScreenBeatlesMachine:reelSchedulerCheckColumnReelDown(parentData)
    local  slotParent = parentData.slotParent
    if parentData.isDone ~= true then
        parentData.isDone = true
        slotParent:stopAllActions()
        
        self:slotOneReelDown(parentData.cloumnIndex)
        
        local quickStopY = -35 --快停回弹距离
        if self.m_quickStopBackDistance then
            quickStopY = -self.m_quickStopBackDistance
        end
        -- local quickStopY = -self.m_configData.p_reelResDis --不读取配置
        local backTotalTotalTime = 0
        local symbolNodeList,start,over = self.m_reels[parentData.cloumnIndex].m_gridList:getList()
        for i = start,over do
            local allActionTime = 0
            local symbolNode = symbolNodeList[i]
            local speedActionTable = {}
            if self.m_isNewReelQuickStop then
                local originalPos = cc.p(symbolNode:getPosition())
                symbolNode:setPositionY(symbolNode:getPositionY() + quickStopY)

                local moveTime = self.m_configData.p_reelResTime
                if self:getGameSpinStage() == QUICK_RUN then
                    moveTime = 0.3
                end
                local back = cc.MoveTo:create(moveTime, originalPos)
                table.insert(speedActionTable,back)
                allActionTime = allActionTime + moveTime
            else
                local originalPos = cc.p(symbolNode:getPosition())
                local dis = self.m_configData.p_reelResDis
                local speedStart = parentData.moveSpeed
                local preSpeed = speedStart / 118
                local timeDown = self.m_configData.p_reelResTime
                if self:getGameSpinStage() ~= QUICK_RUN then
                    for i = 1, 10 do
                        speedStart = speedStart - preSpeed * (11 - i) * 2
                        local moveDis = dis / 10
                        local time = moveDis / speedStart
                        timeDown = timeDown + time
                        local moveBy = cc.MoveBy:create(time, cc.p(slotParent:getPositionX(), -moveDis))
                        table.insert(speedActionTable,moveBy)
                        allActionTime = allActionTime + time
                    end
                end

                local back = cc.MoveTo:create(timeDown, originalPos)
                table.insert(speedActionTable,back)
                allActionTime = allActionTime + timeDown
            end
        
            if i == over then
                local childTab = slotParent:getChildren()
                local tipSlotNoes = nil
                --添加提示节点
                tipSlotNoes = self:addReelDownTipNode(childTab)
                local actionNodeTip =
                    cc.CallFunc:create(
                    function()
                        if tipSlotNoes ~= nil then
                            local nodeParent = parentData.slotParent
                            for i = 1, #tipSlotNoes do
                                --播放提示动画
                                self:playReelDownTipNode(tipSlotNoes[i])
                            end
                        end
                    end
                )

                local actionFinishCallFunc = cc.CallFunc:create(
                function()
                    parentData.isResActionDone = true
                    if self.m_quickStopReelIndex and self.m_quickStopReelIndex == parentData.cloumnIndex then
                        self:newQuickStopReel(self.m_quickStopReelIndex)
                    end
                    self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
                end)

                if self.m_isShowSpecialNodeTip == true then
                    table.insert(speedActionTable, 1, actionNodeTip)
                end
                speedActionTable[#speedActionTable + 1] = actionFinishCallFunc

                symbolNode:runAction(cc.Sequence:create(speedActionTable))
            else
                symbolNode:runAction(cc.Sequence:create(speedActionTable))
            end

            if backTotalTotalTime < allActionTime then
                backTotalTotalTime = allActionTime
            end
        end
        if (not self.m_bProduceSlots_InFreeSpin) then
            if self.m_spine_num < 10 then
                self:reelStopHideMask(backTotalTotalTime,parentData.cloumnIndex)
            end
        end
    end
    return 0.1
end

return CodeGameScreenBeatlesMachine






