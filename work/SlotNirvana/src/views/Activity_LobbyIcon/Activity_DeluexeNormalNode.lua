-- Created by jfwang on 2019-05-05.

--高倍场不属于活动展示的入口也不同不要命名为LobbyNode
local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local Activity_DeluexeNormalNode = class("Activity_DeluexeNormalNode", BaseLobbyNodeUI)
Activity_DeluexeNormalNode.m_isShowTip = nil
function Activity_DeluexeNormalNode:initUI(data)
    local csbName = "Activity_LobbyIconRes/deluexelobby/DeluexeClubNode.csb"
    self:createCsbNode(csbName)

    self.m_progress = self:findChild("LoadingBar_1")
    self.m_labPont = self:findChild("ponit")
    self.m_progress_bg_1 = self:findChild("map_btn_progress_bg_1")
    self.btnFunc = self:findChild("Button_1")
    if self.btnFunc then
        self.btnFunc:setSwallowTouches(false)
    end

    self.nodeProgress = self:findChild("Node_progress")
    if globalDynamicDLControl:checkDownloading(self:getDownLoadKey()) then
        -- 下载中的时候不能显示进度条
        self.nodeProgress:setVisible(false)
    end

    self.m_nodeDLTips = self:findChild("tipsNode_downloading") -- 下载中提示
    self.m_nodeDLTips:setVisible(false)

    self:updateView()
    self:updateRedPointNum()
end

function Activity_DeluexeNormalNode:onEnter()
    BaseLobbyNodeUI.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateView()
            self:endProcessFunc()
        end,
        ViewEventType.NOTIFY_DELUEXECLUB_POINT_UPDATE
    )

    -- 商城购买猫粮 掉落猫粮
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.name == ACTIVITY_REF.DeluxeClubCatActivity or params.name == ACTIVITY_REF.DeluxeClubMergeActivity then
                -- 猫粮数量更新
                self:updateRedPointNum()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH
    )

    -- 养猫活动结束
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.DeluxeClubCat or params.name == ACTIVITY_REF.DeluxeClubMergeActivity then
                self:updateRedPointNum()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    if self.downLoadLockBg ~= nil and self.downLoadProcess ~= nil then
        self:changeAnim("animation0")
    else
        self:changeAnim(globalData.deluexeClubData:getDeluexeClubStatus() and "idle" or "animation0")
    end
end

function Activity_DeluexeNormalNode:changeAnim(animName)
    if self.curAnimName ~= animName then
        self.curAnimName = animName
        self:runCsbAction(animName, true)
    end
end

function Activity_DeluexeNormalNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function Activity_DeluexeNormalNode:updateView()
    local crownNum = globalData.deluexeClubData:getDeluexeClubCrownNum()
    if not globalData.deluexeClubData.p_currPoint then
        globalData.deluexeClubData.p_currPoint = 0
    end
    local progress = globalData.deluexeClubData.p_currPoint * 100 / globalData.constantData.CLUB_OPEN_POINTS
    if crownNum >= 2 then
        progress = 100
    end
    self.m_progress:setPercent(progress)
    local points = util_formatCoins(globalData.deluexeClubData.p_currPoint, 6)
    self.m_labPont:setString(points)
end

-- 小红点 cxc 2020年12月23日14:23:28 (目前就是猫粮的数量)
function Activity_DeluexeNormalNode:updateRedPointNum()
    -- local pointNum = 0
    local node = self:findChild("sp_redDot")

    -- 猫粮数量
    -- local actData = nil
    -- local count = 0

    -- if globalDeluxeManager.getDeluxeGameInfo then
    --     local gameInfo = globalDeluxeManager:getDeluxeGameInfo()
    --     actData = G_GetActivityDataByRef(gameInfo.actRef)
    --     if actData and gameInfo.actRef == ACTIVITY_REF.DeluxeClubCatActivity then
    --         count = actData:getTotalFoodCount()
    --     elseif actData and gameInfo.actRef == ACTIVITY_REF.DeluxeClubMergeActivity then
    --         count = actData:getActRedDotCount()
    --     end

    --     pointNum = pointNum + count
    -- end
    local pointNum = globalDeluxeManager:getLobbyBottomNum()

    if pointNum <= 0 then
        node:setVisible(false)
        return
    end

    node:setVisible(true)
    local lbCount = self:findChild("lb_redNum")
    lbCount:setString(pointNum)
    util_scaleCoinLabGameLayerFromBgWidth(lbCount, 26)
end

--
function Activity_DeluexeNormalNode:clickFunc(sender)
    if globalDynamicDLControl:checkDownloading(self:getDownLoadKey()) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_nodeDLTips)
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSendDataManager:getNetWorkDeluxe():sendDeluxeClubLog()

    globalDeluxeManager:showDeluexeClubView()
    self:openLayerSuccess()
end

function Activity_DeluexeNormalNode:endProcessFunc()
    self.nodeProgress:setVisible(true)
    self:changeAnim(globalData.deluexeClubData:getDeluexeClubStatus() and "idle" or "animation0")
end

-- function Activity_DeluexeNormalNode:getDownLoadingNode()
--     return self
-- end

function Activity_DeluexeNormalNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_DeluexeNormalNode:getBottomName()
    return "CLUB"
end

function Activity_DeluexeNormalNode:getDownLoadKey()
    return "Activity_DeluexeClub"
end

function Activity_DeluexeNormalNode:getProgressPath()
    return "Activity_LobbyIconRes/deluexelobby/ui/deluxe_di.png"
end

function Activity_DeluexeNormalNode:getProcessBgOffset()
    return 0.2, 0.9
end
return Activity_DeluexeNormalNode
