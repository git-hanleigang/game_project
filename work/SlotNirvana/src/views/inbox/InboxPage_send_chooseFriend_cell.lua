--[[--
    选择好友cell
]]
local NetSpriteLua = require("views.NetSprite")
local BaseView = util_require("base.BaseView")
local InboxPage_send_chooseFriend_cell = class("InboxPage_send_chooseFriend_cell", BaseView)
function InboxPage_send_chooseFriend_cell:initUI(index, mainClass)
    self.m_index = index
    self.m_mainClass = mainClass
    self.m_scrollview = self.m_mainClass:getFriendList()
    self.m_isChoosed = false
    self:createCsbNode("InBox/FBCard/InboxPage_Send_ChooseFriend_cell.csb")

    self.m_nameLayer = self:findChild("panel_name")
    self.m_lbName = self:findChild("lb_friendName")
    -- self.m_imgPlus = self:findChild("img_plus")
    -- self.m_imgPlus:setVisible(true)
    -- self.m_imgRight = self:findChild("img_right")
    -- self.m_imgRight:setVisible(false)
    self.m_btnCoin = self:findChild("btn_coin")
    self.m_btnCoin:setVisible(false)
    self.m_btnCard = self:findChild("btn_card")
    self.m_btnCard:setVisible(false)

    self.m_headLayer = self:findChild("layer_head")
    self.m_btnClick = self:findChild("btn_click")
    self:addClick(self.m_btnClick)
    self.m_btnClick:setSwallowTouches(false)
end

function InboxPage_send_chooseFriend_cell:updateUI(cellData, sendType)
    cellData = cellData or {}
    self.m_cellData = cellData

    -- 名字
    self.m_lbName:setString(cellData.p_name)
    -- self:updateLabelSize({label=self.m_lbName,sx=1,sy=1},245)
    util_wordSwing(self.m_lbName, 1, self.m_nameLayer, 2, 30, 2)

    -- 头像
    if cellData.p_facebookHead then
        self:startLoadFriendHead(cellData.p_facebookHead, cellData.p_facebookId, cellData.p_facebookHeadFrame)
    end

    -- self:initChoosed()

    self:updateState()
end

function InboxPage_send_chooseFriend_cell:updateState()
    local sendType = self.m_mainClass:getMainClass():getSendType()
    -- if self.m_isChoosed then
    --     self.m_imgPlus:setVisible(false)
    --     self.m_imgRight:setVisible(true)
    -- else
    --     self.m_imgPlus:setVisible(true)
    --     self.m_imgRight:setVisible(false)
    -- end
    local curBtn = nil
    if sendType == "CARD" then
        self.m_btnCoin:setVisible(false)
        self.m_btnCard:setVisible(true)
        curBtn = self.m_btnCard
    elseif sendType == "COIN" then
        self.m_btnCoin:setVisible(true)
        self.m_btnCard:setVisible(false)
        curBtn = self.m_btnCoin
    else
        return
    end

    if self.m_cellData.isSended then
        curBtn:setBright(false)
        self.m_btnClick:setTouchEnabled(false)
    else
        curBtn:setBright(true)
        local isReached = G_GetMgr(G_REF.Inbox):getFriendRunData():isSendReachedLimit(sendType)
        if isReached then
            -- 已送满
            self.m_btnClick:setTouchEnabled(false)
            curBtn:setBrightStyle(BRIGHT_NORMAL)
        else
            self.m_btnClick:setTouchEnabled(true)
            curBtn:setBrightStyle(BRIGHT_HIGHLIGHT)
        end
    end
end

function InboxPage_send_chooseFriend_cell:initChoosed()
    local isChoosed = false
    local chooseList = self.m_mainClass:getChoosed()
    for i = 1, #chooseList do
        if tonumber(chooseList[i]) == tonumber(self.m_cellData.p_udid) then
            isChoosed = true
        end
    end
    self.m_isChoosed = isChoosed
end

function InboxPage_send_chooseFriend_cell:getState()
    return self.m_isChoosed
end

function InboxPage_send_chooseFriend_cell:changeState(state)
    self.m_isChoosed = state
    self.m_mainClass:setChoosed(self.m_cellData.p_udid, state)
end

function InboxPage_send_chooseFriend_cell:getContentSize()
    return cc.size(427, 95)
end

-- 加载头像
function InboxPage_send_chooseFriend_cell:startLoadFriendHead(head, fbId, frameId)
    if self.m_isInitHead then
        return
    end
    self.m_isInitHead = true

    local nodeHead = self.m_headLayer
    local fbSize = nodeHead:getContentSize()

    -- 头像切图
    nodeHead:removeAllChildren()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, nil, fbSize)
    nodeHead:addChild(nodeAvatar)
    nodeAvatar:setPosition(fbSize.width * 0.5, fbSize.height * 0.5)
end

function InboxPage_send_chooseFriend_cell:canClick()
    -- if self.m_isChoosed == false then
    --     local chooseList = self.m_mainClass:getChoosed()
    --     local sendedList = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendRecordList()
    --     local sendLimit = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendLimit()
    --     local sendType = self.m_mainClass:getMainClass():getSendType()

    --     if #chooseList >= sendLimit[sendType] - #sendedList[sendType] then
    --         return false
    --     end
    -- end
    if self.m_cellData.isSended then
        return false
    end

    return true
end

function InboxPage_send_chooseFriend_cell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_click" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self:canClick() then
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_SEND_CHOOSEFRIEND_CELL_UPDATE_STATE, self.m_index)
            self:changeState(true)
            local sendType = self.m_mainClass:getMainClass():getSendType()
            if sendType == "CARD" then
                self.m_mainClass:showChooseChips()
            else
                self.m_mainClass:FBMail_sendCoin(self.m_index)
            end
        end
    end
end

function InboxPage_send_chooseFriend_cell:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, index)
            if tolua.isnull(self) then
                return
            end
            if self.m_scrollview then
                if self.m_scrollview:getChoiceType() == "SINGLE" then
                    if self.m_index == index then
                        local state = self:getState()
                        self:changeState(not state)
                        self:updateState()
                    else
                        local state = self:getState()
                        if state == true then
                            self:changeState(false)
                            self:updateState()
                        end
                    end
                elseif self.m_scrollview:getChoiceType() == "MULTI" then
                    if self.m_index == index then
                        local state = self:getState()
                        self:changeState(not state)
                        self:updateState()
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_INBOX_SEND_CHOOSEFRIEND_CELL_UPDATE_STATE
    )
end

function InboxPage_send_chooseFriend_cell:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return InboxPage_send_chooseFriend_cell
