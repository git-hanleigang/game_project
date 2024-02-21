--[[-- 
    回收机卡牌 tab 选择 列表
]]
local CardRecoverExchangeTabList = class("CardRecoverExchangeTabList", util_require("base.BaseView"))

function CardRecoverExchangeTabList:getTableView()
    return self.m_tableView
end

function CardRecoverExchangeTabList:getCsbName()
    return string.format(CardResConfig.commonRes.CardRecoverSelTabListRes, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end
function CardRecoverExchangeTabList:initDatas(_Type,_listData,_CurIndex)
    self.m_isShowDetail = false --列表展开
    self.m_listData = _listData
    self.m_type = _Type
    if _CurIndex == -1 then
        _CurIndex = 0
    end
    self.m_curIndex = _CurIndex + 1
end

function CardRecoverExchangeTabList:initUI(_Type,_listData,_CurIndex)
    CardRecoverExchangeTabList.super.initUI(self)
    
    self.m_panel_list = self:findChild("panel_list")
    self.m_panel_cellClone = self:findChild("panel_cellClone")
    self.m_panel_cellClone:setVisible(false)

    self.m_lb_selectAlbum = self:findChild("lb_selectAlbum")
    self.m_lb_selectAlbum:setString(self.m_listData[self.m_curIndex].tabText)
    
    self.m_tableViewSize = self.m_panel_list:getContentSize()
    
    if not self.m_listData then
        return
    end
    if #self.m_listData == 0 then
        return
    end

    self.m_ControlNodeList = {}
    self.m_CurCellsMaxNum = #self.m_listData
    self:createTableView()
    if #self.m_listData > 6 then
        self:createSlide()
    end
    self:runCsbAction("idle_close", false, nil, 60)
end

function CardRecoverExchangeTabList:refreshViewByData(listData)
    
    self.m_listData = listData
    self.m_tableView:reloadData()
end

function CardRecoverExchangeTabList:changeSelectIndexToAll()
    self.m_curIndex = 1
    self.m_lb_selectAlbum:setString(self.m_listData[self.m_curIndex].tabText)
end

function CardRecoverExchangeTabList:createSlide()
    if self.m_slider then
        self.m_slider:removeFromParent()
    end

    local ExchangeSliderBg = string.format(CardResConfig.ExchangeSliderBg, "common" .. CardSysRuntimeMgr:getCurAlbumID())
    local ExchangeSliderMark = string.format(CardResConfig.ExchangeSliderMark, "common" .. CardSysRuntimeMgr:getCurAlbumID())

    self.m_slider = ccui.Slider:create()
    self.m_slider:setTouchEnabled(false)
    self.m_slider:loadBarTexture(ExchangeSliderBg)
    self.m_slider:loadProgressBarTexture(ExchangeSliderBg)
    self.m_slider:loadSlidBallTextures(ExchangeSliderMark)
    self.m_slider:addEventListenerSlider(handler(self, self.sliderMoveEvent))
    self.m_slider:setRotation(-90)
    self.m_slider:setScale(0.8 * 0.6)
    self.m_slider:setMaxPercent(self.m_vCellSize.height * self.m_CurCellsMaxNum - self.m_tableViewSize.height)
    self.m_slider:setPercent((self.m_vCellSize.height * self.m_CurCellsMaxNum - self.m_tableViewSize.height))
    self.m_slider:setPosition(self.m_tableViewSize.width - 5, self.m_tableViewSize.height / 2)
    self.m_panel_list:addChild(self.m_slider)

    -- 创建 slider滑动条 --
    local bgFile = cc.Sprite:create(ExchangeSliderBg)
    local progressFile = cc.Sprite:create(ExchangeSliderBg)
    local thumbFile = cc.Sprite:create(ExchangeSliderMark)

    -- 创建一个长背景条 保证滑块上下齐边 --
    local markSize = thumbFile:getTextureRect()
    local bgSize = bgFile:getTextureRect()
    local addBgNode = ccui.ImageView:create(ExchangeSliderBg)
    addBgNode:setAnchorPoint(cc.p(0.5, 0.5))
    addBgNode:setScale9Enabled(true)
    addBgNode:setSize(cc.size(markSize.width + bgSize.width, bgSize.height))
    addBgNode:setPosition(cc.p(self.m_slider:getContentSize().width / 2, self.m_slider:getContentSize().height / 2))
    self.m_slider:addChild(addBgNode, -1)
    --addBgNode:setScale(0.8)
    -- 监测互斥的方案 --
    self.m_moveTable = true
    self.m_moveSlider = true
end

-- slider 滑动事件 --
function CardRecoverExchangeTabList:sliderMoveEvent()
    self.m_moveTable = false
    if self.m_moveSlider == true then
        local sliderOff = self.m_slider:getPercent()
       -- self.m_tableView:setContentOffset(cc.p(0, -sliderOff))
    end
    self.m_moveTable = true
end

-- tableView回调事件 --
--滚动事件
function CardRecoverExchangeTabList:scrollViewDidScroll(view)
    if not self.m_slider then
        return
    end
    self.m_moveSlider = false
    if self.m_moveTable == true then
        local offY = self.m_tableView:getContentOffset().y

        if self.m_slider ~= nil then
            local sliderY = self.m_slider:getPercent()
            self.m_slider:setPercent(-offY)
        end
    end
    self.m_moveSlider = true
end

function CardRecoverExchangeTabList:createTableView()
    self.m_tableView = cc.TableView:create(self.m_tableViewSize)
    --禁止回弹效果
    self.m_tableView:setBounceable(false)
    --设置滚动方向
    self.m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.m_tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_tableView:setDelegate()
    self.m_vCellSize = self.m_panel_cellClone:getContentSize()
    --self.m_tableView:setTouchEnable(true)
    self.m_panel_list:addChild(self.m_tableView)

    --registerScriptHandler functions must be before the reloadData funtion
    self.m_tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self.m_tableView:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX)
    self.m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
    self.m_tableView:registerScriptHandler(handler(self, self.scrollViewDidScroll), cc.SCROLLVIEW_SCRIPT_SCROLL)
    --调用这个才会显示界面
    self.m_tableView:reloadData()
