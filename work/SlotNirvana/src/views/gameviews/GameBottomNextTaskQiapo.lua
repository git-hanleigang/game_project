local GameBottomNextTaskQiapo = class("GameBottomNextTaskQiapo", util_require("base.BaseView"))

--toComplete
function GameBottomNextTaskQiapo:initUI(_params)
    self:createCsbNode("GameNode/GameBottomNextTaskQiapo.csb")
    self:initCsbNodes()

    self.m_taskInfo = _params.task
    self.m_missionType = _params.type

    self:updateView()
    self:playAnim()
end

function GameBottomNextTaskQiapo:initCsbNodes()
    self.m_sprArrowLeft = self:findChild("spr_jiao_left")
    self.m_sprArrowRight = self:findChild("spr_jiao_right")

    self.m_nodeOne = self:findChild("node_one")
    self.m_nodeTwo = self:findChild("node_two")

    self.m_labOneTitle = self:findChild("lb_one_title")
    self.m_labOneTxt = self:findChild("lb_one_txt")

    self.m_labTwoTitle = self:findChild("lb_two_title")
    self.m_labTwoTxt = self:findChild("lb_two_txt")
    self.m_labTwoTxt2 = self:findChild("lb_two_txt_2")
end

function GameBottomNextTaskQiapo:updateView()
    -- 更新节点显示状态
    self.m_sprArrowLeft:setVisible(self:isLandscape())
    self.m_sprArrowRight:setVisible(not self:isLandscape())

    -- 标题展示
    local title = self.m_missionType == gLobalDailyTaskManager.MISSION_TYPE.DAILY_MISSION and "Daily Mission" or "Season Mission"
    self.m_labOneTitle:setString(title)
    self.m_labTwoTitle:setString(title)

    -- 根据当前任务的数量来决定显示几行的节点
    local tipStr = self.m_taskInfo:getTaskDescription()
    local strList = util_string_split(tipStr, ":")

    if #strList == 1 then
        self.m_nodeOne:setVisible(true)
        self.m_nodeTwo:setVisible(false)
        self.m_labOneTxt:setString(strList[1])
    elseif #strList == 2 then
        self.m_nodeOne:setVisible(false)
        self.m_nodeTwo:setVisible(true)
        self.m_labTwoTxt:setString(strList[1])
        self.m_labTwoTxt2:setString(strList[2])
    end

    -- 设置坐标
    local xDis = 110
    -- if globalData.slotRunData.isPortrait == true then
    --     xDis = -110
    -- end
    self:setPositionX(self:getPositionX() + xDis)
end

function GameBottomNextTaskQiapo:isLandscape()
    -- if globalData.slotRunData.isPortrait == true then
    --     return false
    -- end
    return true
end

function GameBottomNextTaskQiapo:playAnim()
    local dire = self:isLandscape() and "heng" or "shu"
    local startName = "start_" .. dire
    local idleName = "idle" .. dire
    local overName = "over_" .. dire
    self:runCsbAction(
        startName,
        false,
        function()
            self:runCsbAction(
                idleName,
                false,
                function()
                    performWithDelay(
                        self,
                        function()
                            self:runCsbAction(
                                overName,
                                false,
                                function()
                                    self:removeFromParent()
                                end,
                                60
                            )
                        end,
                        3
                    )
                end,
                60
            )
        end,
        60
    )
end

return GameBottomNextTaskQiapo
