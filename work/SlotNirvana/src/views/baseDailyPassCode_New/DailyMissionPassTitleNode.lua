--[[
    --新版每日任务pass主界面 标题
    csc 2021-06-21
]]
local DailyMissionPassTitleNode = class("DailyMissionPassTitleNode", util_require("base.BaseView"))

function DailyMissionPassTitleNode:initDatas(isPortrait)
    self.m_isPortrait = isPortrait
end

function DailyMissionPassTitleNode:initUI()
    self:createCsbNode(self:getCsbName())
    -- 读取csb 节点
    self.m_nodeSpineNpc = self:findChild("node_spine")
    self.m_node_kuang= self:findChild("node_kuang")
    
    self:initKuang()
    self:initSpineNode()
end

function DailyMissionPassTitleNode:getCsbName()
    if self.m_isPortrait then
        return DAILYPASS_RES_PATH.DailyMissionPass_Title_Vertical
    else
        return DAILYPASS_RES_PATH.DailyMissionPass_Title
    end
end

function DailyMissionPassTitleNode:initKuang()
    local path = DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_TitleNode_kuang.csb"
    if self.m_isPortrait then
        path = DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_TitleNode_Vertical_kuang.csb"
    end
    local kuangCsb = util_createAnimation(path)
    if kuangCsb then
        kuangCsb:playAction("idle", true)
        self.m_node_kuang:addChild(kuangCsb)
    end
end

function DailyMissionPassTitleNode:initSpineNode()
    --添加纸钞人spine
    if self.m_nodeSpineNpc then
        local spinePath = DAILYPASS_RES_PATH.DailyMissionPass_MainLayerNpc
        local npc = util_spineCreate(spinePath, false, true, 1)
        self.m_nodeSpineNpc:addChild(npc)
        local spineStrH = DAILYPASS_RES_PATH.DailyMissionPass_MainLayerNpcStrH
        local spineStrV = DAILYPASS_RES_PATH.DailyMissionPass_MainLayerNpcStrV
        if self.m_isPortrait then
            if spineStrV then
                util_spinePlay(npc, spineStrV, true)
            else
                util_spinePlay(npc, "idle_Vertical", true)
            end
        else
            if spineStrH then
                util_spinePlay(npc, spineStrH, true)
            else
                util_spinePlay(npc, "idle", true)
            end
        end
    end
end

return DailyMissionPassTitleNode
