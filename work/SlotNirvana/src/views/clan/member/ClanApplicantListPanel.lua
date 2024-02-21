--[[
Author: cxc
Date: 2021-02-09 15:18:11
LastEditTime: 2021-03-19 16:16:12
LastEditors: Please set LastEditors
Description: 公会 会长查看的 申请人列表 面板k
FilePath: /SlotNirvana/src/views/clan/member/ClanApplicantListPanel.lua
--]]
local ClanApplicantListPanel = class("ClanApplicantListPanel", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanApplicantTableView = util_require("views.clan.member.ClanApplicantTableView")

local MAX_SHOW_COUNT= 20 -- 申请列表限制人数

function ClanApplicantListPanel:ctor()
    ClanApplicantListPanel.super.ctor(self)
    self:setLandscapeCsbName("Club/csd/Application/ClubMemberAppLayer.csb")
    self.m_applyList = {}
    ClanManager:resetClanApplyList()

    gLobalNoticManager:addObserver(self, "recieveClanApplicantList", ClanConfig.EVENT_NAME.RECIEVE_CLAN_APPLICANT_LIST)
    gLobalNoticManager:addObserver(self, "agreeUserJoinEvt", ClanConfig.EVENT_NAME.RECIEVE_CLAN_AGREE_USER_JOIN)
    gLobalNoticManager:addObserver(self, "rejectUserJoinEvt", ClanConfig.EVENT_NAME.RECIEVE_CLAN_REJECT_USER_JOIN)
    gLobalNoticManager:addObserver(self, "clearClanApplicantList", ClanConfig.EVENT_NAME.RECIEVE_CLAN_APPLICANT_CLEAR)
end

function ClanApplicantListPanel:initUI()
    ClanApplicantListPanel.super.initUI(self)

    -- 搜索列表
    local listView = self:findChild("ListView_clan")
    if self.m_tableView == nil then
        local size = listView:getContentSize()
        local param = {
            tableSize = size,
            parentPanel = listView,
            directionType = 2
        }
        self.m_tableView = ClanApplicantTableView.new(param)
        listView:addChild(self.m_tableView)
    end

    ClanManager:requestClanApplyList(1)
end

function ClanApplicantListPanel:updateUI()
    -- 申请人数
    local lbUserCount = self:findChild("font_renshu")
    local curApplyCount = #self.m_applyList
    lbUserCount:setString(curApplyCount .. "/" .. MAX_SHOW_COUNT)

     -- 空文本 
     local spEmpty = self:findChild("sp_empty")
     spEmpty:setVisible(curApplyCount <= 0)
end

function ClanApplicantListPanel:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_clear" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        ClanManager:requestClanApplyClear() 
    end
end

-- 更新数据
function ClanApplicantListPanel:refreshApplyList()
    self.m_applyList = ClanManager:getClanApplyList()
end

-- 收到申请列表
function ClanApplicantListPanel:recieveClanApplicantList()
    self:refreshApplyList()
    
    self.m_tableView:reload(self.m_applyList)
    self:updateUI()
end

-- 同意玩家入会
function ClanApplicantListPanel:agreeUserJoinEvt(_idx)
    if not _idx then 
        self:recieveClanApplicantList()
        return
    end

    self:refreshApplyList()
    self.m_tableView:removeCellAtIndex(_idx)
    self.m_tableView:setViewData(self.m_applyList)
    self:updateUI()
end

-- 拒绝玩家入会
function ClanApplicantListPanel:rejectUserJoinEvt(_idx)
    if not _idx then 
        self:recieveClanApplicantList()
        return
    end

    self:refreshApplyList()
    self.m_tableView:removeCellAtIndex(_idx)
    self.m_tableView:setViewData(self.m_applyList)
    self:updateUI()
end

-- 清空 申请列表
function ClanApplicantListPanel:clearClanApplicantList()
    self.m_applyList = {}    
    self.m_tableView:reload(self.m_applyList)
    self:updateUI()
end

return ClanApplicantListPanel