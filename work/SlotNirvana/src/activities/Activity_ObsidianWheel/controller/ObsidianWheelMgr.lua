--[[
    黑曜卡轮盘抽奖
]]

require("activities.Activity_ObsidianWheel.config.ObsidianWheelCfg")
local ObsidianWheelMgr = class("ObsidianWheelMgr", BaseActivityControl)

function ObsidianWheelMgr:ctor()
    ObsidianWheelMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ObsidianWheel)
end

-- 最新路径
function ObsidianWheelMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function ObsidianWheelMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function ObsidianWheelMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

-- 动态路径 方便换皮操作
function ObsidianWheelMgr:getLuaPathHead()
    -- return "Activity." .. self:getThemeName() .. "Src."
    local themeName = self:getThemeName()
    return themeName .. ".ObsidianWheelCode."
end

-- 动态路径 方便换皮操作
function ObsidianWheelMgr:getCsbPathHead()
    -- return "Activity/" .. self:getThemeName() .. "/"
    local themeName = self:getThemeName()
    return themeName .. "/Activity/"
end

function ObsidianWheelMgr:showRewardLayer(_rewardData, _over)
    local function callFunc()
        if _over then
            _over()
        end
    end
    if not self:isCanShowLayer() then
        callFunc()
        return
    end
    if not (_rewardData and #_rewardData > 0) then
        callFunc()
        return 
    end
    
    local coinNum = 0 
    for i=1,#_rewardData do
        local itemData = _rewardData[i]
        if itemData.p_icon == "Coins" then
            coinNum = coinNum + itemData.p_num
        end
    end
    local view = gLobalItemManager:createRewardLayer(_rewardData, callFunc, coinNum, nil, nil, cc.size(210, 200))
    if not view then
        callFunc()
        return 
    end
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function ObsidianWheelMgr:showMainLayer(_data, _over)
    local function callFunc()
        if _over then
            _over()
        end
    end
    if not self:isCanShowLayer() then
        callFunc()
        return
    end
    if gLobalViewManager:getViewByName("Activity_ObsidianWheel") then
        callFunc()
        return 
    end
    local themeName = self:getThemeName()
    if not themeName then
        callFunc()
        return
    end
    local luaPath = self:getPopPath(themeName)
    local view = util_createView(luaPath, _data, _over)
    if not view then
        callFunc()
        return
    end
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function ObsidianWheelMgr:sendFreeSpinRequest(_success, _fail)
    local successFunc = function(_result)
        local data = self:getRunningData()
        if not data then
            -- 活动已经关闭了
            return
        end
        -- 服务器从0开始
        self:setFreeHitIndex(_result.index + 1)
        if _success then
            _success()
        end
    end
    local failFunc = function()
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect()
    end
    local data = self:getRunningData()
    if not data then
        return
    end
    G_GetNetModel(NetType.ObsidianWheel):sendFreeSpinRequest(successFunc, failFunc)
end

function ObsidianWheelMgr:setFreeHitIndex(_freeHitIndex)
    self.m_freeHitIndex = _freeHitIndex
end

function ObsidianWheelMgr:getFreeHitIndex()
    return self.m_freeHitIndex
end

function ObsidianWheelMgr:setProgressIncrease(_increaseValue)
    self.m_progressIncreaseValue = _increaseValue
end

function ObsidianWheelMgr:getProgressIncrease()
    return self.m_progressIncreaseValue or 0
end

function ObsidianWheelMgr:clearProgressIncrease()
    self.m_progressIncreaseValue = 0
end

function ObsidianWheelMgr:recordGridRewardData(_addItem)
    if not _addItem then
        return
    end
    if not self.m_gridRewardDatas then
        self.m_gridRewardDatas = {}
    end
    table.insert(self.m_gridRewardDatas, _addItem)
end

function ObsidianWheelMgr:getGridRewardData()
    return self.m_gridRewardDatas
end

function ObsidianWheelMgr:clearGridRewardData()
    if self.m_gridRewardDatas then
        self.m_gridRewardDatas = nil
    end
end

function ObsidianWheelMgr:recordProgressRewardData(_addItem)
    if not _addItem then
        return
    end
    if not self.m_progressRewardDatas then
        self.m_progressRewardDatas = {}
    end
    table.insert(self.m_progressRewardDatas, _addItem)
end

function ObsidianWheelMgr:getProgressRewardData()
    return self.m_progressRewardDatas
end

function ObsidianWheelMgr:clearProgressRewardData()
    if self.m_progressRewardDatas then
        self.m_progressRewardDatas = nil
    end
end

function ObsidianWheelMgr:getSkipCacheKey()
    local data = G_GetMgr(ACTIVITY_REF.ObsidianWheel):getRunningData()
    if data then
        local expireAt = data:getExpireAt()
        return "ObsidianWheelSkip_" .. expireAt .. "_" .. globalData.userRunData.uid
    end
end

-- 默认不选中，即不跳过
function ObsidianWheelMgr:isCheckBoxSelected()
    local key = self:getSkipCacheKey()
    if key ~= nil then
        local isSelected = gLobalDataManager:getBoolByField(key, false)
        return isSelected
    end
    return false
end

function ObsidianWheelMgr:setCheckBoxSelected(_isSelected)
    local key = self:getSkipCacheKey()
    if key ~= nil then
        gLobalDataManager:setBoolByField(key, _isSelected)
    end
end

-- 逻辑遮罩层
function ObsidianWheelMgr:addLogicMask()
    local logicMask = util_newMaskLayer(false)
    logicMask:setOpacity(0)
    logicMask:setName("ObsidianLogicMask")
    self:showLayer(logicMask, ViewZorder.ZORDER_UI)
end

function ObsidianWheelMgr:removeLogicMask()
    local mask = self:getLayerByName("ObsidianLogicMask")
    if not tolua.isnull(mask) then
        mask:removeFromParent()
        mask = nil
    end
end

return ObsidianWheelMgr