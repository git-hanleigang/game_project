--
local NetworkLog = require "network.NetworkLog"
local LogPopup = class("LogPopup", NetworkLog)
GD.DotUrlType = {
    UrlName = 1,
    ViewName = 2
}

GD.DotEntryType = {
    Lobby = "Lobby",
    Game = "Game",
    QuestLobby = "QuestLobby"
}

GD.DotEntrySite = {
    UpView = "UpView",
    --  上UI
    DownView = "DownView", -- 下UI
    LobbyCarousel = "LobbyCarousel", --轮播图
    LobbyDisplay = "LobbyDisplay",
    -- 展示位
    LeftView = "LeftView",
    --左UI
    RightView = "RightView",
    --右UI
    LoginLobbyPush = "LoginLobbyPush",
    --登陆推送
    CloseStorePush = "CloseStorePush",
    --关闭商城推送
    LeaveGamePush = "LeaveGamePush",
    --退出关卡推送
    OutQuestLobbyPush = "OutQuestLobbyPush",
    --退出quest活动大厅
    EnterGamePush = "EnterGamePush",
    --进入关卡推送
    LevelUpPush = "LevelUpPush",
    --升级推送
    GamePushPig = "GamePushPig",
    --小猪推送
    SpinPush = "SpinPush",
    --Spin推送
    BigWinPush = "BigWinPush",
    --大赢推送
    FeaturePush = "FeaturePush",
    --feature推送
    NocoinPush = "NocoinPush",
    --nocoin推送
    NocoinNoPayPush = "NocoinNoPayPush"
    --未支付nocoin推送
}

function LogPopup:ctor()
    NetworkLog.ctor(self)
    self.m_urlList = {}
end
--[[
    @desc:
    author:{author}
    time:2020-04-08 20:26:50
    --@node:  打开的界面
	--@keyType: 点击按钮名字 或者是推送Push
	--@urlType: 按钮 或者是 界面
	--@isPrep: 是否是功能的入口起点
	--@entrySite: 打开界面的位置
	--@entryType: 打开界面的类型
    @return:
]]
function LogPopup:addNodeDot(node, keyType, urlType, isPrep, entrySite, entryType)
    if not node or not keyType or not urlType then
        return
    end
    if entrySite and entryType then
        self:setEntrySiteAndType(entrySite, entryType)
    end
    if node then -- 加需要统一打点的标记
        node.m_dotLog = true
    end
    self:pushUrlKey(keyType, urlType, isPrep)
end

function LogPopup:exchangePopType(type)
    if type == PushViewPosType.LoginToLobby then
        return DotEntrySite.LoginLobbyPush
    elseif type == PushViewPosType.LevelToLobby then
        return DotEntrySite.LeaveGamePush
    elseif type == PushViewPosType.CloseStore then
        return DotEntrySite.CloseStorePush
    elseif type == PushViewPosType.NoCoinsToSpin then
        return DotEntrySite.NocoinPush
    end
    return nil
end
--[[
   setEntrySiteAndType(DotEntrySite.UpView,DotEntryType.Lobby)
]]
--1 日志的起点  传入位置和类型  DotEntrySite  DotEntryType
function LogPopup:setEntrySiteAndType(site, type)
    self.m_entrySite = site
    self.m_entryType = type
end
function LogPopup:setClickUrl(site, type, btnName)
    self.m_entrySite = site
    self.m_entryType = type
    self.m_btnName = btnName
end

function LogPopup:getClickUrl()
    return self.m_entrySite, self.m_entryType, self.m_btnName
end

--[[
    2. 具体的点击按钮  界面名字
    pushUrlKey("closeBtn",DotUrlType.UrlName)
    pushUrlKey("VipView",DotUrlType.ViewName)
]]
function LogPopup:pushUrlKey(key, type, isSource)
    if not self.m_urlList then
        self.m_urlList = {}
    end
    if isSource == nil then
        isSource = false
    end
    local checkAdd = function()
        local hasKey = false
        for i = 1, #self.m_urlList do
            if self.m_urlList[i].key == key then
                hasKey = true
                break
            end
        end
        if hasKey then -- 之前有存的记录  删除所有记录
            self:clearUrlList()
        end
        local temp = {key = key, urlType = type}
        self.m_urlList[#self.m_urlList + 1] = temp
        if type == DotUrlType.ViewName then --打开界面时需要发送日志
            self:sendDotLog()
        end
    end
    -- 大厅打开商店（发送一次）  商店内打开vip（发送第二次）   vip内打开vip详情（此次就是不是触发点  也没有前置ui）
    -- 大厅打开vip（发送第一次）   vip内打开vip详情   （发送第二次）
    if isSource == true then
        checkAdd()
    else
        if #self.m_urlList > 0 then
            checkAdd()
        end
    end
end
--非大厅点击的话 如果没有前置的ui 不作处理
function LogPopup:checkHasPrep()
    if self.m_urlList and #self.m_urlList > 0 then
        return true
    else
        return false
    end
end

function LogPopup:clearUrlList()
    self.m_urlList = {}
    self.m_entrySite = nil
    self.m_entryType = nil
    self.m_btnName = nil
end

function LogPopup:removeUrlKey(key)
    local index, hasKey
    for i = 1, #self.m_urlList do
        if self.m_urlList[i].key == key then
            hasKey = true
            index = i
            break
        end
    end
    if hasKey then
        if index > 1 then
            for i = #self.m_urlList, index - 1, -1 do
                table.remove(self.m_urlList, i)
            end
        end
    end
    if #self.m_urlList < 2 then
        self:clearUrlList()
    end
end

--发送日志
function LogPopup:sendDotLog()
    do
        return
    end
    if #self.m_urlList < 2 then
        return
    end
    gL_logData:syncUserData()
    gL_logData:syncEventData("Popup")
    local messageData = {
        type = "System",
        popupName = self.m_urlList[2].key,
        --当前弹窗名字 B
        entryType = self.m_entryType,
        --位置类型
        entrySite = self.m_entrySite,
        --位置名称
        entryName = self.m_urlList[1].key
        --需要排查出所有弹窗的位置
    }
    if self.m_urlList[1].key == "Push" then
        --打开方式
        messageData.entryOpen = "PushOpen"
    else
        --打开方式
        messageData.entryOpen = "TapOpen"
    end
    -- print("sendPopubLog1----------"..messageData.entryName)
    -- print("sendPopubLog2----------"..messageData.popupName)

    if #self.m_urlList == 4 then
        messageData.actionType = "Click"
        messageData.targetName = self.m_urlList[4].key
        -- print("sendPopubLog3----------"..messageData.targetName)

        self:clearUrlList()
    elseif #self.m_urlList == 2 then
        messageData.actionType = "Popup"
    end
    gL_logData.p_data = messageData
    self:sendLogData()
end

return LogPopup
