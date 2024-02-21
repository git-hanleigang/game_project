--
-- wild兑换面板兑换时的二次确认面板
--
local CardWildConfirm = class("CardWildConfirm", BaseLayer)

function CardWildConfirm:initDatas(cardData, yesFunc)
    CardWildConfirm.super.initDatas(self)
    self.m_cardData = cardData
    self.yesFunc = yesFunc

    self:setLandscapeCsbName(string.format(CardResConfig.commonRes.CardWildConfirmRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    self:initData()
end

-- 初始化UI --
function CardWildConfirm:initUI(cardData, yesFunc)
    CardWildConfirm.super.initUI(self)
    -- local isAutoScale = true
    -- if CC_RESOLUTION_RATIO == 3 then
    --     isAutoScale = false
    -- end
    -- self:createCsbNode(string.format(CardResConfig.commonRes.CardWildConfirmRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()), isAutoScale)

    -- self.m_cardData = cardData
    -- self.yesFunc = yesFunc
    -- self:initData()
    self:updateUI()

    -- self:runCsbAction(
    --     "show",
    --     false,
    --     function()
    --         if self.isClose then
    --             return
    --         end
    --         self:runCsbAction("idle", true, nil, 60)
    --     end,
    --     60
    -- )
end

function CardWildConfirm:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CardWildConfirm.super.playShowAction(self, "show", false)
end

function CardWildConfirm:onShowedCallFunc()
    if self.isClose then
        return
    end
    self:runCsbAction("idle", true, nil, 60)
end

--适配方案 --
-- function CardWildConfirm:getUIScalePro()
--     local x = display.width / DESIGN_SIZE.width
--     local y = display.height / DESIGN_SIZE.height
--     local pro = x / y
--     if globalData.slotRunData.isPortrait == true then
--         pro = 0.8
--     end
--     return pro
-- end

-- 点击事件 --
function CardWildConfirm:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_yes" then
        if self.m_clicked == true then
            return
        end
        self.m_clicked = true
        CardSysManager:getWildExcMgr():closeWildConfirm()
        if self.yesFunc then
            self.yesFunc()
        end
    elseif name == "btn_no" then
        if self.m_clicked == true then
            return
        end
        self.m_clicked = true
        CardSysManager:getWildExcMgr():closeWildConfirm()
    end
end

function CardWildConfirm:playHideAction()
    gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
    CardWildConfirm.super.playHideAction(self, "over", false)
end

-- 关闭事件 --
function CardWildConfirm:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true

    -- self:runCsbAction(
    --     "over",
    --     false,
    --     function()
    --         self:removeFromParent()
    --     end,
    --     60
    -- )
    CardWildConfirm.super.closeUI(self)
end

-- 初始化数据 --
function CardWildConfirm:initData()
end

-- 刷新 --
function CardWildConfirm:updateUI()
    local view = nil

    local _logic = CardSysRuntimeMgr:getSeasonLogic(self.m_cardData.albumId)
    if _logic then
        view = _logic:createCardItemView(self.m_cardData)
    end
    view:setScale(0.35)

    self:findChild("card"):addChild(view)

    local des = string.gsub(self.m_cardData.name, "|", " ")
    self:findChild("Font_name"):setString(des)
end

function CardWildConfirm:onEnter()
    CardWildConfirm.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            -- 新赛季开启的时候退出集卡所有界面
            CardSysManager:getWildExcMgr():closeWildConfirm()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )

    -- -- 新手期结束
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         CardSysManager:getWildExcMgr():closeWildConfirm()
    --     end,
    --     ViewEventType.CARD_NOVICE_OVER
    -- )    
end

-- function CardWildConfirm:onExit()
--     gLobalNoticManager:removeAllObservers(self)
-- end

return CardWildConfirm
