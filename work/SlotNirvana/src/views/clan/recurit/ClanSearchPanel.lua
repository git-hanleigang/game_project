--[[
Author: cxc
Date: 2021-02-07 18:07:25
LastEditTime: 2021-07-21 16:42:45
LastEditors: Please set LastEditors
Description: 搜索公会面板
FilePath: /SlotNirvana/src/views/clan/recurit/ClanSearchPanel.lua
--]]

local ClanSearchPanel = class("ClanSearchPanel", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanSearchTableView = util_require("views.clan.recurit.ClanSearchTableView")
local SensitiveWordParser = util_require("utils.sensitive.SensitiveWordParser")

function ClanSearchPanel:ctor()
    ClanSearchPanel.super.ctor(self)
    self:setLandscapeCsbName("Club/csd/Browse/ClubBrowseTeamLayer.csb")
    self:setKeyBackEnabled(true)
    self.m_recommendIdx = 0 -- 推荐页
    self.m_searchIdx = 1    -- 搜索页
    ClanManager:resetClanSearchList()
    ClanManager:resetCurClanSearchStr()

    gLobalNoticManager:addObserver(self, "searchClanInfoSuccess", ClanConfig.EVENT_NAME.RECIEVE_CLAN_SEARCH)
    gLobalNoticManager:addObserver(self, "joinClanSuccess", ClanConfig.EVENT_NAME.RECIEVE_JOIN_CLAN_SUCCESS)
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.KICKED_OFF_TEAM)
end

function ClanSearchPanel:initUI()
    ClanSearchPanel.super.initUI(self)

    -- 搜索框
    local textFieldSearch = self:findChild("text_search")
    local spPlaceHolder = self:findChild("sp_searchword")
    self.m_eboxSearch = util_convertTextFiledToEditBox(textFieldSearch, nil, function(strEventName,pSender)
        if strEventName == "began" then
            spPlaceHolder:setVisible(false)
        elseif strEventName == "changed" or strEventName == "return" then
            local content = self.m_eboxSearch:getText()
            local content = SensitiveWordParser:getString(content, "*", SensitiveWordParser.PARSE_LEVEL.HIGH)
            content = string.gsub(content, "[^%w]", "")
            spPlaceHolder:setVisible(#content <= 0) 
            self.m_eboxSearch:setText(content)
        end
    end)

    self.btn_refresh = self:findChild("btn_refresh")
    self.btn_refresh:setEnabled(true)
    self.lb_timer = self:findChild("lb_timer")
    self:onRefresh()

    -- 搜索列表
    local listView = self:findChild("ListView_clan")
    if self.m_tableView == nil then
        local size = listView:getContentSize()
        local param = {
            tableSize = size,
            parentPanel = listView,
            directionType = 2
        }
        self.m_tableView = ClanSearchTableView.new(param)
        listView:addChild(self.m_tableView)
    end

    -- 邀请列表
    local clanData = ClanManager:getClanData()
    local btnInviteList = self:findChild("Node_invitation")
    local sp_searchkuang = self:findChild("sp_searchkuang")
    local sp_searchkuang_long = self:findChild("sp_searchkuang_long")

    if clanData:isClanMember() then
        btnInviteList:setVisible(false)

        local btnSearch = self:findChild("Node_search")
        btnSearch:setPosition(btnInviteList:getPosition())

        sp_searchkuang:setVisible(false)
        sp_searchkuang_long:setVisible(true)
    else
        self:updateRedUI()
        schedule(self, handler(self, self.updateRedUI), 1)

        sp_searchkuang:setVisible(true)
        sp_searchkuang_long:setVisible(false)
    end

    ClanManager:requestRecommendClanList()
end

function ClanSearchPanel:updateRedUI()
    local clanData = ClanManager:getClanData()
    local sp_numBg = self:findChild("sp_numBg")
    local lb_num = self:findChild("lb_num")
    local inviteList = clanData:getInviteList()
    local counts = table.nums(inviteList)
    sp_numBg:setVisible( counts > 0 )
    lb_num:setString( counts )
end

function ClanSearchPanel:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_close" then
        self:closeUI()
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLOSE_CLNA_PANEL_UI, "ClanSearchPanel")
    elseif name == "btn_search" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        -- 搜索 公会
        local content = self.m_eboxSearch:getText()
        if #content <= 0 then
            self.m_recommendIdx = 0
            ClanManager:requestRecommendClanList() 
        end
        ClanManager:sendClanSearch(content, self.m_searchIdx)
    elseif name == "btn_invitation" then
        -- 查看邀请列表
        ClanManager:popClanInviteListPanel()
    elseif name == "btn_refresh" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        ClanManager:onSearchRefresh()
        self:onRefresh()
        self.m_recommendIdx = self.m_recommendIdx + 1 -- 不增加翻页功能 想要搜索到请键入更详细的信息
        -- 刷新 公会推荐列表
        ClanManager:requestRecommendClanList(self.m_recommendIdx)
    end
end

function ClanSearchPanel:onRefresh()
    if not self.btn_refresh then
        return
    end

    local bl_refresh = ClanManager:getRefreshEnabled()
    if bl_refresh then
        self.btn_refresh:setTouchEnabled( true )
        self.btn_refresh:setBright( true )
        self.lb_timer:setVisible(false)

        if self.schedule_countDown then
            self:stopAction( self.schedule_countDown )
            self.schedule_countDown = nil
        end
        return
    end

    if not self.schedule_countDown then
        -- 倒计时
        local timer = ClanManager:getRefreshTimer()
        local time_count = timer - math.floor(globalData.userRunData.p_serverTime / 1000)
        self.btn_refresh:setTouchEnabled( time_count <= 0 )
        self.btn_refresh:setBright( time_count <= 0 )
        
        self.lb_timer:setString( util_count_down_str(time_count) )
        self.lb_timer:setVisible( time_count > 0 )

        self.schedule_countDown = util_schedule(self, function()
            local timer = ClanManager:getRefreshTimer()
            local time_count_new = timer - math.floor(globalData.userRunData.p_serverTime / 1000)
            if time_count_new <= 0 then
                self.btn_refresh:setTouchEnabled( true )
                self.btn_refresh:setBright( true )
                self.lb_timer:setVisible(false)

                if self.schedule_countDown then
                    self:stopAction( self.schedule_countDown )
                    self.schedule_countDown = nil
                end
                return
            end
            self.lb_timer:setString( util_count_down_str(time_count_new) )
        end, 1)
    end
end

-- 搜索公会成功
function ClanSearchPanel:searchClanInfoSuccess()
    local clanList = ClanManager:getClanSearchList()
    self.m_tableView:reload(clanList)
    
    -- 空文本 
    local spEmpty = self:findChild("sp_empty")
    spEmpty:setVisible(#clanList <= 0)
    if #clanList <= 0 and self.m_recommendIdx > 0 then
        self.m_recommendIdx = 0
        ClanManager:requestRecommendClanList()
    end
end
-- 加入公会成功
function ClanSearchPanel:joinClanSuccess()
    local clanData = ClanManager:getClanData()
    local bJoinClan = clanData:isClanMember()
    if bJoinClan then
        self:closeUI() 
    else
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.APPLICATION_SUBMITTED)
    end
end

return ClanSearchPanel