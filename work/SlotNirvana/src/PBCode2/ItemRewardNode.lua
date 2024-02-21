--道具
local BaseItemNode = util_require("PBCode2.BaseItemNode")
local ItemRewardNode = class("ItemRewardNode", BaseItemNode)

ItemRewardNode._getCsbPath = function(_itemSizeType)
    if not _itemSizeType then
        return
    end
    local csbPath = nil
    if _itemSizeType == ITEM_SIZE_TYPE.REWARD_SUPER then
        csbPath = "PBRes/CommonItemRes/ItemRewardSuperNode.csb"
    elseif _itemSizeType == ITEM_SIZE_TYPE.REWARD_BIG then
        csbPath = "PBRes/CommonItemRes/ItemRewardBigNode.csb"
    elseif _itemSizeType == ITEM_SIZE_TYPE.REWARD then
        csbPath = "PBRes/CommonItemRes/ItemRewardNode.csb"
    elseif _itemSizeType == ITEM_SIZE_TYPE.BATTLE_PASS then
        csbPath = "PBRes/CommonItemRes/ItemRewardBattlePassNode.csb"
    elseif _itemSizeType == ITEM_SIZE_TYPE.SIDEKICKS then
        csbPath = "PBRes/CommonItemRes/ItemRewardNode_sidekicks.csb"
    elseif _itemSizeType == ITEM_SIZE_TYPE.TOP then
        csbPath = "PBRes/CommonItemRes/ItemRewardTopNode.csb"
    else
        csbPath = "PBRes/CommonItemRes/ItemRewardBigNode.csb"
    end
    return csbPath
end

--初始化csb
function ItemRewardNode:getCsbPath()
    return ItemRewardNode._getCsbPath(self.m_itemSizeType)
end
--更新布局与数值
function ItemRewardNode:updateLayoutValue(value)
    if self.m_lb_value then
        self.m_lb_value:setVisible(false)
    end
    if self.m_lb_num then
        self.m_lb_num:setVisible(false)
    end
    if not self.m_data.p_mark then
        return
    end
    if not self.m_itemSizeType then
        return
    end
    local charType = self.m_data.p_mark[1]
    if not charType then
        return
    end
    local char = ""
    if charType == ITEM_MARK_TYPE.NONE then
        --无角标
        self.m_lb_select = nil
    elseif charType == ITEM_MARK_TYPE.CENTER_X then
        if self.m_itemSizeType == ITEM_SIZE_TYPE.BATTLE_PASS then
            --1：下方居中×角标
            self.m_lb_select = self.m_lb_value
        else
            --1：右下角×角标
            self.m_lb_select = self.m_lb_num
        end
        char = "X"
    elseif charType == ITEM_MARK_TYPE.CENTER_ADD then
        --2：下方居中加号角标
        self.m_lb_select = self.m_lb_value
        char = "+"
    elseif charType == ITEM_MARK_TYPE.CENTER_BUFF then
        --3：下方居中BUFF角标&金币
        self.m_lb_select = self.m_lb_value
    elseif charType == ITEM_MARK_TYPE.CENTER_X_ITEM then
        self.m_lb_select = self.m_lb_value
        char = "X"
    elseif charType == ITEM_MARK_TYPE.ONLYONE then
        self.m_lb_select = self.m_lb_value
        char = "X"
        value = 1
    elseif charType == ITEM_MARK_TYPE.MIDDLE_X then
        --7：下方居中x角标
        self.m_lb_select = self.m_lb_value
        char = "x"
    end
    if self.m_lb_select then
        self.m_lb_select:setVisible(true)
        self.m_lb_select:setString(char .. value)
        self.m_lableStr = char .. value
    end
end

function ItemRewardNode:getLabelStrAndHideLable(doHide)
    if self.m_lb_select then
        self.m_lb_select:setVisible(not doHide)
    end
    return self.m_lableStr or ""
end

function ItemRewardNode:getValue()
    return self.m_lb_select
end

function ItemRewardNode:getIcon()
    return self.m_newIcon
end

return ItemRewardNode
