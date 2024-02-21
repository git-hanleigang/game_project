--[[--
    选择好友界面
    区分不同赠送类型，
        送卡时单选
        送金币时多选
]]
local InboxScrollview = util_require("views.inbox.InboxScrollview")
local InboxPage_send_chooseFriend_input = util_require("views.inbox.InboxPage_send_chooseFriend_input")
local BaseView = util_require("base.BaseView")
local InboxPage_send_chooseFriend = class("InboxPage_send_chooseFriend", BaseView)

function InboxPage_send_chooseFriend:initUI(mainClass)
    self.m_mainClass = mainClass
    self:createCsbNode("InBox/FBCard/InboxPage_Send_ChooseFriend.csb")

    self.m_sendLayer = self:findChild("Panel_send")

    self.img_SearchWenzi = self:findChild("lb_searchwenzi")
    self.m_TextField = self:findChild("TextField")

    self.m_btnSendCoinNode = self:findChild("Node_btn_sendcoin")
    -- self.m_btnSendChipNode = self:findChild("Node_btn_sendchip")

    -- self.m_btnSelCard = self:findChild("btn_selectCards")
    self.m_btnSend = self:findChild("btn_send")
    -- self:updateBottomBtnState()

    self:initInput()
    self:initFriendList()
    self:initData()
end

function InboxPage_send_chooseFriend:getMainClass()
    return self.m_mainClass
end

function InboxPage_send_chooseFriend:initInput()
    self.m_friendInput = InboxPage_send_chooseFriend_input:create(self)
    self.m_friendInput:initTextField(self.m_TextField)
end

-- 输入框默认显示文字
function InboxPage_send_chooseFriend:updateInputDefaultText()
    local input = self.m_friendInput:getString()
    if input and input ~= "" then
        self.img_SearchWenzi:setVisible(false)
    else
        self.img_SearchWenzi:setVisible(true)
    end
end

-- 点击状态
function InboxPage_send_chooseFriend:updateBottomBtnState()
    -- local chooseList = self:getChoosed()
    -- if #chooseList > 0 then
    -- 判断赠送次数
    local nLimit = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendLimitBySendType(self.m_curShowSendType)
    local recordList = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendRecordListBySendType(self.m_curShowSendType)
    local nRecord = #recordList
    if (nRecord < nLimit) then
        -- self.m_btnSend:setBright(true)
        -- self.m_btnSelCard:setTouchEnabled(true)
        -- self:setButtonLabelDisEnabled("btn_selectCards", true)
        -- self.m_btnSelCard:setBright(true)
        self.m_btnSend:setTouchEnabled(true)
        self:setButtonLabelDisEnabled("btn_send", true)
    else
        -- self.m_btnSend:setBright(false)
        -- self.m_btnSelCard:setTouchEnabled(false)
        -- self:setButtonLabelDisEnabled("btn_selectCards", false)
        -- self.m_btnSelCard:setBright(false)
        self.m_btnSend:setTouchEnabled(false)
        self:setButtonLabelDisEnabled("btn_send", false)
    end

    local LanguageKey = "InboxPage_send_chooseFriend:btn_send"
    local refStr = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "SEND ALL(%d/%d)"

    self:setButtonLabelContent("btn_send", string.format(refStr, nRecord, nLimit))
end

function InboxPage_send_chooseFriend:getFriendList()
    return self.m_friendList
end

function InboxPage_send_chooseFriend:initFriendList()
    local size = self.m_sendLayer:getContentSize()
    self.m_friendList = InboxScrollview:create()
    local scrollview = self.m_friendList:initScrollView()
    self.m_sendLayer:addChild(scrollview)
    self.m_friendList:setChoiceEnabled(true)
    self.m_friendList:setDisplaySize(size.width, size.height)
    self.m_friendList:setCellSize(284, 117)
    self.m_friendList:setColNum(3)
    self.m_friendList:setMargin(0, 0)
    -- self.m_friendList:setSplitLine("Inbox/Other/InboxNew_fengexian.png", 10)
end

function InboxPage_send_chooseFriend:createCell(cellIndex)
    local cell = util_createView("views.inbox.InboxPage_send_chooseFriend_cell", cellIndex, self)
    return cell
end

function InboxPage_send_chooseFriend:initCellList()
    local cellList = {}
    local listData = {}
    local listData = self:getFriendListData()
    if listData and #listData > 0 then
        for i = 1, #listData do
            local cell = self:createCell(i)
            cellList[i] = cell
            cell:updateUI(listData[i])
        end
    end
    return cellList, listData
end

function InboxPage_send_chooseFriend:resetFriendList()
    if self.m_friendList then
        self.m_friendList:resetList()
    end
end

function InboxPage_send_chooseFriend:initData()
    self.m_curShowSendType = nil
    self.m_choosedList = {}
end

