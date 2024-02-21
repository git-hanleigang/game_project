---
--xcyy
--2018年5月23日
--AquaQuestRespinReelView.lua
local PublicConfig = require "AquaQuestPublicConfig"
local AquaQuestRespinReelView = class("AquaQuestRespinReelView",util_require("Levels.BaseLevelDialog"))


function AquaQuestRespinReelView:initUI(params)
    self.m_machine = params.machine
    self.m_iReelColumnNum = params.colNum
    self.m_iReelRowNum = params.rowNum
    self.m_soundIndex = 1

    self.m_isShowCollectGame = false

    --落地音效
    self.m_symbolDownSounds = {}

    self.m_isDouble = params.isDouble
    self.m_endTypes = params.endTypes
    self.m_randomTypes = params.randomTypes
    self.getSlotNodeWithPosAndType = params.getSlotNodeWithPosAndType
    self.pushSlotNodeToPoolBySymobolType = params.pushSlotNodeToPoolBySymobolType

    self.m_winCoins = 0

    self.m_isRunning = false

    self.m_respinViewList = {}

    if self.m_isDouble then
        if self.m_iReelColumnNum == 5 then
            self:createCsbNode("AquaQuest_respin_reels_3X5_double.csb")
        else
            self:createCsbNode("AquaQuest_respin_reels_3X7_double.csb")
        end
    else
        if self.m_iReelColumnNum == 5 then
            self:createCsbNode("AquaQuest_respin_reels_3X5.csb")
        else
            self:createCsbNode("AquaQuest_respin_reels_3X7.csb")
        end
    end

    self.m_clipParent = self:findChild("Node_sp_reel")

    --respinBar
    self.m_respinbar = util_createView("CodeAquaQuestSrc.AquaQuestRespinBar",{machine = self.m_machine})
    self:findChild("Node_respinbar"):addChild(self.m_respinbar)

    self.m_collectGame = util_createView("CodeAquaQuestSrc.AquaQuestCollectGame",{machine = self.m_machine,parent = self})
    self:addChild(self.m_collectGame)
    self.m_collectGame:setVisible(false)
end

function AquaQuestRespinReelView:onEnter()
    AquaQuestRespinReelView.super.onEnter(self)
    self.m_respinbar:runCsbAction("start")
end

