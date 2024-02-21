--[[
    FB好友送卡，选择卡牌界面
]]
local InboxScrollview = util_require("views.inbox.InboxScrollview")
local BaseView = util_require("base.BaseView")
local InboxPage_send_chooseChip = class("InboxPage_send_chooseChip", BaseLayer)

function InboxPage_send_chooseChip:ctor()
    InboxPage_send_chooseChip.super.ctor(self)

    self:setLandscapeCsbName("InBox/FBCard/InboxPage_Send_SelCardPop.csb")
end

function InboxPage_send_chooseChip:initDatas(_mainClass)
    self.m_mainClass = _mainClass
    self.m_choosedList = {} -- 已经选择的卡牌
end

function InboxPage_send_chooseChip:initCsbNodes()
    self.m_scrollLayer = self:findChild("scrollLayer")
    self.m_scrollLayer:setScrollBarEnabled(false)

    self.m_btnSend = self:findChild("btn_send")

    self.m_slider = self:findChild("img_slide")

    self.m_chooseLayers = {}
    for i = 1, 5 do
        self.m_chooseLayers[i] = self:findChild("chooseLayer_" .. i)
        self:addClick(self.m_chooseLayers[i])
    end

    self.m_choosedNodeList = {}
    for i = 1, 5 do
        local chipNode = self:findChild("node_chip" .. i)
        self.m_choosedNodeList[i] = chipNode
    end
end

function InboxPage_send_chooseChip:initView()
    self:initChipList()
    self:updateSendBtn()
    self:updateBottomList()
    self:updateSlide()
end

