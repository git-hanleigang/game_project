--
--大厅关卡节点
--

local LevelActivity = class("LevelActivity", util_require("base.BaseView"))
local OFFSETX_MUL_SPAN = 48 --多个轮播图间隔
LevelActivity.m_contentLen = nil
function LevelActivity:initUI(info)
    self:createCsbNode("newIcons/Level_activityToos.csb")
    self.m_contentLen = 0
    self.m_posX = 0
    --判空
    if not info.activity or not info.activity.p_hallImages or #info.activity.p_hallImages == 0 then
        return
    end
    self:initData(info)
    self:initHallNode()
    self:registerListener()
end
--初始化数据
function LevelActivity:initData(info)
    self.m_luaName = info.activity:getThemeName()
    self.m_activityId = info.activity:getActivityID()
    self.m_paramData = info.activity
    self.m_hallImagePaths = info.activity.p_hallImages
    self.m_bClickPlaySound = false
end
--初始化展示图
function LevelActivity:initHallNode()
    local baseNode = cc.Node:create()
    self:addChild(baseNode)
    local lastlen = 0
    for i = 1, #self.m_hallImagePaths do
        local hallNode, touch, size = self:createHallNode(baseNode, i, self.m_hallImagePaths[i])
        if hallNode then
            if self.m_contentLen == 0 then
                hallNode:setPositionX(0)
                touch:setPositionX(0)
                self.m_contentLen = size.width
                lastlen = size.width * 0.5
                self.m_posX = self.m_contentLen * 0.5 - 8
            else
                hallNode:setPositionX(self.m_contentLen - lastlen + OFFSETX_MUL_SPAN + size.width * 0.5)
                touch:setPositionX(self.m_contentLen - lastlen + OFFSETX_MUL_SPAN + size.width * 0.5)
                self.m_contentLen = self.m_contentLen + OFFSETX_MUL_SPAN + size.width
                lastlen = size.width * 0.5
            end
            -- 点击是否播放 点击音效
            if hallNode["isClickPlaySound"] then
                self.m_bClickPlaySound = hallNode:isClickPlaySound()
            end
        end
    end
    -- baseNode:setPositionX(lastlen - self.m_contentLen * 0.5)
    -- self.m_posX = self.m_contentLen * 0.5 - 8
end
--获取展示图数据
function LevelActivity:getHallNodeData(index, path)
    local data = {index = index, path = path, key = self.m_activityId, param = self.m_paramData}
    return data
end
--创建展示图节点
function LevelActivity:createHallNode(baseNode, index, path)
    if not path or path == "" then
        return nil, nil, nil
    end
    -- 展示图
    local hallName = ""
    local _mgr = G_GetMgr(self.m_paramData:getRefName())
    if _mgr then
        hallName = _mgr:getHallModule()
    else
        hallName = self.m_paramData:getHallModule()
    end
    if hallName == "" then
        return nil, nil, nil
    end

    if util_IsFileExist(path) then
        local hallNode = nil
        local data = self:getHallNodeData(index, path)
        local hallModule = util_pcallRequire(hallName)
        if hallModule then
            hallNode = util_createView(hallModule, data)
            local content = hallNode:findChild("content")
            local size = content:getContentSize()
            local touch = self:makeTouch(content, self.m_activityId .. index)
            baseNode:addChild(touch, -1)
            self:addClick(touch)
            -- local button_1 = hallNode:findChild("Button_1")
            -- if button_1 then
            --     self:addClick(button_1)
            -- end
            baseNode:addChild(hallNode, -1)
            return hallNode, touch, size
        end
    else
        if isMac() then
            printError("hall path:" .. tostring(path) .. " is not exist!!!")
        end
    end
end

--根据content大小创建按钮监听
function LevelActivity:makeTouch(content, name)
    local touch = ccui.Layout:create()
    touch:setName(name)
    touch:setTag(10)
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(false)
    touch:setAnchorPoint(0.5000, 0.5000)
    touch:setContentSize(content:getContentSize())
    touch:setClippingEnabled(false)
    touch:setBackGroundColorOpacity(0)
    return touch
end

function LevelActivity:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_bClickPlaySound then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end

    local levelNode = self:getParent()
    local index = 1
    if levelNode and levelNode.m_index then
        index = levelNode.m_index
    end
    gLobalSendDataManager:getLogIap():setEntryOrder(index)
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "lobbyDisplay")
    if self.m_luaName and self.m_luaName then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(self.m_luaName .. "_DisplayClick", false)
        end
    end
    if self:isShowShop() then
        local params = {
            shopPageIndex = 1,
            dotKeyType = name,
            dotUrlType = DotUrlType.UrlName,
            dotIsPrep = false
        }
        G_GetMgr(G_REF.Shop):showMainLayer(params)
        return
    end
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():setClickUrl(DotEntrySite.LobbyDisplay, DotEntryType.Lobby, name)
    end
    -- p_reference
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLICK_BROADCAST_HALL, {id = self.m_activityId, d = self.m_paramData, clickFlag = true})
end

function LevelActivity:isShowShop()
    if self.m_luaName == "Activity_DoubleCard" then
        return true
    end
    if self.m_luaName == "Activity_CardStar" then
        return true
    end
    return false
end

function LevelActivity:getContentLen()
    return self.m_contentLen / 2
end

function LevelActivity:getOffsetPosX()
    return self.m_posX
end

function LevelActivity:updateUI()
end

function LevelActivity:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.luaName == self.m_luaName then
                self:clickFunc(params.button)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_SHOW_ACTIVITY_MAINLAYER
    )
end

return LevelActivity
