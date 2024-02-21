---
-- island li
-- 2019年1月26日
-- CodeGameScreenWinningFishMachine.lua
-- 
-- 玩法：
-- 
local BaseSlots = require "Levels.BaseSlots"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseDialog = require "Levels.BaseDialog"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local CodeGameScreenWinningFishMachine = class("CodeGameScreenWinningFishMachine", BaseNewReelMachine)


CodeGameScreenWinningFishMachine.m_isNotice = false

CodeGameScreenWinningFishMachine.m_csb_fps = 60     --csb帧率

CodeGameScreenWinningFishMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenWinningFishMachine.SYMBOL_BONUS_LINK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- bonus
CodeGameScreenWinningFishMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1

CodeGameScreenWinningFishMachine.EFFECT_BUBBLE_CLEAR   =   GameEffect.EFFECT_LINE_FRAME + 1     --气泡消除
CodeGameScreenWinningFishMachine.EFFECT_SELECT         =   GameEffect.EFFECT_EPICWIN + 1    --选择玩法
CodeGameScreenWinningFishMachine.EFFECT_FISH_SWIMMING  =   GameEffect.EFFECT_LINE_FRAME + 3     --金鱼游动

local JACKPOT_POOL = {
    {csbName = "Socre_WinningFish_jackpot_MINI.csb",parentNode = "WinningFish_jackpot_MINI"},
    {csbName = "Socre_WinningFish_jackpot_MINOR.csb",parentNode = "WinningFish_jackpot_MINOR"},
    {csbName = "Socre_WinningFish_jackpot_MAJOR.csb",parentNode = "WinningFish_jackpot_MAJOR"},
    {csbName = "Socre_WinningFish_jackpot_GRAND.csb",parentNode = "WinningFish_jackpot_GRAND"},
    {csbName = "Socre_WinningFish_jackpot_MEGA.csb",parentNode = "WinningFish_jackpot_MEGA"},
}

local CLEAN_BG = {
    "Socre_WinningFish_ChipJiman_mini_di.csb",
    "Socre_WinningFish_ChipJiman_minor_di.csb",
    "Socre_WinningFish_ChipJiman_major_di.csb",
    "Socre_WinningFish_ChipJiman_grand_di.csb",
    "Socre_WinningFish_ChipJiman_mega_di.csb"
}


-- 构造函数
function CodeGameScreenWinningFishMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_slotsAnimNodeFps = 60
    self.m_lineFrameNodeFps = 60 
    self.m_baseDialogViewFps = 60

    self.m_spinRestMusicBG = true

    self.m_spin_free_once = false

    self.m_isRespin_normal = false  --respin状态下普通滚动
    self.m_isNotice = false

    self.m_reelRunSound = "WinningFishSounds/sound_winningFish_quick_run.mp3"--快滚音效

    self.m_isBonusTrigger = false
    self.m_isFeatureOverBigWinInFree = true
    
    --init
    self:initGame()
end

function CodeGameScreenWinningFishMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i >= 3 then
            soundPath = "WinningFishSounds/sound_winningFish_scatter_3.mp3"
        else
            soundPath = "WinningFishSounds/sound_winningFish_scatter_"..i..".mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
        self.m_bonusBulingSoundArry[#self.m_bonusBulingSoundArry + 1] = "WinningFishSounds/sound_winningFish_link_"..i..".mp3"
    end
end

function CodeGameScreenWinningFishMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("WinningFishConfig.csv", "LevelWinningFishConfig.lua")
    self.m_configData.m_machine = self

    -- 中奖音效
    self.m_winPrizeSounds = {}
    for i = 1, 3 do
        self.m_winPrizeSounds[#self.m_winPrizeSounds + 1] = "WinningFishSounds/sound_winningFish_win_" .. i .. ".mp3"
    end

    

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenWinningFishMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "WinningFish"  
end

--[[
    获取respin界面
]]
function CodeGameScreenWinningFishMachine:getRespinView()
    return "CodeWinningFishSrc.WinningFishRespinView"
end

function CodeGameScreenWinningFishMachine:getRespinNode()
    return "CodeWinningFishSrc.WinningFishRespinNode"
end

---
-- 获取游戏区域reel height 这些都是在ccb中配置的 custom properties 属性， 但是目前无法从ccb读取，
-- cocos2dx 未开放接口
--
-- function CodeGameScreenWinningFishMachine:getReelHeight()
--     --宽高比小于16:10的类方屏尺寸,轮盘要放大
--     local radio = display.width / display.height
--     if radio > 1.3 and radio < 1.35 then
--         return 410
--     elseif radio <= 1.6  then
--         return 579
--     end
--     return self.m_reelHeight
-- end

-- function CodeGameScreenWinningFishMachine:getReelWidth()
--     --宽高比小于16:10的类方屏尺寸,轮盘要放大
--     local radio = display.width / display.height
--     if radio > 1.3 and radio < 1.35 then
--         return 1070
--     elseif radio <= 1.6  then
--         return 1120
--     end
--     return self.m_reelWidth
-- end

function CodeGameScreenWinningFishMachine:initUI()

    --初始化背景
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    --背景spin
    self.m_spin_bg = util_spineCreate("WinningFish_bg_base", true, true)
    self:findChild("bg"):addChild(self.m_spin_bg)
    self:changeBg_spin(3)
    

    --收集玩法气泡层
    self.m_bubbleNode = cc.Node:create()
    self:findChild("Node_reel"):addChild(self.m_bubbleNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)
    --全部气泡
    self.m_bubble_pool = {}
    --初始化气泡层
    self:initBubbleSymbol()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 20)

    --特效层(最上层)
    self.m_effectNode_top = cc.Node:create()
    self:addChild(self.m_effectNode_top,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    --freespinBar层
    self.m_freeSpinBarNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_freeSpinBarNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_respin_bg = {}
    for index = 1,self.m_iReelColumnNum do
        local clean_bg = util_createAnimation(CLEAN_BG[index])
        self.m_respin_bg[index] = clean_bg
        self.m_onceClipNode:addChild(clean_bg,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 100)
        clean_bg:setPosition(util_convertToNodeSpace(self:findChild("sp_reel_" .. (index - 1)),self.m_onceClipNode))
        clean_bg:setVisible(false)
    end

    --respin光效层
    self.m_effectNode_respin = {}
    self.m_effect_fast_bg = {}  --快滚背景
    for index=1,5 do
        self.m_effectNode_respin[index] = cc.Node:create()
        self:findChild("root"):addChild(self.m_effectNode_respin[index],SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + index)
        
        --奇数列才有快滚
        if index % 2 == 1 then
            local effect = util_createAnimation("WinFrameWinningFish_run_bg.csb")
            effect:runCsbAction("run",true) 
            self:findChild("sp_reel_"..(index - 1)):addChild(effect)
            self.m_effect_fast_bg[index] = effect
            effect:setVisible(false)
        end
    end

    --初始化黑色遮罩层
    self:initLayerBlack()

    --收集条
    self.m_collectionBar = util_createView("CodeWinningFishSrc.WinningFishCollectionBar")
    self:findChild("WinningFish_shoujitiao"):addChild(self.m_collectionBar)
    self.m_collectionBar:initMachine(self)

    --收集玩法
    self.m_bonusView = util_createView("CodeWinningFishSrc.WinningFishBonusGame")
    self:addChild(self.m_bonusView, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    
    --设置mechine
    self.m_bonusView:enableLocalData(self)
    self.m_bonusView:setVisible(false)

    --freeSpin背景节点
    self.m_freeSpinBgNode = self:findChild("Node_3RowBg_0")
    

    --创建jackpot
    self.m_jackpotPool = {}
    for index=1,5 do
        local jackpot = util_createView("CodeWinningFishSrc.WinningFishJackPot",{csbName = JACKPOT_POOL[index].csbName,pot_index = index})
        jackpot:initMachine(self)
        self.m_jackpotPool[index] = jackpot
        --变更背景的父节点
        local jackpot_bg = self:findChild("WinningFish_reel_yugang_"..(index - 1))
        local pos = util_convertToNodeSpace(jackpot_bg,self.m_clipParent)
        util_changeNodeParent(self.m_clipParent,jackpot_bg,SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 110)
        jackpot_bg:setPosition(pos)

        self.m_clipParent:addChild(jackpot, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 100) 
        jackpot:setPosition(util_convertToNodeSpace(self:findChild(JACKPOT_POOL[index].parentNode),self.m_clipParent))
        -- self:findChild(JACKPOT_POOL[index].parentNode):addChild(jackpot)
    end

    --jackpot获奖界面
    self.m_jackpot_win = util_createView("CodeWinningFishSrc.WinningFishJackPotWinView")
    self:addChild(self.m_jackpot_win,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 6)
    self.m_jackpot_win:setVisible(false)

    --过场动画
    self.m_changeView_ani = util_createAnimation("Socre_WinningFishGuochang.csb")
    self:findChild("root"):addChild(self.m_changeView_ani,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 7)
    self.m_changeView_ani:setVisible(false)

    --玩法选择界面
    self.m_select_view = util_createView("CodeWinningFishSrc.WinningFishSelectView")
    self:findChild("WinningFish_Choice"):addChild(self.m_select_view,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 8)
    self.m_select_view:setPosition(cc.p(-display.width / 2,-display.height / 2))
    self.m_select_view:setVisible(false)
    --设置mechine
    self.m_select_view:enableLocalData(self)
    
    --freespin光效
    self.m_effect_freespin_fp = util_createAnimation("Socre_WinningFish_fp.csb")
    local parentData = self.m_slotParents[5]
    parentData.slotParent:getParent():addChild(self.m_effect_freespin_fp,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)
    self.m_effect_freespin_fp:setPosition(util_convertToNodeSpace(self:findChild("fp"),parentData.slotParent:getParent()))
    self.m_effect_freespin_fp:runCsbAction("idle",true) 
    self.m_effect_freespin_fp:setVisible(false)

    -- gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

    --     if params[self.m_stopUpdateCoinsSoundIndex] then
    --         -- 此时不应该播放赢钱音效
    --         return
    --     end
        
    --     if self.m_bIsBigWin then
    --         return
    --     end

    --     -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
    --     local winCoin = params[1]
        
    --     local totalBet = globalData.slotRunData:getCurTotalBet()
    --     local winRate = winCoin / totalBet
    --     local soundIndex = 2
    --     if winRate <= 1 then
    --         soundIndex = 1
    --     elseif winRate > 1 and winRate <= 3 then
    --         soundIndex = 2
    --     elseif winRate > 3 and winRate <= 6 then
    --         soundIndex = 3
    --     elseif winRate > 6 then
    --         soundIndex = 4
    --     end

    --     local soundTime = soundIndex
    --     if self.m_bottomUI  then
    --         soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
    --     end

    --     local soundName = "WinningFishSounds/music_WinningFish_last_win_".. soundIndex .. ".mp3"
    --     self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
    -- end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end
--
--[[
    背景spin修改
    type_bg:    1 freespin状态下背景
                2 freespin_normal   freespin转化为普通背景
                3 normal状态下背景
                4 normal_freespin   普通背景转化为freespin背景
]]
function CodeGameScreenWinningFishMachine:changeBg_spin(type_bg)
    if type_bg == 1 then --freespin状态
        util_spinePlay(self.m_spin_bg,"freespin",true)
        self:runCsbAction("freespin",true,nil,self.m_csb_fps)
    elseif type_bg == 2 then --freespin转normal
        self:runCsbAction("freespin_normal",false,nil,self.m_csb_fps)
        util_runAnimations({
            {
                type = "spine",
                node = self.m_spin_bg,   
                actionName = "freespin_normal", 
                callBack = function (  )
                    self:changeBg_spin(3)
                end,   --回调函数 可选参数
            }
        })
    elseif type_bg == 3 then    --普通状态
        util_spinePlay(self.m_spin_bg,"normal",true)
        self:runCsbAction("normal",true,nil,self.m_csb_fps)
    else --normal转freespin
        self:runCsbAction("normal_freespin",false,nil,self.m_csb_fps)
        util_runAnimations({
            {
                type = "spine", 
                node = self.m_spin_bg,   
                actionName = "normal_freespin", 
                callBack = function (  )
                    self:changeBg_spin(1)
                end,   --回调函数 可选参数
            }
        })
    end
end

--[[
    过场动画
]]
function CodeGameScreenWinningFishMachine:changeViewAni(func)
    self.m_changeView_ani:setVisible(true)
    self.m_changeView_ani:findChild("Particle_1"):resetSystem()
    self.m_changeView_ani:findChild("Particle_1_0"):resetSystem()
    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_changeView_ani,   --执行动画节点  必传参数
        actionName = "normal_freespin", --动作名称  动画必传参数,单延时动作可不传
        fps = self.m_csb_fps,    --帧率  可选参数
        callBack = function (  )
            self.m_changeView_ani:setVisible(false)
        end,   
    }
    util_runAnimations(params)
    local node_waiting = cc.Node:create()
    self:addChild(node_waiting)
    performWithDelay(node_waiting,function()
        node_waiting:removeFromParent(true)
        if type(func) == "function" then
            func()
        end
    end,2)
end

function CodeGameScreenWinningFishMachine:initFreeSpinBar()
    if globalData.slotRunData.isPortrait == false then
        local node_bar = self:findChild("WinningFish_Freespintime")
        self.m_baseFreeSpinBar = util_createView("CodeWinningFishSrc.WinningFishFreespinBarView")
        self.m_freeSpinBarNode:addChild(self.m_baseFreeSpinBar)
        self.m_baseFreeSpinBar:setPosition(util_convertToNodeSpace(node_bar,self.m_freeSpinBarNode))
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
    end
end

function CodeGameScreenWinningFishMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar:runCsbAction("start",false,function (  )
        self.m_baseFreeSpinBar:runCsbAction("idle")
    end) 
end

function CodeGameScreenWinningFishMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

--[[
    是否显示收集玩法相关控件
]]
function CodeGameScreenWinningFishMachine:showCollectionRes(isShow)
    if not isShow then
        self.m_collectionBar:hideAni()
    else
        self.m_collectionBar:showAni()
    end
    
    self.m_bubbleNode:setVisible(isShow)
end

--[[
    初始化黑色遮罩层
]]
function CodeGameScreenWinningFishMachine:initLayerBlack()
    self.m_layer_colors = {}
    for index =1 ,#self.m_slotParents do
        local parentData = self.m_slotParents[index]
        
        local colNodeName = "sp_reel_" .. (index - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY


        local node = cc.Node:create()
        parentData.slotParent:getParent():addChild(node,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)

        local slotParentNode_1 = cc.LayerColor:create(cc.c3b(0, 0, 0)) 
        slotParentNode_1:setOpacity(210)
        slotParentNode_1:setContentSize(reelSize.width + (index == self.m_iReelColumnNum and 0 or 15), reelSize.height)
        slotParentNode_1:setPositionX(reelSize.width * 0.5)
        node:addChild(slotParentNode_1,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)

        self.m_layer_colors[index] = node
        node:setVisible(false)

    end

    -- local colorLayers = util_createReelMaskColorLayers( self ,REEL_SYMBOL_ORDER.REEL_ORDER_2 ,cc.c3b(0, 0, 0),200 )
    -- self.m_layer_colors = colorLayers
    -- for key,layer in pairs(self.m_layer_colors) do
    --     local size = layer:getContentSize()
    --     layer:setContentSize(isShow)
    -- end
end

--[[
    显示黑色遮罩层
]]
function CodeGameScreenWinningFishMachine:showLayerBlack(isShow)
    for key,layer in pairs(self.m_layer_colors) do
        layer:setVisible(isShow)
    end
end

--[[
    初始化气泡层
]]
function CodeGameScreenWinningFishMachine:initBubbleSymbol()
    for iCol=1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local bubble = util_createAnimation("Socre_WinningFish_Qipao.csb")
            --获取小块索引
            local index = self:getPosReelIdx(iRow ,iCol,self.m_iReelRowNum)
            self.m_bubbleNode:addChild(bubble,index,index)
            --转化坐标位置    
            local pos = cc.p(util_getOneGameReelsTarSpPos(self,index))  
            bubble:setPosition(pos)

            --存储气泡
            self.m_bubble_pool[tostring(index)] = bubble
        end
    end
end

--[[
    刷新气泡
]]
function CodeGameScreenWinningFishMachine:refreshBubbleSymbol()
    --数据安全判定
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    local bubblePos = self.m_runSpinResultData.p_selfMakeData.bubblePos or {}
    for iCol=1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local index = self:getPosReelIdx(iRow ,iCol,self.m_iReelRowNum)
            --获取气泡
            local bubble = self.m_bubble_pool[tostring(index)]

            --判断小块是否已消除
            if table.indexof(bubblePos,index) then
                bubble:setVisible(false)
            else
                bubble:setVisible(true)
            end
        end
    end
end

--[[
    刷新进度条
]]
function CodeGameScreenWinningFishMachine:refreshCollectionBar(isReconnect)
    --数据安全判定
    local selfData = self.m_runSpinResultData.p_selfMakeData 
    --选择界面断线重连会先播气泡收集,导致气泡数量错误
    if not selfData then
        return
    end
    local bubblePos = self.m_runSpinResultData.p_selfMakeData.bubblePos or {}
    local curBubble = self.m_runSpinResultData.p_selfMakeData.currentBubble or {}
    if isReconnect and selfData.bonusType and self.bonusType == "select" then
        self.m_collectionBar:updateProgress(#bubblePos - #curBubble)
    else
        self.m_collectionBar:updateProgress(#bubblePos)
    end
    
end



--[[
    刷新小块
]]
function CodeGameScreenWinningFishMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType    --信号类型
    local reelNode = node
    if symbolType and symbolType == self.SYMBOL_BONUS_LINK then    --Bouns信号
        --下帧调用 才可能取到 x y值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{reelNode})
        self:runAction(callFun)
    end
end

--[[
    设置特殊小块分数
]]
function CodeGameScreenWinningFishMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local score = 1
    --判断是否为真实数据
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --获取真实分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons
        if storedIcons then
            score = self:getSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) or 1
        end
        
    else
        --设置假滚Bonus,随机分数
        score = self:randomDownSymbolScore(symbolNode.p_symbolType)
        if score == nil then
            score = 1
        end
    end

    if score and type(score) ~= "string" then
        --获取当前下注
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet
        --格式化字符串
        score = util_formatCoins(score, 3)
        if symbolNode then
            local lbl_score = symbolNode:getCcbProperty("BitmapFontLabel_1")
            local info={label = lbl_score,sx = 0.62,sy = 0.62}
            if lbl_score then
                lbl_score:setString(score)
                self:updateLabelSize(info,240)
            end
        end
    end
end

--[[
    获取小块真实分数
]]
function CodeGameScreenWinningFishMachine:getSpinSymbolScore(id)
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

    return score
end

--[[
    随机bonus分数
]]
function CodeGameScreenWinningFishMachine:randomDownSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_BONUS_LINK then
        score = self.m_configData:getBnBasePro(1)
    end

    return score
end

--[[
    调整特殊信号层级
]]
function CodeGameScreenWinningFishMachine:getBounsScatterDataZorder(symbolType)
    
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    if symbolType == self.SYMBOL_BONUS_LINK then
        return REEL_SYMBOL_ORDER.REEL_ORDER_3
    end

    local symbolOrder = BaseSlots.getBounsScatterDataZorder(self, symbolType)

    return symbolOrder
end


function CodeGameScreenWinningFishMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound( "WinningFishSounds/sound_winningFish_enter_game.mp3" )
      scheduler.performWithDelayGlobal(function(  )
        if self:getCurrSpinMode() == NORMAL_SPIN_MODE and not self.m_bonusView:isVisible() and not self.m_select_view:isVisible() then
            self:resetMusicBg()
            self:reelsDownDelaySetMusicBGVolume( ) 
        end
      end,3,self:getModuleName())
    end,2,self:getModuleName())
end

function CodeGameScreenWinningFishMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

--[[
    设置轮盘是否显示
]]
function CodeGameScreenWinningFishMachine:setBaseReelShow(isShow)
    if self:findChild("node_base") then
        self:findChild("node_base"):setVisible(isShow)
    end
end

--[[
    接收网络回调
]]
function CodeGameScreenWinningFishMachine:updateNetWorkData()
    -- self.m_runSpinResultData
    gLobalDebugReelTimeManager:recvStartTime()

    if self.m_chooseRepinGame and self.m_select_view:isVisible() then
        self.m_select_view:hideView() 
    end
    
    
    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()
    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    --预告中奖
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData.notice and selfData.notice == 1  then
    -- if false then
        --预告中奖不允许快停
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        
        self.m_isRespin_normal = true

        self.m_isNotice = true
        
        self:netBackUpdateReelDatas()

        self:noticeOfWinning(function(  )
            
            self:netBackStopReel()
        end)
    else
        for key,mode in pairs(self.m_runSpinResultData.p_features) do
            if mode == SLOTO_FEATURE.FEATURE_RESPIN then
                self.m_isRespin_normal = true
                break
            end
        end
        self:netBackStopReel()
    end
end


function CodeGameScreenWinningFishMachine:netBackStopReel( )
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()  -- end

    --第一次进freespin走selfeffect
    if self.isStartFreeSpin then
        self.isStartFreeSpin = false
        return
    end

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
        -- 刷新wild
        self:refreshFreeSpinWilds()
    end
end
---
-- 重写父类接口
--
function CodeGameScreenWinningFishMachine:checkNetDataFeatures()

    local featureDatas =self.m_runSpinResultData and self.m_runSpinResultData.p_features
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

            if self.checkControlerReelType and self:checkControlerReelType( ) then
                globalMachineController.m_isEffectPlaying = true
            end

            self.m_isRunningEffect = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                local checkEnd = false
                if lineData.p_iconPos ~= nil then
                    for posIndex = 1 , #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex] 
    
                        local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
    
                        local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            checkEnd = true
                            local lineInfo = self:getReelLineInfo()
                            local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    
                            for addPosIndex = 1 , #lineData.p_iconPos do
    
                                local posData = lineData.p_iconPos[addPosIndex]
                                local rowColData = self:getRowAndColByPos(posData)
                                lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
    
                            end
    
                            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
                            self.m_reelResultLines = {}
                            self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                            break
                        end
                    end
                end
                if checkEnd == true then
                    break
                end

            end
            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            local params = {self.m_runSpinResultData.p_fsWinCoins,false,false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)

            -- self:sortGameEffects( )
            -- self:playGameEffect()

        elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then  -- respin 玩法一并通过respinCount 来进行判断处理
            
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            
            -- if self.m_initFeatureData.p_status=="CLOSED" then
            --     return
            -- end

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加bonus effect
            if self.m_runSpinResultData.p_selfMakeData.bonusType and self.m_runSpinResultData.p_selfMakeData.bonusType == "select" then
                self:addSelfEffect()
            elseif self.m_runSpinResultData.p_selfMakeData.bonusType and self.m_runSpinResultData.p_selfMakeData.bonusType == "pick" then
                local bonusGameEffect = GameEffectData.new()
                bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
                bonusGameEffect.p_effectOrder = GameEffect.EFFECT_QUEST_DONE + 1
                self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

                if self.checkControlerReelType and self:checkControlerReelType( ) then
                    globalMachineController.m_isEffectPlaying = true
                end
                
                self.m_isRunningEffect = true
            end
            
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})


            for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                local checkEnd = false
                for posIndex = 1 , #lineData.p_iconPos do
                    local pos = lineData.p_iconPos[posIndex] 

                    local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                    local colIndex = pos % self.m_iReelColumnNum + 1

                    local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                        checkEnd = true
                        local lineInfo = self:getReelLineInfo()
                        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS

                        for addPosIndex = 1 , #lineData.p_iconPos do

                            local posData = lineData.p_iconPos[addPosIndex]
                            local rowColData = self:getRowAndColByPos(posData)
                            lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData

                        end

                        lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                        self.m_reelResultLines = {}
                        self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                        break
                    end
                end
                if checkEnd == true then
                    break
                end

            end

            -- self:sortGameEffects( )
            -- self:playGameEffect()


        end
    end

