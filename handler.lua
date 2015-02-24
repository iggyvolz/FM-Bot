local board=require "api"
local function explode(div,str) -- credit: http://richard.warburton.it
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end
local function shell(script)
  return io.popen(script):read("*a"):sub(1,-2)
end

local io,lfs,i,votecount,voters,players=require "io",require "lfs",1,{},{},{"BlankMediaGames","Achilles","PyroMonkeyGG","TurdPile","shapesifter13","Party4lyfe","Guzame","Metrion","iggyvolz","Rickdaily12","ObiWan","ValeforRaine","FMBot","enderitem","M4xwell","Ciara","Nellyfox","Naru2008","iRanOutOfUsersSoHereIsAFakeOne","HereIsAnotherFakeOne"}
while lfs.attributes("./cache/msgs/"..i) do
  print("Reading post "..i)
  local f=assert(io.open("./cache/msgs/"..i.."/author"))
  local author=f:read("*a")
  print("Post is by "..author)
  f:close()
  f=assert(io.open("./cache/msgs/"..i.."/conts"))
  local conts=f:read("*a")
  print("Post contents are "..conts)
  f:close()
  if #explode("/unvote",conts:lower())>1 and voters[author] then
    print("The user unvoted in this post")
    voters[author]=nil
  end
  for i=1,#players do
    print("Checking "..players[i].." now")
    if #explode("/vote "..players[i]:lower(),conts:lower())>1 and not voters[author] then
      print("The player voted for "..players[i])
      voters[author]=players[i]
    end
  end
  if #explode("/nolynch",conts:lower())>1 and not voters[author] then
    print("The player voted to nolynch")
    voters[author]="nolynch"
  end
  i=i+1
end
local function votecounttext(c,m,f)
  local t="[b][color=#"..c.."]Current vote count:\n"
  for i,x in pairs(f) do
    t=t..i.." ("..#x.."): "
    for i,v in ipairs(x) do
      t=t..v..", "
    end
    t=t:sub(1,-3).."\n"
  end
  t=t.."[i]"..m.." votes are needed for majority.[/i][/color][/b]"
  return t
end
print("Recounting the votes...")
for user,vote in pairs(voters) do
  print(user.." voted for "..vote)
  if not votecount[vote] then votecount[vote]={} end
  table.insert(votecount[vote],user)
end
require "pl.pretty".dump(votecount)
require "pl.pretty".dump(voters)
print(votecounttext("0080FF",10,votecount))
board:post("Re: Play around with FMBot",votecounttext("0080FF",10,votecount))
