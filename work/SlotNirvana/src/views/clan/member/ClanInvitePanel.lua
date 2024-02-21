--[[
Author: cxc
Date: 2021-02-07 14:31:51
LastEditTime: 2021-07-23 10:12:40
LastEditors: Please set LastEditors
Description: 玩家邀请 界面
FilePath: /SlotNirvana/src/views/clan/member/ClanInvitePanel.lua
--]]
local ClanInvitePanel = class("ClanInvitePanel", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanInviteUserTableView = util_require("views.clan.member.ClanInviteUserTableView")
local SensitiveWordParser = util_require("utils.sensitive.SensitiveWordParser")

function ClanInvitePanel:ctor()
    ClanInvitePanel.super.ctor(self)
    self:setLandscapeCsbName("Club/csd/Invite/ClubInviteLayer.csb")
    
    self.m_searchIdx = 1
    ClanManager:resetSearchUserList()
    ClanManager:resetCurUserSearchStr()

    gLobalNoticManager:addObserver(self, "searchUserInfoSuccess", ClanConfig.EVENT_NAME.RECIEVE_SEARCH_USER_SUCCESS)
    gLobalNoticManager:addObserver(self, "inviteUserInfoSuccess", ClanConfig.EVENT_NAME.RECIEVE_INVITE_USER_SUCCESS)
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.KICKED_OFF_TEAM)
end

function ClanInvitePanel:initUI()
    ClanInvitePanel.super.initUI(self)

    -- 搜索框
    local textFieldSearch = self:findChild("text_shurukuang")
    local spPlaceHolder = self:findChild("sp_normalword")
    self.m_eboxSearch = util_convertTextFiledToEditBox(textFieldSearch, nil, function(strEventName,pSender)
        if strEventName == "began" then
            spPlaceHolder:setVisible(false)
        elseif strEventName == "changed" or strEventName == "return" then
            local content = self.m_eboxSearch:getText()
            local content = SensitiveWordParser:getString(content, "*", SensitiveWordParser.PARSE_LEVEL.HIGH)
            -- content = string.gsub(content, "[^%w]", "")
            spPlaceHolder:setVisible(#content <= 0) 
            self.m_eboxSearch:setText(content)
        end
    end)

    -- 搜索列表
    local listView = self:findChild("ListView_list")
    if self.m_tableView == nil then
        local size = listView:getContentSize()
        local param = {
            tableSize = size,
            parentPanel = listView,
            directionType = 2
        }
        self.m_tableView = ClanInviteUserTableView.new(param)
        listView:addChild(self.m_tableView)
    end
end

function ClanInvitePanel:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_search" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        -- 搜索 玩家
        local searchStr = self.m_eboxSearch:getText()
        ClanManager:requestSearchUser(searchStr, self.m_searchIdx)
    elseif name == "btn_fbshare" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        -- facebook 分享
        local clanData = ClanManager:getClanData()
        local fbUrl = clanData:getFbShareUrl()
        if fbUrl then
            globalFaceBookManager:facebookShare(fbUrl)
        end
        print("cxc------fburl:", fbUrl)
    end
end

-- 搜索用户成功
function ClanInvitePanel:searchUserInfoSuccess()
    local userList = ClanManager:getSearchUserList()
    self.m_userList = userList    
    self.m_tableView:reload(self.m_userList)
    -- self.m_searchIdx = self.m_searchIdx + 1  -- 不增加翻页功能 想要搜索到请键入更详细的信息

    -- 空文本 
    local spEmpty = self:findChild("sp_empty")
    spEmpty:setVisible(#userList <= 0)
end

-- 邀请玩家成功
function ClanInvitePanel:inviteUserInfoSuccess(_idx)
    if not _idx then
        self:searchUserInfoSuccess()
        return
    end
    
    local userList = ClanManager:getSearchUserList()
    if not next(userList)  then
        return
    end

    self.m_userList = userList 
    self.m_tableView:updateCellAtIndex(_idx)
end

return ClanInvitePanel