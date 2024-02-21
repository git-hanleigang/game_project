

local BaseRoomData = require "data.slotsdata.BaseRoomData"
local BaseRoomView = require "Levels.BaseRoomView"
local SendDataManager = require "network.SendDataManager"
local ZeusVsHadesPlayerLisitView = class("ZeusVsHadesPlayerLisitView",BaseRoomView)

local HEART_BEAT_TIME       =       5          --心跳间隔
local LOGOUT_TIME           =       300       --无操作自动退出时长

function ZeusVsHadesPlayerLisitView:initUI(params)
    --创建时需传入machine
    self.m_machine = params.machine

    self.m_heart_beat_time = HEART_BEAT_TIME

    self.m_logOutTime = 0

    self.m_chooseChirdId = nil--选择的座位id
    
    --解析数据
    gLobalNoticManager:addObserver(self,function(self, params)
        local parseData = params.data

        if self.m_chooseChirdId ~= nil then
            self.m_chooseChirdId = nil
            self:setIsCanTouch(true)
            -- --检测是否座到选择的座位上，如果是，说明这条返回消息是选择座位的返回消息
            -- local setsData = self.m_roomData.m_teamData.sets
            -- for i,data in ipairs(setsData) do
            --     if data.chairId == self.m_chooseChirdId then
            --         self.m_chooseChirdId = nil
            --         if self.m_chooseChirdId ~= nil then
            --             self.m_chooseChirdId = nil
            --             self:setIsCanTouch(true)
            --         end
            --         break
            --     end
            -- end
        end

        self.m_refresh_error_times = 0
        if parseData then
            --已经有result数据不再解析后续数据
            if self.m_roomData.m_teamData.room.result then
                return
            end
            self.m_roomData:parseRoomData(parseData)
            self:refreshPlayInfo()
            -- local roomData = self:getRoomData()
            -- if roomData.extra then
            --     self.m_machine:refreshTriggerTime(roomData.extra.leftTime or 0)
            -- end
            
            local eventData = self.m_roomData:getRoomEvent()
            self:showBigWinAni(eventData)
        end
    end,ViewEventType.NOTIFY_PARSE_ROOM_DATA)

    --刷新房间数据失败
    gLobalNoticManager:addObserver(self,function(self, params)
        self:refreshError(params.errorCode,params.errorData)
    end,ViewEventType.NOTIFY_REFRESH_ROOM_ERROR)

    self:createCsbNode("ZeusVsHades_PlayerList.csb")

    --添加遮罩
    self.m_maskLayer = util_createAnimation("ZeusVsHades_dark.csb")
    self:findChild("Node_yahei"):addChild(self.m_maskLayer)
    self.m_maskLayer:setVisible(false)

    self.m_playerItems = {}--头像
    self.m_noPlayerSpr = {}--没头像时显示的图标
    for index = 1,8 do
        local node = self:findChild("Node_player"..index)
        local item = nil
        if index <= 4 then
            item = util_createView("CodeZeusVsHadesSrc.ZeusVsHadesPlayerItem","ZeusVsHades_kuanglan1.csb")
            local bonusStartEff = util_createAnimation("ZeusVsHades/BonusStart1.csb")
            item:addChild(bonusStartEff)
            bonusStartEff:findChild("1"):setVisible(false)
            item.m_bonusStartEff = bonusStartEff
        else
            item = util_createView("CodeZeusVsHadesSrc.ZeusVsHadesPlayerItem","ZeusVsHades_kuanghong1.csb")
            local bonusStartEff = util_createAnimation("ZeusVsHades/BonusStart1.csb")
            item:addChild(bonusStartEff)
            bonusStartEff:findChild("2"):setVisible(false)
            item.m_bonusStartEff = bonusStartEff
        end
        node:addChild(item)
        table.insert(self.m_playerItems,item)
        item.m_bonusStartEff:setVisible(false)

        local spr = util_createAnimation("ZeusVsHades_PlayerListArrow.csb")
        node:addChild(spr)
        table.insert(self.m_noPlayerSpr,spr)
        spr:playAction("idle",true)

        self:addClick(self:findChild("clickPanel"..index))
    end
    
