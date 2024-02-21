--[[
Author: cxc
Date: 2021-02-26 11:45:59
LastEditTime: 2021-03-19 16:16:57
LastEditors: Please set LastEditors
Description: 邀请列表 面板
FilePath: /SlotNirvana/src/views/clan/recurit/ClanInviteListPanel.lua
--]]
local ClanInviteListPanel = class("ClanInviteListPanel", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanInviteTableView = util_require("views.clan.recurit.ClanInviteTableView")

function ClanInviteListPanel:ctor()
    ClanInviteListPanel.super.ctor(self)
    self:setLandscapeCsbName("Club/csd/Invite/ClubTeamInviteLayer.csb")
    self:setKeyBackEnabled(true)
    
    self.m_inviteList = {}

    gLobalNoticManager:addObserver(self, "joinClanSuccessEvt", ClanConfig.EVENT_NAME.RECIEVE_JOIN_CLAN_SUCCESS)
    gLobalNoticManager:addObserver(self, "rejectJoinClanEvt", ClanConfig.EVENT_NAME.RECIEVE_REJECT_JOIN_CLAN_SUCCESS)
end

function ClanInviteListPanel:initUI(_bPopNextView)
    ClanInviteListPanel.super.initUI(self)

    self.m_bPopNextView = _bPopNextView

    -- 搜索列表
    local listView = self:findChild("ListView_clan")
    if self.m_tableView == nil then
        local size = listView:getContentSize()
        local param = {
            tableSize = size,
            parentPanel = listView,
            directionType = 2
        }
        self.m_tableView = ClanInviteTableView.new(param)
        listView:addChild(self.m_tableView)
    end
    self:refreshInviteListUI()
end

function ClanInviteListPanel:updateUI()
    -- 空文本 
    local spEmpty = self:findChild("sp_empty")
    spEmpty:setVisible(#self.m_inviteList <= 0)
end

-- 刷新邀请列表
function ClanInviteListPanel:refreshInviteListUI()
    self:refreshInviteList()
    
    self.m_tableView:reload(self.m_inviteList)
    self:updateUI()
end

function ClanInviteListPanel:clickFunc(sender)
    local name = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_close" then
        self:closeUI(function(  )
            if self.m_bPopNextView then
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)--弹窗逻辑执行下一个事件 
            end
        end)
    end
end

-- 更新数据
function ClanInviteListPanel:refreshInviteList()
    local clanData = ClanManager:getClanData()
    local inviteList = clanData:getInviteList()
    
    if not next(inviteList)  then
        return
    end

    self.m_inviteList = inviteList
end

-- 同意玩家入会
function ClanInviteListPanel:joinClanSuccessEvt()
    local clanData = ClanManager:getClanData()
    local bJoinClan = clanData:isClanMember()
    if bJoinClan then
        self:closeUI() 
    else
        self:refreshInviteListUI()
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.APPLICATION_SUBMITTED)
    end
end

-- 拒绝玩家入会
function ClanInviteListPanel:rejectJoinClanEvt(_idx)
    if not _idx then 
        self:refreshInviteListUI()
        return
    end

    self:refreshInviteList()
    self.m_tableView:removeCellAtIndex(_idx)
    self.m_tableView:setViewData(self.m_inviteList)
    self:updateUI()
end

return ClanInviteListPanel