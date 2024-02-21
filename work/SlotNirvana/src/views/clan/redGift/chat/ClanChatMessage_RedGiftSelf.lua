--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-12 15:32:11
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-12 15:38:17
FilePath:/SlotNirvana/src/views/clan/redGift/chat/ClanChatMessage_RedGiftSelf.lua
Description: 公会红包 聊天消息 自己发送的
--]]
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ChatConfig = util_require("data.clanData.ChatConfig")
local ClanChatMessage_RedGiftSelf = class("ClanChatMessage_RedGiftSelf", BaseView)

function ClanChatMessage_RedGiftSelf:setData(_data)
    self.m_data = _data
    self.m_msgInfo = {}
    local content = self.m_data.content or "{}"
    if #content > 2 then
        self.m_msgInfo = cjson.decode(content)
    end

    self.m_bMe = self.m_data and self.m_data.sender == globalData.userRunData.userUdid or false
end

function ClanChatMessage_RedGiftSelf:updateUI()
    self:updateColCountUI()
end

function ClanChatMessage_RedGiftSelf:getCsbName()
    return "Club/csd/Gift/Gift_chat_self.csb"
end

function ClanChatMessage_RedGiftSelf:initCsbNodes()
    self.m_spHead = self:findChild("sp_head") -- 头像
    self.m_lbName = self:findChild("lb_name") -- 名字title
    self.m_lbTime = self:findChild("lb_time") --消息倒计时
    self.m_spBox = self:findChild("sp_box") -- 宝箱

    local spBubble = self:findChild("sp_qipao")
    self.m_bubbleContentSize = spBubble:getContentSize()
end

function ClanChatMessage_RedGiftSelf:initUI( _data )
    self:setData(_data)
    ClanChatMessage_RedGiftSelf.super.initUI(self)
    self:initContentUI()

    if self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
        gLobalNoticManager:addObserver(self,function(self, data)
            if data.msgId == self.m_data.msgId then
                self.m_data.status = 1
                self:setData(data)
                self:updateUI()
            end
        end,ChatConfig.EVENT_NAME.NOTIFY_REFRESH_RED_GIFT_CHAT)
    end
end

function ClanChatMessage_RedGiftSelf:initContentUI()
    -- 头像框
    self:initUserHeadUI()
    -- 名字`s Gift
    self:initTitleUI()
    -- 宝箱
    self:initBoxUI()
    -- 领取人数刷新
    self:updateColCountUI()
end

-- 头像框
function ClanChatMessage_RedGiftSelf:initUserHeadUI()
    local fbId = self.m_data.facebookId
    local head = self.m_bMe and globalData.userRunData.HeadName or self.m_data.head
    local frameId = self.m_bMe and globalData.userRunData.avatarFrameId or self.m_data.frameId
    self.m_spHead:removeAllChildren()
    local headSize = self.m_spHead:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, "", headSize)
    self.m_spHead:addChild(nodeAvatar)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
end

-- 名字`s Gift
function ClanChatMessage_RedGiftSelf:initTitleUI()
    local nickName = self.m_bMe and globalData.userRunData.nickName or self.m_data.nickname
    self.m_lbName:setString(nickName .. "'s Gift")

    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbName, 380, 1)
end

-- 宝箱
function ClanChatMessage_RedGiftSelf:initBoxUI()
    local boxIdx = (self.m_msgInfo.gearIndex or 0) + 1
    local iconPath = string.format("Club/ui_new/Gift/Gift_Icon/Gift_icon_close_%s.png", boxIdx)
    util_changeTexture(self.m_spBox, iconPath)
end

-- 领取人数刷新
function ClanChatMessage_RedGiftSelf:updateColCountUI()
    local colCount = self.m_msgInfo.collectedCount or 0
    local tolCount  = self.m_msgInfo.totalCount or 0

    local lbCount = self:findChild("lb_count")
    lbCount:setString(colCount .. "/" .. tolCount)
end

function ClanChatMessage_RedGiftSelf:onEnter()
    self:updateLeftTime()
end

function ClanChatMessage_RedGiftSelf:updateLeftTime()
    if self.m_data.effecTime and self.m_data.effecTime > 0 then
        local left_time = util_getLeftTime(self.m_data.effecTime)
        if left_time < 0 then
            left_time = 0
        end
      
        self.m_bUpdateUISec = left_time > 0
        self.m_lbTime:setString(util_count_down_str(left_time))
    end
end

-- 子类从写 定时器一秒调用一次
function ClanChatMessage_RedGiftSelf:updateUISec()
    if not self.m_bUpdateUISec then
        return
    end

    self:updateLeftTime()
end

function ClanChatMessage_RedGiftSelf:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_head" then
        -- 查看玩家信息
        G_GetMgr(G_REF.UserInfo):showMainLayer()
    elseif name == "btn_view" then
        -- 查看 领取详情
        if self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
            ClanManager:sendTeamRedGiftCollectRecord(self.m_data.msgId, self.m_data.extra.randomSign, self.m_msgInfo.type)
        end
    end
end

function ClanChatMessage_RedGiftSelf:isMyMessage()
    return self.m_bMe
end

function ClanChatMessage_RedGiftSelf:getMessageId()
    return self.m_data.msgId
end

function ClanChatMessage_RedGiftSelf:getContentSize()
    return self.m_bubbleContentSize
end

return ClanChatMessage_RedGiftSelf