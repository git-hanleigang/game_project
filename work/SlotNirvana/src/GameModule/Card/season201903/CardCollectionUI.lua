--[[
    以往赛季
]]
local CardCollectionUI = class("CardCollectionUI", BaseLayer)

function CardCollectionUI:initDatas()
    self.m_colNum = 2
    self.m_seasonSizeW, self.m_seasonSizeH = 368, 218
    self.m_cellSizeW, self.m_cellSizeH = 900, 218
    self.m_space = 50
    self.m_CurCellsMaxNum = 1
    self.m_data = CardSysRuntimeMgr:getCollectionSeasonIDs()
    -- 加入黑曜卡数据
    self:checkAddObsidianData()
    
    self:resortSeasonIds()
    
    self.m_dataCount = #self.m_data
    self.m_cellCount = math.ceil(#self.m_data / self.m_colNum)
    -- -- 监测互斥的方案 --
    -- self.m_moveTable = true
    -- self.m_moveSlider = true

    self.m_cellLua = "GameModule.Card.season201903.CardCollectionCell"
    self:setLandscapeCsbName(string.format(CardResConfig.seasonRes.CardCollectionRes, "season" .. CardSysRuntimeMgr:getCurAlbumID()))

    self:addClickSound({"Button_quit"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

function CardCollectionUI:resortSeasonIds()
    if self.m_data and #self.m_data > 0 then
        local noviceSeasonData = nil
        for i = #self.m_data, 1, -1 do
            if tonumber(self.m_data[i].seasonId) == tonumber(CardNoviceCfg.ALBUMID) then
                noviceSeasonData = table.remove(self.m_data, i)
            end
        end
        if noviceSeasonData then
            table.insert(self.m_data, noviceSeasonData)
        end
    end
end

function CardCollectionUI:checkAddObsidianData()
    local obsidianCardData = G_GetMgr(G_REF.ObsidianCard):getShortCardYears()
    self.isShowObsidianCardEntry = false
    if obsidianCardData then
        self.isShowObsidianCardEntry = obsidianCardData:isCollectionShowObsitionCard()
    end
    if self.isShowObsidianCardEntry == true then
        local isHave = false
        for i = #self.m_data, 1, -1 do
            if self.m_data[i].seasonId == "obsidianCard" then
                isHave = true
            end
        end
        if not isHave then
            table.insert(self.m_data, {seasonId = "obsidianCard"})
        end
    end
end

function CardCollectionUI:getObsidianCellLua()
    return "GameModule.Card.commonViews.CardCollectionObsidianCell"
end

function CardCollectionUI:initUI()
    CardCollectionUI.super.initUI(self)
    self:initData()
    self:initTableView()
    -- self:createSlide()
end

function CardCollectionUI:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CardCollectionUI.super.playShowAction(self, "show", false)
end

function CardCollectionUI:onShowedCallFunc()
    CardSysManager:hideRecoverSourceUI()
    self:runCsbAction("idle", true, nil, 60)
end

function CardCollectionUI:initData()
    self.m_tvLayer = self:findChild("layer_tableview")
    self.m_tableViewSize = self.m_tvLayer:getContentSize()
    self.m_totalH = self.m_cellCount * self.m_cellSizeH
end

function CardCollectionUI:initTableView()
    if not self.m_tableView then
        --创建TableView
        self.m_tableView = cc.TableView:create(self.m_tableViewSize)
        self.m_tvLayer:addChild(self.m_tableView)
        self.m_tableView:setName("tableview")
        --设置滚动方向  水平滚动
        self.m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
        self.m_tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
        self.m_tableView:setDelegate()
    end

    --registerScriptHandler functions must be before the reloadData funtion
    self.m_tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self.m_tableView:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX)
    self.m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
    -- self.m_tableView:registerScriptHandler(handler(self, self.scrollViewDidScroll), cc.SCROLLVIEW_SCRIPT_SCROLL)

    --调用这个才会显示界面
    self.m_tableView:reloadData()
end

function CardCollectionUI:numberOfCellsInTableView(table)
    return self.m_cellCount
end
function CardCollectionUI:cellSizeForTable(table, idx)
    return self.m_cellSizeW, self.m_cellSizeH
end

function CardCollectionUI:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    local cellIndex = idx + 1
    if cell == nil then
        cell = cc.TableViewCell:new()
    end
    cell:removeAllChildren()

    self:initBgNode(cell)

    local startX = self.m_cellSizeW / 2 - (self.m_space / 2) * (self.m_colNum - 1) - (self.m_seasonSizeW / 2) * (self.m_colNum - 1)
    for colIndex = 1, self.m_colNum do
        local __cell = self:createCell(cellIndex, colIndex)
        if __cell then
            __cell:setPosition(startX + (colIndex - 1) * (self.m_space + self.m_seasonSizeW), self.m_cellSizeH / 2)
            cell:addChild(__cell)
        end
    end

    for colIndex = 1, self.m_colNum do
        local dataIndex = self.m_colNum * (cellIndex - 1) + colIndex
        local __cell = cell:getChildByTag(dataIndex)
        if __cell then
            __cell:initView(self.m_data[dataIndex].seasonId)
        end
    end

    return cell
end

function CardCollectionUI:initBgNode()
end

function CardCollectionUI:createCell(cellIndex, colIndex)
    local dataIndex = self.m_colNum * (cellIndex - 1) + colIndex

    local cell = nil
    if self.m_data[dataIndex] then
        if self.m_data[dataIndex].seasonId == "obsidianCard" then
            cell = util_createView(self:getObsidianCellLua())
            cell:setTag(dataIndex)
        else
            cell = util_createView(self.m_cellLua)
            cell:setTag(dataIndex)
        end
    end
    return cell
end

function CardCollectionUI:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_quit" then
        if self.m_isEntering then
            return
        end
        CardSysManager:showRecoverSourceUI()
        self:closeUI()
    end
end

function CardCollectionUI:onEnter()
    CardCollectionUI.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:enterAlbum(params and params.albumId)
        end,
        CardSysConfigs.ViewEventType.CARD_COLLECTION_ENTER_ALBUM
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            -- 新赛季开启的时候退出集卡所有界面
            self:closeUI()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )
end

function CardCollectionUI:canEnterAlbum()
    if self.m_isEntering then
        return false
    end
    return true
end

function CardCollectionUI:enterAlbum(albumId)
    if not albumId then
        return
    end
    if not self:canEnterAlbum() then
        return
    end
    self.m_isEntering = true
    gLobalViewManager:addLoadingAnimaDelay()
    local function outPutNetInfo()
        gLobalViewManager:removeLoadingAnima()
        CardSysRuntimeMgr:setSelAlbumID(albumId)
        CardSysManager:showCardAlbumView(true)
        -- 延迟等界面打开后再设置回来
        performWithDelay(
            self,
            function()
                self.m_isEntering = false
            end,
            0.3
        )
    end
    local function faildFunc()
        gLobalViewManager:removeLoadingAnima()
        self.m_isEntering = false
    end
    -- release_print("------------------- albumId ----------- ", albumId)
    local year = string.sub(tostring(albumId), 1, 4)
    local tExtraInfo = {["year"] = tonumber(year), ["albumId"] = albumId}
    CardSysNetWorkMgr:sendCardsAlbumRequest(tExtraInfo, outPutNetInfo, faildFunc)
end

function CardCollectionUI:createSlide()
    -- 创建 slider滑动条 --
    local bgFile = cc.Sprite:create(CardResConfig.CollectionSliderBg) -- cc.Sprite:create(CardResConfig.CollectionSliderBg)
    local progressFile = cc.Sprite:create(CardResConfig.CollectionSliderBg)
    local thumbFile = cc.Sprite:create(CardResConfig.CollectionSliderMark)

    local markSize = thumbFile:getTextureRect()
    local bgSize = bgFile:getTextureRect() -- cc.size(489, 50)
    bgFile:setVisible(false)
    progressFile:setVisible(false)

    self.m_slider = cc.ControlSlider:create(bgFile, progressFile, thumbFile)
    self.m_slider:setPosition(self.m_tableViewSize.width + 40, self.m_tableViewSize.height / 2)
    self.m_slider:setAnchorPoint(cc.p(0.5, 0.5))
    self.m_slider:setRotation(90)
    self.m_slider:setEnabled(true)
    self.m_slider:setMinimumValue(-(self.m_totalH - self.m_tableViewSize.height))
    self.m_slider:setMaximumValue(0)
    self.m_slider:setValue(-(self.m_totalH - self.m_tableViewSize.height))

    self.m_slider:registerControlEventHandler(handler(self, self.sliderMoveEvent), cc.CONTROL_EVENTTYPE_VALUE_CHANGED)
    -- -- 放到最后吧，往上放的话在切换赛季时偏移量会有问题，像是偏移量使用的上一个赛季的
    self.m_tvLayer:addChild(self.m_slider)

    -- 创建一个长背景条 保证滑块上下齐边 --
    local addBgNode = ccui.ImageView:create(CardResConfig.CollectionSliderBg)
    addBgNode:setAnchorPoint(cc.p(0.5, 0.5))
    addBgNode:setScale9Enabled(true)
    addBgNode:setSize(cc.size(markSize.width + bgSize.width, bgSize.height))
    addBgNode:setPosition(cc.p(self.m_slider:getContentSize().width / 2, self.m_slider:getContentSize().height / 2))
    self.m_slider:addChild(addBgNode, -1)
end

-- -- slider 滑动事件 --
-- function CardCollectionUI:sliderMoveEvent()
--     self.m_moveTable = false
--     if self.m_moveSlider == true then
--         local sliderOff = self.m_slider:getValue()
--         self.m_tableView:setContentOffset(cc.p(0, sliderOff))
--     end
--     self.m_moveTable = true
-- end

-- -- tableView回调事件 --
-- --滚动事件
-- function CardCollectionUI:scrollViewDidScroll(view)
--     self.m_moveSlider = false
--     if self.m_moveTable == true then
--         local offY = self.m_tableView:getContentOffset().y
--         if self.m_slider ~= nil then
--             local sliderY = self.m_slider:getValue()
--             self.m_slider:setValue(offY)
--         end
--     end
--     self.m_moveSlider = true
-- end

return CardCollectionUI