end

--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenWinningFishMachine:checkTriggerINFreeSpin( )
    local isPlayGameEff = false

    -- 检测是否处于
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    local hasReSpinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
        hasReSpinFeature = true
    end

    local hasBonusFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        hasBonusFeature = true
    end

    local isInFs = false
    if hasFreepinFeature == false and 
            self.m_initSpinData.p_freeSpinsTotalCount ~= nil and 
            self.m_initSpinData.p_freeSpinsTotalCount > 0 and 
            (self.m_initSpinData.p_freeSpinsLeftCount > 0) then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
    end

    if isInFs == true then
    
        self:changeFreeSpinReelData()
        
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        
        self:setCurrSpinMode( FREE_SPIN_MODE)

        if self:checkTriggerFsOver( ) then
            local fsOverEffect = GameEffectData.new()
            fsOverEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            fsOverEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = fsOverEffect
        end

        -- 发送事件显示赢钱总数量
        local params = {self.m_runSpinResultData.p_fsWinCoins,false,false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff=true
    end

    return isPlayGameEff
end

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenWinningFishMachine:checkHasGameEffectType(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i=1 ,effectLen , 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == effectType then
            if effectType == GameEffect.EFFECT_RESPIN then
                self.m_isRespin_normal = true
            end
            return true
        end
    end

    return false
end

--[[
    获取随机信号初始化轮盘
]]
function CodeGameScreenWinningFishMachine:randomSlotNodes( )
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]
        for rowIndex=1,rowCount do
            local symbolType = self:getNormalSymbol(colIndex)
            --特殊需求 初始化轮盘不出现特殊信号
            while true do
                if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    break
                end
                symbolType = self:getNormalSymbol(colIndex)
            end

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = columnData.p_showGridH      
           
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex
           

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
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
            node:setPositionY(  (rowIndex - 1) * columnData.p_showGridH + halfNodeH )

           
        end
    end
    self:initGridList()
end

-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
function CodeGameScreenWinningFishMachine:initCloumnSlotNodesByNetData()
    --初始化节点
    self.m_initGridNode = true
    self:respinModeChangeSymbolType()
    for colIndex=self.m_iReelColumnNum,  1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels
        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum  -- 返回来的数据1位置是最上面一行。
        while rowIndex >= 1 do
            if not self.m_initSpinData.p_reels then
                break
            end
            local reels = self.m_initSpinData.p_reels or {}
            local rowDatas = reels[rowIndex] or {}
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]

            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType  )

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType,changeRowIndex,colIndex,true)
            node.p_slotNodeH = columnData.p_showGridH
            node.p_showOrder = self:getBounsScatterDataZorder(symbolType) - changeRowIndex
            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder)
                node:setVisible(true)
            end
            node.p_symbolType = symbolType
            node.p_reelDownRunAnima = parentData.reelDownAnima
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:runIdleAnim()      
            rowIndex = rowIndex - 1
        end  -- end while
    end
    self:initGridList()
