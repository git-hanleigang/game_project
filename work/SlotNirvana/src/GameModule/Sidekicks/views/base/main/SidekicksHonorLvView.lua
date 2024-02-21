--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-22 20:25:35
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-18 15:37:59
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/base/main/SidekicksHonorLvView.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksHonorLvView = class("SidekicksHonorLvView", BaseView)
local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")

function SidekicksHonorLvView:initDatas(_seasonIdx, _mainLayer)
    SidekicksHonorLvView.super.initDatas(self)

    self._seasonIdx = _seasonIdx
    self._mainLayer = _mainLayer
    self._data = G_GetMgr(G_REF.Sidekicks):getRunningData()
    self._stdCfg = self._data:getStdCfg()
end

function SidekicksHonorLvView:getCsbName()
    return string.format("Sidekicks_%s/csd/main/Sidekicks_Main_level.csb", self._seasonIdx)
end

function SidekicksHonorLvView:initUI()
    SidekicksHonorLvView.super.initUI(self)

    self:updateUI()
end
    
function SidekicksHonorLvView:updateUI()
    local honorLv = self._data:getHonorLv()
    -- 图标
    local spIcon = self:findChild("sp_level_icon")
    util_changeTexture(spIcon, string.format("Sidekicks_Common/rank_icon/rank_icon_%s.png", honorLv))

    -- 荣誉等级 经验
    local honorExp = self._data:getHonorExp()
    local cfgHonor = self._stdCfg:getHonorCfgData(honorLv)
    local nextLvExp = cfgHonor:getNextLvExp()
    if not nextLvExp then
        nextLvExp = honorExp
    end
    -- 进度详情
    local lbExpInfo = self:findChild("lb_level_pro")
    -- lbExpInfo:setString(string.format("%s/%s", honorExp, nextLvExp))
    -- 进度progBar
    local prog = honorExp / nextLvExp * 100
    local loadingBar = self:findChild("LoadingBar_1")
    loadingBar:setPercent(prog)
    lbExpInfo:setString(string.format("%.2f", prog) .. "%")
end

function SidekicksHonorLvView:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_click" then
        self._mainLayer:closeSkillbubble()

        local selectSeasonIdx = G_GetMgr(G_REF.Sidekicks):getSelectSeasonIdx()
        G_GetMgr(G_REF.Sidekicks):showRankLayer(selectSeasonIdx)
    end
end

function SidekicksHonorLvView:onEnter()
    SidekicksHonorLvView.super.onEnter(self)

    gLobalNoticManager:addObserver(self, "updateUI", SidekicksConfig.EVENT_NAME.NOTICE_FEED_PET_NET_CALL_BACK) -- 投喂宠物升级
end

return SidekicksHonorLvView