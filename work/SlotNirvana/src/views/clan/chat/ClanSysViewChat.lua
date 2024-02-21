--[[
Author: cxc
Date: 2021-02-03 14:22:21
LastEditTime: 2021-07-23 20:30:30
LastEditors: Please set LastEditors
Description: 公会聊天界面
FilePath: /SlotNirvana/src/views.clan.chat.ClanSysViewChat.lua
--]]
local ClanSysViewChat = class("ClanSysViewChat", util_require("base.BaseView"))
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ChatConfig = util_require("data.clanData.ChatConfig")
local ChatManager = util_require("manager.System.ChatManager"):getInstance()
local SensitiveWordParser = util_require("utils.sensitive.SensitiveWordParser")

local CHAT_TAG = ChatConfig.NOTICE_TYPE

local offset2Edge = 30

-- 直接断线了不是重连隔10秒检测下
local CHAT_TCP_CLOSED_RE_CONNECT_TIME = 10

--连续5条消息10秒cd后再发
local CHAT_CD_MACRO_INFO = {
    limitCount = 5, -- 限制5条
    cd = 10, -- 10sCD后才能发
    interval = 2 -- 每条间隔两秒
}

function ClanSysViewChat:initUI()
    local csbName = "Club/csd/Chat_New/ClubWall_chat.csb"
    if ClanManager:checkRedGiftOpen() then
        -- 公会红包开启
        csbName = "Club/csd/Chat_New/ClubWall_chat_with_gift.csb"
    end
    self:createCsbNode(csbName)

    self.m_tagViewList = {}
    self.m_chatTag = CHAT_TAG.COMMON

    self.m_selfChatCountPre = 0 -- 连续两秒内发的消息个数
    self.m_selfChatCountCur = 0 -- 连续两秒内发的消息个数
    self.m_selfChatCountSub = 0
    self.m_chatCD = 0

    self.m_bRecieveNewMessage = false
    self.m_bJumpToAllTag = false

    self.m_reConnectIdx = 0
    self.m_preState = 0

    self:initView()

    self.m_updateScheduler = schedule(self, handler(self, self.onUpdate), 1)
    self:updateChatMaskVisible()
end

