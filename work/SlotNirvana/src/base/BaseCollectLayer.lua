--[[

    author:{author}
    time:2022-04-28 11:06:31
]]
local BaseLayer = import(".BaseLayer")
local BaseCollectLayer = class("BaseCollectLayer", BaseLayer)

function BaseCollectLayer:ctor()
    BaseCollectLayer.super.ctor(self)
    -- 飞金币起始坐标
    self.m_startPos = nil
    -- 总增加金币数量
    self.m_addTotalCoins = 0
    -- 总增加第二货币数量
    self.m_addTotalGems = 0
    self.m_isFlyingCoins = false
end

function BaseCollectLayer:isFlyingCoins()
    return self.m_isFlyingCoins
end

--[[
    @desc: 领取奖励
    time:2022-04-28 18:20:29
    @addCoins: 增加金币数量
	@startNode: 飞金币起始节点
    @return:
]]
function BaseCollectLayer:onCollect(addCoins, startNode,addGems)
    self:addCoins(addCoins)
    self:addGems(addGems)
    self:setStartNode(startNode)
    self:collectBegin()
end

function BaseCollectLayer:setStartNode(startNode)
    if startNode and startNode:getParent() then
        self.m_startPos = startNode:getParent():convertToWorldSpace(cc.p(startNode:getPosition()))
    end
end

function BaseCollectLayer:addCoins(addCoins)
    self.m_addTotalCoins = self.m_addTotalCoins + (addCoins or 0)
end

function BaseCollectLayer:addGems(addGems)
    self.m_addTotalGems = self.m_addTotalGems + (addGems or 0)
end

-- 领取奖励后的回调
function BaseCollectLayer:collectCallback()
end

function BaseCollectLayer:collectBegin()
    local _addCoins = self.m_addTotalCoins
    local _addGems = self.m_addTotalGems
    
    local _startPos = self.m_startPos
    local cuyMgr = G_GetMgr(G_REF.Currency)
    if _startPos and cuyMgr then
        local info_Currency = {
        }
        if _addCoins > 0 then
            table.insert(info_Currency,
            {cuyType = FlyType.Coin, 
            addValue = _addCoins,
            startPos = _startPos})
        end

        if _addGems > 0 then
            table.insert(info_Currency,
            {cuyType = FlyType.Gem, 
            addValue = _addGems,
            startPos = _startPos})
        end
        if #info_Currency > 0 then
            self:_addBlockMask()
            self.m_isFlyingCoins = true
            cuyMgr:playFlyCurrency(info_Currency,function ()
                if not tolua.isnull(self) then
                    self:_removeBlockMask()
                    self.m_isFlyingCoins = false
                    self:collectCallback()
                end
            end
            )
        else
            self:collectCallback()
        end
    else
        self:collectCallback()
    end
end

return BaseCollectLayer
