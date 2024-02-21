--
-- 大厅轮播 首冲
--

-- 是否首冲
-- globalData.shopRunData:isShopFirstBuyed()

-- 轮播
-- levelNode 类型自己加

-- 移除
-- levelLayerNode onEnter添加移除事件 ？？？

-- 商城
-- 处理商城中的显示和奖励双倍

local LevelFirstBuyNode = class("LevelFirstBuyNode", util_require("base.BaseView"))

function LevelFirstBuyNode:initUI()
    self:createCsbNode("newIcons/Level_FirstBuy.csb")
    self.m_content = self:findChild("content")
    local size = self.m_content:getContentSize()
    self.m_contentLenX = size.width * 0.5
    self.m_contentLenY = size.height * 0.5

    self:runCsbAction("idle", true, nil, 60)
    
    -- 添加点击事件
    local touch = self:makeTouch(self.m_content)
    self:addChild(touch, 1)
    self:addClick(touch)
    self.m_touch = touch
end

function LevelFirstBuyNode:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, loginInfo)
            gLobalViewManager:removeLoadingAnima()
            if gLobalGameHeartBeatManager then
                gLobalGameHeartBeatManager:stopHeartBeat()
            end
            util_restartGame()
        end,
        GlobalEvent.FB_LoginStatus,
        true
    )
end

function LevelFirstBuyNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function LevelFirstBuyNode:isOpenShop()
    return self.isOpen
end

function LevelFirstBuyNode:setIsOpenShop(bOpen)
    self.isOpen = bOpen
end

function LevelFirstBuyNode:getContentLen()
    return self.m_contentLenX, self.m_contentLenY
end

function LevelFirstBuyNode:getOffsetPosX()
    return self.m_contentLenX
end

function LevelFirstBuyNode:updateUI()
end

--根据content大小创建按钮监听
function LevelFirstBuyNode:makeTouch(content)
    local touch = ccui.Layout:create()
    touch:setName("touch")
    touch:setTag(10)
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(true)
    touch:setAnchorPoint(0.5000, 0.5000)
    touch:setContentSize(content:getContentSize())
    touch:setClippingEnabled(false)
    touch:setBackGroundColorOpacity(0)
    return touch
end

--点击回调
function LevelFirstBuyNode:clickFunc(sender)
    local name = sender:getName()

    self:clickRateus(name)
end

--点击回调
function LevelFirstBuyNode:MyclickFunc()
    self:clickRateus()
end

function LevelFirstBuyNode:clickRateus(name)
    if self:isOpenShop() then
        return true
    end

    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    performWithDelay(
        self,
        function()
            -- 打开商城
            local params = {
                shopPageIndex = 1,
                dotKeyType = name,
                dotUrlType = DotUrlType.UrlName,
                dotIsPrep = true,
                dotEntrySite = DotEntrySite.LobbyDisplay,
                dotEntryType = DotEntryType.Lobby
            }
            local view = G_GetMgr(G_REF.Shop):showMainLayer(params)
            if view then
                view:setOverFunc(
                    function()
                        if not tolua.isnull(self) then
                            self:setIsOpenShop(false)
                        end
                    end
                )
            end
        end,
        0.2
    )
    self:setIsOpenShop(true)
end

return LevelFirstBuyNode
