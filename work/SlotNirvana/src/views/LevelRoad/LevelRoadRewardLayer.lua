--[[
    等级里程碑 奖励界面
]]
local ShopItem = require "data.baseDatas.ShopItem"
local LevelRoadRewardLayer = class("LevelRoadRewardLayer", BaseLayer)

function LevelRoadRewardLayer:ctor()
    LevelRoadRewardLayer.super.ctor(self)

    -- 设置横屏csb
    self:setLandscapeCsbName("LevelRoad/csd/LevelRoad_rewardlayer.csb")
    self:setPortraitCsbName("LevelRoad/csd/Main_Portrait/LevelRoad_rewardlayer_Potrait.csb")
    self:setExtendData("LevelRoadRewardLayer")
end

function LevelRoadRewardLayer:initCsbNodes()
    self.m_node_reward = self:findChild("node_item")
    self.m_btn_collect = self:findChild("btn_collect")
end

function LevelRoadRewardLayer:initDatas()
    self.m_coins = 0
    self.m_gems = 0
    self.m_isHasLevelRoadGame = false
end

function LevelRoadRewardLayer:playShowAction()
    gLobalSoundManager:playSound("LevelRoad/sound/LevelRoad_reward.mp3")
    LevelRoadRewardLayer.super.playShowAction(self)
end

function LevelRoadRewardLayer:initView(params)
    if not params then
        return
    end

    local coins = tonumber(params.coins or 0)
    local items = self:parseItemsData(params.items or {})
    local itemDataList = {}
    self.m_coins = coins
    self.m_gems = 0
    -- 金币道具
    if coins and coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
        itemData:setTempData({p_limit = 3})
        itemDataList[#itemDataList + 1] = itemData
    end
    -- 通用道具
    if items and #items > 0 then
        items = self:mergeMiniGameItems(items)
        for i, v in ipairs(items) do
            local num = v.p_num
            local icon = v.p_icon
            if icon == "Gem" then
                self.m_gems = num
            end
            itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
        end
    end

    local itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
    if itemNode then
        self.m_node_reward:addChild(itemNode)
    end
end

-- 合并小游戏道具
function LevelRoadRewardLayer:mergeMiniGameItems(_data)
    local items = {}
    local temp = {}
    for i, v in ipairs(_data) do
        local key = v.p_icon
        if key == "MiniGame_LevelRoad" then
            self.m_isHasLevelRoadGame = true
            local itemInfo = temp[key]
            if itemInfo then
                itemInfo.p_num = itemInfo.p_num + v.p_num
                itemInfo:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_X}})
            else
                temp[key] = v
            end
        else
            table.insert(items, v)
        end
    end
    for i, v in pairs(temp) do
        table.insert(items, v)
    end
    return items
end

function LevelRoadRewardLayer:onClickMask()
    if self.m_isTouch then
        return
    end
    self:onClickCollect()
end

function LevelRoadRewardLayer:onClickCollect()
    self.m_isTouch = true
    self:rewardCollect()
end

function LevelRoadRewardLayer:clickFunc(_sander)
    if self.m_isTouch then
        return
    end

    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    local name = _sander:getName()
    if name == "btn_collect" then
        self:onClickCollect()
    end
end

function LevelRoadRewardLayer:rewardCollect()
    local callBack = function()
        if CardSysManager:needDropCards("Level Road") == true then
            CardSysManager:doDropCards(
                "Level Road",
                function()
                    self:closeUI(
                        function()
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_CLOSE_REWARDLAYER, self.m_isHasLevelRoadGame)
                        end
                    )
                end
            )
        else
            self:closeUI(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_CLOSE_REWARDLAYER, self.m_isHasLevelRoadGame)
                end
            )
        end
    end

    local btnCollect = self.m_btn_collect
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local cuyMgr = G_GetMgr(G_REF.Currency)
    if cuyMgr then
        local flyList = {}
        if self.m_coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.m_coins, startPos = startPos})
        end
        if self.m_gems > 0 then
            table.insert(flyList, {cuyType = FlyType.Gem, addValue = self.m_gems, startPos = startPos})
        end
        if #flyList > 0 then
            cuyMgr:playFlyCurrency(flyList, callBack)
        else
            callBack()
        end
    else
        callBack()
    end
end

function LevelRoadRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

-- 解析道具数据
function LevelRoadRewardLayer:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

return LevelRoadRewardLayer
