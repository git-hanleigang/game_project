---
--xcyy
--2018年5月23日
--LuckyRacingRoomListView.lua

local BaseRoomData = require "data.slotsdata.BaseRoomData"
local BaseRoomView = require "Levels.BaseRoomView"
local SendDataManager = require "network.SendDataManager"
local LuckyRacingRoomListView = class("LuckyRacingRoomListView",BaseRoomView)

local HEART_BEAT_TIME       =       5          --心跳间隔
local LOGOUT_TIME           =       600       --无操作自动退出时长

function LuckyRacingRoomListView:initUI(params)
    --创建时需传入machine
    self.m_machine = params.machine

    self.m_logOutTime = 0

    self.m_heart_beat_time = HEART_BEAT_TIME
    
    --解析数据
    gLobalNoticManager:addObserver(self,function(self, params)
        local parseData = params.data
        self.m_refresh_error_times = 0

        if params.spinResult and params.spinResult ~= "" then
            local levelsTable = cjson.decode(params.spinResult)
            if levelsTable.gameConfig then
                self.m_machine:initGameStatusData(levelsTable)
            end
            
        end


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

    self:createCsbNode("LuckyRacing_ChangeRoom.csb")

    self.m_playerItems = {}
    self.m_chooseBg = {}
    for index = 1,4 do
        local item = util_createView("CodeLuckyRacingSrc.LuckyRacingPlayerHead",{index = index})
        self.m_playerItems[index] = item
        self:findChild("touxiang_"..(index - 1)):addChild(item,10)

        local choose_bg = util_createAnimation("LuckyRacing_xuanzekuang.csb")
        choose_bg:runCsbAction("idleframe",true)
        self:findChild("touxiang_"..(index - 1)):addChild(choose_bg,5)
        choose_bg:setVisible(false)
        self.m_chooseBg[index] = choose_bg
    end
end

function LuckyRacingRoomListView:onEnter()
    self.m_refreshTime = 0
    
    self:refreshPlayInfo()

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

--默认按钮监听回调
function LuckyRacingRoomListView:clickFunc(sender)
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
function LuckyRacingRoomListView:sendRefreshData()
    --当前状态判断 滚轮转动时不刷新数据
    if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isTriggerTeamMission then
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
function LuckyRacingRoomListView:startRefresh()
    --正在显示系统弹版
    if self.m_machine.m_isShowSystemView or not self.m_machine.m_curSelect then
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
function LuckyRacingRoomListView:resetLogoutTime( )
    self.m_logOutTime = 0
end

--[[
    刷新房间数据失败
]]
function LuckyRacingRoomListView:refreshError(errorCode,errorData)
    self.m_refresh_error_times = self.m_refresh_error_times + 1
    if self.m_refresh_error_times >= 3 then
        
    end
end

--[[
    更换房间成功
]]
function LuckyRacingRoomListView:changeSuccess()
    self.m_isWaiting = false
end

--[[
    刷新玩家信息
]]
function LuckyRacingRoomListView:refreshPlayInfo()
    local playersInfo = clone(self.m_roomData:getRoomPlayersInfo())
    --当前选的马
    local curChoose = self.m_machine.m_curSelect
    if not curChoose or curChoose == -1 then
        curChoose = 0
    end

    --将自己放在对应颜色的座位上
    for index = 1,4 do
        local info = playersInfo[index]
        if info and info.udid == globalData.userRunData.userUdid and index ~= curChoose + 1 then
            local temp = playersInfo[index]
            playersInfo[index] = playersInfo[curChoose + 1]
            playersInfo[curChoose + 1] = temp
            break
        end
    end

    for index = 1,4 do
        local info = playersInfo[index]
        local item = self.m_playerItems[index]
        local bg = self.m_chooseBg[index]
        bg:setVisible(false)
        if info then
            local udid = item:getPlayerID()
            local robot = item:getPlayerRobotInfo()
            item:refreshData(info)

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
            item:refreshHead()
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
    触发动画
]]
function LuckyRacingRoomListView:playTriggerAni(udid,func)
    for index = 1,4 do
        local item = self.m_playerItems[index]
        local playerID = item:getPlayerID()
        if playerID and playerID == udid then
            item:playTriggerAni(func)
            break
        end
    end
end

function LuckyRacingRoomListView:getBigWinTypeByID(eventData,_udid)
    
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
function LuckyRacingRoomListView:showBigWinAni(eventData,func)
    local isBigWin = false

    local playersInfo = self.m_roomData:getRoomPlayersInfo()
    for index = 1,4 do
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

return LuckyRacingRoomListView