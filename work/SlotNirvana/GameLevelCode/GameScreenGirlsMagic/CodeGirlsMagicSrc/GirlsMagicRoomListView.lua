---
--xcyy
--2018年5月23日
--GirlsMagicRoomListView.lua

local BaseRoomData = require "data.slotsdata.BaseRoomData"
local BaseRoomView = require "Levels.BaseRoomView"
local SendDataManager = require "network.SendDataManager"
local GirlsMagicRoomListView = class("GirlsMagicRoomListView",BaseRoomView)

local HEART_BEAT_TIME       =       5          --心跳间隔
local LOGOUT_TIME           =       300       --无操作自动退出时长

function GirlsMagicRoomListView:initUI(params)
    --创建时需传入machine
    self.m_machine = params.machine

    self.m_heart_beat_time = HEART_BEAT_TIME

    self.m_logOutTime = 0
    
    --解析数据
    gLobalNoticManager:addObserver(self,function(self, params)
        local parseData = params.data
        self.m_refresh_error_times = 0
        if parseData then
            --已经有result数据不再解析后续数据
            if self.m_roomData.m_teamData.room.result then
                return
            end
            self.m_roomData:parseRoomData(parseData)
            self:refreshPlayInfo()
            local roomData = self:getRoomData()
            if roomData.extra then
                self.m_machine:refreshTriggerTime(roomData.extra.leftTime or 0)
            end
            
            local eventData = self.m_roomData:getRoomEvent()
            self:showBigWinAni(eventData)
        end
    end,ViewEventType.NOTIFY_PARSE_ROOM_DATA)

    --刷新房间数据失败
    gLobalNoticManager:addObserver(self,function(self, params)
        self:refreshError(params.errorCode,params.errorData)
    end,ViewEventType.NOTIFY_REFRESH_ROOM_ERROR)


    self:createCsbNode("GirlsMagic_Room.csb")

    self.m_node_players = {}
    self.m_playerItems = {}
    for index = 1,8 do
        local node = self:findChild("Node_Player_"..(index - 1))
        self.m_node_players[index] = node

        local item = util_createView("CodeGirlsMagicSrc.GirlsMagicPlayerItem", true)
        node:addChild(item)
        self.m_playerItems[index] = item
    end
end

function GirlsMagicRoomListView:onEnter()
    self.m_refreshTime = 0
    
    self:refreshPlayInfo()

    self.m_isCanRefresh = false

    --开始刷新房间数据
    gLobalNoticManager:addObserver(self,function(self, params)
        self:startRefresh()
    end,ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)

    --停止刷新房间数据
    gLobalNoticManager:addObserver(self,function(self, params)
        self:stopRefresh()
    end,ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)

    --切换房间
    gLobalNoticManager:addObserver(self,function(self, params)
        self:sendChangeRoom()
    end,ViewEventType.NOTIFY_CHANGE_ROOM)
end



--[[
    变更状态
]]
function GirlsMagicRoomListView:changeStatus(status)
    self.m_isCanRefresh = status
end

--[[
    开始刷新数据
]]
function GirlsMagicRoomListView:startRefresh()
    --正在显示系统弹版
    if self.m_machine.m_isShowSystemView then
        return
    end
    --刷帧前先刷新一次数据
    self:sendRefreshData()
    self.m_logOutTime = 0
    --刷帧
    self:onUpdate(function(dt)
        self.m_refreshTime = self.m_refreshTime + dt
        self.m_logOutTime = self.m_logOutTime + dt
        if self.m_refreshTime < self.m_heart_beat_time then
            return
        end

        self.m_refreshTime = 0
        --当前状态判断 滚轮转动时不刷新数据
        if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE then
            return
        end

        --超时无操作退出到大厅
        if self.m_logOutTime >= LOGOUT_TIME then
            self:stopRefresh()
            self.m_machine:showOutGame()
        else
            --刷新数据
            self:sendRefreshData()
        end
    end)
end

--[[
    重置退出时间
]]
function GirlsMagicRoomListView:resetLogoutTime( )
    self.m_logOutTime = 0
end