end
--显示触发玩法头像上的特效
function ZeusVsHadesPlayerLisitView:showBonusStartEff()
    local triggerPlayer = self:getRoomData().result.data.triggerPlayer
    local chairId = nil
    for i,setsInfo in ipairs(self:getRoomData().result.data.sets) do
        if setsInfo.udid == triggerPlayer.udid then
            chairId = setsInfo.chairId
            break
        end
    end
    self.m_playerItems[chairId + 1].m_bonusStartEff:setVisible(true)
    self.m_playerItems[chairId + 1].m_bonusStartEff:playAction("actionframe1",false,function ()
        self.m_playerItems[chairId + 1].m_bonusStartEff:setVisible(false)
    end)
end
function ZeusVsHadesPlayerLisitView:onEnter()
    self.m_refreshTime = 0
    
    self:refreshPlayInfo()

    self.m_isCanRefresh = false

    self.m_updateState = 0--update开启状态，0未开启，1只开退出计时，2全开

    --开始刷新房间数据
    gLobalNoticManager:addObserver(self,function(self, params)
        self:startRefresh()
    end,ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)

    --停止刷新房间数据
    gLobalNoticManager:addObserver(self,function(self, params)
        self:stopRefresh()
    end,ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)

    gLobalNoticManager:addObserver(self,function(self, params)
        self:startLogOutTime()
    end,"ZeusVsHadesPlayerLisitView_startLogOutTime")

    gLobalNoticManager:addObserver(self,function(self, params)
        self:changeStatus(params[1])
    end,"ZeusVsHadesPlayerLisitView_changeStatus")

    gLobalNoticManager:addObserver(self,function(self, params)
        self:changeUpdateState(params[1])
    end,"ZeusVsHadesPlayerLisitView_changeUpdateState")

    gLobalNoticManager:addObserver(self,function(self, params)
        self:resumeUpdate()
    end,"ZeusVsHadesPlayerLisitView_resumeUpdate")

    gLobalNoticManager:addObserver(self,function(self, params)
        self:resetLogoutTime()
    end,"ZeusVsHadesPlayerLisitView_resetLogoutTime")
    
end
--暂停后恢复update
function ZeusVsHadesPlayerLisitView:resumeUpdate()
    if self.m_updateState == 2 then
        self:startRefresh()
    elseif self.m_updateState == 1 then
        self:startLogOutTime()
    end
end
function ZeusVsHadesPlayerLisitView:changeUpdateState(state)
    self.m_updateState = state
end
--[[
    变更状态
]]
function ZeusVsHadesPlayerLisitView:changeStatus(status)
    self.m_isCanRefresh = status
end

--[[
    开始刷新数据
]]
function ZeusVsHadesPlayerLisitView:startRefresh()
    --刷帧前先刷新一次数据
    self:stopRefresh()
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
        if self.m_machine:getGameSpinStage() > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE then
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
--只开启计时
function ZeusVsHadesPlayerLisitView:startLogOutTime()
    self:stopRefresh()
    self.m_logOutTime = 0
    --刷帧
    self:onUpdate(function(dt)
        self.m_logOutTime = self.m_logOutTime + dt

        --超时无操作退出到大厅
        if self.m_logOutTime >= LOGOUT_TIME then
            self:stopRefresh()
            self.m_machine:showOutGame()
        end
    end)
end
--[[
    重置退出时间
]]
function ZeusVsHadesPlayerLisitView:resetLogoutTime()
    self.m_logOutTime = 0
end

--[[
    刷新数据
]]
function ZeusVsHadesPlayerLisitView:sendRefreshData()
    --当前状态判断 滚轮转动时不刷新数据
    if self.m_machine:getGameSpinStage() > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or not self.m_isCanRefresh then
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

function ZeusVsHadesPlayerLisitView:onExit()
    self:unscheduleUpdate()
    gLobalNoticManager:removeAllObservers(self)
    --发送退出房间消息
    self:sendLogOutRoom()
end

--[[
    刷新房间数据失败
]]
function ZeusVsHadesPlayerLisitView:refreshError(errorCode,errorData)
    self.m_refresh_error_times = self.m_refresh_error_times + 1
    if self.m_refresh_error_times >= 3 then
        -- self.m_machine:showOutGame()
    end
    if self.m_chooseChirdId ~= nil then
        self.m_chooseChirdId = nil
        self:setIsCanTouch(true)
    end
end