end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData:
    @return:
]]
function CodeGameScreenWinningFishMachine:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self:getNextReelSymbolType( )
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then

        
        if self.m_isNotice then   --respin假滚
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(2, parentData.cloumnIndex)
        elseif self.m_isRespin_normal then   --respin假滚
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(2, parentData.cloumnIndex)
        elseif self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif
            globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE
            then
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

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenWinningFishMachine:checkUpdateReelDatas(parentData )
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    elseif self.m_isNotice then -- 只用作预告中奖修改假滚数据
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(2, parentData.cloumnIndex)
    elseif self.m_isRespin_normal then   --respin假滚
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(2, parentData.cloumnIndex)
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

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenWinningFishMachine:initGameStatusData(gameData)
    if not globalData.userRate then
        local UserRate = require "data.UserRate"
        globalData.userRate = UserRate:create()
    end
    globalData.userRate:enterLevel(self:getModuleName())
    if gameData.gameConfig ~= nil and  gameData.gameConfig.isAllLine ~= nil then
        self.m_isAllLineType = gameData.gameConfig.isAllLine
    end

    -- spin  
    -- feature  
    -- sequenceId
    local operaId = gameData.sequenceId

    self.m_initBetId = (gameData.betId or -1)

    local spin = gameData.spin
    -- spin = nil
    local freeGameCost = gameData.freeGameCost
    local feature = gameData.feature
    local collect = gameData.collect
    local jackpot = gameData.jackpot
    local totalWinCoins = nil
    if gameData.spin then
        totalWinCoins = gameData.spin.freespin.fsWinCoins
    end
    if totalWinCoins == nil then
        totalWinCoins = 0
    end
 
    self.m_freeSpinStartCoins = globalData.userRunData.coinNum ---gameData.totalWinCoins
    self.m_freeSpinOffSetCoins = 0--gameData.totalWinCoins
    self:setLastWinCoin( totalWinCoins )

    if spin ~= nil then
        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spin,self.m_lineDataPool,self.m_symbolCompares,feature)
        self.m_initSpinData = self.m_runSpinResultData
    end
    if feature ~= nil then
        self.m_initFeatureData = SpinFeatureData.new()
        if feature.bonus then
            if feature.bonus then
                -- if feature.bonus.status == "CLOSED" and feature.bonus.content ~= nil then
                --     local bet = feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1]
                --     feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1] = - bet
                -- end
                feature.choose = feature.bonus.choose
                feature.content = feature.bonus.content
                feature.extra = feature.bonus.extra
                feature.status = feature.bonus.status
    
            end
        end 
        self.m_initFeatureData:parseFeatureData(feature)
        -- self.m_initFeatureData:setAllLine(self.m_isAllLineType)
    end

    if freeGameCost then
        --免费送spin活动数据
        self.m_rewaedFSData = freeGameCost 
    end
    
    if collect and type(collect)=="table" and #collect>0 then
        for i=1,#collect do
            self.m_collectDataList[i]:parseCollectData(collect[i])
        end
    end
    if jackpot and type(jackpot)=="table" and #jackpot>0 then
        self.m_jackpotList=jackpot
    end
    if not self.m_jackpotList then
        self:updateJackpotList()
    end

    if gameData.gameConfig ~= nil  then
        if gameData.gameConfig.bonusReels ~= nil then
            self.m_runSpinResultData["p_bonusReels"] = gameData.gameConfig.bonusReels
        end
        
        if gameData.gameConfig.init and gameData.gameConfig.init.bubblePos then
            self.m_runSpinResultData.p_selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
            self.m_runSpinResultData.p_selfMakeData.bubblePos = gameData.gameConfig.init.bubblePos
        end
    end


    if not self.m_jackpotList then
        self:updateJackpotList()
    end

    self.m_gameCrazeBuff = gameData.gameCrazyBuff or false

    self:initMachineGame()
end

function CodeGameScreenWinningFishMachine:showEffect_LineFrame(effectData)

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end 
    end
    
    
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
        self.m_effectNode:setVisible(false)
    end
    
    self:showLineFrame()

    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
     or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 0.5)
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    return true

end

function CodeGameScreenWinningFishMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)
        for index,jackpot in pairs(self.m_jackpotPool) do
            jackpot:updateJackpotInfo()
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self, params)
        self.m_collectionBar:refreshTip(true)
    end,ViewEventType.NOTIFY_CLOSE_PIG_TIPS)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if self.m_bIsBigWin or self.m_bonusView:isVisible() then
            return
        end
        local winAmonut = params[1]
        if type(winAmonut) == "number" then
            local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
            local winRatio = winAmonut / lTatolBetNum
            local soundName = nil
            local soundTime = 2
            if winRatio > 0 then
                if winRatio <= 1 then
                    soundName = self.m_winPrizeSounds[1]
                elseif winRatio > 1 and winRatio <= 3 then
                    soundName = self.m_winPrizeSounds[2]
                elseif winRatio > 3 then
                    soundName = self.m_winPrizeSounds[3]
                    soundTime = 3
                end
            end

            if soundName ~= nil then
                self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
            end
        end

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenWinningFishMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenWinningFishMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS_LINK then
        return "Socre_WinningFish_Chip"
    end
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_WinningFish_10"
    end

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_WinningFish_Scatter_1"
    end
    
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenWinningFishMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function CodeGameScreenWinningFishMachine:addBonusEffect( )
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
    -- 添加bonus effect
    local bonusGameEffect = GameEffectData.new()
    bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
    bonusGameEffect.p_effectOrder = GameEffect.EFFECT_QUEST_DONE + 1
    self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
    self.m_isRunningEffect = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})

end

-----by he 将除自定义动画之外的动画层级赋值
--
function CodeGameScreenWinningFishMachine:setGameEffectOrder()
    if self.m_gameEffects == nil then
        return
    end

    local lenEffect = #self.m_gameEffects
    for i = 1, lenEffect, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType ~= GameEffect.EFFECT_SELF_EFFECT then
            if effectData.p_effectType == GameEffect.EFFECT_BONUS then
                effectData.p_effectOrder = GameEffect.EFFECT_QUEST_DONE + 1
            else
                effectData.p_effectOrder = effectData.p_effectType
            end
            
        end
    end
end

function CodeGameScreenWinningFishMachine:initFeatureInfo(spinData,featureData)

    if featureData.p_bonus and featureData.p_bonus.status == "OPEN" then
        self.m_runSpinResultData.p_bonus = featureData.p_bonus
        self:addBonusEffect()
        if featureData.p_bonus then
            --刷新剩余次数
            self.m_runSpinResultData.p_selfMakeData.pickTimes = featureData.p_bonus.extra.pickTimes
        end
    elseif featureData.p_bonus and featureData.p_bonus.status == "CLOSED" then
        self.m_runSpinResultData.p_selfMakeData = {}
    end
end


-- 断线重连 
function CodeGameScreenWinningFishMachine:MachineRule_initGame()
    --初始化气泡层
    self:refreshBubbleSymbol()

    --刷新收集进度条
    self:refreshCollectionBar(true)

    
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
        self:showCollectionRes(false)
        self:changeBg_spin(1)
    end
    
    
end

--[[
    添加快滚特效
]]
function CodeGameScreenWinningFishMachine:creatReelRunAnimation(col)
    CodeGameScreenWinningFishMachine.super.creatReelRunAnimation(self,col)
    if col % 2 == 1 then
        self.m_effect_fast_bg[col]:setVisible(true)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenWinningFishMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol) 
    if reelCol % 2 == 1 then
        self.m_effect_fast_bg[reelCol]:setVisible(false)
    end

    for iRow = self.m_iReelRowNum, 1, -1 do
        local slotNode = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if slotNode.p_symbolType == self.SYMBOL_BONUS_LINK then
            self.m_bonusNum = self.m_bonusNum + 1
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,self.m_bonusBulingSoundArry[self.m_bonusNum],self.SYMBOL_BONUS_LINK )
            else
                gLobalSoundManager:playSound(self.m_bonusBulingSoundArry[self.m_bonusNum])
            end
        
            break;
        end
    end
    if reelCol == self.m_iReelColumnNum then
        self.m_spin_free_once = false
        self:setMaxMusicBGVolume( )
        self:checkTriggerOrInSpecialGame(function(  )
            self:reelsDownDelaySetMusicBGVolume( ) 
        end)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end
end

function CodeGameScreenWinningFishMachine:checkSymbolTypePlayTipAnima( symbolType )

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then
        return true
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS  then
        return true
    elseif symbolType == self.SYMBOL_BONUS_LINK  then
        return true
    end

end

--播放提示动画
function CodeGameScreenWinningFishMachine:playReelDownTipNode(slotNode)

    self:playScatterBonusSound(slotNode)
    slotNode:runAnim("buling",false,function(  )
        slotNode:runAnim("idleframe",true)
    end)
    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
    self:specialSymbolActionTreatment( slotNode)
end

--[[
    是否播放落地动画
]]
function CodeGameScreenWinningFishMachine:isPlayTipAnima(matrixPosY, matrixPosX, node)
    local nodeData = self.m_reelRunInfo[matrixPosY]:getSlotsNodeInfo()

    if node.p_symbolType == self.SYMBOL_BONUS_LINK then
        return true
    end

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

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenWinningFishMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenWinningFishMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    
end
---------------------------------------------------------------------------
--[[
    初始化RespinView
]]
-- function CodeGameScreenWinningFishMachine:initRespinView(endTypes, randomTypes)
    
-- end

--[[
    ReSpin过场
]]
function CodeGameScreenWinningFishMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    func()
end

