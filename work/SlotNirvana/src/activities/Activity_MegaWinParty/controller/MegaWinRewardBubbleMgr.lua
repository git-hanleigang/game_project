--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-01-10 13:03:33
]]
local MegaWinRewardBubbleMgr = class("MegaWinRewardBubbleMgr", BaseSingleton)

function MegaWinRewardBubbleMgr:ctor()
    self.m_dropBubbleUIs = {}
    self.m_dropBubbleIndex = 0
end

function MegaWinRewardBubbleMgr:clearDate()
    self.m_dropBubbleUIs = {}
    self.m_dropBubbleIndex = 0
end

function MegaWinRewardBubbleMgr:getDropBubbleKey()
    self.m_dropBubbleIndex = self.m_dropBubbleIndex + 1
    return "dropBubble_" .. self.m_dropBubbleIndex
end

function MegaWinRewardBubbleMgr:showDropBubble(_rewardDatas)
    local bubbleUI = self:createDropBubbleUI(_rewardDatas)
    self.m_dropBubbleUIs[bubbleUI:getKey()] = bubbleUI

    local num = table.nums(self.m_dropBubbleUIs)
    local posY = self:getBubblePosY(num, bubbleUI:getBubbleHeight())
    -- print("init: key, posY, num -- ", bubbleUI:getKey(), posY, num)
    bubbleUI:setIndex(num)
    bubbleUI:setPosition(cc.p(display.width, posY))

    bubbleUI:playStart()
    performWithDelay(
        bubbleUI,
        function()
            if tolua.isnull(bubbleUI) then
                return
            end
            bubbleUI:playOver(
                function()
                    if tolua.isnull(bubbleUI) then
                        return
                    end
                    local removeKey = bubbleUI:getKey()
                    local removeIndex = bubbleUI:getIndex()
                    -- print("remove: key, posY, index -- ", removeKey, bubbleUI:getPositionY(), removeIndex)
                    for k, v in pairs(self.m_dropBubbleUIs) do
                        if k == removeKey then
                            if not tolua.isnull(self.m_dropBubbleUIs[k]) then
                                self.m_dropBubbleUIs[k]:removeFromParent()
                                self.m_dropBubbleUIs[k] = nil
                            end
                        else
                            if not tolua.isnull(self.m_dropBubbleUIs[k]) then
                                if v.getIndex and v:getIndex() > removeIndex then
                                    v:setIndex(v:getIndex() - 1)
                                    local nowPos = cc.p(v:getPosition())
                                    local targetPosY = self:getBubblePosY(v:getIndex(), v:getBubbleHeight())
                                    -- print("move: key, posY, num -- ", k, targetPosY, v:getIndex())
                                    v:runAction(cc.MoveTo:create(0.1, cc.p(nowPos.x, targetPosY)))
                                end
                            end
                        end
                    end
                end
            )
        end,
        3
    )
end

function MegaWinRewardBubbleMgr:createDropBubbleUI(_rewardDatas)
    local bubbleUI = util_createView("Activity.BoxReward.MegaWinPartyBoxRewardBubbleNode", _rewardDatas)
    gLobalViewManager:getViewLayer():addChild(bubbleUI, ViewZorder.ZORDER_UI_LOWER)
    local key = self:getDropBubbleKey()
    bubbleUI:setKey(key)
    return bubbleUI
end

function MegaWinRewardBubbleMgr:getBubblePosY(_index, _bubbleHeight)
    -- print("getBubblePosY --- 0", _index, _bubbleHeight)
    local startY = display.height - globalData.gameRealViewsSize.topUIHeight -- globalData.gameLobbyHomeNodePos.y
    -- release_print("MegaWinRewardBubbleMgr:getBubblePosY  display.height = ".. display.height .. " topUIHeight= "..globalData.gameRealViewsSize.topUIHeight .. " _index =" .. _index)
    local offsetY = 0
    local posY = startY - (_bubbleHeight + offsetY) * (_index - 1)
    -- print("getBubblePosY --- 1", startY, posY)
    return posY
end

return MegaWinRewardBubbleMgr