end

function CardRecoverExchangeTabList:numberOfCellsInTableView(table)
    return self.m_CurCellsMaxNum
end

function CardRecoverExchangeTabList:cellSizeForTable(table, idx)
    return self.m_vCellSize.width, self.m_vCellSize.height
end

function CardRecoverExchangeTabList:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
    end
    cell:setTag(idx + 1)
    self:createCell(cell,idx + 1)
    return cell
end

function CardRecoverExchangeTabList:createCell(cell,index)
    
    local cellClone = self.m_panel_cellClone:clone()
    cell:addChild(cellClone)
    cellClone:setPosition(cc.p(0,0))
    cellClone:setVisible(true)
    local  lb_oneAlbum = cellClone:getChildByName("lb_oneAlbum")
    lb_oneAlbum:setString(self.m_listData[index].tabText)

    local  lb_oneAlbum_front = cellClone:getChildByName("lb_oneAlbum_front")
    lb_oneAlbum_front:setString(self.m_listData[index].tabText)
    lb_oneAlbum_front:setVisible(false)

    local  lb_oneAlbum_count = cellClone:getChildByName("lb_oneAlbum_count")
    lb_oneAlbum_count:setVisible(false)

    if self.m_listData[index].count and self.m_listData[index].count >= 0 then
        lb_oneAlbum:setVisible(false)
        lb_oneAlbum_front:setVisible(true)
        lb_oneAlbum_count:setVisible(true)

        local countStr = "(" .. self.m_listData[index].count .. ")"
        if self.m_listData[index].count >= 1000 then
            countStr = "(999+)"
        end
        lb_oneAlbum_count:setString(countStr)
        lb_oneAlbum_count:setColor(cc.c3b(0,255,0))
        if self.m_listData[index].count == 0 then
            lb_oneAlbum_count:setColor(cc.c3b(255,0,0))
        end
    end

    cellClone:setSwallowTouches(false)
    cellClone:addTouchEventListener( function( sender, eventType )
        if eventType == ccui.TouchEventType.ended then
            local endPos = sender:getTouchEndPosition()
            self:selectIndex(index)
        end
    end )
end

function CardRecoverExchangeTabList:selectIndex(index)
    print("点击了cell：" .. self.m_listData[index].tabText)
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
    self.m_lb_selectAlbum:setString(self.m_listData[index].tabText)
    self:hideDetail()
    local selectIndex = index - 1
    if selectIndex == 0 then
        selectIndex = -1 --all
    end
    if self.m_type == "year" then
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_EXCHANGE_TAB_UPDATE, {yearIndex = selectIndex})
    elseif self.m_type == "type" then
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_EXCHANGE_TAB_UPDATE, {typeIndex = selectIndex})
    elseif self.m_type == "star" then
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_EXCHANGE_TAB_UPDATE, {starIndex = selectIndex})
    end
end

function CardRecoverExchangeTabList:showDetail()
    self.m_isShowDetail = true
    self:runCsbAction("show", false, nil, 60)
end

function CardRecoverExchangeTabList:hideDetail()
    if self.m_isShowDetail then
        self.m_isShowDetail = false
        self:runCsbAction("over", false, nil, 60)
    end
end

function CardRecoverExchangeTabList:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_select" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        if self.m_isShowDetail == false then
            self:showDetail()
        else
            self:hideDetail()
        end
    end
end

return CardRecoverExchangeTabList
