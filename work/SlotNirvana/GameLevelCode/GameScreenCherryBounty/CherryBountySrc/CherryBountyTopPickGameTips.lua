--[[
    respin提示兼计数栏
]]
local CherryBountyTopPickGameTips = class("CherryBountyTopPickGameTips", util_require("base.BaseView"))

function CherryBountyTopPickGameTips:initUI(_machine)
    self.m_machine     = _machine
    self:createCsbNode("CherryBounty_xinxiqu_logo.csb")

    self.m_logoSpine = util_spineCreate("CherryBounty_xinxiqu_logo2", true, true)
    self:findChild("Node_spine"):addChild(self.m_logoSpine)
    
    self.m_rewardCsb  = util_createAnimation("CherryBounty_xinxiqu_pick.csb")
    self:findChild("Node_pick"):addChild(self.m_rewardCsb)
    self.m_itemParent = self.m_rewardCsb:findChild("Node_rewardItem")
    -- {name="", count=1, csb=cc.Node}
    self.m_rewardItemList = {}
    for _jpIndex,_jpType in ipairs(self.m_machine.JackpotIndexToType) do
        local rewardItem = {}
        rewardItem.name    = _jpType
        rewardItem.count   = 1
        rewardItem.csb     = util_createAnimation("CherryBounty_xinxiqu_pick_caijin.csb")
        self.m_itemParent:addChild(rewardItem.csb)
        rewardItem.csb:setVisible(false)
        local jpNode = rewardItem.csb:findChild( string.format("jackpot_%d",_jpIndex) )
        jpNode:setVisible(true)
        table.insert(self.m_rewardItemList, rewardItem)
    end
end

--logo时间线
function CherryBountyTopPickGameTips:playLogoIdleAnim()
    self.m_logoSpine:setVisible(true)
    util_spinePlay(self.m_logoSpine, "animation", true)
    
    self.m_rewardCsb:setVisible(false)
    for i,v in ipairs(self.m_rewardItemList) do
        v.csb:setVisible(false)
    end
end
--奖励时间线
function CherryBountyTopPickGameTips:playRewardIdleAnim()
    self.m_logoSpine:setVisible(false)
    self.m_rewardCsb:setVisible(true)
end
--奖励时间线-添加一个奖励
function CherryBountyTopPickGameTips:playRewardAddAnim(_reward, _fun)
    local typeCount  = self:getRewardItemShowCount()
    local rewardItem = self:getRewardItemByType(_reward.name)
    local bAdd = not rewardItem.csb:isVisible()
    if bAdd then
        rewardItem.count   = 1
        rewardItem.csb:setVisible(true)
    else
        rewardItem.count   = rewardItem.count + 1
    end
    if bAdd then
        --彩金栏
        local jpIndexList = self:getJackpotIndexList()
        self.m_machine.m_jackpotBar:playJackpotBarTrigger(jpIndexList)
        --展示切换
        if  typeCount <= 0 then
            self:playRewardIdleAnim()
        end
    end

    self:upDateRewardItemCount()
    self:upDateRewardItemPos()
    self:playSwitchAnim(_reward, _fun)
end
--奖励时间线-刷新
function CherryBountyTopPickGameTips:playSwitchAnim(_reward, _fun)
    self.m_rewardCsb:runCsbAction("switch", false, _fun)
    for i,v in ipairs(self.m_rewardItemList) do
        if _reward.name == v.name then
            v.csb:runCsbAction("switch", false)
        end
    end
end
--奖励列表-刷新数量
function CherryBountyTopPickGameTips:upDateRewardItemCount()
    local showList  = self:getRewardItemShowList()
    for i,v in ipairs(showList) do
        local labMult = v.csb:findChild("m_lb_multi")
        labMult:setString(string.format("X%d", v.count))
    end
end
function CherryBountyTopPickGameTips:upDateRewardItemPos()
    local showList  = self:getRewardItemShowList()
    local typeCount = #showList
    local posIndex  = 1
    local jpCount   = #self.m_machine.JackpotIndexToType
    for _jpIndex=1,jpCount do
        local jpType = self.m_machine.JackpotIndexToType[_jpIndex]
        local rewardItem = self:getShowRewardItemByType(jpType)
        if rewardItem then
            local nodeName = string.format("%d%d", typeCount, posIndex)
            local posNode = self.m_rewardCsb:findChild(nodeName)
            rewardItem.csb:setPosition(util_convertToNodeSpace(posNode, self.m_itemParent))
            rewardItem.csb:setScale(posNode:getScale())
            posIndex = posIndex + 1
        end
    end
end

--奖励列表-获取1个类型
function CherryBountyTopPickGameTips:getRewardItemByType(_name)
    for i,v in ipairs(self.m_rewardItemList) do
        if v.name == _name then
            return v
        end
    end
    return nil
end
--奖励列表-获取1个展示的类型
function CherryBountyTopPickGameTips:getShowRewardItemByType(_name)
    for i,v in ipairs(self.m_rewardItemList) do
        if v.name == _name then
            if v.csb:isVisible() then
                return v
            else
                return nil
            end
        end
    end
    return nil
end
--奖励列表-获取彩金索引列表
function CherryBountyTopPickGameTips:getJackpotIndexList()
    local showList = self:getRewardItemShowList()
    local indexList = {}
    for i,v in ipairs(showList) do
        table.insert(indexList, self.m_machine.JackpotTypeToIndex[v.name])
    end
    return indexList
end
--奖励列表-展示数量
function CherryBountyTopPickGameTips:getRewardItemShowCount()
    local showList = self:getRewardItemShowList()
    local count = #showList
    return count
end
--奖励列表-展示列表
function CherryBountyTopPickGameTips:getRewardItemShowList()
    local list = {}
    for i,v in ipairs(self.m_rewardItemList) do
        if v.csb:isVisible() then
            table.insert(list, v)
        end
    end
    return list
end


return CherryBountyTopPickGameTips