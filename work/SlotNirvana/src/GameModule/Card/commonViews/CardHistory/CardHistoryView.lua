--[[
    卡牌获取历史界面
]]
local CardHistoryView = class("CardHistoryView", BaseLayer)

function CardHistoryView:initDatas(overShow)
    CardHistoryView.super.initDatas(self)
    -- 清空红点数据
    CardSysRuntimeMgr:getSeasonData():setHistoryNewNum()

    self:setLandscapeCsbName(string.format(CardResConfig.commonRes.CardHistoryViewRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    self:setHideLobbyEnabled(true)
    self.m_overShow = overShow

    self:addClickSound({"Button_x"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

-- 初始化UI --
function CardHistoryView:initUI()
    CardHistoryView.super.initUI(self)
    self:initAdapt()
end

function CardHistoryView:initAdapt()
    -- local offsetX = 0
    -- local ratio = display.width / display.height
    -- if ratio <= 1.34 then -- 1024x768
    --     offsetX = 0
    -- elseif ratio <= 1.5 then -- 960x640
    --     offsetX = 25
    -- elseif ratio <= 1.79 then -- 1370x768
    --     offsetX = 45
    -- elseif ratio <= 2 then -- 1280x640
    --     offsetX = 120
    -- else -- 2340x1080 -- 1170x540
    --     offsetX = 190
    -- end

    -- local oriX1 = self:findChild("Button_x"):getPositionX()
    -- self:findChild("Button_x"):setPositionX(oriX1 - offsetX)
end

function CardHistoryView:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CardHistoryView.super.playShowAction(self, "show", false)
end

function CardHistoryView:onShowedCallFunc()
    if self.m_overShow then
        self.m_overShow()
    end
    CardSysManager:hideRecoverSourceUI()
    self:runCsbAction("idle")
end

function CardHistoryView:initView()
    self.m_cardsHistoryList = CardSysRuntimeMgr:getCardDropHistoryInfo()
    if self.m_cardsHistoryList == nil or #self.m_cardsHistoryList == 0 then
        return
    end
    -- 收到数据后 显示列表 --
    self:initTableView()
end

-- 初始化节点 --
function CardHistoryView:initCsbNodes()
    self.m_btnClose = self:findChild("Button_4")
    self.m_btnBack = self:findChild("Button_5")
end

function CardHistoryView:canClick()
    return true
end

-- 点击事件 --
function CardHistoryView:clickFunc(sender)
    local name = sender:getName()
    if not self:canClick() then
        return
    end
    if name == "Button_x" then
        CardSysManager:showRecoverSourceUI()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HISTORY_RED_POINT)
        self:closeUI()
    end
end

function CardHistoryView:onEnter()
    CardHistoryView.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            -- 新赛季开启的时候退出集卡所有界面
            self:closeUI()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )
end

-- 初始化tableView --
function CardHistoryView:initTableView()
    self.m_nHistoryNum = #self.m_cardsHistoryList
    self.m_vCellSize = cc.size(963, 115)

    self.m_TableViewRoot = self:findChild("TableViewRoot")
    local tableViewSize = self.m_TableViewRoot:getContentSize()
    --创建TableView
    self.m_tableView = cc.TableView:create(tableViewSize)
    --设置滚动方向  水平滚动
    -- tableView:setDirection(cc.SCROLLVIEW_DIRECTION_HORIZONTAL)
    self.m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.m_tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_tableView:setDelegate()
    self.m_TableViewRoot:addChild(self.m_tableView)

    --registerScriptHandler functions must be before the reloadData funtion
    self.m_tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self.m_tableView:registerScriptHandler(handler(self, self.scrollViewDidScroll), cc.SCROLLVIEW_SCRIPT_SCROLL)
    self.m_tableView:registerScriptHandler(handler(self, self.scrollViewDidZoom), cc.SCROLLVIEW_SCRIPT_ZOOM)
    self.m_tableView:registerScriptHandler(handler(self, self.tableCellTouched), cc.TABLECELL_TOUCHED)
    self.m_tableView:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX)
    self.m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)

    --调用这个才会显示界面
    -- self.m_tableView :reloadData()

    -- 创建 slider滑动条 --
    local bgFile = cc.Sprite:create(CardResConfig.HistorySliderBg)
    local progressFile = cc.Sprite:create(CardResConfig.HistorySliderBg)
    local thumbFile = cc.Sprite:create(CardResConfig.HistorySliderMark)

    self.m_slider = cc.ControlSlider:create(bgFile, progressFile, thumbFile)
    self.m_slider:setPosition(tableViewSize.width + 30, tableViewSize.height / 2)
    self.m_slider:setAnchorPoint(cc.p(0.5, 0.5))
    self.m_slider:setRotation(90)
    self.m_slider:setEnabled(true)
    self.m_slider:registerControlEventHandler(handler(self, self.sliderMoveEvent), cc.CONTROL_EVENTTYPE_VALUE_CHANGED)

    if self.m_vCellSize.height * self.m_nHistoryNum >= tableViewSize.height then
        self.m_slider:setVisible(true)
        local valueMin = -(self.m_vCellSize.height * self.m_nHistoryNum - tableViewSize.height)
        self.m_slider:setMinimumValue(valueMin)
        self.m_slider:setMaximumValue(0)
        self.m_slider:setValue(valueMin)
    else
        self.m_slider:setVisible(false)
    end

    self.m_TableViewRoot:addChild(self.m_slider)

    -- 创建一个长背景条 保证滑块上下齐边 --
    local markSize = thumbFile:getTextureRect()
    local bgSize = bgFile:getTextureRect()
    local addBgNode = ccui.ImageView:create(CardResConfig.HistorySliderBg)
    addBgNode:setAnchorPoint(cc.p(0.5, 0.5))
    addBgNode:setScale9Enabled(true)
    addBgNode:setSize(cc.size(markSize.width + bgSize.width, bgSize.height))
    addBgNode:setPosition(cc.p(self.m_slider:getContentSize().width / 2, self.m_slider:getContentSize().height / 2))
    self.m_slider:addChild(addBgNode, -1)

    --调用这个才会显示界面,界面初始化之后调用
    self.m_tableView:reloadData()

    -- 监测互斥的方案 --
    self.m_moveTable = true
    self.m_moveSlider = true
