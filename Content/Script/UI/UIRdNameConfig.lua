
local LUIRdNameConfig = {}

LUIRdNameConfig.NameList = {}
LUIRdNameConfig.MidNameList = {}
LUIRdNameConfig.EndNameList = {}

function LUIRdNameConfig:OnInit()
    local rdNameDatas = GameResMgr:GetGameResDataArray("SystemRandomPlayerNameDesc_Res")
    for k, v in pairs(rdNameDatas) do
        if v ~= nil then
            if v.Name ~= "" then
                table.insert(LUIRdNameConfig.NameList , v.Name)
            end

            if v.MiddleName ~= "" then
                table.insert(LUIRdNameConfig.MidNameList , v.MiddleName)
            end

            if v.EndName ~= "" then
                table.insert(LUIRdNameConfig.EndNameList , v.EndName)
            end
        end
    end
end

function LUIRdNameConfig:UnInit()
    LUIRdNameConfig.NameList = nil;
    LUIRdNameConfig.MidNameList = nil;
    LUIRdNameConfig.EndNameList = nil;
end

function LUIRdNameConfig:GetRandomName()
    local strName = ""

    local index = math.random(1 , #self.NameList)
    local nameIndex = index

    local strName = self.NameList[index]

    index = math.random(1 , #self.MidNameList)
    strName = strName .. self.MidNameList[index]

    local tempPlayerName = shallow_copy(self.NameList)
    table.remove(tempPlayerName , nameIndex)

    index = math.random(1 , #tempPlayerName)
    strName = strName .. tempPlayerName[index]

    table.insert(tempPlayerName ,self.NameList[nameIndex])

    local rand = math.random(1 , 10000)
    if rand < 3000 then
        index = math.random(1 , #self.EndNameList)
        strName = strName .. self.EndNameList[index]
    end

    return strName
end


return LUIRdNameConfig