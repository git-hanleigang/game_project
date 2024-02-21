--[[
    带走奖励，二次确认弹板
]]
local CSConfirmLayer = class("CSConfirmLayer", BaseLayer)

function CSConfirmLayer:initDatas()
    self:setLandscapeCsbName(CardSeekerCfg.csbPath .. "Seeker_Confirm.csb")
end

function CSConfirmLayer:initCsbNodes()
    self.m_nodeRewards = self:findChild("node_rewards")
    
    self:setButtonLabelContent("btn_continue","CONTINUE")
    self:setButtonLabelContent("btn_take","TAKE&GO")
end

function CSConfirmLayer:initView()
    self:initRewards()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CSConfirmLayer:initRewards()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local winRewardData = GameData:getWinRewardData()
    if not winRewardData then
        return
    end    
    self.m_itemNodeList = {}

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

    local itemDatas = winRewardData:getMergeItems()
    if itemDatas and #itemDatas > 0 then
        for i = 1, #itemDatas do
            local tempData = itemDatas[i]
            if tempData.p_type == "Package" then
                tempData:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_ADD}})
            end
            self:createRewardNode(tempData)
        end
    end

    util_alignCenter(self.m_itemNodeList, nil, 700)
end

function CSConfirmLayer:createRewardNode(_tempData)
    local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
    local itemNode = gLobalItemManager:createRewardNode(_tempData, ITEM_SIZE_TYPE.REWARD)
    self.m_nodeRewards:addChild(itemNode)
    local nodeData = {node = itemNode, itemData = _tempData, size = cc.size(width, 0), anchor = cc.p(0.5, 0.5)}
    self.m_itemNodeList[#self.m_itemNodeList + 1] = nodeData
end
function CSConfirmLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function CSConfirmLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_continue" then
        self:closeUI()
    elseif name == "btn_take" then
        self:closeUI(
            function()
                G_GetMgr(G_REF.CardSeeker):showRewardLayer(false)
            end
        )
    end
end

function CSConfirmLayer:getTSGameData()
    return G_GetMgr(G_REF.CardSeeker):getData()
end

return CSConfirmLayer
