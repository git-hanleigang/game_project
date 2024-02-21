local PBTipsNode = class("PBTipsNode", util_require("base.BaseView"))
PBTipsNode.m_status = nil
PBTipsNode.STATUS_START = 1
PBTipsNode.STATUS_OVER = 2
PBTipsNode.STATUS_DOING = 3
function PBTipsNode:initUI(itemList,isOneLine,otherCsb)
    -- 类型 1通用 2轮盘单列
    self.m_isOneLine = isOneLine
    self.m_itemList = itemList
    self.m_status = self.STATUS_START
    if otherCsb then
        self:createCsbNode("PBRes/PBTips/PB_TipsNode.csb")
    else
        self:createCsbNode("PBRes/PBTips/PB_TipsNode_0.csb")
    end
    self:initView()
    self:updateItem()
end

function PBTipsNode:initView()
    --遮罩
    self.m_maskUI = util_newMaskLayer()
    self:addChild(self.m_maskUI,-1)
    self.m_maskUI:setScale(6)
    self.m_maskUI:setPosition(-display.width*2,-display.height*2)
    self.m_maskUI:setOpacity(170)
    self.m_maskUI:setContentSize(4000,4000)
    self.m_maskUI:onTouch(function(event)
        if event.name == "ended" then
            self:hidePB()
        end
        return true
    end, false, true)
    self.m_maskUI:setVisible(false)
    self.m_maskUI:setTouchEnabled(false)
    --缩小显示
    self.m_sp_showbg = self:findChild("sp_showbg")
    self.m_sp_shou_title = self:findChild("sp_shou_title")
    self.m_sp_line = self:findChild("sp_line")
    self.m_node_iteml = self:findChild("node_iteml")
    self.m_node_itemr = self:findChild("node_itemr")
    --展开后显示
    self.m_sp_openbg = self:findChild("sp_openbg")
    self.m_sp_open_title = self:findChild("sp_open_title")
    self.m_sp_line1 = self:findChild("sp_line1")
    self.m_node_iteml1 = self:findChild("node_iteml1")
    self.m_node_itemr1 = self:findChild("node_itemr1")
    --按钮
    self.m_btn_hide = self:findChild("btn_hide")
    self.btn_show = self:findChild("btn_show")
    self.m_menu = self:findChild("Menu")
end

--刷新道具
function PBTipsNode:updateItem()
    if not self.m_itemList then
        self:setVisible(false)
        return
    end
    if #self.m_itemList == 1 then
        self:updateOneItem()
    elseif #self.m_itemList == 2 then
        self:updateTwoItem()
    else
        if self.m_isOneLine then
            self:updateLineItem()
        else
            self:updateNormalItem()
        end
    end
end
--增加道具
function PBTipsNode:addItem(node,itemData)
    if not node then
        return
    end
    local propNode = gLobalItemManager:createDescNode(itemData)
    if propNode ~= nil then
        node:addChild(propNode)
    end
end
--只有一个道具
function PBTipsNode:updateOneItem()
    self.m_sp_showbg:setContentSize(330,86)
    local size = self.m_sp_showbg:getContentSize()
    self.m_menu:setVisible(false)
    self.m_sp_line:setVisible(false)
    self.m_node_itemr:setVisible(false)
    self.m_sp_shou_title:setPositionX(size.width*0.5)
    self.m_node_iteml:setPositionX(size.width*0.75)
    self.m_node_iteml:setScale(1.2)
    self:addItem(self.m_node_iteml,self.m_itemList[1])
end
--只有两个道具
function PBTipsNode:updateTwoItem()
    local size = self.m_sp_showbg:getContentSize()
    self.m_menu:setVisible(false)
    self.m_sp_line:setPositionX(size.width*0.5)
    self.m_node_iteml:setPositionX(size.width*0.38)
    self.m_node_itemr:setPositionX(size.width*0.86)
    self.m_node_iteml:setScale(1.2)
    self.m_node_itemr:setScale(1.2)
    self:addItem(self.m_node_iteml,self.m_itemList[1])
    self:addItem(self.m_node_itemr,self.m_itemList[2])
