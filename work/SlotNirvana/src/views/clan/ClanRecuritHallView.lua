--[[
Author: cxc
Date: 2021-02-07 14:51:54
LastEditTime: 2021-07-13 11:32:19
LastEditors: Please set LastEditors
Description: 公会招募 大厅(未加入任何公会 点击入口进入此处)
FilePath: /SlotNirvana/src/views/clan/ClanRecuritHallView.lua
--]]
local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local ClanRecuritHallView = class("ClanRecuritHallView", BaseActivityMainLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRecuritHallView:ctor()
    ClanRecuritHallView.super.ctor(self)
    self:setPauseSlotsEnabled(true)
    self:setHideLobbyEnabled(true)
    self:setKeyBackEnabled(true)
    self:setExtendData("ClanRecuritHallView")

    self:setLandscapeCsbName("Club/csd/Main/ClubJoinTeamLayer.csb")
    -- self:setBgm(ClanConfig.MUSIC_ENUM.BG)
G_GetMgr(ACTIVITY_REF.Zombie):setSpinData(true)
end

function ClanRecuritHallView:initView()
    -- spine
    -- self:initSpineUI()
end

function ClanRecuritHallView:initSpineUI()
    ClanRecuritHallView.super.initSpineUI(self)
    
    local parent = self:findChild("Node_spine")
    local spineNode = util_spineCreate("Club/spine/ClubJoinTeamLayer_npc", true, true, 1)
    parent:addChild(spineNode)

    util_spinePlay(spineNode, "idle", true)
end

function ClanRecuritHallView:onEnter()
    ClanRecuritHallView.super.onEnter(self)

    self:runCsbAction("idle", true)

    self:updateRedUI()
    schedule(self, handler(self, self.updateRedUI), 1)
end

function ClanRecuritHallView:updateRedUI()
    local clanData = ClanManager:getClanData()
    local sp_numBg = self:findChild("sp_InviteRed")
    local lb_num = self:findChild("lb_invite_num")
    local inviteList = clanData:getInviteList()
    local counts = table.nums(inviteList)
    sp_numBg:setVisible(counts > 0)
    lb_num:setString(counts)
end

function ClanRecuritHallView:clickFunc(sender)
    local name = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_close" then
        self:closeUI(
            function()
                if self.m_viewOverFunc then
                    self.m_viewOverFunc()
                end
                ClanManager:exitClanSystem()
            end
        )
    elseif name == "btn_info" then
        -- 规则
        ClanManager:popClanRulePanel()
    elseif name == "btn_creatteam" then
        -- 创建 公会
        local clanData = ClanManager:getClanData()
        local simpleInfo = clanData:getClanSimpleInfo()
        self:popCreateClanPanel(simpleInfo)
    elseif name == "btn_search" then
        -- 搜索 公会
        ClanManager:popSearchClanPanel()
    elseif name == "btn_jointeam" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        -- 快速加入公会
        ClanManager:requestClanQuickJoin()
    end
end

-- 弹出创建公会面板
function ClanRecuritHallView:popCreateClanPanel()
    if not ClanManager:clanCreateEnable() then
        local clanData = ClanManager:getClanData()
        if clanData and clanData:getGemCost() > 0 then
            -- 花费钻石 创建公会
            ClanManager:popGemCreatePanel()
        else
            -- 不可以创建公会
            ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.CANNOT_CREATE_CLAN)
        end
        return
    end
    ClanManager:popEditClanInfoPanel()
end

function ClanRecuritHallView:onGemCostEvt()
    ClanManager:popEditClanInfoPanel()
end

-- 创建公会成功
function ClanRecuritHallView:createClanSuccessEvt()
    local clanData = ClanManager:getClanData()
    local updateNameGems = clanData:getUpdateNameGems() or 0
    if updateNameGems == 0 then
        ClanManager:popCommonTipPanel(
            ProtoConfig.ErrorTipEnum.CREATE_USER_RANDOM_NAME_TIP,
            function()
                self:joinClanSuccessEvt()
            end,
            function()
                self:joinClanSuccessEvt()
            end
        )
        return
    end

    -- 点击以后会自动关闭
    local view =
        gLobalViewManager:showDialog(
        "Club/csd/Tanban/ClanCreateed.csb",
        function()
            self:joinClanSuccessEvt()
        end,
        function()
            self:joinClanSuccessEvt()
        end
    )

    if not view then
        self:joinClanSuccessEvt()
    end
end
-- 加入加入公会成功
function ClanRecuritHallView:joinClanSuccessEvt()
    local clanData = ClanManager:getClanData()
    local bJoinClan = clanData:isClanMember()
    if not bJoinClan then
        return
    end

    self:closeUI(
        function()
            gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig() -- 商城公会权益发生变化
            ClanManager:enterClanSystem(nil, self.m_viewOverFunc)
        end
    )
end

-- 快速加入公会成功
function ClanRecuritHallView:fastJoinClanSuccessEvt()
    local clanData = ClanManager:getClanData()
    local bJoinClan = clanData:isClanMember()
    if not bJoinClan then
        -- 不可以创建公会
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.CANNOT_QUICK_JOIN_CLAN)
        return
    end

    self:closeUI(
        function()
            gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig() -- 商城公会权益发生变化
            ClanManager:enterClanSystem(nil, self.m_viewOverFunc)
        end
    )
end

-- 会长同意了我的加入 直接进入公会
function ClanRecuritHallView:leaderAgreeSelfJoinEvt()
    function enterClanSystem()
        gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig() -- 商城公会权益发生变化
        ClanManager:enterClanSystem(nil, self.m_viewOverFunc)
    end
    self:closeUI(enterClanSystem)
end

-- 注册事件
function ClanRecuritHallView:registerListener()
    ClanRecuritHallView.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "createClanSuccessEvt", ClanConfig.EVENT_NAME.RECIEVE_CLAN_CREATE_SUCCESS)
    gLobalNoticManager:addObserver(self, "joinClanSuccessEvt", ClanConfig.EVENT_NAME.RECIEVE_JOIN_CLAN_SUCCESS)
    gLobalNoticManager:addObserver(self, "fastJoinClanSuccessEvt", ClanConfig.EVENT_NAME.RECIEVE_FAST_JOIN_CLAN_SUCCESS)
    gLobalNoticManager:addObserver(self, "onGemCostEvt", ClanConfig.EVENT_NAME.RECIEVE_CLAN_GEM_SUCCESS)
    gLobalNoticManager:addObserver(self, "leaderAgreeSelfJoinEvt", ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA)
    gLobalNoticManager:addObserver(self, "popCreateClanPanel", ClanConfig.EVENT_NAME.POP_CREATE_CLAN_PANEL) -- 没有可加入的公会弹出创建公会面板
end

function ClanRecuritHallView:closeUI(_cb)
    self:hideParticleUI()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_FUN_OVER)
    ClanRecuritHallView.super.closeUI(self, _cb)
end

-- 隐藏粒子UI
function ClanRecuritHallView:hideParticleUI()
    local list = {"Particle_1", "Particle_2", "Particle_2_0", "Particle_2_0_0"}
    for _, name in ipairs(list) do
        local node = self:findChild(name)
        if node then
            node:setVisible(false)
        end
    end
end

function ClanRecuritHallView:setViewOverFunc(_cb)
    self.m_viewOverFunc = _cb
end

function ClanRecuritHallView:onKeyBack()
    local callback = function()
        if self.m_viewOverFunc then
            self.m_viewOverFunc()
        end
        ClanManager:exitClanSystem()
    end
    ClanRecuritHallView.super.onKeyBack(self, callback)
end

return ClanRecuritHallView
