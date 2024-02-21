---
-- island li
-- 2019年1月26日
-- GameScreenClassicSlots.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local GameScreenClassicSlots = class("GameScreenClassicSlots", BaseSlotoManiaMachine)

GameScreenClassicSlots.SYMBOL_SPECAIL_EMPTY = 100
GameScreenClassicSlots.SYMBOL_SPECAIL_5X = 85
GameScreenClassicSlots.SYMBOL_SPECAIL_3X = 83
GameScreenClassicSlots.SYMBOL_SPECAIL_2X = 82

GameScreenClassicSlots.SYMBOL_SPECAIL_9 = 70
GameScreenClassicSlots.SYMBOL_SPECAIL_8 = 71
GameScreenClassicSlots.SYMBOL_SPECAIL_7 = 72
GameScreenClassicSlots.SYMBOL_SPECAIL_6 = 73
GameScreenClassicSlots.SYMBOL_SPECAIL_5 = 74

-- 构造函数
function GameScreenClassicSlots:ctor()
    BaseSlotoManiaMachine.ctor(self)
end

function GameScreenClassicSlots:initData_( data )
    self.m_parent = data.parent
    self.m_callFunc = data.func
    self.m_effectData = data.effectData
    self.paytable = data.paytable
    self.m_uiHeight = data.height
    self:initGame(data.paytable)
end

