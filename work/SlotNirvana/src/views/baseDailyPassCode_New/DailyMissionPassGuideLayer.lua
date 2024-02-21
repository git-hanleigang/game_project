--[[
    DailyMissionPass 引导界面
    author:{author}
    time:2021-07-15 12:29:54
]]
local BaseView = require("base.BaseView")
local DailyMissionPassGuideLayer = class("DailyMissionPassGuideLayer", BaseView)

function DailyMissionPassGuideLayer:initUI(data)
    self:createCsbNode(self:getCsbName())

    self.data = data

    for i = 1, 4 do
        local nodeGuide = self:findChild("Node_guide" .. i)
        if nodeGuide then
            nodeGuide:setVisible(false)
        end
    end

    self:updateView(self.data.guideStep)
end

function DailyMissionPassGuideLayer:getCsbName()
    if globalData.slotRunData.isPortrait then
        return DAILYPASS_RES_PATH.DailyMissionPass_GuideLayer_Vertical
    end
    return DAILYPASS_RES_PATH.DailyMissionPass_GuideLayer
end

function DailyMissionPassGuideLayer:onEnter()

end

function DailyMissionPassGuideLayer:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function DailyMissionPassGuideLayer:updateView(guideStep)
    -- 根据物品的名称创建图片精灵
    local nodeGuide = self:findChild("Node_guide" .. guideStep)
    if nodeGuide then
        nodeGuide:setVisible(true)
        if guideStep == 4 then
            local sp_normal = self:findChild("Sprite_3_Nomal")
            local sp_threeLine = self:findChild("Sprite_3_ThreeLine")
            if sp_normal then
                sp_normal:setVisible(not G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass())
            end
            if sp_threeLine then
                sp_threeLine:setVisible(G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass())
            end
        end
    end

    -- 添加mask
    self:addMask()
end

function DailyMissionPassGuideLayer:addMask()
    local mask = util_newMaskLayer()
    mask:setOpacity(0)
    local isTouch = false
    mask:onTouch(
        function(event)
            if not isTouch then
                return true
            end
            if event.name == "ended" then
                if self.data.isForceGuide == false then
                    print("DailyMissionPassGuideLayer:addMask  弱引导 , 点击遮罩删除")
                    gLobalNoticManager:postNotification(ViewEventType.EVENT_BATTLE_PASS_NEXT_GUIDE, {nextStep = true})
                else
                    print("DailyMissionPassGuideLayer:addMask  强引导 , 需要点击到对应的节点")
                end
            end

            return true
        end,
        false,
        true
    )

    performWithDelay(
        self,
        function()
            isTouch = true
        end,
        0.5
    )
    self:findChild("node_mask"):addChild(mask)
end

return DailyMissionPassGuideLayer
