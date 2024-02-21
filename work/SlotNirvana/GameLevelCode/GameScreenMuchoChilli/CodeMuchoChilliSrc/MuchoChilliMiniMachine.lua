---
-- xcyy
-- 2018-12-18 
-- MuchoChilliMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local MuchoChilliMiniMachine = class("MuchoChilliMiniMachine", BaseMiniMachine)

MuchoChilliMiniMachine.m_machineIndex = nil -- csv 文件模块名字

MuchoChilliMiniMachine.gameResumeFunc = nil
MuchoChilliMiniMachine.gameRunPause = nil

local Main_Reels = 1

-- 构造函数
function MuchoChilliMiniMachine:ctor()
    MuchoChilliMiniMachine.super.ctor(self)

end

function MuchoChilliMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    self.m_maxReelIndex = data.maxReelIndex 
    self.m_isMiniMachine = true
    self.m_isPlayUpdateRespinNums = true --是否播放刷新respin次数

    --滚动节点缓存列表
    self.cacheNodeMap = {}
    --init
    self:initGame()
end

function MuchoChilliMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end


-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MuchoChilliMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MuchoChilli"
end

function MuchoChilliMiniMachine:getMachineConfigName()

    return "MuchoChilliConfig.csv"
end

-- 继承底层respinView
function MuchoChilliMiniMachine:getRespinView()
    return self.m_parent:getRespinView()
end
-- 继承底层respinNode
function MuchoChilliMiniMachine:getRespinNode()
    return self.m_parent:getRespinNode()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function MuchoChilliMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

---
-- 读取配置文件数据
--
function MuchoChilliMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function MuchoChilliMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("MuchoChilli_Mini_up.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")

    self:initReSpinBar()

    --棋盘集满效果
    self.m_respinMansNode = util_createAnimation("MuchoChilli_mans.csb")
    self:findChild("mans"):addChild(self.m_respinMansNode)
    self.m_respinMansNode:setVisible(false)

    self.m_respinManxNode = util_createAnimation("MuchoChilli_manx.csb")
    self:findChild("manx"):addChild(self.m_respinManxNode)
    self.m_respinManxNode:setVisible(false)

    self.m_respinChengBeiNode = util_createAnimation("MuchoChilli_chengbei.csb")
    self:findChild("chengbei"):addChild(self.m_respinChengBeiNode)
    self.m_respinChengBeiNode:setVisible(false)
end

--[[
    @desc: 
    author:{author}
    time:2023-03-17 12:23:32
    @return:
]]
function MuchoChilliMiniMachine:playReelStartEffect(_actionframe, _func)
    self:runCsbAction(_actionframe, false, function()
        if _func then
            _func()
        end
    end)
    if _actionframe == "sheng" then
        self.m_parent:delayCallBack(40 / 60, function()
            for ParticleIndex = 3, 6 do
                if self:findChild("Particle_"..ParticleIndex) then
                    self:findChild("Particle_"..ParticleIndex):resetSystem()
                end
            end
        end)
    end
end

--[[
    集满的时候 播放集满动画
]]
function MuchoChilliMiniMachine:playJiManEffect( )
    self.m_respinMansNode:setVisible(true)
    self.m_respinManxNode:setVisible(true)
    self.m_respinMansNode:runCsbAction("actionframe", false, function()
        self.m_respinMansNode:setVisible(false)
    end)
    self.m_respinManxNode:runCsbAction("actionframe", false, function()
        self.m_respinManxNode:setVisible(false)
    end)

    self.m_parent:delayCallBack(120 / 60, function()
        self.m_respinChengBeiNode:setVisible(true)
        self.m_respinChengBeiNode:runCsbAction("start", false)
    end)

    -- start之后 0.5秒播放
    self.m_parent:delayCallBack((120+33+0.5) / 60, function()
        self.m_respinChengBeiNode:runCsbAction("chengbei", false, function()
            self.m_respinChengBeiNode:setVisible(false)
        end)
    end)
end

function MuchoChilliMiniMachine:initReSpinBar()
    local node_bar = self:findChild("Node_SingleBoard")
    self.m_respinBarView = util_createView("CodeMuchoChilliSrc.MuchoChilliRespinBar", {machine = self.m_parent})
    node_bar:addChild(self.m_respinBarView)
    self.m_respinBarView:showBarByReelNums(2, true)
    self.m_respinBarView:showTips(true)
end