function InboxPage_send_chooseFriend:updateUI()
    local sendType = self.m_mainClass:getSendType()
    -- if self.m_curShowSendType == nil then
    --     self.m_curShowSendType = sendType
    --     self:updateSendBtn()
    --     self:updateFriendList()
    --     self:updateBottomBtnState()
    -- else
    --     if self.m_curShowSendType ~= sendType then
    -- 清除
    self:clearChoosedList()
    self:resetFriendList()

    self.m_curShowSendType = sendType
    self:updateSendBtn()
    self:updateFriendList()
    self:updateBottomBtnState()
    --     end
    -- end
end

function InboxPage_send_chooseFriend:updateSendBtn()
    if self.m_curShowSendType == "CARD" then
        -- self.m_btnSendChipNode:setVisible(true)
        self.m_btnSendCoinNode:setVisible(false)
    elseif self.m_curShowSendType == "COIN" then
        -- self.m_btnSendChipNode:setVisible(false)
        self.m_btnSendCoinNode:setVisible(true)
    end
end

function InboxPage_send_chooseFriend:updateFriendList()
    if self.m_curShowSendType == "CARD" then
        self.m_friendList:setChoiceType("SINGLE")
    elseif self.m_curShowSendType == "COIN" then
        self.m_friendList:setChoiceType("MULTI")
    else
        return
    end

    local cellList, cellDatas = self:initCellList()
    self.m_cellDatas = cellDatas
    self.m_friendList:initCellList(cellList)
    self.m_friendList:initUIList()
end

