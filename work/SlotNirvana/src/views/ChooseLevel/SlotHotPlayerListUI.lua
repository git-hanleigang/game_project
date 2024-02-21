--[[
Author: cxc
Date: 2022-04-20 18:02:05
LastEditTime: 2022-04-20 18:02:06
LastEditors: cxc
Description: 关卡 热玩 玩家列表UI
FilePath: /SlotNirvana/src/views/ChooseLevel/SlotHotPlayerListUI.lua
--]]
local SlotHotPlayerListUI = class("SlotHotPlayerListUI", BaseView)
local SlotHotPlayerTableView = util_require("views.ChooseLevel.SlotHotPlayerTableView")
local AvatarFrameConfig = util_require("GameModule.Avatar.config.AvatarFrameConfig")

function SlotHotPlayerListUI:getCsbName()
    return "BetChoice/BetChoice_slot_frame.csb"
end

function SlotHotPlayerListUI:initCsbNodes()
    self.m_spBg = self:findChild("sp_bg")
    self.m_layout = self:findChild("layout_user")
    self.m_loadingNode = self:findChild("node_loading")
end

function SlotHotPlayerListUI:initUI(_parentScale)
    SlotHotPlayerListUI.super.initUI(self)

    self.m_parentScale = _parentScale or 1

    -- 适配
    self:adaptUI()
    -- 初始化 tableView
    self:createTableView()
    -- 初始化 loading动画
    self:createLoadingEfUI()

    self:registerListener()
end

-- 适配
function SlotHotPlayerListUI:adaptUI()
    -- 背景
    local bgSize = self.m_spBg:getContentSize()
    local bgSizeNew = cc.size(bgSize.width * self.m_parentScale , bgSize.height)
    self.m_spBg:setContentSize(bgSizeNew)
    -- layout
    local listViewSize = self.m_layout:getContentSize()
    self.m_layout:setContentSize(bgSize.width * self.m_parentScale, bgSize.height)
    -- loading动画
    self.m_loadingNode:move(bgSizeNew.width*0.5, bgSizeNew.height*0.5)
end

-- 初始化 tableView
function SlotHotPlayerListUI:createTableView()
    local size = self.m_layout:getContentSize()
    local param = {
        tableSize = size,
        parentPanel = self.m_layout,
        directionType = 1
    }
    self.m_tableView = SlotHotPlayerTableView.new(param)
    self.m_layout:addChild(self.m_tableView)
end

-- 初始化 loading动画
function SlotHotPlayerListUI:createLoadingEfUI()
    local view = util_createAnimation("BetChoice/BetChoice_loading.csb")
    self.m_loadingNode:addChild(view)
    view:playAction("idle", true)
    self:updateLoadingEfUIVisible({})
end

-- 更新玩家数据
function SlotHotPlayerListUI:updatePlayersUI(_levelName)
    self.m_tableView:reload({})
    self:updateLoadingEfUIVisible({})
    
    self.m_levelName = _levelName
    G_GetMgr(G_REF.AvatarFrame):sendHotPlayerReq(_levelName)
end

-- 请求关卡热玩玩家信息成功
function SlotHotPlayerListUI:onRecieveHotPlayersSuccessEvt()
    local list = G_GetMgr(G_REF.AvatarFrame):getHotPlayersData(self.m_levelName, true)
    self.m_tableView:reload(list)
    if not self.m_bDeal then
        util_setCascadeOpacityEnabledRescursion(self.m_layout, true)
        self.m_bDeal = true
    end
    self:updateLoadingEfUIVisible(list)
end

-- 注册消息事件
function SlotHotPlayerListUI:registerListener()
    gLobalNoticManager:addObserver(self, "onRecieveHotPlayersSuccessEvt", AvatarFrameConfig.EVENT_NAME.RECIEVE_HOT_PLAYER_LIST_SUCCESS)
    gLobalNoticManager:addObserver(self, "onRecieveHotPlayersSuccessEvt", ViewEventType.NOTIFY_AVATAR_FRME_RES_DOWNLOAD_COMPLETE)
end

function SlotHotPlayerListUI:updateLoadingEfUIVisible(_list)
    self.m_loadingNode:setVisible(#_list == 0)
end

return SlotHotPlayerListUI