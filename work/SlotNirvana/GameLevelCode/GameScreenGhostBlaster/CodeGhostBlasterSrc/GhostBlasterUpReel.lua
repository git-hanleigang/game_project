---
--xcyy
--2018年5月23日
--GhostBlasterUpReel.lua
local PublicConfig = require "GhostBlasterPublicConfig"
local GhostBlasterUpReel = class("GhostBlasterUpReel",util_require("Levels.BaseLevelDialog"))

local ROW_NUM   =   3
local COL_NUM   =   5

GhostBlasterUpReel.SYMBOL_GHOST_1    =   11  --2x3小鬼
GhostBlasterUpReel.SYMBOL_GHOST_2    =   12  --2x2小鬼
GhostBlasterUpReel.SYMBOL_GHOST_3    =   13  --1x1小鬼
GhostBlasterUpReel.SYMBOL_GHOST_4    =   14  --金币箱
GhostBlasterUpReel.SYMBOL_EMPTY    =   100   --空信号

function GhostBlasterUpReel:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("GhostBlaster_UpperReels.csb")

    self.m_curGhostID = util_getCurrnetTime()

    --动画池
    self.m_ghostPool = {}

    --变成金币的小块
    self.m_rewardGhost = {}

    self.m_curTotalWin = 0

    self.m_isNeedDownNewGhost = false

    --裁切层
    self.m_clipNode = self:findChild("clipNode")

    --裁切层大小
    self.m_clipSize = self.m_clipNode:getContentSize()
    self.m_slotWidth = self.m_clipSize.width / COL_NUM
    self.m_slotHeight = self.m_clipSize.height / ROW_NUM

    self.m_symbolNodes = {}
end

--[[
    刷新当前赢钱
]]
function GhostBlasterUpReel:resetWinCoins()
    self.m_curTotalWin = 0
end

--[[
    刷新界面
]]
function GhostBlasterUpReel:refreshView(infoData)
    self.m_infoData = infoData
    local reels = infoData.upperReels
    local hpData = infoData.upperTimes

    self:resetWinCoins()
    --初始化轮盘
    self:initGhostShow(reels,hpData)
end

--[[
    获取当前血量
]]
function GhostBlasterUpReel:getCurHp(colIndex,rowIndex)
    local hpData = self.m_infoData.upperTimes
    return hpData[rowIndex][colIndex]
end

--[[
    检测信号值是否相同
]]
function GhostBlasterUpReel:checkIsSameSymbol(reels,colIndex,rowIndex,colCount,rowCount,symbolType)
    local maxCol = colIndex + colCount - 1
    local minRow = rowIndex - rowCount + 1
    if maxCol > COL_NUM then
        maxCol = COL_NUM
    end

    if minRow < 1 then
        minRow = 1
    end

    for iCol = colIndex,maxCol do
        for iRow = rowIndex,minRow,-1 do
            if reels[rowIndex][colIndex] ~= symbolType then
                return false
            end
        end
    end

    return true
end

--[[
    检测当前显示是否与最终结果一致,如果不一致,则强制刷新
]]
function GhostBlasterUpReel:checkIsReelSame(infoData)
    local isSame = true
    local reels = infoData.upperReels

    --先检测轮盘数值是否一致
    for iCol = 1,COL_NUM do
        for iRow = 1,ROW_NUM do
            if reels[iRow][iCol] ~= self.m_infoData.upperReels[iRow][iCol] then
                isSame = false
                break
            end
        end
        if not isSame then
            break
        end
    end

    --检测轮盘小块是否一致
    if isSame then
        for index = 1,#self.m_symbolNodes do
            local ghostAni = self.m_symbolNodes[index]
            if not ghostAni.m_isDefeat then
                local posData = ghostAni.m_posData
                local ghost_col = ghostAni.m_colIndex
                local ghost_row = ghostAni.m_rowIndex
                if not self:checkIsSameSymbol(reels,ghost_col,ghost_row,posData.colCount,posData.rowCount,ghostAni.m_symbolType) then
                    isSame = false
                    break
                end
            end
        end
    end

    if not isSame then
        -- util_printLog("GhostBlaster_log 客户端结果与服务器结果不一致,请检查数据:",true)
        if DEBUG == 2 and device.platform == "mac" and globalData.slotRunData.severGameJsonData then
            util_printLog(globalData.slotRunData.severGameJsonData)
        else
            util_printLongMsgData(globalData.slotRunData.severGameJsonData)
        end
        
        self:refreshView(infoData)

        return
    end
    self.m_infoData = infoData

    local upperTimes = infoData.upperTimes
    
    --检测血量是否一致
    for index = 1,#self.m_symbolNodes do
        local ghostAni = self.m_symbolNodes[index]
        if not ghostAni.m_isDefeat then
            local posData = ghostAni.m_posData
            local ghost_col = ghostAni.m_colIndex
            local ghost_row = ghostAni.m_rowIndex

            --血量不一致,刷新血量
            if ghostAni.m_hp ~= upperTimes[ghost_row][ghost_col] then
                self:initHpShow(ghostAni,upperTimes[ghost_row][ghost_col])
            end

            --获取小块倍数
            local upperMulti = self.m_infoData.upperMulti
            local multi = upperMulti[ghost_row][ghost_col]
            self:setCoinsShow(ghostAni,multi)
        end
    end
