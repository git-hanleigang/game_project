--[[
    邮件推送奖励
]]
local ShopItem = require "data.baseDatas.ShopItem"
local EmailNotifyRewardUI = class("NotifyRewardUI", BaseLayer)

function EmailNotifyRewardUI:ctor()
    EmailNotifyRewardUI.super.ctor(self)

    self:setExtendData("EmailNotifyRewardUI")
end

function EmailNotifyRewardUI:initCsbNodes()
    self.m_rewardNode = self:findChild("Node_reward")
end

function EmailNotifyRewardUI:initDatas(_data, _callback)
    -- self.m_theme = _data.theme
    self.m_coins = tonumber(_data.totalCoins)
    self.m_callback = _callback
    self:initItemData(_data.items)
end

-- 现在只有一个圣诞节的资源，后续有其他主题资源再到这里进行资源匹配
-- cxc 2022年01月04日16:46:35 不做多主题
function EmailNotifyRewardUI:getCsbName()
    return "NotifyReward/EmailPopup/Csb/EmailPopup_Layer.csb"
end

function EmailNotifyRewardUI:initView()
    local uiList = {}
    if self.m_coins and self.m_coins > 0 then 
        local itemNode = util_createView("views.NotifyReward.EmailNotifyRewardNode", self.m_coins)
        if itemNode then 
            self.m_rewardNode:addChild(itemNode)
            uiList[#uiList + 1] = {node = itemNode, size = cc.size(243, 256), alignX = 10, anchor = cc.p(0.5, 0.5)} 
        end
    end

    if self.m_items and #self.m_items > 0 then 
        for i,v in ipairs(self.m_items) do
            local itemNode = util_createView("views.NotifyReward.EmailNotifyRewardNode", v)
            if itemNode then 
                self.m_rewardNode:addChild(itemNode)
                uiList[#uiList + 1] = {node = itemNode, size = cc.size(243, 256), alignX = 10, anchor = cc.p(0.5, 0.5)} 
            end
        end
    end

    util_alignCenter(uiList, nil, 800)
    self:runCsbAction("idle", true)

    self:setButtonLabelContent("btn_cheer", "CATCH ‘EM ALL") 
end

function EmailNotifyRewardUI:initItemData(_netData)
    self.m_items = {}
    if _netData and #_netData > 0 then
        local temp = {}
        for i=1,#_netData do
            local _data = _netData[i]
            -- 合并卡包
            if _data.type == "Card" or _data.type == "Package" then
                if not temp[_data.type] then
                    temp[_data.type] = {}
                end
                if _data.icon and _data.icon ~= "" then
                    if not temp[_data.type][_data.icon] then
                        temp[_data.type][_data.icon] = _data
                    else
                        temp[_data.type][_data.icon].num = temp[_data.type][_data.icon].num + _data.num
                    end
                end
            else
                local itemData = ShopItem:create()
                itemData:parseData(_data)
                table.insert(self.m_items, itemData)
            end
        end
        for _type,_iconValue in pairs(temp) do
            for _icon, _value in pairs(_iconValue) do
                local itemData = ShopItem:create()
                itemData:parseData(_value)
                table.insert(self.m_items, itemData)
            end
        end
    end
end

function EmailNotifyRewardUI:clickFunc(_sender)
    if self.m_isTouch then 
        return
    end
    local senderName = _sender:getName()
    if senderName == "btn_x" or senderName == "btn_cheer" then 
        self.m_isTouch = true
        self:flyCoins()
    end
end

--飞金币
function EmailNotifyRewardUI:flyCoins(_flyCoinsEndCall)
    local _flyCoinsEndCall = function ()
        local cardSource = "Link Code"
        if CardSysManager:needDropCards(cardSource) == true then
            -- 卡包开完消息 只在自己触发掉卡的时候监听 监听早了会被其他地方掉卡影响
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    if not tolua.isnull(self) then 
                        self:closeUI(function ()
                            if self.m_callback then 
                                self.m_callback()
                            end
                        end)
                    end
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards(cardSource, nil)
        else
            if not tolua.isnull(self) then 
                self:closeUI(function ()
                    if self.m_callback then 
                        self.m_callback()
                    end
                end)
            end
        end
    end

    if self.m_coins and self.m_coins > 0 then
        local rewardCoins = self.m_coins
        local coinNode = self:findChild("btn_cheer")
        local senderSize = coinNode:getContentSize()
        local startPos = coinNode:convertToWorldSpace(cc.p(senderSize.width / 2, senderSize.height / 2))
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount
        local view = gLobalViewManager:getFlyCoinsView()
        view:pubShowSelfCoins(true)
        view:pubPlayFlyCoin(
            startPos,
            endPos,
            baseCoins,
            rewardCoins,
            function()
                if _flyCoinsEndCall ~= nil then
                    _flyCoinsEndCall()
                end
            end
        )
    else
        if _flyCoinsEndCall ~= nil then
            _flyCoinsEndCall()
        end
    end
end

return EmailNotifyRewardUI
