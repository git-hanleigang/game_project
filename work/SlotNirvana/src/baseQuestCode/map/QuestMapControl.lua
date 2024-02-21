--
--大厅关卡循环显示与控制
--
local QuestMapControl = class("QuestMapControl")
QuestMapControl.m_content = nil
QuestMapControl.m_scroll = nil
QuestMapControl.m_displayNodeList = nil
QuestMapControl.m_removeLen = 350
QuestMapControl.m_addLen = 450
QuestMapControl.m_nodePool = nil
function QuestMapControl:ctor()
    self.m_nodeList = {}
    self.m_displayNodeList = {}
    self.m_nodePool = {}
end

--释放资源
function QuestMapControl:purge()

end

function QuestMapControl:initData_(node,nodeInfoList)
    self.m_content = node
    self.m_contentLen = 0
    local count = #nodeInfoList
    local mapCell = util_getRequireFile(QUEST_CODE_PATH.QuestMapCell)
    for i=1,count do
        local node = mapCell:create(nodeInfoList[i])
        self.m_content:addChild(node)
        node:setTag(i)
        node:setPosition(self.m_contentLen,0)
        self.m_contentLen = self.m_contentLen + nodeInfoList[i][2]
        self.m_nodePool[i]=node
    end
end

function QuestMapControl:getContentLen()
    return self.m_contentLen
end

--初始化节点信息
function QuestMapControl:initDisplayNode(x)
    self.m_displayNodeList = {}
    local count = #self.m_nodePool
    for i=1,count do
        local node = self.m_nodePool[i]
        if node and node.isDisPlayContent then
            if node:isDisPlayContent(x,self.m_addLen) then
                self.m_displayNodeList[#self.m_displayNodeList+1]=node
                node:showContent(false)
            end
        end
    end
end

--刷新地图
function QuestMapControl:updateMap(x)
    local count = #self.m_displayNodeList
    if count<=0 then
        return
    end
    --检测需要移除的元素
    for i=count,1,-1 do
        local node = self.m_displayNodeList[i]
        if node and node.isDisPlayContent then
            if not node:isDisPlayContent(x,self.m_removeLen) then
                table.remove( self.m_displayNodeList,i)
                node:hideContent()
            end
        end
    end
    self:checkAddDisplayNode(x)
end

--尝试显示可见区域内的贴图
function QuestMapControl:checkAddDisplayNode(x)
    self:checkAddLeftNode(x)
    self:checkAddRightNode(x)
end

--向左检测加贴图
function QuestMapControl:checkAddLeftNode(x)
    local node = self.m_displayNodeList[1]
    if not node then
        return
    end
    local index = node:getTag()
    if index <=1 then
        return
    end
    index = index-1
    local node = self.m_nodePool[index]
    if node and node.isDisPlayContent then
        if node:isDisPlayContent(x,self.m_addLen) then
            table.insert(self.m_displayNodeList,1,node)
            node:showContent(true)
            self:checkAddLeftNode(x)
        end
    end
end

--向右检测加贴图
function QuestMapControl:checkAddRightNode(x)
    local count = #self.m_displayNodeList
    if count<=0 then
        return
    end
    local node = self.m_displayNodeList[count]
    if not node then
        return
    end
    local index = node:getTag()
    if index <=1 then
        return
    end
    index = index+1
    local node = self.m_nodePool[index]
    if node and node.isDisPlayContent then
        if node:isDisPlayContent(x,self.m_addLen) then
            self.m_displayNodeList[#self.m_displayNodeList+1]=node
            node:showContent(true)
            self:checkAddRightNode(x)
        end
    end
end

return QuestMapControl