--[[
    刷新当前respin剩余次数
]]
function MuchoChilliMiniMachine:changeReSpinUpdateUI(curCount, _isComeIn)
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    if totalCount <= 0 then
        if self.m_parent:getRespinType() == "extraSpin" or self.m_parent:getRespinType() == nil then
            totalCount = 4
        else
            totalCount = 3
        end
    end
    self.m_respinBarView:updateRespinCount(curCount, totalCount, _isComeIn)
end

function MuchoChilliMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    MuchoChilliMiniMachine.super.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function MuchoChilliMiniMachine:addSelfEffect()
 
end

function MuchoChilliMiniMachine:MachineRule_playSelfEffect(effectData)

    return true
end

function MuchoChilliMiniMachine:onEnter()
    MuchoChilliMiniMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

-- function MuchoChilliMiniMachine:addObservers()

--     MuchoChilliMiniMachine.super.addObservers(self)

--     gLobalNoticManager:addObserver(
--         self,
--         function(Target, params)
--             Target:MachineRule_respinTouchSpinBntCallBack()
--         end,
--         ViewEventType.RESPIN_TOUCH_SPIN_BTN
--     )
    
-- end

function MuchoChilliMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end

function MuchoChilliMiniMachine:playEffectNotifyChangeSpinStatus( )

end

function MuchoChilliMiniMachine:quicklyStopReel(colIndex)

end

function MuchoChilliMiniMachine:onExit()
    MuchoChilliMiniMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function MuchoChilliMiniMachine:removeObservers()
    MuchoChilliMiniMachine.super.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

function MuchoChilliMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end

function MuchoChilliMiniMachine:beginMiniReel()
    self.m_addSounds = {}
    MuchoChilliMiniMachine.super.beginReel(self)

end

-- 消息返回更新数据
function MuchoChilliMiniMachine:netWorkCallFun(spinResult)

end

function MuchoChilliMiniMachine:enterLevel( )
    MuchoChilliMiniMachine.super.enterLevel(self)
end

function MuchoChilliMiniMachine:enterLevelMiniSelf( )

    MuchoChilliMiniMachine.super.enterLevel(self)
    
end

function MuchoChilliMiniMachine:dealSmallReelsSpinStates( )
    
end

-- 处理特殊关卡 遮罩层级
function MuchoChilliMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    local maxzorder = 0
    local zorder = 0
    for i=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder >  maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

---
--设置bonus scatter 层级
function MuchoChilliMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_parent:getBounsScatterDataZorder(symbolType )

end

function MuchoChilliMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function MuchoChilliMiniMachine:checkGameResumeCallFun( )
    if self:checkGameRunPause() then
        self.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end
        return false
    end
    return true
end

function MuchoChilliMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function MuchoChilliMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function MuchoChilliMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end



---
-- 清空掉产生的数据
--
function MuchoChilliMiniMachine:clearSlotoData()
    
    -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then

        for i=#self.m_lineDataPool,1,-1 do
            self.m_lineDataPool[i] = nil
        end

    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function MuchoChilliMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function MuchoChilliMiniMachine:clearCurMusicBg( )
    
end

function MuchoChilliMiniMachine:reelDownNotifyPlayGameEffect( )
    -- self:playGameEffect()
end

--[[
    刷新小块
]]
function MuchoChilliMiniMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        self:setSpecialNodeScore(node)
    end

    if self.m_parent:isFixLocalSymbol(symbolType) then
        self.m_parent:setLocalSpecialNodeScore(node)
    end
end

--[[
    判断是否为bonus小块
]]
function MuchoChilliMiniMachine:isFixSymbol(symbolType)
    return self.m_parent:isFixSymbol(symbolType)
end

--[[
    给bonus信号块上的数字进行赋值
]]
function MuchoChilliMiniMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if self:isFixSymbol(symbolNode.p_symbolType) then
        -- 展示
        local symbol_node = symbolNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        local coinsView
        if not spineNode.m_csbNode then
            coinsView = util_createAnimation("Socre_MuchoChilli_Bonus_Coins.csb")
            util_spinePushBindNode(spineNode,"shuzi",coinsView)
            spineNode.m_csbNode = coinsView
        else
            spineNode.m_csbNode:setVisible(true)
            coinsView = spineNode.m_csbNode
        end

        local score = 0
        local type = nil
        if iRow ~= nil and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            local pos = self.m_parent:getPosReelIdx(iRow,iCol)
            score, type = self:getReSpinSymbolScore(pos, true)
        else
            score, type = self.m_parent:randomDownRespinSymbolScore(symbolNode)
        end

        self.m_parent:showBonusJackpotOrCoins(coinsView, score, type)
    end
end