--[[
    显示ReSpinView
]]
function CodeGameScreenWinningFishMachine:showRespinView(effectData)
    --可随机的普通信息
    local randomTypes = {
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

    --可随机的特殊信号
    local endTypes = {
        {type = self.SYMBOL_BONUS_LINK, runEndAnimaName = "", bRandom = true}
    }

    --隐藏收集玩法相关控件
    self:showCollectionRes(false)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self.node_mask_ary = {}

    function startAction(  )
        local rsExtraData = self.m_runSpinResultData.p_rsExtraData
        local showJackPots = {}  --需要显示Jackpot
        for key,times in pairs(rsExtraData.reSpinTimes) do
            if self:isRespinCol(key) then   --统计显示的jackpot
                local jackpot = self.m_jackpotPool[key]
                table.insert(showJackPots,#showJackPots + 1,{jackpot = jackpot,index = key})
                jackpot:refreshTimes(times,true)
            else
                --显示变黑动画
                self.m_jackpotPool[key]:turnToBlack(1)
            end
        end

        --递归触发jackpot显示动画
        local showIndex = 1
        function showJackPotStart()
            local jackpot = showJackPots[showIndex]
            if not jackpot then
                return
            end
            --播放Link图标特效
            for iRow =1,self.m_iReelRowNum do
                local symbol = self:getFixSymbol(jackpot.index, iRow)
                if symbol.p_symbolType ~= nil and symbol.p_symbolType == self.SYMBOL_BONUS_LINK  then
                    symbol:getCCBNode():runAnim("actionframe2",false,function(  )
                        symbol:getCCBNode():runAnim("idleframe",true)
                    end,self.m_csb_fps)
                end
            end

            jackpot.jackpot:startAni(function (  )
                showIndex = showIndex + 1
                if showIndex > #showJackPots then
                    self.m_isRespin_normal = false
                    self:showLayerBlack(false)
                    
                    --开始触发respin
                    self:triggerReSpinCallFun(endTypes, randomTypes)
                else
                    showJackPotStart()
                end
            end)
        end

        showJackPotStart()
    end

    for index=1,20 do
        local mask = util_createAnimation("Socre_WinningFish_Linkdiban.csb")
        self.m_onceClipNode:addChild(mask,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE+1)
        mask:setPosition(util_getOneGameReelsTarSpPos(self,index - 1))
        mask:setScale(1.03)
        self.node_mask_ary[#self.node_mask_ary + 1] = mask
        util_runAnimations({
            {
                    type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                    node = mask,   --执行动画节点  必传参数
                    actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
                    fps = 60,    --帧率  可选参数
                    index = index,
                    callBack = function(  )
                        mask:runCsbAction("idleframe")
                    end,   --回调函数 可选参数
            }
        })
        
    end

    local node_waitting = cc.Node:create()
    self:addChild(node_waitting)
    performWithDelay(node_waitting,handler(nil,function (  )
        node_waitting:removeFromParent(true)
        startAction()
    end),0.5)
    
end

--触发respin
function CodeGameScreenWinningFishMachine:triggerReSpinCallFun(endTypes, randomTypes)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    local clipNode = self:createOneClipLayout()
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType,iRow,iCol,isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    clipNode:addChild(self.m_respinView)
    self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)
end

--[[
    创建裁切节点 respin用
]]
function CodeGameScreenWinningFishMachine:createOneClipLayout()
    local iColNum = self.m_iReelColumnNum
    local reel = self:findChild("sp_reel_0")
    local startX = reel:getPositionX()
    local startY = reel:getPositionY()
    local reelEnd = self:findChild("sp_reel_"..(iColNum-1))
    local endX = reelEnd:getPositionX()
    local endY = reelEnd:getPositionY()
    local reelSize = reelEnd:getContentSize()
    local scaleX = reelEnd:getScaleX()
    local scaleY = reelEnd:getScaleY()
    reelSize.width = reelSize.width * scaleX
    reelSize.height = reelSize.height * scaleY
    local offX = reelSize.width * 0.5
    endX = endX - startX + reelSize.width
    endY = reelSize.height
    local layout = ccui.Layout:create()
    layout:setClippingEnabled(true)
    layout:setContentSize(CCSizeMake(endX,endY))
    layout:setAnchorPoint(cc.p(0.5,0.5))
    layout:setPosition(cc.p(0,startY + reelSize.height / 2))
    return layout
end

function CodeGameScreenWinningFishMachine:respinOver()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    local node_waitting = cc.Node:create()
    self:addChild(node_waitting)
    --等待jackpot动作完成
    util_runAnimations({
        {
            type = "delay",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = node_waitting,   --执行动画节点  必传参数
            delayTime = 1.5,  --延时事件  可选参数
            callBack = function()
                --respin结算后移除respin节点
                self:showRespinOverView(nil,function (  )
                    
                end)
                

                local resNodeRow = 5
                for iCol =1,self.m_iReelColumnNum do
                    local symbol = self:getFixSymbol(iCol, resNodeRow)
                    if symbol then
                        util_changeNodeParent(symbol.m_baseNode,symbol,self:getBounsScatterDataZorder(symbol.p_symbolType) - resNodeRow)
                    end
                end
                node_waitting:removeFromParent(true)
            end,   --回调函数 可选参数
        }
    })

    
end

--结束移除小块调用结算特效
function CodeGameScreenWinningFishMachine:removeRespinNode()
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

    --respin单独加了裁切layout,需要将父节点一起移除
    self.m_respinView:getParent():removeFromParent()
    self.m_respinView = nil
end

--[[
    respin玩法结束
]]
function CodeGameScreenWinningFishMachine:showRespinOverView(effectData,callback)
    local strCoins = util_formatCoins(self.m_serverWinCoins, 20)

    local jackpotsWin = self.m_runSpinResultData.p_rsExtraData.jackpotsWin
    local jackIndex = 1
    

    local cleanNodes = self.m_respinView:getAllCleaningNode()
    local cleanIndex = 1
    local winCount = 0
    --结算所有小块
    function showCleanNodesByCol(colIndex,func)
        if cleanIndex <= #cleanNodes[colIndex] then --获得jackpot奖励
            local node = cleanNodes[colIndex][cleanIndex]
            node:setVisible(false)
            local score = self:getSpinSymbolScore(self:getPosReelIdx(node.p_rowIndex, node.p_cloumnIndex)) or 1
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            winCount = winCount + score
            --添加临时结算节点
            local clip_node_temp = util_createAnimation("Socre_WinningFish_Chip.csb")
            local lbl_score = clip_node_temp:findChild("BitmapFontLabel_1")
            local info={label = lbl_score,sx = 0.62,sy = 0.62}
            if lbl_score then
                lbl_score:setString(util_formatCoins(score, 3))
                self:updateLabelSize(info,240)
            end
            clip_node_temp:setPosition(util_convertToNodeSpace(node,self.m_effectNode))
            self.m_effectNode:addChild(clip_node_temp)

            --创建临时光效用于执行动作
            -- local light_temp = util_createAnimation("Socre_WinningFish_jiesuan.csb")
            -- self.m_bottomUI.coinWinNode:addChild(light_temp)
            -- util_runAnimations({
            --     {   --底部ui光效
            --         type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            --         node = light_temp,   --执行动画节点  必传参数
            --         actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
            --         fps = self.m_csb_fps,    --帧率  可选参数 
            --     }
            -- })
            self:playCoinWinEffectUI()

            --刷新赢钱
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(winCount))
            

            util_runAnimations({
                {   --底部ui光效
                    type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                    node = clip_node_temp,   --执行动画节点  必传参数
                    actionName = "shouji", --动作名称  动画必传参数,单延时动作可不传
                    fps = self.m_csb_fps,    --帧率  可选参数
                    soundFile = "WinningFishSounds/sound_winningFish_respin_clean.mp3",  --播放音效 执行动作同时播放 可选参数
                    callBack = function(  )
                        -- light_temp:removeFromParent(true)
                        clip_node_temp:setVisible(false)
                        node:setVisible(true)
                        showCleanNodesByCol(colIndex,func)
                    end 
                }
            })
            cleanIndex = cleanIndex + 1
            return
        end
        
        cleanIndex = 1
        if type(func) == "function" then
            func()
        end
        
        if colIndex >= #cleanNodes then
            --jackpot回复普通状态
            for index=1,5 do
                self.m_jackpotPool[index]:overAni()
            end
            for key,mask in pairs(self.node_mask_ary) do
                mask:removeFromParent(true)
            end

            local wait_node = cc.Node:create()
            self:addChild(wait_node)
            performWithDelay(wait_node,function(  )
                --显示respin结束界面
                wait_node:removeFromParent(true)
                local view =self:showReSpinOver(strCoins,function()
                    --清理创建的临时结算节点
                    self.m_effectNode:removeAllChildren(true)
                    self:triggerReSpinOverCallFun(strCoins)

                    self:removeRespinNode()
                    self:setReelSlotsNodeVisible(true)
                    for k,clean_bg in pairs(self.m_respin_bg) do
                        clean_bg:setVisible(false)
                    end
                    --检测是否同时触发了其他玩法
                    self:checkNetDataFeatures()
                    if type(callback) == "function" then
                        callback()
                    end
                end)
                local node = view:findChild("m_lb_coins")
                view:updateLabelSize({label = node,sx = 1.15,sy = 1.15}, 654)
            end,0.3)
            
            
        end
    end

    

    --结算所有节点
    local colIndex = 1
    function cleanAllNode(  )
        if colIndex > 5 then
            return
        end
        showCleanNodesByCol(colIndex,function(  )
            colIndex = colIndex + 1
            cleanAllNode()
        end)
    end

    local curColIndex = 1
    --结算奖池
    function showJackpotWin(  )
        if curColIndex > 5 then
            cleanAllNode()
            return
        end
        if jackpotsWin then
            local isJackpot = false
            for key,jackpotInfo in pairs(jackpotsWin) do
                if jackpotInfo.column + 1 == curColIndex then
                    isJackpot = true
                    winCount = winCount + jackpotInfo.winCoins
                    
                    local clean_bg = self.m_respin_bg[curColIndex]
                    clean_bg:setVisible(true)
                    
                    --结算特效
                    self.m_respinView:cleanEffect(curColIndex,function (  )
                        
                        clean_bg:setVisible(false)
                        
                        self.m_jackpot_win:showView(self,jackpotInfo,function(  )
                            --刷新赢钱
                            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(winCount))
                            -- showCleanNodesByCol(curColIndex,function()
                            --     curColIndex = curColIndex + 1
                            --     showJackpotWin()
                            -- end)
                            curColIndex = curColIndex + 1
                            showJackpotWin()
                            
                        end)
                    end)
                    break;
                end
            end
            if not isJackpot then
                curColIndex = curColIndex + 1
                showJackpotWin()
                -- showCleanNodesByCol(curColIndex,function(  )
                --     curColIndex = curColIndex + 1
                --     showJackpotWin()
                -- end)
            end
        else
            -- showCleanNodesByCol(curColIndex,function(  )
            --     curColIndex = curColIndex + 1
            --     showJackpotWin()
            -- end)
            cleanAllNode()
            
        end 
    end

    -- 停掉背景音乐
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_respin_over1.mp3")
    local wait_node = cc.Node:create()
    self:addChild(wait_node)
    performWithDelay(wait_node,function(  )
        wait_node:removeFromParent(true)
        showJackpotWin()
    end,4)
    
