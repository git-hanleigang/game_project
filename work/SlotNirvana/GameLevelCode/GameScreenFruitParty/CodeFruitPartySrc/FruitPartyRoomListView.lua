---
--xcyy
--2018年5月23日
--FruitPartyRoomListView.lua

local BaseRoomData = require "data.slotsdata.BaseRoomData"
local BaseRoomView = require "Levels.BaseRoomView"
local SendDataManager = require "network.SendDataManager"
local FruitPartyRoomListView = class("FruitPartyRoomListView",BaseRoomView)

local HEART_BEAT_TIME       =       5          --心跳间隔
local LOGOUT_TIME           =       600       --无操作自动退出时长

function FruitPartyRoomListView:initUI(params)
    --创建时需传入machine
    self.m_machine = params.machine

    self.m_logOutTime = 0

    self.m_rankNum = -1

    self.m_heart_beat_time = HEART_BEAT_TIME
    self.m_isInit = true
    
    --解析数据
    gLobalNoticManager:addObserver(self,function(self, params)
        local parseData = params.data
        self.m_refresh_error_times = 0
        if parseData then
            local roomResult
            if self.m_roomData.m_teamData.room.result then
                roomResult = clone(self.m_roomData.m_teamData.room.result)
            end
            self.m_roomData:parseRoomData(parseData)

            if not self.m_roomData.m_teamData.room.result then
                self.m_roomData.m_teamData.room.result = roomResult
            end

            
            --检测自己,修改自身头像
            self:updateSelfHead()

            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData

            if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isRunningEffect then
                return
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOTTO_PARTY_UPDATE_OPEN_SPOT)
            self:refreshPlayInfo()
            --其他玩家大赢事件
            local eventData = self.m_roomData:getRoomEvent()
            self:showBigWinAni(eventData)

            self.m_isInit = false
        end
    end,ViewEventType.NOTIFY_PARSE_ROOM_DATA)

    --刷新房间数据失败
    gLobalNoticManager:addObserver(self,function(self, params)
        self:refreshError(params.errorCode,params.errorData)
    end,ViewEventType.NOTIFY_REFRESH_ROOM_ERROR)

    self:createCsbNode("FruitParty_Room.csb")

    self.m_node_players = {}
    self.m_playerItems = {}
    for index = 1,8 do
        local node = self:findChild("Node_Player_"..(index - 1))
        self.m_node_players[index] = node

        local item = util_createView("CodeFruitPartySrc.FruitPartyPlayerItem")
        node:addChild(item)
        self.m_playerItems[index] = item
    end
end

--[[
    更新自身头像
]]
function FruitPartyRoomListView:updateSelfHead()
    --触发玩法后所有玩家退出房间,玩家列表要从result中取
    local playersInfo = self.m_roomData:getRoomPlayersInfo()
    
    if playersInfo then
        for k,info in pairs(playersInfo) do
            if info.udid == globalData.userRunData.userUdid then
                info.head = globalData.userRunData.HeadName or info.head
            end
        end
    end
    


    local collectDatas = self.m_roomData:getRoomCollects()
    if collectDatas then
        for k,data in pairs(collectDatas) do
            if data.udid == globalData.userRunData.userUdid then
                data.head = globalData.userRunData.HeadName or data.head
            end
        end
    end
    

    local roomData = self:getRoomData()
    if roomData.result then
        playersInfo = roomData.result.data.sets
        if playersInfo then
            for k,info in pairs(playersInfo) do
                if info.udid == globalData.userRunData.userUdid then
                    info.head = globalData.userRunData.HeadName or info.head
                end
            end
        end
        

        collectDatas = roomData.result.data.collects
        if collectDatas then
            for k,data in pairs(collectDatas) do
                if data.udid == globalData.userRunData.userUdid then
                    data.head = globalData.userRunData.HeadName or data.head
                end
            end
        end
    end
end

--默认按钮监听回调
function FruitPartyRoomListView:clickFunc(sender)
    --当前状态判断 滚轮转动时不能切换房间
    if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isRunningEffect then
        return
    end
    --等待网络消息返回
    if self.m_isWaiting then
        return        
    end

    self.m_isInit = true

    local name = sender:getName()
    local tag = sender:getTag()
    self.m_isWaiting = true
    
    self:sendChangeRoom()

    self.m_rankNum = -1
end

--[[
    刷新数据
]]
function FruitPartyRoomListView:sendRefreshData()
    --当前状态判断 滚轮转动时不刷新数据
    if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isTriggerBonus then
        return
    end
    local gameName = self.m_machine:getNetWorkModuleName()

    local function success()
        --刷新玩家信息
        -- self:refreshPlayInfo()
        -- self:refreshSuccess()
    end

    local function failed(errorCode, errorData)
        
    end

    self.m_refreshTime = 0

    gLobalSendDataManager:getNetWorkFeature():refreshRoomData(gameName,success,failed)
end


--[[
    开始刷新数据
]]
function FruitPartyRoomListView:startRefresh()
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
function FruitPartyRoomListView:resetLogoutTime( )
    self.m_logOutTime = 0
end

--[[
    刷新房间数据失败
]]
function FruitPartyRoomListView:refreshError(errorCode,errorData)
    self.m_refresh_error_times = self.m_refresh_error_times + 1
    if self.m_refresh_error_times >= 3 then
        
    end
end

--[[
    更换房间成功
]]
function FruitPartyRoomListView:changeSuccess()
    self.m_isWaiting = false
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOTTO_PARTY_UPDATE_OPEN_SPOT)
end

--[[
    刷新玩家信息
]]
function FruitPartyRoomListView:refreshPlayInfo()
    local playersInfo = self:getPlayersInfo()

    if #playersInfo == 0 then
        return
    end

    for index = 1,8 do
        local info = playersInfo[index]
        local item = self.m_playerItems[index]
        if info then

            info.rank = index
            item:setVisible(true)
            local udid = item:getPlayerID()
            item:refreshData(info)
            --刷新头像
            if udid ~= info.udid then
                item:refreshHead()
            end
            item:refreshSpotNum(self.m_isInit)
            --排名上升
            if info.udid == globalData.userRunData.userUdid then
                if index < self.m_rankNum then
                    item:showRankUpAni()
                end
                
                self.m_rankNum = index
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

function FruitPartyRoomListView:getBigWinTypeByID(eventData,_udid)
    
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
function FruitPartyRoomListView:showBigWinAni(eventData,func)
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
    获取收集数据
]]
function FruitPartyRoomListView:getPlayersInfo()
    local WinResult = self.m_roomData:getSpotResult()
    local ranks = clone(self.m_roomData:getRoomRanks()) 

    if WinResult then
        local collects = WinResult.data.collects
        local tempPlayers = {}
        for k,collectData in pairs(collects) do
            if not tempPlayers[collectData.udid]  then
                tempPlayers[collectData.udid] = {
                    facebookId = collectData.facebookId,
                    head = collectData.head,
                    udid = collectData.udid,
                    value = 1
                }
            else
                tempPlayers[collectData.udid].value = tempPlayers[collectData.udid].value + 1
            end
        end

        for k,info in pairs(ranks) do
            if tempPlayers[info.udid] then
                info.value = tempPlayers[info.udid].value
            else
                info.value = 0
            end
        end

        table.sort(ranks,function(a,b)
            return a.value > b.value
        end)
    end
    return ranks
end
return FruitPartyRoomListView