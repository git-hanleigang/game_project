local SidekicksStarDetailView = class("SidekicksStarDetailView", BaseView)

local SHOW_TYPE = {
    NORMAL = 1,
    MAX_LEVLE = 2, -- 最大等级了 不能升级了
    NEED_LEVEL_UP = 3, -- 提升你的等级 才能升星
    COMING_SOON = 4, --等下一阶段开启
}

function SidekicksStarDetailView:initDatas(_seasonIdx, _stdCfg, _seasonStageIdx, _detailLayer)
    SidekicksStarDetailView.super.initDatas(self)

    self._seasonIdx = _seasonIdx

    self._data = G_GetMgr(G_REF.Sidekicks):getData()
    self._stdCfg = _stdCfg
    self._seasonStageIdx = _seasonStageIdx
    self._detailLayer = _detailLayer
end

function SidekicksStarDetailView:getCsbName()
    return string.format("Sidekicks_%s/csd/message/Sidekicks_Message_star.csb", self._seasonIdx)
end

function SidekicksStarDetailView:initCsbNodes()
    SidekicksStarDetailView.super.initCsbNodes(self)
    
    self._defaultDesc = self:findChild("lb_levelup_desc"):getString()
    if not string.find(self._defaultDesc, "%%s") then
        self._defaultDesc = "Level %s to unlock next star"
    end

    local nodeStarup = self:findChild("node_starup")
    self._starupNodeParent = nodeStarup:getParent()
    self._starupNodePos = cc.p(nodeStarup:getPosition())

    self:setButtonLabelContent("btn_starup", "STAR UP")
end

function SidekicksStarDetailView:updateUI(_petInfo)
    self._petInfo = _petInfo
    -- self._petCfg = self._petInfo:getCurSCfg()
    -- self._petNextCfg = self._petInfo:getNextSkillCfg()

    -- 当前星级
    self:updateStarNumUI()
    -- 经验
    self:updateExpUI()
    -- 下一级等级
    self:updateNextLvUI()
    -- 更新 节点显隐
    self:updateLvNodeVisible()
end

-- 当前星级
function SidekicksStarDetailView:updateStarNumUI()
    local star = self._petInfo:getStar()
    local advanceIdx, subIdx = math.floor(star/5), star%5
    -- local showCount = 0
    -- if subIdx == 0 then
    --     if advanceIdx > 0 then
    --         showCount = 5
    --     end
    -- else
    --     showCount = subIdx
    -- end
    for i = 1, 5 do
        local nodeStar = self:findChild("node_star_" .. i)
        local starAniView = nodeStar:getChildByName("StarAniView")
        if not starAniView then
            starAniView = util_createAnimation(string.format("Sidekicks_%s/csd/message/Sidekicks_Message_star_icon.csb", self._seasonIdx))
            starAniView:setName("StarAniView")
            starAniView:addTo(nodeStar)
        end
        
        local sp_star = starAniView:findChild("sp_star_2")
        sp_star:setVisible(star-5 >= i)
        nodeStar:setVisible(star >= i)
    end
end

-- 经验
function SidekicksStarDetailView:updateExpUI()
    local starUpCoins = self._petInfo:getStarUpCoins()
    local node_reward = self:findChild("node_reward")
    local lbCoins = self:findChild("lb_reward_coin")
    lbCoins:setString(util_formatCoins(starUpCoins, 3))
    node_reward:setVisible(tonumber(starUpCoins) > 0)

    local nextStarExp = self._petInfo:getStarUpNeedExp()
    local lbExp = self:findChild("lb_item_num")
    local hadCount = self._data:getStarUpItemCount()
    lbExp:setString(string.format("%s/%s", hadCount, nextStarExp))
    if nextStarExp == 0 then
        lbExp:setString("MAX")
    end

    local bCanStarUp = self._petInfo:checkCanStarUp()
    self:setButtonLabelDisEnabled("btn_starup", bCanStarUp and hadCount >= nextStarExp)
    self:findChild("node_reddot_2"):setVisible(bCanStarUp and hadCount >= nextStarExp)
end

-- 下一级等级
function SidekicksStarDetailView:updateNextLvUI()
    local nextLv = self._petInfo:getNextStarNeedLevel()
    local desc = string.format(self._defaultDesc, nextLv)
    local lbDesc = self:findChild("lb_levelup_desc")
    lbDesc:setString(desc)
end

-- 更新 节点显隐
function SidekicksStarDetailView:updateLvNodeVisible()
    local type = self:getCurPetStarShowType()

    self:findChild("node_starup"):setVisible(type == SHOW_TYPE.NORMAL)
    self:findChild("node_limit"):setVisible(type == SHOW_TYPE.COMING_SOON)
    self:findChild("node_levelup"):setVisible(type == SHOW_TYPE.NEED_LEVEL_UP)
    self:findChild("node_max"):setVisible(type == SHOW_TYPE.MAX_LEVLE)
    local node_reward = self:findChild("node_reward")
    if node_reward:isVisible() and type == SHOW_TYPE.MAX_LEVLE then
        -- 满级隐藏金币奖励
        node_reward:setVisible(false)
    end

    self._showType = type
end

function SidekicksStarDetailView:clickFunc(_sender)
    local name = _sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_starup" then
        local hadCount = self._data:getStarUpItemCount()
        local nextStarExp = self._petInfo:getStarUpNeedExp()
        if hadCount >= nextStarExp then
            local exp = self._petInfo:getStarExp()
            local nextStarExp = self._petInfo:getStarUpNeedExp()
            local count = math.min(hadCount , (nextStarExp - exp))
            G_GetMgr(G_REF.Sidekicks):sendStarUpPetReq(self._petInfo:getPetId(), count)
        else
            self._detailLayer:dealGuideLogic() 
            G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = 6})
        end
    end
end

function SidekicksStarDetailView:getCurPetStarShowType()
    local type = SHOW_TYPE.NORMAL
    local Star = self._petInfo:getStar()
    local StarMax = self._petInfo:getStarMax()
    local stage = self._petInfo:getCurLevelAndStarStage()

    if Star >= StarMax then
        -- 没有下一阶段了肯定满级了
        type = SHOW_TYPE.MAX_LEVLE
    elseif stage <= self._seasonStageIdx then
        -- 当前阶段到达瓶颈了
        local bCanStarUp = self._petInfo:checkCanStarUp()
        if not bCanStarUp then
            -- 可以升级去升星吧
            type = SHOW_TYPE.NEED_LEVEL_UP
        end
    else
        type = SHOW_TYPE.COMING_SOON
    end
    return type
end

function SidekicksStarDetailView:getStarUpBtnNode()
    local node = self:findChild("node_starup")
    local btn = self:findChild("btn_starup")
    if node:isVisible() and btn:isTouchEnabled() then
        return node
    end
end

function SidekicksStarDetailView:resetStarUpBtnNode()
    local node = self:findChild("node_starup")
    if node:getParent() == self._starupNodeParent then
        return
    end

    util_changeNodeParent(self._starupNodeParent, node)
    node:move(self._starupNodePos)
end

return SidekicksStarDetailView