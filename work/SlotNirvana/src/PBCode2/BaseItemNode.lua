--道具
local BaseItemNode = class("BaseItemNode", util_require("base.BaseView"))
local CommonIcon_Info = util_require("luaStdTable.CommonIcon_Info")

BaseItemNode._getCsbPath = function()
    return "PBRes/CommonItemRes/ItemDescNode.csb"
end

function BaseItemNode:initDatas(data, newIcon, itemSizeType, mul)
    self.m_data = data
    self.m_newIcon = newIcon --兼容老代码不能直接用icon需要用这个转化后的
    self.m_itemSizeType = itemSizeType or ITEM_SIZE_TYPE.REWARD_BIG
    self.m_mul = mul or 1 --奖励是否翻倍
    self.m_sp_icon = nil
    self.m_specialNode = nil
    if self.m_data and self.m_newIcon then
        self.m_data.p_icon = self.m_newIcon
    end
end

function BaseItemNode:initUI()
    local _csb = self:getCsbPath()
    if _csb then
        self:createCsbNode(_csb)
    end

    self:initView()
    self:updateItem()
end

function BaseItemNode:initCsbNodes()
    self.m_node_icon = self:findChild("node_icon")
    self.m_lb_value = self:findChild("lb_value")
    self.m_lb_num = self:findChild("lb_num")
    self.m_lb_name = self:findChild("lb_name")
    self.m_lb_name_sub = self:findChild("lb_name_sub")
end

--界面
function BaseItemNode:initView()
    self:initOther()
end
--更新道具
function BaseItemNode:updateItem()
    self:updateIcon()
    self:updateNum()
    self:updateFntConfig(self.m_data.p_fntConfig)
end
--更新图标资源
function BaseItemNode:updateIcon(iconPath)
    --检测特殊节点
    if not gLobalItemManager:checkSpecialNode(self.m_newIcon) then
        --正常替图
        -- if iconPath then
        --     self.m_sp_icon = util_createSprite(iconPath)
        -- else
        --     self.m_sp_icon = gLobalItemManager:createNormalNode(self.m_newIcon, self.m_itemSizeType)
        -- end
        -- if self.m_sp_icon then
        --     self.m_node_icon:addChild(self.m_sp_icon)
        -- end
        if not tolua.isnull(self.m_specialNode) then
            self.m_specialNode:removeFromParent()
            self.m_specialNode = nil
        end
        local finalIcon = ""
        if iconPath then
            finalIcon = iconPath
        else
            finalIcon = gLobalItemManager:getNormalIconPath(self.m_newIcon, self.m_itemSizeType)
        end
        if tolua.isnull(self.m_sp_icon) then
            self.m_sp_icon = util_createSprite(finalIcon)
            self.m_node_icon:addChild(self.m_sp_icon)
        else
            util_changeTexture(self.m_sp_icon, finalIcon)
        end
    else
        self.m_node_icon:removeAllChildren()
        self.m_sp_icon = nil
        self.m_specialNode = nil
        --特殊节点
        self.m_specialNode = gLobalItemManager:createSpecialNode(self.m_data, self.m_newIcon, self.m_mul)
        if self.m_specialNode then
            self.m_node_icon:addChild(self.m_specialNode)
        end
    end

    self:checkAddIconTouch()
end

function BaseItemNode:checkAddIconTouch()
    local touch = self.m_node_icon:getChildByName("touch_icon")
    if touch then
        return
    end
    touch = util_makeTouch(self, "touch_icon")
    local width = 128
    if self.m_itemSizeType == ITEM_SIZE_TYPE.REWARD_SUPER then
        width = 320
    end
    touch:setSwallowTouches(true)
    touch:setContentSize(cc.size(width, width))
   
    self.m_node_icon:addChild(touch)
    self:addClick(touch)
end

function BaseItemNode:updateNum()
    --更新数量
    local value = nil
    if self.m_data:isBuff() then
        -- if self.m_mul < 1 then
        --     dump(self.m_data, "buff 数据展示 乘倍问题")
        -- end
        value = self.m_data:getBuffValue(self.m_mul)
    else
        value = self.m_data:getNormalValue(self.m_mul)
    end
    self:updateLayoutValue(value)
end

--子类重写
--初始化csb
function BaseItemNode:getCsbPath()
    return BaseItemNode._getCsbPath()
end
--初始化其他
function BaseItemNode:initOther()
end
--更新布局与数值
function BaseItemNode:updateLayoutValue(value)
end

--更新字体
function BaseItemNode:updateFntConfig(fntConfig)
    if not fntConfig then
        return
    end
    local value = self:getValue()
    if not value then
        return
    end
    if fntConfig.path then
        value:setFntFile(fntConfig.path)
    end
    if fntConfig.scale then
        value:setScale(fntConfig.scale)
    end
    if fntConfig.pos then
        value:setPosition(fntConfig.pos)
    end
end

--获取字体
function BaseItemNode:getValue()
    return self.m_lb_value
end

function BaseItemNode:getItemData()
    return self.m_data
end

function BaseItemNode:setGrey(_isGrey)
    local color = _isGrey and cc.c3b(127, 115, 150) or cc.c3b(255, 255, 255)
    self.m_node_icon:setColor(color)
    local label = self:getValue()
    if label then
        label:setColor(color)
    end
end

function BaseItemNode:resetUI(data, newIcon, itemSizeType, mul)
    local isDirty = self:resetDatas(data, newIcon, itemSizeType, mul)
    if isDirty then
        self:updateItem()
    end
end

function BaseItemNode:resetDatas(data, newIcon, itemSizeType, mul)
    local isDirty = false
    if data then
        self.m_data = data
        isDirty = true
    end
    if newIcon and newIcon ~= self.m_newIcon then
        self.m_newIcon = newIcon --兼容老代码不能直接用icon需要用这个转化后的
        isDirty = true
    end
    if itemSizeType and itemSizeType ~= self.m_itemSizeType then
        self.m_itemSizeType = itemSizeType or ITEM_SIZE_TYPE.REWARD_BIG
        isDirty = true
    end
    if mul and mul ~= self.m_mul then
        self.m_mul = mul or 1 --奖励是否翻倍
        isDirty = true
    end
    if self.m_data and self.m_newIcon then
        self.m_data.p_icon = self.m_newIcon
    end
    return isDirty
end

function BaseItemNode:clickFunc(sender)
    local name = sender:getName()
    if name == "touch_icon" then
        if self.m_data and CommonIcon_Info[self.m_data.p_icon] and CommonIcon_Info[self.m_data.p_icon][2] and CommonIcon_Info[self.m_data.p_icon][2] ~= "" then
            gLobalItemManager:showItemDescTipLayer(self.m_data, self.m_itemSizeType, self.m_mul)
        end
    end
end

-- 设置 道具触摸 可用状态
function BaseItemNode:setIconTouchEnabled(_bTouchEnabled)
    local touch = self.m_node_icon:getChildByName("touch_icon")
    if not touch then
        return
    end

    touch:setTouchEnabled(_bTouchEnabled or false)
end
-- 设置 道具触摸 吞噬状态
function BaseItemNode:setIconTouchSwallowed(_bSwallowTouches)
    local touch = self.m_node_icon:getChildByName("touch_icon")
    if not touch then
        return
    end

    touch:setSwallowTouches(_bSwallowTouches or false)
end

return BaseItemNode
