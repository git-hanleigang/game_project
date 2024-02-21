local NetSpriteLua = require("views.NetSprite")
local LottoPartyBonusSpot = class("LottoPartyBonusSpot", util_require("base.BaseView"))

local imageMap = {
    {headBg = "Common/LottoParty_PinMe_1.png", headFrame = "Common/LottoParty_PinMe_0.png"},
    {headBg = "Common/LottoParty_PinPlayer_1.png", headFrame = "Common/LottoParty_PinPlayer_0.png"}
}

function LottoPartyBonusSpot:initUI(data)
    self:createCsbNode("LottoParty_BonusSlots.csb")
    self.headIcon = self:findChild("sp_head")
    self.headBg = self:findChild("sp_headBg")
    self.headFrame = self:findChild("sp_headFrame")
    
    self:updateUI(data)
end

function LottoPartyBonusSpot:onEnter()
    LottoPartyBonusSpot.super.onEnter(self)
    --关闭个人信息界面
    gLobalNoticManager:addObserver(self,handler(self,function()
        self:updateUI(self.m_data)
    end),ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER)
end

function LottoPartyBonusSpot:isMySelf(_udid)
    if globalData.userRunData.userUdid == _udid then
        return true
    end
    return false
end

function LottoPartyBonusSpot:updateUI(data)
    if data and next(data) and data.udid ~= "" then
        self.m_data = data
        local head = data.head
        local udid = data.udid
        local coins = data.coins
        local index = 1
        if self:isMySelf(udid) then
            index = 1
            head = globalData.userRunData.HeadName or "0"
        else
            index = 2
        end
        local imageInfo = imageMap[index]
        if imageInfo ~= nil then
            util_changeTexture(self.headBg, imageInfo.headBg)
            util_changeTexture(self.headFrame, imageInfo.headFrame)
        end
        --设置头像
        self.headIcon:removeAllChildren()
        if head then
            -- 有真实的数据再进来
            if data.facebookId and data.facebookId ~= "" and (tonumber(head) == 0 or head == "" ) then
                -- 登录了facebook 并且（没有设置过自己的头像或把自己的头像就设置为Facebook头像）
                -- self:startLoadFacebookHead(data.facebookId)
            else
                -- 没有登录facebook 或者 设置了自己默认的头像（设置自己头像为0但是你没有登录facebook默认显示1）
                if tonumber(head) == 0 or head == "" then
                    head = 1
                end
                -- local size = self.headIcon:getContentSize()
                -- util_changeTexture(self.headIcon, "GameNode/ui/ui_facebook_touxiang/TopNode_touxiang_" .. head .. ".png")
                -- self.headIcon:setContentSize(size)
            end
            local frameId
            if index == 1 then
                frameId = globalData.userRunData.avatarFrameId
            else
                frameId = data.frame
            end

            local headSize = self.headIcon:getContentSize()
            local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(data.facebookId, head, frameId, nil, headSize)
            self.headIcon:addChild(nodeAvatar)
            nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )


            if not self.m_headFrame then
                local headFrameNode = cc.Node:create()
                self:findChild("Node_BonusSlotsPlayer"):addChild(headFrameNode, 1)
                self.m_headFrame = headFrameNode
                self.m_headFrame:setPosition(self.headIcon:getPosition())
            else
                self.m_headFrame:removeAllChildren(true)
            end
            util_changeNodeParent(self.m_headFrame, nodeAvatar.m_nodeFrame)
        end
    else
        local headNode = self:findChild("Node_BonusSlotsPlayer")
        headNode:setVisible(false)
    end
end

function LottoPartyBonusSpot:startLoadFacebookHead(fbid)
    local headIcon = self.headIcon
    if fbid ~= nil and fbid ~= "" then
        local fbSize = headIcon:getContentSize()

        -- 头像切图
        local clip_node = cc.ClippingNode:create()

        local netSprite = NetSpriteLua:create()
        local mask = NetSpriteLua:create()
        mask:init("Common/Other/fbmask.png", fbSize)
        clip_node:setStencil(mask)
        clip_node:setAlphaThreshold(0)

        netSprite:init(nil, fbSize)
        clip_node:addChild(netSprite)
        headIcon:addChild(clip_node)
        clip_node:setPosition(0, 0)

        local urlPath = "https://graph.facebook.com/" .. fbid .. "/picture?type=large"
        netSprite:getSpriteByUrl(urlPath, true)
        local isExist, fileName = netSprite:getHeadMd5(urlPath)
        if not isExist then
            LottoPartyHeadManager:addPlayerHeadInfo(urlPath)
        end
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_IMAGE_LOAD_COMPLETE)
    end
end

return LottoPartyBonusSpot
