--[[
    -- 创建table View Cell 用来加载
]]
local DailyMissionThreeLinePassCellNode = class("DailyMissionThreeLinePassCellNode", util_require("base.BaseView"))

function DailyMissionThreeLinePassCellNode:initDatas(isPortrait)
    self.m_isPortrait = isPortrait
end

function DailyMissionThreeLinePassCellNode:initUI()
    self:createCsbNode(self:getCsbName())

    -- 读取csb 节点
    self.m_nodeSeason = self:findChild("node_Season")
    self.m_nodeFree = self:findChild("node_Free")

    self.m_nodePremium = self:findChild("node_Premium")

    self.m_nodeTag = self:findChild("node_tag")
    self.m_nodeCell = self:findChild("node_cell")
    self.m_nodeSafeBox = self:findChild("node_safebox")

    self.m_isPreview = false
end

function DailyMissionThreeLinePassCellNode:getCsbName()
    if self.m_isPortrait then
        return DAILYPASS_RES_PATH.DailyMissionPass_PassCell_ThreeLine_Vertical
    else
        return DAILYPASS_RES_PATH.DailyMissionPass_PassCell_ThreeLine
    end
end

function DailyMissionThreeLinePassCellNode:loadDataUi(_passInfo, _index, _maxIndex)
    self.m_passInfo = _passInfo
    self.m_index = _index
    self.m_maxIndex = _maxIndex
    --
    self.m_nodeTag:setVisible(false)
    self.m_nodeCell:setVisible(false)
    self:setSafeBoxVisible(false)
    --加载节点
    print("---- DailyMissionThreeLinePassCellNode创建 idx = " .. _index)
    if _index == 1 then -- 标签页
        self:updateIcon()
    elseif _index == _maxIndex then -- 宝箱页
        self:updateSafeBox(_index)
    else -- 奖励页
        self:updateReward()
    end
end

function DailyMissionThreeLinePassCellNode:updateIcon()
    self:runCsbAction("idle", true, nil, 60)
    self.m_nodeTag:setVisible(true)
end

function DailyMissionThreeLinePassCellNode:updateReward()
    if self.m_nodeCell then
        self.m_nodeCell:setVisible(true)
    end
    self:updateFree()
    self:updateSeason() 
    self:updatePremium()
end

function DailyMissionThreeLinePassCellNode:updateSeason()
    -- 加载付费节点
    if self.m_seasonView == nil then
        self.m_seasonView = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PassRewardCell_ThreeLine, {type = "season", lock = false, isPreview = self.m_isPreview, isPortrait = self.m_isPortrait })
        self.m_nodeSeason:addChild(self.m_seasonView)
    end
    self.m_seasonView:updateData(self.m_passInfo.payInfo, self.m_passInfo.increase)
end

function DailyMissionThreeLinePassCellNode:updatePremium()
    -- 加载付费节点
    if self.m_premiumView == nil then
        self.m_premiumView = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PassRewardCell_ThreeLine, {type = "premium", lock = false, isPreview = self.m_isPreview, isPortrait = self.m_isPortrait })
        self.m_nodePremium:addChild(self.m_premiumView)
    end
    self.m_premiumView:updateData(self.m_passInfo.tripleInfo, self.m_passInfo.increase)
end

function DailyMissionThreeLinePassCellNode:updateFree()
    -- 加载免费节点
    if self.m_freeView == nil then
        self.m_freeView = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PassRewardCell_ThreeLine, {type = "free", lock = false, isPreview = self.m_isPreview, isPortrait = self.m_isPortrait })
        self.m_nodeFree:addChild(self.m_freeView)
    end
    self.m_freeView:updateData(self.m_passInfo.freeInfo, self.m_passInfo.increase)
end

-- 更新大宝箱状态
function DailyMissionThreeLinePassCellNode:updateSafeBox(_index)
    self:setSafeBoxVisible(true)
    -- 加载保险箱
    if self.m_boxView == nil then
        self.m_boxView = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PassSafeBoxCell_ThreeLine,self.m_isPortrait)
        self.m_nodeSafeBox:addChild(self.m_boxView)
    end
    self.m_boxView:updateData(self.m_passInfo.safeBoxInfo, _index - 1)
end

function DailyMissionThreeLinePassCellNode:setSafeBoxVisible(_isVisible)
    self.m_nodeSafeBox:setVisible(_isVisible)
end

