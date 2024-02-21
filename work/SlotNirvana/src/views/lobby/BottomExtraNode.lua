--[[
    下UI扩展
]]
local BottomExtraMgr = require("manager.System.BottomExtraMgr")
local BottomExtraNode = class("BottomExtraNode", util_require("base.BaseView"))

function BottomExtraNode:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    local deluxeName = ""
    local bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
    if bOpenDeluxe then
        deluxeName = "_1"
    end
    self:createCsbNode("GameNode/BottomNode_extra" .. deluxeName .. ".csb", isAutoScale)
    self:initNode()
    self:addMaskLayer()

    self.m_nodeList = {}
    self:initLobbyBottomNode()

    self:updateUiByDeluxe(bOpenDeluxe)
end

--加载节点
function BottomExtraNode:initNode()
    local plate = self:findChild("bg")
    self.m_plateSize = plate:getContentSize()
end

--加遮罩
function BottomExtraNode:addMaskLayer()
    local maskLayer = util_newMaskLayer(false)
    maskLayer:setZOrder(-10)
    self:addChild(maskLayer)
    self:setPosition(display.cx, display.cy)
    maskLayer:onTouch(
        function()
        end,
        false,
        true
    )
end

--加载按钮
function BottomExtraNode:initLobbyBottomNode()
    self:clearNodes()
    -- self.m_excludeName = {}
    -- self.m_lobbyBottomNodeInfo = {} -- 节点信息 组装数据 data
    --[[
        node -- lobbynode
        info -- 配置表信息
        commingsoon :  true false
    ]]
    -- 初始化节点信息
    -- self:initLobbyBottomNodeInfo()
    -- 根据节点的顺序排序一下
    -- table.sort(
    --     self.m_lobbyBottomNodeInfo,
    --     function(a, b)
    --         return tonumber(a.info.id) < tonumber(b.info.id)
    --     end
    -- )
    BottomExtraMgr:getInstance():initInfos()
    -- 添加节点到相应位置上
    self:addLobbyBottomNode()
end

function BottomExtraNode:updateUiByDeluxe(bOpenDeluxe)
    -- 节点文字
    -- for i = 1, #self.m_lobbyBottomNodeInfo do
    --     local nodeInfo = self.m_lobbyBottomNodeInfo[i]
    --     if nodeInfo and nodeInfo.node then
    --         nodeInfo.node:updateUiByDeluxe(bOpenDeluxe)
    --     end
    -- end
    for _k, _node in pairs(self.m_nodeList or {}) do
        -- local _node = self.m_nodeList[i]
        if _node then
            _node:updateUiByDeluxe(bOpenDeluxe)
        end
    end
end

function BottomExtraNode:clearNodes()
    for _k, _node in pairs(self.m_nodeList or {}) do
        -- local _node = self.m_nodeList[i]
        if not tolua.isnull(_node) then
            _node:removeFromParent()
        end
    end
    self.m_nodeList = {}
end

--添加按钮
function BottomExtraNode:addLobbyBottomNode()
    -- 这块应该遍历的是 计算出来的节点Node 摆放位置table
    -- for i = 1, table.nums(self.m_lobbyBottomNodeInfo) do
    -- local data = self.m_lobbyBottomNodeInfo[i]
    local _nodeInfos = BottomExtraMgr:getInstance():getInfos() or {}
    for i = 1, table.nums(_nodeInfos) do
        local data = _nodeInfos[i]
        local info = data.info
        local commingsoon = data.commingsoon
        local lobbyNode = nil
        print("------- 节点名称 ---- name " .. info.lobbyNodeName)

        if info.activity then -- 如果是活动节点的话。 需要到 ActivityManager 去处理 （模块化）
            lobbyNode = gLobalActivityManager:InitLobbyNode(info.activityName, commingsoon, true)
        else
            lobbyNode = self:createLobbyNode(info.luaFileName)
        end
        if lobbyNode then
            lobbyNode:setName(info.lobbyNodeName)
            lobbyNode:setLogFuncClickInfo(
                {
                    siteType = "Fold",
                    clickName = info.clickName,
                    site = i
                }
            )

            local addNode = self:findChild("addButton_" .. i)
            if addNode then
                addNode:setVisible(true)
                addNode:addChild(lobbyNode)
                -- 封装成新数据
                -- local newData = {
                --     node = lobbyNode,
                --     info = info,
                --     commingsoon = commingsoon
                -- }
                -- self.m_lobbyBottomNodeInfo[i] = newData
                self.m_nodeList[info.lobbyNodeName] = lobbyNode
            end
        end
    end
