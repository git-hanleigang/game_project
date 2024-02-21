--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-12-13 15:08:50
]]
local SidekicksLevelDetailView = class("SidekicksLevelDetailView", BaseView)

local SHOW_TYPE = {
    NORMAL = 1,
    MAX_LEVLE = 2, -- 最大等级了 不能升级了
    NEED_STAR_UP = 3, -- 去升星突破 才能升级
    COMING_SOON = 4, --等下一阶段开启
}

function SidekicksLevelDetailView:initDatas(_seasonIdx, _stdCfg, _seasonStageIdx, _detailLayer)
    SidekicksLevelDetailView.super.initDatas(self)

    self._seasonIdx = _seasonIdx
    self._data = G_GetMgr(G_REF.Sidekicks):getData()
    self._stdCfg = _stdCfg
    self._seasonStageIdx = _seasonStageIdx
    self._detailLayer = _detailLayer
end

function SidekicksLevelDetailView:getCsbName()
    return string.format("Sidekicks_%s/csd/message/Sidekicks_Message_level.csb", self._seasonIdx)
end

function SidekicksLevelDetailView:initCsbNodes()
    SidekicksLevelDetailView.super.initCsbNodes(self)
    
    self._layoutProgBar = self:findChild("layout_prog")
    self._size = self._layoutProgBar:getContentSize()
    self._progBarAddLizi = self:findChild("add_lizi")
    self._liziMaxPosX = self._progBarAddLizi:getPositionX()
    self._progBarAddLizi:setVisible(false)

    local nodeFeed = self:findChild("node_feed")
    self._feedNodeParent = nodeFeed:getParent()
    self._feedNodePos = cc.p(nodeFeed:getPosition())

    self:setButtonLabelContent("btn_feed", "FEED")
end

function SidekicksLevelDetailView:updateUI(_petInfo)
    self._petInfo = _petInfo
    -- self._petCfg = self._petInfo:getCurSkillCfg()
    -- self._petNextCfg = self._petInfo:getNextSkillCfg()

    -- 当前等级
    self:updateLevelLbUI()
    -- 经验
    self:updateExpUI()
    -- 更新 节点显隐
    self:updateLvNodeVisible()
end

-- 当前等级
function SidekicksLevelDetailView:updateLevelLbUI()
    local lbLevel = self:findChild("lb_level_num")
    local level = self._petInfo:getLevel()
    lbLevel:setString("LV." .. level)
    self.m_curLv = level
end

-- 经验
function SidekicksLevelDetailView:updateExpUI()
    local exp = self._petInfo:getLevelExp()
    local nextLvExp = self._petInfo:getLevelUpNeedExp()

    local lbExp = self:findChild("lb_bar_num")
    lbExp:setString(string.format("%s/%s", exp, nextLvExp))
    if nextLvExp == 0 then
        lbExp:setString("MAX")
    end

    local prog = 0
    if nextLvExp > 0 then
        prog = math.min(1, exp / nextLvExp)
    end
    self._layoutProgBar:setContentSize(cc.size(self._size.width * prog, self._size.height))

    local hadCount = self._data:getLvUpItemCount()
    local bCanLevelUp = self._petInfo:checkCanLevelUp()
    self:setButtonLabelDisEnabled("btn_feed", bCanLevelUp)
    self:findChild("node_reddot_2"):setVisible(hadCount ~= 0 and bCanLevelUp)
    self._bActing = false
end

-- 更新 节点显隐
function SidekicksLevelDetailView:updateLvNodeVisible()
    local type = self:getCurPetLevelShowType()

    self:findChild("node_feed"):setVisible(type == SHOW_TYPE.NORMAL)
    self:findChild("node_limit"):setVisible(type == SHOW_TYPE.COMING_SOON)
    self:findChild("node_starup"):setVisible(type == SHOW_TYPE.NEED_STAR_UP)
    self:findChild("node_max"):setVisible(type == SHOW_TYPE.MAX_LEVLE)

    self._showType = type
    self.m_isTouch = false
end

