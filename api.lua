local io=require "io"
local board={
  ["url"]="http://127.0.0.1/phpbb30",
  ["forum"]=2,
  ["topic"]=1,
  ["user"]="iggyvolz",
  ["pass"]="password"
}
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
local function shell(script,joined)
  if joined then
    return io.popen(script):read("*a"):sub(1,-2)
  else
    return explode("\n",io.popen(script):read("*a"):sub(1,-2))
  end
end

shell("curl --silent -d \"username="..board.user.."&password="..board.pass.."&login=Login\" "..board.url.."/ucp.php?mode=login -c cookies.txt")
function board:post(subj,msg)
  local conts=shell("curl --silent \""..self.url.."/posting.php?mode=reply&f="..self.forum.."&t="..self.topic.."\" -b cookies.txt",true)
  shell("sleep 2;curl --silent -d \"message="..msg.."&subject="..subj.."&topic_cur_post_id="..explode("\"",explode("<input type=\"hidden\" name=\"topic_cur_post_id\" value=\"",conts)[2])[1].."&lastclick="..explode("\"",explode("<input type=\"hidden\" name=\"lastclick\" value=\"",conts)[2])[1].."&creation_time="..explode("\"",explode("<input type=\"hidden\" name=\"creation_time\" value=\"",conts)[2])[1].."&form_token="..explode("\"",explode("<input type=\"hidden\" name=\"form_token\" value=\"",conts)[2])[1].."&post=Submit\" \""..self.url.."/posting.php?mode=reply&f="..self.forum.."&t="..self.topic.."\" -b cookies.txt")
end

board:post("foo","bar")