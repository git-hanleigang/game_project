local ScratchWinnerShopListView = class("ScratchWinnerShopListView", util_require("Levels.BaseLevelDialog"))
local ScratchWinnerShopManager = require "CodeScratchWinnerSrc.ScratchWinnerShopManager"
local ScratchWinnerMusicConfig = require "CodeScratchWinnerSrc.ScratchWinnerMusicConfig"

ScratchWinnerShopListView.m_maxCol = 2   --每行的最大列数
ScratchWinnerShopListView.m_cellIntervalW = 40   --列表间隔 宽
ScratchWinnerShopListView.m_cellIntervalH = 10   --列表间隔 高


function ScratchWinnerShopListView:initUI(_machine)
    self:createCsbNode("ScratchWinner_shop.csb")
    self:createScrollView()
    self:initPlayBtn()

    self.m_cellList = {}
    self.m_cellPool = {}
    self.m_machine = _machine

    --数量变更
    gLobalNoticManager:addObserver(self,function(self,params)
        self:upDateButBtnState()
    end,"ScratchWinnerMachine_changeBuyCount")
    --bet数值切换
    gLobalNoticManager:addObserver(self,function(self,params)
        self:upDateButBtnState()
    end,ViewEventType.NOTIFY_BET_CHANGE)
    --请求了购买数据
    gLobalNoticManager:addObserver(self,function(self,params)
        self:setPlayBtnEnable(false)
    end,"ScratchWinnerMachine_readySendBuyData")
    --数据返回
    gLobalNoticManager:addObserver(self,function(self,params)
        if params.isClear then
            self:clearCardCount()
        end
    end,"ScratchWinnerMachine_resultCallFun")
end


--[[
    购买按钮相关
]]
function ScratchWinnerShopListView:initPlayBtn()
    self.m_playBtnCsb = util_createAnimation("ScratchWinner_btnPlay.csb")
    self:findChild("Node_btn"):addChild(self.m_playBtnCsb)
    self.m_btnPlay = self.m_playBtnCsb:findChild("btn_play")
    self:addClick(self.m_btnPlay)

    self.m_playBtnCsb:runCsbAction("idle", true)
end
function ScratchWinnerShopListView:setPlayBtnEnable(_enable)
    self.m_btnPlay:setEnabled(_enable)
    gLobalNoticManager:postNotification("ScratchWinnerMachine_spinBtn_ChangeEnable", {_enable})
end
function ScratchWinnerShopListView:upDateButBtnState()
    local buyList = self:getCurBuyList()
    -- 无法购买 就返回
    local buyState = ScratchWinnerShopManager:getInstance():checkBuyState(buyList, {skipCheckCoins=true})
    self:setPlayBtnEnable(buyState)
end

function ScratchWinnerShopListView:getCurBuyList()
    local buyList = {}
    for i,_cell in ipairs(self.m_cellList) do
        if _cell:isVisible() then
            local count = _cell.m_buyCount
            if count > 0 then
                buyList[_cell.m_cellData.name] = count
            end
        end
    end    

    return buyList
end
function ScratchWinnerShopListView:onBuyBtnClick()
    local buyList  = self:getCurBuyList()
    local buyState = ScratchWinnerShopManager:getInstance():checkBuyState_coins(buyList)
    -- 金币不足打开商店
    if not buyState then
        self.m_machine:operaUserOutCoins()
        return
    end

    gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_Click)
    local keyName   = string.format("Sound_SelectCard_%d", math.random(1, 2))
    local soundName =  ScratchWinnerMusicConfig[keyName]
    gLobalSoundManager:playSound(soundName)

    gLobalNoticManager:postNotification("ScratchWinnerMachine_readySendBuyData", {buyList})
    ScratchWinnerShopManager:getInstance():sendBuyData(buyList)
end

function ScratchWinnerShopListView:clickFunc(sender)
    local name = sender:getName()
    if "btn_play" == name then
        self:onBuyBtnClick()
    end
end

--[[
    游戏模式切换
]]
function ScratchWinnerShopListView:playShowAnim()
    for i,v in ipairs(self.m_cellList) do
        if v:isVisible() then
            v:playShowAnim()
        end
    end
end
function ScratchWinnerShopListView:playHideAnim()
    for i,v in ipairs(self.m_cellList) do
        if v:isVisible() then
            v:playHideAnim()
        end
    end
    return 24/60