function AquaQuestRespinReelView:createRespinView()
    self.m_isShowCollectGame = false
    local spinResult = self.m_machine.m_runSpinResultData
    local rsExtraData = spinResult.p_rsExtraData
    if rsExtraData.respinAllConfig then
        local respinInfoList = self:reateRespinNodeInfo(rsExtraData.respinAllConfig)
        for index = 1,#respinInfoList do
            local respinNodeInfo = respinInfoList[index]
            local respinView = util_createView(self.m_machine:getRespinView(), self.m_machine:getRespinNode())
            respinView:setMachine(self.m_machine,self,index)
            respinView:setCreateAndPushSymbolFun(self.getSlotNodeWithPosAndType,self.pushSlotNodeToPoolBySymobolType)
            self.m_clipParent:addChild(respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)


            respinView:setEndSymbolType(self.m_endTypes, self.m_randomTypes)
            respinView:initRespinSize(self.m_machine.m_SlotNodeW, self.m_machine.m_SlotNodeH, self.m_machine.m_fReelWidth, self.m_machine.m_fReelHeigth)

            respinView:initRespinElement(respinNodeInfo,self.m_iReelRowNum,rsExtraData.reelColumns,function()

            end)

            self.m_respinViewList[#self.m_respinViewList + 1] = respinView
        end
    else
        util_printLog("respin数据错误,请检查数据",true)
    end
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function AquaQuestRespinReelView:reateRespinNodeInfo(respinConfig)
    local respinNodeInfo = {}

    local reelParent = self:findChild("Node_qipan")
    local parentScale = reelParent:getScale()

    for index = 1,#respinConfig do
        local data = respinConfig[index]
        local reels = data.reels
        local infoData = {}
        for iCol = 1, self.m_iReelColumnNum do
            local rowCount = self.m_iReelRowNum
            for iRow = rowCount, 1, -1 do
                --信号类型
                local symbolType = self:getMatrixPosSymbolType(reels,iRow, iCol)
    
                --层级
                local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
                --tag值
                local tag = self.m_machine:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
                --二维坐标
                local arrayPos = {iX = iRow, iY = iCol}
    
                --世界坐标
                local pos, reelHeight, reelWidth = self:getRespinReelPos(iCol,index)
                pos.x = pos.x + reelWidth / 2 * self.m_machine.m_machineRootScale * parentScale
                local slotNodeH = self.m_machine.m_SlotNodeH
                pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machine.m_machineRootScale * parentScale
    
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
                infoData[#infoData + 1] = symbolNodeInfo
            end
        end
        respinNodeInfo[#respinNodeInfo + 1] = infoData
    end

    
    return respinNodeInfo
end

function AquaQuestRespinReelView:getMatrixPosSymbolType(reels,iRow, iCol)
    local rowCount = #reels
    for rowIndex = 1, rowCount do
        local rowDatas = reels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end

function AquaQuestRespinReelView:getRespinReelPos(col,reelIndex)
    local reelNode
    if self.m_isDouble then
        reelNode = self:findChild("sp_reel_"..reelIndex.."_"..(col - 1))
    else
        reelNode = self:findChild("sp_reel_" .. (col - 1))
    end

    if reelNode then
        local posX = reelNode:getPositionX()
        local posY = reelNode:getPositionY()
        local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
        local reelHeight = reelNode:getContentSize().height
        local reelWidth = reelNode:getContentSize().width

        return worldPos, reelHeight, reelWidth
    else
        return cc.p(0,0),self.m_machine.m_SlotNodeH * self.m_iReelRowNum,self.m_machine.m_SlotNodeW * self.m_iReelColumnNum
    end
    
    
end

--[[
    刷新respin次数
]]
function AquaQuestRespinReelView:updateRespinCount(count)
    self.m_respinbar:updateCurRespinCount(count)
end

--[[
    隐藏respin次数条
]]
function AquaQuestRespinReelView:hideRespinBar()
    self.m_respinbar:runCsbAction("over",false,function()
        self.m_respinbar:setVisible(false)
    end)
end

--[[
    开始滚动
]]
function AquaQuestRespinReelView:startMove()
    if self.m_isRunning then
        return
    end
    self.m_isRunning = true

    --落地音效
    self.m_symbolDownSounds = {}
    
    for index = 1,#self.m_respinViewList do
        self.m_respinViewList[index]:resetDataBeforeMove()
    end

    for index = 1,#self.m_respinViewList do
        local respinView = self.m_respinViewList[index]
        
        respinView:startMove()
    end
end

function AquaQuestRespinReelView:stopRespinRun()
    local spinResult = self.m_machine.m_runSpinResultData
    local rsExtraData = spinResult.p_rsExtraData
    if rsExtraData.respinAllConfig then
        for index = 1,#rsExtraData.respinAllConfig do
            local data = rsExtraData.respinAllConfig[index]
            local storedNodeInfo = self:getRespinSpinData(data)
            local unStoredReels = self:getRespinReelsButStored(storedNodeInfo,data)
            local respinView = self.m_respinViewList[index]
            respinView:setRunEndInfo(storedNodeInfo, unStoredReels)
        end
    else
        util_printLog("respin数据错误,请检查数据",true)
    end
    
end

function AquaQuestRespinReelView:getRespinSpinData(data)
    local storedIcons = data.storedIcons
    local reels = data.reels
    local storedInfo = {}
    for index = 1, #storedIcons do
        local posIndex = storedIcons[index]
        local posData = self:getRowAndColByPos(posIndex)
        local iCol,iRow = posData.iY,posData.iX

        local type = self:getMatrixPosSymbolType(reels,iRow, iCol)
        local pos = {iX = iRow, iY = iCol, type = type}
        storedInfo[#storedInfo + 1] = pos
    end
    return storedInfo
end

function AquaQuestRespinReelView:getRespinReelsButStored(storedInfo,data)
    local storedIcons = data.storedIcons
    local reels = data.reels
    local reelData = {}
    function getIsInStore(iRow, iCol)
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
            local type = self:getMatrixPosSymbolType(reels,iRow, iCol)
            if getIsInStore(iRow, iCol) == false then
                local pos = {iX = iRow, iY = iCol, type = type}
                reelData[#reelData + 1] = pos
            end
        end
    end
    return reelData
end

function AquaQuestRespinReelView:getRowAndColByPos(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum

    local rowIndex = self.m_iReelRowNum - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex, iY = colIndex}
end

--[[
    respin停轮
]]
function AquaQuestRespinReelView:reSpinReelDown()
    local isAllDown = true
    for index = 1,#self.m_respinViewList do
        local respinView = self.m_respinViewList[index]
        if not respinView.m_isReelDown then
            isAllDown = false
            break
        end
    end

    if isAllDown then

        self.m_isRunning = false
        self.m_machine:reSpinReelDown()
    end
end

--[[
    变更点击状态
]]
function AquaQuestRespinReelView:changeTouchStatus(status)
    for index = 1,#self.m_respinViewList do
        local respinView = self.m_respinViewList[index]
        respinView:changeTouchStatus(status)
    end
end

--[[
    获取repsin状态
]]
function AquaQuestRespinReelView:getouchStatus()
    local respinView = self.m_respinViewList[1]
    return respinView:getouchStatus()
end

--- respin 快停
function AquaQuestRespinReelView:quicklyStop()
    for index = 1,#self.m_respinViewList do
        local respinView = self.m_respinViewList[index]
        respinView:quicklyStop()
    end
end

--移除所有repsin节点
function AquaQuestRespinReelView:removeRespinNode()
    -- for index = 1,#self.m_respinViewList do
    --     local respinView = self.m_respinViewList[index]
    --     respinView:removeFromParent()
    -- end
    -- self.m_respinViewList = {}
end

function AquaQuestRespinReelView:getPosReelIdx(iRow, iCol)
    local index = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + (iCol - 1)
    return index
end

---
-- 根据pos位置 获取 对应 行列信息
--@return {iX,iY}
function AquaQuestRespinReelView:getRowAndColByPos(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum

    local rowIndex = self.m_iReelRowNum - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex, iY = colIndex}
end

--[[
    大信号合图
]]
function AquaQuestRespinReelView:changeToBigSymbol(func)
    local spinResult = self.m_machine.m_runSpinResultData
    local rsExtraData = spinResult.p_rsExtraData
    local delayTime = 0
    local isSwitch = false
    if rsExtraData.respinAllConfig then
        --全屏合图
        local isFullSymbol,isNormalSymbol = false,false
        for index = 1,#rsExtraData.respinAllConfig do
            --获取合图数据
            local shapes = rsExtraData.respinAllConfig[index].shapes
            local respinView = self.m_respinViewList[index]
            for iShape = 1,#shapes do
                local shapeData = shapes[iShape]
                if shapeData.width == self.m_iReelColumnNum and shapeData.height == self.m_iReelRowNum then
                    isFullSymbol = true
                end

                if shapeData.width == 1 then
                    isNormalSymbol = true
                end
                --合图表现统一放到respinView里
                local aniTime,runSwitch = respinView:changeToBigSymbol(shapes[iShape])
                if not isSwitch then
                    isSwitch = runSwitch
                end
                if aniTime > delayTime then
                    delayTime = aniTime
                end
            end
        end

        if isSwitch then
            local randIndex = math.random(1,100)
            if randIndex <= 30 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_change_big_symbol_"..self.m_soundIndex])
                self.m_soundIndex  = self.m_soundIndex + 1
                if self.m_soundIndex > 2 then
                    self.m_soundIndex = 1
                end
            end

            if isFullSymbol then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_change_full_symbol"])
            elseif isNormalSymbol then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_change_normal_symbol"])
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_change_big_symbol"])
            end
        end

        self.m_machine:delayCallBack(delayTime,function()
            --合图结束后,会有因为出现新的合图而失效的本地数据,需要进行检测移除失效数据
            for index = 1,#rsExtraData.respinAllConfig do
                local shapes = rsExtraData.respinAllConfig[index].shapes
                local respinView = self.m_respinViewList[index]
                respinView:checkBigInfos(shapes)
            end
            if type(func) == "function" then
                func()
            end
        end)
    else
        if type(func) == "function" then
            func()
        end
    end
end

--[[
    结算触发动画
]]
function AquaQuestRespinReelView:runEndTriggerAni(func)
    local list = self:getCleanList()
    --只有一个不需要播触发
    if #list == 1 then
        if type(func) == "function" then
            func()
        end
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_bonus_end_trigger"])

    local delayTime = 0
    for index = 1,#self.m_respinViewList do
        local respinView = self.m_respinViewList[index]
        local aniTime = respinView:runEndTriggerAni()
        if aniTime > delayTime then
            delayTime = aniTime
        end
    end

    self.m_machine:delayCallBack(delayTime,func)
end

--[[
    获取结算列表
]]
function AquaQuestRespinReelView:getCleanList()
    local spinResult = self.m_machine.m_runSpinResultData
    local rsExtraData = spinResult.p_rsExtraData
    if rsExtraData.respinAllConfig then
        local respinAllConfig = rsExtraData.respinAllConfig
        local cleanList = {}
        for index = 1,#respinAllConfig do
            local data = respinAllConfig[index]
            local respinView = self.m_respinViewList[index]
            local list = respinView:getAllCleaningNode(data)
            for key,info in ipairs(list) do
                cleanList[#cleanList + 1] = info
            end

        end

        --排序规则 面积 > respin machine索引 > 列 > 行
        local sortFunc = function(a,b)
            local pos1 = a.posIndex or 0
            local pos2 = b.posIndex or 0
    
            local posData1 = self:getRowAndColByPos(pos1) 
            local posData2 = self:getRowAndColByPos(pos2)
            local iCol1,iRow1= posData1.iY,posData1.iX
            local iCol2,iRow2= posData2.iY,posData2.iX

            local shapeData1 = a.shapeData
            local shapeData2 = b.shapeData

            local area1 = shapeData1.width * shapeData1.height
            local area2 = shapeData2.width * shapeData2.height

            local machineIndex1 = a.machineIndex
            local machineIndex2 = b.machineIndex

            if area1 == area2 then
                if machineIndex1 == machineIndex2 then
                    return iCol1 < iCol2 or (iCol1 == iCol2 and iRow1 > iRow2)
                else
                    return machineIndex1 < machineIndex2
                end
                
            else
                return area1 < area2
            end
        end
    
        util_bubbleSort(cleanList,sortFunc)

        return cleanList
    else
        
        util_printLog("respin数据错误,请检查数据",true)
        return {}
    end
end

--[[
    收集下一个bonus上的金币
]]
function AquaQuestRespinReelView:collectNextSymbolCoins(list,index,func)
    if index > #list then
        if type(func) == "function" then
            func()
        end
        return
    end

    local data = list[index]
    local respinNode = data.respinNode
    local lineData = data.lineData
    local shapeData = data.shapeData
    local winCoins = lineData.amount

    self.m_winCoins  = self.m_winCoins + winCoins

    if not tolua.isnull(respinNode) then
        local symbolNode = respinNode:getLockSymbolNode()
        if not tolua.isnull(symbolNode) then
            if shapeData.width == 1 then
                if shapeData.height == 1 then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_bonus_win_coins_feed_back"])
                else
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_small_bonus_win_coins_feed_back"])
                end
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_big_bonus_win_coins_feed_back"])
            end
            
            local aniName = "jiesuan"..shapeData.height.."_"..shapeData.width
            local ani1,idleName = self:getCleanAniName(shapeData.width,shapeData.height)
            symbolNode:runAnim(aniName,false,function()
                symbolNode:runAnim("idleName",true)
                
            end)
            self.m_machine:playCoinWinEffectUI(winCoins,self.m_winCoins)

            self.m_machine:delayCallBack(0.4,function()
                self:collectNextSymbolCoins(list,index + 1,func)
            end)
        else
            self:collectNextSymbolCoins(list,index + 1,func)
        end
    else
        self:collectNextSymbolCoins(list,index + 1,func)
    end
end

--[[
    变更信号的金币显示
]]
function AquaQuestRespinReelView:changeSymbolToCoins(func)
    local cleanList = self:getCleanList()

    --结算是要先显示bonus上的钱再逐个收集
    self:changeNextSymbolCoins(cleanList,1,function()
        self:collectNextSymbolCoins(cleanList,1,function()
            self.m_machine:delayCallBack(0.5,function()
                if type(func) == "function" then
                    func()
                end
            end)
        end)
    end)
end

--[[
    变更下一个信号
]]
function AquaQuestRespinReelView:changeNextSymbolCoins(list,index,func)
    if index > #list then
        if type(func) == "function" then
            func()
        end
        return
    end

    local data = list[index]
    local respinNode = data.respinNode
    local lineData = data.lineData
    local shapeData = data.shapeData

    local aniName,idleName = self:getCleanAniName(shapeData.width,shapeData.height)

    if not tolua.isnull(respinNode) then
        local symbolNode = respinNode:getLockSymbolNode()
        if not tolua.isnull(symbolNode) then
            --2x2以上的图标要进行收集玩法
            if lineData.num > 1 then
                
                if self.m_isShowCollectGame then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_big_symbol_trigger_again"])
                else
                    self.m_machine:clearCurMusicBg()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_big_symbol_trigger"])
                end
                
                symbolNode:runAnim(aniName,false,function()
                    symbolNode:runAnim(idleName,true)
                    if not self.m_isShowCollectGame then
                        self.m_machine:resetMusicBg(true,"AquaQuestSounds/music_AquaQuest_collect_game.mp3")
                    end
                    self.m_isShowCollectGame = true
                    --收集玩法
                    self:showCollectGameView(symbolNode,lineData,function()
                        
                        self:changeNextSymbolCoins(list,index + 1,func)
                    end)
                    
                end)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_change_bonus_to_coins"])
                self:setCoinsShowOnSymbol(symbolNode,lineData.amount,shapeData,lineData)
                symbolNode:runAnim(aniName,false,function()
                    symbolNode:runAnim(idleName,true)
                    
                end)
                self.m_machine:delayCallBack(0.6,function()
                    self:changeNextSymbolCoins(list,index + 1,func)
                end)
            end
            
        else
            self:changeNextSymbolCoins(list,index + 1,func)
        end
    else
        self:changeNextSymbolCoins(list,index + 1,func)
    end
end

--[[
    显示收集游戏界面
]]
function AquaQuestRespinReelView:showCollectGameView(symbolNode,lineData,func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_change_scene_to_collect_game"])
    self:runCsbAction("actionframe_guochang1",false,function()
        self.m_collectGame:showTotalWin(lineData)
        
        self.m_collectGame:gameStart(lineData,function()
            -- self.m_machine:clearCurMusicBg()
            -- gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_change_scene_to_collect_game"])
            self.m_machine:changeGameBg("changeScene2")
            self:runCsbAction("actionframe_guochang2",false,function()
                
            end)

            self.m_machine:delayCallBack(130 / 60,function()
                
                self.m_collectGame:runTotalWinOverAni(function()
                    self.m_collectGame:flyTotalwinToBigSymbol(symbolNode,lineData,function()
                        
                        if type(func) == "function" then
                            func()
                        end
                    end)
                end)
            end)
            
        end)
    end)
    self.m_collectGame:setVisible(true)
    self.m_machine:changeGameBg("changeScene1")
    
end

--[[
    获取结算时间线名称
]]
function AquaQuestRespinReelView:getCleanAniName(width,height)
    if width == 1 then
        local aniName = "jiesuan"..height
        local idleName = "idleframe_jiesuan_"..height.."_"..width
        return aniName,idleName
    end

    local aniName = "actionframe"..height.."_"..width
    local idleName = "idleframe"..height.."_"..width

    return aniName,idleName
end

--[[
    设置金币显示
]]
function AquaQuestRespinReelView:setCoinsShowOnSymbol(symbolNode,coins,shapeData,lineData)
    if tolua.isnull(symbolNode) then
        return
    end

    local width = shapeData.width
    local height = shapeData.height

    local csbNode,csbName,bindNode = nil,self:getBindNodeInfo(shapeData)

    local aniNode = symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine and not tolua.isnull(spine.m_bindCsbNode) then
        if spine.m_bindNode and spine.m_bindNode == bindNode then
            csbNode = spine.m_bindCsbNode
        end
    end

    if not csbNode then
        --清理绑定节点
        util_spineClearBindNode(spine)
        csbNode = util_createAnimation(csbName)
        util_spinePushBindNode(spine,bindNode,csbNode)
        -- spine:addChild(csbNode)
        spine.m_bindCsbNode = csbNode
        spine.m_bindNode = bindNode
    end

    local Node_coins = csbNode:findChild("Node_coins")
    if not tolua.isnull(Node_coins) then
        Node_coins:setVisible(true)
    end

    local Node_wenben = csbNode:findChild("Node_wenben")
    if not tolua.isnull(Node_wenben) then
        Node_wenben:setVisible(false)
    end

    local m_lb_coins = csbNode:findChild("m_lb_coins")
    local m_lb_num = csbNode:findChild("m_lb_num")

    if not tolua.isnull(m_lb_coins) then
        m_lb_coins:setString(util_formatCoins(coins,3))

        if bindNode == "guadian" then
            local info = {label = m_lb_coins, sx = 1, sy = 1}
            self:updateLabelSize(info, 200)
        end
    end

    if not tolua.isnull(m_lb_num) and lineData then
        m_lb_num:setString(lineData.num)
    end

    return csbNode
end

--[[
    获取绑定节点信息
    -- gd挂Socre_AquaQuest_Bonus_2X1_coins.csb
    -- gd1挂Socre_AquaQuest_Bonus_2X2_coins.csb
    -- gd2挂Socre_AquaQuest_Bonus_2X3_coins.csb
    -- gd3挂Socre_AquaQuest_Bonus_2X4_coins.csb
    -- gd4挂Socre_AquaQuest_Bonus_2X5_coins.csb
    -- gd5挂Socre_AquaQuest_Bonus_2X6_coins.csb
    -- gd6挂Socre_AquaQuest_Bonus_2X7_coins.csb
    -- gd7挂Socre_AquaQuest_Bonus_3X2_coins.csb
    -- gd8挂Socre_AquaQuest_Bonus_3X3_coins.csb
    -- gd9挂Socre_AquaQuest_Bonus_3X4_coins.csb
    -- gd10挂Socre_AquaQuest_Bonus_3X5_coins.csb，
    -- gd11挂Socre_AquaQuest_Bonus_3X6_coins.csb，
    -- gd12挂Socre_AquaQuest_Bonus_3X7_coins.csb
]]
function AquaQuestRespinReelView:getBindNodeInfo(shapeData)
    local width = shapeData.width
    local height = shapeData.height

    local csbName,bindNode

    if width == 1 then
        csbName = "Socre_AquaQuest_Bonus_2X1_coins.csb"
        bindNode = "guadian"
    elseif height == 2 and width == 2 then
        csbName = "Socre_AquaQuest_Bonus_2X2_coins.csb"
        bindNode = "gd1"
    elseif height == 2 and width == 3 then
        csbName = "Socre_AquaQuest_Bonus_2X3_coins.csb"
        bindNode = "gd2"
    elseif height == 2 and width == 4 then
        csbName = "Socre_AquaQuest_Bonus_2X4_coins.csb"
        bindNode = "gd3"
    elseif height == 2 and width == 5 then
        csbName = "Socre_AquaQuest_Bonus_2X5_coins.csb"
        bindNode = "gd4"
    elseif height == 2 and width == 6 then
        csbName = "Socre_AquaQuest_Bonus_2X6_coins.csb"
        bindNode = "gd5"
    elseif height == 2 and width == 7 then
        csbName = "Socre_AquaQuest_Bonus_2X7_coins.csb"
        bindNode = "gd6"
    elseif height == 3 and width == 2 then
        csbName = "Socre_AquaQuest_Bonus_3X2_coins.csb"
        bindNode = "gd7"
    elseif height == 3 and width == 3 then
        csbName = "Socre_AquaQuest_Bonus_3X3_coins.csb"
        bindNode = "gd8"
    elseif height == 3 and width == 4 then
        csbName = "Socre_AquaQuest_Bonus_3X4_coins.csb"
        bindNode = "gd9"
    elseif height == 3 and width == 5 then
        csbName = "Socre_AquaQuest_Bonus_3X5_coins.csb"
        bindNode = "gd10"
    elseif height == 3 and width == 6 then
        csbName = "Socre_AquaQuest_Bonus_3X6_coins.csb"
        bindNode = "gd11"
    elseif height == 3 and width == 7 then
        csbName = "Socre_AquaQuest_Bonus_3X7_coins.csb"
        bindNode = "gd12"
    end

    return csbName,bindNode
end

--[[
    移除绑定节点
]]
function AquaQuestRespinReelView:removeBindNodeOnSymbol(symbolNode)
    local aniNode = symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine and not tolua.isnull(spine.m_bindCsbNode) then
        --清理绑定节点
        util_spineClearBindNode(spine)
        spine.m_bindCsbNode = nil
        spine.m_bindNode = nil
    end
end

--[[
    获取第一列滚轮裁切层
]]
function AquaQuestRespinReelView:getFirstReelNode()
    if self.m_isDouble then
        return self:findChild("sp_reel_1_0")
    else
        return self:findChild("sp_reel_0")
    end
    
end

--[[
    检测播放图标落地音效
]]
function AquaQuestRespinReelView:checkPlaySymbolDownSound(symbolType,colIndex,symbolNode)
    if self.m_symbolDownSounds[colIndex] then
        return
    end
    
    if not self.m_symbolDownSounds then
        self.m_symbolDownSounds = {}
    end

    if not self.m_symbolDownSounds[colIndex] then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_bonus_down"])
    end

    self.m_symbolDownSounds[colIndex] = true

    --快停
    if self.m_respinViewList[1]:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_symbolDownSounds[iCol] = true
        end
    end

end

return AquaQuestRespinReelView