--[[
    已经获得的奖励
]]
local CSMainReward = class("CSMainReward", BaseView)

function CSMainReward:initDatas()
end

function CSMainReward:getCsbName()
    return CardSeekerCfg.csbPath .. "Seeker_MainLayer_Reward.csb"
end

function CSMainReward:initCsbNodes()
    self.m_nodeRewards = self:findChild("node_rewards")
end

function CSMainReward:initUI()
    CSMainReward.super.initUI(self)
    self:runCsbAction("idle", true, nil, 60)
    self:initView()
end

function CSMainReward:initView()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    if not self.m_itemNodeList then
        self.m_itemNodeList = {}
    end

    local winRewardData = GameData:getWinRewardData()
    if not winRewardData then
        return
    end     
    local coinNum = winRewardData:getCoins()
    if coinNum and coinNum > 0 then
        local tempData = gLobalItemManager:createLocalItemData("Coins", coinNum, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        self:createRewardNode(tempData)
    end

    local gemNum = winRewardData:getGems()
    if gemNum and gemNum > 0 then
        local tempData = gLobalItemManager:createLocalItemData("Gem", gemNum, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        self:createRewardNode(tempData)
    end

    local itemDatas = winRewardData:getItems()
    if itemDatas and #itemDatas > 0 then
        for i = 1, #itemDatas do
            local tempData = itemDatas[i]
            if tempData.p_type == "Package" then
                tempData:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_ADD}})
            end
            self:createRewardNode(tempData)
        end
    end

    util_alignCenter(self.m_itemNodeList, nil, 530)
end

function CSMainReward:createRewardNode(_tempData)
    local itemUI = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainRewardItem", _tempData)
    if itemUI then
        self.m_nodeRewards:addChild(itemUI)
        local itemSize = itemUI:getItemSize()
        local nodeData = {node = itemUI, itemData = _tempData, scale = 1, size = cc.size(itemSize.width, 0), anchor = cc.p(0.5, 0.5)}
        self.m_itemNodeList[#self.m_itemNodeList + 1] = nodeData
    end
    return itemUI
end

-- 外部调用
function CSMainReward:winReward(_winLevelIndex)
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local levelData = GameData:getLevelDataByIndex(_winLevelIndex)
    if not levelData then
        return
    end
    local boxData = levelData:getWillOpenBoxRewardData()
    if not boxData then
        return
    end
    gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/titleRewardAppear.mp3")
    local itemUI = nil
    local tempData = nil
    local boxType = boxData:getType()
    if boxType == CardSeekerCfg.BoxType.coin then
        local coinNum = boxData:getValue()
        if coinNum and coinNum > 0 then
            tempData = gLobalItemManager:createLocalItemData("Coins", coinNum, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        end
        itemUI = self:getItemNode("itemIcon", "Coins")
    elseif boxType == CardSeekerCfg.BoxType.gem then
        local gemNum = boxData:getValue()
        if gemNum and gemNum > 0 then
            tempData = gLobalItemManager:createLocalItemData("Gem", gemNum, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        end
        itemUI = self:getItemNode("itemIcon", "Gem")
    elseif boxType == CardSeekerCfg.BoxType.item then
        local itemDatas = boxData:getItems()
        if itemDatas and #itemDatas > 0 then
            for i = 1, #itemDatas do
                itemUI = self:getItemNode("itemId", itemDatas[i].p_itemInfo.p_id)
                tempData = itemDatas[i]
                break
            end
        end
    end

    if tempData then
        if itemUI then
            itemUI:updateNum(tempData)
        else
            if tempData.p_type == "Package" then
                tempData:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_ADD}})
            end
            itemUI = self:createRewardNode(tempData)
            itemUI:playStart()
            util_alignCenter(self.m_itemNodeList, nil, 530)
        end
    end
    if itemUI then
        self:showLight(itemUI)
    end
end

function CSMainReward:showLight(_parentNode)
    local light = util_createAnimation(CardSeekerCfg.csbPath .. "Seeker_MainLayer_Reward_item_light.csb")
    _parentNode:addChild(light,-1)
    light:playAction(
        "start",
        false,
        function()
            if not tolua.isnull(light) then
                light:removeFromParent()
                light = nil
            end
        end,
        60
    )
end

function CSMainReward:getTSGameData()
    return G_GetMgr(G_REF.CardSeeker):getData()
end

function CSMainReward:getItemNode(_type, _value)
    if self.m_itemNodeList and #self.m_itemNodeList > 0 then
        for i = 1, #self.m_itemNodeList do
            local itemData = self.m_itemNodeList[i].itemData
            if _type == "itemIcon" then
                if itemData.p_icon == _value then
                    return self.m_itemNodeList[i].node
                end
            elseif _type == "itemId" then
                if itemData.p_itemInfo and itemData.p_itemInfo.p_id ~= nil then
                    if tonumber(itemData.p_itemInfo.p_id) == tonumber(_value) then
                        return self.m_itemNodeList[i].node
                    end
                end
            end
        end
    end
    return nil
end

return CSMainReward
