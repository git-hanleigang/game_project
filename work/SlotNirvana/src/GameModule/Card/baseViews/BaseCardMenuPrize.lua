--[[
    卡片收集规则中 收集全卡后 奖励说明
]]
local BaseCardMenuPrize = class("BaseCardMenuPrize", BaseLayer)
local SHOW_COL = 2

function BaseCardMenuPrize:initDatas()
    self.m_canClick = false
    self.isClose = false
    self.m_curPageIndex = 1
    self:setHideLobbyEnabled(true)
end

-- 初始化UI --
-- function BaseCardMenuPrize:initUI()
--     BaseCardMenuPrize.super.initUI(self)
-- end

function BaseCardMenuPrize:playShowAction()
    BaseCardMenuPrize.super.playShowAction(self, "show", false)
end

function BaseCardMenuPrize:onShowedCallFunc()
    if self.isClose then
        return
    end
    self.m_canClick = true
    CardSysManager:hideRecoverSourceUI()
    self:runCsbAction("idle", true)
end

function BaseCardMenuPrize:initAdapt()
end


function BaseCardMenuPrize:getPrizeCellCsbName()
    return ""
end

function BaseCardMenuPrize:getTableViewData()
    local cardClanData = CardSysRuntimeMgr:getCardAlbumInfo()
    return cardClanData and cardClanData.cardClans and CardSysRuntimeMgr:sortCardClanInfo(cardClanData.cardClans) or {}
end

-- 初始化数据 --
function BaseCardMenuPrize:initCsbNodes()
    -- self.isClose = false
    self.m_page2clansData = self:getTableViewData()
    -- self.m_curPageIndex = 1
    self.m_cardClanNUm = #self.m_page2clansData -- 目前15个卡组 --
    self.m_pageCellNum = math.ceil(self.m_cardClanNUm / SHOW_COL) -- 分8个显示单元 --

    -- self.m_prePage  = self:findChild("Button_6")
    -- self.m_nextPage = self:findChild("Button_7")
    -- self.m_prePage:setVisible(false)
    -- self.m_nextPage:setVisible(false)

    self.m_rulePage1 = self:findChild("rule_7")
    self.m_rulePage2 = self:findChild("rule_8")
    self.m_rulePage3 = self:findChild("rule_9")
    for i = 1, 3 do
        self["m_rulePage" .. i]:setVisible(false)
    end
    self:showRulePage1()
end

-- 显示 --
function BaseCardMenuPrize:moveToRulePage(nIndex)
    if self.m_curPageIndex == nIndex then
        return
    end

    for i = 1, 3 do
        self["m_rulePage" .. i]:setVisible(false)
    end

    self.m_curPageIndex = nIndex

    if nIndex == 1 then
        self:showRulePage1()
    elseif nIndex == 2 then
        self:showRulePage2()
    elseif nIndex == 3 then
        self:showRulePage3()
    end
end

-- 点击事件 --
function BaseCardMenuPrize:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if not self.m_canClick then
        return
    end
    if name == "Button_4" then
        -- CardSysManager:closeRecoverSourceUI()
        -- CardSysRuntimeMgr:setSelAlbumID(CardSysRuntimeMgr:getCurAlbumID())
        -- 关闭 --
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        self:closeUI()
        CardSysManager:showRecoverSourceUI()
    elseif name == "Button_5" then
        -- 返回 --
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        self:closeUI()
        CardSysManager:showRecoverSourceUI()
    elseif name == "Button_6" then
        -- 左 ---
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        if self.m_curPageIndex - 1 > 0 then
            self:moveToRulePage(self.m_curPageIndex - 1)
        end
    elseif name == "Button_7" then
        -- 右 ---
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        if self.m_curPageIndex + 1 <= 3 then
            self:moveToRulePage(self.m_curPageIndex + 1)
        end
    elseif name == "Button_1" then
        -- rule 1 --
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:moveToRulePage(1)
    elseif name == "Button_2" then
        -- rule 2 --
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:moveToRulePage(2)
    elseif name == "Button_3" then
        -- rule 3 --
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:moveToRulePage(3)
    end
end

-- 关闭事件 --
function BaseCardMenuPrize:closeUI(exitFunc)
    if self.isClose then
        return
    end
    self.isClose = true

    BaseCardMenuPrize.super.closeUI(self, exitFunc)
end


function BaseCardMenuPrize:getTotalSets()
    local albumInfo = CardSysRuntimeMgr:getCardAlbumInfo()
    return albumInfo and #albumInfo.cardClans or 0
end

