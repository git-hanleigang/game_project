--[[
    大赢宝箱
]]

local MegaWinRewardBubbleMgr = require("activities.Activity_MegaWinParty.controller.MegaWinRewardBubbleMgr")
local MegaWinPartyNet = require("activities.Activity_MegaWinParty.net.MegaWinPartyNet")
local MegaWinPartyMgr = class("MegaWinPartyMgr", BaseActivityControl)

function MegaWinPartyMgr:ctor()
    MegaWinPartyMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.MegaWinParty)
    self.m_net = MegaWinPartyNet:getInstance()

    self.m_rewardBubbleMgr = MegaWinRewardBubbleMgr:getInstance()
end

function MegaWinPartyMgr:showSlotRewardBubble(_rewardDatas)
    self.m_rewardBubbleMgr:showDropBubble(_rewardDatas)
end

function MegaWinPartyMgr:clearRewardBubbleDate()
    self.m_rewardBubbleMgr:clearDate()
end

function MegaWinPartyMgr:showMainLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end
    local theme = self:getThemeName()
    local view = util_createView(theme..".Activity."..theme, _data)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function MegaWinPartyMgr:showInfoLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("MegaWinPartyRuleInfoLayer") == nil then
        local view = util_createView("Activity.MegaWinPartyRuleInfoLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
        return view
    end
    return nil
end

--- desc: 显示展示放弃宝箱界面
function MegaWinPartyMgr:showGaveUpLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end
    self.m_isInGaveUpLayer = true

    if gLobalViewManager:getViewByExtendData("MegaWinPartyGaveUpLayer") == nil then
        local view = util_createView("Activity.MegaWinPartyGaveUpLayer",_data)
        self:showLayer(view, ViewZorder.ZORDER_UI)
        view:setOverFunc(
            function()
                self.m_isInGaveUpLayer = false
            end
        )
    end
end


function MegaWinPartyMgr:isInGaveUpLayer()
    return not not self.m_isInGaveUpLayer
end

function MegaWinPartyMgr:createGameBottomNode()
    local node = util_createView("Activity.MegaWinPartyChestListNode")
    self.m_gameBottomNode = node
    return node
end

function MegaWinPartyMgr:getGameBottomNode()
    return self.m_gameBottomNode
end

function MegaWinPartyMgr:moveGameBottomNodeToTop()
    self.data = {}
    self.data.zorder = self.m_gameBottomNode:getZOrder()
    self.data.parent = self.m_gameBottomNode:getParent()
    self.data.pos = cc.p(self.m_gameBottomNode:getPosition())

    self.m_gameBottomNode:forceIdle()

    local newZorder = ViewZorder.ZORDER_UI 
    util_changeNodeParent(gLobalViewManager:getViewLayer(), self.m_gameBottomNode, newZorder)
    self.m_gameBottomNode:setPosition(cc.p(display.cx, 106))
    -- 横竖版都需要适配
    -- local currLayerScale = self.m_csbNode:getChildByName("root"):getScale()
    -- node:setScale(currLayerScale)
end

function MegaWinPartyMgr:resetGameBottomNodeZOrder()
    util_changeNodeParent(self.data.parent, self.m_gameBottomNode, self.data.zorder)
    self.m_gameBottomNode:setScale(1)
    self.m_gameBottomNode:setPosition(self.data.pos)
    self.data.parent = nil
    self.data.zorder = 1
    self.data.pos = nil
end

function MegaWinPartyMgr:showCollectLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end
    local theme = self:getThemeName()
    if gLobalViewManager:getViewByExtendData(theme.."Collect") == nil then
        local view = util_createView(theme..".Activity."..theme.."Collect", _data)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function MegaWinPartyMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function MegaWinPartyMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function MegaWinPartyMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function MegaWinPartyMgr:MegaWinPartySpin()
    self.m_net:MegaWinPartySpin()
end


-- 切换bet是否显示气泡
function MegaWinPartyMgr:checkBetIsShow()
    -- 判断是否有资源和数据
    if not self:isCanShowLayer() then
        return false
    end
    return true
end

function MegaWinPartyMgr:requestOpenBox()
    if not self.m_isRequestOpenBoxFailCount then
        self.m_isRequestOpenBoxFailCount = 0
    end
    if self.m_isRequestOpenBox or self.m_isRequestOpenBoxFailCount > 5 then
        return
    end
    self.m_isRequestOpenBox = true
    self.m_net:requestOpenBox(function ()
        self.m_isRequestOpenBoxFailCount = 0
        self.m_isRequestOpenBox = false
    end,function ()
        self.m_isRequestOpenBox = false
        self.m_isRequestOpenBoxFailCount = self.m_isRequestOpenBoxFailCount + 1
    end)
end

function  MegaWinPartyMgr:clearRequestOpenBoxFailCount()
    self.m_isRequestOpenBoxFailCount = 0
end
--[[ 
    type：0 | 1 (0-丢弃宝箱，1-花费钻石开宝箱)    position：0 | 1~4  (0-额外宝箱，1~4 - 已有宝箱位置) dtp 1 主动丢弃
]]
function MegaWinPartyMgr:requestDropOrGemOpenBox(type,pos,dtp)
    if self.m_isRequestDrop then
        return
    end
    if not dtp then
        dtp = 0
    end
    self.m_isRequestDrop = true
    self.m_net:requestDropOrGemOpenBox(type,pos,dtp,function ()
        self.m_isRequestDrop = false
    end)
end

-- 是否在请求数据
function  MegaWinPartyMgr:isRequestDrop()
    return self.m_isRequestDrop
end

function MegaWinPartyMgr:parseSpinData(_data)
    local gameData = self:getRunningData()
    if gameData then
        gameData:parseSpinData(_data)
    end
end

function MegaWinPartyMgr:getBetBubblePath(_refName)
    return "Activity/MegaWinPartyBetNode"
end


-- 关卡内首次参与 或者 二次确认 弹板
function MegaWinPartyMgr:checkShowFirstOpenInfoLayer()
    if self:isCanShowLayer() then
        if self:isFirstEnterGame() then
            return self:showInfoLayer()
        end
    end
    return nil
end

function MegaWinPartyMgr:isFirstEnterGame()
    local isFrist = gLobalDataManager:getBoolByField("MegaWinPartyMgr_isFirstEnterGame", true)
    if isFrist then
        gLobalDataManager:setBoolByField("MegaWinPartyMgr_isFirstEnterGame", false)
    end
    return isFrist
end


function MegaWinPartyMgr:showOverView()
    if not self:isDownloadRes() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("MegaWinPartyGameOverLayer") == nil then
        local view = util_createView("Activity.MegaWinPartyGameOverLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
        return view
    end
end

return MegaWinPartyMgr