function SidekicksLevelDetailView:clickFunc(_sender)
    if self.m_isTouch then
        return
    end

    local name = _sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_feed" and not self._bActing and not self._detailLayer:getLvUpActing() then
        local hadCount = self._data:getLvUpItemCount()
        if hadCount > 0 then
            self.m_isTouch = true
            local exp = self._petInfo:getLevelExp()
            local nextLvExp = self._petInfo:getLevelUpNeedExp()
            local count = math.min(hadCount , (nextLvExp - exp))
            G_GetMgr(G_REF.Sidekicks):sendFeedPetReq(self._petInfo:getPetId(), count)
        else
            self._detailLayer:dealGuideLogic() 
            G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = 6})
        end
    end
end

function SidekicksLevelDetailView:getCurPetLevelShowType()
    local type = SHOW_TYPE.NORMAL
    local level = self._petInfo:getLevel()
    local levelMax = self._petInfo:getLevelMax()
    local stage = self._petInfo:getCurLevelAndStarStage()

    if level >= levelMax then
        -- 没有下一阶段了肯定满级了
        type = SHOW_TYPE.MAX_LEVLE
    elseif stage <= self._seasonStageIdx then
        -- 当前阶段到达瓶颈了
        local bCanLevelUp = self._petInfo:checkCanLevelUp()
        if not bCanLevelUp then
            -- 可以升级去升星吧
            type = SHOW_TYPE.NEED_STAR_UP
        end
    else
        type = SHOW_TYPE.COMING_SOON
    end
    return type
end

-- 宠物升级 动画相关
function SidekicksLevelDetailView:getLvUpActPosW()
    local refNode = self:findChild("sp_bag_1")
    return refNode:convertToWorldSpaceAR(cc.p(0, 0))
end
function SidekicksLevelDetailView:playFeedOkAct(_petInfo)
    _petInfo = _petInfo or self._petInfo
    local lbExp = self:findChild("lb_bar_num")
    local preExpInfo = string.split(lbExp:getString(), "/")
    local preExp = tonumber(preExpInfo[1]) or 0
    local preNeedExp = tonumber(preExpInfo[2]) or 0
    if preNeedExp == 0 then
        self:updateUI(_petInfo)
        return
    end

    local newExp = _petInfo:getLevelExp()
    -- local newExp = 5000
    local level = _petInfo:getLevel()
    if level > self.m_curLv then
        newExp = preNeedExp
    end
    local addExp = (newExp - preExp)
    local addStep = math.max(addExp / 30, 1)
    if addExp < 10 then
        -- 加这么点经验就别动画了
        self:updateUI(_petInfo)
        return
    end

    schedule(lbExp, function()
        preExp = math.floor(math.min(preExp + addStep, newExp))
        if preExp == newExp then
            lbExp:stopAllActions()
            self:updateUI(_petInfo)
            return
        end

        lbExp:setString(string.format("%s/%s", preExp, preNeedExp))
        local prog = 0
        if preNeedExp > 0 then
            prog = math.min(1, preExp / preNeedExp)
        end
        self._layoutProgBar:setContentSize(cc.size(self._size.width * prog, self._size.height))
        self._progBarAddLizi:setPositionX(math.min(self._size.width * prog, self._liziMaxPosX))
    end, 1/30)
    self._progBarAddLizi:setVisible(true)
    self._progBarAddLizi:start()

    self._bActing = true
end

function SidekicksLevelDetailView:playStart()
    self:runCsbAction("start", false)
end

function SidekicksLevelDetailView:getLevelUpBtnNode()
    local node = self:findChild("node_feed")
    local btn = self:findChild("btn_feed")
    if node:isVisible() and btn:isTouchEnabled() then
        return node
    end
end
function SidekicksLevelDetailView:resetLevelUpBtnNode()
    local node = self:findChild("node_feed")
    if node:getParent() == self._feedNodeParent then
        return
    end

    util_changeNodeParent(self._feedNodeParent, node)
    node:move(self._feedNodePos)
end

return SidekicksLevelDetailView