---
--xcyy
--2018年5月23日
--TakeOrStakeRoomListView.lua

local BaseRoomData = require "data.slotsdata.BaseRoomData"
local BaseRoomView = require "Levels.BaseRoomView"
local SendDataManager = require "network.SendDataManager"
local TakeOrStakeRoomListView = class("TakeOrStakeRoomListView",BaseRoomView)

local HEART_BEAT_TIME       =       5          --心跳间隔
local LOGOUT_TIME           =       300       --无操作自动退出时长

function TakeOrStakeRoomListView:initUI(params)
    --创建时需传入machine
    self.m_machine = params.machine

    self.m_logOutTime = 0

    self.m_heart_beat_time = HEART_BEAT_TIME
    self.m_logout_time = LOGOUT_TIME
    
    --解析数据
    gLobalNoticManager:addObserver(self,function(self, params)
        local parseData = params.data
        self.m_refresh_error_times = 0
        if parseData then

            -- 切换到后台 之后 不在往下面走流程
            if self.m_machine.m_isEnterHouTai then
                return
            end
            
            --判断result是否已经返回
            local roomResult
            if self.m_roomData.m_teamData.room.result then
                roomResult = clone(self.m_roomData.m_teamData.room.result)
            end
            self.m_roomData:parseRoomData(parseData)

            if not self.m_roomData.m_teamData.room.result then
                self.m_roomData.m_teamData.room.result = roomResult
            end            

            if self.m_machine.m_bonusStartWaiting:isVisible() then
                self.m_machine:isComInSheJiao()

            -- 如果社交界面打开的话 刷新社交
            elseif self.m_machine.m_bonusView:isVisible() then
                self.m_machine.m_bonusView:upDateSheJiaoUI()
            else
                -- 玩家头像刷新 不用判断滚动状态
                self:refreshPlayInfo()
                -- 其他玩家大赢事件 不用判断滚动状态
                local eventData = self.m_roomData:getRoomEvent()
                for i,vEvent in ipairs(eventData) do
                    if (globalData.userRunData.userUdid == vEvent.udid) then
                        table.insert(self.m_machine.m_bigWinEvent, vEvent)
                    else
                        self:showBigWinAni(vEvent)
                    end
                end

                if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isRunningEffect then
                    return
                end
                
                self.m_machine:enterLevelUpDateCollectNum()
            end
            
        end
    end,ViewEventType.NOTIFY_PARSE_ROOM_DATA)

    --刷新房间数据失败
    gLobalNoticManager:addObserver(self,function(self, params)
        self:refreshError(params.errorCode,params.errorData)
    end,ViewEventType.NOTIFY_REFRESH_ROOM_ERROR)

    self:createCsbNode("TakeOrStake_Room.csb")

    self.m_playerItems = {}
    for index = 1,8 do
        local node = self:findChild("Node_Player_"..(index - 1))
        local item = util_createView("CodeTakeOrStakeSrc.TakeOrStakePlayerItem")
        node:addChild(item)
        self.m_playerItems[index] = item
    end
end

--默认按钮监听回调
function TakeOrStakeRoomListView:clickFunc(sender)
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
function TakeOrStakeRoomListView:sendRefreshData()
    local roomData = self:getRoomData()
    if roomData.extra.currentPhase == 4 then
        -- 如果等待界面打开的话 刷新等待
        if not self.m_machine.m_bonusStartWaiting:isVisible() then
            --当前状态判断 滚轮转动时不刷新数据
            if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isTriggerBonus then
                return
            end
        end
        self:updataServerData()
    else
        -- 如果社交界面打开的话 刷新社交
        if not self.m_machine.m_bonusView:isVisible() then
            --当前状态判断 滚轮转动时不刷新数据
            if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isTriggerBonus then
                return
            end
        end
        local gameName = self.m_machine:getNetWorkModuleName()

        local function success()
            
        end

        local function failed(errorCode, errorData)
            
        end

        self.m_refreshTime = os.time()

        if roomData.extra.currentPhase then
            self:updataServerData()
        else
            gLobalSendDataManager:getNetWorkFeature():refreshRoomData(gameName,success,failed)
        end
    end
