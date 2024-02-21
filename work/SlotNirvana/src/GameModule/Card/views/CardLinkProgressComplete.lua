--[[
    -- link卡集齐进度面板
    author:{author}
    time:2019-10-16 11:30:16
]]
local BaseCardComplete = util_require("GameModule.Card.baseViews.BaseCardComplete")
local CardLinkProgressComplete = class("CardLinkProgressComplete", BaseCardComplete)
function CardLinkProgressComplete:initUI(params)
    BaseCardComplete.initUI(self, params)
    if globalData.slotRunData.checkViewAutoClick then
        globalData.slotRunData:checkViewAutoClick(self, "Button_collect")
    end
    self:updateUI()
end

function CardLinkProgressComplete:getUIScalePro()
    local x = display.width / DESIGN_SIZE.width
    local y = display.height / DESIGN_SIZE.height
    local pro = x / y
    if globalData.slotRunData.isPortrait == true then
        pro = 0.75
    end
    return pro
end

function CardLinkProgressComplete:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_collect" then
        if self.m_clicked then
            return
        end
        self.m_clicked = true
        CardSysManager:closeCardCollectComplete()
    end
end

function CardLinkProgressComplete:updateUI()
    self:updateLinkProgress()
end

function CardLinkProgressComplete:updateLinkProgress()
    -- 数据处理
    local current = self.m_params.current
    local total = self.m_params.total
    local pre = math.max(0, current - 1)
    -- UI处理
    -- link总数 --
    local bmf_totalNum = self:findChild("bmf_totalNum")
    bmf_totalNum:setString(tostring(total))

    local jindu = self:findChild("jindu")
    -- 进度数字 --
    local percentNode = jindu:getChildByName("percentNode")
    percentNode:setString(pre .. "/" .. total)
    -- 进度条 --
    local LoadingBar = jindu:getChildByName("LoadingBar")
    LoadingBar:setPercent(pre / total * 100)
    -- 粒子位置 --
    local lizi = LoadingBar:getChildByName("Particle_3")
    local size = LoadingBar:getContentSize()
    lizi:setPositionX(size.width * (current / total * 100))

    -- 动作特效
    self:runCsbAction(
        "start_1",
        false,
        function()
            self.m_tick =
                util_schedule(
                self,
                function()
                    pre = pre + 0.1
                    LoadingBar:setPercent(pre / total * 100)
                    if pre >= current then
                        percentNode:setString(current .. "/" .. total)
                        if self.m_tick ~= nil then
                            self:stopAction(self.m_tick)
                        end
                        self.m_tick = nil
                        self:runCsbAction(
                            "start_2",
                            false,
                            function()
                                self:runCsbAction("idle", true, nil, 60)
                            end,
                            60
                        )
                    end
                end,
                0.1
            )
        end,
        60
    )
end

return CardLinkProgressComplete