function GameScreenClassicSlots:initGame(paytable)


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

    self:findChild("shade_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
    self:findChild("shade_2"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
    self:findChild("shade_3"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
end  

function GameScreenClassicSlots:initMachine( )

    self.m_moduleName = self:getModuleName()
    self.m_machineModuleName = self.m_moduleName

    self:createCsbNode("Puss/GameScreenPuss_Classic.csb")
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

    if display.height < 1370 then
        self:findChild("root"):setScale((display.height - self.m_uiHeight) / (1370 - self.m_uiHeight))
    else
        local posY = (display.height - 1370) * 0.5
        self:findChild("reel"):setPositionY(self:findChild("reel"):getPositionY() - posY)
        self:findChild("title"):setPositionY(self:findChild("title"):getPositionY() - posY)
        self:findChild("paytable"):setPositionY(self:findChild("paytable"):getPositionY() + posY * 0.5)
    end
    -- self:findChild("root"):setPositionY(self:findChild("root"):getPositionY() + 100)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function GameScreenClassicSlots:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "Puss_Classic"  
end

function GameScreenClassicSlots:getNetWorkModuleName()
    return self.m_parent:getNetWorkModuleName()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function GameScreenClassicSlots:MachineRule_GetSelfCCBName(symbolType)
    
    if symbolType == self.SYMBOL_SPECAIL_2X then
        return "Socre_Puss_Classic_2x"
    elseif symbolType == self.SYMBOL_SPECAIL_3X then
        return "Socre_Puss_Classic_3x"
    elseif symbolType == self.SYMBOL_SPECAIL_5X then
        return "Socre_Puss_Classic_5x"
    elseif symbolType == self.SYMBOL_SPECAIL_EMPTY then
        return "Socre_Puss_Classic_empty"

    elseif symbolType == self.SYMBOL_SPECAIL_9 then
        return "Socre_Puss_Classic_9"
    elseif symbolType == self.SYMBOL_SPECAIL_8 then
        return "Socre_Puss_Classic_8"
    elseif symbolType == self.SYMBOL_SPECAIL_7 then
        return "Socre_Puss_Classic_7"
    elseif symbolType == self.SYMBOL_SPECAIL_6 then
        return "Socre_Puss_Classic_6"
    elseif symbolType == self.SYMBOL_SPECAIL_5 then
        return "Socre_Puss_Classic_5"

    end



    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function GameScreenClassicSlots:getPreLoadSlotNodes()
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


function GameScreenClassicSlots:slotReelDown()
    BaseSlotoManiaMachine.slotReelDown(self)
    if self.m_spinSoundId ~= nil then
        gLobalSoundManager:stopAudio(self.m_spinSoundId)
        self.m_spinSoundId = nil
    end
end

--绘制多个裁切区域
function GameScreenClassicSlots:drawReelArea()
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
function GameScreenClassicSlots:updateReelInfoWithMaxColumn()
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

function GameScreenClassicSlots:checkRestSlotNodePos( )
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


function GameScreenClassicSlots:spinResultCallFun(param)

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

function GameScreenClassicSlots:requestSpinResult()
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

function GameScreenClassicSlots:callSpinBtn()



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

function GameScreenClassicSlots:MachineRule_checkTriggerFeatures()

end

function GameScreenClassicSlots:callSpinTakeOffBetCoin(betCoin)
    
end

function GameScreenClassicSlots:addLastWinSomeEffect()

end

function GameScreenClassicSlots:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()

    self:runCsbAction("appear")
    -- self:symbolNodeAnimation("appear")

    performWithDelay(self, function()
        local random = math.random(1, 3)
        self.m_spinSoundId = gLobalSoundManager:playSound("PussSounds/sound_classic_spin_"..random..".mp3")
        if self.m_parent.m_gameEffects and type(self.m_parent.m_gameEffects) == "table"  then
            local effectLen = #self.m_parent.m_gameEffects
            for i = 1, effectLen, 1 do
                self.m_parent.m_gameEffects[i] = nil
            end
        end
        

        self:normalSpinBtnCall()
    end, 1)
end

function GameScreenClassicSlots:addObservers()
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

        local soundName = "PussSounds/sound_classic_lastwin_".. soundIndex .. ".mp3"
        local winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function GameScreenClassicSlots:symbolNodeAnimation(animation)
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

function GameScreenClassicSlots:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
-- 每个reel条滚动到底
function GameScreenClassicSlots:slotOneReelDown(reelCol)
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
            gLobalSoundManager:playSound("PussSounds/sound_classic_reelStop.mp3")
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        gLobalSoundManager:playSound("PussSounds/sound_classic_reelStop.mp3")
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

function GameScreenClassicSlots:playEffectNotifyNextSpinCall( )
    if self.m_runSpinResultData.p_winAmount == 0 then
        performWithDelay(self, function()
            local random = math.random(1, 3)
            self.m_spinSoundId = gLobalSoundManager:playSound("PussSounds/sound_classic_spin_"..random..".mp3")
            self:normalSpinBtnCall()
        end, 1)
    else
       
        local index = self.m_runSpinResultData.p_winLines[1].p_id

        -- local fileName = "Pusss_Smallgame_1.csb"
        -- if index == 1 then
        --     fileName = "Pusss_Smallgame_5.csb"
        -- elseif index == 2 or index == 3 then
        --     fileName = "Pusss_Smallgame_4.csb"
        -- elseif index == 4 then
        --     fileName = "Pusss_Smallgame_3.csb"
        -- elseif index == 5 or index == 6 then
        --     fileName = "Pusss_Smallgame_2.csb"
        -- end

        -- local effect, act = util_csbCreate(fileName)
        -- util_csbPlayForKey(act, "idleframe", true)
        -- self.m_nodeEffect[index]:addChild(effect)

        performWithDelay(self, function()

            performWithDelay(self, function()
                
                self.m_parent:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount , GameEffect.EFFECT_BONUS)
                self:symbolNodeAnimation("disappear")
                self:runCsbAction("disappear", false, function()
                    self.m_parent:classicSlotOverView(self.m_runSpinResultData.p_winAmount, self.m_effectData)
                    -- self:removeFromParent()
                end)
            end, 0.5)
            self:clearWinLineEffect()
            self:resetMaskLayerNodes()
            -- effect:removeFromParent()
        end, 2.5)
    end
end

function GameScreenClassicSlots:playEffectNotifyChangeSpinStatus( )

end

function GameScreenClassicSlots:showLineFrameByIndex(winLines,frameIndex)

end

function GameScreenClassicSlots:checkControlerReelType( )
    return false
end
return GameScreenClassicSlots






