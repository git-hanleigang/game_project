--[[--
    黑曜卡历史赛季滑动入口
]]
local SHOW_STATUS = {
    DL_UNLOAD = 1, -- 未下载
    DL_LOADING = 2, -- 正在下载
    DL_FAIL = 3, --下载失败
    DL_SUCCESS = 4 -- 下载完成
}

local BaseView = util_require("base.BaseView")
local CardCollectionObsidianScrollCell = class("CardCollectionObsidianScrollCell", BaseView)

function CardCollectionObsidianScrollCell:getCsbName()
    return "CardRes/CardObsidianCollection/Collection_album_cell.csb"
end

function CardCollectionObsidianScrollCell:initDatas(_data)
    self.m_data = _data
    self.m_seasonId = _data:getSeason()
    self.m_currentCardNums = _data:getCurrent()
    self.m_totalCardNums = _data:getTotal()
end

function CardCollectionObsidianScrollCell:initCsbNodes()
    self.m_spSeason = self:findChild("sp_seasonIcon")

    -- 下载相关节点
    self.m_dlNode = self:findChild("Node_download")
    self.m_dlPro = self:findChild("Node_DL_pro")
    self.m_proBar = self:findChild("LoadingBar_1")
    self.m_proBarText = self:findChild("BitmapFontLabel_1")

    self.m_spLogo = self:findChild("sp_logo")
    self.m_progress = self:findChild("jindu")
    self.m_lbProgress = self:findChild("lb_jindu")

    self.m_touch = self:findChild("touch")
    self.m_touch:setSwallowTouches(false)
    self:addClick(self.m_touch)
end

-- 状态控制
function CardCollectionObsidianScrollCell:setStatus(status)
    self.m_curStatus = status
end

-- 初始化
function CardCollectionObsidianScrollCell:initUI()
    CardCollectionObsidianScrollCell.super.initUI(self)
    self:initView()
end

function CardCollectionObsidianScrollCell:initView()
    self:initDownload()
    self:initClanIcon()
    self:initClanPro()
end

function CardCollectionObsidianScrollCell:initDownload()
    local curStatus = self:getInitStatus()
    self:setStatus(curStatus)
    self:updateUIByStatus()
end

function CardCollectionObsidianScrollCell:updateUIByStatus(percent)
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

function CardCollectionObsidianScrollCell:updateProUI(percent)
    if not CC_DYNAMIC_DOWNLOAD then
        return
    end
    percent = percent or globalCardsManualDLControl:getPercentForKey(self:getDownLoadKey()) -- todo
    if self.m_proBarText then
        self.m_proBarText:setString(math.ceil(percent * 100) .. "%")
    end
    if self.m_proBar then
        self.m_proBar:setPercent(math.ceil(percent * 100))
    end
end

function CardCollectionObsidianScrollCell:initClanIcon()
    local iconPath = string.format("CardRes/CardObsidianCollection/Other/Collection_entry_icon_%s.png", tostring(self.m_seasonId))
    util_changeTexture(self.m_spLogo, iconPath)
end

function CardCollectionObsidianScrollCell:initClanPro()
    local percent = math.floor(self.m_currentCardNums / self.m_totalCardNums * 100)
    self.m_lbProgress:setString(self.m_currentCardNums .. "/" .. self.m_totalCardNums)
    self.m_progress:setPercent(percent)
end

function CardCollectionObsidianScrollCell:clickFunc(sender)
    local name = sender:getName()
    -- 请求进入以往集卡
    if name == "touch" then
        if self.m_canTouch then
            return
        end
        self.m_canTouch = true
        print("--------------- touch 111")
        local DL_KEY = self:getDownLoadKey()
        if CC_DYNAMIC_DOWNLOAD then
            local cur = self:getInitStatus()
            print("--------------- touch status = ", cur)
            if cur == SHOW_STATUS.DL_UNLOAD then
                -- -- 开始下载icon
                -- local albumId = self.m_data:getAlbumId()
                -- globalCardsDLControl:startDownload("2091", string.sub(albumId, 5, 6))
                -- 开始下载基础UI资源
                globalCardsManualDLControl:startDownload(1, {DL_KEY})
                
                -- 点击后立马显示进度条
                self:setStatus(SHOW_STATUS.DL_LOADING)
                self:updateUIByStatus()
            elseif cur == SHOW_STATUS.DL_SUCCESS then
                self:enterAlbum()
            end
        else
            -- 进入旧赛季
            self:enterAlbum()
        end
    end
end

function CardCollectionObsidianScrollCell:enterAlbum()
    local successFunc = function()
        gLobalViewManager:removeLoadingAnima()
        self.m_canTouch = false
        G_GetMgr(G_REF.ObsidianCard):showMainLayer(self.m_seasonId)
    end

    local faildFunc = function()
        self.m_canTouch = false
        gLobalViewManager:removeLoadingAnima()
    end

    local yearID = self.m_data.year
    local albumId = self.m_data:getAlbumId()
    local tExtraInfo = {year = yearID, albumId = albumId}
    gLobalViewManager:addLoadingAnimaDelay()
    CardSysNetWorkMgr:sendObsidianCardsAlbumRequest(tExtraInfo, successFunc, faildFunc)
end

function CardCollectionObsidianScrollCell:onEnter()
    CardCollectionObsidianScrollCell.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, percent)
            print(" ------------- DL_Percent" .. tostring(self:getDownLoadKey()) .. "__" .. percent)
            local curStatus = SHOW_STATUS.DL_UNLOAD
            if percent >= 0 and percent < 1 then
                curStatus = SHOW_STATUS.DL_LOADING
            elseif percent == -1 then
                curStatus = SHOW_STATUS.DL_FAIL
                print(" ------------- DL_FAIL ")
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
            print("--------------- DL_Complete" .. tostring(self:getDownLoadKey()))
            self.m_canTouch = false
            local curStatus = SHOW_STATUS.DL_SUCCESS
            self:setStatus(curStatus)
            self:updateUIByStatus(percent)
        end,
        "DL_Complete" .. tostring(self:getDownLoadKey())
    )
end

function CardCollectionObsidianScrollCell:getContentSize()
    return cc.size(350, 386)
end

function CardCollectionObsidianScrollCell:getInitStatus()
    local DL_KEY = self:getDownLoadKey()
    print("CardCollectionObsidianScrollCell ---- getInitStatus ---- DL_KEY 000 ---", DL_KEY)
    if globalDynamicDLControl:checkDownloading(DL_KEY) then
        -- 没下载或者没下载好
        if globalCardsManualDLControl:getPercentForKey(DL_KEY) == 0 then
            -- 未开启下载
            print("CardCollectionObsidianScrollCell ---- getInitStatus ---- DL_KEY --- DL_UNLOAD")
            return SHOW_STATUS.DL_UNLOAD
        else
            -- 正在下载
            print("CardCollectionObsidianScrollCell ---- getInitStatus ---- DL_KEY --- DL_LOADING")
            return SHOW_STATUS.DL_LOADING
        end
    else
        print("CardCollectionObsidianScrollCell ---- getInitStatus ---- DL_KEY --- DL_SUCCESS")
        return SHOW_STATUS.DL_SUCCESS
    end
end

function CardCollectionObsidianScrollCell:getDownLoadKey()
    return ObsidianCardCfg.CardObsidianDynamicKey[tostring(self.m_seasonId)]
end

return CardCollectionObsidianScrollCell
