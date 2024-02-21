--[[
    --新版每日任务pass主界面 标题
    csc 2021-06-21
]]
local DailyMissionThreeLinePassQiPao = class("DailyMissionThreeLinePassQiPao", util_require("base.BaseView"))
function DailyMissionThreeLinePassQiPao:initUI(isSpeical)
    self.m_useSpecialBubble = isSpeical
    self:createCsbNode(self:getCsbName())

    -- 读取csb 节点
    self.m_imgBg   = self:findChild("Img_qipao")
    self.m_labDesc = self:findChild("lb_desc")
    self.m_nodeReward = self:findChild("node_reward")
end

function DailyMissionThreeLinePassQiPao:getCsbName()
    local result = DAILYPASS_RES_PATH.DailyMissionPass_PassCellQipao_ThreeLine  
    if self.m_useSpecialBubble then
        result = DAILYPASS_RES_PATH.DailyMissionPass_PassCellSpecialQipao_ThreeLine  
    end
    return result
end

function DailyMissionThreeLinePassQiPao:showView(boxInfo)
    if not boxInfo then
        return
    end

    local strDes = boxInfo:getDesc()
    self.m_labDesc:setString(strDes)
    
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

function DailyMissionThreeLinePassQiPao:addMask()
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

function DailyMissionThreeLinePassQiPao:showTaskRewardView(_rewardData)
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
    local node = gLobalItemManager:addPropNodeList(propList, itemSizeType,0.8,110)
    node:setPositionY(node:getPositionY() + 35 )
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

function DailyMissionThreeLinePassQiPao:closeUI()
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

return DailyMissionThreeLinePassQiPao