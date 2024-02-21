--[[
    卡片收集规则中 收集全卡后 奖励说明
]]
local BaseCardMenuPrize = util_require("GameModule.Card.baseViews.BaseCardMenuPrize")
local CardMenuPrize = class("CardMenuPrize", BaseCardMenuPrize)

-- function CardMenuPrize:createCsb()
--     self:createCsbNode(self:getCsbName())
-- end

function CardMenuPrize:initDatas()
    CardMenuPrize.super.initDatas(self)
    self:setLandscapeCsbName(string.format(CardResConfig.seasonRes.CardPrizeRes, "season201903"))
end

-- function CardMenuPrize:getLeftAdaptList()
--     return {}
-- end

-- function CardMenuPrize:getRightAdaptList()
--     return {self:findChild("Button_4")}
-- end

function CardMenuPrize:initAdapt()
    -- local offsetX = 0
    -- local ratio = display.width / display.height
    -- if ratio <= 1.34 then -- 1024x768
    --     offsetX = 0
    -- elseif ratio <= 1.5 then -- 960x640
    --     offsetX = 25
    -- elseif ratio <= 1.79 then -- 1370x768
    --     offsetX = 45
    -- elseif ratio <= 2 then -- 1280x640
    --     offsetX = 120
    -- else -- 2340x1080 -- 1170x540
    --     offsetX = 190
    -- end

    -- local lefts = self:getLeftAdaptList()
    -- if lefts and #lefts > 0 then
    --     for i = 1, #lefts do
    --         local oriX = lefts[i]:getPositionX()
    --         lefts[i]:setPositionX(oriX + offsetX)
    --     end
    -- end

    -- local rights = self:getRightAdaptList()
    -- if rights and #rights > 0 then
    --     for i = 1, #rights do
    --         local oriX = rights[i]:getPositionX()
    --         rights[i]:setPositionX(oriX - offsetX)
    --     end
    -- end
end

-- 初始化UI --
-- function CardMenuPrize:getCsbName()
--     return string.format(CardResConfig.seasonRes.CardPrizeRes, "season201903")
-- end

function CardMenuPrize:getSliderIcon()
    return CardResConfig.otherRes.PrizeSliderBg, CardResConfig.otherRes.PrizeSliderBg, CardResConfig.otherRes.PrizeSliderMark
end

function CardMenuPrize:getPrizeCellCsbName()
    return string.format(CardResConfig.seasonRes.CardPrizeCellRes, "season201903")
end

function CardMenuPrize:getCellSize()
    return cc.size(950, 100)
end

function CardMenuPrize:showRulePage2()
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
                -- prizeCell1:setAnchorPoint(0.5, 0.5)
                prizeCell1:setPosition(cc.p(cellSize.width * 0.25, cellSize.height * 0.5))
                prizeCell1:setTag(10)
                cell:addChild(prizeCell1)

                local prizeCell2 = util_csbCreate(self:getPrizeCellCsbName())
                -- prizeCell1:setAnchorPoint(0.5, 0.5)
                prizeCell2:setPosition(cc.p(cellSize.width * 0.75, cellSize.height * 0.5))
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

-- 章节奖励cell
function CardMenuPrize:updatePage2Cell(pCellNode, index, clanData)
    local coins = pCellNode:getChildByName("coins")
    local logo = pCellNode:getChildByName("CashCards_logo_1")
    local wild = pCellNode:getChildByName("CardLink_rule_wild_3")
    local bgWild = pCellNode:getChildByName("Image_3")

    local bgNormals = {}
    bgNormals[#bgNormals + 1] = pCellNode:getChildByName("Image_1")
    bgNormals[#bgNormals + 1] = pCellNode:getChildByName("Image_4")

    coins:setString(util_formatCoins(tonumber(clanData.coins), 50))
    local pngPath = CardResConfig.getCardClanIcon(clanData.clanId)
    if pngPath then
        util_changeTexture(logo, pngPath)
    end
    -- if CardSysRuntimeMgr:isWildClan(clanData.type) then
    --     -- wild章节要缩小
    --     logo:setScale(0.45)
    -- else
    --     logo:setScale(0.75)
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

-- 点击事件 --
function CardMenuPrize:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if not self.m_canClick then
        return
    end
    if name == "Button_4" then
        -- else
        --     self:closeUI()
        --     CardSysManager:closeRecoverSourceUI()
        --     CardSysRuntimeMgr:setSelAlbumID(CardSysRuntimeMgr:getCurAlbumID())
        -- end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        -- if CardSysRuntimeMgr:getSelAlbumID() == CardSysRuntimeMgr:getCurAlbumID() then
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

return CardMenuPrize