end

--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenWinningFishMachine:checkChangeRespinFixNode(node)
    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex
    local posX, posY = node:getPosition()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = self:getReelParent(node.p_cloumnIndex):convertToNodeSpace(worldPos)
    node.m_symbolTag = SYMBOL_NODE_TAG
    node.m_showOrder = showOrder
    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node.m_isLastSymbol = false
    node.m_bRunEndTarge = false
    local columnData = self.m_reelColDatas[node.p_cloumnIndex]
    node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    self:changeBaseParent(node)
    node:setPosition(nodePos)
    node:setLocalZOrder(showOrder)
end


--[[
    respin结束弹窗
]]
function CodeGameScreenWinningFishMachine:showReSpinOver(coins, func)
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    

    --显示收集玩法相关控件
    self:showCollectionRes(true)

    self:clearRespinLight()
    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_respin_over.mp3")
    self:clearCurMusicBg()
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, func)
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
    return view
end

--[[
    刷新respin次数
    refreshType: 1 开始是刷新,次数需减1 2结束时刷新,次数不需要减1 
]]
function CodeGameScreenWinningFishMachine:refreshRespinTimes(refreshType,colIndex)
    if not self:isRespinCol(colIndex) then
        return
    end
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local times = rsExtraData.reSpinTimes[colIndex]
    local isUnLock = self:isUnLockRewardByCol(colIndex)
    if isUnLock then    --成功解锁奖励
        --显示解锁动画
        self.m_jackpotPool[colIndex]:unlockReward()
    else
        local jackpot = self.m_jackpotPool[colIndex]
        jackpot:refreshTimes(refreshType == 1 and times - 1 or times)
        if times <= 0 and refreshType == 2 then
            --显示变黑动画
            self.m_jackpotPool[colIndex]:turnToBlack(2)
        end
    end
end

--[[
    判断该列是否已成功解锁最大奖励
]]
function CodeGameScreenWinningFishMachine:isUnLockRewardByCol(colIndex)
    local reels = self.m_runSpinResultData.p_reels

    local link_count = 0
    for rowIndex=1,self.m_iReelRowNum do
        if reels[rowIndex][colIndex] == self.SYMBOL_BONUS_LINK then --判断是否为link图标
            link_count = link_count + 1
        end
    end
    return link_count >= 4
end

--[[
    判断该列是否为respin玩法
]]
function CodeGameScreenWinningFishMachine:isRespinCol(colIndex)
    local reels = self.m_runSpinResultData.p_reels

    local link_count = 0
    for rowIndex=1,self.m_iReelRowNum do
        if reels[rowIndex][colIndex] == self.SYMBOL_BONUS_LINK then --判断是否为link图标
            return true
        end
    end
    return false
end

--[[
    清理respin光效
]]
function CodeGameScreenWinningFishMachine:clearRespinLight()
    for index=1,5 do
        self.m_effectNode_respin[index]:removeAllChildren(true)
    end
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenWinningFishMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("WinningFishSounds/music_WinningFish_custom_enter_fs.mp3")

    local showFSView = function ()
        

        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self.isStartFreeSpin = true
            gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_freegame_start.mp3")
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()   
                self:changeBg_spin(4)   
                --过场动画
                self:changeViewAni(function(  ) 
                end)
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end

function CodeGameScreenWinningFishMachine:showFreeSpinOverView()

    -- gLobalSoundManager:playSound("WinningFishSounds/music_WinningFish_over_fs.mp3")

    --显示收集玩法相关控件
    self:showCollectionRes(true)
    self:hideFreeSpinBar()
    --显示normal背景
    self:changeBg_spin(2)

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    --清理背景音乐
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_freegame_over.mp3")
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self.m_isFreeSpinOver = true
        self:triggerFreeSpinOverCallFun()
    end)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node,sx = 1.15,sy = 1.15}, 654)

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWinningFishMachine:MachineRule_SpinBtnCall()
    
    self.m_isNotice = false
    -- self:setMaxMusicBGVolume( )
    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end



    return false -- 用作延时点击spin调用
end

-- 转轮开始滚动函数
function CodeGameScreenWinningFishMachine:beginReel()
    self.m_effectNode:setVisible(true)
    self.m_collectionBar:refreshTip(true)
    self.m_bonusNum = 0
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then 
        BaseNewReelMachine.beginReel(self)
        self.m_isFreeSpinOver = false
        -- 刷新wild
        self.m_effectNode:removeAllChildren(true)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
        --延时动作等待背景压暗动作执行结束
        util_runAnimations({
            {
                type = "delay",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                delayTime = 0.2,  --延时事件  可选参数
                callBack = function()
                    BaseNewReelMachine.beginReel(self)
                    self.m_effect_freespin_fp:setVisible(true)
                    self.m_effect_freespin_fp:runCsbAction("start",false,function()
                        self.m_effect_freespin_fp:runCsbAction("idle",true)
                    end) 
                end,   --回调函数 可选参数
            }
        })
        
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWinningFishMachine:addSelfEffect()
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    local currentBubble = self.m_runSpinResultData.p_selfMakeData.currentBubble 
    if self.m_runSpinResultData.p_selfMakeData.bonusType and self.m_runSpinResultData.p_selfMakeData.bonusType == "select" then   --选择玩法
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_SELECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SELECT -- 动画类型
    end
    if currentBubble and #currentBubble >= 0 then   --气泡收集
        --连线消除气泡
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BUBBLE_CLEAR
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BUBBLE_CLEAR -- 动画类型
    end
    if self.m_runSpinResultData.p_selfMakeData.wildPos and not self.m_runSpinResultData.p_selfMakeData.moveRoute then
        --金鱼游动
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_FISH_SWIMMING
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_FISH_SWIMMING -- 动画类型
        -- self.isStartFreeSpin = true
    end
end

--[[
    显示收集玩法界面
]]
function CodeGameScreenWinningFishMachine:showEffect_Bonus(effectData)
    if self.m_runSpinResultData.p_selfMakeData.bonusType ~= "pick" then
        
        return
    end

    local callBack = function()
        self:setGameSpinStage( IDLE )
        self.m_runSpinResultData.p_bonus = nil
        self.m_runSpinResultData.p_selfMakeData = {}

        self.m_bottomUI:hideAverageBet()
    
        --刷新气泡层
        self:refreshBubbleSymbol()
        --刷新收集条
        self:refreshCollectionBar()

        self:playGameEffect()
        self:resetMusicBg(false,"WinningFishSounds/music_winningFish_base_bg.mp3")
    end
    globalData.slotRunData.lastWinCoin = 0
    --清理底部赢钱
    if self.m_runSpinResultData.p_bonus then
        --计算赢得钱
        local winCount = 0
        for key,value in pairs(self.m_runSpinResultData.p_bonus.extra.pickData) do
            if value[3] > 0 then
                winCount = winCount + value[3]
            end
        end
        --刷新赢钱
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(winCount))
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {winCount, false, true})
        
    else
        self.m_bottomUI:resetWinLabel()
        self.m_bottomUI:updateWinCount("")
    end

    effectData.p_isPlay = true
    self:playGameEffect()
    self:setGameSpinStage( WAIT_RUN )
    self:resetMusicBg(true,"WinningFishSounds/music_winningFish_colloction_bg.mp3")
    self.m_bottomUI:showAverageBet()
    self.m_bonusView:showView(true,callBack)
    

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWinningFishMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_BUBBLE_CLEAR then --清除气泡动画
       
        
        self:clearBubbleAction(function()
            -- 记得完成所有动画后调用这两行
            -- 作用：标识这个动画播放完结，继续播放下一个动画
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_SELECT then --选择玩法
        effectData.p_isPlay = true
        self:removeGameEffectType(GameEffect.EFFECT_BONUS)  --移除bonus玩法

        self.m_spinRestMusicBG = false

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        -- 停掉背景音乐
        self:clearCurMusicBg()

        --清空赢钱
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

        local function func(targetGame)
            if targetGame == 1 then --freegame玩法
                local effectData = GameEffectData.new()
                effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
                self.m_gameEffects[#self.m_gameEffects + 1] = effectData
                self.m_runSpinResultData.p_freeSpinsTotalCount = self.m_runSpinResultData.p_selfMakeData.freeGameTimes
                self.m_runSpinResultData.p_freeSpinsLeftCount = self.m_runSpinResultData.p_selfMakeData.freeGameTimes
                globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_selfMakeData.freeGameTimes
                self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
            else    --respin玩法
                self.m_isRespin_normal = true

                self.m_spin_free_once = true
                self.m_chooseRepinGame = true

                if self:getCurrSpinMode() == AUTO_SPIN_MODE then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Auto,false})
                else
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
                end

                self:normalSpinBtnCall()
            end
            self:playGameEffect()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        end

        local lineLen = #self.m_reelResultLines
        local scatterLineValue = nil
        for i=1,lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                scatterLineValue = lineValue
                table.remove(self.m_reelResultLines,i)
                break
            end
        end

        if scatterLineValue ~= nil then
            if self.m_winSoundsId ~= nil then
                gLobalSoundManager:stopAudio(self.m_winSoundsId)
                self.m_winSoundsId = nil
            end
            gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_scatter_play.mp3")
            -- 播放震动
            self.m_isBonusTrigger = true
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "bonus")
            end
            self:showBonusAndScatterLineTip(scatterLineValue,function()
                gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_select.mp3")
                self.m_select_view:showView(function(targetGame)
                    func(targetGame)
                end)
            end)
            scatterLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
            -- 播放提示时播放音效
            self:playScatterTipMusicEffect()
        else
            self.m_select_view:showView(function(targetGame)
                func(targetGame)
            end)
        end

        
    elseif effectData.p_selfEffectType == self.EFFECT_FISH_SWIMMING then    --金鱼游动
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData.wildPos and not selfData.moveRoute then
            self:refreshFreeSpinWilds()
        end
        effectData.p_isPlay = true
        self:playGameEffect()
    end
    return true
