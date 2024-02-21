--[[
    --新版每日任务pass主界面 标题
    csc 2021-06-21
]]
local QuestPassQiPao = class("QuestPassQiPao", util_require("base.BaseView"))

function QuestPassQiPao:getCsbName()
    return QUEST_RES_PATH.QuestPassCellBubble
end

function QuestPassQiPao:initUI()
    QuestPassQiPao.super.initUI(self)

    self.m_imgBg   = self:findChild("sp_bubble")
    self.m_labDesc = self:findChild("lb_desc") 
end

function QuestPassQiPao:showView(boxInfo)
    if not boxInfo then
        return
    end

    self.m_labDesc:setString(boxInfo.p_desc)
    
    -- 设置九宫格大小
    local size = self.m_labDesc:getContentSize()
    local bgSize = self.m_imgBg:getContentSize()
    self.m_imgBg:setContentSize({width=size.width +bgSize.width,height=bgSize.height} )

    self:runCsbAction(
        "start",
        false,
        function()
            performWithDelay(
                self,
                function()
                    self:closeUI()
                end,
                3
            )
        end
    )
    -- 添加mask
    self:addMask()
end

function QuestPassQiPao:addMask()
    local mask = util_newMaskLayer()
    mask:setOpacity(0)
    local isTouch = false
    mask:onTouch(
        function(event)
            if not isTouch then
                return true
            end
            if event.name == "ended" then
                self:removeFromParent()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_REMOVE_REWARD_INFO,false)
            end

            return true
        end,
        false,
        true
    )

    performWithDelay(
        self,
        function()
            isTouch = true
        end,
        0.5
    )
    self:addChild(mask)
end

function QuestPassQiPao:showTaskRewardView(_rewardData)
    -- 创建奖励道具
    local propList = {}
    if _rewardData.coins and _rewardData.coins > 0 then
        propList[#propList + 1] = gLobalItemManager:createLocalItemData("Coins", tonumber(_rewardData.coins), {p_limit = 3})
    end
    if _rewardData.items and #_rewardData.items > 0 then
        local itemList = {}
        for i = 1, #_rewardData.items do
            local itemData = _rewardData.items[i]
            propList[#propList + 1] = itemData
        end
    end
    --默认大小
    local defaultWidth = 128
    local defaultHeight = 128
    local itemSizeType = ITEM_SIZE_TYPE.BATTLE_PASS
    -- battlepass
    local node = gLobalItemManager:addPropNodeList(propList, itemSizeType,0.9,110)
    node:setPositionY(node:getPositionY() + 45 )
    self.m_nodeReward:addChild(node)

    self.m_labDesc:setVisible(false)
    -- 设置九宫格大小
    local width = #propList == 1 and defaultWidth or gLobalItemManager:getIconDefaultWidth(itemSizeType) 
    local addWidth = #propList == 1 and 0 or width
    width =  width * (#propList) + addWidth 
    self.m_imgBg:setContentSize({width= width ,height = defaultHeight} )
    self:runCsbAction(
        "start",
        false,
        function()
            performWithDelay(
                self,
                function()
                    self:closeUI()
                end,
                3
            )
        end
    )

    -- 添加mask
    self:addMask()
end

function QuestPassQiPao:closeUI()
    self:runCsbAction(
        "over",
        false,
        function()
            if not tolua.isnull(self) then
                self:removeFromParent()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_REMOVE_REWARD_INFO,false)
            end
        end
    )
end

return QuestPassQiPao