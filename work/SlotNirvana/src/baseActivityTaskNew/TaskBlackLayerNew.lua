--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-05 17:36:14
]]
local TaskBlackLayerNew = class("TaskBlackLayerNew", BaseLayer)

function TaskBlackLayerNew:ctor()
    TaskBlackLayerNew.super.ctor(self)
    self.m_currentPage = 1
    self:setMaskEnabled(false)
end

function TaskBlackLayerNew:initDatas(_csbName, _items, _stage)
    assert(_csbName, "TaskBlackLayerNew 传入的csb资源为空")
    self:setLandscapeCsbName(_csbName)
    self.m_items = _items or {}
    self.m_stage = _stage or 1
end

--初始化节点
function TaskBlackLayerNew:initCsbNodes()
    self.m_lb_round = self:findChild("lb_round_title")
end

-- function TaskBlackLayerNew:onShowedCallFunc()
--     self:runCsbAction("start", true, nil, 60)
-- end

function TaskBlackLayerNew:initView()
    -- local root = self:findChild("root")
    -- root:setPosition(display.width/2,display.height/2)
    self.m_lb_round:setString(self.m_stage)
    self.m_reward = {}
    for i=1,3 do
        local node = self:findChild("node_reward_"..i)
        self.m_reward[i] = node
    end
    local start_index = 1
    local items_list = {}
    if #self.m_items > 3 then
        start_index = #self.m_items - 2
        for i=start_index,#self.m_items do
            table.insert(items_list,self.m_items[i])
        end
    end
    for i,v in ipairs(items_list) do
        local itemNode = nil
        if v.coins > 0 then
            local shopItem = gLobalItemManager:createLocalItemData("Coins", v.coins)
            shopItem:setTempData({p_limit = 3})
            itemNode = gLobalItemManager:createRewardNode(shopItem, ITEM_SIZE_TYPE.REWARD)
        else
            itemNode = gLobalItemManager:createRewardNode(v.itemList[1], ITEM_SIZE_TYPE.REWARD)
        end
        local node = self.m_reward[i]
        if itemNode then
            node:addChild(itemNode)
        end
    end
    self:runCsbAction("start", false, function()
        self:closeUI()
    end, 60)
end

function TaskBlackLayerNew:closeUI()
    TaskBlackLayerNew.super.closeUI(self)
end

return TaskBlackLayerNew
