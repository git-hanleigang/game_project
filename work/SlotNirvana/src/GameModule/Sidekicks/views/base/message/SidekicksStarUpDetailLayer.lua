--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-12-15 14:42:27
]]

local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")
local SidekicksStarUpDetailLayer = class("SidekicksStarUpDetailLayer", BaseLayer)

function SidekicksStarUpDetailLayer:initDatas(_seasonIdx)
    SidekicksStarUpDetailLayer.super.initDatas(self)

    self._seasonIdx = _seasonIdx
    self:setPauseSlotsEnabled(true) 
    local csbName = string.format("Sidekicks_%s/csd/starup/Sidekicks_StarUp_new.csb", _seasonIdx)
    self:setLandscapeCsbName(csbName)
end

function SidekicksStarUpDetailLayer:updateUI(_petInfo)
    self._petInfo = _petInfo

    -- 宠物Spine
    self:updateSpineUI()
    -- 当前星级
    self:updateStarNumUI()
    -- 付费buff变化
    self:updatePaySkillUI()

    util_setCascadeOpacityEnabledRescursion(self, true)
end

-- 宠物Spine
function SidekicksStarUpDetailLayer:updateSpineUI()
    local parent = self:findChild("node_spine")
    local petId = self._petInfo:getPetId()
    self.m_spineUI = util_createView("GameModule.Sidekicks.views.common.SidekicksSpineUI", petId, self._seasonIdx)
    self.m_spineUI:addTo(parent)
    self.m_spineUI:playFeedOkAct()
end

-- 当前星级
function SidekicksStarUpDetailLayer:updateStarNumUI()
    self.m_star = self._petInfo:getStar() + 1
    self.m_advanceIdx, self.m_subIdx = math.floor(self.m_star /5), self.m_star % 5
    self.m_showCount = 0
    if self.m_subIdx == 0 then
        if self.m_advanceIdx > 0 then
            self.m_showCount = 5
        end
    else
        self.m_showCount = self.m_subIdx
    end

    for i = 1, 5 do
        local nodeStar = self:findChild("node_star" .. i)
        if nodeStar then
            local starAniView = util_createAnimation(string.format("Sidekicks_%s/csd/starup/Sidekicks_StarUp_star.csb", self._seasonIdx))
            starAniView:addTo(nodeStar)
            starAniView:playAction("idle")

            local sp_star = starAniView:findChild("sp_star1")
            sp_star:setVisible(self.m_star > 5 and self.m_showCount > i)
            starAniView:setVisible(self.m_star-1 >= i)
        end
    end
end

-- 付费buff变化
function SidekicksStarUpDetailLayer:updatePaySkillUI()
    local lbPreNum = self:findChild("lb_benefitsNum_pre")
    local skillInfo = self._petInfo:getSkillInfoById(2)
    local prePayEx = skillInfo:getCurrentEx()
    lbPreNum:setString(string.format("+%s%%", prePayEx))
    
    local lbCurNum = self:findChild("lb_benefitsNum_new")
    local curPayEx = skillInfo:getNextEx()
    lbCurNum:setString(string.format("+%s%%", (curPayEx == 0 and prePayEx or curPayEx)))
end

function SidekicksStarUpDetailLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    SidekicksStarUpDetailLayer.super.playShowAction(self, "start")

    performWithDelay(self, function ()
        local nodeStar = self:findChild("node_star" .. self.m_showCount)
        if nodeStar then
            local starAniView = util_createAnimation(string.format("Sidekicks_%s/csd/starup/Sidekicks_StarUp_star.csb", self._seasonIdx))
            starAniView:addTo(nodeStar)
            starAniView:playAction("start")

            local sp_star = starAniView:findChild("sp_star1")
            sp_star:setVisible(self.m_star > 5)

            local sound = string.format("Sidekicks_%s/sound/Sidekicks_starUp.mp3", self._seasonIdx)
            gLobalSoundManager:playSound(sound)
        end

    end, 1)
end

function SidekicksStarUpDetailLayer:onShowedCallFunc()
    SidekicksStarUpDetailLayer.super.onShowedCallFunc(self)
    self._bCanClick = true
    self:runCsbAction("idle", true)
end

function SidekicksStarUpDetailLayer:onClickMask()
    if not self._bCanClick then
        return
    end
    SidekicksStarUpDetailLayer.super.onClickMask(self)
    self:closeUI()
end

function SidekicksStarUpDetailLayer:clickFunc(_sender)
    self:closeUI()
end

function SidekicksStarUpDetailLayer:closeUI()
    local cb = function()
        local detailLayer = gLobalViewManager:getViewByName(string.format("SidekicksDetailLayer_%d", self._seasonIdx))
        local detailLayerDealGuide = function()
            if detailLayer then
                detailLayer:dealGuideLogic() 
            end
        end

        local view = G_GetMgr(G_REF.Sidekicks):showStarUpReward(self._seasonIdx, self._petInfo)
        if not view then
            detailLayerDealGuide()
        else
            view:setOverFunc(detailLayerDealGuide)
        end
    end
    self:hidePartiicles()
    SidekicksStarUpDetailLayer.super.closeUI(self, cb)
end

return SidekicksStarUpDetailLayer