function ClanSysViewChat:initView()
    local chatList_all = self:findChild("chatList_all") -- 公共聊天页
    chatList_all:setScrollBarEnabled(false)
    chatList_all:setVisible(false)
    -- chatList_all:onScroll(handler(self, self.onScrollEvt))

    local chatList_chat = self:findChild("chatList_chat") -- 纯聊天表情页
    chatList_chat:setScrollBarEnabled(false)
    chatList_chat:setVisible(false)
    -- chatList_chat:onScroll(handler(self, self.onScrollEvt))

    local chatList_chips = self:findChild("chatList_chips") -- 卡牌交流页
    chatList_chips:setScrollBarEnabled(false)
    chatList_chips:setVisible(false)
    -- chatList_chips:onScroll(handler(self, self.onScrollEvt))

    local chatList_gifts = self:findChild("chatList_gifts") -- 奖励领取页
    chatList_gifts:setScrollBarEnabled(false)
    chatList_gifts:setVisible(false)
    -- chatList_gifts:onScroll(handler(self, self.onScrollEvt))

    self.chat_list = {
        [CHAT_TAG.COMMON] = chatList_all,
        [CHAT_TAG.CHAT] = chatList_chat,
        [CHAT_TAG.CHIPS] = chatList_chips,
        [CHAT_TAG.GIFT] = chatList_gifts
    }

    local textFieldMessage = self:findChild("TextField_word")
    local spPlaceHolder = self:findChild("sp_typeword")
    if device.platform == "android" or device.platform == "ios" then
        self.m_eboxMessage =
            util_convertTextFiledToEditBox(
            textFieldMessage,
            nil,
            function(strEventName, pSender)
                if strEventName == "began" then
                    self:switchEmojiUIVisible(false)
                    spPlaceHolder:setVisible(false)
                    self.m_eboxMessage.bFirstResponder = true
                elseif strEventName == "changed" or strEventName == "return" then
                    local str = self.m_eboxMessage:getText()
                    -- str = string.gsub(str, "[^%w^%p^%s]", "")
                    if strEventName == "return" and string.find(str, "^%s+$") then
                        str = "" -- 全是空格置空
                    end

                    self.m_eboxMessage:setText(str)
                    spPlaceHolder:setVisible(#str <= 0)
                    if strEventName == "return" then
                        performWithDelay(self.m_eboxMessage, function()
                            self.m_eboxMessage.bFirstResponder = false
                        end, 0)
                    end
                elseif string.find(strEventName, "keyboradMove") then
                    -- util_keyboardChangeMove(duration, distance)
                    if not GD.KeyBoardChangeFrameInfo or not self.m_eboxMessage.bFirstResponder then
                        return
                    end

                    local duration = KeyBoardChangeFrameInfo["duration"]
                    local beginRect = KeyBoardChangeFrameInfo["begin"]
                    local endRect = KeyBoardChangeFrameInfo["end"]
                    local keyboardCocosPosY = display.height - KeyBoardChangeFrameInfo["end"].y --(AnchorPoint(0,1))
                    if  math.abs(display.width - endRect.width) > 10 then
                        -- 正常 to 分屏   0  （0 0 0 0） -》 （0 641 1024 271）
                        util_keyboardChangeMove(duration, -keyboardCocosPosY, gLobalViewManager:getViewLayer())
                    elseif math.abs(keyboardCocosPosY - KeyBoardChangeFrameInfo["end"].height) > 10 then
                        -- 键盘高度 大于它的实际高度， 底部会空显示黑屏
                        util_keyboardChangeMove(duration, -keyboardCocosPosY, gLobalViewManager:getViewLayer())
                    else
                        local marginBottom = 10
                        local senderPosYW = self.m_senderPosYW or -marginBottom
                        util_keyboardChangeMove(duration, (keyboardCocosPosY - senderPosYW + 10), gLobalViewManager:getViewLayer())
                    end
                end
            end
        )
    else
        self.m_eboxMessage = textFieldMessage
        self.m_eboxMessage:addEventListener(
            function(sender, eventType)
                local event = {}
                if eventType == 0 then
                    -- touch
                    self:switchEmojiUIVisible(false)
                    spPlaceHolder:setVisible(false)
                elseif eventType == 1 or eventType == 2 or eventType == 3 then
                    local str = self.m_eboxMessage:getString()
                    -- str = string.gsub(str, "[^%w^%p^%s]", "")
                    if eventType == 1 and string.find(str, "^%s+$") then
                        -- DETACH_WITH_IME
                        str = "" -- 全是空格置空
                    end

                    self.m_eboxMessage:setString(str)
                    spPlaceHolder:setVisible(#str <= 0)
                end
            end
        )
    end

    -- 要卡
    self.m_nodeReqChip = self:findChild("node_chipwanted") -- 送卡按钮
    self.font_timeBg = self:findChild("sp_shijiankuang") -- 要卡倒计时背景框
    self.font_time = self:findChild("font_time") -- 要卡倒计时
    local nodeChipNovice = self:findChild("node_chipNovice")
    local bCardNovice = CardSysManager:isNovice()
    if bCardNovice then
        self.font_timeBg:setVisible(false)
        self.m_nodeReqChip:setVisible(true)
        self:setButtonLabelDisEnabled("btn_chipwanted", false)
        nodeChipNovice:setVisible(true)
    else
        self:updateTimer()
        nodeChipNovice:setVisible(false)
    end

    -- 聊天cd
    local nodeNormal = self:findChild("node_chatCd")
    local nodeEmoji = self:findChild("node_emojiCd")
    nodeNormal:setVisible(false)
    nodeEmoji:setVisible(false)

    -- 一键领取所有奖励view
    self:initCollectAllView()

    -- tcp提示蒙版
    self.m_tcpMask = self:findChild("chat_mask")
    self.m_tcpMask:setLocalZOrder(2) -- 放的高一点
    self.m_lbTcpStateTip = self:findChild("lb_tcpStateTip")
end

-- 要卡气泡提示
function ClanSysViewChat:initCardBubbleTip()
    local view = gLobalViewManager:getViewByExtendData("ClanHomeView")
    local refNode = self:findChild("node_cardBubbleTip")
    if not view then
        view = refNode
    end
    local cardBubbleTip = util_createView("views.clan.chat.ClanChatCardBubbleTip")
    local posW = refNode:convertToWorldSpace(cc.p(0, 0))
    local posL = view:convertToNodeSpace(posW)
    view:addChild(cardBubbleTip)
    cardBubbleTip:setPosition(posL)
    self.m_cardBubbleTip = cardBubbleTip -- 要卡气泡
end

-- 表情框
function ClanSysViewChat:initEmojiView()
    local view = gLobalViewManager:getViewByExtendData("ClanHomeView")
    local nodeEmoji = self:findChild("node_emoji")
    if not view then
        view = nodeEmoji
    end
    local emojiView = util_createView("views.clan.chat.ClanChatEmojiView")
    local posW = nodeEmoji:convertToWorldSpace(cc.p(0, 0))
    local posL = view:convertToNodeSpace(posW)
    view:addChild(emojiView)
    emojiView:setPosition(posL)
    self.emojiList = emojiView -- 表情背景框
end

-- 一键领取所有奖励view
function ClanSysViewChat:initCollectAllView()
    local layouCollectAll = self:findChild("layout_collectAll")
    self.m_collectAllView = util_createView("views.clan.chat.ClanChatCollectAllView")
    self.m_collectAllView:addTo(layouCollectAll)
    self.m_collectAllView:setPositionX(layouCollectAll:getContentSize().width * 0.5)
end

function ClanSysViewChat:updateUI(_tag)
    _tag = _tag or self.m_chatTag or CHAT_TAG.COMMON
    self:updateBtnEntryState(_tag)

    for _type, chat_listNode in pairs(self.chat_list) do
        chat_listNode:setVisible(_type == _tag)
    end
    self:resetChatList(_tag)

    self:dealCollectAllView()
end

function ClanSysViewChat:updateTimer()
    local time_left = 0
    local cardCd = ClanManager:getReqCardCD() -- CardSysRuntimeMgr:getAskCD()    -- 从卡牌系统获取请求倒计时
    if cardCd and cardCd > 0 then
        time_left = util_getLeftTime(cardCd)
    end
    if time_left <= 0 then
        self.font_timeBg:setVisible(false)
        self.m_nodeReqChip:setVisible(true)
        self.font_time:setString("")
        if self.timerSchedule then
            self:stopAction(self.timerSchedule)
            self.timerSchedule = nil
        end
        self:checkShowCardBubbleTip()
    else
        self.font_timeBg:setVisible(true)
        self.m_nodeReqChip:setVisible(false)
        self.font_time:setString(util_count_down_str(time_left))
        if not self.timerSchedule then
            self.timerSchedule =
                util_schedule(
                self,
                function()
                    self:updateTimer()
                end,
                1
            )
        end
    end
end

-- 更新 tag按钮 显隐状态
function ClanSysViewChat:updateBtnEntryState(_tag)
    local btnAll = self:findChild("btn_all") -- 所有聊天信息
    local btnChips = self:findChild("btn_chips") -- 赠送索要的卡片信息
    local btnGifts = self:findChild("btn_gifts") -- 大奖红包
    local btnChat = self:findChild("btn_chat")

    btnAll:setEnabled(_tag ~= CHAT_TAG.COMMON)
    btnChips:setEnabled(_tag ~= CHAT_TAG.CHIPS)
    btnGifts:setEnabled(_tag ~= CHAT_TAG.GIFT)
    btnChat:setEnabled(_tag ~= CHAT_TAG.CHAT)

    self.m_chatTag = _tag
    ChatManager:recordCurChatTag(_tag)
end

-- 处理 一键收集显示view
function ClanSysViewChat:dealCollectAllView()
    if not self.m_collectAllView then
        return
    end

    local msgIdList, randomSignList = ChatManager:getFastCollectGiftMsgIdAndSign()
    local bCan = #msgIdList > 0
    self.m_collectAllView:setLbCollectAllStr(#msgIdList)
    local bVisible = self.m_collectAllView:isVisible()
    if (not bCan and not bVisible) or (not bVisible and self.m_chatTag ~= CHAT_TAG.COMMON and self.m_chatTag ~= CHAT_TAG.GIFT) then
        -- 没显示不可领取 不处理
        -- 没显示 chat 合 card 俩页签页不处理 不显示它
        return
    end

    if bVisible and (not bCan or (self.m_chatTag ~= CHAT_TAG.COMMON and self.m_chatTag ~= CHAT_TAG.GIFT)) then
        -- 显示着 不能领了或者切到 chat合card 页签了 隐藏它
        self.m_collectAllView:playHideAct()
        return
    end

    if bVisible and not self.m_collectAllView:isActing() then
        -- 显示的情况下 没动画不用处理
        return
    end

    -- 是否有
    self.m_collectAllView:updateUI()
    self.m_collectAllView:playShowAct()
end

-- 切换表情 UI 显隐
function ClanSysViewChat:switchEmojiUIVisible(_visible)
    if tolua.isnull(self.emojiList) then
        return
    end

    local curVisible = self.emojiList:isVisible()
    if curVisible == _visible and _visible == false then
        return
    end

    if _visible ~= nil and _visible ~= curVisible then
        self.emojiList:switchViewVisible(_visible)
        return
    end

    self.emojiList:switchViewVisible(not curVisible)
end

-- 聊天tcp链接情况显隐
-- ChatConfig.TCP_STATE = {
--     CLOSE = 1, -- 未连接
--     CONNECTING = 2, -- 链接中
--     RE_CONNECTING = 3, -- 重连中
-- }
function ClanSysViewChat:updateChatMaskVisible()
    self.m_reConnectIdx = self.m_reConnectIdx + 1
    local curState = ChatManager:getSocketState()
    if self.m_preState == ChatConfig.TCP_STATE.RE_CONNECTING and self.m_preState~=curState then
        -- soket 重连结果报送
        ChatManager:reConnectSplunkLog(curState == ChatConfig.TCP_STATE.CONNECTING and 1 or 2)
    end
    if curState == self.m_preState then
        if curState == ChatConfig.TCP_STATE.RE_CONNECTING then
            local endStr = string.sub("...", 1, self.m_reConnectIdx % 4)
            self.m_lbTcpStateTip:setString(ChatConfig.TCP_TIP_STR.RE_CONNECTING .. endStr)
        end

        -- if curState == ChatConfig.TCP_STATE.CLOSED and self.m_reConnectIdx % CHAT_TCP_CLOSED_RE_CONNECT_TIME == 0 then
        --     ChatManager:getInstance():onOpen()
        -- end

        return
    end
    self.m_preState = curState

    local bShow = curState == ChatConfig.TCP_STATE.RE_CONNECTING
    self.m_tcpMask:setVisible(false) -- 2023年08月07日15:12:46 蒙版不显示了
    if not bShow then
        return
    end

    local tipStr = ""
    if curState == ChatConfig.TCP_STATE.RE_CONNECTING then
        self.m_reConnectIdx = 1
        tipStr = ChatConfig.TCP_TIP_STR.RE_CONNECTING
    elseif curState == ChatConfig.TCP_STATE.CLOSED then
        tipStr = ChatConfig.TCP_TIP_STR.CLOSED
    end
    self.m_lbTcpStateTip:setString(tipStr)
end

function ClanSysViewChat:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_all" then
        self:updateUI(CHAT_TAG.COMMON)
    elseif name == "btn_chat" then
        self:updateUI(CHAT_TAG.CHAT)
    elseif name == "btn_chips" then
        self:updateUI(CHAT_TAG.CHIPS)
    elseif name == "btn_gifts" then
        self:updateUI(CHAT_TAG.GIFT)
    elseif name == "btn_send" then
        if self.m_selfChatCountSub >= CHAT_CD_MACRO_INFO.limitCount then
            self:updateChatCDLableUI()
            self:switchChatCDBubbleVisible("node_chatCd")
            return
        end

        -- 发送普通消息
        local content
        if device.platform == "android" or device.platform == "ios" then
            content = self.m_eboxMessage:getText()
        else
            content = self.m_eboxMessage:getString()
        end
        if not content or string.len(content) <= 0 then
            return
        end
        self:senderMessage(ChatConfig.MESSAGE_TYPE.TEXT, 1, content)
        if device.platform == "android" or device.platform == "ios" then
            self.m_eboxMessage:setText("")
        else
            self.m_eboxMessage:setString("")
        end
        local spPlaceHolder = self:findChild("sp_typeword")
        spPlaceHolder:setVisible(true)
    elseif name == "btn_biaoqing" then
        if self.m_selfChatCountSub >= CHAT_CD_MACRO_INFO.limitCount then
            self:updateChatCDLableUI()
            self:switchChatCDBubbleVisible("node_emojiCd")
            return
        end

        -- 表情框显隐
        self:switchEmojiUIVisible()
    elseif name == "btn_chipwanted" then
        -- 跳转卡牌系统
        if CardSysManager:isDownLoadCardRes() then
            CardSysRuntimeMgr:setIgnoreWild(true)
            CardSysManager:enterCardCollectionSys()
        end
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLOSE_CLAN_GUIDE_LAYER) -- 关闭引导界面事件
        -- test 要卡
        -- ClanManager:requestCardNeeded("202101", "21010603")
    elseif name == "btn_chipNovice" and not tolua.isnull(self.m_cardBubbleTip) then
        if self.m_cardBubbleTip:isVisible() then
            self.m_cardBubbleTip:hideBubbleTip()
        else
            self.m_cardBubbleTip:showBubbleTip()
        end
    elseif name == "btn_redGift" then
        -- 公会红包
        ClanManager:sendTeamRedGiftInfo()
    end
end

-- 发送聊天消息
function ClanSysViewChat:senderMessage(_sendType, _childType, content)
    -- 把纯文本和表情类型拆分开 其实玩家是可以通过手动输入来发送自己想要的表情的
    if _childType == 1 then
        -- 纯文本
        local message = SensitiveWordParser:getString(content, "?")
        ChatManager:sendChat(message, _sendType)
    elseif _childType == 2 then
        -- 表情
        ChatManager:sendChat(content, _sendType)
    end

    self.m_selfChatCountCur = self.m_selfChatCountCur + 1
end

function ClanSysViewChat:dealChatCD()    
    -- 10 秒结束可以点击了
    if self.m_chatCD >= CHAT_CD_MACRO_INFO.cd then
        self.m_selfChatCountCur = 0
        self.m_selfChatCountPre = 0
        self.m_selfChatCountSub = 0
        self:updateChatCDLableUI()
        self.m_chatCD = 0
        return
    end

    self.m_chatCD = self.m_chatCD + 1
    -- 连续发了 5条就不能发了 10CD
    if self.m_selfChatCountSub >= CHAT_CD_MACRO_INFO.limitCount then
        self:updateChatCDLableUI()
        return
    end

    -- 每条间隔两秒
    if self.m_chatCD < CHAT_CD_MACRO_INFO.interval then
        return
    end
    self.m_chatCD = 0

    local sub = self.m_selfChatCountCur - self.m_selfChatCountPre
    -- 两秒内都没发 清空记录
    if sub == self.m_selfChatCountSub then
        self.m_selfChatCountCur = 0
        self.m_selfChatCountPre = 0
        self.m_selfChatCountSub = 0
        return
    end

    -- 记录 连续发了几条
    self.m_selfChatCountSub = sub
end

-- 处理聊天消息的 cd
function ClanSysViewChat:dealChildChatCellCD()

    for _type, listView in pairs(self.chat_list) do
        local cellNodeList = listView:getItems()
        for i, layout in ipairs(cellNodeList) do
            if layout and layout["updateUISec"] then
                layout:updateUISec()
            end
        end
    end

end

-- 更新cd节点
function ClanSysViewChat:updateChatCDLableUI()
    local leftSec = CHAT_CD_MACRO_INFO.cd - self.m_chatCD

    local nodeNormal = self:findChild("node_chatCd")
    local lbCDNormal = nodeNormal:getChildByName("lb_cd")
    lbCDNormal:setString(leftSec .. "S")

    local nodeEmoji = self:findChild("node_emojiCd")
    local lbCDEmoji = nodeEmoji:getChildByName("lb_cd")
    lbCDEmoji:setString(leftSec .. "S")

    if leftSec <= 0 then
        nodeNormal:setVisible(false)
        nodeEmoji:setVisible(false)
    end
end

-- 切换 聊天气泡显隐
function ClanSysViewChat:switchChatCDBubbleVisible(_nodeName)
    local node = self:findChild(_nodeName)
    if not node then
        return
    end

    local bPreVisible = node:isVisible()
    if not bPreVisible then
        performWithDelay(
            node,
            function()
                node:setVisible(false)
            end,
            2
        )
    else
        node:stopAllActions()
    end

    node:setVisible(not bPreVisible)
end

function ClanSysViewChat:getItemFromList(_list, _msgId)
    if not _list then
        return
    end
    local items = _list:getItems()
    for k, item in pairs(items) do
        if item.content then
            if not item.content.getMessageId then
                local data = item.content:getData()
                dump(data, "消息内容", 5)
                assert("消息缺失必要的方法 getMessageId")
            elseif item.content:getMessageId() == _msgId then
                return items[k]
            end
        end
    end
end

function ClanSysViewChat:resetChatList(_type)
    if not self:getParent():isVisible() then
        return
    end

    ChatManager:clearMsgList()

    local chatDatas = ChatManager:getChatData()
    local list_node, chat_list, nodeLimitCount
    if _type == ChatConfig.NOTICE_TYPE.COMMON then
        list_node = self.chat_list[CHAT_TAG.COMMON]
        chat_list = chatDatas:getCommonChatList()
        nodeLimitCount = ChatConfig.MESSAGE_LIMIT_ENUM.ALL
    elseif _type == ChatConfig.NOTICE_TYPE.CHAT then
        list_node = self.chat_list[CHAT_TAG.CHAT]
        chat_list = chatDatas:getTextChatList()
        nodeLimitCount = ChatConfig.MESSAGE_LIMIT_ENUM.CHAT
    elseif _type == ChatConfig.NOTICE_TYPE.CHIPS then
        list_node = self.chat_list[CHAT_TAG.CHIPS]
        chat_list = chatDatas:getChipsChatList()
        nodeLimitCount = ChatConfig.MESSAGE_LIMIT_ENUM.CHIPS
    elseif _type == ChatConfig.NOTICE_TYPE.GIFT then
        list_node = self.chat_list[CHAT_TAG.GIFT]
        chat_list = chatDatas:getGiftChatList()
        nodeLimitCount = ChatConfig.MESSAGE_LIMIT_ENUM.GIFT
    end

    -- 需要刷新卡牌数量
    if _type == ChatConfig.NOTICE_TYPE.COMMON or _type == ChatConfig.NOTICE_TYPE.CHIPS then
        local chip_list = chatDatas:getChipsChatList()
        self:refreshChipsData(chip_list)
    end
    if list_node and nodeLimitCount then
        self:deleteOverItemNode(list_node, nodeLimitCount)
    end
    self:refreshChatByStep(list_node, chat_list, _type)
    -- self:refreshChatOnce(list_node, chat_list, _type)
end

-- 一次性加载
function ClanSysViewChat:refreshChatOnce(list_node, chat_list, _type)
    local width = list_node:getContentSize().width
    for _, chat_data in pairs(chat_list) do
        local item = self:getItemFromList(list_node, chat_data.msgId)
        if item and item.content then
            item.content:setData(chat_data)
            item.content:updateUI()
            local itemSize = item.content:getContentSize()
            item:setContentSize({width = width, height = itemSize.height})
        else
            local chatItem = self:createChatItem(chat_data, width, _type)
            if chatItem then
                list_node:pushBackCustomItem(chatItem)
            else
                printInfo("聊天信息创建失败 消息id：" .. chat_data.msgId or "" .. " 类型 ：" .. _type)
            end
        end
    end
    list_node:jumpToBottom()
end

-- 分帧加载
function ClanSysViewChat:refreshChatByStep(list_node, chat_list, _type)
    if tolua.isnull(list_node) then
        return
    end

    local width = list_node:getContentSize().width

    local max_length = table.nums(chat_list)
    local item_idx = max_length -- 倒序加载 用户看不出来
    local step_length = 5 -- 一次加载几个

    -- 标记已有列表边界 只在已有列表的底部插入 应对新增消息插入到最顶部的问题
    local items = list_node:getItems()
    local start_idx = table.nums(items)
    local refresh = function(_target, _bFist)
        for i = 0, step_length - 1 do
            if item_idx - i < 1 then
                self:clearScheduler()

                item_idx = item_idx - i
                list_node:jumpToBottom()

                if self.m_bRecieveNewMessage and self.m_bJumpToAllTag then
                    self:updateBtnEntryState(CHAT_TAG.COMMON)
                    for _type, chat_listNode in pairs(self.chat_list) do
                        chat_listNode:setVisible(_type == CHAT_TAG.COMMON)
                    end
                end
                self.m_bJumpToAllTag = false
                self.m_bRecieveNewMessage = false
                break
            end

            local chat_data = chat_list[item_idx - i]
            if chat_data then
                local item = self:getItemFromList(list_node, chat_data.msgId)
                if item and item.content then
                    item.content:setData(chat_data)
                    item.content:updateUI()
                    local itemSize = item.content:getContentSize()
                    item:setContentSize({width = width, height = itemSize.height})
                else
                    local chatItem = self:createChatItem(chat_data, width, _type)
                    if chatItem then
                        local idx = _bFist and start_idx or 0
                        list_node:insertCustomItem(chatItem, idx)
                    else
                        local msgId = chat_data.msgId or ""
                        local msgType = chat_data.messageType or ""
                        printInfo("聊天信息创建失败 消息id：" .. msgId .. " 类型 ：" .. msgType)
                    end
                end
            end
        end
        item_idx = item_idx - step_length
        list_node:jumpToBottom()
    end

    -- 先加载一次
    refresh(self, true)
    -- 一次加载不完 就分帧加载
    if item_idx > 1 then
        self:clearScheduler()
        self.m_createCellHandler = util_schedule(self, refresh, 2 / 60)
    end
end

function ClanSysViewChat:createChatItem(data, width, _type)
    if not data or not next(data) then
        return
    end

    local msgItem = self:createChatContent(data, _type)
    if not msgItem then
        return
    end

    local layout = ccui.Layout:create()
    layout:addChild(msgItem)
    layout.content = msgItem
    -- layout.checkSelfVisible = function(item, listView)
    --     local posSelf = item:convertToWorldSpace(cc.p(0, 0))
    --     local posParent = listView:convertToWorldSpace(cc.p(0, 0))
    --     local sizeSelf = item:getContentSize()
    --     local sizeParent = listView:getContentSize()
    --     local bVisible = cc.rectIntersectsRect(cc.rect(posParent.x, posParent.y, sizeParent.width, sizeParent.height), cc.rect(posSelf.x, posSelf.y, sizeSelf.width, sizeSelf.height))
    --     item:setVisible(bVisible)
    -- end
    layout.updateUISec = function(target)
        if tolua.isnull(target.content) or (not target.content["updateUISec"]) then
            return
        end

        target.content:updateUISec()
    end

    local itemSize = msgItem:getContentSize()
    layout:setContentSize({width = width, height = itemSize.height})
    if not msgItem.isMyMessage then
        -- 没有偏向 居中显示
        msgItem:setPosition(width / 2, itemSize.height / 2)
    else
        if msgItem:isMyMessage() then
            local edge_posx = width -- 边界位置
            msgItem:setPosition(edge_posx - offset2Edge, itemSize.height)
        else
            local edge_posx = 0 -- 边界位置
            msgItem:setPosition(edge_posx + offset2Edge, itemSize.height)
        end
    end

    return layout
end

function ClanSysViewChat:createChatContent(data, _type)
    local chat_cell
    if data.messageType == ChatConfig.MESSAGE_TYPE.TEXT then
        if self:isMyMessage(data) and self.m_chatTag ~= CHAT_TAG.COMMON and self.m_chatTag ~= CHAT_TAG.CHAT then
            self.m_bJumpToAllTag = true
        end
        -- 普通文字&表情消息
        chat_cell = util_createView("views.clan.chat.ClanChatMessage_word", data)
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.JACKPOT then
        -- jackpot大奖
        if self:isMyMessage(data) then
            chat_cell = util_createView("views.clan.chat.ClanChatMessage_system", data)
        else
            chat_cell = util_createView("views.clan.chat.ClanChatMessage_reward", data)
        end
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.CARD_CLAN then
        -- 卡册集齐
        if self:isMyMessage(data) then
            chat_cell = util_createView("views.clan.chat.ClanChatMessage_system", data)
        else
            chat_cell = util_createView("views.clan.chat.ClanChatMessage_chipsRewards", data)
        end
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.CASHBONUS_JACKPOT then
        -- 每日转盘中jackpot
        if self:isMyMessage(data) then
            chat_cell = util_createView("views.clan.chat.ClanChatMessage_system", data)
        else
            chat_cell = util_createView("views.clan.chat.ClanChatMessage_reward", data)
        end
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.PURCHASE then
        -- 充值
        if not self:isMyMessage(data) then
            chat_cell = util_createView("views.clan.chat.ClanChatMessage_purchase", data)
        else
            if _type == CHAT_TAG.COMMON or _type == CHAT_TAG.GIFT then
                chat_cell = util_createView("views.clan.chat.ClanChatMessage_system", data)
            end
        end
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.CLAN_CHALLENGE then
        -- 公会挑战
        -- chat_cell = util_createView("views.clan.chat.ClanChatMessage_word", data)
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.CLAN_MEMBER_CARD then
        if self:isMyMessage(data) then
            self.m_bJumpToAllTag = true
        end
        -- 公会内索求集卡
        chat_cell = util_createView("views.clan.chat.ClanChatMessage_chips", data)
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.SYSTEM then
        -- 系统消息
        chat_cell = util_createView("views.clan.chat.ClanChatMessage_system", data)
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.LOTTERY then
        -- 乐透奖励
        if self:isMyMessage(data) then
            chat_cell = util_createView("views.clan.chat.ClanChatMessage_system", data)
        else
            chat_cell = util_createView("views.clan.chat.ClanChatMessage_lotteryRewards", data)
        end
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.RANK_REWARD then
        -- 公会排行榜结算
        chat_cell = util_createView("views.clan.chat.ClanChatMesage_rankRewards", data)
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.RUSH_REWARD then
        -- 公会rush奖励
        chat_cell = util_createView("views.clan.chat.ClanChatMesage_rushRewards", data)
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.JACKPOT_SHARE then
        -- jackpot大奖分享
        if self:isMyMessage(data) then
            chat_cell =util_createView("views.clan.chat.ClanChatMesage_JackpotShareSelf", data)
        else
            chat_cell =util_createView("views.clan.chat.ClanChatMesage_JackpotShareRewards", data)
        end
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.AVATAR_FRAME then
        --头像框奖励
        if self:isMyMessage(data) then
            chat_cell = util_createView("views/clan/chat/ClanChatMessage_system", data)
        else
            chat_cell = util_createView("views/clan/chat/ClanChatMessage_FrameRewards", data)
        end
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.RED_PACKAGE then
        -- 红包
        if self:isMyMessage(data) then
            chat_cell = util_createView("views.clan.redGift.chat.ClanChatMessage_RedGiftSelf", data)
        else
            chat_cell = util_createView("views.clan.redGift.chat.ClanChatMessage_RedGiftOther", data)
        end
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.RED_PACKAGE_COLLECT then
        chat_cell = util_createView("views/clan/chat/ClanChatMessage_system", data)
    elseif data.messageType == ChatConfig.MESSAGE_TYPE.CLAN_DUEL then
        -- 公会对决奖励
        chat_cell = util_createView("views.clan.chat.ClanChatMesage_duelRewards", data)
    end

    if chat_cell then
        return chat_cell
    end
end

function ClanSysViewChat:refreshChipsData(chat_list)
    local cardIds = {}
    local isDirty = false
    for _, msgData in pairs(chat_list) do
        if string.len(msgData.content) > 0 then
            local chipData = cjson.decode(msgData.content)
            if chipData and chipData.card then
                local cardId = chipData.card.cardId
                if cardId then
                    local isExist = false
                    for _, _cardId in pairs(cardIds) do
                        if _cardId == cardId then
                            isExist = true
                            break
                        end
                    end
                    if not isExist then
                        table.insert(cardIds, cardId)
                        if ChatManager:getCardDataById(cardId) == nil then
                            isDirty = true
                        end
                    end
                end
            end
        end
    end

    -- 公会要卡送卡的逻辑
    -- 检索出公会中未知的卡牌信息 向服务器请求数据
    if table.nums(cardIds) and isDirty == true then
        ClanManager:requestCardsData(cardIds)
    end
end

function ClanSysViewChat:isMyMessage(data)
    if data and data.sender == globalData.userRunData.userUdid then
        return true
    end
    return false
end

-- 删除多余的节点 避免内存过高
function ClanSysViewChat:deleteOverItemNode(listView, nodeLimitCount)
    local curNodeCount = table.nums(listView:getItems())

    local subCount = curNodeCount - nodeLimitCount
    for i = 1, subCount do
        listView:removeItem(0)
    end
end

function ClanSysViewChat:onEnter()
    self:registerListener()

    -- 要卡 气泡提示
    self:initCardBubbleTip()
    -- 表情view
    self:initEmojiView()

    if self.m_eboxMessage then
        self.m_senderPosYW = self.m_eboxMessage:convertToWorldSpace(cc.p(0,0)).y
    end

    -- 置顶消息
    self:checkRefreshRedGiftTopUI()
    -- 引导逻辑
    performWithDelay(self, handler(self, self.dealGuideLogic), 0)
end

function ClanSysViewChat:onUpdate()
    self:dealChatCD()
    self:dealChildChatCellCD()
    self:updateChatMaskVisible()
    self:updateRedGiftTopUICD()
end

function ClanSysViewChat:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

-- 注册事件
function ClanSysViewChat:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            if param == self.m_chatTag or param == CHAT_TAG.COMMON then
                self:resetChatList(param)
            end
            self:dealCollectAllView()
            -- gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.NEW_CHAT_INFO)
        end,
        ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_SYNC_REFRESH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self.m_bRecieveNewMessage = true
            if not param then
                param = self.m_chatTag
            end
            self:resetChatList(param)
            if param == ChatConfig.NOTICE_TYPE.GIFT then
                self:dealCollectAllView()
            end
            if param == ChatConfig.NOTICE_TYPE.COMMON then
                gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.NEW_CHAT_INFO)
            end
        end,
        ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_ADD_NEW_REFRESH
    )

    -- 发送emoji
    gLobalNoticManager:addObserver(
        self,
        function(self, _idx)
            if not _idx then
                return
            end
            self:senderMessage(ChatConfig.MESSAGE_TYPE.TEXT, 2, "CustomizeEmoji_" .. _idx)
            self:switchEmojiUIVisible(false)
        end,
        ChatConfig.EVENT_NAME.CHAT_SEND_EMOJI_MESSAGE
    )

    -- 公会聊天发送要卡消息 成功
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:updateTimer()

            self:updateUI(CHAT_TAG.COMMON)
        end,
        ChatConfig.EVENT_NAME.CHAT_SEND_REQ_CARD_NEED
    )

    -- 更新一键领取View的显隐
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:dealCollectAllView()
        end,
        ChatConfig.EVENT_NAME.CHECK_FAST_COLLECT_VIEW_VISIBLE
    )

    -- 关闭公会
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            -- 清楚定时器
            if self.timerSchedule then
                self:stopAction(self.timerSchedule)
                self.timerSchedule = nil
            end

            if self.m_updateScheduler then
                self:stopAction(self.m_updateScheduler)
                self.m_updateScheduler = nil
            end

            self:clearScheduler()
        end,
        ClanConfig.EVENT_NAME.CLOSE_CLAN_HOME_VIEW
    )

    -- 接收到 公会红包 礼物信息
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            ClanManager:popSendGiftLayer()
        end,
        ClanConfig.
        EVENT_NAME.RECIEVE_TEAM_RED_GIFT_INFO_SUCCESS
    )

    -- 刷新红包置顶消息
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:checkRefreshRedGiftTopUI()
        end,
        ChatConfig.
        EVENT_NAME.NOTIFY_REFRESH_RED_GIFT_CHAT_TOP
    )

    -- 查看红包消息领取记录
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            if gLobalViewManager:getViewByExtendData("ClanRedGiftAutoCollectLayer") then
                return
            end

            ClanManager:popGiftCollectDetailLayer(param)
        end,
        ClanConfig.
        EVENT_NAME.RECIEVE_TEAM_RED_COLLECT_RECORD_SUCCESS
    )
end

-- 处理 引导逻辑
function ClanSysViewChat:dealGuideLogic()
    if tolua.isnull(self) then
        return
    end

    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.clanFirstEnterChat.id) -- 第一次进入公会主页
    if bFinish or self.m_tcpMask:isVisible() then
        -- 没连上 聊天服不要引导，没啥意义，还把引导节点层级弄高了
        return
    end

    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstEnterChat)
    -- globalData.NoviceGuideFinishList[#globalData.NoviceGuideFinishList + 1] = NOVICEGUIDE_ORDER.clanFirstEnterChat.id

    local nodeTotal = self.m_csbNode -- 整个聊天功能
    local btnChip = self:findChild("node_chipCard") -- 送卡按钮
    local guideNodeList = {nodeTotal, btnChip}
    ClanManager:showGuideLayer(NOVICEGUIDE_ORDER.clanFirstEnterChat.id, guideNodeList)
end

function ClanSysViewChat:checkShowCardBubbleTip()
    if tolua.isnull(self.m_cardBubbleTip) then
        return
    end

    local bHadPop = ClanManager:isHadPopCardTip()
    if bHadPop then
        return
    end

    local cardCd = ClanManager:getReqCardCD()
    ClanManager:setHadPopCardTip(cardCd)
    self.m_cardBubbleTip:showBubbleTip()
end

-- 清楚定时器
function ClanSysViewChat:clearScheduler()
    if self.m_createCellHandler then
        self:stopAction(self.m_createCellHandler)
        self.m_createCellHandler = nil
    end
end

-- 添加 listView滑动事件
function ClanSysViewChat:onScrollEvt(event)
    -- if event.name ~= "SCROLLING" and event.name ~= "CONTAINER_MOVED" then
    --     return
    -- end

    -- local children = event.target:getItems()
    -- for k, item in pairs(children) do
    --     if item["checkSelfVisible"] then
    --         item:checkSelfVisible(event.target)
    --     end
    -- end
end

-- 检查 刷新 置顶红包消息
function ClanSysViewChat:checkRefreshRedGiftTopUI()
    local chatDatas = ChatManager:getChatData()
    local topGiftData = chatDatas:getUnCollectRedGift()
    if not topGiftData then
        return
    end

    if not self.m_redGiftTopUI then
        local nodeTop = self:findChild("node_chatRedGiftTop")
        self.m_redGiftTopUI = util_createView("views.clan.redGift.chat.ClanChatMessageTopUI", topGiftData)
        nodeTop:addChild(self.m_redGiftTopUI)
        return
    end

    local bActing = self.m_redGiftTopUI:checkIsActing()
    if bActing then
        return
    end

    local showData = self.m_redGiftTopUI:getShowData()
    if showData and showData.msgId == topGiftData.msgId then
        return
    end

    self.m_redGiftTopUI:updateData(topGiftData)
    self.m_redGiftTopUI:updateUI()
end
function ClanSysViewChat:updateRedGiftTopUICD()
    if self.m_redGiftTopUI and self.m_redGiftTopUI:isVisible() then
        self.m_redGiftTopUI:updateUISec()
    end
end

return ClanSysViewChat