end
--正常多个道具 2个以上
function PBTipsNode:updateNormalItem()
    local bgWidth = 640         --背景宽度
    local bgHeight = 40         --背景额外高度
    local cellHeight = 78       --一个格子高度
    local itemHeight = 63       --道具位置高度
    local lineHeight = 100      --分割线位置高度
    local count = #self.m_itemList

    if count%2==0 then
        self.m_sp_openbg:setContentSize(bgWidth,cellHeight*count/2+bgHeight)
    else
        self.m_sp_openbg:setContentSize(bgWidth,cellHeight*(math.floor(count/2)+1)+bgHeight)
    end
    local size = self.m_sp_openbg:getContentSize()
    --收起来时候显示的道具
    self:addItem(self.m_node_iteml,self.m_itemList[1])
    self:addItem(self.m_node_itemr,self.m_itemList[2])
    --csb默认UI布局修改
    self.m_sp_open_title:setPosition(size.width*0.5,size.height-4.5)
    self.m_btn_hide:setPosition(size.width-10,size.height-10)
    self.m_sp_line1:setPosition(size.width*0.5,size.height-lineHeight)
    self.m_node_iteml1:setPosition(size.width*0.38,size.height-itemHeight)
    self.m_node_itemr1:setPosition(size.width*0.86,size.height-itemHeight)
    self.m_node_iteml1:setScale(1.2)
    self.m_node_itemr1:setScale(1.2)
    self:addItem(self.m_node_iteml1,self.m_itemList[1])
    self:addItem(self.m_node_itemr1,self.m_itemList[2])
    --额外新增道具布局添加
    local lineCount = 1
    for i=3,#self.m_itemList do
        local nodeCell = cc.Node:create()
        self.m_sp_openbg:addChild(nodeCell,1)
        self:addItem(nodeCell,self.m_itemList[i])
        nodeCell:setScale(1.2)
        if i%2==0 then
            --右道具
            local nodeHeight = size.height-itemHeight-(lineCount-1)*cellHeight
            nodeCell:setPosition(size.width*0.86,nodeHeight)
        else
            --增加分割线
            if lineCount~=1 then
                local spline = util_createSprite("PBRes/PBTips/ui/PB_open_fenge.png")
                self.m_sp_openbg:addChild(spline,1)
                local nodeLineHeight = size.height-lineHeight-(lineCount-1)*cellHeight
                spline:setPosition(size.width*0.5,nodeLineHeight)
            end
            --左道具
            lineCount = lineCount + 1
            local nodeHeight = size.height-itemHeight-(lineCount-1)*cellHeight
            nodeCell:setPosition(size.width*0.38,nodeHeight)
        end
    end
end
--单列多个道具 2个以上
function PBTipsNode:updateLineItem()
    local sSize = self.m_sp_showbg:getContentSize()
    local bgWidth = sSize.width --背景宽度
    local bgHeight = 40         --背景额外高度
    local cellHeight = 78       --一个格子高度
    local itemHeight = 63       --道具位置高度
    local lineHeight = 100      --分割线位置高度
    local count = #self.m_itemList

    self.m_sp_openbg:setContentSize(bgWidth,cellHeight*count+bgHeight)
    local size = self.m_sp_openbg:getContentSize()
    --收起来时候显示的道具
    self:addItem(self.m_node_iteml,self.m_itemList[1])
    self:addItem(self.m_node_itemr,self.m_itemList[2])
    --csb默认UI布局修改
    self.m_node_itemr1:setVisible(false)
    self.m_sp_open_title:setPosition(size.width*0.5,size.height-4.5)
    self.m_btn_hide:setPosition(size.width-10,size.height-10)
    self.m_sp_line1:setPosition(size.width*0.5,size.height-lineHeight)
    self.m_node_iteml1:setPosition(size.width*0.65,size.height-itemHeight)
    self.m_node_iteml1:setScale(1.2)
    self:addItem(self.m_node_iteml1,self.m_itemList[1])
    --额外新增道具布局添加
    for i=2,#self.m_itemList do
        local nodeCell = cc.Node:create()
        self.m_sp_openbg:addChild(nodeCell,1)
        nodeCell:setScale(1.2)
        local nodeHeight = size.height-itemHeight-(i-1)*cellHeight
        nodeCell:setPosition(size.width*0.65,nodeHeight)
        self:addItem(nodeCell,self.m_itemList[i])
        --增加分割线
        local spline = util_createSprite("PBRes/PBTips/ui/PB_open_fenge.png")
        self.m_sp_openbg:addChild(spline,1)
        local nodeLineHeight = size.height-lineHeight-(i-1)*cellHeight
        spline:setPosition(size.width*0.5,nodeLineHeight)
    end
end
--展示详细收益界面
function PBTipsNode:showPB()
    if self.m_status == self.STATUS_START then
        self.m_status = self.STATUS_DOING
        self:showMaskUI()
        self:runCsbAction("start",false,function()
            self.m_status = self.STATUS_OVER
        end,60)
    end
end
function PBTipsNode:showMaskUI()
    self.m_maskUI:setVisible(true)
    self.m_maskUI:setTouchEnabled(true)
end

--隐藏详细收益界面
function PBTipsNode:hidePB()
    if self.m_status == self.STATUS_OVER then
        self.m_status = self.STATUS_DOING
        self:runCsbAction("over",false,function()
            self.m_maskUI:setVisible(false)
            self.m_maskUI:setTouchEnabled(false)
            self.m_status = self.STATUS_START
        end,60)
    end
end

function PBTipsNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name=="btn_hide" then
        self:hidePB()
    elseif name == "btn_show" then
        self:showPB()
    end
end
return PBTipsNode