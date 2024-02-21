---
-- island li
-- 2019年1月26日
-- CodeGameScreenBunnysLockMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotParentData = require "data.slotsdata.SlotParentData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"
local CodeGameScreenBunnysLockMachine = class("CodeGameScreenBunnysLockMachine", BaseNewReelMachine)

CodeGameScreenBunnysLockMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBunnysLockMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenBunnysLockMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenBunnysLockMachine.Socre_MYSTERY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7

CodeGameScreenBunnysLockMachine.EFFECT_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 1--进度收集
CodeGameScreenBunnysLockMachine.EFFECT_WIN_BY_BONUS = GameEffect.EFFECT_SELF_EFFECT - 2--bonus图标赢钱

local WIN_LINE_ZORDER = 5000
-- 构造函数
function CodeGameScreenBunnysLockMachine:ctor()
    CodeGameScreenBunnysLockMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_collectData = nil    --收集数据
    self.m_mapData = nil        --地图数据
    self.m_lineRespinNodes = {}

    self.m_isBonusWinCoins = false

    self.m_RESPIN_RUN_TIME = 0.1

    self.m_changeScatterTime = 0.1

	--init
	self:initGame()
end

function CodeGameScreenBunnysLockMachine:initGame()
    
    self.m_configData = gLobalResManager:getCSVLevelConfigData("BunnysLockConfig.csv", "LevelBunnysLockConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

---
--设置bonus scatter 层级
function CodeGameScreenBunnysLockMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
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

function CodeGameScreenBunnysLockMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_free_kuang")
    self.m_baseFreeSpinBar = util_createView("CodeBunnysLockSrc.BunnysLockFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenBunnysLockMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_collectBar:hideBarView(false)
end

function CodeGameScreenBunnysLockMachine:initMachineBg()
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

    --后层背景
    self.m_bg_behind = util_spineCreate("Socre_BunnysLock_BJ1",true,true)
    gameBg:findChild("root"):addChild(self.m_bg_behind)

    self.m_bg_front = util_spineCreate("Socre_BunnysLock_BJ2",true,true)
    gameBg:findChild("root"):addChild(self.m_bg_front)
    

    util_spinePlay(self.m_bg_behind,"idle1",true)
    util_spinePlay(self.m_bg_front,"idle1_qian",true)
end

function CodeGameScreenBunnysLockMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.m_collectBar:showBarView()
end

function CodeGameScreenBunnysLockMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_rootNode = self:findChild("root")

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
   
    --收集进度条
    self.m_collectBar = util_createView("CodeBunnysLockSrc.BunnysLockCollectBar",{machine = self})
    self:findChild("Node_loadingBar"):addChild(self.m_collectBar)
    
    
    self.m_baseBgNode = self:findChild("base")
    self.m_freeBgNode = self:findChild("free")

    --topDollar
    self.m_topDollarView = util_createView("CodeBunnysLockBonus.BunnysLockBonusGameTopDollar",{machine = self})
    self.m_rootNode:addChild(self.m_topDollarView,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 15)
    self.m_topDollarView:setPosition(cc.p(-display.center.x,-display.center.y))

    --开箱子
    self.m_openBoxView = util_createView("CodeBunnysLockBonus.BunnysLockBonusGameOpenBox",{machine = self})
    self.m_rootNode:addChild(self.m_openBoxView,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 20)
    self.m_openBoxView:setPosition(cc.p(-display.center.x,-display.center.y))

    --多福多彩
    self.m_colorfulView = util_createView("CodeBunnysLockBonus.BunnysLockBonusGameColorful",{machine = self})
    self.m_rootNode:addChild(self.m_colorfulView,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 25)
    self.m_colorfulView:setPosition(cc.p(-display.center.x,-display.center.y))

    --bonus过场动画
    self.m_changeSceneAni_Bonus = util_createAnimation("BunnysLock_bonus_guochang.csb")
    self.m_rootNode:addChild(self.m_changeSceneAni_Bonus,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10)

    --地图
    self.m_mapView = util_createView("CodeBunnysLockBonus.BunnysLockMapView",{machine = self})
    self.m_changeSceneAni_Bonus:findChild("Map"):addChild(self.m_mapView)
    self.m_mapView:setPosition(cc.p(-display.center.x,-display.center.y))

    --主棋盘
    self.m_mainReelNode = self:findChild("zhuqipan")
   
    --过场显示用
    self.m_lock_bg = util_createAnimation("BunysLock_tubiaosuodingkuang.csb")
    self.m_clipParent:addChild(self.m_lock_bg,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_lock_bg:setPosition(util_convertToNodeSpace(self:findChild("node_lock"),self.m_clipParent))
    self.m_lock_bg:runCsbAction("idleframe",true)
    self.m_lock_bg:setVisible(false)

    --预告中奖动画
    self.m_csb_notice = util_createAnimation("BunnysLock_free_yugao.csb")
    self.m_rootNode:addChild(self.m_csb_notice,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    self.m_csb_notice:setPosition(util_convertToNodeSpace(self:findChild("node_lock"),self.m_rootNode))
    self.m_csb_notice:setVisible(false)

    self.m_spine_notice = util_spineCreate("BunnysLock_free_yugao",true,true)
    self.m_rootNode:addChild(self.m_spine_notice,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 110)
    self.m_spine_notice:setVisible(false)
end


function CodeGameScreenBunnysLockMachine:changeSceneToBonus(isStart,func)
    if self.m_isChangeToBonus then
        return
    end
    self.m_isChangeToBonus = true
    self:showBaseReel(true)
    self.m_mapView:showView(isStart)
    self.m_isShowBonus = true
    
    util_changeNodeParent(self.m_changeSceneAni_Bonus:findChild("Bace"),self.m_mainReelNode)
    self.m_mainReelNode:setPosition(cc.p(0,0))

    self.m_respinView:setVisible(false)
    self:setReelSlotsNodeVisible(true)
    self.m_lock_bg:setVisible(true)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    
    local callFunc = function()
        self.m_changeSceneAni_Bonus:runCsbAction("bace_map",false,function()
            self.m_isChangeToBonus = false
            self:showBaseReel(false)
            self.m_lock_bg:setVisible(false)
            if not isStart then
                self.m_isInMapView = true
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end
            if type(func) == "function" then
                func()
            end
        end)
    end

    if isStart then
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_change_scene_base_to_map.mp3")
        local spine = util_spineCreate("beijing",true,true)
        self.m_rootNode:addChild(spine,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 3000)
        util_spinePlay(spine,"actionframe")
        util_spineEndCallFunc(spine,"actionframe",function()
            spine:setVisible(false)
            self:delayCallBack(1,function()
                spine:removeFromParent()
            end)
        end)

        self:delayCallBack(40 / 30,function()
            callFunc()
        end)
    else
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_change_scene_map_to_base.mp3")
        callFunc()
    end

    
    
end

function CodeGameScreenBunnysLockMachine:changeSceneToBase(func)
    if self.m_isChangeToBase then
        return
    end
    self.m_isChangeToBase = true
    self:showBaseReel(true)

    util_changeNodeParent(self.m_changeSceneAni_Bonus:findChild("Bace"),self.m_mainReelNode)
    self.m_mainReelNode:setPosition(cc.p(0,0))

    self.m_lock_bg:setVisible(true)
    self:setReelSlotsNodeVisible(true)
    self.m_respinView:setVisible(false)

    self.m_mapView:setVisible(true)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_change_scene_map_to_base.mp3")
    self.m_changeSceneAni_Bonus:runCsbAction("map_bace",false,function()
        self.m_isChangeToBase = false
        util_changeNodeParent(self.m_rootNode,self.m_mainReelNode,10)
        self.m_mainReelNode:setPosition(cc.p(0,0))
        self.m_mapView:hideView()

        self.m_respinView:setVisible(true)
        
        self.m_lock_bg:setVisible(false)
        if self.m_lock_bg.m_symbolNode then
            self.m_lock_bg.m_symbolNode:setScale(1)
            self.m_lock_bg.m_symbolNode:putBackToPreParent()
            self.m_lock_bg.m_symbolNode = nil
        end

        self:setReelSlotsNodeVisible(false)

        self.m_isInMapView = false

        self.m_isShowBonus = false

        if type(func) == "function" then
            func()
        end
    end)
end

--隐藏盘面信息
function CodeGameScreenBunnysLockMachine:setReelSlotsNodeVisible(status)
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
            if symbol and symbol.p_symbolType then
                symbol:setVisible(status)
                --如果是显示,需要重置小块的值
                if status then
                    local respinNode = self.m_respinView:getRespinNodeByRowAndCol(iCol,iRow)
                    if respinNode and respinNode.m_baseFirstNode and respinNode.m_baseFirstNode.p_symbolType then
                        local symbolType = respinNode.m_baseFirstNode.p_symbolType
                        if symbolType ~= symbol.p_symbolType then
                            symbol:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType),symbolType)
                            symbol:setLocalZOrder(self:getBounsScatterDataZorder(symbolType) - iRow)
                            if symbol.p_symbolImage then
                                symbol.p_symbolImage:removeFromParent()
                                symbol.p_symbolImage = nil
                            end
                        end

                        --bonus图标特殊处理
                        if symbol and symbolType == self.SYMBOL_BONUS then
                            symbol:getCcbProperty("BitmapFontLabel_1"):setString(respinNode.m_baseFirstNode.m_score)
                            local csbNode = symbol:getCCBNode()
                            if not csbNode.m_spine then
                                local spine = util_spineCreate("Socre_BunnysLock_Bonus2",true,true)
                                symbol:getCcbProperty("spine"):addChild(spine)
                                csbNode.m_spine = spine
                            end
                        end

                        if iCol == 3 and iRow == 2 then
                            symbol:changeParentToOtherNode(self.m_lock_bg)
                            self.m_lock_bg.m_symbolNode = symbol
                            symbol:setScale(respinNode:getScale())
                            symbol:setPosition(cc.p(0,0))
                        else
                            symbol:setScale(1)
                        end
                    end
                end
                
            end
        end
    end
end

--[[
    显示base轮盘
]]
function CodeGameScreenBunnysLockMachine:showBaseReel(isShow)
    self.m_mainReelNode:setVisible(isShow)
    self.m_respinView:setVisible(isShow)
end

function CodeGameScreenBunnysLockMachine:initGameStatusData(gameData)
    CodeGameScreenBunnysLockMachine.super.initGameStatusData(self, gameData)    
    -- self.m_initFeatureData
    if self.m_runSpinResultData.p_selfMakeData then
        self:updateBonusData(self.m_runSpinResultData.p_selfMakeData.map_result,self.m_runSpinResultData.p_selfMakeData.collectData)
    else
        self:updateBonusData(gameData.gameConfig.extra.map,gameData.gameConfig.extra.collect)
    end   
end

function CodeGameScreenBunnysLockMachine:updateBonusData(mapData,collectData)
    self.m_collectData = collectData
    self.m_mapData = mapData
end

--[[
    显示地图
]]
function CodeGameScreenBunnysLockMachine:showMapView(isBonusStart,func)

    if isBonusStart then
        self:changeBgAni("base_bonus")
        self:showMapStartView(function ()
            self:changeSceneToBonus(isBonusStart,function()
                self.m_bottomUI:checkClearWinLabel()
                self:resetMusicBg(true,"BunnysLockSounds/music_BunnysLock_bg_map.mp3")
            end)
            self.m_mapView:setEndCallFunc(func)
        end)
        
    else
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_click_btn.mp3")
        self:changeSceneToBonus(isBonusStart,function()
            
        end)
        self.m_mapView:setEndCallFunc(func)
    end
    
end

--[[
    显示bonus开始弹板
]]
function CodeGameScreenBunnysLockMachine:showMapStartView(func)
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_show_map_start.mp3")
    return self:showDialog("MapStart", {}, func)
end

--[[
    获取当前收集进度
]]
function CodeGameScreenBunnysLockMachine:getCurCollectPercent()
    if not self.m_collectData then
        return 0
    end

    local features = self.m_runSpinResultData.p_features
    if features then
        for k,featureID in pairs(features) do
            if featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                return 100
            end
        end
    end
    

    local curCollect = self.m_collectData.collect or 0
    local totalCollect = self.m_collectData.collectnum or 1

    return math.ceil((curCollect / totalCollect) * 100)
end

-- 断线重连 
function CodeGameScreenBunnysLockMachine:MachineRule_initGame(  )
    
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBunnysLockMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "BunnysLock"  
end

-- 继承底层respinView
function CodeGameScreenBunnysLockMachine:getRespinView()
    return "CodeBunnysLockSrc.BunnysLockRespinView"
end
-- 继承底层respinNode
function CodeGameScreenBunnysLockMachine:getRespinNode()
    return "CodeBunnysLockSrc.BunnysLockRespinNode"
end

function CodeGameScreenBunnysLockMachine:getBottomUINode()
    return "CodeBunnysLockSrc.BunnysLockBottomNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBunnysLockMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.Socre_MYSTERY then
        symbolType = self:getMysteryType(symbolType)
    end
    --bonus
    if symbolType == self.SYMBOL_BONUS then
        return "Socre_BunnysLock_Bonus2"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_BunnysLock_Scatter"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        return "Socre_BunnysLock_Bonus1"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_BunnysLock_10"
    end
   

    return nil
end

function CodeGameScreenBunnysLockMachine:getMysteryType(symbolType)
    if symbolType == self.Socre_MYSTERY then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.change_num then
            symbolType = selfData.change_num
        else
            symbolType = self.SYMBOL_BONUS
        end
    end
    
    return symbolType
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
function CodeGameScreenBunnysLockMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol)
    if isLastSymbol == nil then
        isLastSymbol = false
    end
    symbolType = self:getMysteryType(symbolType)
    local symblNode = self:getSlotNodeBySymbolType(symbolType)
    symblNode.p_cloumnIndex = col
    symblNode.p_rowIndex = row
    symblNode.m_isLastSymbol = isLastSymbol

    self:updateReelGridNode(symblNode)
    self:checkAddSignOnSymbol(symblNode)
    return symblNode
end

function CodeGameScreenBunnysLockMachine:getAnimNodeFromPool(symbolType, ccbName)
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

    symbolType = self:getMysteryType(symbolType)

    ccbName = self:getSymbolCCBNameByType(self, symbolType)

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
            node:loadCCBNode(ccbName, symbolType,spineSymbolData[3])
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
-- 从参考的假数据中获取数据
--
function CodeGameScreenBunnysLockMachine:getRandomReelType(colIndex, reelDatas)
    if reelDatas == nil or #reelDatas == 0 then
        return self:getNormalSymbol(colIndex)
    end
    local reelLen = #reelDatas

    if self.m_randomSymbolSwitch then
        -- 根据滚轮真实假滚数据初始化轮子信号小块
        if self.m_randomSymbolIndex == nil then
            self.m_randomSymbolIndex = util_random(1, reelLen)
        end
        self.m_randomSymbolIndex = self.m_randomSymbolIndex + 1
        if self.m_randomSymbolIndex > reelLen then
            self.m_randomSymbolIndex = 1
        end

        local symbolType = reelDatas[self.m_randomSymbolIndex]
        symbolType = self:getMysteryType(symbolType)
        return symbolType
    else
        while true do
            local symbolType = reelDatas[util_random(1, reelLen)]
            symbolType = self:getMysteryType(symbolType)
            return symbolType
        end
    end

    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenBunnysLockMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil

    if not storedIcons then
        return self:randomDownRespinSymbolScore(self.SYMBOL_BONUS)
    end

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
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    return score
end

function CodeGameScreenBunnysLockMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_BONUS then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getBnBasePro()
    end


    return score
end

-- 给respin小块进行赋值
function CodeGameScreenBunnysLockMachine:setSpecialNodeScore(sender,symbolNode)
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
        score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
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
        score = util_formatCoins(score, 3)

        local csbNode = symbolNode:getCCBNode()
        
        symbolNode:getCcbProperty("BitmapFontLabel_1"):setString(score)
        symbolNode.m_score = score
        if not csbNode.m_spine then
            local spine = util_spineCreate("Socre_BunnysLock_Bonus2",true,true)
            symbolNode:getCcbProperty("spine"):addChild(spine)
            csbNode.m_spine = spine
        end
    end

    symbolNode:runAnim("idleframe")
end

function CodeGameScreenBunnysLockMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if symbolType == self.SYMBOL_BONUS then
        self:setSpecialNodeScore(self,node)
    end
end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBunnysLockMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenBunnysLockMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

--
--单列滚动停止回调
--
function CodeGameScreenBunnysLockMachine:slotOneReelDown(reelCol)    
    CodeGameScreenBunnysLockMachine.super.slotOneReelDown(self,reelCol) 
end



---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenBunnysLockMachine:levelFreeSpinEffectChange()

    
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenBunnysLockMachine:levelFreeSpinOverChangeEffect()

end

--[[
    修改背景动画
]]
function CodeGameScreenBunnysLockMachine:changeBgAni(bgType,func)
    if bgType == "base_free" then
        self:changeBgAni("free")
    elseif bgType == "free_base" then 
        self:changeBgAni("base")
    elseif bgType == "base_bonus" then
        self:changeBgAni("bonus")
    elseif bgType == "bonus_base" then
        self:changeBgAni("base")
    elseif bgType == "base" then
        self.m_baseBgNode:setVisible(true)
        self.m_freeBgNode:setVisible(false)
        util_spinePlay(self.m_bg_behind,"idle1",true)
        util_spinePlay(self.m_bg_front,"idle1_qian",true)
    elseif bgType == "free" then
        self.m_baseBgNode:setVisible(false)
        self.m_freeBgNode:setVisible(true)
        util_spinePlay(self.m_bg_behind,"idle2",true)
        util_spinePlay(self.m_bg_front,"idle2_qian",true)
    elseif bgType == "bonus" then
        util_spinePlay(self.m_bg_behind,"idle3",true)
        util_spinePlay(self.m_bg_front,"idle3_qian",true)
    elseif bgType == "box" then
        util_spinePlay(self.m_bg_behind,"idle5",true)
        util_spinePlay(self.m_bg_front,"idle5_qian",true)
    elseif bgType == "topdollar" then
        util_spinePlay(self.m_bg_behind,"idle6",true)
        util_spinePlay(self.m_bg_front,"idle6_qian",true)
    elseif bgType == "colorful" then
        util_spinePlay(self.m_bg_behind,"idle4",true)
        util_spinePlay(self.m_bg_front,"idle4_qian",true)
    end
end
---------------------------------------------------------------------------


-- 触发freespin时调用
function CodeGameScreenBunnysLockMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("BunnysLockSounds/music_BunnysLock_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else

            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                --过场动画
                self:changeToFreeAni(function()
                    self:changeBgAni("base_free")

                    effectData.p_isPlay = true
                    self:playGameEffect() 
                end)

                --切换场景
                self:delayCallBack(60 / 30,function()
                    self:triggerFreeSpinCallFun()
                    self:changeBgAni("base_free")
                    self.m_respinView:changeEndType()
                end)     
                
            end)
            
            
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

end

--[[
    free过场动画
]]
function CodeGameScreenBunnysLockMachine:changeToFreeAni(func)
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_change_scene_base_to_free.mp3")
    local spine = util_spineCreate("BunnysLock_free_guochang",true,true)
    self.m_rootNode:addChild(spine,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1000)
    util_spinePlay(spine,"actionframe")
    util_spineEndCallFunc(spine,"actionframe",function()
        if type(func) == "function" then
            func()
        end
        spine:setVisible(false)
        self:delayCallBack(1,function()
            spine:removeFromParent()
        end)
    end)
end



---
-- 显示free spin
function CodeGameScreenBunnysLockMachine:showEffect_FreeSpin(effectData)
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

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
    end
    
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    
    --触发动画
    self:showBonusAndScatterLineTip(nil,function ()
        self:showFreeSpinView(effectData)
    end)
     
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenBunnysLockMachine:showBonusAndScatterLineTip(lineValue, callFun)
    -- 播放提示时播放音效
    self:playScatterTipMusicEffect()

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_more_free_trigger.mp3")
    else
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_scatter_trigger.mp3")
    end

   
    
    local animTime = 0
    for index = 1,#self.m_respinView.m_respinNodes do
        local respinNode = self.m_respinView.m_respinNodes[index]
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode and symbolNode.p_symbolType then
            if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                symbolNode:runAnim("actionframe1",false,function()
                    symbolNode:runAnim("idleframe",true)
                end)
                animTime = util_max(animTime, symbolNode:getAniamDurationByName("actionframe1"))
            elseif symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolNode:runAnim("actionframe",false,function()
                    symbolNode:runAnim("idleframe",true)
                end)
                animTime = util_max(animTime, symbolNode:getAniamDurationByName("actionframe"))
            end
        end
    end
    self:delayCallBack(animTime,function()
        if type(callFun) == "function" then
            callFun()
        end
    end)
end

function CodeGameScreenBunnysLockMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local autoType = isAuto and BaseDialog.AUTO_TYPE_NOMAL or nil
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, autoType)

    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_show_free_spin_view.mp3")

    --背景光
    local shine = util_createAnimation("BunnysLock/BonusStart_tanban_shine.csb")
    view:findChild("Node_guang"):addChild(shine)
    shine:runCsbAction("idleframe",true)

    local spine = util_spineCreate("Socre_BunnysLock_Bonus1",true,true)
    util_spinePlay(spine,"freestart_open")
    util_spineEndCallFunc(spine,"freestart_open",function()
        util_spinePlay(spine,"freestart_idleframe",true)
    end)
    view:findChild("Node_tuzi"):addChild(spine)

    return view

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenBunnysLockMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        -- self:resetMusicBg(true)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_show_free_spin_more.mp3")

    local view = self:showDialog("FreeSpinMore", ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY )

    --背景光
    local shine = util_createAnimation("BunnysLock/BonusStart_tanban_shine.csb")
    view:findChild("Node_guang"):addChild(shine)
    shine:runCsbAction("idleframe",true)

    local spine = util_spineCreate("Socre_BunnysLock_Bonus1",true,true)
    util_spinePlay(spine,"freestart_open")
    util_spineEndCallFunc(spine,"freestart_open",function()
        util_spinePlay(spine,"freestart_idleframe",true)
    end)
    view:findChild("Node_tuzi"):addChild(spine)

    return view
