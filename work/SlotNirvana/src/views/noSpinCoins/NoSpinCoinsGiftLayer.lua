--版本更新
local NoSpinCoinsGiftLayer = class("NoSpinCoinsGiftLayer", util_require("base.BaseView"))
function NoSpinCoinsGiftLayer:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode("NoSpinCoinsUI/NoSpinCoinsGiftLayer.csb", isAutoScale)
    self:initView()
end

function NoSpinCoinsGiftLayer:initView()
    self.m_totalCoins = 0
    local machineCurBetList = globalData.slotRunData.machineData:getMachineCurBetList()
    if machineCurBetList and #machineCurBetList > 0 then
        local betData = machineCurBetList[1]
        if betData and betData.p_totalBetValue then
            self.m_totalCoins = betData.p_totalBetValue * 2
        end
    end

    self:setVisible(false)
    local serverGameName = globalData.slotRunData.machineData.p_name
    gLobalSendDataManager:getNetWorkFeature():sendNoSpinCoinsGift(
        serverGameName,
        self.m_totalCoins,
        function(target, resultData)
            if resultData:HasField("result") then
                local result = cjson.decode(resultData.result)
                if result and result.coins then
                    self.m_totalCoins = result.coins
                end
            end

            if self.m_totalCoins and self.m_totalCoins == 0 then
                self:closeUI()
                return
            end
            self:setVisible(true)
            local root = self:findChild("root")
            if root then
                self:runCsbAction("idle")
                self:commonShow(
                    root,
                    function()
                    end
                )
            else
                self:runCsbAction("show")
            end
            self.m_btn_collect = self:findChild("btn_collect")
            local m_lb_coins = self:findChild("m_lb_coins")
            if m_lb_coins then
                m_lb_coins:setString(util_formatCoins(self.m_totalCoins, 35))
                local sx = m_lb_coins:getScaleX()
                local sy = m_lb_coins:getScaleY()
                self:updateLabelSize({label = m_lb_coins, sx = sx, sy = sy}, 1200)
            end
            local sp_coin = self:findChild("Image_7")
            local uiList = {}
            table.insert(uiList,{node = sp_coin})
            table.insert(uiList,{node = m_lb_coins, alignY = 5, alignX = 25})
            util_alignCenter(uiList)
        end,
        function()
            gLobalViewManager:showReConnect()
            self:closeUI()
        end
    )
end

function NoSpinCoinsGiftLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_collect" then
        self:toCollect()
    elseif name == "btn_close" then
        self:toCollect()
    end
end

function NoSpinCoinsGiftLayer:toCollect()
    if self.isToCollect then
        return
    end
    self.isToCollect = true
    self:flyCoins()
end

function NoSpinCoinsGiftLayer:flyCoins()
    if self.m_btn_collect then
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount
        local btnCollect = self:findChild("btn_collect")
        local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
        gLobalViewManager:pubPlayFlyCoin(
            startPos,
            endPos,
            baseCoins,
            self.m_totalCoins,
            function()
                self:closeUI()
            end
        )
    end
end

function NoSpinCoinsGiftLayer:onKeyBack()
    self:toCollect()
end

function NoSpinCoinsGiftLayer:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true

    local root = self:findChild("root")
    if root then
        self:commonHide(
            root,
            function()
                self:removeFromParent()
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        )
    else
        self:runCsbAction(
            "over",
            false,
            function()
                self:removeFromParent()
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end,
            60
        )
    end
end

return NoSpinCoinsGiftLayer
