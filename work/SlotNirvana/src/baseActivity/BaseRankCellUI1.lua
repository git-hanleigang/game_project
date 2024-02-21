--[[
    author:JohnnyFred
    time:2019-11-05 10:23:40
]]
local NetSpriteLua = require("views.NetSprite")
local BaseRankCellUI1 = class("BaseRankCellUI1", util_require("base.BaseView"))
function BaseRankCellUI1:initUI(rankUI)
    self.rankUI = rankUI
    self:createCsbNode(self:getCsbName())
    self.myBg = self:findChild("Sprite_2")
    self.splitLine = self:findChild("Sprite_1")

    --头像
    self.head = self:findChild("head")
    self.m_headId = self:findChild("head_id")
    self.m_headIdLayer = self:findChild("headid_layer")

    --奖励
    self.m_pointValue = self:findChild("pointValue")

    --排名
    self.lbRank = self:findChild("rank_4")

    --没有排名
    self.m_notRank = self:findChild("rank_not")
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function BaseRankCellUI1:setRankValue(rank)
    local validRankFlag = rank > 0
    self.m_notRank:setVisible(not validRankFlag)
    self.lbRank:setVisible(validRankFlag)
    self.lbRank:setString(rank)
end

function BaseRankCellUI1:updateView(data, index)
    local rankCfg = self.rankUI:getRankCfg()
    if rankCfg ~= nil then
        local myRankIndex = rankCfg:getSelfRankIndex()
        --设置排名
        self:setRankValue(data.p_rank)

        self:updateHead(data)
        --设置名称
        if data and data.p_name then
            -- self.m_headId:setString(util_getRankMaxLenStr(data.p_name,10))
            self.m_headId:setString(data.p_name)
            if not self.m_wordSwing then
                self.m_wordSwing = true
                -- util_multiLanguage(self.m_headId,data.p_name,30)
                util_wordSwing(self.m_headId, 1, self.m_headIdLayer, 2, 30, 2)
            end
        end
        --设置奖励
        self.m_pointValue:setString(data.p_points)
        local isSelfFlag = index == nil or myRankIndex == index
        self.myBg:setVisible(isSelfFlag)
        if self.splitLine ~= nil then
            self.splitLine:setVisible(not isSelfFlag)
        end
        self.data = data
    end
end

function BaseRankCellUI1:updateHead(data)
    if not data then
        return
    end
    if self.data and self.data.p_fbid == data.p_fbid and self.data.p_head == data.p_head and self.data.p_frameId == data.p_frameId then
        return
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
        nodeAvatar:setPosition(headSize.width * 0.5, headSize.height * 0.5)
        if limitSize.width < headSize.width then
            self.head:setScale(limitSize.width / headSize.width)
        end
        local layout = ccui.Layout:create()
        layout:setName("layout_touch")
        layout:setTouchEnabled(true)
        layout:setContentSize(headSize)
        layout:addTo(self.head)
        self:addClick(layout)
    end
end
function BaseRankCellUI1:clickFunc(sender)
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
function BaseRankCellUI1:getCsbName()
    return ""
end
------------------------------------------子类重写---------------------------------------
return BaseRankCellUI1