end


-- 触发freespin结束时调用
function CodeGameScreenBunnysLockMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_show_free_over.mp3")

    local callFunc = function ()
        -- 调用此函数才是把当前游戏置为freespin结束状态
        self:triggerFreeSpinOverCallFun()
        self.m_respinView:changeEndType()

        self:changeBgAni("free_base")

        --中间兔子变换idle
        local midRespinNode = self.m_respinView.m_respinNodes[8]
        if midRespinNode and midRespinNode.m_baseFirstNode and midRespinNode.m_baseFirstNode.p_symbolType then
            midRespinNode.m_baseFirstNode:runAnim("idleframe0",true)
        end
    end
    if globalData.slotRunData.lastWinCoin == 0 then
        local view = self:showDialog("FreeSpinOver_NoWins", {}, callFunc)
    else
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        local view = self:showFreeSpinOver( strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount,callFunc)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},782)

        local m_lb_num = view:findChild("m_lb_num")
        view:updateLabelSize({label=m_lb_num,sx=0.65,sy=0.65},110)
    end

    
end

function CodeGameScreenBunnysLockMachine:showRespinJackpot(index,coins,func)
    
    local jackPotWinView = util_createView("CodeBunnysLockSrc.BunnysLockJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,func)
end

-- 结束respin收集
function CodeGameScreenBunnysLockMachine:playLightEffectEnd()
    
    -- 通知respin结束
    self:respinOver()
 
end

--结束移除小块调用结算特效
function CodeGameScreenBunnysLockMachine:reSpinEndAction()    
    self:clearCurMusicBg()
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenBunnysLockMachine:getRespinRandomTypes( )
    local symbolList = { 
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1,
        self.SYMBOL_SCORE_10,
        self.SYMBOL_BONUS
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenBunnysLockMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_BONUS, runEndAnimaName = "buling", bRandom = false},
        {type = TAG_SYMBOL_TYPE.SYMBOL_BONUS, runEndAnimaName = "buling", bRandom = false},
        {type = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, runEndAnimaName = "buling", bRandom = false},
    }

    return symbolList
