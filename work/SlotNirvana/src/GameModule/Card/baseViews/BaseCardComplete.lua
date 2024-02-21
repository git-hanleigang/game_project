--[[
    -- 完成界面：link集卡进度界面，link卡集齐界面，章节集齐界面，赛季集齐界面
    author:{author}
    time:2019-07-17 17:44:05
]]
local BaseCardComplete = class("BaseCardComplete", BaseLayer)

function BaseCardComplete:initDatas(params)
    self.m_params = params
    self.m_isClickCollect = false
    self:setLandscapeCsbName(params.csb)
    self:setPauseSlotsEnabled(true)
    self:setExtendData("BaseCardComplete")
end

function BaseCardComplete:closeUI(callback)
    BaseCardComplete.super.closeUI(
        self,
        function()
            if callback then
                callback()
            end
            if self.m_params and self.m_params.callback then
                self.m_params.callback()
            end
        end
    )
end

function BaseCardComplete:setClickState()
end

-- hasDropEffect: 两侧的金币掉落特效
-- hasCoinEffect: 金币跳动时在金币上添加闪光特效
function BaseCardComplete:updateUI()
    self:setClickState()
end

function BaseCardComplete:updateEffect(hasDropEffect, hasCoinEffect)
    if hasDropEffect then
        local Node_drop_left = self:findChild("Node_drop_left")
        local Node_drop_right = self:findChild("Node_drop_right")
        if Node_drop_left and Node_drop_right then
            local effectPath = CardResConfig.commonRes.CompleteEffectDrop201902
            local effectLua = string.format(effectPath, "common" .. CardSysRuntimeMgr:getCurAlbumID())
            local csbNode1, csbAct1 = util_csbCreate(effectLua)
            util_csbPlayForKey(csbAct1, "idle", true, nil, 60)
            Node_drop_left:addChild(csbNode1)
            local csbNode2, csbAct2 = util_csbCreate(effectLua)
            util_csbPlayForKey(csbAct2, "idle", true, nil, 60)
            Node_drop_right:addChild(csbNode2)
        end
    end
    if hasCoinEffect then
        local Node_text_star = self:findChild("Node_text_star")
        if Node_text_star then
            local effectLua = CardResConfig.commonRes.CompleteEffectCoin201902
            local csbNode, csbAct = util_csbCreate(string.format(effectLua, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
            util_csbPlayForKey(csbAct, "idle", true, nil, 60)
            Node_text_star:addChild(csbNode)
        end
    end
end

--飞金币
function BaseCardComplete:flyCoins(Node_jinbi, rewardCoins, callback)
    self.m_isClickCollect = true

    local coins = tonumber(rewardCoins or 0)
    local startPos = Node_jinbi:getParent():convertToWorldSpace(cc.p(Node_jinbi:getPosition()))
    local flyList = {}
    if coins > 0 then
        table.insert(flyList, { cuyType = FlyType.Coin, addValue = coins, startPos = startPos })
    end
    G_GetMgr(G_REF.Currency):playFlyCurrency(flyList, callback)
end

return BaseCardComplete
