--[[
    
]]

local AvatarGameCollectLayer = class("AvatarGameCollectLayer", BaseLayer)
local ShopItem = util_require("data.baseDatas.ShopItem")

function AvatarGameCollectLayer:ctor()
    AvatarGameCollectLayer.super.ctor(self)

    self:setLandscapeCsbName("Activity/csb/Cash_dice/CashDice_reward.csb")
    self:setExtendData("AvatarGameCollectLayer")
end

function AvatarGameCollectLayer:initDatas(_data, _isAutoCollect)
    self.m_coin = _data.coins
    self.m_items = _data.items
    self.m_isAutoCollect = _isAutoCollect
end

function AvatarGameCollectLayer:initCsbNodes()
    self.m_node_reward = self:findChild("node_reward")
    self.m_root = self:findChild("root")
    self:addClick(self.m_root)
end

function AvatarGameCollectLayer:initView()
    local itemDataList = {}
    -- 金币道具
    if self.m_coin and self.m_coin > 0 then 
        local itemData = gLobalItemManager:createLocalItemData("Coins", self.m_coin)
        itemData:setTempData({p_limit = 3})
        itemDataList[#itemDataList+1] = itemData
    end
    -- 通用道具
    if self.m_items and #self.m_items > 0 then 
        for i,v in ipairs(self.m_items) do
            local itemData = ShopItem:create()
            itemData:parseData(v)
            itemDataList[#itemDataList+1] = gLobalItemManager:createLocalItemData(itemData.p_icon, itemData.p_num, itemData)
        end
    end

    local itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
    if itemNode then 
        self.m_node_reward:addChild(itemNode) 
        self.m_node_reward:setScale(1.2)
    end

    self:checkAutoCollect()
end

function AvatarGameCollectLayer:checkAutoCollect()
    if self.m_isAutoCollect then 
        performWithDelay(self.m_node_reward, function ()
            self.m_isTouch = true
            self:rewardCollect()
        end, 3)
    end
end

function AvatarGameCollectLayer:clickFunc(_sander)
    if self.m_isTouch then 
        return 
    end
    self.m_isTouch = true
    self.m_node_reward:stopAllActions()
    self:rewardCollect()
end

function AvatarGameCollectLayer:rewardCollect()
    local callBack = function ()
        if CardSysManager:needDropCards("Avatar Frame Game") == true then
            gLobalNoticManager:addObserver(self,function(self,func)
                if not tolua.isnull(self) then 
                    self:closeUI(function ()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AVATAR_GAME_COLLECT, true)
                    end)
                end
            end,ViewEventType.NOTIFY_CARD_SYS_OVER)
            CardSysManager:doDropCards("Avatar Frame Game", nil)
        else
            self:closeUI(function ()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AVATAR_GAME_COLLECT, true)
            end)
        end
    end

    local endPos = globalData.flyCoinsEndPos
    local btnCollect = self:findChild("node_button")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local baseCoins = globalData.topUICoinCount 
    local rewardCoins = self.m_coin
    if rewardCoins == 0 then 
        callBack()
    else 
        gLobalViewManager:pubPlayFlyCoin(startPos,endPos,baseCoins,rewardCoins,function()
            callBack()
        end )
    end
end

function AvatarGameCollectLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function AvatarGameCollectLayer:playShowAction()
    local root = self:findChild("root")
    local userDefAction = function(callFunc)
        if self.m_isShowActionEnabled and root then
            gLobalSoundManager:playSound("Activity/sound/game/CollectShow.mp3")
            util_setCascadeOpacityEnabledRescursion(root, true)
    
            local scale = root:getScale()
            root:setScale(0.8 * scale)
    
            local actionList = {}
            actionList[#actionList + 1] = cc.EaseSineInOut:create(cc.ScaleTo:create(12 / 60, scale * 1.02))
            actionList[#actionList + 1] = cc.EaseSineInOut:create(cc.ScaleTo:create(8 / 60, scale * 0.99))
            actionList[#actionList + 1] = cc.ScaleTo:create(6 / 60, scale)
            if callFunc then
                actionList[#actionList + 1] = cc.CallFunc:create(callFunc)
            end
            local seq = cc.Sequence:create(actionList)
            root:runAction(seq)
    
            root:setOpacity(0)
            local actionList2 = {}
            actionList2[#actionList2 + 1] = cc.FadeTo:create(10 / 60, 255)
            local seq2 = cc.Sequence:create(actionList2)
            root:runAction(seq2)
        else
            if callFunc then
                callFunc()
            end
        end
    end
    AvatarGameCollectLayer.super.playShowAction(self, userDefAction)
end

return AvatarGameCollectLayer