end

function CodeGameScreenBunnysLockMachine:showRespinView()
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()
    
    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)
end

--触发respin
function CodeGameScreenBunnysLockMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = true

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
    self.m_rootNode:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)
end

function CodeGameScreenBunnysLockMachine:getMatrixPosSymbolType(iRow, iCol)
    local rowCount = #self.m_runSpinResultData.p_reels
    if rowCount == 0 then
        local symbolType = 0
        local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        symbolType = symbol.p_symbolType
        return symbolType
    end
    for rowIndex = 1, rowCount do
        local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenBunnysLockMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    local hasFeature = self:checkHasFeature()

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            --初始轮盘
            if not hasFeature then
                local initDatas = self.m_configData:getInitReelDatasByColumnIndex(iCol)
                symbolType = initDatas[iRow]
            end

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

function CodeGameScreenBunnysLockMachine:initRespinView(endTypes, randomTypes)
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

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--ReSpin开始改变UI状态
function CodeGameScreenBunnysLockMachine:changeReSpinStartUI(respinCount)
   
end

--ReSpin刷新数量
function CodeGameScreenBunnysLockMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
   
end

--ReSpin结算改变UI状态
function CodeGameScreenBunnysLockMachine:changeReSpinOverUI()

end

-- --重写组织respinData信息
function CodeGameScreenBunnysLockMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}   

    -- for i=1, #storedIcons do
    --     local id = storedIcons[i][1]
    --     local pos = self:getRowAndColByPos(id)
    --     local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)
        
    --     storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    -- end

    return storedInfo
