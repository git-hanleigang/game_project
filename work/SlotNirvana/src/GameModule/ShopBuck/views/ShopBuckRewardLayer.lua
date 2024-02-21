--[[
]]
local ShopBuckRewardLayer = class("ShopBuckRewardLayer", BaseLayer)

function ShopBuckRewardLayer:initDatas(_rewardBucks, _closeFunc)
    self.m_rewardBucks = tonumber(_rewardBucks or 0)
    self.m_closeFunc = _closeFunc
    self:setLandscapeCsbName("ShopBuck/csb/ShopBuckRewardLayer.csb")
    -- self:setPortraitCsbName("")
end

function ShopBuckRewardLayer:initCsbNodes()
    self.m_nodeRoot = self:findChild("root")
    self.m_lbBuck = self:findChild("lb_number")
    self:setButtonLabelContent("btn_yes", "COLLECT")
end

function ShopBuckRewardLayer:initView()
    self:initRewardBuck()
end

function ShopBuckRewardLayer:initRewardBuck()
    self.m_lbBuck:setString(self.m_rewardBucks)
end

-- function ShopBuckRewardLayer:playShowAction()
--     ShopBuckRewardLayer.super.playShowAction(self)
-- end

function ShopBuckRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function ShopBuckRewardLayer:onEnter()
    ShopBuckRewardLayer.super.onEnter(self)
end

function ShopBuckRewardLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_yes" then
        if self.m_isTouch then
            return
        end
        self.m_isTouch = true
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:collectBuck()
    end
end

function ShopBuckRewardLayer:collectBuck()
    self:flyBuck(function()
        if not tolua.isnull(self) then
            self:closeUI(self.m_closeFunc)
        end
    end)
end

-- 代币的飞行和增长
function ShopBuckRewardLayer:flyBuck(_over)
    -- V1
    local btnCollect = self:findChild("btn_yes")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local flyList = {}
    if self.m_rewardBucks > 0 then
        table.insert(flyList, {cuyType = FlyType.Buck, addValue = self.m_rewardBucks, startPos = startPos})
    end
    if #flyList > 0 then
        G_GetMgr(G_REF.Currency):playFlyCurrency(flyList, _over)
    else
        if _over then
            _over()
        end
    end

    -- V2
    -- local view = util_createView("GameModule.Currency.views.CollectBucksUI")
    -- self.m_nodeRoot:addChild(view)

    -- V3
    -- local buckNum = G_GetMgr(G_REF.ShopBuck):getBuckNum()
    -- local initBuckNum = math.max(0, buckNum - self.m_rewardBucks)
    -- view:updateUI(initBuckNum)

    -- if globalData.slotRunData.isPortrait then
    --     view:setPosition(cc.p(ShopBuckConfig.TOP_POS_V.x, display.height - ShopBuckConfig.TOP_POS_V.y))
    -- else
    --     view:setPosition(cc.p(ShopBuckConfig.TOP_POS_H.x, display.height - ShopBuckConfig.TOP_POS_H.y))
    -- end
    -- view:refreshBuck(self.m_rewardBucks, nil, function()
    --     if not tolua.isnull(self) and not tolua.isnull(view) then
    --         view:removeFromParent()
    --         view = nil
    --         if _over then
    --             _over()
    --         end
    --     end
    -- end)
    
    -- V4
    -- local topBuck = nil
    -- local mainLayer = gLobalViewManager:getViewByName("ShopBuckMainLayer")
    -- if not tolua.isnull(mainLayer) then
    --     topBuck = mainLayer:getTopBuckNode()
    -- end
    -- if not topBuck then
    --     if _over then
    --         _over()
    --     end        
    --     return
    -- end
    -- local oriParent = topBuck:getParent()
    -- local wPos = topBuck:getParent():convertToWorldSpace(cc.p(topBuck:getPosition()))
    -- local lPos = self.m_nodeRoot:convertToNodeSpace(wPos)
    -- util_changeNodeParent(self.m_nodeRoot, topBuck)
    -- topBuck:setPosition(lPos)

    -- topBuck:refreshBuck(self.m_rewardBucks, nil, function()
    --     if not tolua.isnull(oriParent) and not tolua.isnull(topBuck) then
    --         util_changeNodeParent(oriParent, topBuck)
    --         topBuck:setPosition(cc.p(0, 0))
    --         if _over then
    --             _over()
    --         end
    --     end        
    -- end)
end

return ShopBuckRewardLayer