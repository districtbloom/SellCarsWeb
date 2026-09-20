-- Server-owned quotes. Client receives presentation and tap bounds, never the reservation price.
local N={}
local Http=game:GetService('HttpService')
local function money(n)return '$'..tostring(n):reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,','')end
function N.Open(holder,key,p)
 holder.negotiations=holder.negotiations or {}
 local q=holder.negotiations[key]
 if not q then
  q={id=Http:GenerateGUID(false),revision=0,price=p.price,opening=p.price,limit=p.limit,step=p.step or 50,mode=p.mode,name=p.name,role=p.role or 'Seller',line=p.line,forgiving=p.forgiving~=false,suggest=p.suggest,minimum=p.minimum or math.max(50,p.price-1000),maximum=p.maximum or p.price+1500}
  holder.negotiations[key]=q
 end
 return q
end
function N.Valid(q,p)
 return q and not q.departed and type(p)=='table' and p.id==q.id and p.revision==q.revision
end
function N.Public(q,prefix,dismiss)
 return {id=q.id,revision=q.revision,role=q.role,step=q.step,suggest=q.suggest or q.price+(q.mode=='Sell' and q.step or -q.step),minimum=q.minimum,maximum=q.maximum,canCounter=not q.agreed and not(q.final and q.forgiving),opening=q.opening,prefix=prefix or 'Trade',canDismiss=dismiss or false,agreed=q.agreed,final=q.final}
end
function N.Counter(q,p)
 if not N.Valid(q,p) or q.agreed or(q.final and q.forgiving) then return false end
 local a=p.amount
 if type(a)~='number' or a~=a or a==math.huge or a==-math.huge or a<q.minimum or a>q.maximum or a%q.step~=0 then return false end
 q.revision+=1
 local acceptable=q.mode=='Sell' and a<=q.limit or q.mode=='Buy' and a>=q.limit
 if acceptable then q.price=a;q.agreed=true;q.line='Deal. '..money(a)..' works for me.'
 elseif q.final and not q.forgiving then q.departed=true;q.line='That’s more than I can spend. I’ll pass.'
 elseif not q.forgiving and math.abs(a-q.limit)>q.step*2 and not q.warned then
  q.warned=true;q.final=true;q.price=q.limit;q.line='That’s too high for me. '..money(q.limit)..' is my limit.'
 else q.price=q.limit;q.final=true;q.line=q.mode=='Sell' and ('My full budget is '..money(q.limit)..'. That’s my best offer.') or (money(q.limit)..' is my lowest price.')end
 return true
end
return N

