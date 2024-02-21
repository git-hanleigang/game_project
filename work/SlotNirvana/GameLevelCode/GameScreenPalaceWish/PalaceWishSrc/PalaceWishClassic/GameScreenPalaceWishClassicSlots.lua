---
-- island li
-- 2019年1月26日
-- GameScreenPalaceWishClassicSlots.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local GameScreenPalaceWishClassicSlots = class("GameScreenPalaceWishClassicSlots", BaseSlotoManiaMachine)

GameScreenPalaceWishClassicSlots.SYMBOL_SPECAIL_EMPTY = 100
GameScreenPalaceWishClassicSlots.SYMBOL_SPECAIL_5X = 85
GameScreenPalaceWishClassicSlots.SYMBOL_SPECAIL_3X = 83
GameScreenPalaceWishClassicSlots.SYMBOL_SPECAIL_2X = 82

GameScreenPalaceWishClassicSlots.SYMBOL_SPECAIL_9 = 70
GameScreenPalaceWishClassicSlots.SYMBOL_SPECAIL_8 = 71
GameScreenPalaceWishClassicSlots.SYMBOL_SPECAIL_7 = 72
GameScreenPalaceWishClassicSlots.SYMBOL_SPECAIL_6 = 73
GameScreenPalaceWishClassicSlots.SYMBOL_SPECAIL_5 = 74

-- 构造函数
function GameScreenPalaceWishClassicSlots:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_isPlayedAnim = false
end

function GameScreenPalaceWishClassicSlots:initData_( data )
    self.m_parent = data.parent
    self.m_callFunc = data.callFunc
    self.paytable = data.paytable
    self.m_uiHeight = data.height
    self:initGame(data.paytable)
end

