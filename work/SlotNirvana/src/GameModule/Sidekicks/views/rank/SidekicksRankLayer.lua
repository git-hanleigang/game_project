--[[
    荣誉
]]

local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")
local SidekicksRankLayer = class("SidekicksRankLayer", BaseLayer)

function SidekicksRankLayer:initDatas(_seasonIdx)
    self.m_seasonIdx = _seasonIdx
    self.m_gameData = G_GetMgr(G_REF.Sidekicks):getRunningData()
    self.m_curLevel = self.m_gameData:getHonorLv()
    self.m_buffNodes = {}
    self.m_pagePoint = {}

    self:setLandscapeCsbName(string.format("Sidekicks_%s/csd/rank/Sidekicks_RankLayer.csb", _seasonIdx))
    self:setExtendData("SidekicksRankLayer")
end

function SidekicksRankLayer:initCsbNodes()
    self.m_sp_rank_icon = self:findChild("sp_rank_icon")
    self.m_sp_rank_name = self:findChild("sp_rank_name")
    self.m_node_bar = self:findChild("node_bar")
    self.m_node_sale = self:findChild("node_sale")
    self.m_node_page = self:findChild("node_page_1")
    self.m_sp_page_other = self:findChild("sp_page_other")
    self.m_sp_page_now = self:findChild("sp_page_now")
    self.m_sp_left = self:findChild("sp_left")
    self.m_sp_right = self:findChild("sp_right")
    self.m_btn_left = self:findChild("btn_left")
    self.m_btn_right = self:findChild("btn_right")
    self.m_node_Ranklayer = self:findChild("node_Ranklayer")
end

function SidekicksRankLayer:initView()
    self:initBuff()
    self:initProgress()
    self:initSale()
    self:initPage()
    self:updateUI(self.m_curLevel)
end

function SidekicksRankLayer:initBuff()
    for i = 1, 4 do
        local node = self:findChild("node_buff_" .. i)
        if node then
            local buff = util_createView("GameModule.Sidekicks.views.rank.SidekicksRankBuff", self.m_seasonIdx, i, self)
            node:addChild(buff)
            table.insert(self.m_buffNodes, buff)
        end
    end
end

function SidekicksRankLayer:initProgress()
    self.m_progress = util_createView("GameModule.Sidekicks.views.rank.SidekicksRankProgress", self.m_seasonIdx, self)
    self.m_node_bar:addChild(self.m_progress)
end

function SidekicksRankLayer:initSale()
    self.m_sale = util_createView("GameModule.Sidekicks.views.rank.SidekicksRankSale", self.m_seasonIdx, self)
    self.m_node_sale:addChild(self.m_sale)
end

function SidekicksRankLayer:initPage()
    table.insert(self.m_pagePoint, {node = self.m_sp_page_other, alignX = 10})
    local stdCfg = self.m_gameData:getStdCfg()
    local honorCfg = stdCfg:getHonorCfg()
    self.m_totalLevel = #honorCfg
    for i = 1, self.m_totalLevel - 1 do
        local pagePoint = cc.Sprite:createWithTexture(self.m_sp_page_other:getTexture())
        self.m_node_page:addChild(pagePoint, -10)
        table.insert(self.m_pagePoint, {node = pagePoint, alignX = 10})
    end
    
    self:alignCenter(self.m_pagePoint)
end

function SidekicksRankLayer:alignCenter(uiList)
    local totalWidth = 0
    local posX, posY = 0, 0
    local nodeSize = self.m_sp_page_other:getContentSize()
    local nodeAnchor = self.m_sp_page_other:getAnchorPoint()

    for k, v in ipairs(uiList) do
        local alignX = v.alignX
        totalWidth = totalWidth + alignX + nodeSize.width
    end

    posX = -totalWidth / 2

    for k, v in ipairs(uiList) do
        local alignX = v.alignX
        local node = v.node
        posX = posX + alignX + nodeAnchor.x * nodeSize.width
        if k > 1 then
            local preInfo = uiList[k - 1]
            posX = posX + (1 - nodeAnchor.x) * nodeSize.width
        end

        node:setPosition(posX, posY)
    end
end

function SidekicksRankLayer:updateUI(_index)
    if self.m_gameData then
        self:changeIcon(_index)
        self:updateBuffNum(_index)
        self:updateProgress(_index)
        self:updateSale(_index)
        self:updatePagePoint(_index)
    end
end

function SidekicksRankLayer:updateBuffNum(_index)
    local stdCfg = self.m_gameData:getStdCfg()
    local honorCfgData = stdCfg:getHonorCfgData(_index)
    for i,v in ipairs(self.m_buffNodes) do
        v:updateNum(honorCfgData:getCoe(), _index)
    end
