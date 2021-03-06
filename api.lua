local io=require "io"
local config=require "config"
local board=config.board
board.__index=board

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
  io.popen("sleep 1")
  return io.popen(script):read("*a"):sub(1,-2)
end
local function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str
end
if not board.private then
  if not board.hidewarnings then
    print("Warning: No private attribute set.  We must blindly assume login is successful.")
  end
end
function board:checklogin()
  if not board.private then return true end
  return (shell("curl --silent \""..board.url..board.private.."\" -b cookies.txt|grep \"In order to login you must be registered. Registering takes only a few moments but gives you increased capabilities. The board administrator may also grant additional permissions to registered users. Before you register please ensure you are familiar with our terms of use and related policies. Please ensure you read any forum rules as you navigate around the board.\"") == "")
end
if not board:checklogin() then
  local result=shell("curl --silent -d \"username="..board.user.."&password="..board.pass.."&login=Login\" "..board.url.."/ucp.php?mode=login -c cookies.txt")
  if #explode("<label>Spell this word backwards",result)>1 then
    print("CAPTCHA question: Spell this word backwards: ",explode(":</label>",explode("<label>Spell this word backwards: ",result)[2])[1])
    local answer=explode(":</label>",explode("<label>Spell this word backwards: ",result)[2])[1]:reverse()
    local qaid=explode("\"",explode("<input type=\"hidden\" name=\"qa_confirm_id\" id=\"qa_confirm_id\" value=\"",result)[2])[1]
    shell("curl --silent -d \"username="..board.user.."&password="..board.pass.."&login=Login&qa_answer="..answer.."&qa_confirm_id="..qaid.."\" "..board.url.."/ucp.php?mode=login -c cookies.txt")
  end
  if not board:checklogin() then
    error("Log in failed")
  end
end
function board:post(subj,msg)
  local conts=shell("curl --silent \""..self.url.."/posting.php?mode=reply&f="..self.forum.."&t="..self.topic.."\" -b cookies.txt")
  shell("curl --silent -d \"message="..url_encode(msg).."&subject="..url_encode(subj).."&topic_cur_post_id="..explode("\"",explode("<input type=\"hidden\" name=\"topic_cur_post_id\" value=\"",conts)[2])[1].."&lastclick="..explode("\"",explode("<input type=\"hidden\" name=\"lastclick\" value=\"",conts)[2])[1].."&creation_time="..explode("\"",explode("<input type=\"hidden\" name=\"creation_time\" value=\"",conts)[2])[1].."&form_token="..explode("\"",explode("<input type=\"hidden\" name=\"form_token\" value=\"",conts)[2])[1].."&post=Submit\" \""..self.url.."/posting.php?mode=reply&f="..self.forum.."&t="..self.topic.."\" -b cookies.txt")
  --"
end
function board:read(p)
  local rp=board:readpage(p//24)
  return rp[(p%24)+1]
end

local function removeblockquotes(q)
  local p=explode("<blockquote>",q)
  s=p[1]
  local l=0
  for i=2,#p do
    l=l+2
    local e=explode("</blockquote>",p[i])
    l=l-#e
    if l == 0 then
      s=s..e[#e]
    end
  end
  return s
end
board.readpages={}
function board:readpage(p)
  if self.readpages[p] then return self.readpages[p] end -- If cached result then return it
  local page,toreturn=removeblockquotes(shell("curl --silent \""..self.url.."/viewtopic.php?f="..self.forum.."&t="..self.topic.."&start="..((p*24)-1).."\" -b cookies.txt")),{}
  for i=1,#explode("<div class=\"postbody\">",page)-2 do
    local sctn=explode("</div>",explode("<div class=\"postbody\">",page)[2+i])[1],{}
    table.insert(toreturn,{["conts"]=explode("<div class=\"content\">",sctn)[2]:gsub("<br />","  "):gsub("%b<>",""),["author"]=explode(">",explode("</a>",explode("<strong>",sctn)[2])[1])[2]})
  end
  self.readpages[p]=toreturn -- Cache this result
  return toreturn
end
function board:readpm(p)
  local page=explode("</div>",explode("<div class=\"postbody\">",shell("curl --silent \""..self.url.."/ucp.php?i=pm&mode=view&p="..p.."\" -b cookies.txt"))[2])[1]
  return {["conts"]=explode("<div class=\"content\">",page)[2],["author"]=explode(">",explode("</a>",explode("<p class=\"author\">",page)[2])[1])[7]}
end
local function numpms()
  local page=shell("curl --silent \""..board.url.."/ucp.php?i=pm&folder=inbox\" -b cookies.txt")
  return tonumber(explode("messages",explode("<li class=\"rightside pagination\">",page)[2])[1])
end
board.numpms=numpms()
local function getpmnums()
  local self,i,pms=board,2,{} -- Simulate other functions for consistancy
  while i<2+board.numpms do
    local page=shell("curl --silent \""..self.url.."/ucp.php?i=pm&folder=inbox&start="..(i-2).."\" -b cookies.txt")
    while explode("<a href=\"./ucp.php?i=pm&amp;mode=view&amp;f=0&amp;p=",page)[i] do
      table.insert(pms,tonumber(explode("\"",explode("<a href=\"./ucp.php?i=pm&amp;mode=view&amp;f=0&amp;p=",page)[i])[1]))
      i=i+1
    end
  end
  return pms
end
board.pmnums=getpmnums()
local function getnumofposts()
  local self=board -- Simulate other functions for consistancy
  local page=shell("curl --silent \""..self.url.."/viewtopic.php?f="..self.forum.."&t="..self.topic.."\" -b cookies.txt")
  local function maybeexplodebull(f)
    if explode("&bull;",explode("posts",f)[1])[2] then return explode("&bull;",f)[2] else return f end
  end
  return tonumber(explode(" posts",maybeexplodebull(explode("<div class=\"pagination\">",page)[2]))[1])
end
board.numposts=getnumofposts()
return board