--[[
    刷新玩家信息
]]
function ZeusVsHadesPlayerLisitView:refreshPlayInfo()
    --触发玩法后所有玩家退出房间,玩家列表要从result中取
    local playersInfoTab = self.m_roomData:getRoomPlayersInfo()
    local roomData = self:getRoomData()
    if roomData.result then
        playersInfoTab = roomData.result.data.sets
    end
    
    for index = 1,8 do
        local info = nil
        for i,playersInfo in ipairs(playersInfoTab) do
            if playersInfo.chairId + 1 == index then
                info = playersInfo
                break
            end
        end
        local item = self.m_playerItems[index]
        local noPlayerSpr = self.m_noPlayerSpr[index]
        if info then
            self:findChild("clickPanel"..index):setVisible(false)
            noPlayerSpr:setVisible(false)
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
            self:findChild("clickPanel"..index):setVisible(true)
            noPlayerSpr:setVisible(true)
        end
    end

    --当前状态判断 滚轮转动时不刷新数据
    if self.m_machine:getGameSpinStage() > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE then
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
--隐藏所有箭头
function ZeusVsHadesPlayerLisitView:hideAllNoPlayerSpr()
    for i,noPlayerSpr in ipairs(self.m_noPlayerSpr) do
        noPlayerSpr:setVisible(false)
    end
end
--[[
    通过玩家udid获取头像
]]
function ZeusVsHadesPlayerLisitView:getUserHeadItemByUdid(udid)
    for k,item in pairs(self.m_playerItems) do
        if item:getPlayerID() == udid then
            return item
        end
    end

    return nil
end

function ZeusVsHadesPlayerLisitView:getBigWinTypeByID(eventData,_udid)
    for i = 1, #eventData do
        local data = eventData[i]
        if data.udid == _udid then
            return data.eventType
        end
    end
    return nil
end

--[[
    显示大赢动画（非自己）
]]
function ZeusVsHadesPlayerLisitView:showBigWinAni(eventData)
    local isBigWin = false
    local playersInfo = self.m_roomData:getRoomPlayersInfo()
    for index = 1,8 do
        local item = self.m_playerItems[index]
        local udid = item:getPlayerID()
        local winType = nil
        if globalData.userRunData.userUdid ~= udid then
            winType = self:getBigWinTypeByID(eventData,udid)
        end
        if winType then
            isBigWin = true
            item:showBigWinAni(winType)
        end
    end
end
--显示大赢动画（自己）
function ZeusVsHadesPlayerLisitView:showSelfBigWinAni(winType)
    local playersInfo = self.m_roomData:getRoomPlayersInfo()
    for index = 1,8 do
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

--设置是否可以点击触摸
function ZeusVsHadesPlayerLisitView:setIsCanTouch(isCanTouch)
    for i = 1,8 do
        self:findChild("clickPanel"..i):setTouchEnabled(isCanTouch)
    end
end
function ZeusVsHadesPlayerLisitView:clickFunc(sender)
    if self.m_machine.m_bottomUI.m_btn_add:isTouchEnabled() == true then
        local name = sender:getName()
        local index = tonumber(string.match(name,"%d+"))
        self:chooseCharSendData(index - 1)
    end
end
function ZeusVsHadesPlayerLisitView:chooseCharSendData(chairId)
    self:setIsCanTouch(false)
    self.m_chooseChirdId = chairId
    local httpSendMgr = SendDataManager:getInstance()
    local gameName = self.m_machine:getNetWorkModuleName()
    if globalData.slotRunData.isDeluexeClub == true then
        gameName = gameName .. "_H"
    end
    local choose = 0
    if chairId >= 4 then
        choose = 1
    end
    --数据发送
    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {
        msg = MessageDataType.MSG_TEAM_MISSION_JOIN, 
        game = gameName,
        roomId = self.m_roomData.m_teamData.roomId,
        chairId = chairId,
        choose = choose
    }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

--头像跳一遍
function ZeusVsHadesPlayerLisitView:allPlayerItemJump(func)
    local jumpItem = {}
    for i,item in ipairs(self.m_playerItems) do
        if item:isVisible() then
            table.insert(jumpItem,item)
        end
    end
    local n = #jumpItem
    for i = 1, n do
        local j = math.random(i, n)
        if j > i then
            jumpItem[i], jumpItem[j] = jumpItem[j], jumpItem[i]
        end
    end

    local delayNode = cc.Node:create()
    self:addChild(delayNode)
    self.m_maskLayer:setVisible(true)
    self.m_maskLayer:playAction("start")
    for i,item in ipairs(jumpItem) do
        performWithDelay(delayNode,function ()
            if i == #jumpItem then
                item:runCsbAction("actionframe",false,function ()
                    if func then
                        func()
                    end
                end)
            else
                item:runCsbAction("actionframe")
            end
        end,0.1 * i)
    end
end
return ZeusVsHadesPlayerLisitView