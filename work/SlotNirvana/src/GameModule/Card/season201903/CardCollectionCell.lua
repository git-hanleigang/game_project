--[[--
    以往赛季的下载节点
    已下载和下载失败，都不能点击下载按钮
]]
local BaseView = util_require("base.BaseView")
local CardCollectionCell = class("CardCollectionCell", BaseView)

local SHOW_STATUS = {
    DL_UNLOAD = 1, -- 未下载
    DL_LOADING = 2, -- 正在下载
    DL_FAIL = 3, --下载失败
    DL_SUCCESS = 4 -- 下载完成
}

function CardCollectionCell:getCsbName()
    -- 下一个赛季，CardCollectionCellRes要移动到commonRes中
    return string.format(CardResConfig.seasonRes.CardCollectionCellRes, "season" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardCollectionCell:initDatas()
    self.m_collectionIconPath = CardResConfig.otherRes.CardCollectionCoverMini
end

-- 状态控制
function CardCollectionCell:setStatus(status)
    self.m_curStatus = status
end

function CardCollectionCell:updateUIByStatus(percent)
    if self.m_curStatus == SHOW_STATUS.DL_UNLOAD then
        self.m_dlNode:setVisible(true)
        self.m_dlPro:setVisible(false)
    elseif self.m_curStatus == SHOW_STATUS.DL_LOADING then
        self.m_dlNode:setVisible(false)
        self.m_dlPro:setVisible(true)
        self:updateProUI(percent)
    elseif self.m_curStatus == SHOW_STATUS.DL_FAIL then
        -- 不用刷新进度，因为进度的值已经变成-1了
        -- self:updateProUI(-1)
        self.m_dlNode:setVisible(false)
        self.m_dlPro:setVisible(true)
    elseif self.m_curStatus == SHOW_STATUS.DL_SUCCESS then
        self.m_dlNode:setVisible(false)
        self.m_dlPro:setVisible(false)
    end
end

-- 初始化
function CardCollectionCell:initUI()
    self:createCsbNode(self:getCsbName())
    self:initNode()
end

function CardCollectionCell:initNode()
    -- self.m_spSeason01 = self:findChild("sp_seasonIcon_1")
    -- self.m_spSeason02 = self:findChild("sp_seasonIcon_2")
    self.m_spSeason = self:findChild("sp_seasonIcon")

    self.m_dlNode = self:findChild("Node_download")
    self.m_dlPro = self:findChild("Node_DL_pro")
    self.m_proBar = self:findChild("LoadingBar_1")
    self.m_proBarText = self:findChild("BitmapFontLabel_1")

    self.m_touch = self:findChild("touch")
end

function CardCollectionCell:initView(seasonId)
    self.m_seasonId = tonumber(seasonId)

    self.m_touch:setSwallowTouches(false)
    self:addClick(self.m_touch)

    self:initIcon(seasonId)

    local curStatus = self:getInitStatus()
    self:setStatus(curStatus)
    self:updateUIByStatus()
end

function CardCollectionCell:initIcon(seasonId)
    local texturePath = string.format(self.m_collectionIconPath, seasonId)
    if texturePath and texturePath ~= "" then
        util_changeTexture(self.m_spSeason, texturePath)
    end
end

function CardCollectionCell:getInitStatus()
    local DL_KEY = self:getDownLoadKey()
    print("CardCollectionCell ---- getInitStatus ---- DL_KEY 000 ---", DL_KEY)
    if globalDynamicDLControl:checkDownloading(DL_KEY) then
        -- 没下载或者没下载好
        if globalCardsManualDLControl:getPercentForKey(DL_KEY) == 0 then
            -- 未开启下载
            print("CardCollectionCell ---- getInitStatus ---- DL_KEY --- DL_UNLOAD")
            return SHOW_STATUS.DL_UNLOAD
        else
            -- 正在下载
            print("CardCollectionCell ---- getInitStatus ---- DL_KEY --- DL_LOADING")
            return SHOW_STATUS.DL_LOADING
        end
    else
        print("CardCollectionCell ---- getInitStatus ---- DL_KEY --- DL_SUCCESS")
        return SHOW_STATUS.DL_SUCCESS
    end
end

function CardCollectionCell:updateProUI(percent)
    if not CC_DYNAMIC_DOWNLOAD then
        return
    end
    percent = percent or globalCardsManualDLControl:getPercentForKey(self:getDownLoadKey())
    if self.m_proBarText then
        self.m_proBarText:setString(math.ceil(percent * 100) .. "%")
    end
    if self.m_proBar then
        self.m_proBar:setPercent(math.ceil(percent * 100))
    end
end

function CardCollectionCell:getDownLoadKey()
    -- if self.m_seasonId == 201901 then
    --     return CardResConfig.DynamicKeys_CardsRes201901
    -- elseif self.m_seasonId == 201902 then
    --     return CardResConfig.DynamicKeys_CardsRes201902
    -- end
    return CardResConfig.CardResDynamicKey[tostring(self.m_seasonId)]
end

function CardCollectionCell:clickFunc(sender)
    local name = sender:getName()
    -- 请求进入以往集卡
    if name == "touch" then
        if self.m_canTouch then
            return
        end
        self.m_canTouch = true

        -- release_print("--------------- touch 111")

        local DL_KEY = self:getDownLoadKey()
        if CC_DYNAMIC_DOWNLOAD then
            local cur = self:getInitStatus()
            -- release_print("--------------- touch status = ", cur)
            if cur == SHOW_STATUS.DL_UNLOAD then
                -- -- 开始下载icon
                -- globalCardsDLControl:startDownload(string.sub(tostring(self.m_seasonId), 1, 4), string.sub(tostring(self.m_seasonId), 5, 6))
                -- 开始下载
                globalCardsManualDLControl:startDownload(1, {DL_KEY})
                -- 点击后立马显示进度条
                gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_COLLECTION_CLICK_SYNC, {key = DL_KEY})
            elseif cur == SHOW_STATUS.DL_SUCCESS then
                self.m_canTouch = false
                self:enterAlbum(tostring(self.m_seasonId))
            end
        else
            -- 进入旧赛季
            self.m_canTouch = false
            self:enterAlbum(tostring(self.m_seasonId))
        end
    end
