---
--xcyy
--2018年5月23日
--DazzlingDiscoRoomListView.lua
local PublicConfig = require "DazzlingDiscoPublicConfig"
local BaseRoomData = require "data.slotsdata.BaseRoomData"
local BaseRoomView = require "Levels.BaseRoomView"
local SendDataManager = require "network.SendDataManager"
local DazzlingDiscoRoomListView = class("DazzlingDiscoRoomListView",BaseRoomView)

local HEART_BEAT_TIME       =       5          --心跳间隔
local LOGOUT_TIME           =       600       --无操作自动退出时长

function DazzlingDiscoRoomListView:initUI(params)
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
            
            if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE then
                return
            end
            self:refreshPlayInfo()
        end
    end,ViewEventType.NOTIFY_PARSE_ROOM_DATA)

    --刷新房间数据失败
    gLobalNoticManager:addObserver(self,function(self, params)
        self:refreshError(params.errorCode,params.errorData)
    end,ViewEventType.NOTIFY_REFRESH_ROOM_ERROR)

    self:createCsbNode("DazzlingDisco_base_minetouxiang.csb")
    self:updateSelfHead()
    self:updateSpotNum()

    --切换房间
    self.m_btn_change_room = util_createAnimation("DazzlingDisco_anniu_changeroom.csb")
    self:findChild("Node_changeroom"):addChild(self.m_btn_change_room)
    self:addClick(self.m_btn_change_room:findChild("Button_changeroom"))
end


--[[
    刷新自己头像
]]
function DazzlingDiscoRoomListView:updateSelfHead()
    local headNode = self:findChild("sp_head")
    headNode:removeAllChildren()
    local frameId = globalData.userRunData.avatarFrameId or 10
    local headId = globalData.userRunData.HeadName
    local fbId = globalData.userRunData.facebookBindingID
    local headSize = headNode:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.Avatar):createAvatarOutClipNode(fbId,headId,nil,true,headSize)
    headNode:addChild(nodeAvatar)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
end

--[[
    刷新自己获得的spot数量
]]
function DazzlingDiscoRoomListView:updateSpotNum()
    local count = self:getSelfSpotCount()

    self:findChild("m_lb_num"):setString(count)
end

--[[
    获取自身获得的spot数量
]]
function DazzlingDiscoRoomListView:getSelfSpotCount()
    local collectList = self:getCollectsData()
    local count = 0
    for i,data in ipairs(collectList) do
        if data.udid == globalData.userRunData.userUdid then
            count = count + 1
        end
    end

    return count
end

--默认按钮监听回调
function DazzlingDiscoRoomListView:clickFunc(sender)
    --当前状态判断 滚轮转动时不能切换房间
    if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isRunningEffect then
        return
    end
    --等待网络消息返回
    if self.m_isWaiting then
        return        
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_btn_click)
    local name = sender:getName()
    local tag = sender:getTag()
    self.m_isWaiting = true
    
    self:sendChangeRoom()

end

--[[
    刷新数据
]]
function DazzlingDiscoRoomListView:sendRefreshData()
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
function DazzlingDiscoRoomListView:startRefresh()
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
function DazzlingDiscoRoomListView:resetLogoutTime( )
    self.m_logOutTime = 0
end

--[[
    刷新房间数据失败
]]
function DazzlingDiscoRoomListView:refreshError(errorCode,errorData)
    self.m_refresh_error_times = self.m_refresh_error_times + 1
    if self.m_refresh_error_times >= 3 then
        
    end
end

--[[
    更换房间成功
]]
function DazzlingDiscoRoomListView:changeSuccess()
    self.m_isWaiting = false
    self.m_machine.m_spotView:refreshView()
end

--[[
    刷新玩家信息
]]
function DazzlingDiscoRoomListView:refreshPlayInfo()
    local playersInfo = self.m_roomData:getRoomRanks()

    if #playersInfo == 0 then
        return
    end


    --当前状态判断 滚轮转动时不刷新数据
    if self.m_machine:getGameSpinStage( ) > IDLE then
        return
    end

    self:updateSpotNum()

    self.m_machine.m_spotView:refreshView()
    
    --不做操作的情况下检测是否触发Bonus
    local isTrigger = self.m_machine:checkTriggerBonus()
    --检测到触发,把玩家直接拉到玩法里
    if isTrigger and not self.m_machine.m_isRunningEffect and self.m_machine.m_isEnterOver then
        self.m_machine:sortGameEffects()
        self.m_machine:playGameEffect()
    end
end

--[[
    获取收集数据
]]
function DazzlingDiscoRoomListView:getCollectsData()
    local spotResult = self.m_roomData:getSpotResult()
    local collectDatas = self.m_roomData:getRoomCollects()
    if spotResult then
        collectDatas = spotResult.data.collects
    end
    return collectDatas
end

return DazzlingDiscoRoomListView