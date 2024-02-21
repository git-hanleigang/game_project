---
--xcyy
--2018年5月23日
--MiningManiaRoomListView.lua

local BaseRoomData = require "data.slotsdata.BaseRoomData"
local BaseRoomView = require "Levels.BaseRoomView"
local SendDataManager = require "network.SendDataManager"
local MiningManiaRoomListView = class("MiningManiaRoomListView",BaseRoomView)

local HEART_BEAT_TIME       =       5          --心跳间隔
local LOGOUT_TIME           =       300       --无操作自动退出时长

function MiningManiaRoomListView:initUI(params)
    --创建时需传入machine
    self.m_machine = params.machine

    self.m_logOutTime = 0

    self.m_heart_beat_time = HEART_BEAT_TIME
    
    --解析数据
    gLobalNoticManager:addObserver(self,function(self, params)
        local parseData = params.data
        self.m_refresh_error_times = 0
        if parseData then

            --判断result是否已经返回
            local roomResult
            if self.m_roomData.m_teamData.room.result then
                roomResult = clone(self.m_roomData.m_teamData.room.result)
            end
            self.m_roomData:parseRoomData(parseData)

            if not self.m_roomData.m_teamData.room.result then
                self.m_roomData.m_teamData.room.result = roomResult
            end            

            if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isRunningEffect then
                return
            end
            self:refreshPlayInfo()
            --其他玩家大赢事件
            local eventData = self.m_roomData:getRoomEvent()
            self:showBigWinAni(eventData)
        end
    end,ViewEventType.NOTIFY_PARSE_ROOM_DATA)

    --刷新房间数据失败
    gLobalNoticManager:addObserver(self,function(self, params)
        self:refreshError(params.errorCode,params.errorData)
    end,ViewEventType.NOTIFY_REFRESH_ROOM_ERROR)

    self:createCsbNode("MiningMania_Room.csb")
    self.m_node_players = {}
    self.m_playerItems = {}
    for index = 1, 5 do
        local node = self:findChild("Seat_"..(index - 1))
        self.m_node_players[index] = node

        local item = util_createView("CodeMiningManiaSrc.MiningManiaPlayerItem")
        node:addChild(item)
        self.m_playerItems[index] = item
    end
end

--默认按钮监听回调
function MiningManiaRoomListView:clickFunc(sender)
    --当前状态判断 滚轮转动时不能切换房间
    if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isRunningEffect then
        return
    end
    --等待网络消息返回
    if self.m_isWaiting then
        return        
    end

    local name = sender:getName()
    local tag = sender:getTag()
    self.m_isWaiting = true
    
    self:sendChangeRoom()
end

--[[
    刷新数据
]]
function MiningManiaRoomListView:sendRefreshData()
    --当前状态判断 滚轮转动时不刷新数据
    if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isTriggerBonus then
        return
    end
    local gameName = self.m_machine:getNetWorkModuleName()

    local function success()
        
    end

    local function failed(errorCode, errorData)
        
    end

    self.m_refreshTime = 0

    gLobalSendDataManager:getNetWorkFeature():refreshRoomData(gameName,success,failed)
end


--[[
    开始刷新数据
]]
function MiningManiaRoomListView:startRefresh()
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
        if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isRunningEffect then
            return
        end
        --超时无操作退出到大厅
        if self.m_logOutTime >= LOGOUT_TIME then
            self:stopRefresh()
            --显示退出游戏提示
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
function MiningManiaRoomListView:resetLogoutTime( )
    self.m_logOutTime = 0
end

--[[
    刷新房间数据失败
]]
function MiningManiaRoomListView:refreshError(errorCode,errorData)
    self.m_refresh_error_times = self.m_refresh_error_times + 1
    if self.m_refresh_error_times >= 3 then
        
    end
end

--[[
    更换房间成功
]]
function MiningManiaRoomListView:changeSuccess()
    self.m_isWaiting = false
end

--[[
    刷新玩家信息
]]
function MiningManiaRoomListView:refreshPlayInfo()
    local playersInfo = self.m_roomData:getRoomPlayersInfo()

    if #playersInfo == 0 then
        return
    end

    for index = 1, 5 do
        local info = playersInfo[index]
        local item = self.m_playerItems[index]
        if info then

            info.rank = index
            item:setVisible(true)
            local udid = item:getPlayerID()
            local robot = item:getPlayerRobotInfo()
            item:refreshData(info)
            --刷新头像
            if udid ~= info.udid then
                item:refreshHead()
            end


            if info.udid and info.udid ~= "" then
                --刷新头像
                if udid ~= info.udid  then
                    item:refreshHead()
                end
            else
                -- 刷新机器人头像
                if robot and robot ~= info.robot  then
                    item:refreshHead()
                end
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
    显示大赢动画
]]
function MiningManiaRoomListView:showBigWinAni(eventData)
    local playersInfo = self.m_roomData:getRoomPlayersInfo()
    for _eventIndex,_data in ipairs(eventData) do
        for _playerIndex,_item in ipairs(self.m_playerItems) do
            local playerInfo = _item:getPlayerInfo()
            local udid = _item:getPlayerID()
            if globalData.userRunData.userUdid ~= udid then
                if playerInfo and playerInfo.udid == _data.udid then
                    _item:showBigWinAni(_data.eventType) 
                end
            end
        end
    end
end

--显示大赢动画（自己）
function MiningManiaRoomListView:showSelfBigWinAni(winType)
    for index = 1,#self.m_playerItems do
        local item = self.m_playerItems[index]
        local udid = item:getPlayerID()
        if globalData.userRunData.userUdid == udid then
            if winType then
                item:showBigWinAni(winType)
            end
            break
        end
    end
end

return MiningManiaRoomListView