--[[
    棋盘是否集满
]]
function MuchoChilliMiniMachine:isJiManReels( )
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    if #storedIcons >= 15 then
        return true
    end
    return false
end

-- 根据网络数据获得respinBonus小块的分数
function MuchoChilliMiniMachine:getReSpinSymbolScore(_pos, _isAdd)
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local viceAddStoredIcons = selfMakeData.viceAddStoredIcons or {}
    local score = nil
    local type = nil

    for _index, _storeData in pairs(storedIcons) do
        if tonumber(_storeData[1]) == _pos then
            score = _storeData[2]
            type = _storeData[3]
            break
        end
    end

    --respin玩法里 如果有加钱的话 刚滚出来的 先减去加的钱
    if score and _isAdd then
        for _index, _addStoreData in ipairs(viceAddStoredIcons) do
            if tonumber(_addStoreData[1]) == _pos then
                score = score - _addStoreData[2]
                break
            end
        end
    end

    if score == nil then
       return 0
    end

    return score, type
end

function MuchoChilliMiniMachine:initRespinView(endTypes, randomTypes)
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
            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function MuchoChilliMiniMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if not self:isFixSymbol(symbolType) then
                symbolType = self.m_parent.SYMBOL_EMPTY
            end
            if symbolType == self.m_parent.SYMBOL_SPECIAL_BONUS and self.m_parent:getRespinType() ~= nil then
                symbolType = self.m_parent.SYMBOL_BONUS
            end
            if symbolType == self.m_parent.SYMBOL_BONUS and self.m_parent:getRespinType() == nil then
                symbolType = self.m_parent.SYMBOL_SPECIAL_BONUS
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_parent.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_parent.m_machineRootScale

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

--[[
    处理spin结果数据
]]
function MuchoChilliMiniMachine:setSpinResultData(result)
    self.m_runSpinResultData = clone(result)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    self.m_runSpinResultData.p_reels = selfData.viceReels
    self.m_runSpinResultData.p_storedIcons = selfData.viceStoredIcons
    self.m_runSpinResultData.p_reSpinCurCount = selfData.viceReSpinCurTimes
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    if totalCount <= 0 then
        if self.m_parent:getRespinType() == "extraSpin" or self.m_parent:getRespinType() == nil then
            self.m_runSpinResultData.p_reSpinsTotalCount = 4
        else
            self.m_runSpinResultData.p_reSpinsTotalCount = 3
        end
    end
end

---判断结算
function MuchoChilliMiniMachine:reSpinReelDown(addNode)
    self:setGameSpinStage(STOP_RUN)
    
    self.m_parent:oneReSpinReelDown()

    if self.m_runSpinResultData.p_reSpinCurCount > 0 then
        -- self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    end
end

--开始滚动
function MuchoChilliMiniMachine:startReSpinRun()
    self.m_isPlayUpdateRespinNums = true
    if self.m_runSpinResultData.p_reSpinCurCount <= 0 then
        self.m_respinBarView:showTextByNums(self.m_runSpinResultData.p_reSpinCurCount, true)
        self:reSpinReelDown()
        return
    end
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end

    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end
    self.m_respinView:startMove()
end

function MuchoChilliMiniMachine:respinOver()
    self:setReelSlotsNodeVisible(true)

    -- self:removeRespinNode()

    self:triggerReSpinOverCallFun(0)
end

function MuchoChilliMiniMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_preReSpinStoredIcons = nil
    
    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0
end

--[[
    bonusBoost玩法 加钱
]]
function MuchoChilliMiniMachine:checkAddBonusSymbolScore(_func)
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local addStoredIcons = selfMakeData.addStoredIcons or {}

    if #addStoredIcons > 0 then
        for _index, _data in ipairs(addStoredIcons) do
            local fixPos = self:getRowAndColByPos(_data[1])
            local respinNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
            if respinNode then
                self.m_parent:playExtraSpinFlyEffect(respinNode, function()
                    self.m_parent:playAddCoinsBonusEffect(respinNode, _data[1], _data[2])
                    if _index == #addStoredIcons then
                        if _func then
                            _func()
                        end
                    end
                end)
            end
        end
    else
        if _func then
            _func()
        end
    end
end

--[[
    respin单列停止
]]
function MuchoChilliMiniMachine:respinOneReelDown(colIndex,isQuickStop)
    self.m_parent:respinOneReelDown(colIndex,isQuickStop)
end

--[[
    检测播放bonus落地音效
]]
function MuchoChilliMiniMachine:checkPlayBonusDownSound(_node)
    self.m_parent:checkPlayBonusDownSound(_node)
end

return MuchoChilliMiniMachine
