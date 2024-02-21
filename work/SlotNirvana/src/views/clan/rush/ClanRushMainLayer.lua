--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-27 16:12:01
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-27 17:25:15
FilePath: /SlotNirvana/src/views/clan/rush/ClanRushMainLayer.lua
Description: 公会Rush 主弹板
--]]
local ClanRushMainLayer = class("ClanRushMainLayer", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRushMainLayer:initDatas(_rushData)
    ClanRushMainLayer.super.initDatas(self)

    self.m_tagLockView = {}

    self.m_rushData = _rushData
    self.m_taskDataList = _rushData:getTaskList()
    self.m_chooseIdx = _rushData:getCurTaskIdx()
    self.m_curTaskIdx = _rushData:getCurTaskIdx()

    self:setKeyBackEnabled(true)
    self:setExtendData("ClanRushMainLayer")
    self:setLandscapeCsbName("Club/csd/Rush/Rush_ranking.csb")
end

function ClanRushMainLayer:initCsbNodes()
    self.m_lbLeftTime = self:findChild("txt_time")
end

function ClanRushMainLayer:initView()
    -- 任务tag按钮 enabled
    self:initTaskTagBtnEnabled() 
    -- 任务subTileUI
    self:initTaskSubTitleUI()
    -- 任务进度UI
    self:initTaskProgUI()
    -- 本公会玩家贡献
    for i=1,3 do
        local data = self.m_taskDataList[i]
        self:initMemberListUI(i, data)
    end
    -- 贡献值限制tip
    self:initTipUI()
    -- 任务剩余时间
    self.m_scheduler = schedule(self, handler(self, self.updateLeftTimeUI), 1)
    self:updateLeftTimeUI()
    -- 触摸mask
    self:initMaskUI()
    self:runCsbAction("idle", true)

    self:updateTaskUIVisible(self.m_chooseIdx)
end

-- 任务tag按钮 enabled
function ClanRushMainLayer:initTaskTagBtnEnabled() 
    for i=1,3 do
        local btn = self:findChild("btn_rush" .. i)
        local btnLock = self:findChild("btn_rushLock" .. i)
        local nodeLock = self:findChild("node_lock" .. i)
        local lockView = util_createAnimation("Club/csd/Rush/node_rush_lock.csb")
        nodeLock:addChild(lockView)
        self.m_tagLockView[i] = lockView 

        btn:setTouchEnabled(self.m_curTaskIdx >= i)
        btnLock:setVisible(self.m_curTaskIdx < i)
    end
end

-- 任务subTileUI
function ClanRushMainLayer:initTaskSubTitleUI()
    for i=1,3 do
        local parent = self:findChild("node_subTitle_" .. i)
        local data = self.m_taskDataList[i]
        if parent and data then
            local view = util_createView("views.clan.rush.ClanRushMainSubTitleUI", data)
            parent:addChild(view)
        end
    end
end

-- 任务进度UI
function ClanRushMainLayer:initTaskProgUI()
    for i=1,3 do
        local parent = self:findChild("node_prog_" .. i)
        local data = self.m_taskDataList[i]
        if parent and data then
            local view = util_createView("views.clan.rush.ClanRushProgressUI", data, 3)
            parent:addChild(view)
        end
    end
end

-- 本公会玩家贡献
function ClanRushMainLayer:initMemberListUI(_idx, _taskData)
    local listView = self:findChild("ListView_" .. _idx)
    if not listView or not _taskData then
        return
    end

    listView:removeAllItems()
	listView:setTouchEnabled(true)
    listView:setScrollBarEnabled(false)

    local memberList = _taskData:getMemberList() 
    if #memberList <= 0 then
        return
    end
    
    local imgPath = _taskData:getTaskIconPath()
    for i=1, #memberList do
        local data = memberList[i]
        local view = self:createMemberCellUI(imgPath, data)
        listView:pushBackCustomItem(view)
    end
end

-- 创建本公会玩家 cellUI
function ClanRushMainLayer:createMemberCellUI(_imgPath, _data)
    local layout = ccui.Layout:create()
    local itemUI = util_createView("views.clan.rush.ClanRushMemberCellUI", _imgPath, _data)
    layout:addChild(itemUI)
    layout:setContentSize(cc.size(1068,72))
    itemUI:move(1068*0.5, 72*0.5)

    -- layout:setBackGroundColorOpacity(200)
	-- layout:setBackGroundColorType(2)
	-- layout:setBackGroundColor(cc.c3b(0,255,0))

    return layout
end

-- 贡献值限制tip
function ClanRushMainLayer:initTipUI()
    for i=1,3 do
        local lbValue = self:findChild("lb_desc_value_" .. i)
        local data = self.m_taskDataList[i]
        if lbValue and data then
            local limitCount = data:getLimitValue()
            local needCount = data:getNeedCount()
            lbValue:setString(limitCount)
            lbValue:setVisible(needCount ~= limitCount)
        end
    end
end

-- 任务剩余时间
function ClanRushMainLayer:updateLeftTimeUI()
    local expireAt = self.m_rushData:getExpireAt()
    local leftTimeStr, bOver = util_daysdemaining(expireAt)
    if bOver then
        self:closeUI()
        return
    end
    
    self.m_lbLeftTime:setString(leftTimeStr)
end

-- 触摸mask
function ClanRushMainLayer:initMaskUI()
    local touchMask = util_makeTouch(gLobalViewManager:getViewLayer(), "touch_mask") 
    touchMask:move(display.center)
    self:addChild(touchMask)
    self:addClick(touchMask)
end

function ClanRushMainLayer:updateTaskUIVisible(_idx)
    for i=1,3 do
        -- 副标题
        local nodeSubTitle = self:findChild("node_subTitle_" .. i)
        nodeSubTitle:setVisible(_idx == i)
        -- 进度
        local nodeProg = self:findChild("node_prog_" .. i)
        nodeProg:setVisible(_idx == i)
        -- 排行列表
        local nodeListView = self:findChild("ListView_" .. i)
        nodeListView:setVisible(_idx == i)
        -- 贡献限制描述
        local nodeDesc = self:findChild("node_desc_" .. i)
        local lbValue = self:findChild("lb_desc_value_" .. i)
        nodeDesc:setVisible(_idx == i and lbValue:isVisible())
        -- tag按钮
        local btn = self:findChild("btn_rush" .. i)
        btn:setEnabled(_idx ~= i)
    end
end

function ClanRushMainLayer:clickFunc(sender)
    local name = sender:getName()
    
    if string.find(name, "btn_rush") then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end

    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_rush1" then
        self:updateTaskUIVisible(1)
    elseif name == "btn_rush2" then
        self:updateTaskUIVisible(2)
    elseif name == "btn_rush3" then
        self:updateTaskUIVisible(3)
    elseif name == "btn_rushLock1" and self.m_tagLockView[1] then
        self.m_tagLockView[1]:playAction("idle")
    elseif name == "btn_rushLock2" and self.m_tagLockView[2] then
        self.m_tagLockView[2]:playAction("idle")
    elseif name == "btn_rushLock3" and self.m_tagLockView[3] then
        self.m_tagLockView[3]:playAction("idle")
    elseif name == "touch_mask" then
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.HIDE_RUSH_GIT_BUBBLE_TIP)
    end
end


-- 注册事件
function ClanRushMainLayer:registerListener()
    ClanRushMainLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.CLOSE_CLAN_HOME_VIEW) -- 关闭公会
end

-- 清楚定时器
function ClanRushMainLayer:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

return ClanRushMainLayer