function BaseCardMenuPrize:getMaxAlbumPrize()
    local albumInfo = CardSysRuntimeMgr:getCardAlbumInfo()
    return albumInfo.coins
end

function BaseCardMenuPrize:showRulePage1()
    self.m_rulePage1:setVisible(true)
    -- 初始化数据 --
    self.m_page1Coins = self:findChild("BitmapFontLabel_2")
    self.m_page1Coins:setString(util_formatCoins(tonumber(self:getMaxAlbumPrize()), 30))
    self.m_page1Num = self:findChild("BitmapFontLabel_3")
    self.m_page1Num:setString(self:getTotalSets())
end

function BaseCardMenuPrize:getCellSize()
    return cc.size(1150, 115)
end

function BaseCardMenuPrize:showRulePage2()
    self.m_rulePage2:setVisible(true)
    -- 初始化数据 --

    if not self.m_tableView then
        local tableViewRoot = self:findChild("tableViewList")
        local tableViewSize = tableViewRoot:getContentSize()

        --创建TableView
        self.m_tableView = cc.TableView:create(tableViewSize)
        --设置滚动方向
        self.m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
        self.m_tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
        self.m_tableView:setDelegate()
        tableViewRoot:addChild(self.m_tableView)

        local cellSize = self:getCellSize()

        local numberOfCellsInTableView = function(table)
            return self.m_pageCellNum
        end

        local cellSizeForTable = function(table, idx)
            return cellSize.width, cellSize.height
        end

        local tableCellAtIndex = function(table, idx)
            local cell = table:dequeueCell()
            if nil == cell then
                cell = cc.TableViewCell:new()

                -- 接下来创建两条数据并列存在 --
                local prizeCell1 = util_csbCreate(self:getPrizeCellCsbName())
                prizeCell1:setPosition(cc.p(100, 0))
                prizeCell1:setTag(10)
                cell:addChild(prizeCell1)

                local prizeCell2 = util_csbCreate(self:getPrizeCellCsbName())
                prizeCell2:setPosition(cc.p(650, 0))
                prizeCell2:setTag(11)
                cell:addChild(prizeCell2)
            end

            -- tableview idx 从0开始计
            local _idx = idx + 1

            -- 第一个的数据idx
            local dataIndex1 = (_idx - 1) * 2 + 1
            -- 第二个的数据idx
            local dataIndex2 = dataIndex1 + 1

            -- 第一个的UI --
            local prizeCell1 = cell:getChildByTag(10)
            if nil ~= prizeCell1 then
                self:updatePage2Cell(prizeCell1, _idx, self.m_page2clansData[dataIndex1])
            end

            -- 第一个的UI --
            local prizeCell2 = cell:getChildByTag(11)
            if nil ~= prizeCell2 then
                if self.m_page2clansData[dataIndex2] then
                    prizeCell2:setVisible(true)
                    self:updatePage2Cell(prizeCell2, _idx, self.m_page2clansData[dataIndex2])
                else
                    prizeCell2:setVisible(false)
                end
            end
            return cell
        end

        --registerScriptHandler functions must be before the reloadData funtion
        self.m_tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
        self.m_tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
        self.m_tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)
        self.m_tableView:registerScriptHandler(handler(self, self.scrollViewDidScroll), cc.SCROLLVIEW_SCRIPT_SCROLL)

        --调用这个才会显示界面
        self.m_tableView:reloadData()

        local sliderBg, sliderPro, sliderMarker = self:getSliderIcon()
        self:initSlider(tableViewRoot, sliderBg, sliderPro, sliderMarker, tableViewSize, cellSize, self.m_pageCellNum)
    end
end

function BaseCardMenuPrize:getSliderIcon()
    return "", "", ""
end

