

local MissionMergeNode = class("MissionMergeNode", util_require("base.BaseView"))
-- 节点特殊ui 配置相关 --

MissionMergeNode.NODE_DISINFO =  -- 具体ui间距设置
{
    -- key = node 个数
    -- space 间距
    -- scale 代表缩放系数
    -- bgsize 代表不同节点个数的时候背景大小
    [2] = {space = 88 , scale = 0.67, bgsize = {width = 210, height = 133}},
    [3] = {space = 118 , scale = 0.67, bgsize = {width = 370, height = 133}},
}

function MissionMergeNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/MissionMergeNode.csb")

    self.node_bg      = self:findChild("node_bg")

    self.data = data
    self:initView()

end

function MissionMergeNode:initView( )
    --根据传入的节点 计算位置进行排序
    self:initNodePos()

    --添加节点
    self:addMergeNode()

    --添加遮罩
    self:addMask()
end

function MissionMergeNode:initNodePos( )
    -- 初始化下面节点的位置
    self.m_mergeNodePos = {}

    -- 计算出分隔条的位置
    self.m_mergeNodeFramePos = {}

    local centerNode = self:findChild("Node_centerPos")
    local centerPos = cc.p(centerNode:getPosition())

    -- 传入活动个数 每个node 的大小 中心点坐标
    -- 得出一个坐标值的表
    local lobbyNum = table.nums(self.data)

    local space = 120
    -- 计算背景大小
    local bgSize = {width = 144, height = 133}

    local disInfo = self.NODE_DISINFO[ table.nums(self.data)]
    if disInfo then
        space = disInfo.space
        bgSize = disInfo.bgsize
    end
    self.m_mergeNodePos = util_layoutCenterPosX(lobbyNum,space,centerPos)

    for i=1, table.nums(self.m_mergeNodePos)  do
        if table.nums(self.m_mergeNodePos) == 1 or table.nums(self.m_mergeNodePos) == i then
            break
        end
        local pos1 = self.m_mergeNodePos[i]
        local pos2 = self.m_mergeNodePos[i + 1]
        local newPosX = (pos2.x - pos1.x )/2 + pos1.x
        table.insert(self.m_mergeNodeFramePos, i , cc.p(newPosX,pos2.y))
    end

    self.node_bg:setContentSize(bgSize)
end

function MissionMergeNode:addMergeNode( )
    -- 这块应该遍历的是 计算出来的节点Node 摆放位置table
    local disInfo = self.NODE_DISINFO[ table.nums(self.data)]
    local scale = 1.0
    if disInfo then
        scale = disInfo.scale
    end
    for i=1, table.nums(self.data)  do
        local info = self.data[i]
        local lobbyNode = nil
        print("------- 节点名称 ---- name "..info.lobbyNodeName)
        lobbyNode = self:createLobbyNode(info.luaFileName)
        if lobbyNode then
            lobbyNode:setPosition(self.m_mergeNodePos[i])
            self:findChild("baseNode"):addChild( lobbyNode,2)
            lobbyNode:setScale(scale)
        end
    end

    for i=1, table.nums(self.m_mergeNodeFramePos)  do
        local pos = self.m_mergeNodeFramePos[i]
        local frame = cc.Sprite:create("Activity_LobbyIconRes/other/lobboy_mission_merge_frame.png")
        frame:setPosition(pos)
        self:findChild("baseNode"):addChild( frame)
    end
end

function MissionMergeNode:createLobbyNode( luaFileName)
    if luaFileName ~= nil then
        local entryNode = util_createFindView("views/Activity_LobbyIcon/" .. luaFileName)
        if not entryNode then
            entryNode = util_createFindView("Activity/"..luaFileName)
        end
        return entryNode
    end
    return nil
end

function MissionMergeNode:addMask()
    local mask = util_newMaskLayer()
    mask:setOpacity(0)
    local isTouch = false
    mask:onTouch(
        function(event)
            if isTouch then
                return
            end
            if event.name == "began" then
                -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MISSION_MERGE_NODE_CLICK)
                isTouch = true
            end

            return true
        end,
        false,
        false
    )
    self:findChild("baseNode"):addChild(mask,1)
end

function MissionMergeNode:onEnter(  )
end

function MissionMergeNode:onExit()
end


return MissionMergeNode