end


---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBunnysLockMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume()


    return false -- 用作延时点击spin调用
end




function CodeGameScreenBunnysLockMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
       self:playEnterGameSound( "BunnysLockSounds/sound_BunnysLock_enter_game.mp3" )

    end,0.4,self:getModuleName())
end

function CodeGameScreenBunnysLockMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    
    self.m_collectBar:initProcess()
    self.m_mapView:resetView()

    CodeGameScreenBunnysLockMachine.super.onEnter(self) 	-- 必须调用不予许删除

    --显示respin界面
    self:showRespinView()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_respinView:changeEndType()
        self:changeBgAni("free")
    else
        self:changeBgAni("base")
    end

    self:addObservers()

    if self.m_isEnterPlayGameEffect or #self.m_gameEffects > 0 then
        self.m_isEnterPlayGameEffect = false
        self:sortGameEffects()
        self:playGameEffect()
    end
end

---
-- 进入关卡
--
function CodeGameScreenBunnysLockMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()
    self.m_isEnterPlayGameEffect = isPlayGameEffect
end

function CodeGameScreenBunnysLockMachine:addObservers()
	CodeGameScreenBunnysLockMachine.super.addObservers(self)
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
            soundName = "BunnysLockSounds/sound_BunnysLock_free_win_sound_".. soundIndex .. ".mp3"
        else
            soundName = "BunnysLockSounds/sound_BunnysLock_win_sound_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenBunnysLockMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBunnysLockMachine.super.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenBunnysLockMachine:initFeatureInfo(spinData,featureData)

    local bonus
    if featureData then
        bonus = featureData.p_data.selfData.bonus
    end
    if bonus and bonus.status == "OPEN" then
        self:addBonusEffect()
    elseif bonus and bonus.status == "CLOSED" then
        
    end
end

--[[
    添加Bonus玩法
]]
function CodeGameScreenBunnysLockMachine:addBonusEffect()

    self:setCurrSpinMode(SPECIAL_SPIN_MODE)
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_CHOOSE_SET_VISIBLE, {isShow = false})

    self.m_isShowBonus = true
    local effect = GameEffectData.new()
    effect.p_effectType = GameEffect.EFFECT_BONUS
    effect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = effect
end

function CodeGameScreenBunnysLockMachine:showEffect_Bonus(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if self.m_initFeatureData then
        selfData = self.m_initFeatureData.p_data.selfData
    end

    
    local endFunc = function()

        self.m_bottomUI:hideAverageBet()
        
        self.m_initFeatureData = nil
        self.m_collectData.turnwin = 0
        globalData.slotRunData.lastWinCoin = 0
        self.m_llBigOrMegaNum = self.m_runSpinResultData.p_winAmount
        if not self:checkHasBigWin() then
            --检测大赢
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
        end

        self:resetMusicBg()

        self:setCurrSpinMode(NORMAL_SPIN_MODE)
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_winAmount,true,true})
        self:changeBgAni("bonus_base")
        self:changeSceneToBase(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    self:clearCurMusicBg()

    self.m_bottomUI:showAverageBet()
    
    if selfData.bonus and selfData.bonus.game == "box" then
        self.m_changeSceneAni_Bonus:runCsbAction("map")
        self.m_mapView:showView(true)
        self:showBaseReel(false)
        self:showOpenBoxView(selfData.bonus,endFunc)
    elseif selfData.bonus and selfData.bonus.game == "topdollar" then
        self.m_changeSceneAni_Bonus:runCsbAction("map")
        self.m_mapView:showView(true)
        self:showBaseReel(false)
        self:showTopDollarView(selfData.bonus,endFunc)
    else
        self:showMapView(true,endFunc)
        -- self.m_mapView:showView(true,endFunc)
    end

    return true
end

--[[
    显示多福多彩界面
]]
function CodeGameScreenBunnysLockMachine:showColorfulView(bonusData,func)
    self:changeBgAni("colorful")
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_change_scene_colorful.mp3")
    self:showBonusStart("colorful",true,function()
        self.m_colorfulView:showView(bonusData,func)
        self.m_mapView:hideView()
        self:resetMusicBg(true,"BunnysLockSounds/music_BunnysLock_bg_bonus.mp3")
    end)
    
end

--[[
    显示top dollar界面
]]
function CodeGameScreenBunnysLockMachine:showTopDollarView(bonusData,func)
    self:changeBgAni("topdollar")
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_change_scene_topdollar.mp3")
    self:showBonusStart("topdollar",true,function()
        self.m_topDollarView:showView(bonusData,func)
        self.m_mapView:hideView()
        self:resetMusicBg(true,"BunnysLockSounds/music_BunnysLock_bg_bonus.mp3")
    end)
    
end

--[[
    显示开箱子界面
]]
function CodeGameScreenBunnysLockMachine:showOpenBoxView(bonusData,func)
    self:changeBgAni("box")
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_change_scene_box.mp3")
    self:showBonusStart("box",true,function()
        self.m_openBoxView:showView(bonusData,func)
        self.m_mapView:hideView()
        self:resetMusicBg(true,"BunnysLockSounds/music_BunnysLock_bg_bonus.mp3")
    end)
    
end

--[[
    显示bonus小游戏开始
]]
function CodeGameScreenBunnysLockMachine:showBonusStart(bonusType,isStart,func)
    self:clearCurMusicBg()

    local delayTime = 60 / 30
    local spine
    if bonusType == "box" then
        spine = util_spineCreate("BunysLock_kaixiang_gc",true,true)   
        if not isStart then
            delayTime = 50 / 30
        end       
    elseif bonusType == "topdollar" then
        spine = util_spineCreate("BunnysLock_topdollar_gc",true,true)  
        if not isStart then
            delayTime = 12 / 30
        end      
    else
        spine = util_spineCreate("BunnysLock_duofuduocai_gc",true,true)      
        
        if isStart then
            delayTime = 100 / 30
        else
            delayTime = 72 / 30
        end
    end

    self.m_rootNode:addChild(spine,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 30)
    -- spine:setPosition(cc.p(-display.center.x,-display.center.y))

    local aniName = isStart and "actionframe" or "actionframe2"

    util_spinePlay(spine,aniName)
    util_spineEndCallFunc(spine,aniName,function()
        spine:setVisible(false)
        self:delayCallBack(1,function()
            spine:removeFromParent()
        end)
    end)

    self:delayCallBack(delayTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示bonus赢钱
]]
function CodeGameScreenBunnysLockMachine:showBonusWinView(gameType,params,func)
    self:clearCurMusicBg()

    local ownerlist = {}
    ownerlist["m_lb_coins_0"] = util_formatCoins(params.baseCoins,50) 
    ownerlist["m_lb_coins_1"] = util_formatCoins(params.bonusCoins,50) 
    ownerlist["m_lb_coins_2"] = util_formatCoins(params.winCoins,50) 
    local view = self:showDialog("BonusOver2", ownerlist, func)

    view:updateLabelSize({label=view:findChild("m_lb_coins_0"),sx=0.59,sy=0.59},782)
    view:updateLabelSize({label=view:findChild("m_lb_coins_1"),sx=0.59,sy=0.59},782)
    view:updateLabelSize({label=view:findChild("m_lb_coins_2"),sx=0.59,sy=0.59},782)

    view:findChild("wenzi_eggbusket"):setVisible(gameType == "topdollar")
    view:findChild("wenzi_easteregg"):setVisible(gameType == "box")
    view:findChild("wenzi_colormatch"):setVisible(gameType == "colorful")
    view:findChild("wenzi_fanailprize"):setVisible(gameType == "finalprize")

    self.m_collectBar:initProcess()
    
