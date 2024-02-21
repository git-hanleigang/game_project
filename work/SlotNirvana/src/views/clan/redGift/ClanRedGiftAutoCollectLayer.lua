--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-14 10:30:03
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-14 10:30:11
FilePath: /SlotNirvana/src/views/clan/redGift/ClanRedGiftAutoCollectLayer.lua
Description: 公会红包 自动领取 弹板
--]]
local ClanRedGiftAutoCollectLayer = class("ClanRedGiftAutoCollectLayer", BaseLayer)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanRedGiftAutoCollectLayer:initDatas(_msgData, _cb)
    self.m_msgData = _msgData
    self.m_msgInfo = {}
    self.m_closeCb = _cb
    local content = self.m_msgData.content or "{}"
    if #content > 2 then
        self.m_msgInfo = cjson.decode(self.m_msgData.content)
    end

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Club/csd/Gift/Gift_Reward_auto.csb")
    self:setExtendData("ClanRedGiftAutoCollectLayer")
end

function ClanRedGiftAutoCollectLayer:initView()
    -- 谁发送的红包nameUI
    self:initSenderNameUI()
    -- 宝箱
    self:initBoxUI()
    -- 头像框
    self:initUserHeadUI()
end

-- 谁发送的红包nameUI
function ClanRedGiftAutoCollectLayer:initSenderNameUI()
    local lbDesc = self:findChild("lb_name")
    local name = self.m_msgData.nickname
    lbDesc:setString(string.format("%s'S GIFT.", name))

    util_scaleCoinLabGameLayerFromBgWidth(lbDesc, 370, 1)
end

-- 宝箱
function ClanRedGiftAutoCollectLayer:initBoxUI()
    -- 档位从0 开始的
    local boxIdx = (self.m_msgInfo.gearIndex or 0) + 1
    local spBoxClose = self:findChild("sp_box_close")
    local spBoxOpen = self:findChild("sp_box_open")
    local iconPathClose = string.format("Club/ui_new/Gift/Gift_Icon/Gift_icon_close_%s.png", boxIdx)
    local iconPathOpen = string.format("Club/ui_new/Gift/Gift_Icon/Gift_icon_open_%s.png", boxIdx)
    util_changeTexture(spBoxClose, iconPathClose)
    util_changeTexture(spBoxOpen, iconPathOpen)
end

-- 头像框
function ClanRedGiftAutoCollectLayer:initUserHeadUI()
    local headParent = self:findChild("node_head")
    local fbId = self.m_msgData.facebookId 
    local head = self.m_msgData.head
    local frameId = self.m_msgData.frameId
    headParent:removeAllChildren()
    local headSize = cc.size(100, 100)
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, "", headSize)
    headParent:addChild(nodeAvatar)
end

function ClanRedGiftAutoCollectLayer:onShowedCallFunc()
    if self.m_msgInfo.type == "ALL" then
        ClanManager:sendTeamRedGiftCollectRecord(self.m_msgData.msgId, self.m_msgData.extra.randomSign, self.m_msgInfo.type)
    end
    self:runCsbAction("start", false, util_node_handler(self, self.showDetailLayer), 60) 
    gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.RED_GIFT_OPEN_BOX)
end

function ClanRedGiftAutoCollectLayer:showDetailLayer()
    local coins = tonumber(self.m_msgData.coins) or 0
    if coins <= 0 then
        self:closeUI(self.m_closeCb)
        return
    end
    if self.m_msgInfo.type == "ASSIGN" then
        self:closeUI(function()
            local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
            local layer = gLobalItemManager:createRewardLayer({itemData}, self.m_closeCb, coins, true)
            gLobalViewManager:showUI(layer, ViewZorder.ZORDER_UI)
        end)
    else
        local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
        local layer = gLobalItemManager:createRewardLayer({itemData}, function()
            self.m_scheduler = schedule(self, util_node_handler(self, self.checkPopDetailLayer), 0.2)
            self:checkPopDetailLayer()
        end, coins, true)
        gLobalViewManager:showUI(layer, ViewZorder.ZORDER_UI)
    end
end

function ClanRedGiftAutoCollectLayer:checkPopDetailLayer()
    if self.m_colDetailData then
        self:clearScheduler()
        self:closeUI(function()
            if self.m_closeCb then
                self.m_closeCb()
            end
            ClanManager:popGiftCollectDetailLayer(self.m_colDetailData, true)
        end)
    end
end

function ClanRedGiftAutoCollectLayer:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

function ClanRedGiftAutoCollectLayer:registerListener()
    ClanRedGiftAutoCollectLayer.super.registerListener(self)

    -- 查看红包消息领取记录
    gLobalNoticManager:addObserver(self, function(self, param)
        if not self.m_msgInfo.type == "ALL" then
            return
        end

        self.m_colDetailData = param
    end, ClanConfig.EVENT_NAME.RECIEVE_TEAM_RED_COLLECT_RECORD_SUCCESS)
end

function ClanRedGiftAutoCollectLayer:closeUI(_cb)
    -- 隐藏粒子
    if self.hidePartiicles then
        self:hidePartiicles()
    end

    ClanRedGiftAutoCollectLayer.super.closeUI(self, _cb)
end

return ClanRedGiftAutoCollectLayer 