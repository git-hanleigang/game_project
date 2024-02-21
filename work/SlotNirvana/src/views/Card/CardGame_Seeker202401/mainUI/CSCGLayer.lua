--[[
    开始界面
]]
local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local CSStartLayer = class("CSStartLayer", BaseActivityMainLayer)

function CSStartLayer:initDatas()
    self:setLandscapeCsbName(CardSeekerCfg.csbPath .. "Seeker_CG.csb")
    self:setMaskEnabled(false)
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setPauseSlotsEnabled(true)
end

function CSStartLayer:initCsbNodes()
    self.m_nodeCG = self:findChild("node_cg")
end

function CSStartLayer:initView()
    self:initCG()
end

function CSStartLayer:initCG()
    -- 创建
    gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/CG.mp3")
    local CGSpine = util_spineCreate(CardSeekerCfg.otherPath .. "spine/guochang", true, true, 1)
    self.m_nodeCG:addChild(CGSpine)

    util_spinePlay(CGSpine, "guochang", false)
    util_spineEndCallFunc(
        CGSpine,
        "guochang",
        function()
            gLobalNoticManager:postNotification(ViewEventType.CARD_SEEKER_CG_CLOSED)
            util_nextFrameFunc(
                function()
                    if not tolua.isnull(self) then
                        self:closeUI()
                    end
                end
            )
        end
    )
end

return CSStartLayer