end
--[[
    滑动列表相关
]]
function ScratchWinnerShopListView:setDataList(_dataList)
    for _cellIndex,_cellData in ipairs(_dataList) do
        -- 获取
        local cell = self:getCellByIndex(_cellIndex)
        local bNew = not cell
        if not cell then
            if #self.m_cellPool > 0 then
                cell = table.remove(self.m_cellPool, 1)
                cell:setVisible(true)
            else    
                cell = self:createOneCell(_cellIndex, _cellData)
                self.m_scrollview:addChild(cell)
            end
            
            table.insert(self.m_cellList, cell)
        end

        cell.m_cellIndex = _cellIndex
        --设置数据
        cell:setCellData(_cellData)
        --刷新展示
        cell:updateCellUi(_cellData)
        --等数据存在后添加事件监听
        if bNew then
            cell:addBaseCardObserver()
        end
    end
    if #_dataList < #self.m_cellList then
        for _cellIndex=#self.m_cellList,#_dataList+1,-1 do
            local cell = table.remove(self.m_cellList, _cellIndex)
            table.insert(cell, self.m_cellPool)
            cell:removeBaseCardObserver()
            cell:setVisible(false)
            cell:setCellData(nil)
        end
    end
    --刷新坐标和大小
    self:upDateCellPosition()
    --滑倒顶部
    self.m_scrollview:scrollToTop(0, true)