end

-- slider 滑动事件 --
function CardHistoryView:sliderMoveEvent()
    self.m_moveTable = false
    if self.m_moveSlider == true then
        local sliderOff = self.m_slider:getValue()
        self.m_tableView:setContentOffset(cc.p(0, sliderOff))
    end
    self.m_moveTable = true
end

-- tableView回调事件 --
--滚动事件
function CardHistoryView:scrollViewDidScroll(view)
    self.m_moveSlider = false

    if self.m_moveTable == true then
        if self.m_slider ~= nil then
            local offY = self.m_tableView:getContentOffset().y
            self.m_slider:setValue(offY)
        end
    end
    self.m_moveSlider = true
end

function CardHistoryView:scrollViewDidZoom(view)
    -- print("scrollViewDidZoom")
end

--cell点击事件
function CardHistoryView:tableCellTouched(table, cell)
    -- print("点击了cell：" .. cell:getIdx())
end

--cell的大小，注册事件就能直接影响界面，不需要主动调用
function CardHistoryView:cellSizeForTable(table, idx)
    return self.m_vCellSize.width, self.m_vCellSize.height
end

--显示出可视部分的界面，出了裁剪区域的cell就会被复用
function CardHistoryView:tableCellAtIndex(table, idx)
    idx = idx + 1
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
        cell:addChild(self:createHistoryCell())
    end

    -- 初始化卡片 时间 来源等数据 --
    local historyData = self.m_cardsHistoryList[idx]
    local historyCell = cell:getChildByTag(10)
    historyCell:updateUI(historyData)
    return cell
end

--设置cell个数，注册就能生效，不用主动调用
function CardHistoryView:numberOfCellsInTableView(table)
    return #self.m_cardsHistoryList
end

-- 根据索引创建历史记录单元 --
function CardHistoryView:createHistoryCell()
    -- 初始化卡片 时间 来源等数据 --
    local historyCell = util_createView("GameModule.Card.commonViews.CardHistory.CardHistoryCell")
    historyCell:setPosition(cc.p(0, 0))
    historyCell:setTag(10)
    return historyCell
end

return CardHistoryView
