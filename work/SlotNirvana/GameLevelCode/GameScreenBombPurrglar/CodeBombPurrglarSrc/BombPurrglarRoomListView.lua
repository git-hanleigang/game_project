---
--xcyy
--2018年5月23日
--BombPurrglarRoomListView.lua

local BaseRoomData = require "data.slotsdata.BaseRoomData"
local BaseRoomView = require "Levels.BaseRoomView"
local SendDataManager = require "network.SendDataManager"
local BombPurrglarRoomListView = class("BombPurrglarRoomListView",BaseRoomView)

local HEART_BEAT_TIME       =       5          --心跳间隔
local LOGOUT_TIME           =       300       --无操作自动退出时长

function BombPurrglarRoomListView:initUI(params)
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

            -- 玩家头像刷新 不用判断滚动状态
            self:refreshPlayInfo()
            -- 其他玩家大赢事件 不用判断滚动状态
            local eventData = self.m_roomData:getRoomEvent()
            self:showBigWinAni(eventData)

            -- 当前状态判断 滚轮转动时不刷新数据
            if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isRunningEffect then
                return
            end
            
            self.m_machine:enterLevelUpDateCollectNum()
        end
    end,ViewEventType.NOTIFY_PARSE_ROOM_DATA)

    --刷新房间数据失败
    gLobalNoticManager:addObserver(self,function(self, params)
        self:refreshError(params.errorCode,params.errorData)
    end,ViewEventType.NOTIFY_REFRESH_ROOM_ERROR)




    self:createCsbNode("BombPurrglar_Room.csb")

    self.m_playerItems = {}
    for index = 1,8 do
        local node = self:findChild("Node_Player_"..(index - 1))
        local item = util_createView("CodeBombPurrglarSrc.BombPurrglarPlayerItem")
        node:addChild(item)
        self.m_playerItems[index] = item
    end


    --^^^测试代码
    -- self.m_roomData.getSpotResult = function(_obj)
        
    --     local fileUtil = cc.FileUtils:getInstance()
    --     local fullPath = fileUtil:fullPathForFilename("CodeBombPurrglarSrc/resultData.json")
    --     local jsonStr = fileUtil:getStringFromFile(fullPath) 
    --     local result = cjson.decode(jsonStr)

    --     return result
    -- end

end

--默认按钮监听回调
function BombPurrglarRoomListView:clickFunc(sender)
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
function BombPurrglarRoomListView:sendRefreshData()
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
function BombPurrglarRoomListView:startRefresh()
    --正在显示系统弹版 | 未领取奖励
    if self.m_machine.m_isShowSystemView or self.m_machine:isTriggerReconnectionRewardView() then
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
function BombPurrglarRoomListView:resetLogoutTime( )
    self.m_logOutTime = 0
end

--[[
    刷新房间数据失败
]]
function BombPurrglarRoomListView:refreshError(errorCode,errorData)
    self.m_refresh_error_times = self.m_refresh_error_times + 1
    if self.m_refresh_error_times >= 3 then
        
    end
end

--[[
    更换房间成功
]]
function BombPurrglarRoomListView:changeSuccess()
    self.m_isWaiting = false
end

--[[
    刷新玩家信息
]]
function BombPurrglarRoomListView:refreshPlayInfo()
    local playersInfo = self:getPlayersInfo()

    if #playersInfo == 0 then
        return
    end

    for index = 1,8 do
        local info = playersInfo[index]
        local item = self.m_playerItems[index]
        if info then

            item:setVisible(true)

            item:refreshData(info)
            --刷新头像
            item:refreshHead()

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



function BombPurrglarRoomListView:getPlayersInfo()
    local setData = {}

    local result = self.m_roomData:getSpotResult()

    -- 玩法触发后需要优先取触发座位的数据
    -- 因为房间数据内可能不包含触发玩法后立刻断线玩家的数据
    if result then
        setData = result.data.sets or {}
    else
        setData = clone(self.m_roomData:getRoomPlayersInfo()) 
    end
    
    table.sort(setData, function(a,b)
        -- 按座位排序
        if a.chairId and b.chairId then
            return a.chairId < b.chairId
        end

        return false
    end)
    
    return setData
end

-- 获取一个玩家触发玩法后的数据包, 只有一个地方在调用 传入玩法数据 筛选玩家数据
function BombPurrglarRoomListView:getPlayerResultSetData(resultData, _chairId, _udid)
    local data = nil

    local result = resultData
    local setData = result.data.sets

    if _chairId then
        for i,_data in ipairs(setData) do
            if _chairId == _data.chairId then
                return _data
            end
        end
    end

    if _udid then
        for i,_data in ipairs(setData) do
            if _udid == _data.udid then
                return _data
            end
        end
    end

    return nil
end

--[[
    显示大赢动画
]]
function BombPurrglarRoomListView:showBigWinAni(eventData)
    local isBigWin = false

    local playersInfo = self.m_roomData:getRoomPlayersInfo()

    for _eventIndex,_data in ipairs(eventData) do
        
        for _playerIndex,_item in ipairs(self.m_playerItems) do
            local playerInfo = _item:getPlayerInfo()
            local udid = _item:getPlayerID()
            if globalData.userRunData.userUdid ~= udid then
                if playerInfo and playerInfo.udid == _data.udid then
                    isBigWin = true
                    _item:showBigWinAni(_data.eventType) 
                end
            end
        end
    end

end

--显示大赢动画（自己）
function BombPurrglarRoomListView:showSelfBigWinAni(winType)
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

function BombPurrglarRoomListView:getBigWinTypeByID(eventData,_udid)
    
    for i = 1, #eventData do
        local data = eventData[i]
        if data.udid == _udid then
            return data.eventType
        end
    end
    return nil
end


--[[
    playerItems 相关
]]
function BombPurrglarRoomListView:getPlayerItem(_udid)

    if _udid then
        for _playerIndex,_item in ipairs(self.m_playerItems) do
            local playerInfo = _item:getPlayerInfo()
            if playerInfo and playerInfo.udid == _udid then
                return _item
            end
        end
    end

    return nil
end


return BombPurrglarRoomListView