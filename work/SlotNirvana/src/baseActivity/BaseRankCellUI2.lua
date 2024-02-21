--[[
    author:JohnnyFred
    time:2019-11-05 10:23:40
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseRankCellUI2 = class("BaseRankCellUI2", util_require("base.BaseView"))
function BaseRankCellUI2:initUI(data, index)
    self:createCsbNode(self:getCsbName())
    self.m_index = index
    --索引
    self.rankIcon = self:findChild("rank_1")
    self.lbRank = self:findChild("rank_4")
    self.coinIcon = self:findChild("QuestLink_jiesuan_shan_16")
    self.m_propNode = self:findChild("propNode")
    self.lbCoins = self:findChild("coins")
    self.sprAdd = self:findChild("BitmapFontLabel_1")
    util_setCascadeOpacityEnabledRescursion(self, true)
    self:initView(data)
end

function BaseRankCellUI2:setRankValue(minRank, maxRank)
    local topThreeFlag = minRank == maxRank
    self.rankIcon:setVisible(topThreeFlag)
    self.lbRank:setVisible(not topThreeFlag)
    if topThreeFlag then
        util_changeTexture(self.rankIcon, self:getTopThreeBgName(minRank))
    end
    self.lbRank:setString(string.format("%d-%d", minRank, maxRank))
end

function BaseRankCellUI2:initView(data)
    if data ~= nil then
        --设置排名
        self:setRankValue(data.p_minRank, data.p_maxRank)
        --设置奖励金币
        self:initCoins(data)
        --设置奖励物品
        self:initRewardList(data.p_items)
    else
        if self.sprAdd then
            self.sprAdd:setVisible(false)
        end
    end
end

--设置奖励
function BaseRankCellUI2:initCoins(data)
    local maxLen = self:getCoinMaxLen()
    self.lbCoins:setString(util_formatCoins(data.p_coins, maxLen))
end

--设置奖励物品
function BaseRankCellUI2:initRewardList(extraPropList)
    local rewardUIList = {}
    local propNode = self.m_propNode
    if extraPropList ~= nil and #extraPropList > 0 then
        if self.sprAdd then
            self.sprAdd:setVisible(true)
            table.insert(rewardUIList, {node = self.sprAdd})
        end

        local scale = self:getRewardItemScale()
        local item_width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
        for k, v in ipairs(extraPropList) do
            local propUI = gLobalItemManager:createRewardNode(v, ITEM_SIZE_TYPE.TOP)
            if propUI ~= nil then
                propUI:setScale(scale)
                propNode:addChild(propUI)
                table.insert(rewardUIList, {node = propUI, alignX = 3, size = cc.size(item_width, item_width), anchor = cc.p(0.5, 0.5)})
            end
        end
    end
    util_alignLeft(rewardUIList)
end

--buff添加时间显示
function BaseRankCellUI2:addBuffLeftTimeNode(parentUI, buffInfo)
    local cont = parentUI:getContentSize()
    local buffCsb = util_createBuffLeftTime(util_switchSecondsToHSM(buffInfo.buffExpire), cc.p(cont.width / 2, 20))
    parentUI:addChild(buffCsb, 100)
end
------------------------------------------子类重写---------------------------------------
function BaseRankCellUI2:getCsbName()
    return nil
end

function BaseRankCellUI2:getTopThreeBgName(rank)
    return nil
end

function BaseRankCellUI2:getCoinMaxLen()
    return 6
end

function BaseRankCellUI2:getRewardItemScale()
    return 0.9
end
------------------------------------------子类重写---------------------------------------
return BaseRankCellUI2