end
function ScratchWinnerShopListView:upDateCellPosition()
    if #self.m_cellList < 1 then
        return
    end
    --[[
        1 2
        3 4
        5 6
    ]]
    local maxCol  = self.m_maxCol
    local maxRow  = math.ceil(#self.m_cellList / maxCol)

    local firstCell = self.m_cellList[1]
    local ceelSize = firstCell:getCellSize()
    local viewSize  = self.m_scrollview:getContentSize()
    local innerSize = cc.size(viewSize.width, 0)
    innerSize.height = maxRow * ceelSize.height + (maxRow - 1) * self.m_cellIntervalH

    for _cellIndex,_cell in ipairs(self.m_cellList) do
        local pos = self:getOneCellPos(_cellIndex, ceelSize)
        _cell:setPosition(pos)
        _cell:setLocalZOrder(_cellIndex)
    end
    print( string.format("[ScratchWinnerShopListView:upDateCellPosition] innerSize=(%d, %d)",innerSize.width, innerSize.height) )
    self.m_scrollview:setInnerContainerSize(innerSize)
end
function ScratchWinnerShopListView:getOneCellPos(_cellIndex, _cellSize)
    local maxCol  = self.m_maxCol
    local maxRow  = math.ceil(#self.m_cellList / maxCol)

    local row = math.ceil(_cellIndex/maxCol)
    local col = (0==math.mod(_cellIndex, maxCol)) and maxCol or math.mod(_cellIndex, maxCol)
    local posX = (col-1) * (_cellSize.width+self.m_cellIntervalW) 
    local posY = ( (maxRow-row) * _cellSize.height) + (row-1) * self.m_cellIntervalH 
    local pos = cc.p(posX, posY)
    print("[ScratchWinnerShopListView:getOneCellPos] ",_cellIndex,pos.x, pos.y)
    return pos
end


function ScratchWinnerShopListView:createScrollView()
    if nil ~= self.m_scrollview then
        return
    end
    self.m_scrollview = ccui.ScrollView:create()
    self.m_scrollview:setDirection(ccui.ScrollViewDir.vertical)
    self.m_scrollview:setBounceEnabled(true)
    self.m_scrollview:setScrollBarEnabled(false)
    self:addChild(self.m_scrollview)

    local templateNode = self:findChild("ScrollView")
    local size = templateNode:getContentSize()
    self.m_scrollview:setContentSize(size)

    self.m_scrollview:onScroll(function(data)
        if  data.name == "CONTAINER_MOVED" then
            -- local percent = self.m_scrollview:getScrolledPercentVertical()
            -- print("[ScratchWinnerShopListView:createScrollView] ", percent)
        end
    end)

    local pos = cc.p(templateNode:getPosition())
    pos.x = pos.x - size.width/2
    pos.y = pos.y - size.height/2
    self.m_scrollview:setPosition(pos)
end

--[[
    卡片相关
]]
function ScratchWinnerShopListView:getCellByIndex(_index)
    local cell = self.m_cellList[_index]
    return cell
end
function ScratchWinnerShopListView:getCellByCellData(_cellData)
    for i,_cell in ipairs(self.m_cellList) do
        if nil ~= _cell.m_cellData then
            local bFind = true
            for kk,vv in pairs(_cellData) do
                if vv ~= _cell.m_cellData[kk] then
                    bFind = false
                    break
                end
            end
            if bFind then
                return _cell
            end
        end
    end
    return nil
end
function ScratchWinnerShopListView:createOneCell(_cellIndex, _cellData)
    local cardConfig = ScratchWinnerShopManager:getInstance():getCardConfig(_cellData.name)
    local codeName   = cardConfig.cardCellCode
    local csbName    = cardConfig.cardCellRes
    local cell = util_createView(codeName, csbName)
    cell:initMachine(self.m_machine)

    return cell
end


--[[
    出卡流程
]]
function ScratchWinnerShopListView:playExportAnim(_animIndex, _list, _fun)
    local cardList = _list[_animIndex]
    if not cardList then
        _fun()
        return
    elseif #cardList < 1 then
        self:playExportAnim(_animIndex + 1, _list, _fun)
        return
    end

    local cardData = cardList[1]
    local cell = self:getCellByCellData({name=cardData.name})
    cell:setVisible(false)
    -- 临时cell
    local tempCell = self:createOneCell(0, cell.m_cellData)
    tempCell:setCellData(cell.m_cellData)
    tempCell:updateCellUi()
    tempCell:changeAllBtnEnable(false)
    tempCell:upDateBuyCountLab(cell.m_buyCount)
    tempCell:setLockState(false)
    self:addChild(tempCell, 10)
    tempCell:setPosition(util_convertToNodeSpace(cell, self))
    tempCell:playExportAnim(_animIndex, cardList, 
        function()
            cell:setVisible(true)
            util_afterDrawCallBack(function()
                if tolua.isnull(tempCell) then
                    return
                end
                tempCell:setVisible(false)
            end)            
        end,
        function()
            local animTime = self.m_machine:changeBgShowState(false, true)
            self:playExportAnim(_animIndex + 1, _list, _fun)
            tempCell:runAction(cc.RemoveSelf:create())
        end
    )

    -- self:changeExportCellOrder(cell, true)
    -- cell:playExportAnim(_animIndex, cardList, function()
    --     self:changeExportCellOrder(cell, false)
    --     local animTime = self.m_machine:changeBgShowState(false, true)
    --     self:playExportAnim(_animIndex + 1, _list, _fun)
    -- end)
end
function ScratchWinnerShopListView:changeExportCellOrder(_cell, _bExport)
    local parent       = self.m_scrollview
    local parentExport = self

    local nextParent = _bExport and parentExport or parent
    
    if not _bExport then
        util_changeNodeParent(nextParent, _cell)
        local pos = self:getOneCellPos(_cell.m_cellIndex, _cell:getCellSize())

        local _isPortrait = globalData.slotRunData.isPortrait
        local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
        print("ScratchWinnerShopListView:changeExportCellOrder",_isPortrait)
        if _isPortrait == _isPortraitMachine then
            _cell:setPosition(pos)
        else
            _cell:setPosition(pos.y, pos.x)
        end
        
        _cell:addBaseCardObserver()
    else
        local pos = util_convertToNodeSpace(_cell, nextParent)
        util_changeNodeParent(nextParent, _cell)
        _cell:setPosition(pos)
        _cell:addBaseCardObserver()
    end
end

--[[
    第一次进入关卡初始化卡片数量
]]
function ScratchWinnerShopListView:firstEnterLevelUpDateCardCount(_cardCount)
    for i,_cell in ipairs(self.m_cellList) do
        if _cell:isVisible() then
            local name = _cell.m_cellData.name
            local cardData = ScratchWinnerShopManager:getInstance():getCardShopData(name)
            if nil ~= cardData then
                local cardCount = _cardCount
                if cardCount > 0 then
                    _cell.m_buyCount = 0
                    _cell:changeBuyCount(cardCount, false)
                end
            end
        end
    end
end
--[[
    断线重连刷新数量
]]
function ScratchWinnerShopListView:reconnectionUpDateCardCount()
    for i,_cell in ipairs(self.m_cellList) do
        if nil ~= _cell.m_cellData then
            local name = _cell.m_cellData.name
            local cardCount = ScratchWinnerShopManager:getInstance():getCardCount(name) 
            if cardCount > 0 then
                _cell.m_buyCount = 0
                _cell:changeBuyCount(cardCount, false)
            end
        end
    end
end
--[[
    清理背包重置卡片数量
]]
function ScratchWinnerShopListView:clearCardCount()
    for i,_cell in ipairs(self.m_cellList) do
        if _cell:isVisible() then
            _cell.m_buyCount = 0
            _cell:upDateBuyCountLab(_cell.m_buyCount)
        end
    end
end

return ScratchWinnerShopListView