end

--[[
    从池子里获取一个动画
]]
function GhostBlasterUpReel:getGhostAniFormPool(symbolType,colIndex,rowIndex)
    local aniName = self.m_machine:getUpReelGostAniName(symbolType)

    local zOrder = (10 - symbolType % 10) * 10000 + colIndex * 100 + rowIndex

    local spine = util_spineCreate(aniName,true,true)
    self.m_clipNode:addChild(spine,zOrder)

    --血量显示角标
    local hpSign = util_createAnimation("Socre_GhostBlaster_jiaobiao.csb")
    spine:addChild(hpSign)
    local sizeData = self:getGhostSize(symbolType)
    hpSign:setPosition(cc.p(sizeData.size.width / 2 - 35,-sizeData.size.height / 2 + 32))
    spine.m_hpSign = hpSign
    self.m_curGhostID = self.m_curGhostID + 1
    spine.m_id = tostring(self.m_curGhostID)
    spine.m_isDefeat = false
    spine.m_isBox = (symbolType == self.SYMBOL_GHOST_4)
    spine.m_isCollect = false
    --结束特效
    local overAni = util_createAnimation("GhostBlaster_base_over_texiao.csb")
    util_spinePushBindNode(spine,"texiao",overAni)
    spine.m_overAni = overAni
    overAni:setVisible(false)
    for index = 1,4 do
        overAni:findChild("Node_texiao"..index):setVisible(index + 10 == symbolType)
    end

    --金币label
    local label = util_createAnimation("GhostBlaster_base_jiangli.csb")
    util_spinePushBindNode(spine,"wenzi",label)
    label:setVisible(false)
    -- spine:addChild(label)
    spine.m_lbl_csb = label
    return spine
end

--[[
    血量角标提层
]]
function GhostBlasterUpReel:changeHpSignToTop(ghostAni)
    local hpSign = ghostAni.m_hpSign
    local pos = util_convertToNodeSpace(hpSign,self.m_machine.m_effectNode)
    util_changeNodeParent(self.m_machine.m_effectNode,hpSign,1000)
    hpSign:setPosition(pos)
end

--[[
    血量角标放回原处
]]
function GhostBlasterUpReel:putHpSignBack(ghostAni)
    util_changeNodeParent(ghostAni,ghostAni.m_hpSign)
    local sizeData = self:getGhostSize(ghostAni.m_symbolType)
    ghostAni.m_hpSign:setPosition(cc.p(sizeData.size.width / 2 - 35,-sizeData.size.height / 2 + 32))
end

--[[
    清空盘面上的所有小块
]]
function GhostBlasterUpReel:clearAllGhostAni()
    for index,ghostAni in pairs(self.m_symbolNodes) do
        ghostAni:removeFromParent()
    end

    self.m_symbolNodes = {}
end

--[[
    清理单个小块
]]
function GhostBlasterUpReel:clearOneGhost(ghostAni)
    for index =#self.m_symbolNodes, 1,-1 do
        if ghostAni.m_id == self.m_symbolNodes[index].m_id then
            self.m_symbolNodes[index]:removeFromParent()
            table.remove(self.m_symbolNodes,index)
            return
        end
    end
end

--[[
    初始化轮盘显示
]]
function GhostBlasterUpReel:initGhostShow(reels,hpData)
    --先清空所有小块
    self:clearAllGhostAni()

    for iRow = ROW_NUM,1,-1 do
        for iCol = 1,COL_NUM do
            local symbolType = reels[iRow][iCol]
            local curHp = hpData[iRow][iCol]
            self:createGhostAni(symbolType,iCol,iRow,curHp)
        end
    end

    self:sortGhostAni()
end

--[[
    将小块按从下到上从左到右的顺序排序
]]
function GhostBlasterUpReel:sortGhostAni()
    util_bubbleSort(self.m_symbolNodes,function(a,b)
        local iCol1,iRow1 = a.m_colIndex,a.m_rowIndex
        local iCol2,iRow2 = b.m_colIndex,b.m_rowIndex

        return iRow1 > iRow2 or (iRow1 == iRow2 and iCol1 < iCol2)
    end)
end

