---
--xcyy
--2018年5月23日
--LottoPartyRoomListView.lua
local SendDataManager = require "network.SendDataManager"
local LottoPartyRoomListView = class("LottoPartyRoomListView", util_require("base.BaseView"))

function LottoPartyRoomListView:initUI()
    self:createCsbNode("LottoParty_Room.csb")
    self.m_btn = self:findChild("Btn_ChangeRoom")
    self.m_rankNum = 0
end

function LottoPartyRoomListView:initPlayerData()
    local palyerDatas = LottoPartyManager:getRoomRanks()
    self.m_roomPlayers = {}
    for i = 1, #palyerDatas do
        local data = palyerDatas[i]
        local playerCsb = util_createView("CodeLottoPartySpotSrc.LottoPartyRoomPlayer", data)
        local index = i - 1
        if self:isMySelf(data.udid) then
            self.m_rankNum = i
        end
        local posNode = self:findChild("Node_Player_" .. index)
        local pos = cc.p(posNode:getPosition())
        self:addChild(playerCsb)
        playerCsb:setPosition(pos)
        self.m_roomPlayers[#self.m_roomPlayers + 1] = playerCsb
    end
end

function LottoPartyRoomListView:getBigWinTypeByID(_udid)
    local eventData = LottoPartyManager:getRoomEvent()
    for i = 1, #eventData do
        local data = eventData[i]
        if data.udid == _udid then
            return data.eventType
        end
    end
    return nil
end

function LottoPartyRoomListView:resetRoomPlayers()
    for i = 1, #self.m_roomPlayers do
        local playerCsb = self.m_roomPlayers[i]
        playerCsb:removeFromParent()
    end
    local palyerDatas = LottoPartyManager:getRoomRanks()
    self.m_roomPlayers = {}
    for i = 1, #palyerDatas do
        local data = palyerDatas[i]
        local playerCsb = util_createView("CodeLottoPartySpotSrc.LottoPartyRoomPlayer", data)
        if self:isMySelf(data.udid) then
            self.m_rankNum = i
        end
        local index = i - 1
        local posNode = self:findChild("Node_Player_" .. index)
        local pos = cc.p(posNode:getPosition())
        self:addChild(playerCsb)
        playerCsb:setPosition(pos)
        local winType = self:getBigWinTypeByID(data.udid)
        playerCsb:playBigWinAction(winType)
        self.m_roomPlayers[#self.m_roomPlayers + 1] = playerCsb
    end
end

function LottoPartyRoomListView:isMySelf(_udid)
    if globalData.userRunData.userUdid == _udid then
        return true
    end
    return false
end

function LottoPartyRoomListView:updataRoomPlayers()
    for i = 1, #self.m_roomPlayers do
        local playerCsb = self.m_roomPlayers[i]
        playerCsb:removeFromParent()
    end
    local WinResult = LottoPartyManager:getSpotResult()

    local palyerDatas = {}
    if WinResult then
        palyerDatas = WinResult.data.rank
    else
        palyerDatas = LottoPartyManager:getRoomRanks()
    end

    self.m_roomPlayers = {}
    for i = 1, #palyerDatas do
        local data = palyerDatas[i]

        local playerCsb = util_createView("CodeLottoPartySpotSrc.LottoPartyRoomPlayer", data)
        local index = i - 1
        local posNode = self:findChild("Node_Player_" .. index)
        local pos = cc.p(posNode:getPosition())
        self:addChild(playerCsb)
        playerCsb:setPosition(pos)
        local winType = self:getBigWinTypeByID(data.udid)
        playerCsb:playBigWinAction(winType)
        if self:isMySelf(data.udid) then
            if i < self.m_rankNum then
                playerCsb:playRankUp()
            end
            self.m_rankNum = i
        end
        self.m_roomPlayers[#self.m_roomPlayers + 1] = playerCsb
    end
end

function LottoPartyRoomListView:onEnter()
end

function LottoPartyRoomListView:onExit()
    --发送退出房间消息
    self:sendLogOutRoom( )
end

function LottoPartyRoomListView:setBtnTouch(_enabled)
    self.m_btn:setTouchEnabled(_enabled)
    self.m_btn:setBright(_enabled)
end

function LottoPartyRoomListView:clickFunc(sender)
    local name = sender:getName()
    if name == "Btn_ChangeRoom" then
        self.m_btn:setTouchEnabled(false)
        self:sendChangeRoom()
    end
end

function LottoPartyRoomListView:sendChangeRoom()
    local headManager = G_GetMgr(G_REF.Avatar)
    headManager:removeDownloadInfo()
    
    LottoPartyHeadManager:removeAllHeadInfo()
    local gameName = "LottoParty"
    gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReset(
        gameName,
        function()
            if not tolua.isnull(self) then
                self.m_btn:setTouchEnabled(true)
                self:changeSuccess()
            end
        end,
        function(errorCode, errorData)
            print("-----LottoParty errorCode -----", errorCode)
            self:changeFailed()
        end
    )
end

function LottoPartyRoomListView:changeSuccess()
    self:resetRoomPlayers()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOTTO_PARTY_UPDATE_OPEN_SPOT)
end

function LottoPartyRoomListView:changeFailed()
end


--[[
    发送退出房间
]]
function LottoPartyRoomListView:sendLogOutRoom( )
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():sendActionData_ExitRoom()
end

return LottoPartyRoomListView