function InboxPage_send_chooseFriend:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_back" then
        self.m_mainClass:changeState("ChooseGift")
        if self.m_friendInput then
            self.m_friendInput:setString("")
        end
    elseif name == "btn_x" then
        if self.m_friendInput then
            self.m_friendInput:setString("")
        end
    elseif name == "btn_selectCards" then
        self:showChooseChips()
    elseif name == "btn_send" then
        -- 一键赠送
        local sendType = self.m_mainClass:getSendType()
        local sendedList = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendRecordListBySendType(sendType)
        local nLimit = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendLimitBySendType(sendType)
        local nLast = math.max(0, (nLimit - #sendedList))
        for i = 1, #self.m_cellDatas do
            local _data = self.m_cellDatas[i]
            if _data and not _data.isSended then
                -- self:setChoosed(_data.id, true)
                self:setChoosed(_data.p_udid, true)
                nLast = nLast - 1
                if nLast <= 0 then
                    break
                end
            end
        end
        self:FBMail_sendCoin()
    end
end

function InboxPage_send_chooseFriend:getFriendListData()
    -- local originData = G_GetMgr(G_REF.Inbox):getFriendRunData():getFaceBookFriendInfo()

    -- TODO 好友数据 从好友数据中获取好友列表
    local friendData = G_GetMgr(G_REF.Friend):getData()
    if not friendData then
        return {}
    end
    local originData = friendData:getFriendAllList()

    -- 条件筛选：未满足等级要求的不显示
    local limitLv = 0
    if self.m_curShowSendType == "CARD" then
        limitLv = globalData.constantData.INBOX_FACEBOOK_CARD
    elseif self.m_curShowSendType == "COIN" then
        limitLv = globalData.constantData.INBOX_FACEBOOK_COIN
    end
    if CC_INBOX_FB_TEST then
        limitLv = -999999 -- 服务器下发的数据里可能有等级为-1的
    end
    local levelTemp = {}
    for i = 1, #originData do
        if originData[i]:getLevel() >= limitLv then
            levelTemp[#levelTemp + 1] = originData[i]
        end
    end
    if #levelTemp == 0 then
        return {}
    end

    -- 条件筛选：已经送过的不能再送
    local sendedTemp = {}
    local friendsTemp = clone(levelTemp)
    -- local sendedList = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendRecordList()
    local sendType = self.m_mainClass:getSendType()
    local sendedList = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendRecordListBySendType(sendType)
    if #sendedList > 0 then
        for i = 1, #friendsTemp do
            local oriData = friendsTemp[i]
            local isSended = false
            for j = 1, #sendedList do
                if oriData:getUDID() == sendedList[j] then
                    oriData.isSended = true
                end
            end
            -- if not isSended then
            sendedTemp[#sendedTemp + 1] = oriData
            -- end
        end
    else
        sendedTemp = friendsTemp
    end

    if #sendedTemp == 0 then
        return {}
    end

    -- 条件筛选：输入搜索
    -- str = string.gsub(str, " ", "")
    local content = self.m_friendInput:getString()
    if content and content ~= "" then
        local indexTemp = {}
        local matchingIndexs = {}
        for i = 1, #sendedTemp do
            local oriData = sendedTemp[i]
            local startIndex, overIndex = string.find(string.lower(oriData:getName()), string.lower(content), nil, true)
            if startIndex ~= nil then
                indexTemp[#indexTemp + 1] = {matchingType = 1, startIndex = startIndex, data = oriData}
                matchingIndexs[#matchingIndexs + 1] = i
            end
        end

        if string.find(content, " ") then
            for i = 1, #sendedTemp do
                local isMatching = false
                for j = 1, #matchingIndexs do
                    if i == matchingIndexs[j] then
                        isMatching = true
                    end
                end
                if not isMatching then
                    local oriData = sendedTemp[i]
                    local startIndex, overIndex = string.find(string.lower(string.gsub(oriData:getName(), " ", "")), string.lower(string.gsub(content, " ", "")), nil, true)
                    if startIndex ~= nil then
                        indexTemp[#indexTemp + 1] = {matchingType = 2, startIndex = startIndex, data = oriData}
                    end
                end
            end
        end

        local temp = {}
        if #indexTemp > 0 then
            table.sort(
                indexTemp,
                function(a, b)
                    local UDIDA = a.data:getUDID()
                    local UDIDB = b.data:getUDID()
                    local nameA = a.data:getName()
                    local nameB = b.data:getName()
                    if a.matchingType == b.matchingType then
                        if a.startIndex == b.startIndex then
                            if nameA == nameB then
                                return UDIDA == UDIDB
                            else
                                return nameA <= nameB
                            end
                        else
                            return a.startIndex <= b.startIndex
                        end
                    else
                        return a.matchingType == b.matchingType
                    end
                end
            )

            for i = 1, #indexTemp do
                temp[#temp + 1] = indexTemp[i].data
            end
        end
        return temp
    else
        return sendedTemp
    end
end

function InboxPage_send_chooseFriend:removeChoosed(udids)
    if not udids or type(udids) ~= "table" then
        return
    end
    if #udids == 0 then
        return
    end
    for i = 1, #udids do
        local udid = udids[i]
        if udid and self.m_choosedList[tostring(udid)] ~= nil then
            self.m_choosedList[tostring(udid)] = nil
        end
    end
end

function InboxPage_send_chooseFriend:clearChoosedList()
    if self.m_choosedList and next(self.m_choosedList) ~= nil then
        self.m_choosedList = {}
    end
end

function InboxPage_send_chooseFriend:setChoosed(udid, isChoosed)
    self.m_choosedList[tostring(udid)] = isChoosed
    -- self:updateBottomBtnState()
end

function InboxPage_send_chooseFriend:getChoosed()
    if self.m_choosedList == nil then
        return {}
    end
    local temp = {}
    for udid, isChoosed in pairs(self.m_choosedList) do
        if isChoosed == true then
            temp[#temp + 1] = tostring(udid)
        end
    end
    return temp
end

function InboxPage_send_chooseFriend:showChooseChips()
    G_GetMgr(G_REF.Inbox):getFriendNetwork():FBInbox_requestFBCardList(
        function()
            if not tolua.isnull(self) then
                local view = util_createView("views.inbox.InboxPage_send_chooseChip", self)
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            end
        end
    )
end

function InboxPage_send_chooseFriend:FBMail_sendCoin()
    local success = function()
        if not tolua.isnull(self) then
            self.m_sendNeting = false

            -- 返回到选择界面
            -- self.m_mainClass:changeState("ChooseGift")

            -- self:initData()
            -- 清除
            -- self:clearChoosedList()
            -- self:resetFriendList()
            -- self:updateBottomBtnState()
            self:updateUI()
        end
    end
    local fail = function()
        if not tolua.isnull(self) then
            self.m_sendNeting = false
        end
    end

    -- local fbIds = self:getChoosed() or {}
    -- if #fbIds <= 0 then
    --     return
    -- end
    local udids = self:getChoosed() or {}
    if #udids <= 0 then
        return
    end

    self.m_sendNeting = true

    local extraData = {}
    extraData["mailType"] = "COIN"
    -- extraData["facebookIds"] = fbIds -- {"ffffffacffffffbc32ffffffa72e5b"}
    extraData["friendUdid"] = udids -- {"ffffffacffffffbc32ffffffa72e5b"}
    G_GetMgr(G_REF.Inbox):getFriendNetwork():FBInbox_sendFBMail(extraData, success, fail)

    -- 清除
    -- self:clearChoosedList()
    -- self:resetFriendList()
    -- self:updateSendBtn()
    -- self:updateFriendList()
    -- self:updateBottomBtnState()
end

-----------------------------------------------------------
function InboxPage_send_chooseFriend:onEnter()
    -- TODO 好友数据 刷新好友列表，有了数据后刷新，或者，送过卡或者送过金币后刷新
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         if params.flag then
    --             -- 好友列表已经获取到，刷新列表
    --             self:clearChoosedList()
    --             self:resetFriendList()
    --             self:updateSendBtn()
    --             self:updateFriendList()
    --             self:updateBottomBtnState()
    --         end
    --     end,
    --     ViewEventType.NOTIFY_INBOX_FACEBOOK_FRIEND_LIST
    -- )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:removeChoosed(params and params.FBIdList)
            self:resetFriendList()
            self:updateSendBtn()
            self:updateFriendList()
            self:updateBottomBtnState()
        end,
        ViewEventType.NOTIFY_UPDATE_CHOOSEFRIEND_UI
    )
end

function InboxPage_send_chooseFriend:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return InboxPage_send_chooseFriend
