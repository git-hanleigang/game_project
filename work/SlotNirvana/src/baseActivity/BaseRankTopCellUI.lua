--[[
    author:JohnnyFred
    time:2020-06-24 11:00:43
]]
local NetSpriteLua = require("views.NetSprite")
local BaseRankTopCellUI = class("BaseRankTopCellUI", util_require("base.BaseView"))

function BaseRankTopCellUI:initUI(data)
    self:createCsbNode(self:getCsbName())
    self.bg = self:findChild("Sprite_bg")
    self.rank = self:findChild("rank_1")
    self.head = self:findChild("head")
    self.headID = self:findChild("head_id")
    self.headIDLayer = self:findChild("headid_layer")
    self.hatIcon = self:findChild("Sprite_5")
    self.valueBg = self:findChild("Image_4")
    self.lbPoint = self:findChild("pointValue")
    self.data = data
    util_setCascadeOpacityEnabledRescursion(self,true)
    self:updateRankUI()
end

function BaseRankTopCellUI:updateRankUI()
    local data = self.data
    local rank = data.p_rank
    local point = data.p_points
    local name = data.p_name
    local head = data.p_head
    local imageMap = self:getImageMap()
    if imageMap ~= nil then
        local imageInfo = imageMap[rank]
        if self.bg and imageInfo.bg then
            util_changeTexture(self.bg,imageInfo.bg)
        end
        if self.rank and imageInfo.rank then
            util_changeTexture(self.rank,imageInfo.rank)
        end
        if self.hatIcon and imageInfo.hatIcon then
            util_changeTexture(self.hatIcon,imageInfo.hatIcon)
        end
        if self.valueBg and imageInfo.valueBg then
            util_changeTexture(self.valueBg,imageInfo.valueBg)
        end
    end

    --设置头像
    local limitSize = cc.size(60, 60)
    local headSize = self.head:getContentSize()
    local nodeAvatar = self.head:getChildByName("CommonAvatarNode")
    if nodeAvatar then
        nodeAvatar:updateUI(data.p_fbid, data.p_head, data.p_frameId, nil, headSize)
    else
        self.head:removeAllChildren()
        nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(data.p_fbid, data.p_head, data.p_frameId, nil, headSize)
        self.head:addChild(nodeAvatar)
        nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
        if limitSize.width < headSize.width then
            self.head:setScale(limitSize.width / headSize.width)
        end

        local layout = ccui.Layout:create()
        layout:setName("layout_touch")
        layout:setTouchEnabled(true)
        layout:setContentSize(headSize)
        self:addClick(layout)
        layout:addTo(self.head)
    end

    self.headID:setString(name or "ROBOT")
    if not self.m_wordSwing then
        self.m_wordSwing = true
        util_wordSwing(self.headID, 1, self.headIDLayer, 2, 30, 2)
    end

    self.lbPoint:setString(point)
end

------------------------------------------子类重写---------------------------------------
function BaseRankTopCellUI:getCsbName()
    return nil
end

function BaseRankTopCellUI:getImageMap()
    return nil
end

function BaseRankTopCellUI:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
        if not self.data then
            return
        end
        if not self.data.p_udid then
            return
        end
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.data.p_udid, "","",self.data.p_frameId)
    end
end
------------------------------------------子类重写---------------------------------------

return BaseRankTopCellUI