end
--创建按钮
function BottomExtraNode:createLobbyNode(_luaFileName)
    if _luaFileName ~= nil then
        local entryNode = util_createFindView("views/Activity_LobbyIcon/" .. _luaFileName)
        if not entryNode then
            entryNode = util_createFindView("Activity/" .. _luaFileName)
        end
        return entryNode
    end
    return nil
end
-- 刷新节点信息
function BottomExtraNode:updateLobbyNode()
    -- for i = table.nums(self.m_lobbyBottomNodeInfo), 1, -1 do
    --     local data = self.m_lobbyBottomNodeInfo[i]
    --     data.node:removeFromParent()
    --     table.remove(self.m_lobbyBottomNodeInfo, i)
    -- end
    self:initLobbyBottomNode()
end
--活动结束
function BottomExtraNode:closeActivityNode(param)
    -- 修改这块儿的代码 。活动结束了找到对应的 bottom node 节点进行状态更换
    -- local activityKey = ActivityManager.getActivityRelativeBaseKey(param)
    local activityKey = param
    local refresh = false
    -- for i = table.nums(self.m_lobbyBottomNodeInfo), 1, -1 do
    -- local data = self.m_lobbyBottomNodeInfo[i]
    local _nodeInfos = BottomExtraMgr:getInstance():getInfos() or {}
    for i = 1, table.nums(_nodeInfos) do
        local data = _nodeInfos[i]
        local info = data.info
        local _node = self.m_nodeList[info.lobbyNodeName]
        -- if data.node then
        if _node then
            print("------- BottomNode:closeActivityNode activityKey = " .. activityKey)
            if info.activityName == activityKey then
                -- 直接更新 近期活动展示，如果近期没有活动需要开则活动节点就不显示了
                if (info.lobbyNodeName == "Activity" or info.lobbyNodeName == "Quest") and not data.commingsoon then
                    refresh = true
                    break
                else
                    if info.commingSoon then
                        if _node.showCommingSoon then
                            _node:showCommingSoon()
                        end
                    else
                        refresh = true
                        break
                    end
                end
            end
        end
    end
    if refresh then
        -- performWithDelay(
        --     self,
        --     function()
        --         self:updateLobbyNode()
        --     end,
        --     1.1
        -- )
        self:updateLobbyNode()
    end
end
function BottomExtraNode:clickFunc(_sander)
    if self.m_touch then
        return
    end

    self.m_touch = true

    local name = _sander:getName()
    local tag = _sander:getTag()
    if name == "btn_close" then
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_UI_EXTRA_DOWN)
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:runCsbAction(
            "over",
            false,
            function()
                self:closeUI()
            end,
            60
        )
    end
end

function BottomExtraNode:closeUI()
    if self.isClosed then
        return
    end
    self.isClosed = true

    self:clearNodes()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_UI_EXTRA_UP)
    self:removeFromParent()
end
--监听
function BottomExtraNode:registerListener()
    --按钮打开界面时，关闭扩展栏
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if not tolua.isnull(self) then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_LOBBY_UI_OPEN_VIEW
    )
    ---- quest 界面隐藏
    --gLobalNoticManager:addObserver(
    --    self,
    --    function(self, params)
    --        self:updateLobbyNode()
    --    end,
    --    ViewEventType.NOTIFY_QUEST_VIEW_HIDE
    --)
    --活动结束
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:closeActivityNode(params)
        end,
        ViewEventType.NOTIFY_ACTIVITY_FIND_CLOSE
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.VipBoost then
                if self.m_vipBoostNode then
                    self.m_vipBoostNode:removeFromParent()
                    self.m_vipBoostNode = nil
                end
            else
                self:closeActivityNode(params.name)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function BottomExtraNode:onEnter()
    self:registerListener()
    self:runCsbAction(
        "start",
        false,
        function()
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_UI_EXTRA_UP)
        end,
        60
    )
end

return BottomExtraNode
