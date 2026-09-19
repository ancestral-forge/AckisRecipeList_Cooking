local root = "guides/Guidelime_CookingTriage/"
local function loadPart(name, addon) assert(loadfile(root .. name .. ".lua"))("Guidelime_CookingTriage", addon) end
local addon = {catalogRevision = "before", nodes = {[10]={title="Vendor"},[11]={title="Other"},[20]={title="Trainer"},[30]={title="Quest"}}, catalog = {
    {id="v1",kind="vendor",sourceID=10,spellID=1,items={100},name="One",expected=true,confidence="confident",reason="baseline"},
    {id="v2",kind="vendor",sourceID=10,spellID=2,items={101},name="Two",expected=false,confidence="uncertain",reason="negative control"},
    {id="other",kind="vendor",sourceID=11,spellID=1,items={100},name="Other",expected=true,confidence="confident",reason="baseline"},
    {id="t",kind="trainer",sourceID=20,spellID=200,items={},name="Trainer",expected=false,confidence="confident",reason="baseline"},
    {id="q",kind="quest",sourceID=30,questID=400,spellID=3,items={300},name="Quest",expected=true,confidence="uncertain",reason="baseline"},
    {id="loot",kind="loot",sourceID=600,spellID=4,items={400},name="Loot",expected=true,confidence="uncertain",reason="baseline",deferred="random"},
    {id="rogue",kind="quest",sourceID=30,questID=401,spellID=5,items={500},name="Rogue",expected=true,confidence="confident",class="ROGUE",reason="baseline"},
}}
loadPart("Verification",addon)
local V = addon.Verification
local run = V.NewRun("Player", "MAGE", 1, {})
assert(#run.cases == 6)
local snapshot = {kind="vendor",npcID=10,items={[100]=true},stock={[100]=0},complete=false,at=2}
V.Observe(run,snapshot)
assert(run.results.v1.state == "present" and not run.results.other and not run.results.v2)
snapshot.items = {}; V.Observe(run,snapshot)
assert(run.results.v1.state == "present", "Empty stock erased positive evidence")
assert(not V.Mark(run,"v2","absent","checked",3,snapshot,true), "Filtered menu accepted as absence")
snapshot.complete = true
assert(not V.Mark(run,"v2","absent","checked",3,snapshot,false))
assert(V.Mark(run,"v2","absent","full list, no restrictions",3,snapshot,true))
assert(V.Outcome(V.Find(run,"v2"),run.results.v2) == "match", "Expected absence must count as a match")
snapshot.items={[101]=true}; V.Observe(run,snapshot)
assert(run.results.v2.state == "conflict")
assert(V.Mark(run,"v2","unseen","",4))
V.Observe(run,snapshot)
assert(V.Outcome(V.Find(run,"v2"),run.results.v2) == "mismatch")
V.Observe(run,{kind="trainer",npcID=20,spells={[200]=true},at=4})
V.Observe(run,{kind="quest",npcID=30,questID=999,items={[300]=true},at=4})
assert(not run.results.q, "Wrong quest attributed a reward")
V.Observe(run,{kind="quest",npcID=30,questID=400,items={[300]=true},at=4})
assert(not V.Mark(run,"loot","absent","nothing dropped",5,snapshot,true))
assert(not V.Mark(run,"loot","blocked","",5))
assert(V.Mark(run,"loot","blocked","no container available",5))
local nonTrainerRun = V.NewRun("Player", "MAGE", 6, {})
local marked, markedCount = V.MarkNonTrainer(nonTrainerRun, 20, "NPC не открывает меню тренера", 6)
assert(marked and markedCount == 1 and nonTrainerRun.results.t.state == "absent")
assert(nonTrainerRun.results.t.evidence.method == "manual-nontrainer")
assert(V.Outcome(V.Find(nonTrainerRun, "t"), nonTrainerRun.results.t) == "match")
assert(not V.MarkNonTrainer(nonTrainerRun, 20, "", 6), "Non-trainer confirmation accepted without explanation")
local stats = V.Stats(run)
assert(stats.confident.match==1 and stats.confident.mismatch==1 and stats.confident.unseen==1)
assert(stats.uncertain.match==1 and stats.uncertain.mismatch==1 and stats.uncertain.blocked==1)
local report = V.Report(run,true)
assert(report:find("50.0%%") and report:find("negative control",1,true))
addon.catalog[1].expected=false; addon.catalog[1].confidence="uncertain"; addon.catalogRevision="after"
assert(run.revision=="before" and V.Find(run,"v1").expected and V.Find(run,"v1").confidence=="confident")
local newRun=V.NewRun("Player","MAGE",8,{})
assert(newRun.revision=="after" and not V.Find(newRun,"v1").expected and not next(newRun.results))
run.finished=7
assert(not V.Mark(run,"other","present","seen",9))
V.Observe(run,{kind="vendor",npcID=11,items={[100]=true},at=9})
assert(not run.results.other)
addon.catalog[1].expected=true; addon.catalog[1].confidence="confident"

-- Exercise the actual recorder event paths with delayed loading and NPC changes.
local frames,timers={},{}
local guid,merchant,trainer,filters,questID = nil,{}, {}, {available=true,unavailable=true,used=true},400
local function npc(id) guid="Creature-0-1-1-1-"..id.."-00000001" end
CreateFrame=function(kind)
    local f={scripts={}}
    function f:RegisterEvent() end
    function f:SetScript(event,fn) self.scripts[event]=fn end
    function f:SetOwner() end
    function f:ClearLines() end
    function f:SetMerchantItem() end
    function f:SetTrainerService(i) self.index=i end
    function f:GetSpell() return "Spell", trainer[self.index].spell end
    function f:NumLines() return 0 end
    function f:Hide() end
    frames[#frames+1]=f
    return f
end
UIParent={}
C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
time=function() return 20 end
UnitGUID=function(unit) assert(unit=="npc"); return guid end
UnitClass=function() return "Mage","MAGE" end
UnitName=function() return "Player" end
GetRealmName=function() return "Realm" end
GetBuildInfo=function() return "2.5.6","69546","",20506 end
GetMerchantNumItems=function() return #merchant end
GetMerchantItemLink=function(i) return merchant[i].id and "item:"..merchant[i].id end
GetMerchantItemInfo=function(i) return "Item",nil,10,1,merchant[i].stock end
GetNumTrainerServices=function() return #trainer end
GetTrainerServiceTypeFilter=function(key) return filters[key] end
GetTrainerServiceInfo=function(i) return "Service",nil,trainer[i].kind or "available",trainer[i].expanded end
GetTrainerServiceSkillReq=function() return "Cooking",25 end
GetQuestID=function() return questID end
GetNumQuestRewards=function() return 1 end
GetNumQuestChoices=function() return 0 end
GetQuestItemLink=function() return "item:300" end
unpack=table.unpack or unpack
loadPart("Recorder",addon)
local function event(name) frames[1].scripts.OnEvent(frames[1],name) end
local function flush() local work=timers;timers={};for _,fn in ipairs(work) do fn() end end
local live=addon.StartRun()
npc(10);merchant={{id=100,stock=0}};event("MERCHANT_SHOW")
npc(11);flush()
assert(not next(live.results), "Delayed scan attributed a different NPC")
event("MERCHANT_SHOW");flush()
assert(live.results.other and not live.results.v1)
npc(10);event("MERCHANT_SHOW");flush()
assert(live.results.v1.state=="present")
local c=V.Find(live,"v2")
assert(V.CanMarkAbsent(c,addon.CurrentSnapshot(c),true))
event("MERCHANT_UPDATE")
assert(not addon.CurrentSnapshot(c), "Old menu eligible while a refresh is pending")
for _=1,20 do event("MERCHANT_UPDATE") end
assert(#timers==1,"Update burst was not coalesced")
flush();event("MERCHANT_CLOSED")
assert(not addon.CurrentSnapshot(c))
npc(20);trainer={{spell=200}};filters.used=false;event("TRAINER_SHOW");flush()
local t=V.Find(live,"t")
assert(live.results.t.state=="present" and not addon.CurrentSnapshot(t).complete)
filters.used=true;trainer={{spell=nil}};event("TRAINER_UPDATE");flush()
assert(not addon.CurrentSnapshot(t).complete,"Unresolved spells allowed absence")
trainer={{kind="header",expanded=false}};event("TRAINER_UPDATE");flush()
assert(not addon.CurrentSnapshot(t).complete,"Collapsed group allowed absence")
event("TRAINER_CLOSED")
npc(30);questID=999;event("QUEST_DETAIL");flush();assert(not live.results.q)
questID=400;event("QUEST_DETAIL");flush();assert(live.results.q.state=="present")
event("QUEST_FINISHED");assert(not addon.CurrentSnapshot(V.Find(live,"q")))
-- Simulate saved-variable persistence and addon reload without reclassifying data.
CookingTriageDB=V.Copy(CookingTriageDB)
local saved=addon.GetRun()
assert(saved.revision=="after" and saved.results.q.state=="present")
assert(addon.StartRun()==saved and #CookingTriageDB.runs==1)
addon.FinishRun();local another=addon.StartRun()
assert(#CookingTriageDB.runs==2 and another~=saved and saved.finished and saved.report)
assert(not next(another.results) and saved.results.v1.state=="present")
print("PASS: frozen cohorts, expected absence, independent NPC/quest attribution, conflicts, pending/blocked, reports, delayed menus, filters, persistence and new runs")