end

--[[
    显示基础赢钱
]]
function CodeGameScreenBunnysLockMachine:showBaseBonusWinCoins(coins,func)
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_bonus_show_win_coins.mp3")
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins,50) 
    local view = self:showDialog("BonusOver1", ownerlist, func)

    view:updateLabelSize({label=view:findChild("m_lb_coins"),sx=1,sy=1},782)

    view:findChild("Node_0"):setVisible(false)
    view:findChild("Node_1"):setVisible(true)
    view:findChild("Node_2"):setVisible(false)

    self.m_collectBar:initProcess()
    self.m_mapView:setVisible(true)
end

--[[
    显示jackpot赢钱
]]
function CodeGameScreenBunnysLockMachine:showJackpotWin(jackpotType,coins,func)

    self:clearCurMusicBg()
    
    local view = util_createView("CodeBunnysLockSrc.BunnysLockJackPotWinView",{
        machine = self,
        jackpotType = jackpotType,
        winCoin = coins,
        func = function()
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
end

-- ------------玩法处理 -- 

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenBunnysLockMachine:addSelfEffect()
    --bonus收集
    if self:getCurCollectPercent() ~= self.m_collectBar:getPercent() then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_COLLECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_COLLECT -- 动画类型
    end

    --中间出现兔子且轮盘里有bonus图标
    local reels = self.m_runSpinResultData.p_reels
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if reels[2][3] == TAG_SYMBOL_TYPE.SYMBOL_BONUS and #storedIcons > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_WIN_BY_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_WIN_BY_BONUS -- 动画类型
    end
        
    self.m_isShowBonus = self:checkHasFeature()
    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBunnysLockMachine:MachineRule_playSelfEffect(effectData)
    --bonus收集
    if effectData.p_selfEffectType == self.EFFECT_COLLECT then
        self:collectBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_WIN_BY_BONUS then --bonus图标赢钱
        self:collectBonusScore(function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
	return true
end

--[[
    bonus图标赢钱
]]
function CodeGameScreenBunnysLockMachine:collectBonusScore(func)

    local callBack = function()
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_fly_bonus_to_win_coins.mp3")

        for index = 1,#self.m_respinView.m_respinNodes do
            local respinNode = self.m_respinView.m_respinNodes[index]
            local symbolNode = respinNode.m_baseFirstNode
            if symbolNode and symbolNode.p_symbolType and symbolNode.p_symbolType == self.SYMBOL_BONUS then
                self:flyCollectScoreAni(symbolNode.m_score,symbolNode,self.m_bottomUI.coinWinNode)
            end
        end
    
        self.m_isBonusWinCoins = true
        self:delayCallBack(40 / 60,function()
            gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_fly_bonus_to_win_coins_feedback.mp3")
            self:playCoinWinEffectUI()
    
            local storedIcons = self.m_runSpinResultData.p_storedIcons
            local multiple = 0
            for index = 1,#storedIcons do
                multiple = multiple + storedIcons[index][2]
            end
    
            local lineBet = globalData.slotRunData:getCurTotalBet()
            local score = lineBet * multiple
            local winAmount = self.m_runSpinResultData.p_winAmount
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                if not self:checkHasBigWin() then
                    self:checkFeatureOverTriggerBigWin(score, GameEffect.EFFECT_BONUS)
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {winAmount, false, true,winAmount - score})
                
            else
                if not self:checkHasBigWin() then
                    self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin, GameEffect.EFFECT_BONUS)
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, true})
                
            end

            -- for index = 1,#self.m_respinView.m_respinNodes do
            --     local respinNode = self.m_respinView.m_respinNodes[index]
            --     local symbolNode = respinNode.m_baseFirstNode
            --     if symbolNode and symbolNode.p_symbolType and symbolNode.p_symbolType ~= self.SYMBOL_BONUS and symbolNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            --         symbolNode:runAnim("dark_over")
            --     end
            -- end

            if self.m_isNoticeCollectScore then
                self.m_isNoticeCollectScore = false
                for index = 1,#self.m_respinView.m_respinNodes do
                    local respinNode = self.m_respinView.m_respinNodes[index]
                    respinNode:hideDarkAni()
                end
            end
            
            if type(func) == "function" then
                func()
            end
        end)
    end

    --兔子播触发
    local midRespinNode = self.m_respinView.m_respinNodes[8]
    if midRespinNode and midRespinNode.m_baseFirstNode and midRespinNode.m_baseFirstNode.p_symbolType then
        local randIndex = math.random(1,3)
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_bonus_trigger_"..randIndex..".mp3")
        midRespinNode.m_baseFirstNode:runAnim("actionframe",false,function()
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                midRespinNode.m_baseFirstNode:runAnim("idleframe",true)
            else
                midRespinNode.m_baseFirstNode:runAnim("idleframe0",true)
            end
            
        end)

        for index = 1,#self.m_respinView.m_respinNodes do
            local respinNode = self.m_respinView.m_respinNodes[index]
            local symbolNode = respinNode.m_baseFirstNode
            if symbolNode and symbolNode.p_symbolType and symbolNode.p_symbolType == self.SYMBOL_BONUS then
                symbolNode:setLocalZOrder(symbolNode:getLocalZOrder() + WIN_LINE_ZORDER)
                symbolNode:runAnim("actionframe",false,function()
                    symbolNode:setLocalZOrder(symbolNode:getLocalZOrder() - WIN_LINE_ZORDER)
                end)

                local csbNode = symbolNode:getCCBNode()
                if csbNode.m_spine then
                    util_spinePlay(csbNode.m_spine,"actionframe")
                end
            end
        end
        self:delayCallBack(2,function()
            callBack()
        end)
    else
        callBack()
    end

    
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenBunnysLockMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
    if winAmonut == nil then
        return
    end

    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
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

function CodeGameScreenBunnysLockMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 or self.m_isBonusWinCoins then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

--[[
    收集分数动画
]]
function CodeGameScreenBunnysLockMachine:flyCollectScoreAni(coins,startNode,endNode,func)
    local flyNode = util_createAnimation("Socre_BunnysLock_Bonus2.csb")
    local Particle = flyNode:findChild("Particle_1")
    Particle:setPositionType(0)

    flyNode:findChild("BitmapFontLabel_1"):setString(util_formatCoins(coins, 3))

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.DelayTime:create(10 / 60),
        cc.MoveTo:create(30 / 60,endPos),
        cc.CallFunc:create(function()
            Particle:stopSystem()
            if type(func) == "function" then
                func()
            end
        end),
        cc.Hide:create(),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
    flyNode:runCsbAction("shouji",false)
end
--[[
    bonus收集进度
]]
function CodeGameScreenBunnysLockMachine:collectBonus(func)
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_fly_bonus_to_collectBar.mp3")
    for index = 1,#self.m_respinView.m_respinNodes do
        local respinNode = self.m_respinView.m_respinNodes[index]
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode and symbolNode.p_symbolType and symbolNode.p_symbolType == self.SYMBOL_BONUS then
            self:flyCollectAni(symbolNode,self.m_collectBar:findChild("shoujitubiao_3_0"))
        end
    end

    local curPercent = self:getCurCollectPercent()
    if curPercent < 100 then
        if type(func) == "function" then
            func()
        end
    end

    self:delayCallBack(40 / 60,function()
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_fly_bonus_to_collectBar_feedback.mp3")
        self.m_collectBar:updateProcess(curPercent,function()
            if curPercent == 100 then
                if type(func) == "function" then
                    func()
                end
            end
        end)
    end)

    

    
    
end

--[[
    收集动画
]]
function CodeGameScreenBunnysLockMachine:flyCollectAni(startNode,endNode,func)
    local flyNode = util_createAnimation("Socre_BunnysLock_Bonus2.csb")

    for index = 1,2 do
        local Particle = flyNode:findChild("Particle_"..index)
        Particle:setPositionType(0)
    end
    

    flyNode:findChild("BitmapFontLabel_1"):setVisible(false)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    local distance = cc.pGetDistance(startPos, endPos)
    local time = distance / 1000

    -- local speed = distance / (40 / 60)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(time,endPos),
        cc.CallFunc:create(function()
            for index = 1,2 do
                local Particle = flyNode:findChild("Particle_"..index)
                Particle:stopSystem()
            end
            
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
    flyNode:runCsbAction("shouji",false)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBunnysLockMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end


function CodeGameScreenBunnysLockMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenBunnysLockMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenBunnysLockMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    CodeGameScreenBunnysLockMachine.super.slotReelDown(self)
end


function CodeGameScreenBunnysLockMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

---
-- 点击spin 按钮开始执行老虎机逻辑
--
function CodeGameScreenBunnysLockMachine:normalSpinBtnCall()
    --暂停中点击了spin不自动开始下一次
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.normalSpinBtnCall then
                self:normalSpinBtnCall()
            end
        end
        return
    end

    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
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
        self:runNextReSpinReel()
    else
        self:setGameSpinStage(WAIT_RUN)
    end

    local timeend = xcyy.SlotsUtil:getMilliSeconds()

    release_print("normalSpinBtnCall 消耗时间4 .. " .. (timeend - time1) .. " =========== ")
end

--开始下次ReSpin
function CodeGameScreenBunnysLockMachine:runNextReSpinReel()
    self.m_isShowBonus = false
    --隐藏提示
    self.m_collectBar:hideTip()
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end

    if self.m_isInMapView then
        self.m_isInMapView = false
        self:changeSceneToBase(function()
            self:runNextReSpinReel()
        end)
        return
    end

    self.m_isNotice = false

    self.m_isBonusWinCoins = false
    self:resetReelDataAfterReel()
    self:notifyClearBottomWinCoin()
    --将锁定的小块解除锁定
    self:unLockRespinNode()

    -- 修改freespin count 的信息
    self:checkChangeFsCount()

    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1

    -- freespin时不做钱的计算
    if not self:checkSpecialSpin(  ) and
        self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
            self:getCurrSpinMode() ~= RESPIN_MODE and betCoin > totalCoin and
                self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE  then

        self:operaUserOutCoins()
    else
        if  self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
                self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
                    not self:checkSpecialSpin(  ) then
            
            self:callSpinTakeOffBetCoin(betCoin)
        else
            self:takeSpinNextData()
        end

        --统计quest spin次数
        self:staticsQuestSpinData()

        self:setGameSpinStage(GAME_MODE_ONE_RUN)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        globalData.userRate:pushSpinCount(1)
        globalData.userRate:pushUsedCoins(betCoin)
        globalData.rateUsData:addSpinCount()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})

        self:delayCallBack(self.m_RESPIN_RUN_TIME,function()
            if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
                self:startReSpinRun()
            end
        end)
    end
end

--[[
    解除锁定小块
]]
function CodeGameScreenBunnysLockMachine:unLockRespinNode()
    local respinNodes = self.m_respinView.m_respinNodes
    for index = 1,#respinNodes do
        local respinNode = respinNodes[index]
        if self:getCurrSpinMode() == FREE_SPIN_MODE and index == 8 then
            self.m_respinView:changeRespinNodeLockStatus(respinNode,true)
        else
            self.m_respinView:changeRespinNodeLockStatus(respinNode,false)
        end
    end
end

--开始滚动
function CodeGameScreenBunnysLockMachine:startReSpinRun()
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

    self:delayCallBack(self.m_changeScatterTime,function()
        self:requestSpinReusltData()
        self.m_respinView:startMove()
    end)
    
end

function CodeGameScreenBunnysLockMachine:requestSpinReusltData()
    local time = xcyy.SlotsUtil:getMilliSeconds()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        performWithDelay(
            self,
            function()
                self:requestSpinResult()
            end,
            0.5
        )
    else
        self:requestSpinResult()
    end

    self.m_isWaitingNetworkData = true

    self:setGameSpinStage(WAITING_DATA)
    -- 设置stop 按钮处于不可点击状态
    if self:getCurrSpinMode() == RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false, true})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
    end

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

function CodeGameScreenBunnysLockMachine:requestSpinResult()
    local betCoin = globalData.slotRunData:getCurTotalBet()

    local totalCoin = globalData.userRunData.coinNum

    -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
    if self.m_spinIsUpgrade == nil then
        self.m_spinIsUpgrade = false
    end
    if self.m_spinNextLevel == nil then
        self.m_spinNextLevel = globalData.userRunData.levelNum
    end
    if self.m_spinNextProVal == nil then
        self.m_spinNextProVal = globalData.userRunData.currLevelExper
    end
    --检测大赢类型

    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
        self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
            not self:checkSpecialSpin(  ) then

                self.m_topUI:updataPiggy(betCoin)
                isFreeSpin = false
    end
    
    self:updateJackpotList()
    
    self:setSpecialSpinStates(false )

    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }
    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

---
-- 处理spin 返回结果
function CodeGameScreenBunnysLockMachine:spinResultCallFun(param)
    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverDelayTime
    -- 把spin数据写到文件 便于找数据bug
    if param[1] == true then
        if device.platform == "mac"  then 
            if param[2] and param[2].result then
                release_print("消息返回胡来了")
                print(cjson.encode(param[2].result))
            end
        end
        dumpStrToDisk(param[2].result, "------------> result = ", 50)
    else
        dumpStrToDisk({"false"}, "------------> result = ", 50)
    end
    self:checkTestConfigType(param)
    local isOpera = self:checkOpearReSpinAndSpecialReels(param) -- 处理respin逻辑
    if isOpera == true then
        return
    end

    if param[1] == true then -- 处理spin成功
        self:checkOperaSpinSuccess(param)
    else -- 处理spin失败
        self:checkOpearSpinFaild(param)
    end
