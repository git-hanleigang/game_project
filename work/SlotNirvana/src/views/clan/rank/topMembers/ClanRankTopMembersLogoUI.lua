--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-10 12:13:52
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-10 12:15:31
FilePath: /SlotNirvana/src/views/clan/rank/topTeam/ClanRankTopMembersLogoUI.lua
Description: 最强个人排行， 前三名奖台logoUI
--]]
local ClanRankTopMembersLogoUI = class("ClanRankTopMembersLogoUI", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRankTopMembersLogoUI:initDatas(_rankCellData, _idx)
    ClanRankTopMembersLogoUI.super.initDatas(self)
    
    self.m_rankCellData = _rankCellData
    self.m_rankIdx = _idx or 1
end

function ClanRankTopMembersLogoUI:initUI()
    ClanRankTopMembersLogoUI.super.initUI(self)

    local nodeMid = self:findChild("node_mid")
    if nodeMid then
        local isVis = self.m_rankCellData and true or false
        nodeMid:setVisible(isVis)
    end

    local sp_head_frame = self:findChild("sp_touxiangkuang")
    if sp_head_frame then
        sp_head_frame:setVisible(false)
    end
    -- 个人头像
    local nodeHead = self:findChild("node_head")
    if nodeHead and self.m_rankCellData then
        local fbid = self.m_rankCellData:getFacebookId()
        local headName = self.m_rankCellData:getUserHead()
        local frameId = self.m_rankCellData:getUserFrame()
        local headSize = cc.size(140, 140)
        local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, headName, frameId, nil, headSize)
        nodeAvatar:registerTakeOffEvt()
        nodeAvatar:setName("m_spHead")
        nodeHead:addChild(nodeAvatar)
        -- nodeAvatar:setPosition(headSize.width * 0.5, headSize.height * 0.5)
        if sp_head_frame then
            if frameId and frameId ~= "" then
                sp_head_frame:setVisible(tonumber(frameId) <= 0)
            else
                sp_head_frame:setVisible(true)
            end
            local touchSize = sp_head_frame:getContentSize()
            local touchScale = sp_head_frame:getScale()
            local width = touchSize.width * touchScale
            local height = touchSize.height * touchScale
            local layout = ccui.Layout:create()
            layout:setName("layout_touch")
            layout:setTouchEnabled(true)
            layout:setContentSize(width, height)
            layout:setPosition(-width / 2, -height / 2)
            layout:addTo(nodeHead)
            self:addClick(layout)
        end
    end

    -- 玩家名字
    local layoutTeamName = self:findChild("layout_teamName")
    local lbTeamName = self:findChild("lb_teamName")
    lbTeamName:setString("")
    if self.m_rankCellData then
        local teamName = self.m_rankCellData:getUserName()
        lbTeamName:setString(teamName) 
        util_wordSwing(lbTeamName, 2, layoutTeamName, 3, 30, 3)
        self:runCsbAction("idle", true) 
    end
end

function ClanRankTopMembersLogoUI:getCsbName()
    return string.format("Club/csd/RANK/TopMembers/TopMembers_ranking_%d.csb", self.m_rankIdx)
end

function ClanRankTopMembersLogoUI:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
        if not self.m_rankCellData then
            return
        end
        if not self.m_rankCellData:getUdid() then
            return
        end
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_rankCellData:getUdid(), "","",self.m_rankCellData:getUserFrame())
    end
end

return ClanRankTopMembersLogoUI