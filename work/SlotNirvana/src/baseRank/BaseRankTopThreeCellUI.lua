--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-02-09 14:43:29
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-02-09 15:25:16
FilePath: /SlotNirvana/src/baseRank/BaseRankTopThreeCellUI.lua
Description: 排行榜 前三名 UI 基类
--]]
local BaseRankTopThreeCellUI = class("BaseRankTopThreeCellUI", BaseView)

function BaseRankTopThreeCellUI:initUI(data)
    self.m_data = data

    BaseRankTopThreeCellUI.super.initUI(self)
    self:updateRankUI()
end

function BaseRankTopThreeCellUI:initCsbNodes()
    BaseRankTopThreeCellUI.super.initCsbNodes()

    self.m_spHead = self:findChild("sp_head")
    self.m_layoutName = self:findChild("layout_name")
    self.m_lbName = self:findChild("lb_name")
    self.m_lbNum = self:findChild("lb_num")
end

function BaseRankTopThreeCellUI:updateRankUI()
    -- 设置头像
    self:updateHeadUI()
    -- 姓名
    self:updateNameUI()
    -- 累积数量
    self:updateNumUI()
end

--设置头像
function BaseRankTopThreeCellUI:updateHeadUI()
    local rank = self.m_data.p_rank or 1
    local headSize = self.m_spHead:getContentSize()
    local nodeAvatar = self.m_spHead:getChildByName("CommonAvatarNode")
    if nodeAvatar then
        nodeAvatar:updateUI(self.m_data.p_fbid, self.m_data.p_head, self.m_data.p_frameId, nil, headSize)
    else
        self.m_spHead:removeAllChildren()
        nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(self.m_data.p_fbid, self.m_data.p_head, self.m_data.p_frameId, nil, headSize)
        self.m_spHead:addChild(nodeAvatar)
        nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )

        local layout = ccui.Layout:create()
        layout:setName("layout_touch")
        layout:setTouchEnabled(true)
        layout:setContentSize(headSize)
        self:addClick(layout)
        layout:addTo(self.m_spHead)
    end
end

-- 姓名
function BaseRankTopThreeCellUI:updateNameUI()
    self.m_lbName:setString(self.m_data.p_name or "Pending")
    if self.m_layoutName then
        util_wordSwing(self.m_lbName, 1, self.m_layoutName, 2, 30, 2, nil, true)
    end
end

-- 累积数量
function BaseRankTopThreeCellUI:updateNumUI()
    local num = self.m_data.p_points or 0
    if self.m_lbNum then
        self.m_lbNum:setString(util_getFromatMoneyStr(num))
    end
end

function BaseRankTopThreeCellUI:getImageMap()
    return nil
end

function BaseRankTopThreeCellUI:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
        if not self.m_data or not self.m_data.p_udid then
            return
        end
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_data.p_udid, "", "", self.m_data.p_frameId)
    end
end
------------------------------------------子类重写---------------------------------------

return BaseRankTopThreeCellUI