-- 滑动条 --
function BaseCardMenuPrize:initSlider(tableViewNode, bgIcon, proIcon, markIcon, tableViewSize, cellSize, cellNum)
    -- 创建 slider滑动条 --
    local bgFile = cc.Sprite:create(bgIcon)
    local progressFile = cc.Sprite:create(proIcon)
    local thumbFile = cc.Sprite:create(markIcon)

    self.m_slider = cc.ControlSlider:create(bgFile, progressFile, thumbFile)
    self.m_slider:setPosition(tableViewSize.width - 30, tableViewSize.height / 2)
    self.m_slider:setAnchorPoint(cc.p(0.5, 0.5))
    self.m_slider:setRotation(90)
    self.m_slider:setEnabled(true)
    self.m_slider:registerControlEventHandler(handler(self, self.sliderMoveEvent), cc.CONTROL_EVENTTYPE_VALUE_CHANGED)
    self.m_slider:setMinimumValue(-(cellSize.height * cellNum - tableViewSize.height))
    self.m_slider:setMaximumValue(0)
    self.m_slider:setValue(-(cellSize.height * cellNum - tableViewSize.height))
    tableViewNode:addChild(self.m_slider)

    -- 创建一个长背景条 保证滑块上下齐边 --
    local markSize = thumbFile:getTextureRect()
    local bgSize = bgFile:getTextureRect()
    local addBgNode = ccui.ImageView:create(bgIcon)
    addBgNode:setAnchorPoint(cc.p(0.5, 0.5))
    addBgNode:setScale9Enabled(true)
    addBgNode:setSize(cc.size(markSize.width + bgSize.width, bgSize.height))
    addBgNode:setPosition(cc.p(self.m_slider:getContentSize().width / 2, self.m_slider:getContentSize().height / 2))
    self.m_slider:addChild(addBgNode, -1)

    -- 监测互斥的方案 --
    self.m_moveTable = true
    self.m_moveSlider = true
end

-- slider 滑动事件 --
function BaseCardMenuPrize:sliderMoveEvent()
    self.m_moveTable = false
    if self.m_moveSlider == true then
        local sliderOff = self.m_slider:getValue()
        self.m_tableView:setContentOffset(cc.p(0, sliderOff))
    end
    self.m_moveTable = true
end

-- tableView回调事件 --
--滚动事件
function BaseCardMenuPrize:scrollViewDidScroll(view)
    self.m_moveSlider = false

    if self.m_moveTable == true then
        local offY = self.m_tableView:getContentOffset().y

        if self.m_slider ~= nil then
            local sliderY = self.m_slider:getValue()
            self.m_slider:setValue(offY)
        end
    end
    self.m_moveSlider = true
end

-- 章节奖励cell
function BaseCardMenuPrize:updatePage2Cell(pCellNode, index, clanData)
    local coins = pCellNode:getChildByName("coins")
    local logo = pCellNode:getChildByName("CashCards_logo_1")
    local wild = pCellNode:getChildByName("CardLink_rule_wild_3")
    local bgWild = pCellNode:getChildByName("Image_3")

    local bgNormals = {}
    bgNormals[#bgNormals + 1] = pCellNode:getChildByName("Image_1")
    bgNormals[#bgNormals + 1] = pCellNode:getChildByName("Image_4")

    coins:setString(util_formatCoins(tonumber(clanData.coins), 50))
    util_changeTexture(logo, CardResConfig.getCardClanIcon(clanData.clanId))
    if clanData.clanId == "201901" then
        logo:setScale(0.5)
    elseif clanData.clanId == "201902" then
        if CardSysRuntimeMgr:isWildClan(clanData.type) then
            -- wild章节要缩小
            logo:setScale(0.45)
        else
            logo:setScale(0.75)
        end
    end
    -- --test 赛季未开启临时删除第二赛季前三张这个赛季开了就可以删除
    -- local hasSeasonOpening = CardSysManager:hasSeasonOpening()
    -- if not hasSeasonOpening then
    --     if clanData.season and clanData.season == 1 then
    --         logo:setScale(0.5)
    --     end
    -- end
    if clanData.wild then
        wild:setVisible(false) -- 这个赛季普通章节不会送wild卡改为false
        bgWild:setVisible(true)
        for i = 1, #bgNormals do
            bgNormals[i]:setVisible(false)
        end
    else
        wild:setVisible(false)
        bgWild:setVisible(false)

        local showindex = index % 2 + 1
        for i = 1, #bgNormals do
            bgNormals[i]:setVisible(i == showindex)
        end
    end
end

function BaseCardMenuPrize:getTotalLinkCardNum()
    return CardSysRuntimeMgr:getSeasonData():getTotalLinkCard()
end

function BaseCardMenuPrize:getMaxLinkCoins()
    return globalData.constantData.CARD_LinkRewardCoinsWorth
end

function BaseCardMenuPrize:showRulePage3()
    self.m_rulePage3:setVisible(true)
    -- 初始化数据 --

    -- Link 最大数量 --
    local linkNumNode = self:findChild("BitmapFontLabel_4")
    linkNumNode:setString(tostring(self:getTotalLinkCardNum()))

    -- Link游戏最大金币奖励 --
    local maxLinkCoinsWorthNode = self:findChild("BitmapFontLabel_5")

    maxLinkCoinsWorthNode:setString("$" .. util_formatCoins(self:getMaxLinkCoins(), 10))
end

return BaseCardMenuPrize