--[[
    创建小块
]]
function GhostBlasterUpReel:createGhostAni(symbolType,iCol,iRow,curHp)
    --检测是否需要创建小块
    if not self:checkNeedAddGhost(iCol,iRow) or symbolType == self.SYMBOL_EMPTY then
        return
    end

    local ghostAni = self:getGhostAniFormPool(symbolType,iCol,iRow)
    
    self.m_symbolNodes[#self.m_symbolNodes + 1] = ghostAni

    --获取小块位置
    local posData = self:getGhostPosData(symbolType,iCol,iRow)
    ghostAni:setPosition(posData.pos)

    ghostAni.m_symbolType = symbolType
    ghostAni.m_colIndex = iCol
    ghostAni.m_rowIndex = iRow
    ghostAni.m_posData = posData       --位置信息

    self:initHpShow(ghostAni,curHp)

    --获取小块倍数
    local upperMulti = self.m_infoData.upperMulti
    local multi = upperMulti[iRow][iCol]
    self:setCoinsShow(ghostAni,multi)

    if symbolType == self.SYMBOL_GHOST_4 then
        ghostAni.m_lbl_csb:setVisible(true)
        ghostAni.m_lbl_csb:runCsbAction("start")
    end

    --检测是否播放濒死动画
    self:checkPlayNearDeathAni(ghostAni,curHp,true)
    

    return ghostAni
end

--[[
    检测播放濒死动画
]]
function GhostBlasterUpReel:checkPlayNearDeathAni(ghostAni,hp,isInit)
    if tolua.isnull(ghostAni) or ghostAni.m_isOver then
        return
    end

    local symbolType = ghostAni.m_symbolType
    if symbolType < self.SYMBOL_GHOST_4 then
        if hp <= 1 then
            util_spinePlay(ghostAni,"idleframe2_2",true)
        else
            util_spinePlay(ghostAni,"idleframe2",true)
        end
    else
        util_spinePlay(ghostAni,"idleframe2",true)
    end
end

--[[
    设置金币显示
]]
function GhostBlasterUpReel:setCoinsShow(ghostAni,multi)
    if not ghostAni then
        return
    end
    local csbLbl = ghostAni.m_lbl_csb

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local winCoins = multi * lineBet

    ghostAni.m_score = winCoins

    local symbolType = ghostAni.m_symbolType
    
    local isTriggerPicks = self.m_machine:checkTriggerPicks()
    if isTriggerPicks and ghostAni.m_posData.rowCount == 3 then
        csbLbl:findChild("Node_coins_big"):setVisible(false)
        csbLbl:findChild("Node_coins_small"):setVisible(false)
        csbLbl:findChild("Node_pick"):setVisible(true)
    else
        if symbolType == self.SYMBOL_GHOST_1 or symbolType == self.SYMBOL_GHOST_2 then
            csbLbl:findChild("Node_coins_big"):setVisible(true)
            csbLbl:findChild("Node_coins_small"):setVisible(false)
        else
            csbLbl:findChild("Node_coins_big"):setVisible(false)
            csbLbl:findChild("Node_coins_small"):setVisible(true)
        end
    
        csbLbl:findChild("Node_pick"):setVisible(false)
    end
    
    local str = util_formatCoins(winCoins,3)
    csbLbl:findChild("m_lb_coins_1"):setString(str)
    csbLbl:findChild("m_lb_coins_2"):setString(str)
end

--[[
    初始化血量
]]
function GhostBlasterUpReel:initHpShow(ghostAni,hp)
    if tolua.isnull(ghostAni) then
        return
    end
    local hpSign = ghostAni.m_hpSign
    self:setHp(ghostAni,hp)

    hpSign:findChild("m_lb_num"):setString(hp)

    if hp <= 1 then
        hpSign:runCsbAction("idleframe",true)
    else
        util_csbPauseForIndex(hpSign.m_csbAct,0)
    end
end

--[[
    设置血量
]]
function GhostBlasterUpReel:setHp(ghostAni,hp)
    ghostAni.m_hp = hp
    local ghost_col = ghostAni.m_colIndex
    local ghost_row = ghostAni.m_rowIndex
    local posData = ghostAni.m_posData

    --变更血量数据
    for iCol = ghost_col,ghost_col + posData.colCount - 1 do
        for iRow = ghost_row,ghost_row - posData.rowCount + 1, - 1 do
            if iRow < 1 then
                break;
            end
            self.m_infoData.upperTimes[iRow][iCol] = hp
        end
    end
end

--[[
    设置血量显示
]]
function GhostBlasterUpReel:setHpShow(ghostAni)
    if tolua.isnull(ghostAni) then
        return
    end
    local hpSign = ghostAni.m_hpSign
    
    local hp = ghostAni.m_hp

    local function checkPlayIdle()
        if hp <= 1 then
            hpSign:runCsbAction("idleframe",true)
        end
    end

    hpSign:runCsbAction("actionframe",false,function()
        checkPlayIdle()
    end)
    --第16帧切换数字
    self.m_machine:delayCallBack(16 / 60,function()
        if not tolua.isnull(hpSign) then
            hpSign:findChild("m_lb_num"):setString(hp)
        end
    end)
end

--[[
    隐藏hp显示
]]
function GhostBlasterUpReel:hideHpSign(ghostAni)
    if not ghostAni then
        return
    end
    ghostAni.m_hpSign:setVisible(false)
end

--[[
    检测是否需要创建小块
]]
function GhostBlasterUpReel:checkNeedAddGhost(iCol,iRow)
    for index ,ghostAni in ipairs(self.m_symbolNodes) do
        if ghostAni.m_symbolType ~= self.SYMBOL_EMPTY then
            local posData = ghostAni.m_posData

            --判断是否处于大信号范围内
            if iCol >= ghostAni.m_colIndex and 
            iCol <= ghostAni.m_colIndex - 1 + posData.colCount and 
            iRow >= ghostAni.m_rowIndex - posData.rowCount + 1 and 
            iRow <= ghostAni.m_rowIndex then
                return false
            end
        end
        
    end

    return true
end

--[[
    根据行列值获取小块
]]
function GhostBlasterUpReel:getGhostAniByColAndRow(colIndex,rowIndex)
    for index ,ghostAni in ipairs(self.m_symbolNodes) do
        local posData = ghostAni.m_posData

        --判断是否处于信号范围内
        if colIndex >= ghostAni.m_colIndex and
        colIndex <= ghostAni.m_colIndex - 1 + posData.colCount and 
        rowIndex >= ghostAni.m_rowIndex - posData.rowCount + 1 and 
        rowIndex <= ghostAni.m_rowIndex and not ghostAni.m_isDefeat then
            return ghostAni
        end
    end

    return nil
end

--[[
    根据行获取最下面一层的小块
]]
function GhostBlasterUpReel:getGhostAniByCol(colIndex)
    for index ,ghostAni in ipairs(self.m_symbolNodes) do
        local posData = ghostAni.m_posData

        --判断是否处于大信号范围内
        if colIndex >= ghostAni.m_colIndex and  
            colIndex <= ghostAni.m_colIndex - 1 + posData.colCount and
            ghostAni.m_symbolType ~= self.SYMBOL_EMPTY then
            return ghostAni
        end
    end

    return nil
end

--[[
    获取小块位置数据
]]
function GhostBlasterUpReel:getGhostPosData(symbolType,iCol,iRow)
    local sizeData = self:getGhostSize(symbolType)
    local posX = self.m_slotWidth * (iCol - 1) + sizeData.size.width / 2
    local posY = self.m_slotHeight * (3 - iRow) + sizeData.size.height / 2

    local data = {
        pos = cc.p(posX,posY),          --小块位置
        size = sizeData.size,           --小块大小
        colCount = sizeData.colCount,   --所占行数
        rowCount = sizeData.rowCount    --所占列数
    }

    return data
end

--[[
    获取小块大小
]]
function GhostBlasterUpReel:getGhostSize(symbolType)
    if symbolType == self.SYMBOL_GHOST_1 then
        return {size = CCSizeMake(self.m_slotWidth * 2,self.m_slotHeight * 3),colCount = 2,rowCount = 3}
    end

    if symbolType == self.SYMBOL_GHOST_2 then
        return {size = CCSizeMake(self.m_slotWidth * 2,self.m_slotHeight * 2),colCount = 2,rowCount = 2}
    end

    return {size = CCSizeMake(self.m_slotWidth,self.m_slotHeight), colCount = 1,rowCount = 1}
end

--[[
    小块打击动画
]]
function GhostBlasterUpReel:hitGhostAni(ghostAni,hp,count)
    if not tolua.isnull(ghostAni)  then
        self:setHpShow(ghostAni)
        gLobalSoundManager:playSound(PublicConfig.Music_Shoot_FeedBack)
        local aniName = "actionframe"
        if hp <= 1 and ghostAni.m_symbolType < self.SYMBOL_GHOST_4 then
            aniName = "actionframe2"
            if hp == 1 then
                if ghostAni.m_symbolType == self.SYMBOL_GHOST_1 then
                    gLobalSoundManager:playSound(PublicConfig.Music_Dizzy_Red)
                elseif ghostAni.m_symbolType == self.SYMBOL_GHOST_2 then
                    gLobalSoundManager:playSound(PublicConfig.Music_Dizzy_Blue)
                elseif ghostAni.m_symbolType == self.SYMBOL_GHOST_3 then
                    gLobalSoundManager:playSound(PublicConfig.Music_Dizzy_Geen)
                end
            end
        end

        util_spinePlay(ghostAni,aniName)
        util_spineEndCallFunc(ghostAni,aniName,function()
            --炮击结束
            if count <= 0 then
                --检测是否播放濒死动画
                self:checkPlayNearDeathAni(ghostAni,ghostAni.m_hp)
            end
        end)
    end
end

--[[
    设置击败状态
]]
function GhostBlasterUpReel:setGhostDefeatStatus(ghostAni)
    util_printLog("GhostBlaster_log 设置击败状态")
    ghostAni.m_isDefeat = true
end

--[[
    检测变更轮盘(小鬼血量为0时调用)
    @count: 剩余炮击次数
]]
function GhostBlasterUpReel:checkChangeReels(ghostAni,data,colIndex,count,clearCount,func)
    local symbolType = ghostAni.m_symbolType
    local ghost_col = ghostAni.m_colIndex
    local ghost_row = ghostAni.m_rowIndex
    local posData = ghostAni.m_posData  --位置信息    
    
    util_printLog("GhostBlaster_log 检测变更轮盘")

    local upperMulti = self.m_infoData.upperMulti
    local multi = upperMulti[ghost_row][ghost_col]
    --小鬼变金币
    local delayTime = self:changeGhostToCoins(ghostAni,multi)

    --切换小鬼信号值为空信号
    ghostAni.m_symbolType = self.SYMBOL_EMPTY
    

    --变更轮盘数据
    for iCol = ghost_col,ghost_col + posData.colCount - 1 do
        for iRow = ghost_row,ghost_row - posData.rowCount + 1, - 1 do
            if iRow < 1 then
                break;
            end
            self.m_infoData.upperReels[iRow][iCol] = self.SYMBOL_EMPTY
        end
    end

    --检测当前列是否还有可打击的小块
    local isNeedDownNewGhost = true
    for iRow = ROW_NUM,1,-1 do
        if self.m_infoData.upperReels[iRow][colIndex] ~= self.SYMBOL_EMPTY then
            isNeedDownNewGhost = false
            break
        end
    end

    --需要落下新的小鬼
    if isNeedDownNewGhost then
        self.m_isNeedDownNewGhost = true
        local nextReels = data.changeReels[clearCount + 1]
        local nextTimes = data.changeTimes[clearCount + 1]
        local nextMulti = data.changeMulti[clearCount + 1]

        util_printLog("GhostBlaster_log 变更轮盘时落下新的小鬼")

        self.m_machine:delayCallBack(delayTime,function()
            --检测是否需要落下新的小鬼
            self:checkDownNewGhost(ghostAni,nextReels,nextTimes,nextMulti,true,func)
        end)
        
    else
        if type(func) == "function" then
            func()
        end
    end
    
end

--[[
    检测是否需要落下新的图标
]]
function GhostBlasterUpReel:checkDownNewGhost(ghostAni,nextReels,nextTimes,nextMulti,isDelay,func)
    util_printLog("GhostBlaster_log 检测落下新的图标")
    local maxCol = COL_NUM
    local list = {}
    for iCol = 1,maxCol do
        local targetRow = ROW_NUM

        local isSameCol = true
        for iRow = ROW_NUM,1,-1 do
            if nextReels[iRow][iCol] ~= self.m_infoData.upperReels[iRow][iCol] then
                isSameCol = false
                break
            end
        end
        if not isSameCol then
            local rowIndex = ROW_NUM
            while rowIndex > 0 do
                local symbolType = self.m_infoData.upperReels[rowIndex][iCol]
                local rowCount = 1
                if symbolType ~= self.SYMBOL_EMPTY  then
                    local upGhost = self:getGhostAniByColAndRow(iCol,rowIndex)
                    for index = targetRow,1,-1 do
                        local nextSymbolType  = nextReels[index][iCol]
                        local times= nextTimes[index][iCol]
                        if symbolType == nextSymbolType and times == upGhost.m_hp and rowIndex < index then
                            rowCount = upGhost.m_posData.rowCount
                            local offset = index - upGhost.m_rowIndex
                            --塞入下落列表
                            local key = tostring(self:getGhostKey(upGhost.m_colIndex,upGhost.m_rowIndex + offset))
                            if not list[key] then
                                list[key] = {
                                    ghostAni = upGhost,
                                    offset = offset,
                                    tarRowIndex = upGhost.m_rowIndex + offset,
                                    posData = self:getGhostPosData(upGhost.m_symbolType,upGhost.m_colIndex,upGhost.m_rowIndex + offset)
                                }
                            end
                            targetRow = index - 1
                            break
                        end
                    end
                end

                rowIndex  = rowIndex - rowCount
            end
        end        
    end

    if next(list) then
        local str = ""
        for key,data in pairs(list) do
            local ghostAni = data.ghostAni
            ghostAni.m_rowIndex = data.tarRowIndex
            ghostAni.m_posData = data.posData
            str = str.."/"..key
        end
        util_printLog("GhostBlaster_log 落下新的图标:"..str)
    end

    --在顶部创建小块
    self:createGhostOnTop(nextReels,nextTimes,nextMulti,list)

    if self.m_machine.m_isCurClearGhost then
        --刷新当前轮盘数据
        self.m_infoData.upperReels = clone(nextReels)
        self.m_infoData.upperTimes = clone(nextTimes)
        self.m_infoData.upperMulti = clone(nextMulti)
    end
    

    local defeatList = self:getDefeatedGhost()
    if #defeatList > 0 then
        local delayTime = 0
        if isDelay and #defeatList == 1 and not defeatList[1].m_isBox then
            --播完start要额外展示0.6秒
            delayTime = 0.6
        end
        self.m_rewardGhost[#self.m_rewardGhost + 1] = defeatList
        self.m_machine:delayCallBack(delayTime,function()
            self:collectGhostCoins(defeatList,1,function()
                self.m_isNeedDownNewGhost = false
                --下移小块
                if next(list) then
                    self:moveDownGhost(list,function()
                        self.m_machine.m_isCurClearGhost = false
                        if type(func) == "function" then
                            func()
                        end
                    end)
                    
                else
                    if type(func) == "function" then
                        func()
                    end
                end
            end)
        end)
    else
        if type(func) == "function" then
            func()
        end
    end
    
end

--[[
    清理击败的小鬼
]]
function GhostBlasterUpReel:clearDefeatGhost()
    util_printLog("GhostBlaster_log 清理击败的小鬼")
    --清理击败的小鬼
    for k,list in pairs(self.m_rewardGhost) do
        for index,ghostAni in ipairs(list) do
            self:clearOneGhost(ghostAni)
        end
    end
end

--[[
    获取击败的小鬼
]]
function GhostBlasterUpReel:getDefeatedGhost()
    local list = {}
    for index = 1,#self.m_symbolNodes do
        local ghostAni = self.m_symbolNodes[index]
        if ghostAni.m_isDefeat and not ghostAni.m_isCollect then
            ghostAni.m_isCollect = true
            list[#list + 1] = ghostAni
        end
    end

    return list
end

--[[
    下移小鬼
]]
function GhostBlasterUpReel:moveDownGhost(list,func)
    gLobalSoundManager:playSound(PublicConfig.Music_Top_Symbol_Down)
    for key,data in pairs(list) do
        local offset = data.offset
        local ghostAni = data.ghostAni
        local startPos = cc.p(ghostAni:getPosition())
        local endPos = ghostAni.m_posData.pos
        local actionList = {
            cc.MoveTo:create(0.5,endPos),
            cc.CallFunc:create(function()
                if not tolua.isnull(ghostAni) then
                    if ghostAni.m_hp > 3 then
                        util_spinePlay(ghostAni,"buling")
                        util_spineEndCallFunc(ghostAni,"buling",function()
                            self:checkPlayNearDeathAni(ghostAni,ghostAni.m_hp,true)
                        end)
                    end
                    
                end
            end)
        }
        ghostAni:runAction(cc.Sequence:create(actionList))
    end

    self.m_machine:delayCallBack(1.5,func)
end

--[[
    在顶部创建新的小鬼
]]
function GhostBlasterUpReel:createGhostOnTop(nextReels,nextTimes,nextMulti,list)
    util_printLog("GhostBlaster_log 在顶部创建新的小块")
    --获取小块的列索引
    local function getSymbolColIndex(col,row)
        
        local symbolType = nextReels[row][col]
        if symbolType == self.SYMBOL_GHOST_1 or symbolType == self.SYMBOL_GHOST_2 then
            if col > 1 and nextReels[row][col] == nextReels[row][col - 1] then
                return col - 1
            end
        end

        return col
    end

    local function createNewGhost(symbolType,hp,col,row,offset)
        if symbolType ~= self.SYMBOL_EMPTY and self:checkNeedAddGhost(col,row) then
            local newGhost = self:getGhostAniFormPool(symbolType,col,row)

            self.m_symbolNodes[#self.m_symbolNodes + 1] = newGhost

            --获取小块位置
            local posData = self:getGhostPosData(symbolType,col,row)
            local pos = cc.p(posData.pos.x,self.m_slotHeight * (ROW_NUM + offset - 1) + posData.size.height / 2)
            newGhost:setPosition(pos)

            newGhost.m_symbolType = symbolType
            newGhost.m_colIndex = col
            newGhost.m_rowIndex = row
            newGhost.m_posData = posData       --位置信息

            self:initHpShow(newGhost,hp)
            local multi = nextMulti[row][col]
            self:setCoinsShow(newGhost,multi)

            if symbolType == self.SYMBOL_GHOST_4 then
                newGhost.m_lbl_csb:setVisible(true)
                newGhost.m_lbl_csb:runCsbAction("start")
            end

            self:checkPlayNearDeathAni(newGhost,hp,true)

            local key = tostring(self:getGhostKey(newGhost.m_colIndex,row))
            list[key] = {
                ghostAni = newGhost,
                offset = offset,
                tarRowIndex = row,
                posData = posData
            }
        end
    end

    --检测该列是否相等
    for iCol = 1,COL_NUM do
        local isSameCol = true
        for iRow = ROW_NUM,1,-1 do
            if nextReels[iRow][iCol] ~= self.m_infoData.upperReels[iRow][iCol] then
                isSameCol = false
                break
            end
        end

        if not isSameCol then
            local emptyCount = 0
            local startIndex = 0
            for iRow = ROW_NUM,1,-1 do
                --计算连续的空信号数量
                local symbolType = self.m_infoData.upperReels[iRow][iCol]
                if symbolType ~= self.SYMBOL_EMPTY and startIndex ~= 0 then
                    break
                end
                emptyCount  = emptyCount + 1
                if startIndex == 0 and symbolType == self.SYMBOL_EMPTY then
                    startIndex = iRow
                end
            end
            if emptyCount == 1 then
                local rowCount1 = self:getGhostRowCount(self.m_infoData.upperReels[1][iCol])
                if rowCount1 == 1 then 
                    --在顶部创建一个小块
                    local symbolType = nextReels[1][iCol]
                    local hp = nextTimes[1][iCol]
                    local colIndex = getSymbolColIndex(iCol,1)
                    createNewGhost(symbolType,hp,colIndex,1,1)
                elseif rowCount1 == 2 then
                    --如果落到最下面一层,需要创建新的小块
                    if self.m_infoData.upperReels[1][iCol] ==  nextReels[3][iCol] then
                        local symbolType = nextReels[1][iCol]
                        local hp = nextTimes[1][iCol]
                        local colIndex = getSymbolColIndex(iCol,1)
                        createNewGhost(symbolType,hp,colIndex,1,1)
                    end
                else
                    --整列大信号,不需要创建额外的小块
                end
            elseif emptyCount == 2 then
                local rowCount1 = self:getGhostRowCount(self.m_infoData.upperReels[1][iCol])
                local rowCount2 = self:getGhostRowCount(nextReels[1][iCol])
                if rowCount1 == 1 then 
                    if nextReels[2][iCol] == self.SYMBOL_EMPTY and rowCount2 > 1 then
                        --创建一个即可
                        local symbolType = nextReels[1][iCol]
                        local hp = nextTimes[1][iCol]
                        local colIndex = getSymbolColIndex(iCol,1)
                        createNewGhost(symbolType,hp,colIndex,1,1)
                    else
                        --必定会落到最下面,上面需创建新的小块,偏移量必定为2
                        for iCount = 1,2 do
                            local symbolType = nextReels[ROW_NUM - iCount][iCol]
                            local rowCount2 = self:getGhostRowCount(symbolType)
                            local hp = nextTimes[ROW_NUM - iCount][iCol]
                            local colIndex = getSymbolColIndex(iCol,ROW_NUM - iCount)
                            createNewGhost(symbolType,hp,colIndex,ROW_NUM - iCount,2)
                        end
                    end
                    
                elseif rowCount1 == 2 then --如果落到最下面一层,需要创建新的小块
                    if self.m_infoData.upperReels[1][iCol] ==  nextReels[3][iCol] then
                        local symbolType = nextReels[1][iCol]
                        local hp = nextTimes[1][iCol]
                        local colIndex = getSymbolColIndex(iCol,1)
                        createNewGhost(symbolType,hp,colIndex,1,2)
                    end
                else 
                    --整列大信号,不需要创建额外的小块
                end
            else    --需创建整列
                local tempCount = 0
                local tempIndex = 0
                for iRow = ROW_NUM,1,-1 do
                    --计算连续的空信号数量

                    local symbolType = nextReels[iRow][iCol]
                    
                    if symbolType ~= self.SYMBOL_EMPTY and tempIndex ~= 0 then
                        break
                    end
                    tempCount  = tempCount + 1
                    if tempIndex == 0 and symbolType == self.SYMBOL_EMPTY then
                        tempIndex = iRow
                    end
                end
                for iCount = ROW_NUM,1,-1 do
                    local symbolType = nextReels[iCount][iCol]
                    local hp = nextTimes[iCount][iCol]
                    local offset = 3
                    if tempCount == 1 and tempIndex == 3 then
                        offset = 2
                    elseif tempCount == 1 and tempIndex == 2 and iCount == 2 then
                        offset = 2
                    elseif tempCount == 2 and tempIndex == 1 then
                        offset = 1
                    end
                    local colIndex = getSymbolColIndex(iCol,iCount)
                    createNewGhost(symbolType,hp,colIndex,iCount,offset)
                end
            end
        end
    end


    self:sortGhostAni()

    return list
end

--[[
    小鬼变金币
]]
function GhostBlasterUpReel:changeGhostToCoins(ghostAni,multi)
    ghostAni.m_isOver = true
    util_spinePlay(ghostAni,"over")

    if ghostAni.m_symbolType == self.SYMBOL_GHOST_1 then
        self.m_machine:delayCallBack(18/30,function()
            gLobalSoundManager:playSound(PublicConfig.Music_Base_Box_Down)
        end)
        gLobalSoundManager:playSound(PublicConfig.Music_Die_Red)
    elseif ghostAni.m_symbolType == self.SYMBOL_GHOST_2 then
        gLobalSoundManager:playSound(PublicConfig.Music_Die_Blue)
    elseif ghostAni.m_symbolType == self.SYMBOL_GHOST_3 then
        gLobalSoundManager:playSound(PublicConfig.Music_Die_Green)
    end

    self:setCoinsShow(ghostAni,multi)

    util_spineFrameCallFunc(ghostAni,"over","texiao",function()
        gLobalSoundManager:playSound(PublicConfig.Music_Chang_To_Coins)
        ghostAni.m_overAni:setVisible(true)
        ghostAni.m_overAni:runCsbAction("over",false,function()
            ghostAni.m_overAni:setVisible(false)
        end)
    end,function()
        -- ghostAni:setVisible(false)
        ghostAni:setLocalZOrder(1)
    end)

    --掉金币的动效,层级要在bonus图标的下方
    self:dropCoinAni(ghostAni)

    local delayTime = 0

    if ghostAni.m_symbolType ~= self.SYMBOL_GHOST_4 then
        delayTime = 20 / 30
        if ghostAni.m_posData.rowCount == 3 then
            delayTime = 25 / 30
        end
        
        
        self.m_machine:delayCallBack(delayTime,function()
            
            ghostAni.m_lbl_csb:setVisible(true)
            ghostAni.m_lbl_csb:runCsbAction("start")
        end)
    end

    
    return delayTime + 20 / 60
end

--[[
    击败小鬼掉金币动效
]]
function GhostBlasterUpReel:dropCoinAni(ghostAni)
    if tolua.isnull(self.m_machine.m_curHitBonusSymbol) then
        return
    end

    local symbol = self.m_machine.m_curHitBonusSymbol
    local parent = self.m_machine.m_effectNode

    local spine = util_spineCreate("GhostBlaster_Jinbi",true,true)
    local zOrder = 50
    parent:addChild(spine,zOrder)
    local aniName = "actionframe3"
    if ghostAni.m_symbolType == self.SYMBOL_GHOST_1 then
        aniName = "actionframe"
    elseif ghostAni.m_symbolType == self.SYMBOL_GHOST_2 then
        aniName = "actionframe2"
    end
    local pos = util_convertToNodeSpace(ghostAni,parent)
    spine:setPosition(pos)
    util_spinePlay(spine,aniName)
    util_spineEndCallFunc(spine,aniName,function()
        self.m_machine:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
    end)
end

--[[
    累加totalWin
]]
function GhostBlasterUpReel:addTotalWin(winCoins)
    self.m_curTotalWin = self.m_curTotalWin + winCoins
end

--[[
    获取totalWin
]]
function GhostBlasterUpReel:getTotalWin()
    return self.m_curTotalWin
end

--[[
    收集击败的小鬼的金币
]]
function GhostBlasterUpReel:collectGhostCoins(defeatList,index,func)
    if index > #defeatList then
        if type(func) == "function" then
            func()
        end
        return
    end
    
    local ghostAni = defeatList[index]
    local endNode = self.m_machine.m_bottomUI.coinWinNode

    local delayTime = 0

    --只有击败2X3图标时才会触发pick玩法,此时图标必下落
    local isTriggerPicks = self.m_machine:checkTriggerPicks()
    local isPick = false
    if isTriggerPicks and ghostAni.m_posData.rowCount == 3 then
        endNode = self.m_machine.m_pickTip:findChild("zi")
        isPick = true
    else
        self:addTotalWin(ghostAni.m_score)
    end

    self:flyCoinsToTotalWin(ghostAni,endNode,isPick,function()
        if isTriggerPicks and ghostAni.m_posData.rowCount == 3 then
            
            self:collectGhostCoins(defeatList,index + 1,func)
        else
            self.m_machine:playCoinWinEffectUI()
            --刷新赢钱
            self.m_machine.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_curTotalWin))
    
            self:collectGhostCoins(defeatList,index + 1,func)
        end
        
    end)
end

--[[
    飞金币动画
]]
function GhostBlasterUpReel:flyCoinsToTotalWin(ghostAni,endNode,isPick,func)
    local effectNode = self.m_machine.m_effectNode
    local flyNode = util_createAnimation("GhostBlaster_base_jiangli.csb")
    effectNode:addChild(flyNode)

    local flyFunc = function()
        ghostAni.m_lbl_csb:setVisible(false)
        local winCoins = ghostAni.m_score

        local symbolType = ghostAni.m_symbolType
        if isPick then
            flyNode:findChild("Node_coins_big"):setVisible(false)
            flyNode:findChild("Node_coins_small"):setVisible(false)
            flyNode:findChild("Node_pick"):setVisible(true)
        else
            if ghostAni.m_posData.colCount > 1 then
                flyNode:findChild("Node_coins_big"):setVisible(true)
                flyNode:findChild("Node_coins_small"):setVisible(false)
            else
                flyNode:findChild("Node_coins_big"):setVisible(false)
                flyNode:findChild("Node_coins_small"):setVisible(true)
            end
        
            flyNode:findChild("Node_pick"):setVisible(false)
        end
        
        
        local str = util_formatCoins(winCoins,3)
        flyNode:findChild("m_lb_coins_1"):setString(str)
        flyNode:findChild("m_lb_coins_2"):setString(str)


        local startPos = util_convertToNodeSpace(ghostAni.m_lbl_csb,effectNode)
        local endPos = util_convertToNodeSpace(endNode,effectNode)

        flyNode:setPosition(startPos)

        local delayTime,flyTime = 40 / 60,20 / 60

        flyNode:runCsbAction("fly")
        local actionList = {
            cc.DelayTime:create(delayTime),
            cc.CallFunc:create(function()
                if isPick then
                    gLobalSoundManager:playSound(PublicConfig.Music_Reward_Text_Fly)
                else
                    gLobalSoundManager:playSound(PublicConfig.Music_Base_Collect_Bottom)
                end
            end),
            cc.EaseQuadraticActionIn:create(cc.MoveTo:create(flyTime,endPos)),
            cc.CallFunc:create(function()
                if not isPick then
                    if type(func) == "function" then
                        func()
                    end
                end
                
            end),
            cc.DelayTime:create(2 / 60),
            cc.RemoveSelf:create(true)
        }

        if isPick then
            self.m_machine:delayCallBack(50 / 60,function()
                self.m_machine:showPickTip()
                if type(func) == "function" then
                    func()
                end
            end)
        end

        flyNode:runAction(cc.Sequence:create(actionList))
    end
    
    -- if ghostAni.m_symbolType ~= self.SYMBOL_GHOST_4 then
    --     ghostAni.m_lbl_csb:runCsbAction("start",false,function()
    --         flyFunc()
    --     end)
    -- else
    --     flyFunc()
    -- end
    flyFunc()

    
end

--[[
    获取精灵键值
]]
function GhostBlasterUpReel:getGhostKey(colIndex,rowIndex)
    return colIndex * 1000 + rowIndex
end

--[[
    获取小块所占纵向格子数
]]
function GhostBlasterUpReel:getGhostRowCount(symbolType)
    if symbolType == self.SYMBOL_GHOST_1 then
        return 3
    elseif symbolType == self.SYMBOL_GHOST_2 then
        return 2
    end

    return 1
end

return GhostBlasterUpReel