-- 没有选择卡牌时，按钮置灰不能点击
function InboxPage_send_chooseChip:updateSendBtn()
    local choosedList = self:getChoosed()
    self:setButtonLabelDisEnabled("btn_send", #choosedList > 0)
end

-- 底部已经选择的卡牌
function InboxPage_send_chooseChip:updateBottomList()
    local listData = self:getChipListData()
    local choosedList = self:getChoosed()
    for i = 1, 5 do
        local chipNode = self.m_choosedNodeList[i]
        chipNode:removeAllChildren()
        if i <= #choosedList then
            local cardData = choosedList[i]
            local chip = util_createView("GameModule.Card.season201903.MiniChipUnit")
            chip:playIdle()
            chip:reloadUI(cardData, true)
            chipNode:addChild(chip)
        end
    end
end

function InboxPage_send_chooseChip:initChipList()
    local listData = self:getChipListData()
    if listData then
        for k, v in ipairs(listData) do
            self:addTitle(v.clanId, v.name)
            self:addCards(v.cards)
        end
    end
end

function InboxPage_send_chooseChip:addTitle(_clanId, _name)
    local title = util_createView("views.inbox.InboxPage_send_chooseChip_title", _clanId, _name)
    local height = title:getHeight()
    local layout = ccui.Layout:create()
    layout:setContentSize({width = 715, height = height + 10})
    layout:addChild(title)
    title:setPosition(385, height / 2 + 5)
    self.m_scrollLayer:pushBackCustomItem(layout)
end

function InboxPage_send_chooseChip:addCards(_cards)
    local layout = ccui.Layout:create()
    local width = 900
    local height = #_cards > 5 and 320 or 160
    layout:setContentSize({width = width, height = height})
    for i, v in ipairs(_cards) do
        local cell = util_createView("views.inbox.InboxPage_send_chooseChip_cell", self)
        cell:updateUI(v)
        cell:setPosition(79 + 176 * (i - (1 + 5 * (i <= 5 and 0 or 1))), (#_cards > 5 and (i <= 5 and 240 or 80) or 80))
        layout:addChild(cell)
    end
    self.m_scrollLayer:pushBackCustomItem(layout)
end

function InboxPage_send_chooseChip:clickChoosedLayer(index)
    local choosedList = self:getChoosed()
    if index <= #choosedList then
        local cardData = choosedList[index]
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_SEND_CHOOSECARD_CELL_UPDATE_STATE, cardData.cardId)
    end
end

function InboxPage_send_chooseChip:updateSlide()
    if self.m_slider then
        self.m_slider:setPercent(0)
        self.m_slider:addEventListener(handler(self, self.sliderMoveEvent))
        self.m_scrollLayer:onScroll(handler(self, self.scrollMoveEvent))
    end
end

function InboxPage_send_chooseChip:sliderMoveEvent(_sender, _event)
    if _event == 0 then
        local percent = self.m_slider:getPercent()
        self.m_scrollLayer:jumpToPercentVertical(percent)
    end
end

function InboxPage_send_chooseChip:scrollMoveEvent(_event)
    if _event.eventType == 9 then
        local percent = self.m_scrollLayer:getScrolledPercentVertical()
        self.m_slider:setPercent(percent)
    end
end

function InboxPage_send_chooseChip:canClick()
    if self.m_sendNeting then
        return false
    end
    return true
end

function InboxPage_send_chooseChip:clickFunc(sender)
    if not self:canClick() then
        return
    end
    local name = sender:getName()
    if name == "btn_send" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:sendCards()
    elseif name == "btn_close" then
        self:closeUI()
    elseif string.sub(name, 1, 12) == "chooseLayer_" then
        local str = string.split(name, "_")
        local index = tonumber(str[2])
        self:clickChoosedLayer(index)
    end
end

function InboxPage_send_chooseChip:sendCards()
    self.m_sendNeting = true

    local extraData = {}
    extraData["mailType"] = "CARD"
    -- extraData["facebookIds"] = self.m_mainClass:getChoosed() -- {"ffffffacffffffbc32ffffffa72e5b"}
    extraData["friendUdid"] = self.m_mainClass:getChoosed() -- {"ffffffacffffffbc32ffffffa72e5b"}
    extraData["cards"] = self:getChoosedCards()
    G_GetMgr(G_REF.Inbox):getFriendNetwork():FBInbox_sendFBMail(
        extraData,
        function()
            if not tolua.isnull(self) then
                self.m_sendNeting = false
                -- 返回到选择界面
                self.m_mainClass:getMainClass():changeState("ChooseGift")
                self.m_mainClass:initData()
                -- 清除
                self.m_mainClass:clearChoosedList()
                self.m_mainClass:resetFriendList()
                self.m_mainClass:updateBottomBtnState()

                -- 发送成功后，关闭界面
                self:closeUI()
            end
        end,
        function()
            if not tolua.isnull(self) then
                self.m_sendNeting = false
            end
        end
    )
end

function InboxPage_send_chooseChip:getChipListData()
    local temp = G_GetMgr(G_REF.Inbox):getFriendRunData():getFBCardList()
    -- for i=1,#temp do
    --     if temp[i].type == "LINK" or temp[i].type == "GOLDEN" then
    --         print("temp ----- ",i, temp[i].type)
    --     end
    -- end
    -- local types = {LINK = 3, GOLDEN = 2, NORMAL = 1}
    -- table.sort(
    --     temp,
    --     function(a, b)
    --         if types[a.type] == types[b.type] then
    --             if a.star == b.star then
    --                 return tonumber(a.cardId) < tonumber(b.cardId)
    --             else
    --                 return a.star > b.star
    --             end
    --         else
    --             return types[a.type] > types[b.type]
    --         end
    --     end
    -- )
    return temp
end

--------------------------------------------------------------------------------
function InboxPage_send_chooseChip:setChoosed(_clanId, _cardId, isChoosed)
    local listData = self:getChipListData()
    local insertFlag = true
    for i, v in ipairs(self.m_choosedList) do
        if v.cardId == _cardId then
            table.removebyvalue(self.m_choosedList, v)
            insertFlag = false
        end
    end
    if insertFlag then
        for i, v in ipairs(listData) do
            if v.clanId == _clanId then
                for n, m in ipairs(v.cards) do
                    if m.cardId == _cardId then
                        table.insert(self.m_choosedList, m)
                    end
                end
            end
        end
    end

    self:updateBottomList()
    self:updateSendBtn()
end

function InboxPage_send_chooseChip:getChoosed()
    return self.m_choosedList
end
--------------------------------------------------------------------------------
function InboxPage_send_chooseChip:getChoosedCards()
    local cards = {}
    local choosedList = self:getChoosed()
    for i, v in ipairs(choosedList) do
        if not cards[v.cardId] then
            cards[v.cardId] = 0
        end
        cards[v.cardId] = cards[v.cardId] + 1
    end

    return cards
end
return InboxPage_send_chooseChip