function GameScreenPalaceWishClassicSlots:initGame(paytable)


	--初始化基本数据
	self:initMachine()
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}

    self.m_nodeEffect = {}
    local index = 1
    while true do
        local lab = self:findChild("paytable_" .. index )
        local node = self:findChild("ZJ_" .. index )
        if lab ~= nil then
            -- local len = 5
            -- if index > 4 then
            --     len = 4
            -- end
            lab:setString(util_formatCoins(tonumber(paytable[index]), 4))
            self.m_nodeEffect[#self.m_nodeEffect + 1] = node
        else
            break
        end
        index = index + 1
    end

    -- self:findChild("shade_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
    -- self:findChild("shade_2"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
    -- self:findChild("shade_3"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
end  

function GameScreenPalaceWishClassicSlots:initMachine( )

    self.m_moduleName = self:getModuleName()
    self.m_machineModuleName = self.m_moduleName

    self:createCsbNode("PalaceWish/GameScreenPalaceWish_Classic.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
    self:updateBaseConfig()
    
    self:updateMachineData()
    self:initMachineData()
    self:initSymbolCCbNames()

    self:drawReelArea()

    self:updateReelInfoWithMaxColumn()
    self:initReelEffect()

    self:slotsReelRunData(self.m_configData.p_reelRunDatas,self.m_configData.p_bInclScatter
    ,self.m_configData.p_bInclBonus,self.m_configData.p_bPlayScatterAction
    ,self.m_configData.p_bPlayBonusAction)

    self:runCsbAction("start")

    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_classic_machine_enter.mp3")

    --人物
    self.m_juese = util_spineCreate("Socre_PalaceWish_juese", true, true)
    self:findChild("Node_juese"):addChild(self.m_juese)
    self.m_juese:setVisible(true)
    util_spinePlay(self.m_juese, "actionframe6_idle", true)
    self.m_juese:setPosition(cc.p(0, 0))


    --崩钱特效
    self.m_winJumpCoinsEffect = util_spineCreate("PalaceWish_win", true, true)
    -- self.m_bottomUI.coinWinNode:addChild(self.m_winJumpCoinsEffect)
    self.m_winJumpCoinsEffect:setVisible(false)
    
    self.m_winJumpCoinsEffect:setPositionY(530)
    local posNode = util_convertToNodeSpace(self.m_parent.m_bottomUI.coinWinNode, self)
    self.m_parent:addChild(self.m_winJumpCoinsEffect, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_winJumpCoinsEffect:setPosition(cc.pAdd(cc.p(posNode), cc.p(0, 530)))

    --spin前特效
    self.m_magicEffect = util_createAnimation("PalaceWish_classic_magic.csb")
    self:findChild("Node_magic"):addChild(self.m_magicEffect)
    self.m_magicEffect:setVisible(true)

    self.m_winEffect = {}
    for i=1,8 do
        local effect = util_createAnimation("PalaceWish_classic_win.csb")
        self:findChild("win" .. i):addChild(effect)
        self.m_winEffect[i] = effect
        if i == 4 then
            effect:findChild("glow22"):setVisible(true)
            effect:findChild("glow11"):setVisible(false)
        else
            effect:findChild("glow22"):setVisible(false)
            effect:findChild("glow11"):setVisible(true)
        end
        self.m_winEffect[i]:setVisible(false)
    end
    
    self:findChild("PalaceWish_classic_reelBorder_3"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 900)
    self:findChild("PalaceWish_classic_cover_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 901)
    self:findChild("PalaceWish_classic_cover_1_0"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 901)

    self:findChild("xian"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1000)
    self:findChild("PalaceWish_classic1_1_0"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1001)
    self:findChild("PalaceWish_classic1_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1001)
    -- self:findChild("Node_magic"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1010)
end

function GameScreenPalaceWishClassicSlots:playJueseAnim()
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_classic_roleAppear.mp3")

    self.m_juese:setVisible(true)
    util_spinePlay(self.m_juese, "actionframe6", false)
    local spineEndCallFunc = function()
        util_spinePlay(self.m_juese, "actionframe6_idle", true)
    end
    util_spineEndCallFunc(self.m_juese, "actionframe6", spineEndCallFunc)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function GameScreenPalaceWishClassicSlots:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "PalaceWish_Classic"  
end

function GameScreenPalaceWishClassicSlots:getNetWorkModuleName()
    return self.m_parent:getNetWorkModuleName()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function GameScreenPalaceWishClassicSlots:MachineRule_GetSelfCCBName(symbolType)
    
    if symbolType == self.SYMBOL_SPECAIL_2X then
        return "Socre_PalaceWish_Classic_2x"
    elseif symbolType == self.SYMBOL_SPECAIL_3X then
        return "Socre_PalaceWish_Classic_3x"
    elseif symbolType == self.SYMBOL_SPECAIL_5X then
        return "Socre_PalaceWish_Classic_5x"
    elseif symbolType == self.SYMBOL_SPECAIL_EMPTY then
        return "Socre_PalaceWish_Classic_empty"

    elseif symbolType == self.SYMBOL_SPECAIL_9 then
        return "Socre_PalaceWish_Classic_9"
    elseif symbolType == self.SYMBOL_SPECAIL_8 then
        return "Socre_PalaceWish_Classic_8"
    elseif symbolType == self.SYMBOL_SPECAIL_7 then
        return "Socre_PalaceWish_Classic_7"
    elseif symbolType == self.SYMBOL_SPECAIL_6 then
        return "Socre_PalaceWish_Classic_6"
    elseif symbolType == self.SYMBOL_SPECAIL_5 then
        return "Socre_PalaceWish_Classic_5"

    end



    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function GameScreenPalaceWishClassicSlots:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SPECAIL_2X,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SPECAIL_3X,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SPECAIL_5X,count =  2}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SPECAIL_9,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SPECAIL_8,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SPECAIL_7,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SPECAIL_6,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SPECAIL_5,count =  2}

    return loadNode
end


function GameScreenPalaceWishClassicSlots:slotReelDown()
    BaseSlotoManiaMachine.slotReelDown(self)
    if self.m_spinSoundId ~= nil then
        gLobalSoundManager:stopAudio(self.m_spinSoundId)
        self.m_spinSoundId = nil
    end
end

--绘制多个裁切区域
function GameScreenPalaceWishClassicSlots:drawReelArea()
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
            clipNode:setContentSize(clipNodeWidth,reelSize.height)
            --假函数
            clipNode.getClippingRegion= function() return {width = clipNodeWidth,height = reelSize.height} end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        else
            clipNode = cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create()     
        
        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)

        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY - high * 0.5)
        clipNode:setTag(CLIP_NODE_TAG + i)



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
function GameScreenPalaceWishClassicSlots:updateReelInfoWithMaxColumn()
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

function GameScreenPalaceWishClassicSlots:checkRestSlotNodePos( )
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

        --判断tag值 如果父节点有节点tag < xxx 切节点不为轮盘 则将节点放入对应轮盘 轮盘有节点tag 》xx 则将节点放入父节点
        local childs = slotParent:getChildren()
        for i = 1, #childs do
            local childNode = childs[i]
            if childNode.m_isLastSymbol == true then
                if childNode:getTag() < SYMBOL_NODE_TAG + BIG_SYMBOL_NODE_DIFF_TAG then
                    --将该节点放在 .m_clipParent
                    childNode:removeFromParent()
                    local posWorld =
                        slotParent:convertToWorldSpace(cc.p(childNode:getPositionX(), childNode:getPositionY()))
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


function GameScreenPalaceWishClassicSlots:spinResultCallFun(param)

    if param[1] == true then
        local spinData = param[2]
        -- print(cjson.encode(param[2])) 
        -- if spinData.action == "SPIN" then

            globalData.seqId = spinData.sequenceId
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果

            --发送测试赢钱数
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN,self.m_serverWinCoins)

            globalData.userRate:pushCoins(self.m_serverWinCoins)


            release_print("消息返回胡来了")

            
            self.m_parent:setLastWinCoin( spinData.result.freespin.fsWinCoins )
            self.m_parent.m_runSpinResultData.p_features = spinData.result.features or {0}

            self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
            self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
            
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

            self:updateNetWorkData()
        -- end

    else
        self:checkOpearSpinFaild(param)  
    end
end

function GameScreenPalaceWishClassicSlots:requestSpinResult()
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

    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,
                        data=self.m_collectDataList,jackpot = self.m_jackpotList, betLevel = self.m_iBetLevel}
    -- local operaId = 
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, true, moduleName, 
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end

function GameScreenPalaceWishClassicSlots:callSpinBtn()
    local callSpin = function()
        -- 去除掉 ， auto和 freespin的倒计时监听
        if self.m_handerIdAutoSpin ~= nil then
            scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
            self.m_handerIdAutoSpin = nil
        end

        self:notifyClearBottomWinCoin()

        local betCoin = self:getSpinCostCoins() or toLongNumber(0)
        local totalCoin = globalData.userRunData.coinNum or 1

        -- freespin时不做钱的计算
        if false and self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and betCoin > totalCoin then
            --金币不足
            -- gLobalTriggerManager:triggerShow({viewType=TriggerViewType.Trigger_NotEnoughSpin})
            gLobalPushViewControl:showView(PushViewPosType.NoCoinsToSpin)
            -- cxc 2023-12-05 15:57:06 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
            local checkOperaGuidePop = function()
                if tolua.isnull(self) then
                    return
                end
                
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
                    view:setOverFunc(util_node_handler(self, self.showLuckyVedio))
                else
                    self:showLuckyVedio()
                end
            end
            gLobalPushViewControl:setEndCallBack(checkOperaGuidePop)
          
            if self:getCurrSpinMode() == AUTO_SPIN_MODE then
                gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)
            end

        else
            if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
                self:getCurrSpinMode() ~= RESPIN_MODE and false
            then
                self:callSpinTakeOffBetCoin(betCoin)
                print("callSpinBtn  点击了spin14")
            else
                self.m_spinNextLevel = globalData.userRunData.levelNum
                self.m_spinNextProVal = globalData.userRunData.currLevelExper
                self.m_spinIsUpgrade = false
            end

            --统计quest spin次数
            self:staticsQuestSpinData()

            self:spinBtnEnProc()

            self:setGameSpinStage( GAME_MODE_ONE_RUN )

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
    if self.m_isPlayedAnim then
        callSpin()
    else
        self.m_isPlayedAnim = true
        self:playJueseAnim()
        performWithDelay(self, function()
            local random = math.random(1, 3)
            self.m_spinSoundId = gLobalSoundManager:playSound("PalaceWishSounds/sound_classic_spin_"..random..".mp3")
            callSpin()
        end,36/30)
    end
    
end

function GameScreenPalaceWishClassicSlots:MachineRule_checkTriggerFeatures()

end

function GameScreenPalaceWishClassicSlots:callSpinTakeOffBetCoin(betCoin)
    
end

function GameScreenPalaceWishClassicSlots:addLastWinSomeEffect()

end

function GameScreenPalaceWishClassicSlots:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()

    -- self:runCsbAction("appear")
    -- self:symbolNodeAnimation("appear")

    performWithDelay(self, function()
        
        if self.m_parent.m_gameEffects and type(self.m_parent.m_gameEffects) == "table"  then
            local effectLen = #self.m_parent.m_gameEffects
            for i = 1, effectLen, 1 do
                self.m_parent.m_gameEffects[i] = nil
            end
        end
        

        self:normalSpinBtnCall()
    end, 1)
end

function GameScreenPalaceWishClassicSlots:addObservers()
	BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
            soundTime = 2
        elseif winRate > 1 and winRate <= 6 then
            soundIndex = 2
            soundTime = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
            soundTime = 3
        end

        local soundName = "PalaceWishSounds/sound_classic_lastwin_1.mp3"
        local winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function GameScreenPalaceWishClassicSlots:symbolNodeAnimation(animation)
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

function GameScreenPalaceWishClassicSlots:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
-- 每个reel条滚动到底
function GameScreenPalaceWishClassicSlots:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1)
    and
    (self:getGameSpinStage( ) ~= QUICK_RUN
    or self.m_hasBigSymbol == true
    )
    then
        self:creatReelRunAnimation(reelCol + 1)
    end


    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol) then
            gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_reel_down.mp3")
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_reel_down.mp3")
    end


    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

