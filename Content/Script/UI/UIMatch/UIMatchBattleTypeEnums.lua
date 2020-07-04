local uiMatchBattleTypeEnums = {}



uiMatchBattleTypeEnums.MatchBattleTypeState =
{
    None = 0,
    SelectCamp = 1,
    MonsterCampSelected = 2,
    HunterCampSelected = 3,
    InviteTeammate = 4,
    TeamGroup = 5,
    ReadyToPlay = 6,
}

uiMatchBattleTypeEnums.ReadyTipsState =
{
    None = 0,
    InMatchBattleType = 1,
    OutMatchBattleType = 2,
}


uiMatchBattleTypeEnums.TeamGroupSlotState =
{
    Empty = 0,
    Teammate = 1,
}

uiMatchBattleTypeEnums.ChooseHeroState =
{
    None = 0,
    Selected = 1,
}

return uiMatchBattleTypeEnums