end

--[[
    获取下注所需金币
]]
function CodeGameScreenWinningFishMachine:getSpinCostCoins()
    if self.m_spin_free_once then
        return toLongNumber(0)
    end
    return CodeGameScreenWinningFishMachine.super.getSpinCostCoins(self)
end

---
-- 显示free spin
function CodeGameScreenWinningFishMachine:showEffect_FreeSpin(effectData)

    self.m_beInSpecialGameTrigger = true
    
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    -- 停掉背景音乐
    self:clearCurMusicBg()
    self:showFreeSpinView(effectData)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end

--[[
    预告中奖特效
]]
function CodeGameScreenWinningFishMachine:noticeOfWinning(func)
    local effect = util_createAnimation("Socre_WinningFish_YuGaozhongjiang.csb") 
    self:findChild("yugaozj"):addChild(effect)
    self.m_effectNode:setVisible(true)
    effect:findChild("Particle_1_0"):resetSystem()
    util_setCascadeOpacityEnabledRescursion(effect:findChild("Panel_1"),true)
    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_notice.mp3")
    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = effect,   --执行动画节点  必传参数
            actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
            fps = self.m_csb_fps,    --帧率  可选参数  
            keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
                {
                    keyFrameIndex = 130,    --关键帧数  帧动画用
                    callBack = function(  )
                        self:showLayerBlack(true)
                    end,
                }       --关键帧回调
            },   
            callBack = function (  )
                effect:removeFromParent()
                self.m_effectNode:removeAllChildren(true)
                if type(func) == "function" then
                    func()
                end
                
            end
        }
    })
end

--[[
    刷新金鱼Wild图标
]]
function CodeGameScreenWinningFishMachine:refreshFreeSpinWilds()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.m_effectNode:removeAllChildren(true)
    local moveRoute = selfData.moveRoute
    local wildPos = selfData.wildPos

    if not wildPos then
        return
    end

    self.m_effectNode:setVisible(true)

    if moveRoute then
        gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_fish_swimming.mp3")
        for index=1,#moveRoute do
            local startIndex = moveRoute[index][1]
            local endIndex = moveRoute[index][2]

            local startPos = self:getRowAndColByPos(startIndex)
            --开始小块节点
            local startNode = self.m_bubble_pool[tostring(startIndex)]--self:getFixSymbol(startPos.iY , startPos.iX)

            local endPos = self:getRowAndColByPos(endIndex)
            --终止小块节点
            local endNode = self.m_bubble_pool[tostring(endIndex)]--self:getFixSymbol(endPos.iY , endPos.iX)

            --开始小块倍数
            local startTimes = moveRoute[index][3]
            --结束小块倍数
            local endTimes = wildPos[tostring(endIndex)]

            local startSpine = util_spineCreate("Socre_WinningFish_Wild", true, true)
            startSpine:setPosition(util_convertToNodeSpace(startNode,self.m_effectNode))
            self.m_effectNode:addChild(startSpine,endIndex,endIndex)

            if endTimes == 1 then
                util_spinePlay(startSpine,"you",false)
                startSpine:runAction(cc.Sequence:create({
                    cc.MoveTo:create(0.7,util_convertToNodeSpace(endNode,self.m_effectNode)),
                    cc.CallFunc:create(function(  )
                        util_runAnimations({
                            {
                                type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                                node = startSpine,   --执行动画节点  必传参数
                                actionName = "chu_idle_wild", --动作名称  动画必传参数,单延时动作可不传
                            },
                            {
                                type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                                node = startSpine,   --执行动画节点  必传参数
                                actionName = "idleframe", --动作名称  动画必传参数,单延时动作可不传
                                callBack = function(  )
                                    -- local fixNode = self:getFixSymbol(endPos.iY , endPos.iX)
                                    -- if fixNode then
                                    --     fixNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                    -- end
                                end,   --回调函数 可选参数
                            }
                        })
                    end)
                }) )
            elseif endIndex == -1 then
                util_spinePlay(startSpine,startTimes == 1 and "you" or "you"..startTimes,false)
                local overAction = startTimes == 1 and "over_wild" or "over_x"..startTimes
                local pos = cc.p(startSpine:getPosition()) 
                pos.x = pos.x - 230
                startSpine:runAction(cc.Sequence:create({
                    cc.MoveTo:create(0.7,pos),
                    cc.CallFunc:create(function (  )
                        util_spinePlay(startSpine,overAction,false)
                        util_spineEndCallFunc(startSpine,overAction,function()        --结束回调
                            startSpine:setVisible(false)
                        end)
                    end),
                    
                }) )
            else
                util_spinePlay(startSpine,startTimes == 1 and "you" or "you"..startTimes,false)
                local params = {}
                startSpine:runAction(cc.Sequence:create({
                    cc.MoveTo:create(0.7,util_convertToNodeSpace(endNode,self.m_effectNode)),
                    cc.CallFunc:create(function(  )
                        if endTimes > startTimes then
                            params[1] = {
                                type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                                node = startSpine,   --执行动画节点  必传参数
                                actionName = "start_x"..endTimes, --动作名称  动画必传参数,单延时动作可不传
                            }
                            params[2] = {
                                type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                                node = startSpine,   --执行动画节点  必传参数
                                actionName = "idle_x"..endTimes, --动作名称  动画必传参数,单延时动作可不传
                                callBack = function(  )
                                    local fixNode = self:getFixSymbol(endPos.iY , endPos.iX)
                                    if fixNode then
                                        fixNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                    end
                                end,   --回调函数 可选参数
                            }
                        else
                            params[1] = {
                                type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                                node = startSpine,   --执行动画节点  必传参数
                                actionName = "chu_idle_x"..endTimes, --动作名称  动画必传参数,单延时动作可不传
                            }
                            params[2] = {
                                type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                                node = startSpine,   --执行动画节点  必传参数
                                actionName = "idle_x"..endTimes, --动作名称  动画必传参数,单延时动作可不传
                                callBack = function(  )
                                    -- local fixNode = self:getFixSymbol(endPos.iY , endPos.iX)
                                    -- if fixNode then
                                    --     fixNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                    -- end
                                end,   --回调函数 可选参数
                            }
                        end
                        util_runAnimations(params)
                    end)
                }) )
            end
        end
    else
        for index,times in pairs(wildPos) do
            local startPos = self:getRowAndColByPos(index)
            --开始小块节点
            local startNode = self.m_bubble_pool[tostring(index)]--self:getFixSymbol(startPos.iY , startPos.iX)

            local startSpine = util_spineCreate("Socre_WinningFish_Wild", true, true)
            startSpine:setPosition(util_convertToNodeSpace(startNode,self.m_effectNode))
            self.m_effectNode:addChild(startSpine,index,index)
            util_spinePlay(startSpine,times == 1 and "start_zou" or "idle_x"..times,false)
            self.m_effectNode:setVisible(false)
        end
    end
end

--[[
    单列滚动停止
]]
function CodeGameScreenWinningFishMachine:slotOneReelDownFinishCallFunc( reelCol )

    CodeGameScreenWinningFishMachine.super.slotOneReelDownFinishCallFunc(self,reelCol)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE or not selfData or not selfData.wildPos then
        return
    end
    local moveRoute = selfData.moveRoute
    local wildPos = selfData.wildPos
    for index,times in pairs(wildPos) do
        local startPos = self:getRowAndColByPos(index)
        if startPos.iY == reelCol then
            local fixNode = self:getFixSymbol(startPos.iY , startPos.iX)
            fixNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
            fixNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - fixNode.p_rowIndex)

            if times == 1 then
                fixNode:runIdleAnim()
            else
                local animName = "idle_x"..times
                fixNode:runAnim(animName,false)
            end
        end
    end

    if reelCol == self.m_iReelColumnNum then
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE and self.m_effect_freespin_fp:isVisible() then 
            self.m_isFreeSpinFpHide = true
            self.m_effect_freespin_fp:runCsbAction("over",false,function()
                self.m_isFreeSpinFpHide = false
                self.m_effect_freespin_fp:setVisible(false)
            end) 
        end
        
        self.m_effectNode:setVisible(false)
        self.m_effectNode:removeAllChildren(true)
        for index,times in pairs(wildPos) do
            local startPos = self:getRowAndColByPos(index)
            --开始小块节点
            local startNode = self.m_bubble_pool[tostring(index)]--self:getFixSymbol(startPos.iY , startPos.iX)

            local startSpine = util_spineCreate("Socre_WinningFish_Wild", true, true)
            startSpine:setPosition(util_convertToNodeSpace(startNode,self.m_effectNode))
            self.m_effectNode:addChild(startSpine)
            util_spinePlay(startSpine,times == 1 and "start_zou" or "idle_x"..times,false)
            self.m_effectNode:setVisible(false)
        end
    end