function GameScreenPalaceWishClassicSlots:playEffectNotifyNextSpinCall( )
    if self.m_runSpinResultData.p_winAmount == 0 then
        performWithDelay(self, function()
            -- self.m_magicEffect:setVisible(true)
            -- self.m_magicEffect:runCsbAction("actionframe", false, function()
                local random = math.random(1, 3)
                self.m_spinSoundId = gLobalSoundManager:playSound("PalaceWishSounds/sound_classic_spin_"..random..".mp3")
                self:normalSpinBtnCall()
                -- self.m_magicEffect:setVisible(false)
            -- end)

        end, 1)

        
    else
       
        local index = self.m_runSpinResultData.p_winLines[1].p_id

        for i=1,8 do
            if self.m_winEffect[i] and index == i then
                self.m_winEffect[i]:setVisible(true)
                self.m_winEffect[i]:runCsbAction("actionframe", true)
            end
        end

        self.m_magicEffect:setVisible(true)
        self.m_magicEffect:runCsbAction("actionframe", false, function()
            self.m_magicEffect:setVisible(false)
        end)

        self.m_winJumpCoinsEffect:setVisible(true)
        util_spinePlay(self.m_winJumpCoinsEffect, "actionframe", false)
        local spineEndCallFunc = function()
            self.m_winJumpCoinsEffect:setVisible(false)
        end
        util_spineEndCallFunc(self.m_winJumpCoinsEffect, "actionframe", spineEndCallFunc)

        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_classic_finalwin.mp3")

        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_classic_magicEffect.mp3")

        -- gLobalSoundManager:playSound("PalaceWishSounds/sound_classic_lastwin_1.mp3")
        

        performWithDelay(self, function()

            performWithDelay(self, function()
                
                self.m_parent:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount , GameEffect.EFFECT_BONUS)
                -- self:symbolNodeAnimation("disappear")
                -- self:runCsbAction("disappear", false, function()
                    self.m_parent:classicSlotOverView(self.m_runSpinResultData.p_winAmount, self.m_callFunc)
                    -- self:removeFromParent()
                -- end)
            end, 0.5)
            self:clearWinLineEffect()
            self:resetMaskLayerNodes()
            -- effect:removeFromParent()
        end, 2.5)
    end