--------------------------- 点击事件 ----------------------------
-- 点击检测 获取付费奖励节点  --
function DailyMissionThreeLinePassCellNode:getRewardNode(type)
    if self.m_nodeCell:isVisible() == false then
        return nil
    end
    if type == 2 then
        local payNode = self.m_premiumView:getTouchNode()
        return payNode
    elseif type == 1 then
        local payNode = self.m_seasonView:getTouchNode()
        return payNode
    else
        local freeNode = self.m_freeView:getTouchNode()
        return freeNode
    end
end
-- 点击检测 获取大宝箱节点 --
function DailyMissionThreeLinePassCellNode:getBoxNode(_nodeType)
    if self.m_nodeSafeBox:isVisible() == false then
        return nil
    end

    local boxTouchNode = self.m_boxView:getTouchNode(_nodeType)
    return boxTouchNode
end

-- 点击检测 事件触发 --
function DailyMissionThreeLinePassCellNode:onRewardNodeClick(type)
    if type == 2 then
        self.m_premiumView:onClick()
    elseif type == 1 then
        self.m_seasonView:onClick()
    else
        self.m_freeView:onClick()
    end
end

--按钮点击事件
function DailyMissionThreeLinePassCellNode:onBoxNodeClick(_nodeType)
    self.m_boxView:onClick(_nodeType)
end

-- 收集之后更新
function DailyMissionThreeLinePassCellNode:collectUpdate(_params)
    if _params and _params.type == 0 then
        if self.m_freeView then
            self.m_freeView:collectUpdate(_params)
        end
    end
    if _params and _params.type == 1 then
        if self.m_seasonView then
            self.m_seasonView:collectUpdate(_params)
        end
    end

    if _params and _params.type == 4 then
        if self.m_premiumView then
            self.m_premiumView:collectUpdate(_params)
        end
    end
    -- if self.m_boxView then
    --     self.m_boxView:collectUpdate(_params)
    -- end
end

function DailyMissionThreeLinePassCellNode:beforeClose()
    if self.m_freeView then
        self.m_freeView:beforeClose()
    end
    if self.m_seasonView then
        self.m_seasonView:beforeClose()
    end
    if self.m_premiumView then
        self.m_premiumView:beforeClose()
    end
end

function DailyMissionThreeLinePassCellNode:collectAllUpdate()
    if self.m_freeView then
        self.m_freeView:collectAllUpdate()
    end
    if self.m_seasonView then
        self.m_seasonView:collectAllUpdate()
    end
    if self.m_premiumView then
        self.m_premiumView:collectAllUpdate()
    end
    -- 一键领取不包含保险箱
end

function DailyMissionThreeLinePassCellNode:buyPassUpdate(_type)
    if _type == "pay" then
        -- 只有付费的需要播放动画
        if G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():isUnlocked() then
            if self.m_seasonView then
                self.m_seasonView:showUnlockAction()
            end
        end
        if G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():getCurrIsPayHigh() then
            if self.m_premiumView then
                self.m_premiumView:showUnlockAction()
            end
        end
    elseif _type == "safeBox" then
        if self.m_boxView then
            self.m_boxView:showUnlockAction()
        end
    end
end

function DailyMissionThreeLinePassCellNode:updateSafeBoxStatus(_max)
    if self.m_boxView then
        self.m_boxView:updateBoxStatus(_max)
    end
end

function DailyMissionThreeLinePassCellNode:getCellByLevel(_boxType, _level)
    local node = nil
    if _boxType == "free" then
        if self.m_freeView and self.m_freeView:isCellByLevel(_level) then
            node = self.m_freeView
        end
    elseif _boxType == "season" then
        if self.m_seasonView and self.m_seasonView:isCellByLevel(_level) then
            node = self.m_seasonView
        end
    elseif _boxType == "premium" then
        if self.m_premiumView and self.m_premiumView:isCellByLevel(_level) then
            node = self.m_premiumView
        end
    elseif _boxType == "safeBox" then
        if self.m_boxView and self.m_boxView:isCellByLevel(_level) then
            node = self.m_boxView
        end
    end
    return node
end

function DailyMissionThreeLinePassCellNode:updateClaimStatus()
    if self.m_freeView then
        self.m_freeView:updateClaimStatus()
    end
    if self.m_seasonView then
        self.m_seasonView:updateClaimStatus()
    end
end

return DailyMissionThreeLinePassCellNode
