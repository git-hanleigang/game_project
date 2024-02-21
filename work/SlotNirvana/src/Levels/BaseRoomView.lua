---
--xcyy
--2018年5月23日
--BaseRoomView.lua

local BaseRoomData = require "data.slotsdata.BaseRoomData"
local BaseView = util_require("base.BaseView")
local SendDataManager = require "network.SendDataManager"
local BaseRoomView = class("BaseRoomView",BaseView)

local HEART_BEAT_TIME       =       10          --心跳间隔

function BaseRoomView:ctor()
    BaseView.ctor(self)
    self.m_roomData = BaseRoomData.new()--BaseRoomData:getInstance()
    self.m_heart_beat_time = HEART_BEAT_TIME
    self.m_refresh_error_times = 0
end

function BaseRoomView:initUI(params)
    --创建时需传入machine
    self.m_machine = params.machine
    
    --解析数据
    gLobalNoticManager:addObserver(self,function(self, params)
        self.m_refresh_error_times = 0
        local parseData = params.data
        if parseData then
            self.m_roomData:parseRoomData(parseData)
        end
    end,ViewEventType.NOTIFY_PARSE_ROOM_DATA)

    --刷新房间数据失败
    gLobalNoticManager:addObserver(self,function(self, params)
        self:refreshError(params.errorCode,params.errorData)
    end,ViewEventType.NOTIFY_REFRESH_ROOM_ERROR)
end

function BaseRoomView:onEnter()
    self.m_refreshTime = 0
    
    self:refreshPlayInfo()

    --开始刷帧
    self:startRefresh()

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
    刷新房间数据失败
]]
function BaseRoomView:refreshError(errorCode,errorData)
    self.m_refresh_error_times = self.m_refresh_error_times + 1
    if self.m_refresh_error_times >= 3 then
        gLobalViewManager:showReConnect(true)
    end
end

function BaseRoomView:onExit()
    self:unscheduleUpdate()
    gLobalNoticManager:removeAllObservers(self)
    --发送退出房间消息
    self:sendLogOutRoom( )
end

--[[
    开始刷新数据
]]
function BaseRoomView:startRefresh()
    --刷帧前先刷新一次数据
    self:sendRefreshData()
    --刷帧
    self:onUpdate(function(dt)
        self.m_refreshTime = self.m_refreshTime + dt
        if self.m_refreshTime < self.m_heart_beat_time then
            return
        end

        

        self.m_refreshTime = 0
        --当前状态判断 滚轮转动时不刷新数据
        if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE then
            return
        end
        --刷新数据
        self:sendRefreshData()
    end)
end

--[[
    停止刷新数据
]]
function BaseRoomView:stopRefresh()
    self:unscheduleUpdate()
    self.m_refreshTime = 0
end

--默认按钮监听回调
function BaseRoomView:clickFunc(sender)
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
    切换房间
]]
function BaseRoomView:sendChangeRoom()
    local headManager = G_GetMgr(G_REF.Avatar)
    headManager:removeDownloadInfo()

    local gameName = self.m_machine:getNetWorkModuleName()
    gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReset(
        gameName,
        function()
            if not tolua.isnull(self) then
                self:changeSuccess()
            end
        end,
        function(errorCode, errorData)
            util_printLog("-----changeRoom errorCode -----"..errorCode,true)
            if not tolua.isnull(self) then
                self:changeFailed()
            end
            
        end
    )
end

function BaseRoomView:changeSuccess()
    self.m_isWaiting = false
    -- self:refreshPlayInfo()
end

function BaseRoomView:changeFailed()
    self.m_isWaiting = false
end


--[[
    刷新玩家信息接口 需子类实现
]]
function BaseRoomView:refreshPlayInfo()
    
end

--[[
    获取房间数据
]]
function BaseRoomView:getRoomData( )
    return self.m_roomData:getRoomData()
end

--[[
    刷新房间数据成功
]]
function BaseRoomView:refreshSuccess()
    
end

--[[
    刷新数据
]]
function BaseRoomView:sendRefreshData()
    --当前状态判断 滚轮转动时不刷新数据
    if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE then
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

    gLobalSendDataManager:getNetWorkFeature():refreshRoomData(gameName,success,failed)
end

--[[
    发送退出房间
]]
function BaseRoomView:sendLogOutRoom( )
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():sendActionData_ExitRoom()
end

return BaseRoomView