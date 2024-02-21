--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-12 15:32:11
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-12 15:38:17
FilePath:/SlotNirvana/src/views/clan/redGift/chat/ClanChatMessage_RedGiftOther.lua
Description: 公会红包 聊天消息 接收的
--]]
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ChatManager = util_require("manager.System.ChatManager"):getInstance()
local ChatConfig = util_require("data.clanData.ChatConfig")
local ClanChatMessage_RedGiftOther = class("ClanChatMessage_RedGiftOther", BaseView)

function ClanChatMessage_RedGiftOther:setData(_data)
    self.m_data = _data
    self.m_msgInfo = {}
    local content = self.m_data.content or "{}"
    if #content > 2 then
        self.m_msgInfo = cjson.decode(content)
    end

    self.m_bMe = self.m_data and self.m_data.sender == globalData.userRunData.userUdid or false
end

function ClanChatMessage_RedGiftOther:updateUI()
    -- 赠送的金币价值
    self:updatePriceUI()
    self:updateColCountUI()
    self:updateState()
end

function ClanChatMessage_RedGiftOther:getCsbName()
    if self.m_msgInfo.type == "ALL" then
        return "Club/csd/Gift/Gift_chat_other_all.csb"
    end
    return "Club/csd/Gift/Gift_chat_other_assign.csb"
end

function ClanChatMessage_RedGiftOther:initCsbNodes()
    self.m_spHead = self:findChild("sp_head") -- 头像
    self.m_lbName = self:findChild("lb_name") -- 名字title
    self.m_lbPrice = self:findChild("lb_price") -- 赠送的金币价值
    self.m_lbTime = self:findChild("lb_time") --消息倒计时
    self.m_spBox = self:findChild("sp_box") -- 宝箱

    local btnCollect = self:findChild("btn_collect")
    btnCollect:setSwallowTouches(false)

    local spBubble = self:findChild("sp_qipao")
    self.m_bubbleContentSize = spBubble:getContentSize()
end

function ClanChatMessage_RedGiftOther:initUI( _data )
    self:setData(_data)
    ClanChatMessage_RedGiftOther.super.initUI(self)
    self:initContentUI()
    self:updateState()
end

function ClanChatMessage_RedGiftOther:initContentUI()
    self:updateLeftTime()

    -- 头像框
    self:initUserHeadUI()
    -- 名字`s Gift
    self:initTitleUI()
    -- 赠送的金币价值
    self:updatePriceUI()
    -- 宝箱
    self:initBoxUI()
    -- 领取人数刷新
    self:updateColCountUI()
end

function ClanChatMessage_RedGiftOther:updateState()
    if self.m_data.status == 0 then
        if self.m_bUpdateUISec then
            self:runCsbAction("can_collect", true)
        else
            self:runCsbAction("timeOver", false)
        end
    else
        self:runCsbAction("collected", false)
    end
end

-- 头像框
function ClanChatMessage_RedGiftOther:initUserHeadUI()
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
function ClanChatMessage_RedGiftOther:initTitleUI()
    local nickName = self.m_bMe and globalData.userRunData.nickName or self.m_data.nickname
    self.m_lbName:setString(nickName .. "'s Gift")

    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbName, 380, 1)
end

-- 赠送的金币价值
function ClanChatMessage_RedGiftOther:updatePriceUI()
    local price = self.m_msgInfo.collectDollars or "0"
    self.m_lbPrice:setString("$ " .. price)
end

-- 宝箱
function ClanChatMessage_RedGiftOther:initBoxUI()
    -- 档位从0 开始的
    local boxIdx = (self.m_msgInfo.gearIndex or 0) + 1
    local iconPath = string.format("Club/ui_new/Gift/Gift_Icon/Gift_icon_close_%s.png", boxIdx)
    util_changeTexture(self.m_spBox, iconPath)
end

-- 领取人数刷新
function ClanChatMessage_RedGiftOther:updateColCountUI()
    if self.m_msgInfo.type ~= "ALL" then
        return
    end

    local colCount = self.m_msgInfo.collectedCount or 0
    local tolCount  = self.m_msgInfo.totalCount or 0

    local lbCount = self:findChild("lb_count")
    lbCount:setString(colCount .. "/" .. tolCount)
end

function ClanChatMessage_RedGiftOther:onEnter()  
    -- 注册 领取事件
    if self.m_data.status == 0 and self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
        gLobalNoticManager:addObserver(self,function(self,data)
            if data.coins and data.msgId == self.m_data.msgId then
                self.m_data.status = 1
                self.m_data.coins = tonumber(data.coins)
                local colDollars = self.m_msgInfo.collectDollars or "0"
                if tonumber(colDollars) == 0 and data.dollars  then
                    self.m_msgInfo.collectDollars = data.dollars
                end
                if self.m_bClick then
                    self:flyCoins()
                end
                self:updateUI()
                self.m_bClick = false
                gLobalNoticManager:removeObserver(self, ChatConfig.EVENT_NAME.COLLECTED_TEAM_RED_GIFT_SUCCESS )
            end
        end,ChatConfig.EVENT_NAME.COLLECTED_TEAM_RED_GIFT_SUCCESS)
    end

    -- 注册 领取事件
    if self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
        gLobalNoticManager:addObserver(self,function(self, data)
            if data.msgId == self.m_data.msgId then
                self:setData(data)
                self:updateUI()
            end
        end,ChatConfig.EVENT_NAME.NOTIFY_REFRESH_RED_GIFT_CHAT)
    end
end

function ClanChatMessage_RedGiftOther:updateLeftTime()
    if self.m_data.effecTime and self.m_data.effecTime > 0 then
        local left_time = util_getLeftTime(self.m_data.effecTime)
        if left_time < 0 then
            left_time = 0
        end
      
        self.m_bUpdateUISec = left_time > 0
        if not self.m_bUpdateUISec then
            self:updateState()
        end
        self.m_lbTime:setString(util_count_down_str(left_time))
    end
end

-- 子类从写 定时器一秒调用一次
function ClanChatMessage_RedGiftOther:updateUISec()
    if not self.m_bUpdateUISec then
        return
    end

    self:updateLeftTime()
end

function ClanChatMessage_RedGiftOther:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_head" then
        -- 查看玩家信息
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_data.sender, "", "", self.m_data.frameId)
    elseif name == "btn_collect" and self.m_bUpdateUISec and self.m_data.status == 0 then
        -- 领取
        if self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
            -- 注册 领取事件
            self.m_bClick = true
            ClanManager:sendTeamRedGiftCollect( self.m_data.msgId, self.m_data.extra.randomSign )
        else
            printInfo("聊天发送领奖请求 信息不全 不能发送")
        end
    elseif name == "btn_view" then
        if self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
            ClanManager:sendTeamRedGiftCollectRecord(self.m_data.msgId, self.m_data.extra.randomSign, self.m_msgInfo.type)
        end
    end
end

function ClanChatMessage_RedGiftOther:isMyMessage()
    return self.m_bMe
end

function ClanChatMessage_RedGiftOther:getMessageId()
    return self.m_data.msgId
end

function ClanChatMessage_RedGiftOther:getContentSize()
    return self.m_bubbleContentSize
end

function ClanChatMessage_RedGiftOther:flyCoins()
    -- 弹出 领取红包弹板 不飞金币了
    ClanManager:popAutoColRedGiftLayer(self.m_data)
end

return ClanChatMessage_RedGiftOther