end

function SidekicksRankLayer:changeIcon(_index)
    local iconPath = "Sidekicks_Common/rank_icon/rank_icon_" .. _index .. ".png"
    local namePath = "Sidekicks_Common/rank_name/rank_name_" .. _index .. ".png"
    util_changeTexture(self.m_sp_rank_icon, iconPath)
    util_changeTexture(self.m_sp_rank_name, namePath)
end

function SidekicksRankLayer:updateProgress(_index)
    local stdCfg = self.m_gameData:getStdCfg()
    local honorCfgData = stdCfg:getHonorCfgData(_index)
    local needExp = honorCfgData:getNextLvExp()
    local curExp = self.m_gameData:getHonorExp()
    local curLevel = self.m_gameData:getHonorLv()
    self.m_progress:updateUI(curExp, needExp, curLevel, _index)
end

function SidekicksRankLayer:updateSale(_index)
    local curLevel = self.m_gameData:getHonorLv()
    local saleData = self.m_gameData:getHonorLvSaleInfoByLv(_index)
    self.m_sale:updateUI(saleData, curLevel, _index)
end

function SidekicksRankLayer:updatePagePoint(_index)
    local pageInfo = self.m_pagePoint[_index]
    local node = pageInfo.node
    local x, y = node:getPosition()
    self.m_sp_page_now:setPosition(x, y)

    self.m_sp_left:setVisible(self.m_curLevel > 1)
    self.m_sp_right:setVisible(self.m_curLevel < self.m_totalLevel)
    self.m_btn_left:setTouchEnabled(self.m_curLevel > 1)
    self.m_btn_right:setTouchEnabled(self.m_curLevel < self.m_totalLevel)
end

function SidekicksRankLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function SidekicksRankLayer:getTouch()
    return self.m_isTouch
end

function SidekicksRankLayer:setTouch(_flag)
    self.m_isTouch = _flag
end

function SidekicksRankLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_info" then
    elseif name == "btn_left" then
        if self:getTouch() then
            return
        end

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:changePage(-1)
    elseif name == "btn_right" then
        if self:getTouch() then
            return
        end

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:changePage(1)
    end
end

function SidekicksRankLayer:changePage(_num)
    self.m_curLevel = self.m_curLevel + _num
    if self.m_curLevel < 1 then
        self.m_curLevel = 1
    end

    if self.m_curLevel > self.m_totalLevel then
        self.m_curLevel = self.m_totalLevel
    end

    self:updateUI(self.m_curLevel)
    self:hideBubble()
end

function SidekicksRankLayer:toCurPage()
    if self.m_gameData then
        self.m_curLevel = self.m_gameData:getHonorLv()
        self:updateUI(self.m_curLevel)
    end
end

function SidekicksRankLayer:showBubble(_index, _showNum)
    if not self.m_bubble then
        self.m_bubble = util_createView("GameModule.Sidekicks.views.rank.SidekicksRankBuffBubble", self.m_seasonIdx)
        self.m_node_Ranklayer:addChild(self.m_bubble)
    end

    local buffNode = self:findChild("node_buff_" .. _index)
    local x, y = buffNode:getPosition()
    self.m_bubble:setPosition(x, y)
    self.m_bubble:playOpen(_index, _showNum, self.m_curLevel)
end

function SidekicksRankLayer:hideBubble()
    if self.m_bubble then
        self.m_bubble:hideSelf()
    end
end

function SidekicksRankLayer:buySuccess(_data)
    local func = function ()
        self:createRewardUI(_data)
    end

    local x, y = self.m_node_Ranklayer:getPosition()
    local worldPos = self.m_node_Ranklayer:getParent():convertToWorldSpace(cc.p(x, y))

    self.m_sale:collectReward(func, worldPos)
end

function SidekicksRankLayer:buyfailed()
    self:setTouch(false)
    self.m_sale:setTouch(false)
end

function SidekicksRankLayer:createRewardUI(_data)
    self:buyfailed()

    if not _data then
        return
    end

    G_GetMgr(G_REF.Sidekicks):showSaleReward(self.m_seasonIdx, _data)
end

function SidekicksRankLayer:registerListener()
    SidekicksRankLayer.super.registerListener(self)

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == G_REF.Sidekicks then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.success then
                self:buySuccess(params.data)
            else
                self:buyfailed()
            end
        end,
        SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_HONOR_SALE
    )
end

return SidekicksRankLayer