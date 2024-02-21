--[[
    比赛
    author: 徐袁
    time: 2021-08-12 14:15:33
]]
local LeagueNetModel = util_require("activities.Activity_Leagues.net.LeagueNetModel")
local LeagueSaleControl = class("LeagueSaleControl", BaseActivityControl)

function LeagueSaleControl:ctor()
    LeagueSaleControl.super.ctor(self)
    self.m_buying = false
    self:setRefName(ACTIVITY_REF.LeagueSale)
    
    self.m_netModel = LeagueNetModel:getInstance() 
end

function LeagueSaleControl:addPreRef(_refName)
    self.m_preModuleRef = {}
    LeagueSaleControl.super.addPreRef(self, _refName)
end

-- 显示促销界面
function LeagueSaleControl:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView(self:getPopModule())

    -- 促销面板中会弹出商城和商城的后续弹框，UI层级暂时定为 ZORDER_UI，先不用 ZORDER_POPUI
    self:showLayer(view, ViewZorder.ZORDER_UI) 
    return view
end

--打点支付信息先放这里临时修复
function LeagueSaleControl:initShowIapLog()
    local goodsInfo = {}
    goodsInfo.goodsTheme = "Promotion_Leagues"
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "limitBuy"
    purchaseInfo.purchaseName = "ArenaSale"
    purchaseInfo.purchaseStatus = ""
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end

-- 促销buff飞行效果
function LeagueSaleControl:flyBuffEffect(_desPos)
    local _flyNode = cc.Node:create()
    _flyNode:setName("fly_league_promision")

    -- 添加遮罩层
    local _flyMask = util_newMaskLayer(true)
    performWithDelay(
        _flyMask,
        function()
            if _flyMask ~= nil and _flyMask.removeFromParent then
                _flyMask:removeFromParent()
                _flyMask = nil
            end
        end,
        2
    )

    gLobalViewManager:getViewLayer():addChild(_flyMask, ViewZorder.ZORDER_SPECIAL)
    gLobalViewManager:getViewLayer():addChild(_flyNode, ViewZorder.ZORDER_SPECIAL)
    local _nodeSD, _actSD = util_csbCreate("Activity/csd/league_shandian.csb")

    _flyNode:addChild(_nodeSD)

    local _srcPos = cc.p(display.width / 2, display.height / 2)
    _flyNode:setPosition(_srcPos)

    -- 计算旋转弧度
    local _tan2 = math.atan2((_srcPos.y - _desPos.y), (_srcPos.x - _desPos.x)) * (-180 / math.pi)
    local _dis = math.sqrt(math.pow(_desPos.y - _srcPos.y, 2) + math.pow(_desPos.x - _srcPos.x, 2))
    local _scale = _dis / (4 * 177 - 50)

    -- 播放音效
    gLobalSoundManager:playSound("Sound/leagues_promotion.mp3")

    util_csbPlayForKey(
        _actSD,
        "start",
        false,
        function()
            _flyNode = gLobalViewManager:getViewLayer():getChildByName("fly_league_promision")
            if _flyNode then
                local _nodeTW, _actTW = util_csbCreate("Activity/csd/league_tuowei.csb")
                _nodeTW:setRotation(_tan2)
                _nodeTW:setScaleX(_scale)
                _flyNode:addChild(_nodeTW)
                util_csbPlayForKey(
                    _actTW,
                    "start",
                    false,
                    function()
                        -- 通知促销节点播放闪电特效
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_LIGHTNING_ARRIVE)
                        if _flyNode then
                            _flyNode:removeFromParent()
                            _flyNode = nil
                        end
                    end,
                    60
                )
            end
        end,
        60
    )
end

function LeagueSaleControl:buyLeagueBuff()
    local leagueSale = self:getRunningData()
    if not leagueSale then
        return
    end

    -- 检测宝石是否满足条件
    if self:checkGem() then
        if self.m_buying then
            return
        end
        self.m_buying = true
        self:sendLeagueSaleUseGem()
    else
        self:openGemStore("btn_buy")
    end
end

function LeagueSaleControl:checkGem()
    local needGems = 0
    local leagueSale = self:getRunningData()
    if leagueSale then
        local saleItems = leagueSale:getSaleItems()
        if saleItems and saleItems[1] then
            needGems = saleItems[1].p_gemPrice or 0
        end
    end
    return globalData.userRunData.gemNum >= needGems
end

function LeagueSaleControl:openGemStore(openBtnName)
    gLobalSendDataManager:getLogIap():setEntryType("Arena")
    local params = {shopPageIndex = 2 , dotKeyType = openBtnName, dotUrlType = DotUrlType.UrlName , dotIsPrep = false}
    local view = G_GetMgr(G_REF.Shop):showMainLayer(params)
    if view then
        view.buyShop = true
    end
end

-- 首充降档
function LeagueSaleControl:sendLeagueSaleUseGem()
    local success = function()
        self.m_buying = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_SALE_SUCCESS)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
    end

    local fail = function()
        self.m_buying = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_SALE_FAIL)
        gLobalViewManager:showReConnect()
    end

    self.m_netModel:sendLeagueSaleUseGem(success, fail)
end

return LeagueSaleControl