end

function CardCollectionCell:enterAlbum(albumId)
    -- 改为发消息进入，方便处理，连续点击的问题
    if self.m_checkEnterDownloading ~= nil then
        self.m_checkEnterDownloading = nil
    end
    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_COLLECTION_ENTER_ALBUM, {albumId = albumId})
end

function CardCollectionCell:onEnter()
    CardCollectionCell.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, percent)
            -- release_print(" ------------- DL_Percent" .. tostring(self:getDownLoadKey()).."__"..percent)
            local curStatus = SHOW_STATUS.DL_UNLOAD
            if percent >= 0 and percent < 1 then
                curStatus = SHOW_STATUS.DL_LOADING
            elseif percent == -1 then
                curStatus = SHOW_STATUS.DL_FAIL

                -- release_print(" ------------- DL_FAIL ")
                -- 如果下载失败，要重置可点击状态
                self.m_canTouch = false
            end
            self:setStatus(curStatus)
            self:updateUIByStatus(percent)
        end,
        "DL_Percent" .. tostring(self:getDownLoadKey())
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, percent)
            -- 如果下载成功了，要重置可点击状态
            release_print("--------------- DL_Complete" .. tostring(self:getDownLoadKey()))
            self.m_canTouch = false
            local curStatus = SHOW_STATUS.DL_SUCCESS
            self:setStatus(curStatus)
            self:updateUIByStatus(percent)
        end,
        "DL_Complete" .. tostring(self:getDownLoadKey())
    )

    -- 同步一下
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if self:getDownLoadKey() == params.key then
                self:setStatus(SHOW_STATUS.DL_LOADING)
                self:updateUIByStatus()
            end
        end,
        CardSysConfigs.ViewEventType.CARD_COLLECTION_CLICK_SYNC
    )
end

-- function CardCollectionCell:onExit()
--     gLobalNoticManager:removeAllObservers(self)
-- end

function CardCollectionCell:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        if not self.clickStartFunc then
            return
        end
        self:clickStartFunc(sender)
    elseif eventType == ccui.TouchEventType.moved then
        if not self.clickMoveFunc then
            return
        end
        self:clickMoveFunc(sender)
    elseif eventType == ccui.TouchEventType.ended then
        if not self.clickEndFunc then
            return
        end
        self:clickEndFunc(sender)
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()
        local offy = math.abs(endPos.y - beginPos.y)
        if offy < 50 and globalData.slotRunData.changeFlag == nil then
            self:clickFunc(sender)
        end
    elseif eventType == ccui.TouchEventType.canceled then
        -- print("Touch Cancelled")
        if not self.clickEndFunc then
            return
        end
        self:clickEndFunc(sender, eventType)
    end
end

return CardCollectionCell
