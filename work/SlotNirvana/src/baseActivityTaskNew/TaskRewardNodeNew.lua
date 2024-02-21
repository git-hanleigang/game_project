--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-06 10:53:26
    describe:新版大活动任务奖励节点
]]
local TaskRewardNodeNew = class("TaskRewardNodeNew", util_require("base.BaseView"))

function TaskRewardNodeNew:initUI(_params)
    self.m_data = _params.data
    self.m_spineName = _params.spineName
    self.m_flowerOpenSound = _params.flowerOpenSound
    self.m_isInAnimation = false
    self:createCsbNode(_params.csbName)
    self:runCsbAction("idle", true)
    self:initNode()
    self:addItems()
    self:initStage()
    self:initSpine()
end

--初始化节点
function TaskRewardNodeNew:initNode()
    self.m_node_reward = self:findChild("node_reward")
    assert(self.m_node_reward, "任务节点为空")
    self.m_lb_number = self:findChild("lb_number")
    assert(self.m_lb_number, "进度描述为空")
    self.m_node_bubble = self:findChild("node_bubble")
    assert(self.m_node_bubble, "气泡奖励节点为空")
    self.m_sp_bubble = self:findChild("sp_bubble_di")
    assert(self.m_sp_bubble, "气泡底板为空")
    self.m_sp_dui = self:findChild("sp_dui")
    assert(self.m_sp_dui, "对勾节点为空")
    self.m_node_spine = self:findChild("node_spine")
    assert(self.m_node_spine, "spine节点为空")
end

--初始化spine
function TaskRewardNodeNew:initSpine()
    local spineName = self.m_spineName
    if spineName then
        self.m_spine = util_spineCreate(spineName, false, true, 1)
        self.m_node_spine:addChild(self.m_spine)
        if self.m_data.collect then
            util_spinePlay(self.m_spine, "idle2", true)
        else
            util_spinePlay(self.m_spine, "idle1", true)
        end
    end
end

--初始化spine
function TaskRewardNodeNew:playSpine()
    if self.m_spine then
        if self.m_flowerOpenSound and type(self.m_flowerOpenSound) == "string" then
            gLobalSoundManager:playSound(self.m_flowerOpenSound)
        end
        util_spinePlay(self.m_spine, "kaihua", false)
        util_spineEndCallFunc(
            self.m_spine,
            "kaihua",
            function()
                util_spinePlay(self.m_spine, "idle2", true)
            end
        )
    end
end

--添加道具
function TaskRewardNodeNew:addItems()
    if self.m_data then
        local itemDataList = {}
        --金币道具
        if self.m_data.coins and self.m_data.coins > 0 then
            local itemData = gLobalItemManager:createLocalItemData("Coins", self.m_data.coins)
            itemData:setTempData({p_limit = 3})
            itemDataList[#itemDataList + 1] = itemData
        end
        --通用道具
        local rewardItems = self.m_data.itemList
        local count = #rewardItems
        if rewardItems and count > 0 then
            for i, v in ipairs(rewardItems) do
                itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            end
        end
        local itemNode = nil
        local itemWidth = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD) * 0.6
        local extraWidth = (#itemDataList - 1) * (itemWidth + 10)
        itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
        itemNode:setScale(0.6)
        self.m_node_reward:addChild(itemNode)
        local size = self.m_sp_bubble:getContentSize()
        self.m_sp_bubble:setContentSize(cc.size(size.width + extraWidth, size.height))
        if self.m_data.collect then
            self:runCsbAction("idle2", true)
            for i = 1, #itemDataList do
                local node = itemNode:getChildByTag("" .. i)
                if node then
                    node:setGrey(true)
                end
            end
        end
        self.m_itemNode = itemNode
        self.m_itemDataList = itemDataList
    end
end

function TaskRewardNodeNew:initStage()
    local point = self.m_data.needPoints or ""
    self.m_lb_number:setString("" .. point)
end

function TaskRewardNodeNew:refreshShow(_data)
    self.m_data = _data
    self.m_node_reward:removeAllChildren()
    self:addItems()
end

function TaskRewardNodeNew:setItemMask()
    for i = 1, #self.m_itemDataList do
        local node = self.m_itemNode:getChildByTag("" .. i)
        if node then
            util_setCascadeColorEnabledRescursion(node, true)
            node:runAction(cc.TintTo:create(15 / 60, cc.c3b(127, 115, 150)))
        end
    end
end

-- 打勾动画
function TaskRewardNodeNew:playCheckAction()
    if self.m_isInAnimation then
        return
    end
    self.m_isInAnimation = true
    self:runCsbAction(
        "dagou",
        false,
        function()
            self:runCsbAction("idle2", true)
        end,
        60
    )
    self:setItemMask()
    self:playSpine()
end

--增加初始化动画
function TaskRewardNodeNew:updateUI()
    self:runCsbAction("idle", true)
    if self.m_spine then
        util_spinePlay(self.m_spine, "idle1", true)
    end
end

return TaskRewardNodeNew