end


---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenWinningFishMachine:showLineFrameByIndex(winLines,frameIndex)

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
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

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
                    -- slotsNode:runLineAnim()
                    if (globalData.slotRunData.currSpinMode == FREE_SPIN_MODE or self.m_isFreeSpinOver)
                    and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        local index = self:getPosReelIdx(slotsNode.p_rowIndex,slotsNode.p_cloumnIndex)
                        local wildPos = self.m_runSpinResultData.p_selfMakeData.wildPos or {}
                        local times = wildPos[tostring(index)] or 1
                        if times == 1 then
                            slotsNode:runLineAnim()
                        else
                            local animName = "actionframe"..times
                            slotsNode:runAnim(animName,true)
                        end
                    else
                        slotsNode:runLineAnim()
                    end
                end
            end
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenWinningFishMachine:playInLineNodes()

    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i=1,#self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if (globalData.slotRunData.currSpinMode == FREE_SPIN_MODE or self.m_isFreeSpinOver)
            and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                local index = self:getPosReelIdx(slotsNode.p_rowIndex,slotsNode.p_cloumnIndex)
                local wildPos = self.m_runSpinResultData.p_selfMakeData.wildPos or {}
                local times = wildPos[tostring(index)] or 1
                if times == 1 then
                    slotsNode:runLineAnim()
                else
                    local animName = "actionframe"..times
                    slotsNode:runAnim(animName,true)
                end
            else
                slotsNode:runLineAnim()
            end
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()) )
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
function CodeGameScreenWinningFishMachine:playInLineNodesIdle()

    if self.m_lineSlotNodes == nil then
        return
    end

    for i=1,#self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if (globalData.slotRunData.currSpinMode == FREE_SPIN_MODE or self.m_isFreeSpinOver)
            and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                local index = self:getPosReelIdx(slotsNode.p_rowIndex,slotsNode.p_cloumnIndex)
                local wildPos = self.m_runSpinResultData.p_selfMakeData.wildPos or {}
                local times = wildPos[tostring(index)] or 1
                if times == 1 then
                    slotsNode:runIdleAnim()
                else
                    local animName = "idle_x"..times
                    slotsNode:runAnim(animName,false)
                end
            else
                slotsNode:runIdleAnim()
            end
        end
    end

end

--[[
    清除气泡动画
]]
function CodeGameScreenWinningFishMachine:clearBubbleAction(_callBack)
    if not self.m_runSpinResultData.p_selfMakeData then
        if type(_callBack) == "function" then
            _callBack()
        end
        return
    end
    --当前需要消除的气泡
    local currentBubble = self.m_runSpinResultData.p_selfMakeData.currentBubble 
    if currentBubble and #currentBubble > 0 then
        
        for index=1,#currentBubble do
            --获取要消除的气泡
            local slotIndex = currentBubble[index]
            local bubble = self.m_bubble_pool[tostring(slotIndex)]
            --获取终点节点
            local node_end = self.m_collectionBar:getNextNode(index)

            util_runAnimations({
                {
                    type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                    node = bubble,   --执行动画节点  必传参数
                    actionName = "shouji", --动作名称  动画必传参数,单延时动作可不传
                    fps = self.m_csb_fps,    --帧率  可选参数
                    keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
                        {
                            keyFrameIndex = 25,    --关键帧数  帧动画用
                            callBack = function(  )
                                bubble:setVisible(false)
                                bubble:runCsbAction("idleframe")
                                --创建临时气泡用于执行动作
                                local bubble_temp = util_createAnimation("Socre_WinningFish_Qipao_shouji.csb")
                                local pos = cc.p(bubble:getPosition())
                                bubble_temp:setPosition(pos)
                                self.m_effectNode:addChild(bubble_temp)
                                bubble_temp:runCsbAction("actionframe",true,nil,self.m_csb_fps)
                                local nodePos = util_convertToNodeSpace(node_end,self.m_effectNode)
                                bubble_temp:findChild("Particle_1"):setPositionType(0)
                                if index == 1 then
                                    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_colloct.mp3")
                                end
                                bubble_temp:runAction(cc.Sequence:create({cc.MoveTo:create(0.4, nodePos), cc.RemoveSelf:create(true)}))
                            
                                performWithDelay(node_end,function()
                                    if index == #currentBubble then
                                        if self.m_runSpinResultData.p_selfMakeData and 
                                            self.m_runSpinResultData.p_selfMakeData.bubblePos and 
                                            #self.m_runSpinResultData.p_selfMakeData.bubblePos >= 20 then
                                                
                                            if self.levelDeviceVibrate then
                                                self:levelDeviceVibrate(6, "collect")
                                            end
                                        end

                                        self.m_collectionBar:playCollectionAni(self.m_runSpinResultData.p_selfMakeData.bubblePos,function(  )
                                        end)
                                        gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_colloct_back.mp3")
                                    end
                                    node_end:runCsbAction("actionframe",false,function()
                                        node_end.m_isShow = true

                                    end)
                                end,0.4)
                            end,
                        }       --关键帧回调
                    }
                }
            })

        end

        local time = 0
        local time1 = 0
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local bubblePos = selfData.bubblePos or {}
        if #bubblePos >= 20 then
            time = 1.45 + 0.42 + 0.4 + 1
        else
            time = 0.42 + 0.4
        end
      
        time1 = time

        local isRespin = false
        for key,featureID in pairs(self.m_runSpinResultData.p_features) do
            if featureID == SLOTO_FEATURE.FEATURE_RESPIN then
                isRespin = true
                break;
            end
        end

        local isSelect = false 
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.bonusType == "select" then
            isSelect = true
        end

        local isBonus = false
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.bonusType == "pick" then
            isBonus = true
        end
        if isRespin or isSelect or isBonus or self.m_bIsBigWin then    --进入respin时按钮不可点击
            print("等待收集完毕在执行后续逻辑")
        else
            time1 = 0
        end

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            --刷新所有气泡
            self:refreshBubbleSymbol()
            --刷新收集进度条
            self:refreshCollectionBar()
        
            self.m_runSpinResultData.p_selfMakeData.currentBubble = nil
            waitNode:removeFromParent()
         end,time)

        local waitNode_1 = cc.Node:create()
        self:addChild(waitNode_1)
        performWithDelay(waitNode_1,function(  )

            if type(_callBack) == "function" then
                _callBack()
            end

            waitNode_1:removeFromParent()

        end,time1)

    else
        if type(_callBack) == "function" then
            _callBack()
        end
    end
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenWinningFishMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenWinningFishMachine:checkTriggerOrInSpecialGame( func )

    if self:getCurrSpinMode() == FREE_SPIN_MODE or
        self:getCurrSpinMode() == RESPIN_MODE or
            self:getCurrSpinMode() == AUTO_SPIN_MODE or
                self:checktriggerSpecialGame( ) or self.m_runSpinResultData.p_bonusStatus == "OPEN" then

        self:removeSoundHandler() -- 移除监听

    else

       if func then
            func()
       end
    end
end

function CodeGameScreenWinningFishMachine:playEffectNotifyNextSpinCall( )

    -- BaseNewReelMachine.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    if (self.m_bQuestComplete or self.m_isRespin_normal) and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
    self:getCurrSpinMode() == FREE_SPIN_MODE then

        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    end

end

function CodeGameScreenWinningFishMachine:netBackUpdateReelDatas( )

    local slotsParents = self.m_slotParents

    for i = 1, #slotsParents do
        local parentData = slotsParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local reelDatas = self:checkUpdateReelDatas(parentData)

    end
end

function CodeGameScreenWinningFishMachine:scaleMainLayer()
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
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        if display.width < 1370 then
            mainScale = mainScale * 0.95
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + 10)
    end

end

function CodeGameScreenWinningFishMachine:dealSmallReelsSpinStates( )

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                                        {SpinBtn_Type.BtnType_Stop,false})

    if self.m_chooseRepinGame then

        local waitTime = self.m_startSpinWaitTime or 0
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            CodeGameScreenWinningFishMachine.super.dealSmallReelsSpinStates(self )
            waitNode:removeFromParent()
        end,waitTime)

        self.m_chooseRepinGame = false
    else
        CodeGameScreenWinningFishMachine.super.dealSmallReelsSpinStates(self )
    end
end

function CodeGameScreenWinningFishMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if ("respin" == _sFeature and self.m_isBonusTrigger) or "free" == _sFeature then
        self.m_isBonusTrigger = false
        return
    end
    if CodeGameScreenWinningFishMachine.super.levelDeviceVibrate then
        CodeGameScreenWinningFishMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenWinningFishMachine






