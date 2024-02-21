--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-12 15:32:11
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-12 15:38:17
FilePath: /SlotNirvana/src/views/clan/redGift/chat/ClanChatMessageTopUI.lua
Description: 公会红包 聊天消息 置顶消息
--]]
local ClanChatMessageTopUI = class("ClanChatMessageTopUI", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ChatConfig = require("data.clanData.ChatConfig")

function ClanChatMessageTopUI:updateData(_data)
    self.m_data = _data
    self.m_msgInfo = {}
    local content = self.m_data.content or "{}"
    if #content > 2 then
        self.m_msgInfo = cjson.decode(content)
    end
end

function ClanChatMessageTopUI:getCsbName()
    return "Club/csd/Gift/Gift_chat_top.csb"
end

function ClanChatMessageTopUI:initCsbNodes()
    self.m_spHead = self:findChild("sp_head") -- 头像
    self.m_lbName = self:findChild("lb_name") -- 名字title
    self.m_lbPrice = self:findChild("lb_price") -- 赠送的金币价值
    self.m_lbTime = self:findChild("lb_time") --消息倒计时
    self.m_spBox = self:findChild("sp_box") -- 宝箱
end

function ClanChatMessageTopUI:initUI( _data )
    ClanChatMessageTopUI.super.initUI(self)
    self:updateData(_data)
    
    self:updateUI()
end

function ClanChatMessageTopUI:updateUI()
    self.m_bActing = false
    self.m_bclick = false

    self:updateLeftTime()

    -- 头像框
    self:updateUserHeadUI()
    -- 名字`s Gift
    self:updateTitleUI()
    -- 不同类型描述显隐
    self:updateDescUIVisible()
    -- 宝箱
    self:updateBoxSpUI()
    self:setVisible(true)
end

-- 头像框
function ClanChatMessageTopUI:updateUserHeadUI()
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
function ClanChatMessageTopUI:updateTitleUI()
    local nickName = self.m_bMe and globalData.userRunData.nickName or self.m_data.nickname
    self.m_lbName:setString(nickName .. "'s Gift")

    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbName, 490, 1)
end

-- 不同类型描述显隐
function ClanChatMessageTopUI:updateDescUIVisible()
    local lbDescAssign = self:findChild("lb_desc_assign")
    local lbDescAll = self:findChild("lb_desc_all")
    lbDescAll:setVisible(self.m_msgInfo.type == "ALL")
    lbDescAssign:setVisible(self.m_msgInfo.type == "ASSIGN")
end

-- 宝箱
function ClanChatMessageTopUI:updateBoxSpUI()
    local boxIdx = (self.m_msgInfo.gearIndex or 0) + 1
    local iconPath = string.format("Club/ui_new/Gift/Gift_Icon/Gift_icon_close_%s.png", boxIdx)
    util_changeTexture(self.m_spBox, iconPath)
end

function ClanChatMessageTopUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_head" then
        -- 查看玩家信息
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_data.sender, "", "", self.m_data.frameId)
    elseif name == "btn_collect" and self.m_data.status == 0 then
        self.m_bclick = true
        -- 领取
        if self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
            ClanManager:sendTeamRedGiftCollect( self.m_data.msgId, self.m_data.extra.randomSign )
        else
            printInfo("聊天发送领奖请求 信息不全 不能发送")
        end
    end
end

function ClanChatMessageTopUI:onEnter()
    -- 注册 领取事件
    if self.m_data.status == 0 and self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
        gLobalNoticManager:addObserver(self,function(self,data)
            if data.msgId == self.m_data.msgId then
                self.m_data.status = 1
                self.m_data.coins = tonumber(data.coins)
                if self.m_bclick then
                    self:flyCoins()
                else
                    self:flyOverCB()
                end
                self.m_bclick = false
            end
        end, ChatConfig.EVENT_NAME.COLLECTED_TEAM_RED_GIFT_SUCCESS)
    end
end

function ClanChatMessageTopUI:updateLeftTime()
    if self.m_data.effecTime and self.m_data.effecTime > 0 then
        local left_time = util_getLeftTime(self.m_data.effecTime)
        if left_time < 0 then
            left_time = 0
        end
      
        self.m_bUpdateUISec = left_time > 0
        if not self.m_bUpdateUISec then
            self:flyOverCB()
        end
        self.m_lbTime:setString(util_count_down_str(left_time))
    end
end

function ClanChatMessageTopUI:updateUISec()
    if not self.m_bUpdateUISec then
        return
    end

    self:updateLeftTime()
end

function ClanChatMessageTopUI:flyCoins()
    self.m_bActing = true
    
    if self.m_data and self.m_data.coins > 0 then 
        -- 弹出 领取红包弹板 不飞金币了
        ClanManager:popAutoColRedGiftLayer(self.m_data, util_node_handler(self, self.flyOverCB))
        -- local startPos = self.m_spBox:convertToWorldSpace(cc.p(0, 0))
        -- local endPos = globalData.flyCoinsEndPos
        -- local cuyMgr = G_GetMgr(G_REF.Currency)
        -- cuyMgr:playFlyCurrency( {cuyType = FlyType.Coin, addValue = self.m_data.coins,startPos = startPos}, util_node_handler(self, self.flyOverCB))
    else
        self:flyOverCB()
    end
end

function ClanChatMessageTopUI:flyOverCB()
    self.m_bActing = false
    self:setVisible(false)
    -- 刷新新的消息
    gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_REFRESH_RED_GIFT_CHAT_TOP) -- 刷新红包置顶消息
end

function ClanChatMessageTopUI:checkIsActing()
    return self.m_bActing
end

function ClanChatMessageTopUI:getShowData()
    return self.m_data
end

return ClanChatMessageTopUI