end

-- 等待其他玩家 进入的时候 发送这个 消息
function TakeOrStakeRoomListView:updataServerData( )
    local httpSendMgr = SendDataManager:getInstance()
    local gameName = self.m_machine:getNetWorkModuleName()
    if globalData.slotRunData.isDeluexeClub == true then
        gameName = gameName .. "_H"
    end

    local roomData = self.m_machine.m_roomList:getRoomData()
    local actionData = httpSendMgr:getNetWorkSlots():getSendActionData(ActionType.TeamMissionRefresh, gameName)
    local params = {}
    params.action = 2
    actionData.data.params = json.encode(params)
    httpSendMgr:getNetWorkSlots():sendMessageData(actionData)
end

--[[
    开始刷新数据
]]
function TakeOrStakeRoomListView:startRefresh()
    --正在显示系统弹版
    -- if self.m_machine.m_isShowSystemView then
    --     return
    -- end
    --刷帧前先刷新一次数据
    self:sendRefreshData()
    self.m_logOutTime = 0
    --刷帧
    self:onUpdate(function(dt)
        local time = os.time()
        local time1 = time - self.m_refreshTime
        local refreshTime = os.time() - self.m_refreshTime
        self.m_logOutTime = self.m_logOutTime + dt

        if refreshTime < self.m_heart_beat_time then
            return
        end

        self.m_refreshTime = os.time()
        --当前状态判断 滚轮转动时不刷新数据
        if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine.m_isRunningEffect then
            return
        end
        --超时无操作退出到大厅
        if self.m_logOutTime >= self.m_logout_time then
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
function TakeOrStakeRoomListView:resetLogoutTime( )
    self.m_logOutTime = 0
end

--[[
    刷新房间数据失败
]]
function TakeOrStakeRoomListView:refreshError(errorCode,errorData)
    self.m_refresh_error_times = self.m_refresh_error_times + 1
    if self.m_refresh_error_times >= 3 then
        
    end
end

--[[
    更换房间成功
]]
function TakeOrStakeRoomListView:changeSuccess()
    self.m_isWaiting = false

    self:playTouXiangEffect()
end

--默认按钮监听回调
function TakeOrStakeRoomListView:clickFunc(sender)
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
    
    gLobalSoundManager:playSound("TakeOrStakeSounds/sound_TakeOrStake_touxiang_click.mp3")
    self:sendChangeRoom()
end

-- 播放头像动画
function TakeOrStakeRoomListView:playTouXiangEffect( )
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
            item:playEffectByComeInOrChange()
        end
    end
end

--[[
    刷新玩家信息
]]
function TakeOrStakeRoomListView:refreshPlayInfo()
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

function TakeOrStakeRoomListView:getPlayersInfo()
    local setData = {}

    local result = self.m_roomData:getSpotResult()

    -- 玩法触发后需要优先取触发座位的数据
    -- 因为房间数据内可能不包含触发玩法后立刻断线玩家的数据
    setData = clone(self.m_roomData:getRoomPlayersInfo()) 
    if #setData <= 0 then
        if result then
            setData = result.data.sets or {}
        end
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

--[[
    显示大赢动画
]]
function TakeOrStakeRoomListView:showBigWinAni(eventData)
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
end

function TakeOrStakeRoomListView:getBigWinTypeByID(eventData,_udid)

    if eventData.udid == _udid then
        return eventData.eventType
    end

    return nil
end

function TakeOrStakeRoomListView:onExit()
    self:unscheduleUpdate()
    gLobalNoticManager:removeAllObservers(self)
    if self.m_roomData.m_teamData.room and self.m_roomData.m_teamData.room.extra and 
        self.m_roomData.m_teamData.room.extra.currentPhase then
            if self.m_roomData.m_teamData.room.extra.overTake then
                --发送退出房间消息
                self:sendLogOutRoom( )
            end
    else
        --发送退出房间消息
        self:sendLogOutRoom( )
    end
end

return TakeOrStakeRoomListView