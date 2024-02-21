--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-06-17 11:18:29
]]
local GuideTestData = {}
GuideTestData.testStepCfg = {
    {id = 1, startStep = "1001", guideName = "testGuide", refName = "testRef"},
    {id = 2, startStep = "1101", guideName = "testGuide2", refName = "testRef"}
}

GuideTestData.testStepInfos = {
    {stepId = "1001", guideName = "testGuide", refName = "testRef", nextStep = "1002", isCoerce = false, isSwallow = false, archiveStep = "", luaName = "GuideTestLayer1", nodeName = "btn_1"},
    {stepId = "1002", guideName = "testGuide", refName = "testRef", nextStep = "1003", isCoerce = true, archiveStep = "", luaName = "GuideTestLayer1", nodeName = "btn_2"},
    {stepId = "1003", guideName = "testGuide", refName = "testRef", nextStep = "1003", isCoerce = true, archiveStep = "", luaName = "", nodeName = ""},
    {stepId = "1101", guideName = "testGuide2", refName = "testRef", nextStep = "1102", isCoerce = true, archiveStep = "", luaName = "GuideTestLayer2", nodeName = "btn_1"},
    {stepId = "1102", guideName = "testGuide2", refName = "testRef", nextStep = "1101", isCoerce = true, archiveStep = "", luaName = "", nodeName = ""},
}

return GuideTestData