end

---
-- 检测处理respin  和 special reel的逻辑
--
function CodeGameScreenBunnysLockMachine:checkOpearReSpinAndSpecialReels(param)
    if param[1] == true then
        local spinData = param[2]
        -- print("respin"..cjson.encode(param[2]))
        if spinData.action == "SPIN" then
            self:operaUserInfoWithSpinResult(param)

            self.m_isWaitingNetworkData = false

            self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
            self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)

            if self.m_runSpinResultData.p_selfMakeData then
                self:updateBonusData(self.m_runSpinResultData.p_selfMakeData.map_result,self.m_runSpinResultData.p_selfMakeData.collectData)
            end   

            self:MachineRule_RestartProbabilityCtrl()

            --重置收集数据
            self.m_collectData = self.m_runSpinResultData.p_selfMakeData.collectData
            self.m_mapData = self.m_runSpinResultData.p_selfMakeData.map_result
            
            self:getRandomList()

            local selfData = self.m_runSpinResultData.p_selfMakeData
            if selfData and selfData.change_num and selfData.change_num == self.SYMBOL_BONUS then
                self.m_respinView:changeMidEndType(true)
            end

            self:setGameSpinStage(GAME_MODE_ONE_RUN)

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})

            -- 出现预告动画概率30%
            self.m_isNotice = (math.random(1, 100) <= 30) 
            --收集bonus分数预告
            self.m_isNoticeCollectScore = true--(math.random(1, 100) <= 50) 
            if self.m_isNoticeCollectScore then
                local reels = self.m_runSpinResultData.p_reels
                local bonusCount = 0
                for iCol = 1,self.m_iReelColumnNum do
                    for iRow = 1,self.m_iReelRowNum do
                        if reels[iRow][iCol] == self.SYMBOL_BONUS then
                            bonusCount = bonusCount + 1
                        end
                    end
                end

                if bonusCount < 4 or reels[2][3] ~= TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                    self.m_isNoticeCollectScore = false
                end
            end
            
            

            local features = self.m_runSpinResultData.p_features or {}
            if #features >= 2 and features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
            
                if self.m_isNotice then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                    self:playNoticeAni(function()

                    end)
                    self:delayCallBack(0.5,function()
                        self:stopRespinRun()
                    end)
                else
                    self:stopRespinRun()
                end
                
            else
                --预告收集bonus分数
                if self.m_isNoticeCollectScore then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                    self:playNoticeCollectScore(function()
                        
                    end)

                    self:delayCallBack(0.5,function()
                        self:stopRespinRun()
                    end)
                    
                else
                    self:stopRespinRun()
                end
                
            end

            
        end
    else
        --TODO 佳宝 给与弹板玩家提示。。
        gLobalViewManager:showReConnect(true)
    end
    return true
end

--预告收集bonus分数
function CodeGameScreenBunnysLockMachine:playNoticeCollectScore(func)
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_notice_collect_score.mp3")
    -- local iCol = 1
    local delayTime = 0
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum,1,-1 do
            if not(iCol == 3 and iRow == 2) then
                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(iCol,iRow) 
                if respinNode then
                    respinNode:toDarkAni()
                    self:delayCallBack(delayTime,function()
                        respinNode:playNoticeAni()
                    end)
                    delayTime = delayTime + 0.1
                end
            end
            
        end
    end

    self:delayCallBack(delayTime + 40 / 60,function()
        if type(func) == "function" then
            func()
        end
    end)

end

---判断结算
function CodeGameScreenBunnysLockMachine:reSpinReelDown(addNode)
    self:setGameSpinStage(STOP_RUN)

    self.m_respinView:changeMidEndType(false)

    self:updateQuestUI()

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)

    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]

            if reelData == nil or tolua.type(reelData) == "number" then
                
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end

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

    -- self:checkRestSlotNodePos()

    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()

    self:delaySlotReelDown()
    self:stopAllActions()
    self:reelDownNotifyPlayGameEffect()
end

--[[
    延迟回调
]]
function CodeGameScreenBunnysLockMachine:delayCallBack(time, func)
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

function CodeGameScreenBunnysLockMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_lineRespinNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                if frameIndex > #winLines then
                    frameIndex = 1
                    if self.m_showLineHandlerID ~= nil then
                        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                        self.m_showLineHandlerID = nil
                        self:showAllFrame(winLines)
                        self:playInLineNodes()
                        showLienFrameByIndex()
                    end
                    return
                end
                self:playInLineNodesIdle()
                -- 跳过scatter bonus 触发的连线
                while true do
                    if frameIndex > #winLines then
                        break
                    end
                    -- print("showLine ... ")
                    local lineData = winLines[frameIndex]

                    if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                        if #winLines == 1 then
                            break
                        end

                        frameIndex = frameIndex + 1
                        if frameIndex > #winLines then
                            frameIndex = 1
                        end
                    else
                        break
                    end
                end
                -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
                -- 所以打上一个判断
                if frameIndex > #winLines then
                    frameIndex = 1
                end

                self:showLineFrameByIndex(winLines, frameIndex)

                frameIndex = frameIndex + 1
            end,
            self.m_changeLineFrameTime,
            self:getModuleName()
        )
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- end
        self:showAllFrame(winLines) -- 播放全部线框

        showLienFrameByIndex()
    else

        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines, 1)
        end
    end
end

function CodeGameScreenBunnysLockMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
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
            for checkIndex = 1, #self.m_lineRespinNodes do
                local checkNode = self.m_lineRespinNodes[checkIndex]
                if checkNode == slotNode then
                    isHasNode = true
                    break
                end
            end
            if isHasNode == false then
                if bChangeToMask == false then
                    self.m_lineRespinNodes[#self.m_lineRespinNodes + 1] = slotNode
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

                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(symPosData.iY,symPosData.iX)

                checkAddLineSlotNode(respinNode)

                if respinNode.m_baseFirstNode and respinNode.m_baseFirstNode.p_symbolType then
                    if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                        self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = respinNode.m_baseFirstNode
                    end
    
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = respinNode.m_baseFirstNode
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end
end

---
-- 将SlotNode 提升层级到遮罩层以上(本关提到respinView上)
--
function CodeGameScreenBunnysLockMachine:changeToMaskLayerSlotNode(respinNode)
    self.m_lineRespinNodes[#self.m_lineRespinNodes + 1] = respinNode

    self.m_respinView:changeRespinNodeLockStatus(respinNode,true,true)
end

function CodeGameScreenBunnysLockMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineRespinNodes

    for i,respinNode in ipairs(self.m_lineRespinNodes) do
        self.m_respinView:changeRespinNodeLockStatus(respinNode,false)
        if respinNode.m_baseFirstNode and respinNode.m_baseFirstNode.p_symbolType then
            respinNode.m_baseFirstNode:runIdleAnim()
        end
    end

    self.m_lineRespinNodes = {}
end

--[[
    @desc: 在开始滚动前重置数据
    time:2020-07-21 18:25:31
    @return:
]]
function CodeGameScreenBunnysLockMachine:resetReelDataAfterReel()
    self.m_waitChangeReelTime = 0

    --添加线上打印
    local logName = self:getModuleName()
    if logName then
        release_print("beginReel ... GameLevelName = " .. logName)
    else
        release_print("beginReel ... GameLevelName = nil")
    end

    self:stopAllActions()
    self:beforeCheckSystemData()
    -- 记录 本次spin 中共产生的 scatter和bonus 数量，播放音效使用
    self.m_nScatterNumInOneSpin = 0
    self.m_nBonusNumInOneSpin = 0

    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SET_SPIN_BTN_ORDER,{false,gLobalViewManager.p_ViewLayer })
    local effectLen = #self.m_gameEffects
    for i = 1, effectLen, 1 do
        self.m_gameEffects[i] = nil
    end

    self:clearWinLineEffect()

    self.m_showLineFrameTime = nil

    self:resetreelDownSoundArray()
    self:resetsymbolBulingSoundArray()
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenBunnysLockMachine:showLineFrameByIndex(winLines, frameIndex)
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

        preNode = self.m_respinView:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

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

        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(symPosData.iY,symPosData.iX)
        node:setPosition(util_convertToNodeSpace(respinNode.m_baseFirstNode,self.m_respinView))

        local scale = 1
        local isMid = false
        if symPosData.iX == 2 and symPosData.iY == 3 then
            
            scale = respinNode:getScale()
            isMid = true
        end
        node:setScale(scale)
        local zOrder = respinNode.m_baseFirstNode:getLocalZOrder() + 10

        if node:getParent() == nil then
            
            self.m_respinView:addChild(node, zOrder, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            node:runAnim("actionframe", true)
        else
            node:runAnim("actionframe", true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            node:setLocalZOrder(zOrder)
        end
    end

    self:showEachLineSlotNodeLineAnim( frameIndex )
end

---
-- 显示所有的连线框
--
function CodeGameScreenBunnysLockMachine:showAllFrame(winLines)
    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0

    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        preNode = self.m_respinView:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

        if preNode ~= nil then
            -- end
            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index = 1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s", "")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i = 1, frameNum do
            local symPosData = lineValue.vecValidMatrixSymPos[i]

            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then
                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(symPosData.iY,symPosData.iX)

                local node = self:getFrameWithPool(lineValue, symPosData)
                node:setPosition(util_convertToNodeSpace(respinNode.m_baseFirstNode,self.m_respinView))

                local isMid = false
                local scale = 1
                if symPosData.iX == 2 and symPosData.iY == 3 then
                    scale = respinNode:getScale()
                    isMid = true
                end
                node:setScale(scale)

                local zOrder = respinNode.m_baseFirstNode:getLocalZOrder() + 10

                if symPosData.iY == 3 then
                    print("zOrder is "..zOrder.." row is "..symPosData.iX)
                end
                checkIndex = checkIndex + 1
                self.m_respinView:addChild(node, zOrder, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
            end
        end
    end
end

--预告中奖
function CodeGameScreenBunnysLockMachine:playNoticeAni(func)
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_notice_free.mp3")
    self.m_csb_notice:setVisible(true)
    self.m_csb_notice:runCsbAction("actionframe",false,function()
        self.m_csb_notice:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
    self.m_spine_notice:setVisible(true)
    util_spinePlay(self.m_spine_notice,"actionframe")
    util_spineEndCallFunc(self.m_spine_notice,"actionframe",function()
        self.m_spine_notice:setVisible(false)
        
    end)
end

--绘制多个裁切区域
-- function CodeGameScreenBunnysLockMachine:drawReelArea()
--     local iColNum = self.m_iReelColumnNum
--     self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()
--     self.m_slotParents = {}
--     local slotW = 0
--     local slotH = 0
--     local lMax = util_max
--     -- 取底边  和 上边
--     local prePosX = -1

--     self:checkOnceClipNode()
--     for i = 1, iColNum, 1 do
--         local colNodeName = "sp_reel_" .. (i - 1)
--         local reel = self:findChild(colNodeName)
--         local reelSize = reel:getContentSize()
--         local posX = reel:getPositionX()
--         local posY = reel:getPositionY()
--         local scaleX = reel:getScaleX()
--         local scaleY = reel:getScaleY()

--         reelSize.width = reelSize.width * scaleX
--         reelSize.height = reelSize.height * scaleY

--         local diffW = 0
--         if prePosX == -1 then
--             slotW = slotW + reelSize.width
--         else
--             diffW = (posX - prePosX - reelSize.width)
--             slotW = slotW + reelSize.width + diffW
--         end
--         prePosX = posX

--         slotH = lMax(slotH, reelSize.height)

--         local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
--         local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

--         local clipNode
--         local clipNodeBig
--         if self.m_onceClipNode then
--             clipNode = cc.Node:create()
--             clipNode:setContentSize(clipNodeWidth, reelSize.height)
--             --假函数
--             clipNode.getClippingRegion = function()
--                 return {width = clipNodeWidth, height = reelSize.height}
--             end
--             self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)

--             clipNodeBig = cc.Node:create()
--             clipNodeBig:setContentSize(clipNodeWidth, reelSize.height)
--             --假函数
--             clipNodeBig.getClippingRegion = function()
--                 return {width = clipNodeWidth, height = reelSize.height}
--             end
--             self.m_onceClipNode:addChild(clipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000000)
--         else
--             clipNode =
--                 cc.ClippingRectangleNode:create(
--                 {
--                     x = clipWidthX,
--                     y = 0,
--                     width = clipNodeWidth,
--                     height = reelSize.height
--                 }
--             )
--             self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
--         end

--         local slotParentNode = cc.Layer:create() --cc.LayerColor:create(cc.c4f(r,g,b,200))
--         slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
--         --slotParentNode:setPositionX(- reelSize.width * 0.5)
--         clipNode:addChild(slotParentNode)
--         clipNode:setPosition(posX - reelSize.width * 0.5, posY)
--         clipNode:setTag(CLIP_NODE_TAG + i)
--         -- slotParentNode:setVisible(false)

--         local parentData = SlotParentData:new()
--         parentData.slotParent = slotParentNode
--         parentData.cloumnIndex = i
--         parentData.rowNum = self.m_iReelRowNum
--         parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
--         parentData.startX = reelSize.width * 0.5
--         parentData:reset()

--         self.m_slotParents[i] = parentData

--         if clipNodeBig then
--             local slotParentNodeBig = cc.Layer:create()
--             slotParentNodeBig:setContentSize(reelSize.width * 2, reelSize.height)
--             clipNodeBig:addChild(slotParentNodeBig)
--             clipNodeBig:setPosition(posX - reelSize.width * 0.5, posY)
--             parentData.slotParentBig = slotParentNodeBig
--         end
--     end

--     if self.m_clipParent ~= nil then
--         self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
--         self.m_slotEffectLayer:setOpacity(55)
--         self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
--         self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
--         self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

--         self:findChild("root"):addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

--         self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
--         self.m_slotFrameLayer:setOpacity(55)
--         self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
--         self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
--         self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
--         self:findChild("root"):addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)

--         self.m_touchSpinLayer = ccui.Layout:create()
--         self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
--         self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
--         self.m_touchSpinLayer:setTouchEnabled(true)
--         self.m_touchSpinLayer:setSwallowTouches(false)

--         self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
--         self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
--         self.m_touchSpinLayer:setName("touchSpin")
--     end
-- end

---
--
function CodeGameScreenBunnysLockMachine:clearLineAndFrame()
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        preNode = self.m_respinView:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

        if preNode ~= nil then
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end
end

function CodeGameScreenBunnysLockMachine:scaleMainLayer()
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
        mainScale = 0.83
    elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
        mainScale = 0.90
        mainPosY = mainPosY - 10
    elseif ratio < 640 / 960 and ratio >= 768 / 1230 then
        mainScale = 0.96
        -- mainPosY = mainPosY - 20
    elseif ratio < 768 / 1230 and ratio > 768 / 1370 then
        mainScale = 0.98
    else
        mainScale = 1
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

--绘制多个裁切区域
function CodeGameScreenBunnysLockMachine:drawReelArea()
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

        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)

        self:findChild("root"):addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(util_convertToNodeSpace(self.m_csbOwner["sp_reel_0"],self:findChild("root")))
        self.m_touchSpinLayer:setName("touchSpin")

    -- 测试数据，看点击区域范围
    -- self.m_touchSpinLayer:setBackGroundColor(cc.c3b(0, 0, 0))
    -- self.m_touchSpinLayer:setBackGroundColorOpacity(0)
    -- self.m_touchSpinLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    end
end

return CodeGameScreenBunnysLockMachine