--[[
    刷新数据
]]
function GirlsMagicRoomListView:sendRefreshData()
    --当前状态判断 滚轮转动时不刷新数据
    if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or not self.m_isCanRefresh then
        return
    end

    local httpSendMgr = SendDataManager:getInstance()
    local gameName = self.m_machine:getNetWorkModuleName()
    if globalData.slotRunData.isDeluexeClub == true then
        gameName = gameName .. "_H"
    end

    local actionData = httpSendMgr:getNetWorkSlots():getSendActionData(ActionType.TeamMissionOption, gameName)
    local params = {}
    params.action = 2
    actionData.data.params = json.encode(params)
    httpSendMgr:getNetWorkSlots():sendMessageData(actionData)
end

function GirlsMagicRoomListView:onExit()
    self:unscheduleUpdate()
    gLobalNoticManager:removeAllObservers(self)
    --发送退出房间消息
    self:sendLogOutRoom()
end

--[[
    刷新房间数据失败
]]
function GirlsMagicRoomListView:refreshError(errorCode,errorData)
    self.m_refresh_error_times = self.m_refresh_error_times + 1
    if self.m_refresh_error_times >= 3 then
        -- self.m_machine:showOutGame()
    end
end

--[[
    刷新玩家信息
]]
function GirlsMagicRoomListView:refreshPlayInfo()
    --触发玩法后所有玩家退出房间,玩家列表要从result中取
    local playersInfo = self.m_roomData:getRoomPlayersInfo()
    local roomData = self:getRoomData()
    if roomData.result then
        playersInfo = roomData.result.data.sets
    end
    for index = 1,8 do
        local info = playersInfo[index]
        local item = self.m_playerItems[index]
        if info then
            item:setVisible(true)
            local udid = item:getPlayerID()
            --刷新头像
            if udid ~= info.udid then
                item:refreshData(info)
                item:refreshHead()
            end
        else
            item:refreshData(nil)
            item:setVisible(false)
        end
    end

    --当前状态判断 滚轮转动时不刷新数据
    if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE then
        return
    end

    
    --不做操作的情况下检测是否触发Bonus
    local isTrigger = self.m_machine:checkTriggerBonus()
    --检测到触发,把玩家直接拉到玩法里
    if isTrigger and not self.m_machine.m_isRunningEffect then
        self.m_machine:sortGameEffects()
        self.m_machine:playGameEffect()
    end
end

--[[
    刷新房间数据成功
]]
function GirlsMagicRoomListView:refreshSuccess()
    
end

--[[
    通过玩家udid获取头像
]]
function GirlsMagicRoomListView:getUserHeadItemByUdid(udid)
    for k,item in pairs(self.m_playerItems) do
        if item:getPlayerID() == udid then
            return item
        end
    end

    return nil
end

function GirlsMagicRoomListView:getBigWinTypeByID(eventData,_udid)
    
    for i = 1, #eventData do
        local data = eventData[i]
        if data.udid == _udid then
            return data.eventType
        end
    end
    return nil
end

--[[
    显示大赢动画
]]
function GirlsMagicRoomListView:showBigWinAni(eventData,func)
    local isBigWin = false

    local playersInfo = self.m_roomData:getRoomPlayersInfo()
    for index = 1,8 do
        local item = self.m_playerItems[index]
        local udid = item:getPlayerID()
        local winType = self:getBigWinTypeByID(eventData,udid)
        if winType then
            isBigWin = true
            item:showBigWinAni(winType)
        end
    end

    if not isBigWin then
        if type(func) == "function" then
            func()
        end
    else
        self.m_machine:delayCallBack(100 / 60,function(  )
            if type(func) == "function" then
                func()
            end
        end)
    end
end

--[[
    添加其他玩家大赢事件
]]
function GirlsMagicRoomListView:addOtherBigWinEffect( )
    local isBigWin = false
    local eventData = self.m_machine.m_roomData:getRoomEvent()
    local playersInfo = self.m_roomData:getRoomPlayersInfo()
    for index = 1,8 do
        local item = self.m_playerItems[index]
        local udid = item:getPlayerID()
        local winType = self:getBigWinTypeByID(eventData,udid)
        if udid ~= globalData.userRunData.userUdid and winType then
        -- if winType then
            isBigWin = true
            break;
        end
    end
    if isBigWin then
        self.m_machine:addOtherBigWinEffect(eventData)

        if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE then
            return
        end
        if not self.m_machine.m_isRunningEffect then
            self.m_machine:sortGameEffects()
            -- self.m_machine:playGameEffect()
        end
    end
    
end

return GirlsMagicRoomListView