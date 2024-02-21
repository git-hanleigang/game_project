--[[
    
    author:徐袁
    time:2021-03-29 14:52:29
]]
local StatuePickCloudLayer = class("StatuePickCloudLayer", BaseLayer)

StatuePickCloudLayer.ActionType = "Common"

function StatuePickCloudLayer:ctor()
    StatuePickCloudLayer.super.ctor(self)

    self:setLandscapeCsbName("CardRes/season202102/Statue/StatuePick_effect_yun_Layer.csb")
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setShowBgOpacity(0)
    -- self:setPauseSlotsEnabled(true)
    self:setExtendData("StatuePickCloudLayer")
end

--[[
    @desc: 初始化csb节点
    author:徐袁
    time:2021-03-29 14:52:29
    @return:
]]
function StatuePickCloudLayer:initCsbNodes()
end

--[[
    @desc: 初始化界面显示
    author:徐袁
    time:2021-03-29 14:52:29
    @return:
]]
function StatuePickCloudLayer:initView()
end

--[[
    @desc: 刷新界面显示
    author:徐袁
    time:2021-03-29 14:52:29
    @return:
]]
function StatuePickCloudLayer:updateView()
end

-- 注册消息事件
function StatuePickCloudLayer:registerListener()
    StatuePickCloudLayer.super.registerListener(self)
end

function StatuePickCloudLayer:onEnter()
    StatuePickCloudLayer.super.onEnter(self)
end

function StatuePickCloudLayer:onExit()
    StatuePickCloudLayer.super.onExit(self)
end

-- layer显示完成的回调
function StatuePickCloudLayer:onShowedCallFunc()
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatueFog)
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", false)

            StatuePickControl:showStatuePickMainLayer()
            -- 持续1秒执行结束
            performWithDelay(
                self,
                function()
                    self:runCsbAction(
                        "over",
                        false,
                        function()
                            self:closeUI()
                        end
                    )
                end,
                1
            )
        end
    )
end

function StatuePickCloudLayer:clickFunc(sender)
    local senderName = sender:getName()
end

return StatuePickCloudLayer
