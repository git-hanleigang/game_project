--[[
    
    author:徐袁
    time:2021-03-29 15:22:09
]]
local StatuePickStartLayer = class("StatuePickStartLayer", BaseLayer)

StatuePickStartLayer.ActionType = "Common"

function StatuePickStartLayer:ctor()
    StatuePickStartLayer.super.ctor(self)

    self:setLandscapeCsbName("CardRes/season202102/Statue/StatuePickStartLayer.csb")
    self:setShowActionEnabled(false)
    -- self:setHideActionEnabled(false)
    self:setShowBgOpacity(0)
    -- self:setPauseSlotsEnabled(true)
    self:setExtendData("StatuePickStartLayer")
end

--[[
    @desc: 初始化csb节点
    author:徐袁
    time:2021-03-29 15:22:09
    @return:
]]
function StatuePickStartLayer:initCsbNodes()
    self.m_spCoins = self:findChild("sp_coins")
    self.m_txtCoins = self:findChild("font_coin")
    self.m_nodeReward = self:findChild("node_reward")
end

--[[
    @desc: 初始化界面显示
    author:徐袁
    time:2021-03-29 15:22:09
    @return:
]]
function StatuePickStartLayer:initView()
end

--[[
    @desc: 刷新界面显示
    author:徐袁
    time:2021-03-29 15:22:09
    @return:
]]
function StatuePickStartLayer:updateView()
    local maxCoins = StatuePickGameData:getMaxCoins()
    self.m_txtCoins:setString(util_formatCoins(maxCoins, 21))
    local txtMaxLength = 683
    self:updateLabelSize({label = self.m_txtCoins}, txtMaxLength)

    -- 计算updateLabelSize缩放比例
    local txtWidth = self.m_txtCoins:getContentSize().width
    local txtScale = txtMaxLength / txtWidth
    if txtWidth <= txtMaxLength then
        txtScale = 1
    end

    local UIList = {}
    table.insert(UIList, {node = self.m_spCoins, anchor = cc.p(0.5, 0.5)})
    table.insert(UIList, {node = self.m_txtCoins, scale = txtScale, alignX = 5, anchor = cc.p(0.5, 0.5)})
    util_alignCenter(UIList)

    local rewardList = {}

    -- 显示宝石
    local gemCoins = gLobalItemManager:createLocalItemData("Gem")
    table.insert(rewardList, gemCoins)

    -- 卡包
    -- local _packet = gLobalItemManager:createLocalItemData("card_kabao")
    -- table.insert(rewardList, _packet)

    -- 神像卡
    local _sxCard = gLobalItemManager:createLocalItemData("Card_Statue_Package")
    table.insert(rewardList, _sxCard)

    local _nodeItem = gLobalItemManager:addPropNodeList(rewardList, nil, 0.7)
    if _nodeItem then
        self.m_nodeReward:addChild(_nodeItem)
    end
end

-- 注册消息事件
function StatuePickStartLayer:registerListener()
    StatuePickStartLayer.super.registerListener(self)
end

function StatuePickStartLayer:onEnter()
    StatuePickStartLayer.super.onEnter(self)
    self:updateView()
end

function StatuePickStartLayer:onExit()
    StatuePickStartLayer.super.onExit(self)
end

-- layer显示完成的回调
function StatuePickStartLayer:onShowedCallFunc()
end

function StatuePickStartLayer:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "Button_1" then
        StatuePickControl:requestStartGame()
    end
end

return StatuePickStartLayer
