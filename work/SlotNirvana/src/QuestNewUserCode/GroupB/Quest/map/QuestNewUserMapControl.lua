--
--大厅关卡循环显示与控制 quest新手期
-- 添加前后景
--
local QuestNewUserMapControl = class("QuestNewUserMapControl")
QuestNewUserMapControl.m_content = nil
QuestNewUserMapControl.m_scroll = nil
QuestNewUserMapControl.m_displayNodeList = nil
QuestNewUserMapControl.m_removeLen = 350
QuestNewUserMapControl.m_addLen = 450
QuestNewUserMapControl.m_nodePool = nil

QuestNewUserMapControl.m_roadWidth = 1047
QuestNewUserMapControl.m_frontWidth = 2000

function QuestNewUserMapControl:ctor()
    self.m_nodeList = {}
    self.m_displayNodeList = {}
    self.m_nodePool = {}
end

--释放资源
function QuestNewUserMapControl:purge()
end

function QuestNewUserMapControl:initData_(node, nodeInfoList)
    self.m_content = node
    -- 初始化前后景 节点 --
    self:initFarAndNearLayer()

    -- 当前路的长度
    self.m_contentLen = QUEST_RES_PATH.BG_ROAD_LEN
    -- local quest_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    -- if quest_data then
    --     -- 根据章节数 重新计算地图长度
    --     local counts = quest_data:getPhaseCount()
    --     if counts > 0 then
    --         self.m_contentLen = counts / 6 * QUEST_RES_PATH.BG_ROAD_LEN + QUEST_CONFIGS.box_offset
    --     end
    -- end

    -- 初始化远景显示 --
    local cell_posx = 0
    -- 初始屏幕上 前后景长度时1:1 后面滑动过程中移动比例按设计比例滑动
    local bg_len = (self.m_contentLen - display.width) * QUEST_RES_PATH.BG_FAR_RATIO + display.width
    local count = #nodeInfoList
    local mapCell = util_getRequireFile(QUEST_CODE_PATH.QuestMapCell)
    for i = 1, count do
        local node = mapCell:create(nodeInfoList[i])
        self.m_farBg:addChild(node)
        node:setTag(i)
        node:setPosition(cell_posx, 0)
        self.m_nodePool[i] = node

        cell_posx = cell_posx + nodeInfoList[i][2]
        if cell_posx >= bg_len then
            break
        end
    end

    printInfo("当前加载背景数量 " .. #self.m_nodePool)
    -- 初始化路面显示 --
    self.m_InitRoad = false
    -- 初始化前景显示 --
    self.m_InitFront = false
end

-- 初始化地图远景/近景层 --
function QuestNewUserMapControl:initFarAndNearLayer()
    local pParent = self.m_content:getParent()
    assert(pParent, "HolyShit , map controller root is nil")

    -- 远景跟节点 --
    self.m_farBg = cc.Node:create()
    pParent:addChild(self.m_farBg, 0)
    -- 近景根节点 --
    self.m_nearBg = cc.Node:create()
    pParent:addChild(self.m_nearBg, 2)
end

-- 移动远景/近景图 --
function QuestNewUserMapControl:moveFarAndNearLayer()
    local vPos = cc.p(self.m_content:getPosition())

    local farBgPos = vPos.x * QUEST_RES_PATH.BG_FAR_RATIO
    if self.m_farBg then
        self.m_farBg:setPosition(farBgPos, vPos.y)
    end

    local nearBgPos = vPos.x * QUEST_RES_PATH.BG_NEAR_RATIO
    if self.m_nearBg then
        self.m_nearBg:setPosition(nearBgPos, vPos.y)
    end
end

-- 初始化路面显示 --
function QuestNewUserMapControl:roadRender()
    if self.m_InitRoad == true then
        return
    end
    local roadCount = math.ceil(self.m_contentLen / self.m_roadWidth)

    local roadPos = self.m_content:convertToNodeSpace(cc.p(0, 0))
    for i = 1, roadCount do
        local roadTex = util_createSprite(QUEST_RES_PATH.QuestMapRoadPath)
        self.m_content:addChild(roadTex)
        roadTex:setAnchorPoint(cc.p(0.0, 0.0))
        roadTex:setPosition(cc.p((i - 1) * self.m_roadWidth, roadPos.y))
    end

    if not self.decorateNode and QUEST_RES_PATH.QuestMapDecorateNode then
        local csbNode, csbAct = util_csbCreate(QUEST_RES_PATH.QuestMapDecorateNode)
        if csbNode then
            self.m_content:addChild(csbNode)
            csbNode:setPosition(cc.p(0, -display.height / 2))
            self.decorateNode = csbNode
        end
    end

    self.m_InitRoad = true
end

-- 初始化近景显示 --
function QuestNewUserMapControl:frontRender()
    if self.m_InitFront == true then
        return
    end

    local frontWidth = self.m_contentLen * GD.QUEST_RES_PATH.BG_NEAR_RATIO
    local frontCount = math.ceil(frontWidth / self.m_frontWidth)

    local frontPos = self.m_content:convertToNodeSpace(cc.p(0, 0))
    for i = 1, frontCount do
        local frontTex = util_createSprite(QUEST_RES_PATH.QuestMapFrontPath)
        self.m_nearBg:addChild(frontTex)
        frontTex:setAnchorPoint(cc.p(0.0, 0.0))
        frontTex:setPosition(cc.p((i - 1) * self.m_frontWidth, frontPos.y))
    end
    self.m_InitFront = true
end

-- 路面及近景显示
function QuestNewUserMapControl:updateRoadAndFrontRender(x)
    -- 路面计算 --
    -- self:roadRender()
    --
    -- self:frontRender()
end

function QuestNewUserMapControl:getContentLen()
    return self.m_contentLen
end

--初始化节点信息
function QuestNewUserMapControl:initDisplayNode(x)
    -- 校正远景层位置 --
    local farBgPos = x * QUEST_RES_PATH.BG_FAR_RATIO

    self.m_displayNodeList = {}
    local count = #self.m_nodePool
    for i = 1, count do
        local node = self.m_nodePool[i]
        if node and node.isDisPlayContent then
            if node:isDisPlayContent(farBgPos, self.m_addLen) then
                self.m_displayNodeList[#self.m_displayNodeList + 1] = node
                node:showContent(false)
            end
        end
    end
end

--刷新地图
function QuestNewUserMapControl:updateMap(x)
    self:moveFarAndNearLayer(x)
    -- 路面及近景显示 --
    self:updateRoadAndFrontRender(x)

    local count = #self.m_displayNodeList
    if count <= 0 then
        return
    end
    -- 校正远景层位置 --
    local farBgPos = x * QUEST_RES_PATH.BG_FAR_RATIO
    --检测需要移除的元素
    for i = count, 1, -1 do
        local node = self.m_displayNodeList[i]
        if node and node.isDisPlayContent then
            if not node:isDisPlayContent(farBgPos, self.m_removeLen) then
                table.remove(self.m_displayNodeList, i)
                node:hideContent()
            end
        end
    end
    self:checkAddDisplayNode(farBgPos)
end

--尝试显示可见区域内的贴图
function QuestNewUserMapControl:checkAddDisplayNode(x)
    self:checkAddLeftNode(x)
    self:checkAddRightNode(x)
end

--向左检测加贴图
function QuestNewUserMapControl:checkAddLeftNode(x)
    local node = self.m_displayNodeList[1]
    if not node then
        return
    end
    local index = node:getTag()
    if index <= 1 then
        return
    end
    index = index - 1
    local node = self.m_nodePool[index]
    if node and node.isDisPlayContent then
        if node:isDisPlayContent(x, self.m_addLen) then
            table.insert(self.m_displayNodeList, 1, node)
            node:showContent(true)
            self:checkAddLeftNode(x)
        end
    end
end

--向右检测加贴图
function QuestNewUserMapControl:checkAddRightNode(x)
    local count = #self.m_displayNodeList
    if count <= 0 then
        return
    end
    local node = self.m_displayNodeList[count]
    if not node then
        return
    end
    local index = node:getTag()
    if index <= 1 then
        return
    end
    index = index + 1
    local node = self.m_nodePool[index]
    if node and node.isDisPlayContent then
        if node:isDisPlayContent(x, self.m_addLen) then
            self.m_displayNodeList[#self.m_displayNodeList + 1] = node
            node:showContent(true)
            self:checkAddRightNode(x)
        end
    end
end

return QuestNewUserMapControl