end

function GameScreenPalaceWishClassicSlots:playEffectNotifyChangeSpinStatus( )

end

function GameScreenPalaceWishClassicSlots:showLineFrameByIndex(winLines,frameIndex)

end

function GameScreenPalaceWishClassicSlots:checkControlerReelType( )
    return false
end

function GameScreenPalaceWishClassicSlots:resetMusicBg(isMustPlayMusic, musicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    self:resetCurBgMusicName(musicName)

    if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
        -- if preBgMusic ~= self.m_currentMusicBgName or isMustPlayMusic == true then
        --     self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        -- end
        -- if self.m_currentMusicId == nil then
        --     self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        -- end
    else
        -- gLobalSoundManager:stopAudio(self.m_currentMusicId)
        -- self.m_currentMusicId = nil
        self:clearCurMusicBg()
    end
end

function GameScreenPalaceWishClassicSlots:onExit()
    -- BaseMachineGameEffect.onExit(self) -- 必须调用不予许删除
    --停止背景音乐
    -- gLobalSoundManager:stopBgMusic()
    -- gLobalSoundManager:stopAllSounds()

    gLobalDebugReelTimeManager.m_Machine = nil

    self:removeObservers()

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
        local viewLayer = gLobalViewManager.p_ViewLayer
        if not tolua.isnull(viewLayer) then
            viewLayer:removeAllChildren()
        end
    end
    

    self:removeSoundHandler()

    self:clearLayerChildReferenceCount()

    self:clearLevelsCodeCache()
    --离开，清空
    gLobalActivityManager:clear()
end

function GameScreenPalaceWishClassicSlots:updateReelGridNode(symblNode)
    if symblNode then
        symblNode:runIdleAnim()
    end
end

function GameScreenPalaceWishClassicSlots:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    -- 改
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, false})
    -- 改
end

return GameScreenPalaceWishClassicSlots






